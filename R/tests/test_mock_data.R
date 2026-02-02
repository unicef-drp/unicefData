# ============================================================================
# Mock API Data Tests
#
# Tests using shared mock API fixtures from tests/fixtures/api_responses/
# These tests verify data structure and processing without API calls.
#
# Aligns with:
# - Python: python/tests/test_404_fallback.py
# - Stata: stata/tests/test_mock_data.do
#
# Date: 2026-01-25
# ============================================================================

cat("\n========================================================================\n")
cat("R Mock API Data Tests\n")
cat("========================================================================\n")

# Determine fixture directory path
if (file.exists("tests/fixtures/api_responses")) {
  FIXTURES_DIR <- "tests/fixtures/api_responses"
} else if (file.exists("../../tests/fixtures/api_responses")) {
  FIXTURES_DIR <- "../../tests/fixtures/api_responses"
} else {
  stop("Fixtures directory not found. Run from R/ or R/tests/ directory")
}

cat("Fixtures directory:", FIXTURES_DIR, "\n")

# Test counter
tests_run <- 0
tests_passed <- 0
tests_failed <- 0

# Test helper function
test_that <- function(description, test_fn) {
  tests_run <<- tests_run + 1
  cat("\nTest", tests_run, ":", description, "\n")

  tryCatch({
    test_fn()
    cat("  ✓ PASSED\n")
    tests_passed <<- tests_passed + 1
  }, error = function(e) {
    cat("  ✗ FAILED:", conditionMessage(e), "\n")
    tests_failed <<- tests_failed + 1
  })
}

# Test 1: Load valid CME data for Albania
test_that("Load valid CME data (Albania)", {
  file_path <- file.path(FIXTURES_DIR, "cme_albania_valid.csv")
  stopifnot(file.exists(file_path))

  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # Verify structure
  stopifnot(nrow(data) == 3)
  stopifnot(ncol(data) > 0)

  # Check required columns
  required_cols <- c("DATAFLOW", "REF_AREA", "INDICATOR", "TIME_PERIOD", "OBS_VALUE")
  for (col in required_cols) {
    if (!col %in% names(data)) {
      stop(paste("Missing column:", col))
    }
  }

  # Verify data values
  stopifnot(data$DATAFLOW[1] == "CME")
  stopifnot(data$REF_AREA[1] == "ALB")
  stopifnot(data$INDICATOR[1] == "CME_MRY0T4")
  stopifnot(data$OBS_VALUE[1] == 8.5)
})

# Test 2: Load valid USA data
test_that("Load valid CME data (USA)", {
  file_path <- file.path(FIXTURES_DIR, "cme_usa_valid.csv")
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  stopifnot(nrow(data) == 2)
  stopifnot(data$REF_AREA[1] == "USA")
  stopifnot(data$OBS_VALUE[1] == 6.7)
})

# Test 3: Load empty response
test_that("Load empty response (invalid indicator)", {
  file_path <- file.path(FIXTURES_DIR, "empty_response.csv")
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # Should have headers but no data rows
  stopifnot(nrow(data) == 0)
  stopifnot(ncol(data) > 0)  # Has column headers
})

# Test 4: Verify time series structure
test_that("Verify time series structure", {
  file_path <- file.path(FIXTURES_DIR, "cme_albania_valid.csv")
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # Check years are in sequence
  stopifnot(data$TIME_PERIOD[1] == 2020)
  stopifnot(data$TIME_PERIOD[2] == 2021)
  stopifnot(data$TIME_PERIOD[3] == 2022)
})

# Test 5: Verify mortality trend
test_that("Verify mortality trend (decreasing)", {
  file_path <- file.path(FIXTURES_DIR, "cme_albania_valid.csv")
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # Mortality should decrease over time
  stopifnot(data$OBS_VALUE[1] > data$OBS_VALUE[2])
  stopifnot(data$OBS_VALUE[2] > data$OBS_VALUE[3])
})

# Test 6: Verify data types
test_that("Verify data types", {
  file_path <- file.path(FIXTURES_DIR, "cme_albania_valid.csv")
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # TIME_PERIOD should be numeric
  stopifnot(is.numeric(data$TIME_PERIOD))

  # OBS_VALUE should be numeric
  stopifnot(is.numeric(data$OBS_VALUE))

  # DATAFLOW should be character
  stopifnot(is.character(data$DATAFLOW))
})

# Test 7: Check unit measure
test_that("Check unit measure", {
  file_path <- file.path(FIXTURES_DIR, "cme_albania_valid.csv")
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  stopifnot(data$UNIT_MEASURE[1] == "PER_1000_LIVEBIRTHS")
})

# Test 8: Check observation status
test_that("Check observation status", {
  file_path <- file.path(FIXTURES_DIR, "cme_albania_valid.csv")
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  stopifnot(data$OBS_STATUS[1] == "AVAILABLE")
})

# Test 9: Compare Albania vs USA mortality rates
test_that("Compare Albania vs USA mortality rates", {
  alb_data <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"), stringsAsFactors = FALSE)
  usa_data <- read.csv(file.path(FIXTURES_DIR, "cme_usa_valid.csv"), stringsAsFactors = FALSE)

  alb_rate_2020 <- alb_data$OBS_VALUE[alb_data$TIME_PERIOD == 2020]
  usa_rate_2020 <- usa_data$OBS_VALUE[usa_data$TIME_PERIOD == 2020]

  # Albania (8.5) should have higher mortality than USA (6.7)
  stopifnot(alb_rate_2020 > usa_rate_2020)
})

# Test 10: Verify CSV column names match SDMX standard
test_that("Verify CSV column names match SDMX standard", {
  file_path <- file.path(FIXTURES_DIR, "cme_albania_valid.csv")
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # Expected SDMX columns (order may vary)
  expected_cols <- c("DATAFLOW", "REF_AREA", "INDICATOR", "SEX", "TIME_PERIOD",
                     "OBS_VALUE", "UNIT_MEASURE", "OBS_STATUS")

  for (col in expected_cols) {
    if (!col %in% names(data)) {
      stop(paste("Expected SDMX column not found:", col))
    }
  }
})

# Summary
cat("\n========================================================================\n")
cat("Test Summary\n")
cat("========================================================================\n")
cat("Total tests:  ", tests_run, "\n")
cat("Passed:       ", tests_passed, "\n")
cat("Failed:       ", tests_failed, "\n")
cat("========================================================================\n")

cat("\nFixtures used:\n")
cat("  - cme_albania_valid.csv\n")
cat("  - cme_usa_valid.csv\n")
cat("  - empty_response.csv\n")

cat("\nTests verify:\n")
cat("  ✓ CSV structure matches SDMX format\n")
cat("  ✓ Required columns present\n")
cat("  ✓ Data types correct (numeric TIME_PERIOD, OBS_VALUE)\n")
cat("  ✓ Time series ordering\n")
cat("  ✓ Empty responses handled\n")
cat("  ✓ Cross-country comparisons\n")
cat("========================================================================\n")

# Exit with appropriate code
if (tests_failed > 0) {
  cat("\nSome tests failed!\n")
  quit(status = 1)
} else {
  cat("\nAll tests passed! ✓\n")
  quit(status = 0)
}

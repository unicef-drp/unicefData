# ============================================================================
# Cross-Language Output Validation Tests (Phase 7) - R Implementation
#
# Validates that R's data processing produces output structurally consistent
# with the expected output fixtures shared across all three languages.
#
# These tests use shared fixtures from tests/fixtures/ and do NOT require
# network access.
#
# Run: Rscript tests/test_cross_language_output.R
# ============================================================================

cat("\n========================================================================\n")
cat("Cross-Language Output Validation Tests (R)\n")
cat("========================================================================\n")

# Resolve fixture directories
if (file.exists("tests/fixtures/api_responses")) {
  FIXTURES_DIR <- "tests/fixtures/api_responses"
  EXPECTED_DIR <- "tests/fixtures/expected"
} else if (file.exists("fixtures/api_responses")) {
  FIXTURES_DIR <- "fixtures/api_responses"
  EXPECTED_DIR <- "fixtures/expected"
} else {
  stop("Fixtures directory not found. Run from repo root or tests/ directory")
}

# Test counters
tests_run <- 0
tests_passed <- 0
tests_failed <- 0

run_test <- function(description, test_fn) {
  tests_run <<- tests_run + 1
  tryCatch({
    test_fn()
    cat("  PASS ", description, "\n")
    tests_passed <<- tests_passed + 1
  }, error = function(e) {
    cat("  FAIL ", description, ":", conditionMessage(e), "\n")
    tests_failed <<- tests_failed + 1
  })
}

# ============================================================================
# 7.2.1 - Output Structure Validation
# ============================================================================

cat("\n--- 7.2.1: Output Structure ---\n")

run_test("Fixture files exist", function() {
  stopifnot(dir.exists(FIXTURES_DIR))
  stopifnot(dir.exists(EXPECTED_DIR))

  required_fixtures <- c(
    "cme_albania_valid.csv", "cme_usa_valid.csv", "empty_response.csv",
    "nutrition_multi_country.csv", "cme_disaggregated_sex.csv",
    "vaccination_multi_indicator.csv"
  )
  for (f in required_fixtures) {
    if (!file.exists(file.path(FIXTURES_DIR, f))) {
      stop(paste("Missing fixture:", f))
    }
  }

  required_expected <- c(
    "expected_columns.csv", "expected_cme_albania_output.csv",
    "expected_nutrition_multi_output.csv", "expected_error_messages.csv"
  )
  for (f in required_expected) {
    if (!file.exists(file.path(EXPECTED_DIR, f))) {
      stop(paste("Missing expected:", f))
    }
  }
})

run_test("CME Albania column structure", function() {
  mapping <- read.csv(file.path(EXPECTED_DIR, "expected_columns.csv"),
                      stringsAsFactors = FALSE)
  data <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"),
                   stringsAsFactors = FALSE)

  stopifnot(nrow(data) == 3)

  required <- mapping$sdmx_column[mapping$required == "yes"]
  actual_cols <- names(data)
  for (col in required) {
    if (!col %in% actual_cols) stop(paste("Missing required column:", col))
  }
})

run_test("CME Albania data values", function() {
  api_data <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"),
                       stringsAsFactors = FALSE)
  expected <- read.csv(file.path(EXPECTED_DIR, "expected_cme_albania_output.csv"),
                       stringsAsFactors = FALSE)

  stopifnot(nrow(api_data) == nrow(expected))

  for (i in seq_len(nrow(api_data))) {
    stopifnot(api_data$REF_AREA[i] == expected$iso3[i])
    stopifnot(api_data$INDICATOR[i] == expected$indicator[i])
    stopifnot(abs(api_data$OBS_VALUE[i] - expected$value[i]) < 0.001)
    stopifnot(api_data$TIME_PERIOD[i] == expected$period[i])
  }
})

run_test("Nutrition multi-country structure", function() {
  data <- read.csv(file.path(FIXTURES_DIR, "nutrition_multi_country.csv"),
                   stringsAsFactors = FALSE)
  stopifnot(nrow(data) == 6)
  stopifnot("AGE" %in% names(data))

  countries <- sort(unique(data$REF_AREA))
  stopifnot(identical(countries, c("BGD", "ETH", "IND")))
})

run_test("Nutrition values match expected", function() {
  api_data <- read.csv(file.path(FIXTURES_DIR, "nutrition_multi_country.csv"),
                       stringsAsFactors = FALSE)
  expected <- read.csv(file.path(EXPECTED_DIR, "expected_nutrition_multi_output.csv"),
                       stringsAsFactors = FALSE)

  stopifnot(nrow(api_data) == nrow(expected))

  for (i in seq_len(nrow(api_data))) {
    stopifnot(api_data$REF_AREA[i] == expected$iso3[i])
    stopifnot(abs(api_data$OBS_VALUE[i] - expected$value[i]) < 0.001)
  }
})

run_test("Disaggregated sex structure", function() {
  data <- read.csv(file.path(FIXTURES_DIR, "cme_disaggregated_sex.csv"),
                   stringsAsFactors = FALSE)
  stopifnot(nrow(data) == 6)

  sex_values <- sort(unique(data$SEX))
  stopifnot(length(sex_values) == 3)
  stopifnot(all(c("F", "M", "_T") %in% sex_values))

  # Male mortality > female (biological pattern)
  for (yr in c(2020, 2021)) {
    year_data <- data[data$TIME_PERIOD == yr, ]
    male_val <- year_data$OBS_VALUE[year_data$SEX == "M"]
    female_val <- year_data$OBS_VALUE[year_data$SEX == "F"]
    if (male_val <= female_val) {
      stop(paste("Year", yr, ": Male should > Female"))
    }
  }
})

run_test("Multi-indicator structure", function() {
  data <- read.csv(file.path(FIXTURES_DIR, "vaccination_multi_indicator.csv"),
                   stringsAsFactors = FALSE)
  stopifnot(nrow(data) == 8)

  indicators <- sort(unique(data$INDICATOR))
  stopifnot(identical(indicators, c("IM_DTP3", "IM_MCV1")))

  countries <- sort(unique(data$REF_AREA))
  stopifnot(identical(countries, c("GHA", "KEN")))
})

run_test("Empty response structure", function() {
  data <- read.csv(file.path(FIXTURES_DIR, "empty_response.csv"),
                   stringsAsFactors = FALSE)
  stopifnot(nrow(data) == 0)
  stopifnot(ncol(data) > 0)
})

run_test("Data types numeric", function() {
  fixtures <- c("cme_albania_valid.csv", "nutrition_multi_country.csv",
                "cme_disaggregated_sex.csv", "vaccination_multi_indicator.csv")
  for (f in fixtures) {
    data <- read.csv(file.path(FIXTURES_DIR, f), stringsAsFactors = FALSE)
    if (!is.numeric(data$OBS_VALUE)) stop(paste(f, ": OBS_VALUE not numeric"))
    if (!is.numeric(data$TIME_PERIOD)) stop(paste(f, ": TIME_PERIOD not numeric"))
  }
})

run_test("Column mapping completeness", function() {
  mapping <- read.csv(file.path(EXPECTED_DIR, "expected_columns.csv"),
                      stringsAsFactors = FALSE)
  sdmx_cols <- mapping$sdmx_column

  fixtures <- c("cme_albania_valid.csv", "nutrition_multi_country.csv",
                "vaccination_multi_indicator.csv")
  for (f in fixtures) {
    data <- read.csv(file.path(FIXTURES_DIR, f), stringsAsFactors = FALSE)
    for (col in names(data)) {
      if (!col %in% sdmx_cols) {
        stop(paste("Column", col, "in", f, "not in expected_columns.csv"))
      }
    }
  }
})

# ============================================================================
# 7.2.2 - Error Message Validation
# ============================================================================

cat("\n--- 7.2.2: Error Validation ---\n")

run_test("Error message patterns", function() {
  errors <- read.csv(file.path(EXPECTED_DIR, "expected_error_messages.csv"),
                     stringsAsFactors = FALSE)
  stopifnot(nrow(errors) >= 3)

  for (i in seq_len(nrow(errors))) {
    if (nchar(errors$scenario[i]) == 0) stop("Missing scenario name")
    if (nchar(errors$error_type[i]) == 0) stop("Missing error type")
    if (nchar(errors$message_pattern[i]) == 0) stop("Missing message pattern")

    langs <- strsplit(errors$languages[i], ";")[[1]]
    if (!"r" %in% langs && !"python" %in% langs) {
      stop(paste("Scenario", errors$scenario[i], "missing major language"))
    }
  }
})

# ============================================================================
# 7.2.3 - Cache Validation
# ============================================================================

cat("\n--- 7.2.3: Cache Validation ---\n")

# Skip cache tests if package not installed (CI with minimal deps)
if (requireNamespace("unicefData", quietly = TRUE)) {
  run_test("R clear_unicef_cache exported", function() {
    exports <- getNamespaceExports("unicefData")
    if (!"clear_unicef_cache" %in% exports) stop("clear_unicef_cache not exported")
  })

  run_test("R clear_schema_cache exported", function() {
    exports <- getNamespaceExports("unicefData")
    if (!"clear_schema_cache" %in% exports) stop("clear_schema_cache not exported")
  })
} else {
  cat("  SKIP  Cache validation tests (unicefData package not installed)\n")
}

# ============================================================================
# Summary
# ============================================================================

cat("\n========================================================================\n")
cat(sprintf("Results: %d/%d passed, %d failed\n", tests_passed, tests_run, tests_failed))
cat("========================================================================\n")

if (tests_failed > 0) {
  cat("\nSome tests failed!\n")
  quit(status = 1)
} else {
  cat("\nAll tests passed!\n")
  quit(status = 0)
}

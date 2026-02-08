# ============================================================================
# Pipeline Tests with Fixture Data (R)
#
# Tests clean_unicef_data() and filter_unicef_data() functions directly
# using shared CSV fixtures. No network access required.
#
# Fixtures: tests/fixtures/api_responses/
#
# Run: Rscript R/tests/test_pipeline_fixtures.R   (from repo root)
# ============================================================================

cat("\n========================================================================\n")
cat("Pipeline Tests with Fixture Data (R)\n")
cat("========================================================================\n")

# --- Check dependencies ---
required_pkgs <- c("dplyr", "magrittr", "httr", "readr", "countrycode", "yaml", "rlang")
missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  cat(sprintf("SKIP: Missing packages: %s\n", paste(missing_pkgs, collapse = ", ")))
  cat("Install with: install.packages(c('", paste(missing_pkgs, collapse = "', '"), "'))\n")
  cat("These tests run in CI where packages are installed.\n")
  cat("========================================================================\n")
  quit(status = 0)
}

# --- Resolve paths ---
if (file.exists("tests/fixtures/api_responses")) {
  FIXTURES_DIR <- "tests/fixtures/api_responses"
  R_DIR <- "R"
} else if (file.exists("../../tests/fixtures/api_responses")) {
  FIXTURES_DIR <- "../../tests/fixtures/api_responses"
  R_DIR <- ".."
} else {
  stop("Fixtures directory not found. Run from repo root or R/tests/ directory.")
}

# --- Source package code (pure functions, no network) ---
cat("Sourcing package code from:", R_DIR, "\n")

# Utilities first (user agent, helpers)
source(file.path(R_DIR, "utils.R"))

# Core functions (clean_unicef_data, filter_unicef_data, etc.)
# Suppress metadata loading messages during test init
suppressMessages({
  source(file.path(R_DIR, "unicef_core.R"))
})

# --- Test infrastructure ---
tests_run <- 0
tests_passed <- 0
tests_failed <- 0

run_test <- function(description, test_fn) {
  tests_run <<- tests_run + 1
  result <- tryCatch({
    test_fn()
    tests_passed <<- tests_passed + 1
    cat(sprintf("  PASS  %s\n", description))
  }, error = function(e) {
    tests_failed <<- tests_failed + 1
    cat(sprintf("  FAIL  %s: %s\n", description, conditionMessage(e)))
  })
}

# ==========================================================================
# clean_unicef_data() tests
# ==========================================================================

cat("\n--- clean_unicef_data() ---\n")

run_test("Column renaming (REF_AREA -> iso3, TIME_PERIOD -> period)", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"),
                  stringsAsFactors = FALSE)
  cleaned <- clean_unicef_data(raw)

  stopifnot("iso3" %in% names(cleaned))
  stopifnot("period" %in% names(cleaned))
  stopifnot("value" %in% names(cleaned))
  stopifnot("indicator" %in% names(cleaned))

  # Original SDMX columns should be gone
  stopifnot(!"REF_AREA" %in% names(cleaned))
  stopifnot(!"TIME_PERIOD" %in% names(cleaned))
  stopifnot(!"OBS_VALUE" %in% names(cleaned))
})

run_test("Period column is numeric", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"),
                  stringsAsFactors = FALSE)
  cleaned <- clean_unicef_data(raw)

  stopifnot(is.numeric(cleaned$period))
  stopifnot(all(cleaned$period >= 2000))
  stopifnot(all(cleaned$period <= 2030))
})

run_test("Value column is numeric", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"),
                  stringsAsFactors = FALSE)
  cleaned <- clean_unicef_data(raw)

  stopifnot(is.numeric(cleaned$value))
  stopifnot(all(!is.na(cleaned$value)))
})

run_test("Country name added for ALB", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"),
                  stringsAsFactors = FALSE)
  cleaned <- clean_unicef_data(raw)

  if ("country" %in% names(cleaned)) {
    # countrycode should resolve ALB -> Albania
    stopifnot(any(grepl("Albania", cleaned$country, ignore.case = TRUE)))
  }
})

run_test("geo_type = 0 for country codes (ALB)", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"),
                  stringsAsFactors = FALSE)
  cleaned <- clean_unicef_data(raw)

  if ("geo_type" %in% names(cleaned)) {
    # ALB is a country, not an aggregate
    stopifnot(all(cleaned$geo_type == 0))
  }
})

run_test("Multi-country cleaning preserves all countries", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "nutrition_multi_country.csv"),
                  stringsAsFactors = FALSE)
  cleaned <- clean_unicef_data(raw)

  n_countries <- length(unique(cleaned$iso3))
  stopifnot(n_countries == 3)  # IND, ETH, BGD
})

run_test("Indicator column value preserved", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "cme_albania_valid.csv"),
                  stringsAsFactors = FALSE)
  cleaned <- clean_unicef_data(raw)

  stopifnot("CME_MRY0T4" %in% cleaned$indicator)
})

run_test("Empty response returns 0-row dataframe", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "empty_response.csv"),
                  stringsAsFactors = FALSE)
  cleaned <- clean_unicef_data(raw)

  stopifnot(nrow(cleaned) == 0)
})

# ==========================================================================
# filter_unicef_data() tests
#
# NOTE: In the real pipeline, filter is applied BEFORE clean (on raw SDMX
# data with uppercase column names like SEX, AGE). See unicefData.R lines
# 528 (filter) vs 538 (clean). Tests match this order.
# ==========================================================================

cat("\n--- filter_unicef_data() ---\n")

run_test("Sex filter default (_T) keeps only total rows", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "cme_disaggregated_sex.csv"),
                  stringsAsFactors = FALSE)

  # 6 rows: 2 years x 3 sex values
  stopifnot(nrow(raw) == 6)

  # Filter on raw data (before clean), matching real pipeline order
  filtered <- filter_unicef_data(raw, sex = "_T", verbose = FALSE)

  # Should keep only _T rows (2 years)
  stopifnot(all(filtered$SEX == "_T"))
  stopifnot(nrow(filtered) == 2)
})

run_test("Sex filter explicit (M) keeps only male rows", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "cme_disaggregated_sex.csv"),
                  stringsAsFactors = FALSE)

  # Filter on raw data (before clean), matching real pipeline order
  filtered <- filter_unicef_data(raw, sex = "M", verbose = FALSE)

  stopifnot(all(filtered$SEX == "M"))
  stopifnot(nrow(filtered) == 2)
})

run_test("NUTRITION dataflow age defaults to Y0T4", function() {
  raw <- read.csv(file.path(FIXTURES_DIR, "nutrition_multi_country.csv"),
                  stringsAsFactors = FALSE)

  # Filter on raw data (before clean), matching real pipeline order
  filtered <- filter_unicef_data(raw, dataflow = "NUTRITION", verbose = FALSE)

  if ("AGE" %in% names(filtered)) {
    # Should keep Y0T4 rows (that's all this fixture has)
    stopifnot(all(filtered$AGE == "Y0T4"))
  }
  # Should preserve all 6 rows (3 countries x 2 years, all Y0T4)
  stopifnot(nrow(filtered) == 6)
})

# ==========================================================================
# Summary
# ==========================================================================

cat("\n========================================================================\n")
cat(sprintf("Results: %d/%d passed, %d failed\n", tests_passed, tests_run, tests_failed))
cat("========================================================================\n")

if (tests_failed > 0) {
  cat("\nSome tests failed!\n")
  quit(status = 1)
} else {
  cat("\nAll tests passed!\n")
}

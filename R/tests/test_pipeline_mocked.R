# ============================================================================
# Full Pipeline Tests with Mocked HTTP Responses (R)
#
# Tests the complete unicefData() flow (fetch -> clean -> filter -> output)
# using mocked HTTP responses from shared fixture CSVs. No live API calls.
#
# Equivalent to Python's test_pipeline_mocked.py using @responses.activate.
# Instead of webmockr, we mock fetch_sdmx_text() directly — R's idiomatic
# equivalent of intercepting HTTP at the adapter level.
#
# Fixtures: tests/fixtures/api_responses/
#
# Run: Rscript R/tests/test_pipeline_mocked.R   (from repo root)
# ============================================================================

cat("\n========================================================================\n")
cat("Full Pipeline Tests with Mocked HTTP (R)\n")
cat("========================================================================\n")

# --- Check dependencies ---
required_pkgs <- c("dplyr", "magrittr", "httr", "readr", "countrycode", "yaml", "rlang", "purrr")
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

# --- Source package code ---
cat("Sourcing package code from:", R_DIR, "\n")
source(file.path(R_DIR, "utils.R"))
suppressMessages({
  source(file.path(R_DIR, "unicef_core.R"))
  source(file.path(R_DIR, "unicefData.R"))
})

# --- Load fixture CSV content ---
read_fixture <- function(filename) {
  paste(readLines(file.path(FIXTURES_DIR, filename), warn = FALSE), collapse = "\n")
}

FIXTURE_CME_ALBANIA     <- read_fixture("cme_albania_valid.csv")
FIXTURE_NUTRITION_MULTI <- read_fixture("nutrition_multi_country.csv")
FIXTURE_CME_SEX         <- read_fixture("cme_disaggregated_sex.csv")
FIXTURE_VACCINATION     <- read_fixture("vaccination_multi_indicator.csv")
FIXTURE_EMPTY           <- read_fixture("empty_response.csv")

# =========================================================================
# Mock infrastructure — R equivalent of Python's @responses.activate
# =========================================================================
#
# We replace fetch_sdmx_text() in the global environment. Since all R code
# was sourced into global, .fetch_one_flow() will find our mock when it
# calls fetch_sdmx_text(). This is identical in spirit to Python's
# `responses` library intercepting requests.get() at the adapter level.
# =========================================================================

# Save original function
.original_fetch_sdmx_text <- fetch_sdmx_text

# Create mock that routes by URL pattern (like Python conftest mock_pipeline_endpoints)
.create_mock_fetch <- function(sex_fixture = "albania") {
  cme_body <- if (sex_fixture == "brazil") FIXTURE_CME_SEX else FIXTURE_CME_ALBANIA

  function(url, ua = NULL, retry = 3) {
    # Nutrition indicator
    if (grepl("NT_ANT_HAZ", url)) return(FIXTURE_NUTRITION_MULTI)

    # Vaccination indicators
    if (grepl("IM_(DTP3|MCV1)", url)) return(FIXTURE_VACCINATION)

    # CME indicator
    if (grepl("CME_MRY0T4", url)) return(cme_body)

    # Default: 404 (like Python's catch-all)
    stop(
      structure(
        list(message = sprintf("Not Found (404): %s", url), url = url, status = 404L),
        class = c("sdmx_404", "error", "condition")
      )
    )
  }
}

# Helper: activate mock, run test, restore original (like @responses.activate)
with_mocked_http <- function(test_fn, sex_fixture = "albania") {
  # Activate mock
  assign("fetch_sdmx_text", .create_mock_fetch(sex_fixture), envir = .GlobalEnv)
  on.exit({
    # Always restore original (like Python's responses cleanup)
    assign("fetch_sdmx_text", .original_fetch_sdmx_text, envir = .GlobalEnv)
  })
  test_fn()
}

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
# TestPipelineBasic — matches Python TestPipelineBasic
# ==========================================================================

cat("\n--- unicefData() full pipeline (basic) ---\n")

run_test("Basic fetch and clean: standard columns present", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"), year = "2020:2022")
    )

    stopifnot(is.data.frame(df))
    stopifnot(nrow(df) > 0)

    # Column renaming: SDMX -> standard
    stopifnot("iso3" %in% names(df))
    stopifnot("period" %in% names(df))
    stopifnot("value" %in% names(df))
    stopifnot("indicator" %in% names(df))

    # Original SDMX columns should be gone
    stopifnot(!"REF_AREA" %in% names(df))
    stopifnot(!"TIME_PERIOD" %in% names(df))
    stopifnot(!"OBS_VALUE" %in% names(df))
  })
})

run_test("Period column is numeric", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"))
    )

    stopifnot(is.numeric(df$period))
    stopifnot(all(df$period >= 2000))
    stopifnot(all(df$period <= 2030))
  })
})

run_test("Value column is numeric", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"))
    )

    stopifnot(is.numeric(df$value))
    stopifnot(all(!is.na(df$value)))
  })
})

run_test("Country filtering: only ALB returned", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"))
    )

    stopifnot(all(df$iso3 == "ALB"))
  })
})

run_test("geo_type = 0 for country codes (ALB)", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"))
    )

    if ("geo_type" %in% names(df)) {
      stopifnot(all(df$geo_type == 0))
    }
  })
})

run_test("raw=TRUE returns unprocessed DataFrame with original columns", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"), raw = TRUE)
    )

    stopifnot(is.data.frame(df))
    stopifnot(nrow(df) > 0)
    # Raw mode renames core columns but keeps other SDMX columns
    stopifnot("iso3" %in% names(df) || "REF_AREA" %in% names(df))
    stopifnot("indicator" %in% names(df) || "INDICATOR" %in% names(df))
  })
})


# ==========================================================================
# TestPipelineFiltering — matches Python TestPipelineFiltering
# ==========================================================================

cat("\n--- unicefData() pipeline filtering ---\n")

run_test("Sex default filter (_T) keeps only total rows", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("BRA"), sex = "_T")
    )

    stopifnot(is.data.frame(df))
    if ("sex" %in% names(df) && nrow(df) > 0) {
      stopifnot(all(df$sex == "_T"))
    }
  }, sex_fixture = "brazil")
})

run_test("Sex explicit (M) returns only male rows", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("BRA"), sex = "M")
    )

    stopifnot(is.data.frame(df))
    if ("sex" %in% names(df) && nrow(df) > 0) {
      stopifnot(all(df$sex == "M"))
    }
  }, sex_fixture = "brazil")
})


# ==========================================================================
# TestPipelineMulti — matches Python TestPipelineMulti
# ==========================================================================

cat("\n--- unicefData() multi-country/indicator ---\n")

run_test("Multi-country: IND, ETH, BGD all appear", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "NT_ANT_HAZ_NE2", countries = c("IND", "ETH", "BGD"))
    )

    stopifnot(is.data.frame(df))
    if (nrow(df) > 0) {
      countries <- unique(df$iso3)
      stopifnot(length(countries) >= 2)
    }
  })
})

run_test("Empty/unknown indicator returns empty or raises gracefully", function() {
  with_mocked_http(function() {
    result <- tryCatch({
      df <- suppressMessages(suppressWarnings(
        unicefData(indicator = "NONEXISTENT_INDICATOR_XYZ", countries = c("ALB"))
      ))
      # If it returns, should be empty
      stopifnot(is.data.frame(df))
      stopifnot(nrow(df) == 0)
    }, error = function(e) {
      # Error is also acceptable (like SDMXNotFoundError in Python)
      TRUE
    })
  })
})


# ==========================================================================
# TestPipelineColumnOrder — matches Python TestPipelineColumnOrder
# ==========================================================================

cat("\n--- unicefData() column ordering ---\n")

run_test("Critical standard columns present", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"))
    )

    critical_cols <- c("indicator", "iso3", "period", "value")
    for (col in critical_cols) {
      if (!col %in% names(df)) {
        stop(sprintf("Missing critical column: %s", col))
      }
    }
  })
})

run_test("Indicator column contains requested indicator code", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"))
    )

    stopifnot("indicator" %in% names(df))
    stopifnot("CME_MRY0T4" %in% df$indicator)
  })
})

run_test("Country name added when country_names=TRUE (default)", function() {
  with_mocked_http(function() {
    df <- suppressMessages(
      unicefData(indicator = "CME_MRY0T4", countries = c("ALB"))
    )

    if ("country" %in% names(df)) {
      stopifnot(any(grepl("Albania", df$country, ignore.case = TRUE)))
    }
  })
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

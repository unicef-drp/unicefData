# =============================================================================
# Error Condition Tests (ERR family)
#
# Gould (2001): "Test that your code does not work in circumstances where it
# should not." Validates parameter rejection and graceful error handling.
#
# No network access required (except ERR-04/08 which test API error paths).
# Uses helper-fixtures.R for path resolution (auto-loaded by testthat)
# =============================================================================

# FIXTURES_DIR provided by helper-fixtures.R
FIXTURES_DIR <- get_fixtures_dir()

# ===========================================================================
# Year parsing validation
# ===========================================================================

test_that("parse_year handles single integer", {
  skip_if_not_installed("unicefData")
  result <- unicefData:::parse_year(2020)
  expect_equal(result$start_year, 2020)
  expect_equal(result$end_year, 2020)
})

test_that("parse_year handles range string", {
  skip_if_not_installed("unicefData")
  result <- unicefData:::parse_year("2015:2023")
  expect_equal(result$start_year, 2015)
  expect_equal(result$end_year, 2023)
})

test_that("parse_year handles comma-separated string", {
  skip_if_not_installed("unicefData")
  result <- unicefData:::parse_year("2015,2018,2020")
  expect_equal(result$year_list, c(2015, 2018, 2020))
})

test_that("parse_year handles NULL", {
  skip_if_not_installed("unicefData")
  result <- unicefData:::parse_year(NULL)
  expect_null(result$start_year)
  expect_null(result$end_year)
})

# ===========================================================================
# DL-06: Duplicate detection
# ===========================================================================

test_that("DL-06: pinning fixture has no duplicates on key dims", {
  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)
  key_cols <- intersect(
    c("REF_AREA", "INDICATOR", "SEX", "WEALTH_QUINTILE", "TIME_PERIOD"),
    names(df)
  )
  n_total <- nrow(df)
  n_unique <- nrow(unique(df[key_cols]))
  expect_equal(n_total, n_unique, info = "No duplicate rows on key dimensions")
})

test_that("DL-06: multi-country fixture has no duplicates", {
  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_BRA_2020.csv"),
                 stringsAsFactors = FALSE)
  key_cols <- intersect(
    c("REF_AREA", "INDICATOR", "SEX", "WEALTH_QUINTILE", "TIME_PERIOD"),
    names(df)
  )
  expect_equal(nrow(df), nrow(unique(df[key_cols])))
})

test_that("DL-06: time series fixture has no duplicates", {
  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2015_2023.csv"),
                 stringsAsFactors = FALSE)
  key_cols <- intersect(
    c("REF_AREA", "INDICATOR", "SEX", "WEALTH_QUINTILE", "TIME_PERIOD"),
    names(df)
  )
  expect_equal(nrow(df), nrow(unique(df[key_cols])))
})

# ===========================================================================
# DATA-01: Data type validation
# ===========================================================================

test_that("DATA-01: OBS_VALUE is numeric across fixtures", {
  fixtures <- c("CME_MRY0T4_USA_2020_pinning.csv",
                "CME_MRY0T4_BRA_sex_2020.csv",
                "CME_multi_USA_2020.csv",
                "IM_MCV1_USA_BRA_2015_2023.csv")
  for (f in fixtures) {
    df <- read.csv(file.path(FIXTURES_DIR, f), stringsAsFactors = FALSE)
    expect_true(is.numeric(df$OBS_VALUE), info = paste(f, ": OBS_VALUE not numeric"))
  }
})

test_that("DATA-01: TIME_PERIOD is integer years", {
  fixtures <- c("CME_MRY0T4_USA_2020_pinning.csv",
                "CME_MRY0T4_USA_2015_2023.csv",
                "CME_MRY0T4_BRA_1990_2023.csv")
  for (f in fixtures) {
    df <- read.csv(file.path(FIXTURES_DIR, f), stringsAsFactors = FALSE)
    expect_true(is.numeric(df$TIME_PERIOD), info = paste(f, ": TIME_PERIOD not numeric"))
    expect_true(all(df$TIME_PERIOD == as.integer(df$TIME_PERIOD)),
                info = paste(f, ": TIME_PERIOD not integer"))
  }
})

test_that("DATA-01: REF_AREA is 3-character ISO3", {
  fixtures <- c("CME_MRY0T4_USA_2020_pinning.csv",
                "CME_MRY0T4_USA_BRA_2020.csv",
                "CME_MRY0T4_multi_2018_2023.csv")
  for (f in fixtures) {
    df <- read.csv(file.path(FIXTURES_DIR, f), stringsAsFactors = FALSE)
    expect_true(all(nchar(df$REF_AREA) == 3),
                info = paste(f, ": REF_AREA not 3 chars"))
  }
})

# ===========================================================================
# ERR-06: No indicator provided
# ===========================================================================

test_that("ERR-06: unicefData with no indicator errors", {
  skip_if_not_installed("unicefData")
  expect_error(unicefData::unicefData())
})

# ===========================================================================
# ERR: Mutually exclusive format options
# ===========================================================================

test_that("ERR: empty indicator string is handled", {
  skip_if_not_installed("unicefData")
  # Empty string should not succeed silently
  result <- tryCatch(
    unicefData::unicefData(indicator = ""),
    error = function(e) "error"
  )
  expect_true(result == "error" || (is.data.frame(result) && nrow(result) == 0))
})

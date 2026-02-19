# =============================================================================
# Deterministic / Offline Tests (DET-01 to DET-11, REGR-01)
#
# Gould (2001) Phase 6: Network-independent verification using frozen CSV
# fixtures. No skip_on_cran() — these run everywhere.
#
# Fixtures: tests/fixtures/deterministic/ (shared across Python/R/Stata)
# Uses helper-fixtures.R for path resolution (auto-loaded by testthat)
# =============================================================================

# FIXTURES_DIR and load_fixture() are provided by helper-fixtures.R
FIXTURES_DIR <- get_fixtures_dir()

load_fixture <- function(name) {
  read_fixture(name)
}

# ===========================================================================
# DET-01: Single indicator, all countries
# ===========================================================================

test_that("DET-01: single indicator fixture loads", {
  df <- load_fixture("CME_MRY0T4_all_2020.csv")
  expect_gt(nrow(df), 0)
})

test_that("DET-01: required SDMX columns present", {
  df <- load_fixture("CME_MRY0T4_all_2020.csv")
  for (col in c("REF_AREA", "INDICATOR", "TIME_PERIOD", "OBS_VALUE")) {
    expect_true(col %in% names(df), info = paste("Missing:", col))
  }
})

test_that("DET-01: single indicator, single year", {
  df <- load_fixture("CME_MRY0T4_all_2020.csv")
  expect_equal(length(unique(df$INDICATOR)), 1)
  expect_equal(unique(df$INDICATOR), "CME_MRY0T4")
  expect_equal(length(unique(df$TIME_PERIOD)), 1)
  expect_equal(unique(df$TIME_PERIOD), 2020)
})

test_that("DET-01: 100+ countries", {
  df <- load_fixture("CME_MRY0T4_all_2020.csv")
  expect_gt(length(unique(df$REF_AREA)), 100)
})

# ===========================================================================
# DET-02: Value pinning — USA U5MR 2020
# ===========================================================================

test_that("DET-02: USA total U5MR ≈ 6.4688", {
  df <- load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
  total <- df[df$REF_AREA == "USA" & df$SEX == "_T", ]
  expect_equal(nrow(total), 1)
  expect_equal(total$OBS_VALUE, 6.4688, tolerance = 0.01)
})

test_that("DET-02: male > female mortality", {
  df <- load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
  male <- df$OBS_VALUE[df$SEX == "M"]
  female <- df$OBS_VALUE[df$SEX == "F"]
  expect_gt(male, female)
})

test_that("DET-02: three sex categories", {
  df <- load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
  expect_setequal(unique(df$SEX), c("F", "M", "_T"))
})

# ===========================================================================
# DET-03: Multi-country (USA + BRA)
# ===========================================================================

test_that("DET-03: both USA and BRA present", {
  df <- load_fixture("CME_MRY0T4_USA_BRA_2020.csv")
  expect_true("USA" %in% df$REF_AREA)
  expect_true("BRA" %in% df$REF_AREA)
})

test_that("DET-03: 6 rows (2 countries × 3 sex)", {
  df <- load_fixture("CME_MRY0T4_USA_BRA_2020.csv")
  expect_equal(nrow(df), 6)
})

# ===========================================================================
# DET-04: Time series (USA 2015-2023)
# ===========================================================================

test_that("DET-04: 9 distinct years", {
  df <- load_fixture("CME_MRY0T4_USA_2015_2023.csv")
  years <- sort(unique(df$TIME_PERIOD))
  expect_equal(length(years), 9)
  expect_equal(min(years), 2015)
  expect_equal(max(years), 2023)
})

test_that("DET-04: declining U5MR trend", {
  df <- load_fixture("CME_MRY0T4_USA_2015_2023.csv")
  totals <- df[df$SEX == "_T", ]
  totals <- totals[order(totals$TIME_PERIOD), ]
  expect_gt(totals$OBS_VALUE[1], totals$OBS_VALUE[nrow(totals)])
})

test_that("DET-04: USA only", {
  df <- load_fixture("CME_MRY0T4_USA_2015_2023.csv")
  expect_equal(length(unique(df$REF_AREA)), 1)
  expect_equal(unique(df$REF_AREA), "USA")
})

# ===========================================================================
# DET-05: Sex disaggregation (BRA 2020)
# ===========================================================================

test_that("DET-05: M, F, _T sex values present", {
  df <- load_fixture("CME_MRY0T4_BRA_sex_2020.csv")
  expect_true("F" %in% df$SEX)
  expect_true("M" %in% df$SEX)
  expect_true("_T" %in% df$SEX)
})

test_that("DET-05: male > female (total wealth)", {
  df <- load_fixture("CME_MRY0T4_BRA_sex_2020.csv")
  male <- df$OBS_VALUE[df$SEX == "M" & df$WEALTH_QUINTILE == "_T"]
  female <- df$OBS_VALUE[df$SEX == "F" & df$WEALTH_QUINTILE == "_T"]
  expect_gt(male, female)
})

test_that("DET-05: wealth quintiles present", {
  df <- load_fixture("CME_MRY0T4_BRA_sex_2020.csv")
  wq <- unique(df$WEALTH_QUINTILE)
  expect_true("_T" %in% wq)
  expect_gt(length(wq), 1)
})

# ===========================================================================
# DET-06: Missing fixture → error
# ===========================================================================

test_that("DET-06: missing fixture raises error", {
  expect_error(load_fixture("NONEXISTENT_FILE_12345.csv"))
})

# ===========================================================================
# DET-07: Multi-indicator (USA 2020)
# ===========================================================================

test_that("DET-07: >= 3 distinct indicators", {
  df <- load_fixture("CME_multi_USA_2020.csv")
  expect_gte(length(unique(df$INDICATOR)), 3)
})

test_that("DET-07: USA only", {
  df <- load_fixture("CME_multi_USA_2020.csv")
  expect_equal(unique(df$REF_AREA), "USA")
})

# ===========================================================================
# DET-08: Nofilter (USA 2020)
# ===========================================================================

test_that("DET-08: nofilter fixture has data", {
  df <- load_fixture("CME_MRY0T4_USA_nofilter_2020.csv")
  expect_gt(nrow(df), 0)
  for (col in c("REF_AREA", "INDICATOR", "OBS_VALUE")) {
    expect_true(col %in% names(df))
  }
})

# ===========================================================================
# DET-09: Long time series (BRA 1990-2023)
# ===========================================================================

test_that("DET-09: spans 30+ years", {
  df <- load_fixture("CME_MRY0T4_BRA_1990_2023.csv")
  years <- unique(df$TIME_PERIOD)
  expect_lte(min(years), 1990)
  expect_gte(max(years), 2023)
  expect_gte(length(years), 30)
})

test_that("DET-09: BRA only", {
  df <- load_fixture("CME_MRY0T4_BRA_1990_2023.csv")
  expect_equal(unique(df$REF_AREA), "BRA")
})

test_that("DET-09: declining trend", {
  df <- load_fixture("CME_MRY0T4_BRA_1990_2023.csv")
  totals <- df[df$SEX == "_T", ]
  totals <- totals[order(totals$TIME_PERIOD), ]
  expect_gt(totals$OBS_VALUE[1], totals$OBS_VALUE[nrow(totals)])
})

# ===========================================================================
# DET-10: Multi-country time series (5 countries)
# ===========================================================================

test_that("DET-10: 5 countries", {
  df <- load_fixture("CME_MRY0T4_multi_2018_2023.csv")
  expect_equal(length(unique(df$REF_AREA)), 5)
})

test_that("DET-10: known countries", {
  df <- load_fixture("CME_MRY0T4_multi_2018_2023.csv")
  expected <- c("BRA", "ETH", "IND", "NGA", "USA")
  expect_setequal(unique(df$REF_AREA), expected)
})

test_that("DET-10: multiple years", {
  df <- load_fixture("CME_MRY0T4_multi_2018_2023.csv")
  expect_gte(length(unique(df$TIME_PERIOD)), 5)
})

# ===========================================================================
# DET-11: Cross-dataflow (IMMUNISATION — IM_MCV1)
# ===========================================================================

test_that("DET-11: vaccination indicator present", {
  df <- load_fixture("IM_MCV1_USA_BRA_2015_2023.csv")
  expect_true("IM_MCV1" %in% df$INDICATOR)
})

test_that("DET-11: USA and BRA present", {
  df <- load_fixture("IM_MCV1_USA_BRA_2015_2023.csv")
  expect_true("USA" %in% df$REF_AREA)
  expect_true("BRA" %in% df$REF_AREA)
})

test_that("DET-11: has VACCINE or AGE column (non-CME schema)", {
  df <- load_fixture("IM_MCV1_USA_BRA_2015_2023.csv")
  expect_true("VACCINE" %in% names(df) || "AGE" %in% names(df))
})

# ===========================================================================
# REGR-01a: Regression baseline — mortality
# ===========================================================================

test_that("REGR-01a: USA mortality baseline ≈ 6.4688", {
  df <- load_fixture("snap_mortality_baseline.csv")
  usa <- df[df$iso3 == "USA", ]
  expect_equal(nrow(usa), 1)
  expect_equal(usa$value, 6.4688, tolerance = 0.01)
})

test_that("REGR-01a: BRA mortality baseline ≈ 14.8719", {
  df <- load_fixture("snap_mortality_baseline.csv")
  bra <- df[df$iso3 == "BRA", ]
  expect_equal(nrow(bra), 1)
  expect_equal(bra$value, 14.8719, tolerance = 0.01)
})

# ===========================================================================
# REGR-01b: Regression baseline — vaccination
# ===========================================================================

test_that("REGR-01b: IND vaccination baseline ≈ 85", {
  df <- load_fixture("snap_vaccination_baseline.csv")
  ind <- df[df$iso3 == "IND", ]
  expect_equal(nrow(ind), 1)
  expect_equal(ind$value, 85, tolerance = 1)
})

test_that("REGR-01b: ETH vaccination baseline ≈ 62", {
  df <- load_fixture("snap_vaccination_baseline.csv")
  eth <- df[df$iso3 == "ETH", ]
  expect_equal(nrow(eth), 1)
  expect_equal(eth$value, 62, tolerance = 1)
})

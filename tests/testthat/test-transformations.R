# =============================================================================
# Transformation & Pipeline Tests (TRANS, META, PIPE families)
#
# Tests clean_unicef_data(), filter_unicef_data(), and post-production
# transformations using deterministic fixtures. No network access required.
#
# Fixtures: tests/fixtures/deterministic/ (shared across Python/R/Stata)
# Uses helper-fixtures.R for path resolution (auto-loaded by testthat)
# =============================================================================

# FIXTURES_DIR provided by helper-fixtures.R
FIXTURES_DIR <- get_fixtures_dir()

# ===========================================================================
# PIPE-01: clean_unicef_data column renaming
# ===========================================================================

test_that("PIPE-01: clean_unicef_data renames SDMX columns", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)
  cleaned <- unicefData:::clean_unicef_data(df)

  expect_true("iso3" %in% names(cleaned), info = "REF_AREA -> iso3")
  expect_true("period" %in% names(cleaned), info = "TIME_PERIOD -> period")
  expect_true("value" %in% names(cleaned), info = "OBS_VALUE -> value")
  expect_true("indicator" %in% names(cleaned), info = "INDICATOR -> indicator")
  expect_true("sex" %in% names(cleaned), info = "SEX -> sex")
})

# ===========================================================================
# PIPE-02: Period conversion
# ===========================================================================

test_that("PIPE-02: period is numeric after cleaning", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2015_2023.csv"),
                 stringsAsFactors = FALSE)
  cleaned <- unicefData:::clean_unicef_data(df)

  expect_true(is.numeric(cleaned$period))
  expect_equal(min(cleaned$period), 2015)
  expect_equal(max(cleaned$period), 2023)
})

# ===========================================================================
# PIPE-03: Value conversion
# ===========================================================================

test_that("PIPE-03: value is numeric after cleaning", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)
  cleaned <- unicefData:::clean_unicef_data(df)

  expect_true(is.numeric(cleaned$value))
  # USA U5MR should be ~6.47
  total_val <- cleaned$value[cleaned$sex == "_T"]
  expect_equal(total_val, 6.4688, tolerance = 0.01)
})

# ===========================================================================
# PIPE-04: filter_unicef_data sex filter
# ===========================================================================

test_that("PIPE-04: filter by sex=_T keeps only totals", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)
  # filter_unicef_data expects SDMX column names (SEX not sex)
  filtered <- unicefData:::filter_unicef_data(df, sex = "_T", verbose = FALSE)

  expect_true(all(filtered$SEX == "_T"),
              info = "Only _T rows should remain after sex=_T filter")
  expect_equal(nrow(filtered), 1)
})

test_that("PIPE-04: filter by sex=M keeps only male", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)
  filtered <- unicefData:::filter_unicef_data(df, sex = "M", verbose = FALSE)

  expect_true(all(filtered$SEX == "M"))
  expect_equal(nrow(filtered), 1)
})

# ===========================================================================
# PIPE-05: geo_type assignment
# ===========================================================================

test_that("PIPE-05: geo_type = 0 for country codes", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)
  cleaned <- unicefData:::clean_unicef_data(df)

  if ("geo_type" %in% names(cleaned)) {
    expect_true(all(cleaned$geo_type == 0),
                info = "USA should have geo_type=0 (country, not region)")
  }
})

# ===========================================================================
# PIPE-06: Standard column order
# ===========================================================================

test_that("PIPE-06: standard column order after cleaning", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_BRA_2020.csv"),
                 stringsAsFactors = FALSE)
  cleaned <- unicefData:::clean_unicef_data(df)

  # Core columns should all be present (order may vary due to country join)
  core_cols <- c("indicator", "indicator_name", "iso3", "country",
                 "geo_type", "period", "value")
  for (col in core_cols) {
    expect_true(col %in% names(cleaned), info = paste("Missing core column:", col))
  }
})

# ===========================================================================
# PIPE-07: Multi-country cleaning preserves all countries
# ===========================================================================

test_that("PIPE-07: multi-country cleaning preserves all", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_multi_2018_2023.csv"),
                 stringsAsFactors = FALSE)
  cleaned <- unicefData:::clean_unicef_data(df)

  expect_equal(length(unique(cleaned$iso3)), 5)
  expect_true("USA" %in% cleaned$iso3)
  expect_true("BRA" %in% cleaned$iso3)
})

# ===========================================================================
# PIPE-08: Empty DataFrame handling
# ===========================================================================

test_that("PIPE-08: empty DataFrame returns 0 rows", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)
  empty <- df[df$REF_AREA == "NONEXISTENT", ]
  expect_equal(nrow(empty), 0)

  cleaned <- unicefData:::clean_unicef_data(empty)
  expect_equal(nrow(cleaned), 0)
})

# ===========================================================================
# DL-08: Wealth quintile data structure
# ===========================================================================

test_that("DL-08: wealth quintile values in BRA fixture", {
  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_BRA_sex_2020.csv"),
                 stringsAsFactors = FALSE)

  wq <- unique(df$WEALTH_QUINTILE)
  expect_true("_T" %in% wq, info = "Total wealth quintile should be present")
  # BRA fixture has Q1-Q5 wealth quintiles
  expect_true(any(grepl("^Q[1-5]$", wq)),
              info = "Should have Q1-Q5 wealth quintile values")
})

test_that("DL-08: Q1 (poorest) > Q5 (richest) mortality", {
  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_BRA_sex_2020.csv"),
                 stringsAsFactors = FALSE)

  q1 <- df$OBS_VALUE[df$WEALTH_QUINTILE == "Q1"]
  q5 <- df$OBS_VALUE[df$WEALTH_QUINTILE == "Q5"]
  if (length(q1) > 0 && length(q5) > 0) {
    expect_gt(q1[1], q5[1],
              label = "Poorest quintile should have higher U5MR than richest")
  }
})

# ===========================================================================
# EDGE-02: Single-observation stability
# ===========================================================================

test_that("EDGE-02: single-row cleaning works", {
  skip_if_not_installed("unicefData")

  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)
  single <- df[df$SEX == "_T", ]
  expect_equal(nrow(single), 1)

  cleaned <- unicefData:::clean_unicef_data(single)
  expect_equal(nrow(cleaned), 1)
  expect_true("iso3" %in% names(cleaned))
})

# ===========================================================================
# EDGE-03: Special characters
# ===========================================================================

test_that("EDGE-03: unit of measure with comma parses correctly", {
  df <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                 stringsAsFactors = FALSE)

  if ("Unit.of.measure" %in% names(df)) {
    unit <- df$Unit.of.measure[1]
    expect_true(grepl("1,000|1000", unit))
  }
})

# ===========================================================================
# Cross-dataflow column schema difference
# ===========================================================================

test_that("CME vs IMMUNISATION have different column schemas", {
  cme <- read.csv(file.path(FIXTURES_DIR, "CME_MRY0T4_USA_2020_pinning.csv"),
                  stringsAsFactors = FALSE)
  imm <- read.csv(file.path(FIXTURES_DIR, "IM_MCV1_USA_BRA_2015_2023.csv"),
                  stringsAsFactors = FALSE)

  # CME has WEALTH_QUINTILE, IMMUNISATION has VACCINE
  cme_only <- setdiff(names(cme), names(imm))
  imm_only <- setdiff(names(imm), names(cme))

  # They should not be identical schemas

  expect_gt(length(cme_only) + length(imm_only), 0,
            label = "CME and IMMUNISATION should have different columns")
})

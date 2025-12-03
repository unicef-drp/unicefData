# 03_data_formats.R - Output Format Options
# ==========================================
#
# Demonstrates different output formats and data transformations.
# Matches: python/examples/03_data_formats.py
#
# Examples:
#   1. Long format (default)
#   2. Wide format (years as columns)
#   3. Wide indicators (indicators as columns)
#   4. Latest value per country
#   5. Most recent N values (MRV)

# Adjust path if running from examples directory
if (file.exists("../get_unicef.R")) {
  source("../get_unicef.R")
} else if (file.exists("R/get_unicef.R")) {
  source("R/get_unicef.R")
} else if (file.exists("unicefData/R/get_unicef.R")) {
  source("unicefData/R/get_unicef.R")
} else {
  stop("Could not find get_unicef.R")
}

cat("======================================================================\n")
cat("03_data_formats.R - Output Format Options\n")
cat("======================================================================\n")

COUNTRIES <- c("ALB", "USA", "BRA", "IND", "NGA")

# =============================================================================
# Example 1: Long Format (Default)
# =============================================================================
cat("\n--- Example 1: Long Format (Default) ---\n")
cat("One row per observation\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = COUNTRIES,
  start_year = 2020,
  format = "long"  # default
)

cat(sprintf("Shape: %d x %d\n", nrow(df), ncol(df)))
print(head(df[, c("iso3", "country", "period", "value")], 10))

# =============================================================================
# Example 2: Wide Format (Years as Columns)
# =============================================================================
cat("\n--- Example 2: Wide Format (Years as Columns) ---\n")
cat("Countries as rows, years as columns\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = COUNTRIES,
  start_year = 2020,
  format = "wide"
)

cat(sprintf("Shape: %d x %d\n", nrow(df), ncol(df)))
print(df)

# =============================================================================
# Example 3: Wide Indicators (Indicators as Columns)
# =============================================================================
cat("\n--- Example 3: Wide Indicators ---\n")
cat("Indicators as columns (for comparison)\n\n")

df <- get_unicef(
  indicator = c("CME_MRY0T4", "CME_MRM0"),
  countries = COUNTRIES,
  start_year = 2020,
  format = "wide_indicators"
)

cat(sprintf("Shape: %d x %d\n", nrow(df), ncol(df)))
print(head(df, 10))

# =============================================================================
# Example 4: Latest Value Per Country
# =============================================================================
cat("\n--- Example 4: Latest Value Per Country ---\n")
cat("Cross-sectional analysis (one value per country)\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = COUNTRIES,
  start_year = 2015,
  latest = TRUE
)

cat(sprintf("Shape: %d x %d (one row per country)\n", nrow(df), ncol(df)))
print(df[, c("iso3", "country", "period", "value")])

# =============================================================================
# Example 5: Most Recent N Values (MRV)
# =============================================================================
cat("\n--- Example 5: Most Recent 3 Values (MRV=3) ---\n")
cat("Keep only 3 most recent years per country\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA"),
  start_year = 2010,
  mrv = 3
)

cat(sprintf("Shape: %d x %d (expect 6 rows: 3 years x 2 countries)\n", nrow(df), ncol(df)))
print(df[, c("iso3", "period", "value")])

# =============================================================================
# Example 6: Default Behavior (All Countries, All Years, Totals)
# =============================================================================
cat("\n--- Example 6: Default Behavior ---\n")
cat("Only indicator specified -> All countries, all years, totals only\n\n")

# Note: Limiting to a short time range to avoid fetching too much data for the example
df <- get_unicef(
  indicator = "CME_MRY0T4",
  start_year = 2021
)

cat(sprintf("Shape: %d x %d\n", nrow(df), ncol(df)))
# Check that we have multiple countries and only Total sex/wealth if available
cols_to_show <- intersect(c("iso3", "country", "period", "value", "sex", "wealth_quintile"), names(df))
print(head(df[, cols_to_show], 10))

# =============================================================================
# Example 7: Wide Formats by Dimension
# =============================================================================
cat("\n--- Example 7: Wide Formats by Dimension ---\n")
cat("Pivoting by Sex, Wealth, Age, etc.\n\n")

# Wide by Wealth Quintile
cat("1. Wide by Wealth Quintile:\n")
# Note: Not all indicators have wealth disaggregation. 
# Using an indicator that typically does (e.g. Stunting or similar if CME doesn't in this context)
# But CME_MRY0T4 often has it in MICS. Let's try.
df_wealth <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = c("COL", "PER"),
  start_year = 2015,
  format = "wide_wealth"
)
print(head(df_wealth))

# Wide by Sex
cat("\n2. Wide by Sex:\n")
df_sex <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = c("ZWE", "KEN"),
  start_year = 2019,
  format = "wide_sex"
)
print(head(df_sex))

cat("\n======================================================================\n")
cat("Data Formats Complete!\n")
cat("======================================================================\n")

# ============================================================================
# 05_advanced_features.R - Advanced Features
# ============================================================================
#
# Demonstrates advanced query features.
# Matches: python/examples/05_advanced_features.py
#
# Examples:
#   1. Disaggregation by sex
#   2. Disaggregation by wealth quintile
#   3. Time series with specific year range
#   4. Multiple countries with latest values
#   5. Combining filters
# ============================================================================

# Source common setup (handles path resolution)
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
.script_dir <- if (length(.file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", .file_arg[1])))
} else {
  "."
}
source(file.path(.script_dir, "_setup.R"))
data_dir <- get_validation_data_dir()

cat(strrep("=", 70), "\n")
cat("05_advanced_features.R - Advanced Features\n")
cat(strrep("=", 70), "\n")

# ============================================================================
# Example 1: Disaggregation by Sex
# ============================================================================
cat("\n--- Example 1: Disaggregation by Sex ---\n")
cat("Under-5 mortality by sex\n\n")

df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA", "BRA"),
  start_year = 2020,
  sex = c("M", "F")  # Male and Female
)

print(df[, c("iso3", "period", "sex", "value")])

# ============================================================================
# Example 2: Disaggregation by Wealth
# ============================================================================
cat("\n--- Example 2: Disaggregation by Wealth ---\n")
cat("Stunting by wealth quintile\n\n")

df <- unicefData(
  indicator = "NT_ANT_HAZ_NE2_MOD",
  countries = c("IND", "NGA", "ETH"),
  start_year = 2015,
  # wealth_quintile is not a direct argument in unicefData, but handled via ... or specific logic
  # The refactored unicefData only exposes 'sex' explicitly.
  # We need to pass it via ... if supported, or filter afterwards.
  # However, the current unicefData implementation only accepts 'sex' as a named argument for filtering.
  # Let's try passing it and see if ... captures it, or if we need to filter manually.
  # Looking at unicefData definition: unicefData <- function(..., sex=NULL)
  # It seems it doesn't have ... passed to filter_unicef_data.
  # We might need to fetch all and filter.
)

# Filter manually for now as unicefData might not expose wealth_quintile directly yet
if (nrow(df) > 0 && "wealth_quintile" %in% names(df)) {
  df <- df[df$wealth_quintile %in% c("Q1", "Q5"), ]
  print(df[, c("iso3", "period", "wealth_quintile", "value")])
} else {
  cat("No wealth-disaggregated data available for these countries\n")
}

# ============================================================================
# Example 3: Time Series
# ============================================================================
cat("\n--- Example 3: Time Series ---\n")
cat("Mortality trends 2000-2023\n\n")

df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB"),
  year = "2000:2023"
)

cat("Time series:", nrow(df), "observations\n")
print(head(df[, c("period", "value")], 10))

# ============================================================================
# Example 4: Multiple Countries Latest
# ============================================================================
cat("\n--- Example 4: Multiple Countries Latest ---\n")
cat("Latest immunization rates for many countries\n\n")

# Get latest DPT3 coverage for multiple countries
df <- unicefData(
  indicator = "IM_DTP3",
  countries = c("AFG", "ALB", "USA", "BRA", "IND", "CHN", "NGA", "ETH"),
  start_year = 2015,
  latest = TRUE
)

print(df[, c("iso3", "country", "period", "value")])

# ============================================================================
# Example 5: Combining Filters
# ============================================================================
cat("\n--- Example 5: Combining Filters ---\n")
cat("Complex query with multiple filters\n\n")

df <- unicefData(
  indicator = c("CME_MRY0T4", "CME_MRM0"),  # Multiple indicators
  countries = c("ALB", "USA", "BRA"),        # Multiple countries
  year = 2020,                             # From 2020
  latest = TRUE,                              # Latest values only
  add_metadata = c("indicator_name")          # Include names
)

print(df[, c("iso3", "indicator", "indicator_name", "period", "value")])

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Advanced Features Complete!\n")
cat(strrep("=", 70), "\n")

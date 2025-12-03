# ============================================================================
# 04_metadata_options.R - Add Metadata to Data
# ============================================================================
#
# Demonstrates adding metadata columns to output.
# Matches: python/examples/04_metadata_options.py
#
# Examples:
#   1. Add region classification
#   2. Add income group
#   3. Add indicator name
#   4. Combine multiple metadata
#   5. Simplify output columns
# ============================================================================

# Adjust path if running from examples directory
if (file.exists("../unicef_api/get_unicef.R")) {
  source("../unicef_api/get_unicef.R")
} else if (file.exists("R/unicef_api/get_unicef.R")) {
  source("R/unicef_api/get_unicef.R")
} else if (file.exists("unicefData/R/get_unicef.R")) {
  source("unicefData/R/get_unicef.R")
} else {
  stop("Could not find get_unicef.R")
}

cat(strrep("=", 70), "\n")
cat("04_metadata_options.R - Add Metadata to Data\n")
cat(strrep("=", 70), "\n")

COUNTRIES <- c("ALB", "USA", "BRA", "IND", "NGA", "ETH", "CHN")

# ============================================================================
# Example 1: Add Region Classification
# ============================================================================
cat("\n--- Example 1: Add Region ---\n")
cat("UNICEF/World Bank regional classification\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = COUNTRIES,
  start_year = 2020,
  latest = TRUE,
  add_metadata = c("region")
)

cat("Columns:", paste(names(df), collapse = ", "), "\n")
print(df[, c("iso3", "country", "region", "value")])

# ============================================================================
# Example 2: Add Income Group
# ============================================================================
cat("\n--- Example 2: Add Income Group ---\n")
cat("World Bank income classification\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = COUNTRIES,
  start_year = 2020,
  latest = TRUE,
  add_metadata = c("income_group")
)

print(df[, c("iso3", "country", "income_group", "value")])

# ============================================================================
# Example 3: Add Indicator Name
# ============================================================================
cat("\n--- Example 3: Add Indicator Name ---\n")
cat("Full indicator description\n\n")

df <- get_unicef(
  indicator = c("CME_MRY0T4", "CME_MRM0"),
  countries = c("ALB", "USA"),
  start_year = 2020,
  latest = TRUE,
  add_metadata = c("indicator_name")
)

print(df[, c("iso3", "indicator", "indicator_name", "value")])

# ============================================================================
# Example 4: Multiple Metadata
# ============================================================================
cat("\n--- Example 4: Multiple Metadata ---\n")
cat("Combine region, income group, and indicator name\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = COUNTRIES,
  start_year = 2020,
  latest = TRUE,
  add_metadata = c("region", "income_group", "indicator_name")
)

cat("Columns:", paste(names(df), collapse = ", "), "\n")
print(head(df[, c("iso3", "region", "income_group", "value")]))

# ============================================================================
# Example 5: Simplify Output
# ============================================================================
cat("\n--- Example 5: Simplify Output ---\n")
cat("Keep only essential columns\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = COUNTRIES,
  start_year = 2020,
  simplify = TRUE
)

cat("Simplified columns:", paste(names(df), collapse = ", "), "\n")
print(head(df))

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Metadata Options Complete!\n")
cat(strrep("=", 70), "\n")

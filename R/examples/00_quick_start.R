# 00_quick_start.R - Quick Start Guide
# ======================================
#
# Demonstrates the basic unicefData() API with 5 simple examples.
# Matches: python/examples/00_quick_start.py
#
# Examples:
#   1. Single indicator, specific countries
#   2. Multiple indicators
#   3. Nutrition data
#   4. Immunization data
#   5. All countries (large download)

# Source common setup (handles path resolution)
# Get directory of this script
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
.script_dir <- if (length(.file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", .file_arg[1])))
} else {
  "."
}
source(file.path(.script_dir, "_setup.R"))
data_dir <- get_validation_data_dir()

cat("======================================================================\n")
cat("00_quick_start.R - UNICEF API Quick Start Guide\n")
cat("======================================================================\n")

# =============================================================================
# Example 1: Single Indicator - Under-5 Mortality
# =============================================================================
cat("\n--- Example 1: Single Indicator (Under-5 Mortality) ---\n")
cat("Indicator: CME_MRY0T4\n")
cat("Countries: Albania, USA, Brazil\n")
cat("Years: 2015-2023\n\n")

df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA", "BRA"),
  year = "2015:2023"
)

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
print(head(df[, c("iso3", "country", "period", "value")]))
write.csv(df, file.path(data_dir, "00_ex1_mortality.csv"), row.names = FALSE)

# =============================================================================
# Example 2: Multiple Indicators - Mortality Comparison
# =============================================================================
cat("\n--- Example 2: Multiple Indicators (Mortality) ---\n")
cat("Indicators: CME_MRM0 (Neonatal), CME_MRY0T4 (Under-5)\n")
cat("Years: 2020-2023\n\n")

df <- unicefData(
  indicator = c("CME_MRM0", "CME_MRY0T4"),
  countries = c("ALB", "USA", "BRA"),
  year = "2020:2023"
)

cat(sprintf("Result: %d rows\n", nrow(df)))
cat(sprintf("Indicators: %s\n", paste(unique(df$indicator), collapse = ", ")))
write.csv(df, file.path(data_dir, "00_ex2_multi_indicators.csv"), row.names = FALSE)

# =============================================================================
# Example 3: Nutrition - Stunting Prevalence
# =============================================================================
cat("\n--- Example 3: Nutrition (Stunting) ---\n")
cat("Indicator: NT_ANT_HAZ_NE2_MOD\n")
cat("Countries: Afghanistan, India, Nigeria\n")
cat("Years: 2015+\n\n")

df <- unicefData(
  indicator = "NT_ANT_HAZ_NE2_MOD",
  countries = c("AFG", "IND", "NGA"),
  year = "2015:2024"
)

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
write.csv(df, file.path(data_dir, "00_ex3_nutrition.csv"), row.names = FALSE)

# =============================================================================
# Example 4: Immunization - DTP3 Coverage
# =============================================================================
cat("\n--- Example 4: Immunization (DTP3) ---\n")
cat("Indicator: IM_DTP3\n")
cat("Countries: Nigeria, Kenya, South Africa\n")
cat("Years: 2015-2023\n\n")

df <- unicefData(
  indicator = "IM_DTP3",
  countries = c("NGA", "KEN", "ZAF"),
  year = "2015:2023"
)

cat(sprintf("Result: %d rows\n", nrow(df)))
write.csv(df, file.path(data_dir, "00_ex4_immunization.csv"), row.names = FALSE)

# =============================================================================
# Example 5: All Countries (Large Download)
# =============================================================================
cat("\n--- Example 5: All Countries ---\n")
cat("Indicator: CME_MRY0T4 (Under-5 mortality)\n")
cat("Countries: ALL\n")
cat("Years: 2020+\n\n")

df <- unicefData(
  indicator = "CME_MRY0T4",
  year = "2020:2024"
)

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
cat(sprintf("Years: %d - %d\n", min(df$period), max(df$period)))
write.csv(df, file.path(data_dir, "00_ex5_all_countries.csv"), row.names = FALSE)

cat("\n======================================================================\n")
# Example 6: Minimal Call (Only Indicator)
# =============================================================================
cat("\n--- Example 6: Minimal Call (Only Indicator) ---\n")
cat("Indicator: CME_MRY0T4\n")
cat("Result: All countries, all years, default filters (Totals)\n\n")

# Note: This can be a large download!
df <- unicefData(indicator = "CME_MRY0T4")

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
print(head(df))

# =============================================================================
# Example 7: Multiple Indicators Merged (Wide Format)
# =============================================================================
cat("\n--- Example 7: Multiple Indicators Merged (Wide Format) ---\n")
cat("Indicators: Under-5 (CME_MRY0T4) & Neonatal (CME_MRM0)\n")
cat("Format: wide_indicators (Merged side-by-side)\n\n")

df <- unicefData(
  indicator = c("CME_MRY0T4", "CME_MRM0"),
  countries = c("ALB", "USA", "BRA"),
  year = "2015",
  format = "wide_indicators"
)

cat(sprintf("Result: %d rows\n", nrow(df)))
print(head(df))

cat("\n======================================================================\n")
cat("Quick Start Complete!\n")
cat("======================================================================\n")

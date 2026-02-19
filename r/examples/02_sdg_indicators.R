# 02_sdg_indicators.R - SDG Indicator Examples
# ==============================================
#
# Demonstrates fetching SDG-related indicators across different domains.
# Matches: python/examples/02_sdg_indicators.py
#
# Examples:
#   1. Child Mortality (SDG 3.2)
#   2. Stunting/Wasting (SDG 2.2)
#   3. Education Completion (SDG 4.1)
#   4. Child Marriage (SDG 5.3)
#   5. WASH indicators (SDG 6)

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

cat("======================================================================\n")
cat("02_sdg_indicators.R - SDG Indicator Examples\n")
cat("======================================================================\n")

# Common parameters
COUNTRIES <- c("AFG", "BGD", "BRA", "ETH", "IND", "NGA", "PAK")

# =============================================================================
# Example 1: Child Mortality (SDG 3.2)
# =============================================================================
cat("\n--- Example 1: Child Mortality (SDG 3.2) ---\n")
cat("Under-5 and Neonatal mortality rates\n\n")

df <- unicefData(
  indicator = c("CME_MRY0T4", "CME_MRM0"),
  countries = COUNTRIES,
  year = "2015:2024"
)

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
cat(sprintf("Indicators: %s\n", paste(unique(df$indicator), collapse = ", ")))
write.csv(df, file.path(data_dir, "02_ex1_child_mortality.csv"), row.names = FALSE)

# =============================================================================
# Example 2: Nutrition (SDG 2.2)
# =============================================================================
cat("\n--- Example 2: Nutrition (SDG 2.2) ---\n")
cat("Stunting, Wasting, Overweight\n\n")

df <- unicefData(
  indicator = c("NT_ANT_HAZ_NE2_MOD", "NT_ANT_WHZ_NE2", "NT_ANT_WHZ_PO2_MOD"),
  countries = COUNTRIES,
  year = "2015:2024"
)

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
write.csv(df, file.path(data_dir, "02_ex2_nutrition.csv"), row.names = FALSE)

# =============================================================================
# Example 3: Education Completion (SDG 4.1)
# =============================================================================
cat("\n--- Example 3: Education (SDG 4.1) ---\n")
cat("Completion rates - Primary, Lower Secondary, Upper Secondary\n\n")

df <- unicefData(
  indicator = c("ED_CR_L1_UIS_MOD", "ED_CR_L2_UIS_MOD", "ED_CR_L3_UIS_MOD"),
  countries = COUNTRIES,
  year = "2015:2024",
  dataflow = "EDUCATION_UIS_SDG" # Explicit dataflow for reliability
)

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
write.csv(df, file.path(data_dir, "02_ex3_education.csv"), row.names = FALSE)

# =============================================================================
# Example 4: Child Marriage (SDG 5.3)
# =============================================================================
cat("\n--- Example 4: Child Marriage (SDG 5.3) ---\n")
cat("Women married before age 18\n\n")

df <- unicefData(
  indicator = "PT_F_20-24_MRD_U18_TND",
  countries = COUNTRIES,
  year = "2015:2024"
)

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
write.csv(df, file.path(data_dir, "02_ex4_child_marriage.csv"), row.names = FALSE)

# =============================================================================
# Example 5: WASH (SDG 6)
# =============================================================================
cat("\n--- Example 5: WASH (SDG 6) ---\n")
cat("Safely managed water and sanitation\n\n")

df <- unicefData(
  indicator = c("WS_PPL_W-SM", "WS_PPL_S-SM"),
  countries = COUNTRIES,
  year = "2015:2024"
)

cat(sprintf("Result: %d rows, %d countries\n", nrow(df), length(unique(df$iso3))))
write.csv(df, file.path(data_dir, "02_ex5_wash.csv"), row.names = FALSE)

cat("\n======================================================================\n")
cat("SDG Indicators Complete!\n")
cat("======================================================================\n")

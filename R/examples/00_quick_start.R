# 00_quick_start.R
# Quick start guide for unicef_api R package
# 
# This demonstrates the unified get_unicef() API that is consistent
# with the Python package.

cat("========================================\n")
cat("unicefdata R Package - Quick Start\n")
cat("========================================\n\n")

# Set working directory
setwd("D:/jazevedo/GitHub/unicefData")

# Load required packages
cat("Loading packages...\n")
suppressPackageStartupMessages({
  library(httr)
  library(xml2)
  library(tibble)
  library(readr)
  library(dplyr)
  library(memoise)
  library(purrr)
  library(countrycode)
})

# Source the R functions
cat("Sourcing R functions...\n")
source("R/get_unicef.R")

# =============================================================================
# Example 1: Basic Usage - Fetch Under-5 Mortality
# =============================================================================
cat("\n--- Example 1: Basic Usage ---\n")
cat("Fetching under-5 mortality for Albania, USA, and Brazil (2015-2023)\n\n")

df <- get_unicef(
  indicator = "CME_MRY0T4",
  dataflow = "CME",
  countries = c("ALB", "USA", "BRA"),
  start_year = 2015,
  end_year = 2023
)

if (nrow(df) > 0) {
  cat(sprintf("✅ Downloaded %d observations\n", nrow(df)))
  cat("\nSample data:\n")
  print(head(df[, c("iso3", "country", "indicator", "period", "value")]))
} else {
  cat("⚠️ No data returned\n")
}

# =============================================================================
# Example 2: Multiple Indicators
# =============================================================================
cat("\n--- Example 2: Multiple Indicators ---\n")
cat("Fetching neonatal + under-5 mortality for 2020-2023\n\n")

df <- get_unicef(
  indicator = c("CME_MRM0", "CME_MRY0T4"),
  dataflow = "CME",
  start_year = 2020,
  end_year = 2023
)

if (nrow(df) > 0) {
  cat(sprintf("✅ Downloaded %d observations\n", nrow(df)))
  cat(sprintf("   Indicators: %s\n", paste(unique(df$indicator), collapse = ", ")))
  cat(sprintf("   Countries: %d\n", length(unique(df$iso3))))
}

# =============================================================================
# Example 3: List Available Dataflows
# =============================================================================
cat("\n--- Example 3: List Available Dataflows ---\n")

flows <- list_dataflows()
cat(sprintf("✅ Found %d dataflows\n\n", nrow(flows)))
cat("Key dataflows for child indicators:\n")
key_flows <- c("CME", "NUTRITION", "EDUCATION_UIS_SDG", "IMMUNISATION", "MNCH")
print(flows %>% filter(id %in% key_flows))

# =============================================================================
# Example 4: Nutrition Data
# =============================================================================
cat("\n--- Example 4: Nutrition Data ---\n")
cat("Fetching stunting prevalence\n\n")

df <- get_unicef(
  indicator = "NT_ANT_HAZ_NE2_MOD",
  dataflow = "NUTRITION",
  start_year = 2015
)

if (nrow(df) > 0) {
  cat(sprintf("✅ Downloaded %d observations\n", nrow(df)))
  cat(sprintf("   Countries: %d\n", length(unique(df$iso3))))
  cat(sprintf("   Years: %s\n", paste(range(df$period), collapse = "-")))
}

# =============================================================================
# Example 5: Legacy Syntax (Backward Compatible)
# =============================================================================
cat("\n--- Example 5: Legacy Syntax (still works) ---\n")

df <- get_unicef(
  flow = "CME",  # legacy
  key = "CME_MRY0T4",  # legacy
  start_period = 2020,  # legacy
  end_period = 2023  # legacy
)

if (nrow(df) > 0) {
  cat(sprintf("✅ Legacy syntax works! Downloaded %d observations\n", nrow(df)))
}

cat("\n========================================\n")
cat("Quick start complete!\n")
cat("========================================\n")

# 01_indicator_discovery.R - Discover Available Indicators
# ==========================================================
#
# Demonstrates how to search and discover UNICEF indicators.
# Matches: python/examples/01_indicator_discovery.py
#
# Examples:
#   1. List all categories
#   2. Search by keyword
#   3. Search within category
#   4. Get indicator info
#   5. List dataflows

# Adjust path if running from examples directory
if (file.exists("../unicef_api/get_unicef.R")) {
  source("../unicef_api/get_unicef.R")
} else if (file.exists("R/unicef_api/get_unicef.R")) {
  source("R/unicef_api/get_unicef.R")
} else if (file.exists("unicefData/R/unicef_api/get_unicef.R")) {
  source("unicefData/R/unicef_api/get_unicef.R")
} else {
  stop("Could not find get_unicef.R")
}

# source("../indicator_registry.R") # This file might not exist or need similar handling

cat("======================================================================\n")
cat("01_indicator_discovery.R - Discover UNICEF Indicators\n")
cat("======================================================================\n")

# =============================================================================
# Example 1: List All Categories
# =============================================================================
cat("\n--- Example 1: List All Categories ---\n\n")

# list_categories() is not available in the R client yet.
# Using list_unicef_flows() instead which lists dataflows (categories)
flows <- list_unicef_flows()
print(head(flows))

# =============================================================================
# Example 2: Search by Keyword
# =============================================================================
cat("\n--- Example 2: Search by Keyword ---\n")
cat("Searching for 'mortality'...\n\n")

# search_indicators() is not available in the R client yet.
# We can search within the flows or implement a basic search
mortality_flows <- flows[grep("mortality", flows$name, ignore.case = TRUE), ]
print(mortality_flows)

# =============================================================================
# Example 3: Search Within Category
# =============================================================================
cat("\n--- Example 3: Search Within Category ---\n")
cat("Skipping codelist fetch as it requires specific flow/dimension knowledge that varies.\n")
cat("Use list_unicef_flows() to see available dataflows.\n")

# GLOBAL_DATAFLOW is usually more reliable for listing indicators
# global_indicators <- list_unicef_codelist("GLOBAL_DATAFLOW", "INDICATOR")
# print(head(global_indicators))

# search_indicators(category = "NUTRITION", limit = 5)

# =============================================================================
# Example 4: Get Indicator Info
# =============================================================================
cat("\n--- Example 4: Get Indicator Info ---\n")
cat("Getting info for CME_MRY0T4...\n\n")

# get_indicator_info() is not available in the R client yet.
# We can use detect_dataflow() to find where it belongs
flow <- detect_dataflow("CME_MRY0T4")
cat(sprintf("Indicator CME_MRY0T4 belongs to dataflow: %s\n", flow))

# info <- get_indicator_info("CME_MRY0T4")
# if (!is.null(info)) {
#   cat(sprintf("Code: %s\n", info$code))
#   cat(sprintf("Name: %s\n", info$name))
#   cat(sprintf("Category: %s\n", info$category))
# }

# =============================================================================
# Example 5: Auto-detect Dataflow
# =============================================================================
cat("\n--- Example 5: Auto-detect Dataflow ---\n")
cat("Detecting dataflows for various indicators...\n\n")

indicators <- c(
  "CME_MRY0T4",              # Child Mortality
  "NT_ANT_HAZ_NE2_MOD",      # Nutrition
  "ED_CR_L1_UIS_MOD",        # Education (needs override)
  "PT_F_20-24_MRD_U18_TND"   # Child Marriage (needs override)
)

for (ind in indicators) {
  # Use detect_dataflow() instead of get_dataflow_for_indicator()
  df <- detect_dataflow(ind)
  cat(sprintf("  %s -> %s\n", ind, df))
}

# =============================================================================
# Example 6: List Available Dataflows
# =============================================================================
cat("\n--- Example 6: List Available Dataflows ---\n\n")

# Use list_unicef_flows() instead of list_dataflows()
flows <- list_unicef_flows()
cat(sprintf("Total dataflows: %d\n", nrow(flows)))
cat("\nKey dataflows:\n")
key_flows <- c("CME", "NUTRITION", "EDUCATION_UIS_SDG", "IMMUNISATION", "MNCH", "PT", "PT_CM", "PT_FGM")
print(flows[flows$id %in% key_flows, c("id", "agency")])

cat("\n======================================================================\n")
cat("Indicator Discovery Complete!\n")
cat("======================================================================\n")

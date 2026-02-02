#!/usr/bin/env Rscript
# R_vs_Python_diagnostic.R
# Deep dive into why R gets 404 while Python gets data

suppressPackageStartupMessages({
    library(unicefData)
    library(httr)
})

cat("\n=== R vs Python: Deep Diagnostic ===\n\n")

# Check how R constructs the API request
cat("Step 1: Check metadata mapping\n")
cat("------------------------------------------------------------\n")

# Look at what dataflow R detects for each indicator
check_dataflow <- function(indicator_code) {
    cat(sprintf("\nIndicator: %s\n", indicator_code))
    
    # Try to access the indicator registry
    if (exists("get_indicator_dataflow", mode="function")) {
        df <- get_indicator_dataflow(indicator_code)
        cat(sprintf("  Detected dataflow: %s\n", df))
    } else {
        cat("  (Could not access get_indicator_dataflow)\n")
    }
    
    # Check if metadata exists
    if (file.exists("../R/metadata/current/unicef_indicators_metadata.yaml")) {
        cat("  ✓ Metadata file exists\n")
    } else {
        cat("  ✗ Metadata file NOT found\n")
    }
}

check_dataflow("COD_DENGUE")
check_dataflow("MG_NEW_INTERNAL_DISP")

cat("\n\nStep 2: Trace API request URL construction\n")
cat("------------------------------------------------------------\n")

# Enable httr debugging to see actual requests
cat("\nAttempting to fetch COD_DENGUE with verbose httr output:\n")
cat("(This will show the exact URL being requested)\n\n")

set_config(verbose())

tryCatch({
    result <- unicefData(
        indicator = "COD_DENGUE",
        countries = "USA",
        year = "2020"
    )
    cat("\nResult:", nrow(result), "rows\n")
}, error = function(e) {
    cat("\nError class:", class(e), "\n")
    cat("Error message:", e$message, "\n")
})

set_config(reset_config())

cat("\n=== End Diagnostic ===\n\n")

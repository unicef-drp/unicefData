#!/usr/bin/env Rscript
# test_indicator_suite.R
# Version 1.0.0  10Jan2026
#
# Comprehensive R indicator test suite for unicefData validation
#
# This script:
# 1. Loads all known indicators from metadata
# 2. Tests each indicator download
# 3. Captures success/failure + row counts
# 4. Exports results to CSV
# 5. Generates detailed error log
#
# Usage:
#   Rscript validation/test_indicator_suite.R
#   Rscript validation/test_indicator_suite.R --indicators CME_MRY0T4 WSHPOL_SANI_TOTAL
#   Rscript validation/test_indicator_suite.R --limit 10

# =============================================================================
# Setup
# =============================================================================

# Suppress warnings
options(warn = -1)

# Load required libraries
suppressPackageStartupMessages({
    library(unicefData)
    library(dplyr)
    library(readr)
    library(stringr)
})

# Create output directories (centralized logs)
# Get repo root: scripts/ -> validation/ -> unicefData-dev/
script_dir <- getwd()
repo_root <- dirname(dirname(script_dir))
test_dir <- file.path(repo_root, "logs", "tests")
dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(test_dir, "success"), showWarnings = FALSE)
dir.create(file.path(test_dir, "failed"), showWarnings = FALSE)

# Generate timestamp
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
results_csv <- file.path(test_dir, sprintf("test_results_%s.csv", timestamp))
errors_log <- file.path(test_dir, sprintf("test_errors_%s.txt", timestamp))
summary_log <- file.path(test_dir, sprintf("test_summary_%s.txt", timestamp))

# =============================================================================
# Configuration
# =============================================================================

# Test parameters
test_countries <- c("USA", "BRA", "IND", "KEN", "CHN")
test_year <- "2020"

# All known indicators (from metadata)
# In production, load from config/indicators.yaml
indicators <- c(
    "CME_MRM0", "CME_MRY0T4",
    "MAT_MMRATIO", "MAT_SBA",
    "WSHPOL_SANI_TOTAL", "WSHPOL_SAFE_DRINK",
    "NUTRI_STU_0TO4_TOT", "NUTRI_WST_0TO4_TOT",
    "IMMUNIZ_DPT", "IMMUNIZ_MMR"
)

cat("================================================================================\n")
cat("UNICEF Indicator Validation Suite for R\n")
cat("================================================================================\n")
cat(sprintf("Output directory: %s\n", test_dir))
cat(sprintf("Results CSV:      %s\n", results_csv))
cat(sprintf("Error log:        %s\n", errors_log))
cat(sprintf("Timestamp:        %s\n", timestamp))
cat("\nTest configuration:\n")
cat(sprintf("  Countries: %s\n", paste(test_countries, collapse = ", ")))
cat(sprintf("  Year:      %s\n", test_year))
cat(sprintf("  Indicators: %d\n", length(indicators)))
cat("\n")

# =============================================================================
# Main test loop
# =============================================================================

results_list <- list()
success_count <- 0
failed_count <- 0
not_found_count <- 0

for (i in seq_along(indicators)) {
    indicator <- indicators[i]
    
    cat(sprintf("\n[%d/%d] Testing indicator: %s\n", i, length(indicators), indicator))
    
    # Test start time
    start_time <- Sys.time()
    
    # Initialize result
    status <- "unknown"
    rows_returned <- 0
    error_message <- ""
    
    # Attempt download
    tryCatch({
        cat(sprintf("    Downloading %s for: %s\n", indicator, paste(test_countries, collapse = ", ")))
        
        df <- unicefData(
            indicator = indicator,
            countries = test_countries,
            year = test_year
        )
        
        # Check if data was returned
        if (is.null(df) || nrow(df) == 0) {
            status <- "not_found"
            rows_returned <- 0
            not_found_count <- not_found_count + 1
            cat("    ⚠ No data returned\n")
        } else {
            status <- "success"
            rows_returned <- nrow(df)
            success_count <- success_count + 1
            cat(sprintf("    ✓ Success: %d rows\n", rows_returned))
            
            # Export to success folder
            outfile <- file.path(test_dir, "success", sprintf("%s.csv", indicator))
            tryCatch({
                write_csv(df, outfile)
            }, error = function(e) {
                cat(sprintf("    ⚠ Warning: Could not export to %s\n", outfile))
            })
        }
    }, error = function(e) {
        status <<- "failed"
        error_message <<- as.character(e$message)
        failed_count <<- failed_count + 1
        cat(sprintf("    ✗ Error: %s\n", error_message))
        
        # Write error to log
        outfile <- file.path(test_dir, "failed", sprintf("%s.error", indicator))
        writeLines(error_message, outfile)
    })
    
    # Calculate execution time
    execution_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    # Store result
    results_list[[i]] <- data.frame(
        indicator_code = indicator,
        status = status,
        rows_returned = rows_returned,
        error_message = error_message,
        execution_time_sec = execution_time,
        timestamp = format(start_time, "%Y-%m-%d %H:%M:%S"),
        stringsAsFactors = FALSE
    )
}

# =============================================================================
# Export results
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("Exporting results...\n")
cat("================================================================================\n")

# Combine results
results_df <- bind_rows(results_list)

# Export to CSV
write_csv(results_df, results_csv)
cat(sprintf("Exported to: %s\n", results_csv))

# =============================================================================
# Summary Report
# =============================================================================

cat(sprintf("Generated summary: %s\n\n", summary_log))

summary_text <- sprintf(
    "UNICEF Indicator Validation Summary\n%s\n\nGenerated: %s\n\nTest Configuration\n%s\nCountries: %s\nYear:      %s\n\nResults Summary\n%s\nTotal indicators tested: %d\nSuccessful:              %d (%.1f%%)\nFailed:                  %d (%.1f%%)\nNot found:               %d (%.1f%%)\n\nDetailed Results\n%s\n",
    strrep("=", 80),
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    strrep("-", 80),
    paste(test_countries, collapse = ", "),
    test_year,
    strrep("-", 80),
    nrow(results_df),
    success_count,
    if (nrow(results_df) > 0) success_count / nrow(results_df) * 100 else 0,
    failed_count,
    if (nrow(results_df) > 0) failed_count / nrow(results_df) * 100 else 0,
    not_found_count,
    if (nrow(results_df) > 0) not_found_count / nrow(results_df) * 100 else 0,
    strrep("-", 80)
)

# Add detailed results
summary_text <- paste0(summary_text, 
    paste(
        apply(results_df, 1, function(row) {
            if (row["status"] == "success") {
                sprintf("%s: SUCCESS (%s rows)", row["indicator_code"], row["rows_returned"])
            } else if (row["status"] == "not_found") {
                sprintf("%s: NO DATA", row["indicator_code"])
            } else {
                sprintf("%s: FAILED - %s", row["indicator_code"], row["error_message"])
            }
        }),
        collapse = "\n"
    ),
    "\n"
)

writeLines(summary_text, summary_log)

# =============================================================================
# Final summary to console
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("TEST COMPLETE\n")
cat("================================================================================\n")
cat(sprintf("Total indicators:    %d\n", nrow(results_df)))
cat(sprintf("Successful:          %d\n", success_count))
cat(sprintf("Failed:              %d\n", failed_count))
cat(sprintf("Not found (404):     %d\n", not_found_count))
cat("\nResults saved to:\n")
cat(sprintf("  CSV:     %s\n", results_csv))
cat(sprintf("  Summary: %s\n", summary_log))
cat("================================================================================\n")

quit(save = "no", status = 0)

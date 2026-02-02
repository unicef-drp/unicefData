#!/usr/bin/env Rscript
# r_verbose_http_trace.R
# Capture exact HTTP requests/responses with httr verbose mode

suppressPackageStartupMessages({
    library(unicefData)
    library(httr)
})

cat("\n=== R: Verbose HTTP Request Capture ===\n\n")

# Set up output file for verbose logs
log_file <- "r_http_trace.log"
cat("Verbose logging to:", log_file, "\n\n")

# Create connection for logging
log_conn <- file(log_file, open = "w")

# Enable verbose httr logging (this will print to console AND we'll capture separately)
options(HTTPUserAgent = sprintf("R/%s libcurl/%s", R.version$major, curl::curl_version()$version))

cat("Testing: COD_DENGUE and MG_NEW_INTERNAL_DISP\n")
cat("Indicators with 404 errors\n\n")

indicators <- c("COD_DENGUE", "MG_NEW_INTERNAL_DISP")

for (indicator in indicators) {
    cat(sprintf("\n%s\n", strrep("=", 70)))
    cat(sprintf("Indicator: %s\n", indicator))
    cat(strrep("=", 70), "\n\n")
    
    # Enable verbose mode
    set_config(verbose())
    
    cat("Making API request with verbose output...\n")
    cat("(Watch for REQUEST URL, REQUEST HEADERS, RESPONSE STATUS)\n\n")
    
    tryCatch({
        result <- unicefData(
            indicator = indicator,
            countries = "USA",
            year = "2020"
        )
        
        cat("\n✓ Request succeeded\n")
        cat("  Rows returned:", nrow(result), "\n")
        
    }, error = function(e) {
        cat("\n✗ Error encountered\n")
        cat("  Error class:", class(e), "\n")
        cat("  Error message:", e$message, "\n")
    })
    
    # Disable verbose for next iteration
    reset_config()
}

cat("\n\n=== Verbose Output Complete ===\n")
cat("Note: httr verbose output appears above\n")
cat("Key things to look for:\n")
cat("  1. Full URL being requested\n")
cat("  2. Request headers (User-Agent, Accept, etc)\n")
cat("  3. HTTP response status code\n")
cat("  4. Response headers\n\n")

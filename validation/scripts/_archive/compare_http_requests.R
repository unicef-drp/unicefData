#!/usr/bin/env Rscript
# compare_http_requests.R
# Master diagnostic: Capture and compare HTTP requests across Python and R
# Stata trace is optional due to complexity

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║  HTTP REQUEST COMPARISON: Python vs R                             ║\n")
cat("║  Indicators: COD_DENGUE, MG_NEW_INTERNAL_DISP (404 errors in R)  ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Step 1: Run R with verbose HTTP logging
cat("STEP 1: Capturing R HTTP requests with httr verbose mode\n")
cat("─" %+% strrep("─", 68), "\n\n")

suppressPackageStartupMessages({
    library(unicefData)
    library(httr)
})

r_trace_results <- list()

indicators <- c("COD_DENGUE", "MG_NEW_INTERNAL_DISP")

for (indicator in indicators) {
    cat(sprintf("\nTesting: %s\n", indicator))
    cat(strrep("─", 50), "\n")
    
    # Create a custom error/output capture
    output_capture <- capture.output({
        set_config(verbose())
        
        tryCatch({
            result <- unicefData(
                indicator = indicator,
                countries = "USA",
                year = "2020"
            )
            
            status <- "SUCCESS"
            rows <- nrow(result)
            error_msg <- NULL
            
        }, error = function(e) {
            status <<- "ERROR"
            rows <<- 0
            error_msg <<- e$message
        })
        
        reset_config()
    }, type = "message")
    
    # Print captured output (contains httr verbose info)
    if (length(output_capture) > 0) {
        # Filter for URL-related lines
        url_lines <- output_capture[grepl("URL|Host|Request|Status|GET|POST", output_capture, ignore.case=TRUE)]
        if (length(url_lines) > 0) {
            cat("Captured request details:\n")
            for (line in url_lines) {
                cat(sprintf("  %s\n", line))
            }
        }
    }
    
    cat(sprintf("Result: %s (%d rows)\n", status, rows))
    
    r_trace_results[[indicator]] <- list(
        status = status,
        rows = rows,
        error = error_msg
    )
}

cat("\n\n")
cat("STEP 2: Capturing Python HTTP requests\n")
cat("─" %+% strrep("─", 68), "\n\n")

# Run Python with verbose logging
python_cmd <- sprintf(
    'cd "%s" && python python_verbose_http_trace.py',
    getwd()
)

python_output <- tryCatch({
    system(python_cmd, intern = TRUE)
}, error = function(e) {
    cat("Could not run Python script:", e$message, "\n")
    NULL
})

if (!is.null(python_output)) {
    # Look for URL-like patterns in output
    url_patterns <- python_output[grepl("http|sdmx|URL|GET|POST", python_output, ignore.case=TRUE)]
    if (length(url_patterns) > 0) {
        cat("Key request details from Python:\n")
        for (line in url_patterns) {
            cat(sprintf("  %s\n", line))
        }
    }
}

cat("\n\n")
cat("STEP 3: Summary and Analysis\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")

cat("\nR Results:\n")
for (indicator in indicators) {
    result <- r_trace_results[[indicator]]
    status_icon <- if (result$status == "SUCCESS") "✅" else "❌"
    cat(sprintf("  %s %s: %d rows\n", status_icon, indicator, result$rows))
    if (!is.null(result$error)) {
        cat(sprintf("     Error: %s\n", substr(result$error, 1, 80)))
    }
}

cat("\nKey Comparison Points:\n")
cat("  □ User-Agent header\n")
cat("    ├─ R: libcurl/7.x r-curl/5.x R/4.5.x\n")
cat("    └─ Python: python-requests/2.31.0\n\n")
cat("  □ Base URL and dimensions\n")
cat("    ├─ Expected: https://sdmx.unicef.org/rest/data/DATAFLOW/.../INDICATOR\n")
cat("    └─ Compare actual URLs captured above\n\n")
cat("  □ Query parameters\n")
cat("    ├─ startPeriod/endPeriod format\n")
cat("    ├─ Country parameter encoding\n")
cat("    └─ Dimension ordering\n\n")
cat("  □ Response handling\n")
cat("    ├─ R HTTP status detection\n")
cat("    ├─ Error classification (404 vs not_found)\n")
cat("    └─ Retry behavior\n")

cat("\n╚════════════════════════════════════════════════════════════════════╝\n\n")

cat("Next Steps:\n")
cat("  1. Review captured URLs above\n")
cat("  2. Compare R vs Python request construction\n")
cat("  3. Test URLs directly with curl if different\n")
cat("  4. Check metadata configuration for each indicator\n\n")

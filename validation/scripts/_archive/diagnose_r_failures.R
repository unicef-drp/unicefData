#!/usr/bin/env Rscript
# diagnose_r_failures.R
# Diagnostic script to investigate why COD_DENGUE and MG_NEW_INTERNAL_DISP fail in R

suppressPackageStartupMessages({
    library(unicefData)
    library(dplyr)
})

cat("\n=== R Dataflow Diagnostic ===\n\n")

# Environment info
cat("R Environment:\n")
cat("  R Version:", R.version$version.string, "\n")
cat("  Working Directory:", getwd(), "\n")
cat("  unicefData Package Version:", as.character(packageVersion('unicefData')), "\n\n")

# Test setup
indicators_to_test <- c("COD_DENGUE", "MG_NEW_INTERNAL_DISP")
test_countries <- "USA"
test_year <- "2020"

cat("Test Configuration:\n")
cat("  Indicators:", paste(indicators_to_test, collapse=", "), "\n")
cat("  Countries:", test_countries, "\n")
cat("  Year:", test_year, "\n\n")

# Diagnostic function
test_indicator <- function(indicator_code) {
  cat(sprintf("Testing: %s\n", indicator_code))
  cat(strrep("-", 60), "\n")
  
  tryCatch({
    cat("  [1] Calling unicefData()...\n")
    result <- unicefData(
      indicator = indicator_code,
      countries = test_countries,
      year = test_year
    )
    
    cat("  [2] Result received\n")
    cat("      - Class:", class(result), "\n")
    cat("      - Is NULL:", is.null(result), "\n")
    
    if (!is.null(result)) {
      cat("      - nrow():", nrow(result), "\n")
      cat("      - ncol():", ncol(result), "\n")
      cat("      - Column names:", paste(names(result), collapse = ", "), "\n")
      
      if (nrow(result) > 0) {
        cat("      - First row:\n")
        print(head(result, 1))
        cat("  ✅ SUCCESS: Data retrieved\n")
        return(list(status="success", rows=nrow(result)))
      } else {
        cat("  ⚠️ NOT_FOUND: NULL or empty result\n")
        return(list(status="not_found", rows=0))
      }
    } else {
      cat("  ⚠️ NOT_FOUND: Result is NULL\n")
      return(list(status="not_found", rows=0))
    }
    
  }, error = function(e) {
    cat("  ❌ ERROR:\n")
    cat("      Message:", e$message, "\n")
    cat("      Call:", as.character(e$call), "\n")
    return(list(status="error", error_msg=e$message))
  }, warning = function(w) {
    cat("  ⚠️ WARNING: ", w$message, "\n")
  })
  
  cat("\n")
}

# Run diagnostics
for (indicator in indicators_to_test) {
  test_indicator(indicator)
}

cat("=== Diagnostic Complete ===\n\n")

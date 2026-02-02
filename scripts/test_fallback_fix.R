#!/usr/bin/env Rscript
# Test if the fallback sequences lazy loading fix works

# Set working directory to package root
setwd("C:\\GitHub\\myados\\unicefData-dev")

# Load the package from source so internal helpers are available
if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("Please install devtools to run this test")
}
devtools::load_all(".", export_all = FALSE)

# Test 1: Check if fallback sequences can be loaded at runtime
cat("[TEST] Attempting to load fallback sequences at runtime...\n")

# Try to access the fallback sequences loading function
# There are two implementations - try both
fallback <- NULL
tryCatch({
  # Try the indicator_registry.R implementation first
  fallback <- unicefData:::.load_fallback_sequences()
  cat("[INFO] Using .load_fallback_sequences() from indicator_registry.R\n")
}, error = function(e) {
  # If that fails, try the unicef_core.R implementation
  tryCatch({
    fallback <<- unicefData:::.get_fallback_sequences()
    cat("[INFO] Using .get_fallback_sequences() from unicef_core.R\n")
  }, error = function(e2) {
    cat("[ERROR] Could not load fallback sequences using either method:\n")
    cat("  - .load_fallback_sequences():", e$message, "\n")
    cat("  - .get_fallback_sequences():", e2$message, "\n")
  })
})

if (is.null(fallback)) {
  cat("[ERROR] Fallback sequences is NULL!\n")
} else {
  cat(sprintf("[SUCCESS] Loaded fallback sequences with %d prefixes\n", length(fallback)))
  cat(sprintf("[DEBUG] Prefixes: %s\n", paste(head(names(fallback), 10), collapse=", ")))
  
  # Check if IM prefix is present
  if ("IM" %in% names(fallback)) {
    cat("[SUCCESS] IM prefix found in fallback sequences\n")
    cat(sprintf("[DEBUG] IM dataflows: %s\n", paste(fallback$IM, collapse=", ")))
  } else {
    cat("[ERROR] IM prefix NOT found in fallback sequences!\n")
  }
  
  # Check if FD prefix is present
  if ("FD" %in% names(fallback)) {
    cat("[SUCCESS] FD prefix found in fallback sequences\n")
    cat(sprintf("[DEBUG] FD dataflows: %s\n", paste(fallback$FD, collapse=", ")))
  } else {
    cat("[ERROR] FD prefix NOT found in fallback sequences!\n")
  }
}

# Test 2: Test dataflow detection for IM_DTP3
cat("\n[TEST] Testing dataflow detection for IM_DTP3...\n")
tryCatch({
  # Try detect_dataflow() first (if it exists)
  if (exists("detect_dataflow", envir = asNamespace("unicefData"))) {
    detected_df <- detect_dataflow("IM_DTP3")
    cat(sprintf("[DEBUG] Detected dataflow (via detect_dataflow): %s\n", detected_df))
  } else {
    # Fall back to get_dataflow_for_indicator() (exported function)
    detected_df <- get_dataflow_for_indicator("IM_DTP3")
    cat(sprintf("[DEBUG] Detected dataflow (via get_dataflow_for_indicator): %s\n", detected_df))
  }

  if (detected_df != "GLOBAL_DATAFLOW") {
    cat("[SUCCESS] IM_DTP3 detected to use correct dataflow (not GLOBAL_DATAFLOW)\n")
  } else {
    cat("[ERROR] IM_DTP3 still defaulting to GLOBAL_DATAFLOW!\n")
  }
}, error = function(e) {
  cat(sprintf("[ERROR] Could not detect dataflow: %s\n", e$message))
})

# Test 3: Fetch IM_DTP3 data and check columns
cat("\n[TEST] Fetching IM_DTP3 data from API...\n")
tryCatch({
  result <- unicefData::unicefdata(
    indicator = "IM_DTP3",
    filters = list(
      TIME_PERIOD = "2023"
    ),
    labels = "id",
    return_metadata = FALSE,
    verbose = FALSE,
    max_retries = 3
  )
  
  if (is.data.frame(result) && nrow(result) > 0) {
    n_cols <- ncol(result)
    cat(sprintf("[DEBUG] R returned %d columns\n", n_cols))
    cat(sprintf("[DEBUG] Column names: %s\n", paste(head(names(result), 15), collapse=", ")))
    
    # Check for vaccine column
    if ("vaccine" %in% names(result)) {
      cat("[SUCCESS] vaccine column FOUND in R result\n")
    } else {
      cat("[ERROR] vaccine column NOT FOUND in R result!\n")
    }
  } else {
    cat("[ERROR] Failed to fetch data or returned empty result\n")
  }
}, error = function(e) {
  cat(sprintf("[ERROR] Error fetching data: %s\n", e$message))
})

cat("\n[TEST] Fallback sequences fix validation complete.\n")

#!/usr/bin/env Rscript
# Simplified test for fallback sequences (works without devtools)

# Set working directory to package root
setwd("C:\\GitHub\\myados\\unicefData-dev")

cat("=== Testing Fallback Sequences ===\n\n")
cat("Working directory:", getwd(), "\n\n")

# Method 1: Try loading the installed package (if available)
package_loaded <- FALSE
tryCatch({
  library(unicefData)
  package_loaded <- TRUE
  cat("[INFO] Loaded installed unicefData package\n\n")
}, error = function(e) {
  cat("[INFO] unicefData package not installed, will try devtools...\n\n")
})

# Method 2: Try devtools if package not loaded
if (!package_loaded) {
  if (requireNamespace("devtools", quietly = TRUE)) {
    cat("[INFO] Using devtools::load_all()\n")
    devtools::load_all(".", export_all = FALSE, quiet = TRUE)
    package_loaded <- TRUE
  } else {
    cat("[ERROR] Neither unicefData package nor devtools is available\n")
    cat("[INFO] Please run one of:\n")
    cat("  1. install.packages('devtools')\n")
    cat("  2. devtools::install() (from package directory)\n")
    quit(status = 1)
  }
}

# Now run the tests
cat("\n=== Test 1: Load Fallback Sequences ===\n")

fallback <- NULL
method_used <- "unknown"

# Try .load_fallback_sequences() first (indicator_registry.R)
tryCatch({
  fallback <- unicefData:::.load_fallback_sequences()
  method_used <- ".load_fallback_sequences()"
  cat("[SUCCESS] Loaded using", method_used, "\n")
}, error = function(e1) {
  # If that fails, try .get_fallback_sequences() (unicef_core.R)
  tryCatch({
    fallback <<- unicefData:::.get_fallback_sequences()
    method_used <<- ".get_fallback_sequences()"
    cat("[SUCCESS] Loaded using", method_used, "\n")
  }, error = function(e2) {
    cat("[ERROR] Both methods failed:\n")
    cat("  .load_fallback_sequences():", e1$message, "\n")
    cat("  .get_fallback_sequences():", e2$message, "\n")
  })
})

# Check results
if (!is.null(fallback)) {
  cat(sprintf("[SUCCESS] Loaded fallback sequences with %d prefixes\n", length(fallback)))
  cat(sprintf("[INFO] Prefixes: %s\n", paste(head(names(fallback), 10), collapse=", ")))

  # Check for IM prefix
  if ("IM" %in% names(fallback)) {
    cat(sprintf("[SUCCESS] IM prefix found with %d dataflows: %s\n",
                length(fallback$IM),
                paste(fallback$IM, collapse=", ")))
  } else {
    cat("[WARNING] IM prefix NOT found in fallback sequences\n")
  }

  # Check for FD prefix
  if ("FD" %in% names(fallback)) {
    cat(sprintf("[SUCCESS] FD prefix found with %d dataflows: %s\n",
                length(fallback$FD),
                paste(fallback$FD, collapse=", ")))
  } else {
    cat("[WARNING] FD prefix NOT found in fallback sequences\n")
  }

  # Check for DEFAULT
  if ("DEFAULT" %in% names(fallback)) {
    cat(sprintf("[INFO] DEFAULT fallback: %s\n", paste(fallback$DEFAULT, collapse=", ")))
  }
} else {
  cat("[ERROR] Fallback sequences is NULL!\n")
}

cat("\n=== Test 2: Dataflow Detection ===\n")

tryCatch({
  # Try get_dataflow_for_indicator() (exported function)
  detected_df <- get_dataflow_for_indicator("IM_DTP3")
  cat(sprintf("[INFO] Detected dataflow for IM_DTP3: %s\n", detected_df))

  if (detected_df != "GLOBAL_DATAFLOW") {
    cat("[SUCCESS] IM_DTP3 uses specific dataflow (not GLOBAL_DATAFLOW)\n")
  } else {
    cat("[WARNING] IM_DTP3 defaulting to GLOBAL_DATAFLOW\n")
  }
}, error = function(e) {
  cat(sprintf("[ERROR] Dataflow detection failed: %s\n", e$message))
})

cat("\n=== Test 3: Fetch Real Data ===\n")

tryCatch({
  cat("[INFO] Fetching IM_DTP3 data for year 2023...\n")

  result <- unicefdata(
    indicator = "IM_DTP3",
    filters = list(TIME_PERIOD = "2023"),
    labels = "id",
    return_metadata = FALSE,
    verbose = FALSE,
    max_retries = 3
  )

  if (is.data.frame(result) && nrow(result) > 0) {
    cat(sprintf("[SUCCESS] Fetched %d rows, %d columns\n", nrow(result), ncol(result)))
    cat(sprintf("[INFO] Columns: %s\n", paste(head(names(result), 15), collapse=", ")))

    # Check for vaccine column
    if ("vaccine" %in% names(result)) {
      cat("[SUCCESS] 'vaccine' column found in result\n")
    } else {
      cat("[WARNING] 'vaccine' column NOT found in result\n")
    }
  } else {
    cat("[WARNING] No data returned or empty result\n")
  }
}, error = function(e) {
  cat(sprintf("[ERROR] Data fetch failed: %s\n", e$message))
})

cat("\n=== Test Complete ===\n")

#!/usr/bin/env Rscript
# Test if unicefData R package loads and works

# Set user library path
userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library', '4.5')
.libPaths(c(userLib, .libPaths()))

cat("=== Testing unicefData R Package ===\n\n")

# Test 1: Load the package
cat("[TEST 1] Loading unicefData package...\n")
tryCatch({
  library(unicefData)
  cat("[SUCCESS] Package loaded\n")
  cat("  Version:", as.character(packageVersion("unicefData")), "\n\n")
}, error = function(e) {
  cat("[FAILED]", e$message, "\n\n")
  quit(status = 1)
})

# Test 2: Check if fallback sequences function exists
cat("[TEST 2] Checking fallback sequences functions...\n")
if (exists("get_dataflow_for_indicator", where = asNamespace("unicefData"))) {
  cat("[SUCCESS] get_dataflow_for_indicator() found\n\n")
} else {
  cat("[WARNING] get_dataflow_for_indicator() not found\n\n")
}

# Test 3: Test dataflow detection
cat("[TEST 3] Testing dataflow detection for IM_DTP3...\n")
tryCatch({
  suppressMessages({
    df <- get_dataflow_for_indicator("IM_DTP3")
  })
  cat("[SUCCESS] Detected dataflow:", df, "\n\n")
}, error = function(e) {
  cat("[FAILED]", e$message, "\n\n")
})

# Test 4: Try fetching a small indicator
cat("[TEST 4] Fetching CME_ARR_10T19 data...\n")
tryCatch({
  suppressMessages({
    result <- unicefdata(
      indicator = "CME_ARR_10T19",
      filters = list(TIME_PERIOD = "2023"),
      labels = "id",
      return_metadata = FALSE,
      verbose = FALSE
    )
  })

  if (is.data.frame(result) && nrow(result) > 0) {
    cat(sprintf("[SUCCESS] Fetched %d rows, %d columns\n", nrow(result), ncol(result)))
    cat(sprintf("  First 5 columns: %s\n", paste(head(names(result), 5), collapse=", ")))
  } else {
    cat("[WARNING] No data returned\n")
  }
}, error = function(e) {
  cat("[FAILED]", e$message, "\n")
})

cat("\n=== Test Complete ===\n")

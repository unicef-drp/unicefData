#!/usr/bin/env Rscript
#' sync_examples_r.R - Run all R examples
#' ========================================
#'
#' Runs all R example scripts to generate CSV outputs in validation/data/r/
#'
#' Usage:
#'     Rscript validation/sync_examples_r.R
#'     Rscript validation/sync_examples_r.R --verbose
#'     Rscript validation/sync_examples_r.R --example 00_quick_start

# Setup paths
script_dir <- dirname(sys.frame(1)$ofile)
if (is.null(script_dir) || script_dir == "") {
  script_dir <- "."
}
base_dir <- normalizePath(file.path(script_dir, ".."), mustWork = FALSE)
r_dir <- file.path(base_dir, "R")
examples_dir <- file.path(r_dir, "examples")
output_dir <- file.path(script_dir, "data", "r")

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
verbose <- "--verbose" %in% args || "-v" %in% args
specific_example <- NULL
if (any(grepl("^--example", args))) {
  idx <- which(grepl("^--example", args))
  if (idx < length(args)) {
    specific_example <- args[idx + 1]
  }
}

# Example scripts to run
examples <- c(
  "00_quick_start.R",
  "01_indicator_discovery.R",
  "02_sdg_indicators.R",
  "03_data_formats.R",
  "04_metadata_options.R",
  "05_advanced_features.R",
  "06_test_fallback.R"
)

run_example <- function(script_name, verbose = FALSE) {
  script_path <- file.path(examples_dir, script_name)
  
  if (!file.exists(script_path)) {
    cat(sprintf("  [SKIP] %s not found\n", script_name))
    return(NA)
  }
  
  cat(sprintf("  Running %s...\n", script_name))
  
  tryCatch({
    source(script_path, local = new.env())
    cat(sprintf("  [OK] %s\n", script_name))
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("  [FAIL] %s: %s\n", script_name, conditionMessage(e)))
    if (verbose) {
      cat(sprintf("  Stack trace:\n"))
      traceback()
    }
    return(FALSE)
  })
}

# Main
cat(strrep("=", 60), "\n")
cat("Running R Examples\n")
cat(strrep("=", 60), "\n")
cat(sprintf("Output directory: %s\n\n", output_dir))

# Ensure output directory exists
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Filter examples if specified
if (!is.null(specific_example)) {
  examples <- examples[grepl(specific_example, examples)]
  if (length(examples) == 0) {
    cat(sprintf("No examples match: %s\n", specific_example))
    quit(status = 1)
  }
}

# Run examples
results <- sapply(examples, function(ex) run_example(ex, verbose))

# Summary
cat("\n")
cat(strrep("=", 60), "\n")
cat("Summary\n")
cat(strrep("=", 60), "\n")

passed <- sum(results == TRUE, na.rm = TRUE)
failed <- sum(results == FALSE, na.rm = TRUE)
skipped <- sum(is.na(results))

cat(sprintf("  Passed:  %d\n", passed))
cat(sprintf("  Failed:  %d\n", failed))
cat(sprintf("  Skipped: %d\n", skipped))
cat("\n")
cat(sprintf("CSV outputs saved to: %s\n", output_dir))

# Exit with appropriate status
if (failed > 0) {
  quit(status = 1)
} else {
  quit(status = 0)
}

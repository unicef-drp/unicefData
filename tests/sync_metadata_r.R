#!/usr/bin/env Rscript
# Sync R metadata from UNICEF SDMX API
# Run from: C:\GitHub\others\unicefData
# Usage: Rscript tests/sync_metadata_r.R

# ==============================================================================
# Setup
# ==============================================================================

# Change to repo directory
setwd("C:/GitHub/others/unicefData")

# Start logging
log_file <- "tests/logs/sync_metadata_r.log"
sink(log_file, split = TRUE)

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("R Metadata Sync Test\n")
cat("Started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Load package in development mode
cat("Loading unicefData package...\n")
suppressMessages({
  library(devtools)
  load_all(".")
})

# ==============================================================================
# Run Metadata Sync
# ==============================================================================

cat("\n", paste(rep("-", 70), collapse = ""), "\n")
cat("Running sync_all_metadata()...\n")
cat(paste(rep("-", 70), collapse = ""), "\n\n")

# Set output directory
output_dir <- "R/metadata/current"
cat("Output directory:", output_dir, "\n\n")

# Helper for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x

# Run the sync
tryCatch({
  results <- sync_all_metadata(
    verbose = TRUE,
    output_dir = output_dir,
    include_schemas = TRUE
  )
  
  cat("\n", paste(rep("-", 70), collapse = ""), "\n")
  cat("RESULTS\n")
  cat(paste(rep("-", 70), collapse = ""), "\n\n")
  
  cat("Summary:\n")
  cat("  Dataflows:  ", results$dataflows %||% 0, "\n")
  cat("  Indicators: ", results$indicators %||% 0, "\n")
  cat("  Countries:  ", results$countries %||% 0, "\n")
  cat("  Regions:    ", results$regions %||% 0, "\n")
  cat("  Codelists:  ", results$codelists %||% 0, "\n")
  cat("  Schemas:    ", results$schemas %||% 0, "\n")
  
  # Check for files created
  cat("\nFiles in output directory:\n")
  files <- list.files(output_dir, pattern = "\\.yaml$", full.names = FALSE)
  for (f in files[1:min(10, length(files))]) {
    cat("  -", f, "\n")
  }
  if (length(files) > 10) {
    cat("  ... and", length(files) - 10, "more files\n")
  }
  
  cat("\n[OK] Metadata sync completed successfully!\n")
  
}, error = function(e) {
  cat("\n[ERROR] Metadata sync failed:\n")
  cat("  ", conditionMessage(e), "\n")
  cat("\n")
})

# ==============================================================================
# Cleanup
# ==============================================================================

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("Finished:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat(paste(rep("=", 70), collapse = ""), "\n")

sink()
cat("Log saved to:", log_file, "\n")

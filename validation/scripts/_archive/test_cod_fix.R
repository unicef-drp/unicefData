#!/usr/bin/env Rscript
# Quick test: Can R now fetch COD_DENGUE with the fix?

library(tidyverse)

# Add R package to path
source("../../R/indicator_registry.R")
source("../../R/get_sdmx.R")

cat("\n=== Testing COD_DENGUE dataflow detection ===\n")

# Test the dataflow detection
dataflow <- get_dataflow_for_indicator("COD_DENGUE")
cat(sprintf("COD_DENGUE detected dataflow: %s\n", dataflow))

dataflow_mg <- get_dataflow_for_indicator("MG_NEW_INTERNAL_DISP")
cat(sprintf("MG_NEW_INTERNAL_DISP detected dataflow: %s\n", dataflow_mg))

cat("\nNow attempting to fetch data...\n")

# Try to fetch COD_DENGUE
tryCatch({
  result <- get_sdmx(
    indicator = "COD_DENGUE",
    dataflow = dataflow,
    countries = NULL,
    year = 2020
  )
  
  if (!is.null(result) && nrow(result) > 0) {
    cat(sprintf("✓ SUCCESS: Retrieved %d rows\n", nrow(result)))
    cat(sprintf("  Columns: %s\n", paste(names(result), collapse=", "))
  } else {
    cat("✗ FAILED: No data returned\n")
  }
}, error = function(e) {
  cat(sprintf("✗ ERROR: %s\n", e$message))
})

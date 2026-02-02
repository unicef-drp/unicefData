#!/usr/bin/env Rscript
# Compare API behavior: Python vs R for COD_DENGUE and MG_NEW_INTERNAL_DISP

library(httr)
library(jsonlite)

cat("\n=== Direct API Testing (Comparing Dataflow Requests) ===\n\n")

# Test cases with their dataflows
test_cases <- list(
  list(indicator="COD_DENGUE", dataflow="GLOBAL_DATAFLOW", python_success=TRUE),
  list(indicator="MG_NEW_INTERNAL_DISP", dataflow="MIGRATION", python_success=TRUE)
)

# Base URL for UNICEF SDMX API
base_url <- "https://sdmx.unicef.org/rest/data"

for (test in test_cases) {
  ind <- test$indicator
  df <- test$dataflow
  
  cat(sprintf("Testing: %s (dataflow: %s)\n", ind, df))
  cat("------------------------------------------------------------\n")
  
  # Construct SDMX query URL (similar to what unicefData package should do)
  # Format: https://sdmx.unicef.org/rest/data/DATAFLOW/DIMENSION1.DIMENSION2+/all/?startPeriod=2020&endPeriod=2020
  
  # Try different query formats that R/unicefData might be using
  query_formats <- list(
    list(
      name = "Format 1: Direct indicator query",
      url = sprintf("%s/%s/all+all+%s?startPeriod=2020&endPeriod=2020", base_url, df, ind)
    ),
    list(
      name = "Format 2: Simpler query",
      url = sprintf("%s/%s?detail=full&startPeriod=2020", base_url, df)
    )
  )
  
  for (fmt in query_formats) {
    cat(sprintf("  %s:\n", fmt$name))
    cat(sprintf("    URL: %s\n", substr(fmt$url, 1, 80)), "...\n")
    
    tryCatch({
      response <- HEAD(fmt$url, timeout(5))
      cat(sprintf("    Response: %d\n", response$status_code))
      
      if (response$status_code != 404) {
        cat("    ✅ Found\n")
      } else {
        cat("    ❌ Not Found (404)\n")
      }
    }, error = function(e) {
      cat(sprintf("    ERROR: %s\n", substr(as.character(e), 1, 50)))
    })
  }
  
  cat("\n")
}

cat("=== End Direct API Testing ===\n\n")

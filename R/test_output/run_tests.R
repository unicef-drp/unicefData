# ============================================================================
# Comprehensive test suite for unicefdata R package
# Tests all major functionality and saves results to CSV files
# Uses get_unicef() for consistent output with Python package
# ============================================================================

# Set working directory
setwd("D:/jazevedo/GitHub/unicefData")

# Source the main get_unicef function (which loads dependencies)
source("R/get_unicef.R")

# Also source metadata functions for metadata tests
source("R/metadata.R")
source("R/flows.R")

# Output directory
OUTPUT_DIR <- "R/test_output"
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# Helper function
log_msg <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
}

# ============================================================================
# Test Functions
# ============================================================================

test_list_flows <- function() {
  log_msg("Testing list_sdmx_flows()...")
  
  flows <- list_sdmx_flows()
  
  log_msg(sprintf("  Found %d dataflows", nrow(flows)))
  
  # Save to CSV with UTF-8 encoding
  write.csv(flows, file.path(OUTPUT_DIR, "test_dataflows.csv"), 
            row.names = FALSE, fileEncoding = "UTF-8")
  log_msg("  Saved to test_dataflows.csv")
  
  return(nrow(flows) > 50)
}

test_child_mortality <- function() {
  log_msg("Testing child mortality (CME_MRY0T4)...")
  
  df <- get_unicef(
    indicator = "CME_MRY0T4",
    countries = c("USA", "GBR", "FRA", "DEU", "JPN"),
    start_year = 2015,
    end_year = 2023
  )
  
  log_msg(sprintf("  Retrieved %d observations", nrow(df)))
  
  if (!is.null(df) && nrow(df) > 0) {
    log_msg(sprintf("  Countries: %s", paste(unique(df$country_code), collapse = ", ")))
    log_msg(sprintf("  Years: %s", paste(sort(unique(df$year)), collapse = ", ")))
    
    write.csv(df, file.path(OUTPUT_DIR, "test_mortality.csv"), row.names = FALSE)
    log_msg("  Saved to test_mortality.csv")
    return(nrow(df) > 0)
  }
  
  return(FALSE)
}

test_stunting <- function() {
  log_msg("Testing stunting (NT_ANT_HAZ_NE2)...")
  
  df <- get_unicef(
    indicator = "NT_ANT_HAZ_NE2",
    countries = c("IND", "BGD", "PAK", "NPL", "ETH"),
    start_year = 2010,
    end_year = 2023,
    ignore_duplicates = TRUE  # Allow duplicate removal for this dataset
  )
  
  log_msg(sprintf("  Retrieved %d observations", nrow(df)))
  
  if (!is.null(df) && nrow(df) > 0) {
    write.csv(df, file.path(OUTPUT_DIR, "test_stunting.csv"), row.names = FALSE)
    log_msg("  Saved to test_stunting.csv")
    return(nrow(df) > 0)
  }
  
  return(FALSE)
}

test_immunization <- function() {
  log_msg("Testing immunization (IM_DTP3)...")
  
  df <- get_unicef(
    indicator = "IM_DTP3",
    countries = c("NGA", "COD", "BRA", "IDN", "MEX"),
    start_year = 2015,
    end_year = 2023
  )
  
  log_msg(sprintf("  Retrieved %d observations", nrow(df)))
  
  if (!is.null(df) && nrow(df) > 0) {
    write.csv(df, file.path(OUTPUT_DIR, "test_immunization.csv"), row.names = FALSE)
    log_msg("  Saved to test_immunization.csv")
    return(nrow(df) > 0)
  }
  
  return(FALSE)
}

test_metadata_sync <- function() {
  log_msg("Testing metadata sync...")
  
  cache_dir <- file.path(OUTPUT_DIR, "metadata_test")
  set_metadata_cache(cache_dir)
  
  results <- sync_metadata(verbose = FALSE)
  
  log_msg(sprintf("  Synced: %d dataflows, %d indicators", 
                  results$dataflows, results$indicators))
  
  # Test vintage listing
  vintages <- list_vintages()
  log_msg(sprintf("  Vintages available: %s", paste(vintages, collapse = ", ")))
  
  return(results$dataflows > 50)
}

test_multiple_indicators <- function() {
  log_msg("Testing multiple indicators...")
  
  # Use get_unicef with multiple indicators
  df <- get_unicef(
    indicator = c("CME_MRY0T4", "CME_MRY0"),
    countries = c("BRA", "IND", "CHN"),
    start_year = 2020,
    end_year = 2023,
    ignore_duplicates = TRUE  # Allow duplicate removal for combined datasets
  )
  
  if (!is.null(df) && nrow(df) > 0) {
    # Log per indicator
    for (ind in unique(df$indicator_code)) {
      n <- sum(df$indicator_code == ind)
      log_msg(sprintf("  %s: %d observations", ind, n))
    }
    
    write.csv(df, file.path(OUTPUT_DIR, "test_multiple_indicators.csv"), row.names = FALSE)
    log_msg(sprintf("  Saved %d total observations", nrow(df)))
    return(TRUE)
  }
  
  return(FALSE)
}

# ============================================================================
# Run All Tests
# ============================================================================

run_all_tests <- function() {
  cat("============================================================\n")
  cat("UNICEF API R Package Test Suite\n")
  cat(sprintf("Started: %s\n", Sys.time()))
  cat("============================================================\n")
  
  tests <- list(
    list(name = "List Dataflows", fn = test_list_flows),
    list(name = "Child Mortality", fn = test_child_mortality),
    list(name = "Stunting", fn = test_stunting),
    list(name = "Immunization", fn = test_immunization),
    list(name = "Metadata Sync", fn = test_metadata_sync),
    list(name = "Multiple Indicators", fn = test_multiple_indicators)
  )
  
  results <- list()
  
  for (test in tests) {
    result <- tryCatch({
      passed <- test$fn()
      list(name = test$name, status = if (passed) "PASS" else "FAIL", error = NULL)
    }, error = function(e) {
      log_msg(sprintf("  ERROR: %s", e$message))
      list(name = test$name, status = "ERROR", error = e$message)
    })
    results[[length(results) + 1]] <- result
  }
  
  cat("\n============================================================\n")
  cat("TEST RESULTS\n")
  cat("============================================================\n")
  
  passed_count <- 0
  for (r in results) {
    icon <- if (r$status == "PASS") "PASS" else "FAIL"
    cat(sprintf("[%s] %s\n", icon, r$name))
    if (!is.null(r$error)) {
      cat(sprintf("   Error: %s\n", r$error))
    }
    if (r$status == "PASS") passed_count <- passed_count + 1
  }
  
  cat(sprintf("\nTotal: %d/%d tests passed\n", passed_count, length(results)))
  cat("============================================================\n")
  
  invisible(passed_count == length(results))
}

# Run tests
run_all_tests()

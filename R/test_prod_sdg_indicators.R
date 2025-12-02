# Test script for R - replicates PROD-SDG-REP-2025 indicator downloads
# Mirrors the Python test_prod_sdg_indicators.py

source("get_unicef.R")

cat("======================================================================\n")
cat("PROD-SDG-REP-2025 Indicator Download Test (R)\n")
cat("======================================================================\n\n")

# Define test categories matching Python test
PROD_SDG_INDICATORS <- list(
  MORTALITY = list(
    indicators = c("CME_MRM0", "CME_MRY0T4"),
    dataflow = "CME"
  ),
  NUTRITION = list(
    indicators = c("NT_ANT_HAZ_NE2_MOD", "NT_ANT_WHZ_NE2", "NT_ANT_WHZ_PO2_MOD"),
    dataflow = "NUTRITION"
  ),
  IMMUNIZATION = list(
    indicators = c("IM_DTP3", "IM_MCV1"),
    dataflow = "IMMUNISATION"
  ),
  EDUCATION = list(
    indicators = c("ED_CR_L1_UIS_MOD", "ED_CR_L2_UIS_MOD"),
    dataflow = "EDUCATION_UIS_SDG",
    use_explicit = TRUE
  ),
  CHILD_PROTECTION = list(
    indicators = c("PT_CHLD_Y0T4_REG"),
    dataflow = "PT"
  ),
  CHILD_MARRIAGE = list(
    indicators = c("PT_F_20-24_MRD_U18_TND"),
    dataflow = "PT_CM",
    use_explicit = TRUE
  ),
  FGM = list(
    indicators = c("PT_F_15-49_FGM"),
    dataflow = "PT_FGM",
    use_explicit = TRUE
  ),
  CHILD_POVERTY = list(
    indicators = c("PV_CHLD_DPRV-S-L1-HS"),
    dataflow = "CHLD_PVTY"
  ),
  IPFM = list(
    indicators = c("PT_F_PS-SX_V_PTNR_12MNTH"),
    dataflow = "PT"  # Will need fallback to GLOBAL_DATAFLOW
  )
)

# Run tests
results <- list()
total_rows <- 0
start_time <- Sys.time()

for (category_name in names(PROD_SDG_INDICATORS)) {
  cat(sprintf("\n============================================================\n"))
  cat(sprintf("Testing: %s\n", category_name))
  cat(sprintf("============================================================\n"))
  
  category_info <- PROD_SDG_INDICATORS[[category_name]]
  indicators <- category_info$indicators
  expected_df <- category_info$dataflow
  use_explicit <- isTRUE(category_info$use_explicit)
  
  cat(sprintf("Indicators: %s\n", paste(indicators, collapse=", ")))
  cat(sprintf("Expected dataflow: %s\n", expected_df))
  
  test_start <- Sys.time()
  
  tryCatch({
    # Fetch data
    if (use_explicit) {
      cat("Using explicit dataflow: Yes (auto-detection unreliable)\n")
      df <- get_unicef(
        indicator = indicators,
        dataflow = expected_df,
        countries = NULL  # All countries
      )
    } else {
      df <- get_unicef(
        indicator = indicators,
        countries = NULL  # All countries
      )
    }
    
    elapsed <- as.numeric(difftime(Sys.time(), test_start, units="secs"))
    
    if (nrow(df) > 0) {
      n_countries <- length(unique(df$iso3))
      n_rows <- nrow(df)
      total_rows <- total_rows + n_rows
      
      cat(sprintf("  [OK] SUCCESS\n"))
      cat(sprintf("     Rows: %s\n", format(n_rows, big.mark=",")))
      cat(sprintf("     Countries: %d\n", n_countries))
      cat(sprintf("     Time: %.2fs\n", elapsed))
      
      results[[category_name]] <- list(status="success", rows=n_rows, countries=n_countries)
    } else {
      cat(sprintf("  [EMPTY] No data returned\n"))
      results[[category_name]] <- list(status="empty", rows=0)
    }
    
  }, error = function(e) {
    elapsed <- as.numeric(difftime(Sys.time(), test_start, units="secs"))
    cat(sprintf("  [FAIL] %s\n", substr(as.character(e), 1, 80)))
    results[[category_name]] <<- list(status="failed", error=as.character(e))
  })
  
  # Small delay between tests
  Sys.sleep(0.5)
}

# Summary
total_time <- as.numeric(difftime(Sys.time(), start_time, units="secs"))

cat("\n======================================================================\n")
cat("SUMMARY\n")
cat("======================================================================\n\n")

success_count <- sum(sapply(results, function(r) r$status == "success"))
total_count <- length(results)

cat(sprintf("[OK] Successful: %d/%d\n", success_count, total_count))
cat(sprintf("[DATA] Total rows downloaded: %s\n", format(total_rows, big.mark=",")))
cat(sprintf("[TIME] Total time: %.1fs\n", total_time))

if (success_count < total_count) {
  cat("\nFailed categories:\n")
  for (name in names(results)) {
    if (results[[name]]$status != "success") {
      cat(sprintf("  - %s: %s\n", name, results[[name]]$status))
    }
  }
}

cat(sprintf("\nR: %d/%d passed\n", success_count, total_count))

# 06_test_fallback.R - Test Dataflow Fallback Mechanism
# =========================================================
#
# Tests 5 key indicators demonstrating:
# 1. Direct dataflow fetch (CME, NUTRITION)
# 2. Static overrides (EDUCATION, CHILD_MARRIAGE)
# 3. Dynamic fallback (IPV -> GLOBAL_DATAFLOW)
#
# Matches: python/examples/06_test_fallback.py

# Source common setup (handles path resolution)
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
.script_dir <- if (length(.file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", .file_arg[1])))
} else {
  "."
}
source(file.path(.script_dir, "_setup.R"))
data_dir <- get_validation_data_dir()

cat("======================================================================\n")
cat("06_test_fallback.R - Test Dataflow Fallback Mechanism\n")
cat("======================================================================\n\n")

# Test cases - same as Python 06_test_fallback.py
tests <- list(
  list(
    name = "MORTALITY (CME)",
    indicator = "CME_MRY0T4",
    countries = c("AFG", "ALB", "USA"),
    expected = "Direct fetch from CME"
  ),
  list(
    name = "NUTRITION (stunting)",
    indicator = "NT_ANT_HAZ_NE2_MOD",
    countries = c("AFG", "ALB", "USA"),
    expected = "Direct fetch from NUTRITION"
  ),
  list(
    name = "EDUCATION (override)",
    indicator = "ED_CR_L1_UIS_MOD",
    countries = c("AFG", "ALB", "USA"),
    expected = "Uses override to EDUCATION_UIS_SDG"
  ),
  list(
    name = "CHILD_MARRIAGE (override)",
    indicator = "PT_F_20-24_MRD_U18_TND",
    countries = c("AFG", "ALB"),
    expected = "Uses override to PT_CM"
  ),
  list(
    name = "IPV (fallback)",
    indicator = "PT_F_PS-SX_V_PTNR_12MNTH",
    countries = c("AFG", "ALB"),
    expected = "Needs fallback to GLOBAL_DATAFLOW"
  )
)

results <- list()
total_start <- Sys.time()

for (t in tests) {
  cat(sprintf("\n--- Testing: %s ---\n", t$name))
  cat(sprintf("Indicator: %s\n", t$indicator))
  
  start <- Sys.time()
  
  tryCatch({
    df <- unicefData(
      indicator = t$indicator,
      countries = t$countries,
      year = "2015:2024"
    )
    
    elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
    
    if (nrow(df) > 0) {
      cat(sprintf("[OK] %d rows in %.1fs\n", nrow(df), elapsed))
      results[[t$name]] <- "OK"
    } else {
      cat(sprintf("[EMPTY] No data in %.1fs\n", elapsed))
      results[[t$name]] <- "EMPTY"
    }
  }, error = function(e) {
    elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
    cat(sprintf("[FAIL] %s (%.1fs)\n", substr(e$message, 1, 60), elapsed))
    results[[t$name]] <<- "FAIL"
  })
}

# Summary
total_time <- as.numeric(difftime(Sys.time(), total_start, units = "secs"))

cat("\n======================================================================\n")
cat("SUMMARY\n")
cat("======================================================================\n")

success <- sum(sapply(results, function(r) r == "OK"))
total <- length(results)

for (name in names(results)) {
  cat(sprintf("[%-5s] %s\n", results[[name]], name))
}

cat(sprintf("\nR: %d/%d passed (%.1fs total)\n", success, total, total_time))

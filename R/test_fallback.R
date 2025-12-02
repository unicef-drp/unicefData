# Test script for R fallback mechanism
source("get_unicef.R")

cat("============================================================\n")
cat("R TEST SUMMARY\n")
cat("============================================================\n\n")

tests <- list(
  list(ind="CME_MRY0T4", desc="Child Mortality"),
  list(ind="ED_CR_L1_UIS_MOD", desc="Education (needs override)"),
  list(ind="PT_F_20-24_MRD_U18_TND", desc="Child Marriage (needs override)"),
  list(ind="PT_F_PS-SX_V_PTNR_12MNTH", desc="IPV (needs fallback)")
)

results <- lapply(tests, function(t) {
  tryCatch({
    df <- get_unicef(indicator=t[["ind"]], countries=c("AFG"), start_year=2015)
    list(desc=t[["desc"]], status=if(nrow(df)>0) "OK" else "EMPTY", rows=nrow(df))
  }, error = function(e) {
    list(desc=t[["desc"]], status="FAIL", rows=0)
  })
})

cat("\n")
for (r in results) {
  cat(sprintf("[%-5s] %s: %d rows\n", r[["status"]], r[["desc"]], r[["rows"]]))
}

success <- sum(sapply(results, function(r) r[["status"]] == "OK"))
cat(sprintf("\nR: %d/%d passed\n", success, length(results)))

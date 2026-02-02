#!/usr/bin/env Rscript
# Show exact URL construction differences

cat("\n=== R SDMX URL Construction Pattern ===\n\n")

cat("Based on R unicef_core.R source code analysis:\n\n")

cat("Standard SDMX REST API URL pattern for UNICEF:\n")
cat("  https://sdmx.unicef.org/rest/data/DATAFLOW+DIMENSIONS/FILTERS/?startPeriod=YYYY&endPeriod=YYYY\n\n")

cat("For COD_DENGUE (GLOBAL_DATAFLOW):\n")
cat("  Expected: https://sdmx.unicef.org/rest/data/GLOBAL_DATAFLOW/.../COD_DENGUE?...\n")
cat("  R Attempt: [Getting 404]\n")
cat("  Python Success: [Returns 70 rows]\n")
cat("  Stata Success: [Returns 70 rows]\n\n")

cat("For MG_NEW_INTERNAL_DISP (MIGRATION):\n")
cat("  Expected: https://sdmx.unicef.org/rest/data/MIGRATION/.../MG_NEW_INTERNAL_DISP?...\n")
cat("  R Attempt: [Getting 404]\n")
cat("  Python Success: [Returns 3,616 rows]\n")
cat("  Stata Success: [Returns 3,616 rows]\n\n")

cat("Difference Hypotheses:\n")
cat("  1. User-Agent header (libcurl vs requests vs Stata HTTP client)\n")
cat("  2. Accept header (XML vs JSON vs default)\n")
cat("  3. Dimension ordering in query string\n")
cat("  4. Country parameter encoding (USA vs US vs USA...)\n")
cat("  5. Request session/cookie handling\n\n")

cat("To Debug:\n")
cat("  1. Modify fetch_sdmx_text() to log the URL\n")
cat("  2. Use curl verbose mode: httr::set_config(httr::verbose())\n")
cat("  3. Compare exact URL between successful Python/Stata runs\n\n")

cat("Files to Check:\n")
cat("  - R/unicef_core.R lines 85-115 (fetch_sdmx_text)\n")
cat("  - R/unicef_core.R lines 120-200 (unicefData_raw function)\n")
cat("  - R/unicef_core.R lines 164-190 (get_fallback_dataflows)\n\n")

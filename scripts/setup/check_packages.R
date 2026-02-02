#!/usr/bin/env Rscript
# Check which packages are installed

needed <- c('yaml', 'devtools', 'dplyr', 'magrittr', 'httr', 'readr',
            'rlang', 'purrr', 'tibble', 'jsonlite', 'xml2', 'memoise')

installed_pkgs <- rownames(installed.packages())

installed <- needed[needed %in% installed_pkgs]
missing <- needed[!(needed %in% installed_pkgs)]

cat("=== Package Status ===\n\n")
cat(sprintf("Installed (%d): %s\n", length(installed), paste(installed, collapse=", ")))
cat(sprintf("\nMissing (%d): %s\n", length(missing), paste(missing, collapse=", ")))

if (length(missing) == 0) {
  cat("\n[SUCCESS] All required packages are installed!\n")
} else {
  cat("\n[INFO] To install missing packages, run R as administrator and execute:\n")
  cat(sprintf("  install.packages(c(%s))\n", paste(sprintf("'%s'", missing), collapse=", ")))
}

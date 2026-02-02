#!/usr/bin/env Rscript
# Install dependencies needed for testing

cat("=== Installing Test Dependencies ===\n\n")

# List of required packages
required <- c("yaml", "devtools", "dplyr", "magrittr", "httr", "readr", "rlang",
              "purrr", "tibble", "jsonlite", "xml2", "memoise")

# Check which are missing
missing <- character(0)
for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing <- c(missing, pkg)
  }
}

if (length(missing) == 0) {
  cat("[SUCCESS] All required packages are already installed!\n")
  quit(status = 0)
}

cat(sprintf("[INFO] Need to install %d packages: %s\n\n",
            length(missing),
            paste(missing, collapse=", ")))

# Install missing packages
for (pkg in missing) {
  cat(sprintf("[INFO] Installing %s...\n", pkg))
  tryCatch({
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
    cat(sprintf("[SUCCESS] %s installed\n", pkg))
  }, error = function(e) {
    cat(sprintf("[ERROR] Failed to install %s: %s\n", pkg, e$message))
  })
}

cat("\n[INFO] Installation complete. You can now run the test scripts.\n")

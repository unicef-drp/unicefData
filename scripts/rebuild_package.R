#!/usr/bin/env Rscript
# Rebuild and install unicefData package from source

# Set user library path
userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library', '4.5')
dir.create(userLib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(userLib, .libPaths()))

cat("=== Rebuilding unicefData Package ===\n\n")
cat("User library:", userLib, "\n")
cat("Working directory:", getwd(), "\n\n")

# Install/rebuild the package from source
cat("Installing package from source...\n")
tryCatch({
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("devtools not available")
  }

  # Install from current directory
  devtools::install(pkg = ".", lib = userLib, upgrade = "never", quiet = FALSE)

  cat("\n[SUCCESS] Package installed to user library\n")

  # Verify installation
  cat("\nVerifying installation...\n")
  library(unicefData, lib.loc = userLib)
  cat("Version:", as.character(packageVersion("unicefData")), "\n")

  # Test a function
  cat("\nTesting get_dataflow_for_indicator()...\n")
  df <- get_dataflow_for_indicator("CME_MRM0")
  cat("Result:", df, "\n")

  cat("\n[SUCCESS] Package working correctly\n")

}, error = function(e) {
  cat("[ERROR]", e$message, "\n")
  quit(status = 1)
})

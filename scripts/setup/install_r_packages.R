#!/usr/bin/env Rscript
# Install R packages to user library (no admin required)

# Set user library path
userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library', '4.5')
dir.create(userLib, recursive = TRUE, showWarnings = FALSE)

# Add to library paths (user library first)
.libPaths(c(userLib, .libPaths()))

cat("=== R Package Installation ===\n\n")
cat("Library paths:\n")
print(.libPaths())
cat("\n")

# List of required packages
required <- c('yaml', 'devtools', 'dplyr', 'magrittr', 'httr', 'readr',
              'rlang', 'purrr', 'tibble', 'jsonlite', 'xml2', 'memoise')

cat("Installing", length(required), "packages to:", userLib, "\n\n")

# Install packages
for (pkg in required) {
  cat("Installing", pkg, "... ")
  tryCatch({
    install.packages(pkg, lib = userLib, repos = "https://cloud.r-project.org",
                     quiet = TRUE, dependencies = TRUE)
    cat("OK\n")
  }, error = function(e) {
    cat("FAILED:", e$message, "\n")
  })
}

cat("\n=== Installation Complete ===\n")
cat("\nInstalled packages in user library:\n")
installed <- installed.packages(lib.loc = userLib)
if (nrow(installed) > 0) {
  print(installed[, c("Package", "Version")])
} else {
  cat("No packages installed\n")
}

#!/usr/bin/env Rscript
# Install unicefData package from source
# This script is portable and works across different systems

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Get user library path from environment or use R default
user_lib <- Sys.getenv("R_LIBS_USER")
if (user_lib == "" || !nzchar(user_lib)) {
  # Fall back to first writable library path
  user_lib <- .libPaths()[1]
}

# Allow override via command line argument
if (length(args) >= 2 && args[1] == "--lib") {
  user_lib <- args[2]
}

# Get package path - default to current working directory
# Usage: Rscript install_package.R [package_path] [--lib library_path]
pkg_path <- normalizePath(getwd(), mustWork = FALSE)
if (length(args) >= 1 && args[1] != "--lib") {
  # First arg is package path (not a flag)
  pkg_path <- normalizePath(args[1], mustWork = FALSE)
}

# Verify DESCRIPTION file exists (indicating valid R package)
if (!file.exists(file.path(pkg_path, "DESCRIPTION"))) {
  stop("No DESCRIPTION file found in '", pkg_path, "'. Not a valid R package directory.")
}

# Create user library if it doesn't exist
if (!dir.exists(user_lib)) {
  dir.create(user_lib, recursive = TRUE)
  cat("Created user library at:", user_lib, "\n")
}

# Set library paths
.libPaths(c(user_lib, .libPaths()))
cat("Library paths before install:\n")
print(.libPaths())

# Install package
cat("Installing unicefData from source:", pkg_path, "\n")
install.packages(pkg_path,
                repos = NULL,
                type = "source",
                lib = user_lib,
                dependencies = FALSE)

cat("Package installed successfully to:", user_lib, "\n")
cat("Library paths:\n")
print(.libPaths())

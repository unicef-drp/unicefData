# _setup.R - Common setup for R examples
# =========================================
#
# This file provides a common setup routine that all example scripts can source.
# It handles finding the unicefData.R source file from various execution contexts.

# Get script directory for proper path resolution
get_script_dir <- function() {
  # Try multiple methods to find script directory

  # Method 1: sys.frame - works in source()
  tryCatch({
    for (i in seq_len(sys.nframe())) {
      ofile <- sys.frame(i)$ofile
      if (!is.null(ofile) && nzchar(ofile)) {
        return(dirname(normalizePath(ofile)))
      }
    }
  }, error = function(e) NULL)

  # Method 2: commandArgs - works in Rscript
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
  }

  # Method 3: Current working directory
  return(getwd())
}

# Set up paths
.example_script_dir <- get_script_dir()
.r_pkg_dir <- normalizePath(file.path(.example_script_dir, ".."), mustWork = FALSE)
.repo_root <- normalizePath(file.path(.example_script_dir, "..", ".."), mustWork = FALSE)

# Source the core module first (contains unicefData_raw and helpers)
core_file <- file.path(.r_pkg_dir, "unicef_core.R")
if (file.exists(core_file)) {
  source(core_file)
}

# Source the main unicefData.R
source_file <- file.path(.r_pkg_dir, "unicefData.R")
if (file.exists(source_file)) {
  source(source_file)

} else if (file.exists("../unicefData.R")) {
  source("../unicefData.R")
} else if (file.exists("R/unicefData.R")) {
  source("R/unicefData.R")
} else {
  stop("Could not find unicefData.R. Please run from the R/examples directory or repository root.")
}

# Setup data directory - centralized for cross-language validation
.validation_data_dir <- file.path(.repo_root, "validation", "data", "r")
if (!dir.exists(.validation_data_dir)) {
  dir.create(.validation_data_dir, recursive = TRUE, showWarnings = FALSE)
}

# Helper function for examples to get the data directory
get_validation_data_dir <- function() {
  .validation_data_dir
}

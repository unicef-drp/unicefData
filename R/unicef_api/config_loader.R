# R/config_loader.R
# =================
# Shared Configuration Loader for UNICEF SDG Indicators
#
# Loads indicator and dataflow configurations from the shared YAML config file.
# This ensures R and Python packages use identical indicator definitions.
#
# Usage:
#   source("R/config_loader.R")
#   indicators <- load_shared_indicators()
#   dataflows <- load_shared_dataflows()

# Required packages
if (!requireNamespace("yaml", quietly = TRUE)) {
  message("Installing yaml package...")
  install.packages("yaml", repos = "https://cloud.r-project.org")
}

# ============================================================================
# Configuration File Discovery
# ============================================================================

#' Get path to the shared indicators.yaml config file
#'
#' Searches in order:
#' 1. UNICEF_CONFIG_PATH environment variable
#' 2. ../../config/indicators.yaml relative to this file
#' 3. ./config/indicators.yaml relative to current working directory
#'
#' @return Path to indicators.yaml
#' @export
get_config_path <- function() {
  # Check environment variable first
  env_path <- Sys.getenv("UNICEF_CONFIG_PATH", "")
  if (nzchar(env_path) && file.exists(env_path)) {
    return(env_path)
  }
  
  # Try relative paths
  possible_paths <- c(
    # Relative to package root
    file.path(getwd(), "config", "indicators.yaml"),
    file.path(getwd(), "..", "config", "indicators.yaml"),
    file.path(getwd(), "..", "..", "config", "indicators.yaml"),
    # Common installation paths
    system.file("config", "indicators.yaml", package = "unicefdata"),
    file.path(Sys.getenv("HOME"), ".unicefdata", "indicators.yaml")
  )
  
  for (path in possible_paths) {
    if (file.exists(path)) {
      return(normalizePath(path, mustWork = FALSE))
    }
  }
  
  stop(paste(
    "Could not find indicators.yaml config file.",
    "Set UNICEF_CONFIG_PATH environment variable",
    "or ensure config/indicators.yaml exists."
  ))
}

# ============================================================================
# Config Loading Functions
# ============================================================================

#' Load the full configuration from YAML
#'
#' @param config_path Optional explicit path to config file
#' @return Full configuration list
#' @export
load_config <- function(config_path = NULL) {
  if (is.null(config_path)) {
    config_path <- get_config_path()
  }
  yaml::read_yaml(config_path)
}

#' Load indicator definitions from shared config
#'
#' @param config_path Optional explicit path to config file
#' @return Named list of indicator definitions
#' @export
load_shared_indicators <- function(config_path = NULL) {
  config <- load_config(config_path)
  indicators <- config$indicators
  
  if (is.null(indicators)) {
    return(list())
  }
  
  # Transform to consistent format
  result <- list()
  for (code in names(indicators)) {
    info <- indicators[[code]]
    result[[code]] <- list(
      code = info$code %||% code,
      name = info$name %||% code,
      dataflow = info$dataflow,
      sdg_target = info$sdg_target,
      unit = info$unit,
      category = info$category,
      description = info$description
    )
  }
  
  result
}

#' Load dataflow definitions from shared config
#'
#' @param config_path Optional explicit path to config file
#' @return Named list of dataflow definitions
#' @export
load_shared_dataflows <- function(config_path = NULL) {
  config <- load_config(config_path)
  config$dataflows %||% list()
}

#' Load category definitions from shared config
#'
#' @param config_path Optional explicit path to config file
#' @return Named list of category definitions
#' @export
load_shared_categories <- function(config_path = NULL) {
  config <- load_config(config_path)
  config$categories %||% list()
}

# ============================================================================
# Filtering Functions
# ============================================================================

#' Get indicator codes by category
#'
#' @param category Category name (e.g., 'mortality', 'nutrition')
#' @param config_path Optional explicit path to config file
#' @return Character vector of indicator codes
#' @export
get_indicators_by_category <- function(category, config_path = NULL) {
  config <- load_config(config_path)
  indicators <- config$indicators
  
  codes <- character()
  for (code in names(indicators)) {
    if (identical(indicators[[code]]$category, category)) {
      codes <- c(codes, code)
    }
  }
  codes
}

#' Get indicator codes by SDG goal
#'
#' @param sdg_goal SDG goal number (e.g., '3', '4')
#' @param config_path Optional explicit path to config file
#' @return Character vector of indicator codes
#' @export
get_indicators_by_sdg <- function(sdg_goal, config_path = NULL) {
  config <- load_config(config_path)
  indicators <- config$indicators
  
  prefix <- paste0(sdg_goal, ".")
  codes <- character()
  for (code in names(indicators)) {
    target <- indicators[[code]]$sdg_target
    if (!is.null(target) && startsWith(target, prefix)) {
      codes <- c(codes, code)
    }
  }
  codes
}

#' Get indicator codes by dataflow
#'
#' @param dataflow Dataflow name (e.g., 'CME', 'NUTRITION')
#' @param config_path Optional explicit path to config file
#' @return Character vector of indicator codes
#' @export
get_indicators_by_dataflow <- function(dataflow, config_path = NULL) {
  config <- load_config(config_path)
  indicators <- config$indicators
  
  codes <- character()
  for (code in names(indicators)) {
    if (identical(indicators[[code]]$dataflow, dataflow)) {
      codes <- c(codes, code)
    }
  }
  codes
}

#' Get all available indicator codes
#'
#' @param category Optional: filter by category
#' @param sdg_goal Optional: filter by SDG goal
#' @param dataflow Optional: filter by dataflow
#' @param config_path Optional explicit path to config file
#' @return Character vector of indicator codes
#' @export
get_indicator_codes <- function(
  category = NULL,
  sdg_goal = NULL,
  dataflow = NULL,
  config_path = NULL
) {
  config <- load_config(config_path)
  indicators <- config$indicators
  
  codes <- character()
  for (code in names(indicators)) {
    info <- indicators[[code]]
    
    # Apply filters
    if (!is.null(category) && !identical(info$category, category)) {
      next
    }
    if (!is.null(sdg_goal)) {
      prefix <- paste0(sdg_goal, ".")
      if (is.null(info$sdg_target) || !startsWith(info$sdg_target, prefix)) {
        next
      }
    }
    if (!is.null(dataflow) && !identical(info$dataflow, dataflow)) {
      next
    }
    
    codes <- c(codes, code)
  }
  
  sort(codes)
}

# ============================================================================
# Null-coalescing operator (for R < 4.4)
# ============================================================================

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# ============================================================================
# Cached Config
# ============================================================================

.config_cache <- new.env()

#' Get cached configuration (loads once, reuses thereafter)
#'
#' @param config_path Optional explicit path to config file
#' @return Full configuration list
#' @export
get_cached_config <- function(config_path = NULL) {
  if (is.null(.config_cache$config)) {
    .config_cache$config <- load_config(config_path)
  }
  .config_cache$config
}

#' Clear the cached configuration
#' @export
clear_config_cache <- function() {
  .config_cache$config <- NULL
  invisible(NULL)
}

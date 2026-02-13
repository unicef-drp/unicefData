# =============================================================================
# unicef_core.R - Core data fetching with intelligent fallback logic
# =============================================================================
#
# PURPOSE:
#   Low-level data fetching engine for UNICEF SDMX API. Handles HTTP requests,
#   dataflow detection, fallback logic, and data cleaning. Called by the
#   user-facing unicefData.R module.
#
# STRUCTURE:
#   1. Imports & Setup - Package dependencies and environment
#   2. YAML Loaders - Metadata, fallback sequences, region codes
#   3. HTTP Helpers - SDMX fetch with retry and 404 handling
#   4. Dataflow Detection - Auto-detect and fallback logic
#   5. Data Fetching - Raw API calls with pagination
#   6. Data Cleaning - Column standardization
#   7. Data Filtering - Disaggregation filtering
#   8. Schema Validation - Structure verification
#
# Version: 1.6.1 (2026-01-12) - Unified fallback architecture
# Author: João Pedro Azevedo (UNICEF)
# License: MIT
# =============================================================================


# =============================================================================
# #### 1. Imports & Setup ####
# =============================================================================

# Lazy-load fallback sequences at first use (not at module init) to respect working directory
.FALLBACK_ENV <- new.env(parent = emptyenv())

#' @import dplyr
#' @importFrom magrittr %>%
#' @importFrom stats na.omit setNames
#' @importFrom utils capture.output head write.csv
NULL

# Ensure required packages are loaded
if (!requireNamespace("magrittr", quietly = TRUE)) stop("Package 'magrittr' required")
if (!requireNamespace("dplyr", quietly = TRUE)) stop("Package 'dplyr' required")
if (!requireNamespace("httr", quietly = TRUE)) stop("Package 'httr' required")
if (!requireNamespace("readr", quietly = TRUE)) stop("Package 'readr' required")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Package 'yaml' required")

`%>%` <- magrittr::`%>%`


#' Check if an error is an HTTP 404 response
#'
#' @param e An error condition object
#' @return TRUE if the error represents a 404 Not Found, FALSE otherwise
#' @keywords internal
.is_http_404 <- function(e) {
  if (inherits(e, "sdmx_404")) return(TRUE)
  if (inherits(e, "http_404")) return(TRUE)

  resp <- tryCatch(e$response, error = function(x) NULL)
  if (!is.null(resp) && inherits(resp, "response")) {
    return(httr::status_code(resp) == 404)
  }

  FALSE
}

# =============================================================================
# #### 2. YAML Loaders ####
# =============================================================================

#' Load comprehensive indicators metadata from canonical YAML file
#'
#' Enables direct dataflow lookup by indicator code instead of using prefix-based 
#' fallback sequences. Much faster (O(1) vs trying multiple dataflows).
#'
#' @return List with indicators metadata (indicator code -> dataflow mapping, etc.)
#' @keywords internal
.load_indicators_metadata_yaml <- function() {
  candidates <- c(
    # Workspace root (where user is editing) - inst/metadata/current/ in dev repo
    file.path(getwd(), 'inst', 'metadata', 'current', '_unicefdata_indicators_metadata.yaml'),
    # Stata src folder (canonical source in private -dev repo)
    file.path(getwd(), 'stata', 'src', '__unicefdata_indicators_metadata.yaml'),
    # Package bundled location (inst/ is stripped at install time)
    system.file('metadata', 'current', '_unicefdata_indicators_metadata.yaml', package = 'unicefData', mustWork = FALSE)
  )
  
  for (candidate in candidates) {
    if (file.exists(candidate)) {
      tryCatch({
        yaml_data <- yaml::read_yaml(candidate)
        if (!is.null(yaml_data$indicators)) {
          if (grepl('workspace|stata', candidate)) {
            message(sprintf("Loaded comprehensive indicators metadata from: %s", candidate))
          }
          return(yaml_data$indicators)
        }
      }, error = function(e) {
        warning(sprintf("Error loading YAML from %s: %s. Trying next location...", candidate, e$message))
      })
    }
  }
  
  # No metadata file found - will fall back to prefix-based logic
  message("No comprehensive indicators metadata found. Will use prefix-based fallback sequences.")
  return(NULL)
}

#' Load fallback dataflow sequences from canonical YAML (shared with Python/Stata)
#'
#' Reads _dataflow_fallback_sequences.yaml from the workspace root or package metadata.
#' This ensures all languages (Stata, Python, R) use identical dataflow resolution logic.
#'
#' @return List with fallback sequences by indicator prefix
#' @keywords internal
.load_fallback_sequences_yaml <- function() {
  # Priority 1: Check workspace root (where user has latest YAML)
  candidates <- c(
    # Workspace root (where user is editing) - inst/metadata/current/ in dev repo
    file.path(getwd(), 'inst', 'metadata', 'current', '_dataflow_fallback_sequences.yaml'),
    # Python metadata folder (cross-platform metadata source)
    file.path(getwd(), 'python', 'metadata', 'current', '_dataflow_fallback_sequences.yaml'),
    # Stata src folder (canonical source in private -dev repo)
    file.path(getwd(), 'stata', 'src', '_', '_dataflow_fallback_sequences.yaml'),
    # Package bundled location (inst/ is stripped at install time)
    system.file('metadata', 'current', '_dataflow_fallback_sequences.yaml', package = 'unicefData', mustWork = FALSE)
  )
  
  for (candidate in candidates) {
    if (file.exists(candidate)) {
      tryCatch({
        yaml_data <- yaml::read_yaml(candidate)
        if (!is.null(yaml_data$fallback_sequences)) {
          if (grepl('workspace|stata', candidate)) {
            message(sprintf("Loaded canonical dataflow fallback sequences from: %s", candidate))
          }
          return(yaml_data$fallback_sequences)
        }
      }, error = function(e) {
        warning(sprintf("Error loading YAML from %s: %s. Trying next location...", candidate, e$message))
      })
    }
  }
  
  # No YAML found - return NULL (will fall back to GLOBAL_DATAFLOW)
  warning("Could not load canonical _dataflow_fallback_sequences.yaml from workspace or package. Will use GLOBAL_DATAFLOW as fallback.")
  NULL
}

#' Get fallback dataflow sequences (lazy loading)
#'
#' Returns cached fallback sequences, loading from YAML on first access.
#' Used for dataflow discovery when indicator is not in primary dataflow.
#'
#' @return Named list of fallback sequences by prefix, or NULL if not available
#' @keywords internal
.get_fallback_sequences <- function() {
  if (!exists("sequences", envir = .FALLBACK_ENV, inherits = FALSE)) {
    assign("sequences", .load_fallback_sequences_yaml(), envir = .FALLBACK_ENV)
  }
  get("sequences", envir = .FALLBACK_ENV, inherits = FALSE)
}
# Load comprehensive indicators metadata at module initialization
.INDICATORS_METADATA_YAML <- .load_indicators_metadata_yaml()

#' Load aggregate/region ISO3 codes for geo_type classification
#'
#' Reads _unicefdata_regions.yaml to get codes for regions, income groups, and 
#' other aggregates. Returns a set of ISO3 codes for use in geo_type derivation.
#' This ensures parity with Stata and Python implementations.
#'
#' @return Character vector of ISO3 codes that are aggregates
#' @keywords internal
.load_region_codes_yaml <- function() {
  candidates <- c(
    # Workspace root (where user is editing) - inst/metadata/current/ in dev repo
    file.path(getwd(), 'inst', 'metadata', 'current', '_unicefdata_regions.yaml'),
    # Stata src folder (canonical source in private -dev repo)
    file.path(getwd(), 'stata', 'src', '_', '_unicefdata_regions.yaml'),
    # Package bundled location (inst/ is stripped at install time)
    system.file('metadata', 'current', '_unicefdata_regions.yaml', package = 'unicefData', mustWork = FALSE)
  )
  
  for (candidate in candidates) {
    if (file.exists(candidate)) {
      tryCatch({
        yaml_data <- yaml::read_yaml(candidate)
        if (!is.null(yaml_data$regions) && is.list(yaml_data$regions)) {
          codes <- names(yaml_data$regions)
          if (grepl('workspace|stata', candidate)) {
            message(sprintf("Loaded aggregate/region codes from: %s (%d codes)", candidate, length(codes)))
          }
          return(codes)
        }
      }, error = function(e) {
        warning(sprintf("Error loading YAML from %s: %s. Trying next location...", candidate, e$message))
      })
    }
  }
  
  warning(
    "Could not load _unicefdata_regions.yaml. geo_type will default to country (0). ",
    "Ensure metadata/current/_unicefdata_regions.yaml is available for parity with Stata/Python."
  )
  return(character(0))  # Return empty vector if no file found
}

# Load region codes at module initialization
.REGION_CODES_YAML <- .load_region_codes_yaml()


#' Clear All UNICEF Caches
#'
#' Resets all in-memory caches across the package: indicator metadata,
#' fallback sequences, region codes, schema cache, and config cache.
#' After clearing, the next API call will reload all metadata from
#' YAML files (or fetch fresh from the API if file cache is stale).
#'
#' @param reload Logical. If TRUE (default), immediately reload YAML-based
#'   caches (indicators metadata, fallback sequences, region codes).
#'   If FALSE, caches are cleared but not reloaded until next use.
#' @param verbose Logical. If TRUE, print what was cleared.
#'
#' @return Invisibly returns a named list of cleared cache names.
#' @export
#'
#' @examples
#' \dontrun{
#'   # Clear everything and reload
#'   clear_unicef_cache()
#'
#'   # Clear without reloading (lazy reload on next use)
#'   clear_unicef_cache(reload = FALSE)
#' }
clear_unicef_cache <- function(reload = TRUE, verbose = TRUE) {
  cleared <- character(0)
  ns <- environment(clear_unicef_cache)

  # 1. Fallback sequences (unicef_core.R)
  if (exists("sequences", envir = .FALLBACK_ENV, inherits = FALSE)) {
    rm("sequences", envir = .FALLBACK_ENV)
  }
  cleared <- c(cleared, "fallback_sequences")

  # 2. Indicators metadata YAML (unicef_core.R)
  tryCatch({
    unlockBinding(".INDICATORS_METADATA_YAML", ns)
    assign(".INDICATORS_METADATA_YAML", NULL, envir = ns)
  }, error = function(e) NULL)
  cleared <- c(cleared, "indicators_metadata")

  # 3. Region codes YAML (unicef_core.R)
  tryCatch({
    unlockBinding(".REGION_CODES_YAML", ns)
    assign(".REGION_CODES_YAML", NULL, envir = ns)
  }, error = function(e) NULL)
  cleared <- c(cleared, "region_codes")

  # 4. Indicator registry cache (indicator_registry.R)
  .indicator_cache$data <- NULL
  .indicator_cache$loaded <- FALSE
  .indicator_cache$fallback_sequences <- NULL
  .indicator_cache$fallback_loaded <- FALSE
  cleared <- c(cleared, "indicator_registry")

  # 5. Schema cache (schema_cache.R)
  rm(list = ls(envir = .schema_cache_env), envir = .schema_cache_env)
  cleared <- c(cleared, "schema_cache")

  # 6. Config cache (config_loader.R)
  .config_cache$config <- NULL
  cleared <- c(cleared, "config_cache")

  # Reload YAML-based caches if requested
  if (reload) {
    tryCatch({
      assign(".INDICATORS_METADATA_YAML", .load_indicators_metadata_yaml(), envir = ns)
      lockBinding(".INDICATORS_METADATA_YAML", ns)
    }, error = function(e) NULL)
    tryCatch({
      assign(".REGION_CODES_YAML", .load_region_codes_yaml(), envir = ns)
      lockBinding(".REGION_CODES_YAML", ns)
    }, error = function(e) NULL)
    # Fallback sequences reload lazily via .get_fallback_sequences()
  }

  if (verbose) {
    msg <- sprintf("Cleared %d caches: %s", length(cleared), paste(cleared, collapse = ", "))
    if (reload) msg <- paste0(msg, " (YAML caches reloaded)")
    message(msg)
  }

  invisible(cleared)
}


# =============================================================================
# #### 3. HTTP Helpers ####
# =============================================================================

#' Fetch SDMX content as text
#'
#' @param url URL to fetch
#' @param ua User agent string
#' @param retry Number of retries
#' @return Content as text
#' @keywords internal
fetch_sdmx_text <- function(url, ua = .unicefData_ua, retry) {
  resp <- httr::RETRY("GET", url, ua, times = retry, pause_base = 1)
  status <- httr::status_code(resp)
  # 404 error
  if (identical(status, 404L)) {
    stop(
      structure(
        list(message = sprintf("Not Found (404): %s", url), url = url, status = status),
        class = c("sdmx_404", "error", "condition")
      )
    )
  }
  # for other errors we can keep the normal behaviour
  httr::stop_for_status(resp)
  httr::content(resp, as = "text", encoding = "UTF-8")
}

# =============================================================================
# #### 4. Dataflow Detection ####
# =============================================================================

#' @title Detect Dataflow from Indicator
#' @description Auto-detects the correct dataflow for a given indicator code.
#' @param indicator Indicator code (e.g. "CME_MRY0T4")
#' @return Character string of dataflow ID
#' @export
detect_dataflow <- function(indicator) {
  if (is.null(indicator)) return(NULL)

  # Infer from prefix (fallback if not in metadata)
  parts <- strsplit(indicator, "_")[[1]]
  prefix <- parts[1]

  # Note: Hardcoded prefix_map removed - use fallback sequences from YAML
  # Get fallback dataflows for this prefix
    # Use lazy-loading helper to get fallback sequences (loads at runtime when getwd is set)
    fallback_sequences <- .get_fallback_sequences()
    if (!is.null(fallback_sequences) && prefix %in% names(fallback_sequences)) {
      sequence <- fallback_sequences[[prefix]]
    if (length(sequence) > 0) {
      return(sequence[1])  # Return first dataflow in sequence
    }
  }

  return("GLOBAL_DATAFLOW")
}

#' Get fallback dataflows for an indicator
#'
#' Returns alternative dataflows to try when the primary dataflow fails.
#' Uses comprehensive indicators metadata for direct lookup, falling back
#' to prefix-based sequences from canonical YAML.
#'
#' @param original_flow Character string of the original dataflow that failed
#' @param indicator_code Optional indicator code for direct metadata lookup
#' @return Character vector of fallback dataflow IDs to try
#' @keywords internal
get_fallback_dataflows <- function(original_flow, indicator_code = NULL) {
  # Build prefix-specific fallback chains from canonical YAML or comprehensive metadata
  fallbacks <- c()
  
  # If we have an indicator code, first try direct metadata lookup
  if (!is.null(indicator_code)) {
    # Priority 1: Direct lookup in comprehensive indicators metadata
    # Check both 'dataflow' (singular) and 'dataflows' (plural) fields
    if (!is.null(.INDICATORS_METADATA_YAML) && indicator_code %in% names(.INDICATORS_METADATA_YAML)) {
      meta <- .INDICATORS_METADATA_YAML[[indicator_code]]
      # Check 'dataflows' (plural) first, then 'dataflow' (singular)
      dataflow_value <- meta$dataflows %||% meta$dataflow
      if (!is.null(dataflow_value)) {
        # Handle both list and scalar values
        if (is.list(dataflow_value)) {
          dataflows_list <- unlist(dataflow_value)
        } else {
          dataflows_list <- dataflow_value
        }
        # Return dataflows that are different from original_flow
        fallbacks <- setdiff(dataflows_list, original_flow)
        if (length(fallbacks) > 0) {
          return(fallbacks)
        }
        # If all dataflows match original_flow, return empty (no fallback needed)
        return(c())
      }
    }
    
    # Priority 2: Prefix-based fallback sequences (fallback for indicators not in metadata)
    prefix <- strsplit(indicator_code, "_")[[1]][1]
    fallback_sequences <- .get_fallback_sequences()
    if (!is.null(fallback_sequences) && prefix %in% names(fallback_sequences)) {
      fallbacks <- fallback_sequences[[prefix]]
    } else if (!is.null(fallback_sequences) && "DEFAULT" %in% names(fallback_sequences)) {
      # Use default fallback for unknown prefixes
      fallbacks <- fallback_sequences$DEFAULT %||% c("GLOBAL_DATAFLOW")
    } else {
      fallbacks <- c("GLOBAL_DATAFLOW")
    }
    
    # Remove the original_flow from fallbacks to avoid duplicate attempts
    fallbacks <- setdiff(fallbacks, original_flow)
  } else {
    # No indicator code provided, use generic fallback
    if (!is.null(original_flow) && !identical(original_flow, "GLOBAL_DATAFLOW")) {
      fallbacks <- c("GLOBAL_DATAFLOW")
    }
  }
  
  return(fallbacks)
}

# =============================================================================
# #### 5. Data Fetching ####
# =============================================================================

#' Fetch data from a single dataflow with 404 detection
#'
#' Low-level helper that fetches indicator data from a specific dataflow.
#' Returns status "not_found" for 404 errors (allowing fallback to other dataflows)
#' or throws for other errors.
#'
#' @param indicator Character vector of indicator codes
#' @param dataflow Character string of dataflow ID
#' @param countries Character vector of ISO3 country codes (optional)
#' @param start_year_str Character string of start year (optional)
#' @param end_year_str Character string of end year (optional)
#' @param max_retries Integer number of retry attempts
#' @param version SDMX version string (default "1.0")
#' @param verbose Logical for progress messages
#' @param totals Logical for including totals
#' @param labels Label format ("id" or "name")
#' @return List with status ("ok" or "not_found") and df (data.frame or NULL)
#' @keywords internal
.fetch_one_flow <- function(
    indicator,
    dataflow,
    countries = NULL,
    start_year_str = NULL,
    end_year_str = NULL,
    max_retries = 3,
    version = "1.0",
  verbose = TRUE,
  totals = FALSE,
  labels = "id"
) {
  base <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
  if (is.null(indicator) || length(indicator) == 0) {
    indicator_str <- ""
  } else {
    indicator <- trimws(as.character(indicator))
    indicator <- indicator[nzchar(indicator)]
    indicator_str <- if (length(indicator) > 0) {
      paste0(".", paste(indicator, collapse = "+"), ".")
    } else {
      ""
    }
  }

  # Override and expand dimensions for WS_HCF_* to expose service/hcf/residence breakdowns
  if (!is.null(indicator) && length(indicator) == 1 && grepl("^WS_HCF_", toupper(indicator[[1]]))) {
    dataflow <- "WASH_HEALTHCARE_FACILITY"
    code <- toupper(indicator[[1]])
    tail <- sub("^WS_HCF_", "", code)
    service_type <- ""
    if (grepl("^W-", tail)) {
      service_type <- "WAT"
    } else if (grepl("^S-", tail)) {
      service_type <- "SAN"
    } else if (grepl("^H-", tail)) {
      service_type <- "HYG"
    } else if (grepl("^WM-", tail)) {
      service_type <- "HCW"
    } else if (grepl("^C-", tail)) {
      service_type <- "CLEAN"
    }
    hcf_vals <- c("_T","NON_HOS","HOS","GOV","NON_GOV")
    res_vals <- c("_T","U","R")
    hcf_part <- paste(hcf_vals, collapse = "+")
    res_part <- paste(res_vals, collapse = "+")
    if (nzchar(service_type)) {
      indicator_str <- paste0(".", code, ".", service_type, ".", hcf_part, ".", res_part)
    } else {
      indicator_str <- paste0(".", code, "..", hcf_part, ".", res_part)
    }
  }
  # Explicit totals across known dimensions when requested
  if (totals && !is.null(indicator) && length(indicator) > 0 && !grepl("^WS_HCF_", toupper(indicator[[1]]))) {
    # Attempt to load schema to determine dimension count
    if (!exists("load_dataflow_schema", mode = "function")) {
      script_dir <- dirname(sys.frame(1)$ofile %||% ".")
      schema_script <- file.path(script_dir, "schema_sync.R")
      if (file.exists(schema_script)) source(schema_script)
    }
    dim_suffix <- "._T"
    if (exists("load_dataflow_schema", mode = "function")) {
      schema <- tryCatch(load_dataflow_schema(dataflow), error = function(e) NULL)
      if (!is.null(schema) && !is.null(schema$dimensions)) {
        ids <- vapply(schema$dimensions, function(d) d$id, character(1))
        ids <- ids[!(ids %in% c("REF_AREA", "INDICATOR"))]
        if (length(ids) > 0) {
          dim_suffix <- paste0(".", paste(rep("_T", length(ids)), collapse = "."))
        }
      }
    }
    indicator_str <- paste0(indicator_str, sub("^\\.", "", dim_suffix))
  }
  rel_path <- if (nzchar(indicator_str)) {
    sprintf("data/UNICEF,%s,%s/%s", dataflow, version, indicator_str)
  } else {
    sprintf("data/UNICEF,%s,%s/", dataflow, version)
  }

  # Validate labels parameter
  if (!labels %in% c("id", "both", "none")) {
    stop(sprintf("labels must be 'id', 'both', or 'none', got '%s'", labels))
  }

  # Default: request codes only to prevent duplicate label columns (cross-platform consistency)
  # labels parameter can be "id", "both", or "none"
  # Value labels can be applied client-side if needed
  full_url <- paste0(base, "/", rel_path, "?format=csv&labels=", labels)
  if (!is.null(start_year_str)) full_url <- paste0(full_url, "&startPeriod=", start_year_str)
  if (!is.null(end_year_str))   full_url <- paste0(full_url, "&endPeriod=", end_year_str)

  # Shared dynamic User-Agent
  ua <- .unicefData_ua

  if (verbose) message("Fetching data...")

  # IMPORTANT: catch 404 as a signal, not a fatal error
  out <- tryCatch(
    {
      txt <- fetch_sdmx_text(full_url, ua = ua, retry = max_retries)  # 'retry' matches function signature
      readr::read_csv(I(txt), show_col_types = FALSE)
    },
    error = function(e) e
  )

  if (inherits(out, "error")) {
    if (.is_http_404(out)) {
      # "Not in this dataflow"
      return(list(status = "not_found", df = NULL))
    }
    # Any other error is still fatal (transient errors should be handled by RETRY)
    stop(out)
  }

  df_all <- out
  if (is.null(df_all)) {
    df_all <- dplyr::tibble()
  }

  # Filter countries (post-fetch)
  if (!is.null(countries) && nrow(df_all) > 0 && "REF_AREA" %in% names(df_all)) {
    df_all <- df_all %>% dplyr::filter(REF_AREA %in% countries)
  }

  list(status = "ok", df = df_all)
}


#' @title Fetch Raw UNICEF Data
#' @description Low-level fetcher for UNICEF SDMX API.
#' @param indicator Character vector of indicator codes.
#' @param dataflow Character string of dataflow ID.
#' @param countries Character vector of ISO3 codes.
#' @param start_year Numeric or character start year (YYYY).
#' @param end_year Numeric or character end year (YYYY).
#' @param max_retries Integer, number of retries for failed requests.
#' @param version Character string of SDMX version (e.g. "1.0").
#' @param verbose Logical, print progress messages.
#' @param totals Logical, include total aggregations.
#' @param labels Character, label format ("id" or "name").
#' @export
unicefData_raw <- function(
    indicator = NULL,
    dataflow = NULL,
    countries = NULL,
    start_year = NULL,
    end_year = NULL,
    max_retries = 3,
    version = NULL,
    verbose = TRUE,
    totals = FALSE,
    labels = "id"
) {
  # Validate indicator input to prevent hard-to-read API 400 errors.
  if (!is.null(indicator)) {
    indicator <- as.character(indicator)
    indicator <- trimws(indicator)

    if (length(indicator) == 0 || all(!nzchar(indicator))) {
      stop(
        "`indicator` cannot be empty. Provide a valid indicator code (e.g., 'CME_MRY0T4').\n",
        "Use search_indicators() to find available indicator codes."
      )
    }

    if (any(!nzchar(indicator))) {
      stop(
        "`indicator` contains empty value(s). Remove blank entries and try again.\n",
        "Use search_indicators() to find available indicator codes."
      )
    }
  }

  # Validate inputs
  if (is.null(dataflow) && is.null(indicator)) {
    stop("Either 'indicator' or 'dataflow' must be specified.")
  }

  # Validate year
  validate_year <- function(x) {
    if (!is.null(x)) {
      x_chr <- as.character(x)
      if (!grepl("^\\d{4}$", x_chr)) stop("Year must be 4 digits")
      return(x_chr)
    }
    NULL
  }
  start_year_str <- validate_year(start_year)
  end_year_str <- validate_year(end_year)

  # Get version if needed
  ver <- version %||% "1.0" # Simplified version handling for raw fetch

  # determine primary dataflow
  if (is.null(dataflow)) {
    dataflow <- detect_dataflow(indicator[1])
    if (verbose) message(sprintf("Auto-detected dataflow: '%s'", dataflow))
  }

  # Candidate flows: primary + fallbacks
  flows <- dataflow
  if (!is.null(indicator)) {
    fb <- get_fallback_dataflows(original_flow = dataflow, indicator_code = indicator[1])
    if (length(fb) > 0) flows <- unique(c(dataflow, fb))
  }

  last_not_found <- FALSE
  for (flow in flows) {
    if (verbose && !identical(flow, dataflow)) {
      message(sprintf("Trying fallback dataflow '%s'...", flow))
    }

    res <- .fetch_one_flow(
      indicator = indicator,
      dataflow  = flow,
      countries = countries,
      start_year_str = start_year_str,
      end_year_str   = end_year_str,
      max_retries = max_retries,
      version = ver,
      verbose = verbose,
      totals = totals,
      labels = labels
    )

    if (identical(res$status, "ok")) {
      return(res$df)
    }

    if (identical(res$status, "not_found")) {
      last_not_found <- TRUE
      next
    }
  }

  # If all candidates were 404 (indicator not found in any attempted flow), return empty
  if (last_not_found) {
    # Always show which dataflows were tried (not just when verbose)
    warning(sprintf(
      "Not Found (404): Indicator '%s' not found in any dataflow.\n  Tried dataflows: %s\n  Browse available indicators at: https://data.unicef.org/",
      indicator[1], paste(flows, collapse = ", ")
    ), call. = FALSE)
    return(dplyr::tibble())
  }

  # Otherwise: no pages but not 404 -> empty
  dplyr::tibble()
}

#
#
#   # Build URL
#   base <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
#   indicator_str <- if (!is.null(indicator)) paste0(".", paste(indicator, collapse = "+"), ".") else "."
#   rel_path <- sprintf("data/UNICEF,%s,%s/%s", dataflow, ver, indicator_str)
#   full_url <- paste0(base, "/", rel_path, "?format=csv&labels=both")
#
#   if (!is.null(start_year_str)) full_url <- paste0(full_url, "&startPeriod=", start_year_str)
#   if (!is.null(end_year_str)) full_url <- paste0(full_url, "&endPeriod=", end_year_str)
#
#   # Paging
#   ua <- httr::user_agent("unicefData/1.0")
#   pages <- list()
#   page <- 0L
#
#   repeat {
#     page_url <- full_url
#     if (verbose) message(sprintf("Fetching page %d...", page + 1))
#     # this NULL here masks 404, let's fix and make fallback possible:
#     df <- tryCatch(
#       readr::read_csv(fetch_sdmx_text(page_url, ua, max_retries), show_col_types = FALSE),
#       error = function(e) {

#' @title Validate Data Against Schema
#' @description Checks if dataframe matches expected schema. Warns on mismatch.
#' @export
validate_unicef_schema <- function(df, dataflow) {
  # Ensure schema_sync is loaded
  if (!exists("load_dataflow_schema", mode = "function")) {
    script_dir <- dirname(sys.frame(1)$ofile %||% ".")
    schema_script <- file.path(script_dir, "schema_sync.R")
    if (file.exists(schema_script)) source(schema_script)
  }

  if (exists("load_dataflow_schema", mode = "function")) {
    schema <- load_dataflow_schema(dataflow)
    if (!is.null(schema)) {
      # Check dimensions
      expected_dims <- sapply(schema$dimensions, function(d) d$id)
      missing_dims <- setdiff(expected_dims, names(df))
      if (length(missing_dims) > 0) {
        warning(sprintf("Dataflow '%s': Missing expected dimensions: %s",
                        dataflow, paste(missing_dims, collapse = ", ")))
      }

      # Check attributes (optional but good to know)
      expected_attrs <- sapply(schema$attributes, function(a) a$id)
      missing_attrs <- setdiff(expected_attrs, names(df))
      # Don't warn for attributes as they are often optional
    }
  }
}

# =============================================================================
# #### 6. Data Cleaning ####
# =============================================================================

#' @title Clean and Standardize UNICEF Data
#' @description Renames columns and converts types.
#' @param df Data frame to clean.
#' @export
clean_unicef_data <- function(df) {
  if (nrow(df) == 0) return(df)

  # Rename map
  rename_map <- c(
    "indicator" = "INDICATOR", "indicator_name" = "Indicator",
    "iso3" = "REF_AREA", "country" = "Geographic area",
    "unit" = "UNIT_MEASURE", "unit_name" = "Unit of measure",
    "sex" = "SEX", "sex_name" = "Sex",
    "age" = "AGE", "wealth_quintile" = "WEALTH_QUINTILE",
    "wealth_quintile_name" = "Wealth Quintile", "residence" = "RESIDENCE",
    "maternal_edu_lvl" = "MATERNAL_EDU_LVL", "lower_bound" = "LOWER_BOUND",
    "upper_bound" = "UPPER_BOUND", "obs_status" = "OBS_STATUS",
    "obs_status_name" = "Observation Status", "data_source" = "DATA_SOURCE",
    "ref_period" = "REF_PERIOD", "country_notes" = "COUNTRY_NOTES"
  )

  existing_renames <- rename_map[rename_map %in% names(df)]
  df_clean <- df %>% dplyr::rename(!!!existing_renames)

  # Convert period
  convert_period <- function(val) {
    if (is.na(val)) return(NA_real_)
    val_str <- as.character(val)
    if (grepl("^\\d{4}-\\d{2}", val_str)) {
      parts <- strsplit(val_str, "-")[[1]]
      return(as.numeric(parts[1]) + as.numeric(parts[2])/12)
    }
    as.numeric(val_str)
  }

  if ("TIME_PERIOD" %in% names(df_clean)) {
    df_clean$period <- sapply(df_clean$TIME_PERIOD, convert_period)
    df_clean$value <- as.numeric(df_clean$OBS_VALUE)
    df_clean <- df_clean %>% dplyr::select(-TIME_PERIOD, -OBS_VALUE)
  }

  # Standard columns
  standard_cols <- c("indicator", "indicator_name", "iso3", "country", "geo_type", "period", "value",
                     "unit", "unit_name", "sex", "sex_name", "age",
                     "wealth_quintile", "wealth_quintile_name", "residence",
                     "maternal_edu_lvl", "lower_bound", "upper_bound",
                     "obs_status", "obs_status_name", "data_source",
                     "ref_period", "country_notes")

  for (col in standard_cols) {
    if (!col %in% names(df_clean)) df_clean[[col]] <- NA_character_
  }

  # Reorder
  extra_cols <- setdiff(names(df_clean), standard_cols)
  df_clean <- df_clean %>% dplyr::select(dplyr::all_of(standard_cols), dplyr::all_of(extra_cols))

  # Add country names if missing
  if (all(is.na(df_clean$country)) && "iso3" %in% names(df_clean)) {
    df_clean <- df_clean %>%
      dplyr::select(-country) %>%
      dplyr::left_join(
        countrycode::codelist %>% dplyr::select(iso3 = iso3c, country = country.name.en),
        by = "iso3"
      ) %>%
      dplyr::select(iso3, country, dplyr::everything())
  }

  # Add geo_type: 1 for aggregates (ISO3 in YAML regions list), 0 otherwise (numeric)
  if ("iso3" %in% names(df_clean)) {
    if (length(.REGION_CODES_YAML) == 0) {
      warning("geo_type classification: region codes not loaded; treating all as country (0).")
    }
    df_clean <- df_clean %>%
      dplyr::mutate(
        geo_type = dplyr::if_else(iso3 %in% .REGION_CODES_YAML, 1L, 0L)
      )
  }

  return(df_clean)
}
# =============================================================================
# #### 7. Data Filtering ####
# =============================================================================

#' @title Filter UNICEF Data (Sex, Age, Wealth, etc.)
#' @description Filters data to specific disaggregations or defaults to totals.
#'   Uses indicator metadata (disaggregations_with_totals) to determine which
#'   dimensions have _T totals and should be filtered by default.
#' @param df Data frame to filter.
#' @param sex Character string for sex filter (e.g. "F", "M", "_T").
#' @param age Character string for age filter.
#' @param wealth Character string for wealth quintile filter.
#' @param residence Character string for residence filter.
#' @param maternal_edu Character string for maternal education filter.
#' @param verbose Logical, print progress messages.
#' @param indicator_code Optional indicator code to enable metadata-driven filtering.
#'   Placed at end to preserve backward compatibility with existing positional calls.
#' @param dataflow Optional dataflow name for dataflow-specific filtering logic.
#'   For NUTRITION dataflow, age defaults to Y0T4 instead of _T.
#' @export
filter_unicef_data <- function(df, sex = NULL, age = NULL, wealth = NULL, residence = NULL, maternal_edu = NULL, verbose = TRUE, indicator_code = NULL, dataflow = NULL) {
  if (nrow(df) == 0) return(df)

  available_disaggregations <- c()
  applied_filters <- c()
  skipped_filters <- c()

  # Get indicator metadata for smart filtering (disaggregations_with_totals)
  dims_with_totals <- c()
  if (!is.null(indicator_code) && !is.null(.INDICATORS_METADATA_YAML) &&
      indicator_code %in% names(.INDICATORS_METADATA_YAML)) {
    meta <- .INDICATORS_METADATA_YAML[[indicator_code]]
    if (!is.null(meta$disaggregations_with_totals)) {
      dims_with_totals <- meta$disaggregations_with_totals
      if (verbose) {
        message(sprintf("Using metadata for %s: dimensions with totals = %s",
                        indicator_code, paste(dims_with_totals, collapse = ", ")))
      }
    }
  }

  # Filter by sex (default is "_T" for total)
  # STATA-STYLE: Only filter if value exists; otherwise keep all data
  if ("SEX" %in% names(df)) {
    sex_values <- unique(na.omit(df$SEX))
    if (length(sex_values) > 1 || (length(sex_values) == 1 && sex_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("sex: ", paste(sex_values, collapse = ", ")))
    }
    if (!is.null(sex) && !identical(sex, "ALL")) {
      # Check if requested value exists before filtering (Stata behavior)
      if (any(sex %in% sex_values)) {
        df <- df %>% dplyr::filter(SEX %in% sex)
        applied_filters <- c(applied_filters, paste0("sex: ", paste(sex, collapse = ", ")))
      } else {
        # Value not found - keep all data (Stata behavior)
        skipped_filters <- c(skipped_filters, paste0("sex: ", paste(sex, collapse = ", "), " not found; keeping all"))
      }
    }
  }

  # Filter by age (default: keep only total age groups)
  # STATA-STYLE: Only filter if value exists
  # NUTRITION dataflow special case: use Y0T4 (0-4 years) as default since _T doesn't exist
  if ("AGE" %in% names(df)) {
    age_values <- unique(na.omit(df$AGE))
    if (length(age_values) > 1) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("age: ", paste(age_values, collapse = ", ")))
      if (is.null(age)) {
        # Special case: NUTRITION dataflow uses Y0T4 (0-4 years) instead of _T
        # The AGE dimension in NUTRITION has specific age groups but no _T total
        df_upper <- if (!is.null(dataflow)) toupper(dataflow) else ""
        if (df_upper == "NUTRITION" && "Y0T4" %in% age_values && !("_T" %in% age_values)) {
          df <- df %>% dplyr::filter(AGE == "Y0T4")
          applied_filters <- c(applied_filters, "age: Y0T4 (Default for NUTRITION)")
          message("Note: NUTRITION dataflow uses age=Y0T4 (0-4 years) as default instead of _T")
        } else {
          # Keep only total age groups if any exist
          total_ages <- c("_T", "Y0T4", "Y0T14", "Y0T17", "Y15T49", "ALLAGE")
          age_totals <- intersect(total_ages, age_values)
          if (length(age_totals) > 0) {
            # Prefer _T if available, otherwise use first available total
            if ("_T" %in% age_totals) {
              df <- df %>% dplyr::filter(AGE == "_T")
              applied_filters <- c(applied_filters, "age: _T (Default)")
            } else {
              preferred_age <- age_totals[1]
              df <- df %>% dplyr::filter(AGE == preferred_age)
              applied_filters <- c(applied_filters, paste0("age: ", preferred_age, " (Default - _T not available)"))
            }
          }
          # If no totals exist, keep all (Stata behavior)
        }
      } else if (age != "ALL") {
        if (age %in% age_values) {
          df <- df %>% dplyr::filter(AGE == age)
          applied_filters <- c(applied_filters, paste0("age: ", age))
        } else {
          skipped_filters <- c(skipped_filters, paste0("age: ", age, " not found; keeping all"))
        }
      }
    }
  }

  # Filter by wealth quintile (default: total if in metadata)
  # METADATA-DRIVEN: Only filter to _T if WEALTH_QUINTILE is in dims_with_totals
  # OR if no metadata available (safe default). This matches Python behavior.
  if ("WEALTH_QUINTILE" %in% names(df)) {
    wq_values <- unique(na.omit(df$WEALTH_QUINTILE))
    if (length(wq_values) > 1 || (length(wq_values) == 1 && wq_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("wealth_quintile: ", paste(wq_values, collapse = ", ")))
    }
    # Only apply default filter if dimension is in metadata OR no metadata available
    if (is.null(wealth) && "_T" %in% wq_values &&
        ("WEALTH_QUINTILE" %in% dims_with_totals || length(dims_with_totals) == 0)) {
      df <- df %>% dplyr::filter(WEALTH_QUINTILE == "_T")
      applied_filters <- c(applied_filters, "wealth_quintile: _T (Default)")
    } else if (!is.null(wealth) && wealth != "ALL") {
      if (wealth %in% wq_values) {
        df <- df %>% dplyr::filter(WEALTH_QUINTILE == wealth)
        applied_filters <- c(applied_filters, paste0("wealth_quintile: ", wealth))
      } else {
        skipped_filters <- c(skipped_filters, paste0("wealth_quintile: ", wealth, " not found; keeping all"))
      }
    }
  }

  # Filter by residence (default: total if in metadata)
  # METADATA-DRIVEN: Only filter to _T if RESIDENCE is in dims_with_totals
  # OR if no metadata available (safe default). This matches Python behavior.
  if ("RESIDENCE" %in% names(df)) {
    res_values <- unique(na.omit(df$RESIDENCE))
    if (length(res_values) > 1 || (length(res_values) == 1 && res_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("residence: ", paste(res_values, collapse = ", ")))
    }
    # Only apply default filter if dimension is in metadata OR no metadata available
    if (is.null(residence) && "_T" %in% res_values &&
        ("RESIDENCE" %in% dims_with_totals || length(dims_with_totals) == 0)) {
      df <- df %>% dplyr::filter(RESIDENCE == "_T")
      applied_filters <- c(applied_filters, "residence: _T (Default)")
    } else if (!is.null(residence) && residence != "ALL") {
      if (residence %in% res_values) {
        df <- df %>% dplyr::filter(RESIDENCE == residence)
        applied_filters <- c(applied_filters, paste0("residence: ", residence))
      } else {
        skipped_filters <- c(skipped_filters, paste0("residence: ", residence, " not found; keeping all"))
      }
    }
  }

  # Filter by maternal education level (default: total if in metadata)
  # METADATA-DRIVEN: Only filter to _T if MATERNAL_EDU_LVL is in dims_with_totals
  # OR if no metadata available (safe default). This matches Python behavior.
  if ("MATERNAL_EDU_LVL" %in% names(df)) {
    edu_values <- unique(na.omit(df$MATERNAL_EDU_LVL))
    if (length(edu_values) > 1 || (length(edu_values) == 1 && edu_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("maternal_edu_lvl: ", paste(edu_values, collapse = ", ")))
    }
    # Only apply default filter if dimension is in metadata OR no metadata available
    if (is.null(maternal_edu) && "_T" %in% edu_values &&
        ("MATERNAL_EDU_LVL" %in% dims_with_totals || length(dims_with_totals) == 0)) {
      df <- df %>% dplyr::filter(MATERNAL_EDU_LVL == "_T")
      applied_filters <- c(applied_filters, "maternal_edu_lvl: _T (Default)")
    } else if (!is.null(maternal_edu) && maternal_edu != "ALL") {
      if (maternal_edu %in% edu_values) {
        df <- df %>% dplyr::filter(MATERNAL_EDU_LVL == maternal_edu)
        applied_filters <- c(applied_filters, paste0("maternal_edu_lvl: ", maternal_edu))
      } else {
        skipped_filters <- c(skipped_filters, paste0("maternal_edu_lvl: ", maternal_edu, " not found; keeping all"))
      }
    }
  }

  # Filter by disability status using metadata-driven logic
  # DISABILITY_STATUS dimension: _T=total, PD=without disabilities, PWD=with disabilities
  # Only filter to _T if DISABILITY_STATUS is in dims_with_totals
  if ("DISABILITY_STATUS" %in% names(df)) {
    dis_values <- unique(na.omit(df$DISABILITY_STATUS))
    if (length(dis_values) > 1 || (length(dis_values) == 1 && !dis_values[1] %in% c("_T", "PD"))) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("disability_status: ", paste(dis_values, collapse = ", ")))
    }

    # Check if metadata says this dimension has totals
    has_totals <- "DISABILITY_STATUS" %in% dims_with_totals

    if (has_totals && "_T" %in% dis_values) {
      df <- df %>% dplyr::filter(.data$DISABILITY_STATUS == "_T")
      applied_filters <- c(applied_filters, "disability_status: _T (Default)")
    } else if (!has_totals && "PD" %in% dis_values && length(dis_values) > 1) {
      # PD = "People without Disabilities" - baseline when no total exists
      df <- df %>% dplyr::filter(.data$DISABILITY_STATUS == "PD")
      applied_filters <- c(applied_filters, "disability_status: PD (no _T in metadata)")
    }
  }

  # Filter by education level (use metadata to check if totals exist)
  if ("EDUCATION_LEVEL" %in% names(df)) {
    edu_lvl_values <- unique(na.omit(df$EDUCATION_LEVEL))
    if (length(edu_lvl_values) > 1 || (length(edu_lvl_values) == 1 && edu_lvl_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("education_level: ", paste(edu_lvl_values, collapse = ", ")))
    }
    # Only filter if in metadata OR no metadata available (safe default)
    if (("EDUCATION_LEVEL" %in% dims_with_totals || length(dims_with_totals) == 0) &&
        "_T" %in% edu_lvl_values) {
      df <- df %>% dplyr::filter(.data$EDUCATION_LEVEL == "_T")
      applied_filters <- c(applied_filters, "education_level: _T (Default)")
    }
  }

  # Filter by ethnic group (use metadata to check if totals exist)
  if ("ETHNIC_GROUP" %in% names(df)) {
    eth_values <- unique(na.omit(df$ETHNIC_GROUP))
    if (length(eth_values) > 1 || (length(eth_values) == 1 && eth_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("ethnic_group: ", paste(eth_values, collapse = ", ")))
    }
    # Only filter if in metadata OR no metadata available (safe default)
    if (("ETHNIC_GROUP" %in% dims_with_totals || length(dims_with_totals) == 0) &&
        "_T" %in% eth_values) {
      df <- df %>% dplyr::filter(.data$ETHNIC_GROUP == "_T")
      applied_filters <- c(applied_filters, "ethnic_group: _T (Default)")
    }
  }

  # Log available disaggregations and applied filters
  if (verbose) {
    if (length(available_disaggregations) > 0) {
      message(sprintf("Note: Disaggregated data available: %s.",
                      paste(available_disaggregations, collapse = "; ")))
    }
    if (length(applied_filters) > 0) {
      message(sprintf("Applied filters: %s.", paste(applied_filters, collapse = "; ")))
    }
    if (length(skipped_filters) > 0) {
      message(sprintf("Skipped filters: %s.", paste(skipped_filters, collapse = "; ")))
    }
  }

  return(df)
}

# =============================================================================
# #### 8. Schema Validation ####
# =============================================================================

#' @title Validate Data Against Schema
#' @description Checks if the data matches the expected schema for the dataflow.
#' @param df Data frame to validate
#' @param dataflow_id Dataflow ID
#' @return Validated data frame (warnings issued if mismatch)
#' @export
validate_unicef_schema <- function(df, dataflow_id) {
  # Ensure schema_sync.R is loaded
  if (!exists("load_dataflow_schema", mode = "function")) {
    script_file <- sys.frame(1)$ofile
    script_dir <- if (is.null(script_file)) "." else dirname(script_file)
    schema_path <- file.path(script_dir, "schema_sync.R")
    if (file.exists(schema_path)) {
      source(schema_path, local = FALSE)
    }
  }

  if (!exists("load_dataflow_schema", mode = "function")) {
    warning("Could not load schema validation functions. Skipping validation.")
    return(df)
  }

  expected_cols <- get_expected_columns(dataflow_id)
  if (length(expected_cols) == 0) return(df)

  missing_cols <- setdiff(expected_cols, names(df))
  if (length(missing_cols) > 0) {
    warning(sprintf("Data for %s is missing expected columns: %s",
                    dataflow_id, paste(missing_cols, collapse = ", ")))
  }

  return(df)
}

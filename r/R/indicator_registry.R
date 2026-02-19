#' Indicator Registry - Auto-sync UNICEF Indicator Metadata
#' 
#' This module automatically fetches and caches the complete UNICEF indicator
#' codelist from the SDMX API. The cache is created on first use and can be
#' refreshed on demand.
#'
#' @description
#' Key features:
#' - Automatic download of indicator codelist from UNICEF SDMX API
#' - Maps each indicator code to its dataflow (category)
#' - Caches metadata locally in config/unicef_indicators_metadata.yaml
#' - Supports offline usage after initial sync
#' - Version tracking for cache freshness
#'
#' @examples
#' # Auto-detect dataflow from indicator code
#' dataflow <- get_dataflow_for_indicator("CME_MRY0T4")
#' print(dataflow)  # "CME"
#'
#' # Refresh cache manually
#' refresh_indicator_cache()
#'
#' @name indicator_registry
NULL

# ==============================================================================
# Configuration
# ==============================================================================

CODELIST_URL <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0"
CACHE_FILENAME <- "unicef_indicators_metadata.yaml"
FALLBACK_SEQUENCES_FILENAME <- "_dataflow_fallback_sequences.yaml"
CACHE_MAX_AGE_DAYS <- 30

# Module-level cache (environment for mutable state)
.indicator_cache <- new.env(parent = emptyenv())
.indicator_cache$data <- NULL
.indicator_cache$loaded <- FALSE
.indicator_cache$fallback_sequences <- NULL
.indicator_cache$fallback_loaded <- FALSE


# ==============================================================================
# Internal Functions
# ==============================================================================

#' Get path to the indicator cache file
#' 
#' Uses temporary session cache by default (tempdir()) to avoid writing
#' to user's home directory without permission. For persistent caching,
#' set UNICEF_DATA_HOME_R or UNICEF_DATA_HOME environment variable
#' to explicitly specify a cache location.
#' 
#' @keywords internal
.get_cache_path <- function() {
  # 1. Environment override for unified cross-language cache (explicit opt-in)
  env_home <- if (nzchar(Sys.getenv("UNICEF_DATA_HOME_R"))) {
    Sys.getenv("UNICEF_DATA_HOME_R")
  } else {
    Sys.getenv("UNICEF_DATA_HOME")
  }
  if (nzchar(env_home)) {
    metadata_dir <- file.path(env_home, "metadata", "current")
    if (!dir.exists(metadata_dir)) {
      dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
    }
    return(file.path(metadata_dir, CACHE_FILENAME))
  }

  # 2. Default: Use tempdir() for session-based temp cache
  # This avoids writing to home directory without user permission
  metadata_dir <- file.path(tempdir(), "unicef_api_cache", "metadata", "current")
  if (!dir.exists(metadata_dir)) {
    dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  }
  file.path(metadata_dir, CACHE_FILENAME)
}

#' Get path to fallback sequences file
#' 
#' Looks for canonical _dataflow_fallback_sequences.yaml
#' Uses multiple fallback strategies for development and installed package scenarios
#' 
#' @keywords internal
.get_fallback_sequences_path <- function() {
  fallback_file <- FALLBACK_SEQUENCES_FILENAME  # "_dataflow_fallback_sequences.yaml"
  
  # FIRST: Try system.file for installed packages (this is the standard location)
  sys_file <- system.file("metadata", "current", fallback_file, package = "unicefData")
  if (nzchar(sys_file) && file.exists(sys_file)) {
    return(normalizePath(sys_file))
  }
  
  # SECOND: Look in development folders (relative to cwd)
  candidates <- c(
    file.path(getwd(), "metadata", "current", fallback_file),
    file.path(getwd(), "inst", "metadata", "current", fallback_file),
    file.path(getwd(), "stata", "metadata", "current", fallback_file),
    file.path(getwd(), "..", "metadata", "current", fallback_file),
    file.path(getwd(), "..", "inst", "metadata", "current", fallback_file),
    file.path(getwd(), "..", "stata", "metadata", "current", fallback_file),
    file.path(getwd(), "..", "..", "metadata", "current", fallback_file),
    file.path(getwd(), "..", "..", "inst", "metadata", "current", fallback_file),
    file.path(getwd(), "..", "..", "stata", "metadata", "current", fallback_file)
  )
  
  # Check candidates
  for (candidate in candidates) {
    if (file.exists(candidate)) {
      return(normalizePath(candidate))
    }
  }
  
  return(NULL)
}

#' Load fallback sequences from canonical YAML
#' 
#' Loads dataflow fallback sequences used by all platforms for consistent
#' indicator-to-dataflow resolution. Returns a named list where names are
#' indicator prefixes and values are character vectors of dataflows to try.
#' 
#' @return Named list of fallback sequences by indicator prefix
#' @keywords internal
.load_fallback_sequences <- function() {
  # Check if already loaded in this session
  if (.indicator_cache$fallback_loaded && !is.null(.indicator_cache$fallback_sequences)) {
    return(.indicator_cache$fallback_sequences)
  }
  
  fallback_file <- .get_fallback_sequences_path()

  # DEBUG: Show what was found (only if unicefData.debug option is TRUE)
  if (isTRUE(getOption("unicefData.debug", FALSE))) {
    message("[DEBUG] .get_fallback_sequences_path() returned: ",
            if (is.null(fallback_file)) "NULL" else fallback_file)
  }

  # If file not found, return default sequences
  if (is.null(fallback_file)) {
    if (isTRUE(getOption("unicefData.debug", FALSE))) {
      message("[DEBUG] Using hardcoded defaults (file not found)")
    }
    default_sequences <- list(
      ED = c("EDUCATION_UIS_SDG", "EDUCATION", "GLOBAL_DATAFLOW"),
      PT = c("PT", "PT_CM", "PT_FGM", "CHILD_PROTECTION", "GLOBAL_DATAFLOW"),
      COD = c("CAUSE_OF_DEATH", "CME", "MORTALITY", "GLOBAL_DATAFLOW"),
      PV = c("CHLD_PVTY", "GLOBAL_DATAFLOW"),
      NT = c("NUTRITION", "GLOBAL_DATAFLOW"),
      CME = c("CME", "GLOBAL_DATAFLOW"),
      FD = c("FUNCTIONAL_DIFF", "DISABILITY", "HEALTH", "GLOBAL_DATAFLOW"),
      HVA = c("HIV_AIDS", "HEALTH", "GLOBAL_DATAFLOW"),
      IM = c("IMMUNISATION", "HEALTH", "GLOBAL_DATAFLOW"),
      MNCH = c("MNCH", "HEALTH", "GLOBAL_DATAFLOW"),
      ECD = c("ECD", "EDUCATION", "GLOBAL_DATAFLOW"),
      WS = c("WASH_HOUSEHOLDS", "WASH_SCHOOLS", "GLOBAL_DATAFLOW"),
      DM = c("DM", "DEMOGRAPHICS", "GLOBAL_DATAFLOW"),
      MG = c("MG", "MIGRATION", "GLOBAL_DATAFLOW"),
      GN = c("GENDER", "GLOBAL_DATAFLOW"),
      SPP = c("SOC_PROTECTION", "GLOBAL_DATAFLOW"),
      WT = c("WASH_HOUSEHOLDS", "WASH_SCHOOLS", "PT", "EDUCATION", "GLOBAL_DATAFLOW"),
      DEFAULT = c("GLOBAL_DATAFLOW")
    )
    .indicator_cache$fallback_sequences <- default_sequences
    .indicator_cache$fallback_loaded <- TRUE
    return(default_sequences)
  }
  
  # Try to load YAML file
  tryCatch({
    if (!requireNamespace("yaml", quietly = TRUE)) {
      warning("yaml package required to load fallback sequences. Using defaults.")
      return(.indicator_cache$fallback_sequences %||% list(DEFAULT = "GLOBAL_DATAFLOW"))
    }
    
    if (isTRUE(getOption("unicefData.debug", FALSE))) {
      message("[DEBUG] Loading YAML from: ", fallback_file)
    }

    data <- yaml::yaml.load_file(fallback_file)
    
    if (!is.null(data$fallback_sequences)) {
      sequences <- data$fallback_sequences
      .indicator_cache$fallback_sequences <- sequences
      .indicator_cache$fallback_loaded <- TRUE
      return(sequences)
    } else {
      warning("No 'fallback_sequences' key found in ", fallback_file)
      return(list(DEFAULT = "GLOBAL_DATAFLOW"))
    }
  }, error = function(e) {
    warning("Error loading fallback sequences from ", fallback_file, ": ", e$message)
    return(list(DEFAULT = "GLOBAL_DATAFLOW"))
  })
}

#' Infer organizational CATEGORY from indicator code prefix
#'
#' DEPRECATED FOR DATAFLOW DETECTION: This function infers category for
#' organizational grouping only. For actual API dataflow detection, use
#' get_dataflow_for_indicator() which implements the canonical fallback
#' sequence from _dataflow_fallback_sequences.yaml.
#'
#' Note: Category != Dataflow. For example, WS_HCF_* indicators have
#' category='WASH' but dataflow='WASH_HEALTHCARE_FACILITY'.
#'
#' @param indicator_code Character. The indicator code
#' @return Character. The inferred organizational category name
#' @keywords internal
.infer_category <- function(indicator_code) {
  # ===========================================================================
  # KNOWN DATAFLOW OVERRIDES
  # ===========================================================================
  # Some indicators exist in dataflows that don't match their prefix or the

  # metadata reports the wrong dataflow. These are known exceptions that 
  # require explicit mapping.
  #
  # Issue: The UNICEF SDMX API metadata sometimes reports indicators in a
  # generic dataflow (e.g., "PT", "EDUCATION") but the data only exists in
  # a more specific dataflow (e.g., "PT_CM", "EDUCATION_UIS_SDG").
  #
  # These mappings were discovered by testing against the production script:
  # PROD-SDG-REP-2025/01_data_prep/012_codes/0121_get_data_api.R
  # ===========================================================================
  
  # DEPRECATED: Hardcoded overrides removed in favor of canonical YAML-based fallback sequences
  # See: metadata/current/_dataflow_fallback_sequences.yaml
  # All indicators now use fallback sequence approach via get_dataflow_for_indicator()
  

  # ===========================================================================
  # DYNAMIC PATTERN-BASED OVERRIDES
  # ===========================================================================
  # REMOVED: All pattern-based overrides (FGM, etc.)
  # All dataflow mappings now loaded from comprehensive indicators metadata:
  # - _unicefdata_indicators_metadata.yaml (733 indicators)
  # - _dataflow_fallback_sequences.yaml (prefix-based fallback)
  #
  # Direct O(1) lookup replaces pattern matching.
  
  # Child Marriage indicators: PT_*_MRD_* -> PT_CM
  if (startsWith(indicator_code, "PT_") && grepl("_MRD_", indicator_code)) {
    return("PT_CM")
  }
  
  # UIS SDG Education indicators: ED_*_UIS* -> EDUCATION_UIS_SDG
  if (startsWith(indicator_code, "ED_") && grepl("_UIS", indicator_code)) {
    return("EDUCATION_UIS_SDG")
  }
  
  # ===========================================================================
  # DEPRECATED: PREFIX_TO_CATEGORY
  # ===========================================================================
  # These mappings are for ORGANIZATIONAL CATEGORY ONLY, not dataflow detection.
  # For dataflow detection, use get_dataflow_for_indicator() which implements
  # the canonical fallback sequences from _dataflow_fallback_sequences.yaml.
  #
  # WARNING: Category != Dataflow. For example:
  #   - WS_HCF_* -> category=WASH, but dataflow=WASH_HEALTHCARE_FACILITY
  #   - WS_SCH_* -> category=WASH, but dataflow=WASH_SCHOOLS
  # ===========================================================================
  PREFIX_TO_CATEGORY <- list(
    CME = "CME",
    NT = "NUTRITION",
    IM = "IMMUNISATION",
    ED = "EDUCATION",
    WS = "WASH",  # Category only - NOT dataflow (could be WASH_HOUSEHOLDS, WASH_SCHOOLS, WASH_HEALTHCARE_FACILITY)
    HVA = "HIV_AIDS",
    MNCH = "MNCH",
    PT = "PT",
    ECD = "ECD",
    DM = "DM",
    ECON = "ECON",
    GN = "GENDER",
    MG = "MIGRATION",
    FD = "FUNCTIONAL_DIFF",
    PP = "POPULATION",
    EMPH = "EMPH",
    EDUN = "EDUCATION",
    SDG4 = "EDUCATION_UIS_SDG",
    PV = "CHLD_PVTY",
    # Additional category mappings
    COD = "CAUSE_OF_DEATH",      # Cause of death indicators
    TRGT = "CHILD_RELATED_SDG",  # SDG/National targets
    SPP = "SOC_PROTECTION",      # Social protection programs
    WT = "PT"                    # Child labour/adolescent indicators
  )
  
  # Extract prefix (first part before underscore)
  parts <- strsplit(indicator_code, "_")[[1]]
  if (length(parts) > 0) {
    prefix <- parts[1]
    if (prefix %in% names(PREFIX_TO_CATEGORY)) {
      return(PREFIX_TO_CATEGORY[[prefix]])
    }
  }
  
  return("GLOBAL_DATAFLOW")
}


#' Parse SDMX codelist XML response
#' @param xml_content Character. Raw XML content from API
#' @return Named list of indicator metadata
#' @keywords internal
.parse_codelist_xml <- function(xml_content) {
  # Requires xml2 package
  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop("Package 'xml2' is required for parsing SDMX XML but not available.")
  }
  
  doc <- xml2::read_xml(xml_content)
  
  # Define namespaces
  ns <- c(
    structure = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure",
    common = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common"
  )
  
  # Find all Code elements
  codes <- xml2::xml_find_all(doc, ".//structure:Code", ns)
  
  indicators <- list()
  
  for (code_elem in codes) {
    code_id <- xml2::xml_attr(code_elem, "id")
    if (is.na(code_id) || code_id == "") next
    
    # Extract name
    name_elem <- xml2::xml_find_first(code_elem, ".//common:Name", ns)
    name <- if (!is.na(name_elem)) xml2::xml_text(name_elem) else ""
    
    # Extract description
    desc_elem <- xml2::xml_find_first(code_elem, ".//common:Description", ns)
    description <- if (!is.na(desc_elem)) xml2::xml_text(desc_elem) else ""
    
    # Extract URN
    urn <- xml2::xml_attr(code_elem, "urn")
    if (is.na(urn)) urn <- ""
    
    # Extract parent from <structure:Parent><Ref id="..."/></structure:Parent>
    parent_elem <- xml2::xml_find_first(code_elem, "structure:Parent/Ref", ns)
    parent_id <- if (!is.na(parent_elem)) xml2::xml_attr(parent_elem, "id") else ""
    if (is.na(parent_id)) parent_id <- ""
    
    indicator_data <- list(
      code = code_id,
      name = name,
      description = description,
      urn = urn
    )
    
    # Add parent only if present
    if (nchar(parent_id) > 0) {
      indicator_data$parent <- parent_id
    }
    
    indicators[[code_id]] <- indicator_data
  }
  
  return(indicators)
}


#' Fetch indicator codelist from UNICEF SDMX API
#' @return Named list of indicator metadata
#' @keywords internal
.fetch_indicator_codelist <- function() {
  message("Fetching indicator codelist from UNICEF SDMX API...")
  
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Package 'httr' is required for API requests but not available.")
  }
  
  response <- httr::GET(
    CODELIST_URL,
    httr::timeout(60),
    httr::add_headers(Accept = "application/xml")
  )
  
  if (httr::http_error(response)) {
    stop(sprintf("Failed to fetch codelist: HTTP %d", httr::status_code(response)))
  }
  
  xml_content <- httr::content(response, as = "text", encoding = "UTF-8")
  indicators <- .parse_codelist_xml(xml_content)
  
  message(sprintf("Successfully fetched %d indicators", length(indicators)))
  
  return(indicators)
}


#' Load cached indicator metadata
#' @return List with 'indicators' and 'last_updated' or NULL
#' @keywords internal
.load_cache <- function() {
  cache_path <- .get_cache_path()
  
  if (!file.exists(cache_path)) {
    return(NULL)
  }
  
  tryCatch({
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("Package 'yaml' is required but not available.")
    }
    
    data <- yaml::read_yaml(cache_path)
    
    if (is.null(data) || is.null(data$indicators)) {
      return(NULL)
    }
    
    # Parse last updated
    last_updated <- NULL
    if (!is.null(data$metadata) && !is.null(data$metadata$last_updated)) {
      last_updated <- tryCatch(
        as.POSIXct(data$metadata$last_updated, format = "%Y-%m-%dT%H:%M:%S"),
        error = function(e) NULL
      )
    }
    
    return(list(
      indicators = data$indicators,
      last_updated = last_updated
    ))
    
  }, error = function(e) {
    warning(sprintf("Failed to load cache: %s", e$message))
    return(NULL)
  })
}


#' Save indicator metadata to cache file
#' @param indicators Named list of indicator metadata
#' @keywords internal
.save_cache <- function(indicators) {
  cache_path <- .get_cache_path()
  
  # Ensure directory exists
  cache_dir <- dirname(cache_path)
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  data <- list(
    metadata = list(
      version = "1.0",
      source = "UNICEF SDMX Codelist CL_UNICEF_INDICATOR",
      url = CODELIST_URL,
      last_updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
      description = "Comprehensive UNICEF indicator codelist with metadata (auto-generated)",
      indicator_count = length(indicators)
    ),
    indicators = indicators
  )
  
  tryCatch({
    # Write YAML without line wrapping for cross-platform consistency
    yaml_lines <- .yaml_no_wrap(data)
    writeLines(yaml_lines, cache_path, useBytes = TRUE)
    message(sprintf("Saved %d indicators to %s", length(indicators), cache_path))
  }, error = function(e) {
    warning(sprintf("Failed to save cache: %s", e$message))
  })
  
  invisible(NULL)
}

#' Convert R list to YAML without line wrapping
#' @param data List to convert
#' @param indent Current indentation level
#' @return Character vector of YAML lines
#' @keywords internal
.yaml_no_wrap <- function(data, indent = 0) {
  lines <- character()
  prefix <- strrep("  ", indent)
  
  if (is.null(data)) {
    return("~")
  }
  
  if (!is.list(data)) {
    # Scalar value
    return(.yaml_scalar(data))
  }
  
  names_data <- names(data)
  
  for (i in seq_along(data)) {
    key <- names_data[i]
    value <- data[[i]]
    
    if (is.null(key) || key == "") {
      # List item (no key)
      if (is.list(value) && length(value) > 0) {
        lines <- c(lines, paste0(prefix, "- ", names(value)[1], ": ", .yaml_scalar(value[[1]])))
        if (length(value) > 1) {
          for (j in 2:length(value)) {
            lines <- c(lines, paste0(prefix, "  ", names(value)[j], ": ", .yaml_scalar(value[[j]])))
          }
        }
      } else {
        lines <- c(lines, paste0(prefix, "- ", .yaml_scalar(value)))
      }
    } else {
      # Named key
      if (is.list(value) && length(value) > 0 && !is.null(names(value))) {
        lines <- c(lines, paste0(prefix, key, ":"))
        lines <- c(lines, .yaml_no_wrap(value, indent + 1))
      } else if (is.list(value) && length(value) > 0) {
        # Unnamed list (array)
        lines <- c(lines, paste0(prefix, key, ":"))
        for (item in value) {
          if (is.list(item)) {
            lines <- c(lines, .yaml_no_wrap(item, indent + 1))
          } else {
            lines <- c(lines, paste0(prefix, "  - ", .yaml_scalar(item)))
          }
        }
      } else {
        lines <- c(lines, paste0(prefix, key, ": ", .yaml_scalar(value)))
      }
    }
  }
  
  return(lines)
}

#' Convert scalar value to YAML string
#' @param x Scalar value
#' @return Character string in YAML format
#' @keywords internal
.yaml_scalar <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return("''")
  }
  if (is.logical(x)) {
    return(tolower(as.character(x)))
  }
  if (is.numeric(x)) {
    return(as.character(x))
  }
  # String - check if quoting needed
  x <- as.character(x)
  if (x == "" || grepl("^[\\s]|[\\s]$|[:#\\[\\]{}\"'|>]", x, perl = TRUE) || x %in% c("true", "false", "null", "~")) {
    # Quote strings that need it
    return(paste0("'", gsub("'", "''", x), "'"))
  }
  return(x)
}


#' Check if cache is stale
#' @param last_updated POSIXct. When cache was last updated
#' @return Logical. TRUE if cache should be refreshed
#' @keywords internal
.is_cache_stale <- function(last_updated) {
  if (is.null(last_updated)) return(TRUE)
  
  age_days <- as.numeric(difftime(Sys.time(), last_updated, units = "days"))
  return(age_days > CACHE_MAX_AGE_DAYS)
}


#' Ensure indicator cache is loaded
#' @param force_refresh Logical. If TRUE, always fetch fresh data
#' @return Named list of indicator metadata
#' @keywords internal
.ensure_cache_loaded <- function(force_refresh = FALSE) {
  # Return memory cache if already loaded
  if (.indicator_cache$loaded && !is.null(.indicator_cache$data) && !force_refresh) {
    return(.indicator_cache$data)
  }
  
  # Try to load from file cache
  cached <- .load_cache()
  
  # Use file cache if valid and not stale
  if (!is.null(cached) && !.is_cache_stale(cached$last_updated) && !force_refresh) {
    .indicator_cache$data <- cached$indicators
    .indicator_cache$loaded <- TRUE
    return(.indicator_cache$data)
  }
  
  # Fetch fresh data from API
  tryCatch({
    fresh_indicators <- .fetch_indicator_codelist()
    .save_cache(fresh_indicators)
    .indicator_cache$data <- fresh_indicators
    .indicator_cache$loaded <- TRUE
    return(.indicator_cache$data)
    
  }, error = function(e) {
    # If fetch fails but we have stale cache, use it
    if (!is.null(cached)) {
      warning(sprintf("Using stale cache (fetch failed): %s", e$message))
      .indicator_cache$data <- cached$indicators
      .indicator_cache$loaded <- TRUE
      return(.indicator_cache$data)
    }
    
    # No cache and no connection
    warning("No cache available and cannot fetch from API")
    .indicator_cache$data <- list()
    .indicator_cache$loaded <- TRUE
    return(.indicator_cache$data)
  })
}


# ==============================================================================
# Public API
# ==============================================================================

#' Get Dataflow for Indicator
#'
#' Returns the dataflow (category) for a given indicator code. This function
#' automatically loads the indicator cache on first use, fetching from the
#' UNICEF SDMX API if necessary.
#'
#' IMPORTANT: Known dataflow overrides are checked FIRST, before the cache.
#' This ensures problematic indicators (where the API metadata is wrong)
#' always get the correct dataflow.
#'
#' @param indicator_code Character. UNICEF indicator code (e.g., "CME_MRY0T4")
#' @param default Character. Default dataflow if indicator not found (default: "GLOBAL_DATAFLOW")
#'
#' @return Character. Dataflow name (e.g., "CME", "NUTRITION", "EDUCATION")
#'
#' @examples
#' \dontrun{
#' get_dataflow_for_indicator("CME_MRY0T4")
#' # Returns: "CME"
#'
#' get_dataflow_for_indicator("NT_ANT_HAZ_NE2_MOD")
#' # Returns: "NUTRITION"
#'
#' get_dataflow_for_indicator("ED_CR_L1_UIS_MOD")
#' # Returns: "EDUCATION_UIS_SDG" (uses override, not wrong cache value)
#' }
#'
#' @export
get_dataflow_for_indicator <- function(indicator_code, default = "GLOBAL_DATAFLOW") {
  # 3-TIER DATAFLOW RESOLUTION (matching Python's approach)
  # TIER 1: Direct indicator metadata lookup (O(1) - fastest and most accurate)
  # TIER 2: Prefix-based fallback sequences
  # TIER 3: Default fallback

  # ============================================================================
  # TIER 1: Direct lookup in comprehensive indicators metadata
  # ============================================================================
  # Check _unicefdata_indicators_metadata.yaml for indicator's 'dataflows' field
  # This is the same approach Python uses for accurate dataflow detection

  # Try to access indicators metadata from package-private cache first
  indicators_meta <- .indicator_cache$indicators_metadata

  # If not cached, try to load from installed package metadata file
  if (is.null(indicators_meta)) {
    indicators_meta <- tryCatch({
      meta_file <- system.file("metadata", "current", "_unicefdata_indicators_metadata.yaml",
                               package = "unicefData", mustWork = FALSE)
      if (nzchar(meta_file) && file.exists(meta_file) && requireNamespace("yaml", quietly = TRUE)) {
        loaded <- yaml::yaml.load_file(meta_file)
        .indicator_cache$indicators_metadata <- loaded$indicators  # Cache for reuse
        loaded$indicators
      } else {
        NULL
      }
    }, error = function(e) NULL)
  }

  # Check if indicator exists in comprehensive metadata
  if (!is.null(indicators_meta) && indicator_code %in% names(indicators_meta)) {
    meta <- indicators_meta[[indicator_code]]
    # Check 'dataflows' (plural) first, then 'dataflow' (singular)
    dataflow_value <- meta$dataflows %||% meta$dataflow
    if (!is.null(dataflow_value)) {
      # Handle both list and scalar values
      if (is.list(dataflow_value)) {
        dataflows_list <- unlist(dataflow_value)
      } else {
        dataflows_list <- dataflow_value
      }
      if (length(dataflows_list) > 0) {
        if (isTRUE(getOption("unicefData.debug", FALSE))) {
          message("[TIER 1] Found ", indicator_code, " in metadata: dataflows=", paste(dataflows_list, collapse = ", "))
        }
        return(dataflows_list[1])  # Return first (primary) dataflow
      }
    }
  }

  # ============================================================================
  # TIER 2: Prefix-based fallback sequences
  # ============================================================================
  # Load fallback sequences from canonical YAML
  fallback_sequences <- .load_fallback_sequences()

  # Extract prefix
  prefix <- strsplit(indicator_code, "_")[[1]][1]

  # Get fallback sequence for this prefix
  if (prefix %in% names(fallback_sequences)) {
    dataflows_to_try <- fallback_sequences[[prefix]]
    if (isTRUE(getOption("unicefData.debug", FALSE))) {
      message("[TIER 2] Using prefix '", prefix, "' fallback: ", paste(dataflows_to_try, collapse = ", "))
    }
  } else {
    # Default sequence if prefix not found
    dataflows_to_try <- fallback_sequences$DEFAULT %||% c("GLOBAL_DATAFLOW")
    if (isTRUE(getOption("unicefData.debug", FALSE))) {
      message("[TIER 2] Prefix '", prefix, "' not found, using DEFAULT: ", paste(dataflows_to_try, collapse = ", "))
    }
  }

  # Return first dataflow in sequence (will be tried with fallback logic in get_sdmx)
  if (length(dataflows_to_try) > 0) {
    return(dataflows_to_try[1])
  }

  return(default)
}


#' Get Indicator Info
#'
#' Returns full metadata for an indicator.
#'
#' @param indicator_code Character. UNICEF indicator code
#'
#' @return Named list with indicator metadata or NULL if not found
#'
#' @examples
#' \dontrun{
#' info <- get_indicator_info("CME_MRY0T4")
#' print(info$name)
#' # "Under-five mortality rate"
#' }
#'
#' @export
get_indicator_info <- function(indicator_code) {
  indicators <- .ensure_cache_loaded()
  
  if (indicator_code %in% names(indicators)) {
    return(indicators[[indicator_code]])
  }
  
  return(NULL)
}


#' List Indicators
#'
#' List all known indicators, optionally filtered by dataflow or name.
#'
#' @param dataflow Character. Filter by dataflow/category (e.g., "CME", "NUTRITION")
#' @param name_contains Character. Filter by name substring (case-insensitive)
#'
#' @return Named list of matching indicators
#'
#' @examples
#' \dontrun{
#' # Get all mortality indicators
#' mortality <- list_indicators(dataflow = "CME")
#'
#' # Search by name
#' stunting <- list_indicators(name_contains = "stunting")
#' }
#'
#' @export
list_indicators <- function(dataflow = NULL, name_contains = NULL) {
  indicators <- .ensure_cache_loaded()
  
  result <- list()
  
  for (code in names(indicators)) {
    info <- indicators[[code]]
    
    # Apply dataflow filter
    if (!is.null(dataflow)) {
      if (is.null(info$category) || info$category != dataflow) {
        next
      }
    }
    
    # Apply name filter
    if (!is.null(name_contains)) {
      name <- if (!is.null(info$name)) tolower(info$name) else ""
      if (!grepl(tolower(name_contains), name, fixed = TRUE)) {
        next
      }
    }
    
    result[[code]] <- info
  }
  
  return(result)
}


#' Search Indicators
#'
#' Search and display UNICEF indicators in a user-friendly format.
#' This function allows analysts to search the indicator metadata to find
#' indicator codes they need. Results are printed to the screen in a
#' formatted table.
#'
#' @param query Character. Search term to match in indicator code, name, or description
#'   (case-insensitive). If NULL, shows all indicators.
#' @param category Character. Filter by dataflow/category (e.g., "CME", "NUTRITION").
#'   Use list_categories() to see available categories.
#' @param limit Integer. Maximum number of results to display (default: 50).
#'   Set to NULL or 0 to show all matches.
#' @param show_description Logical. If TRUE, includes description column (default: TRUE).
#'
#' @return Invisibly returns a data.frame with the matching indicators.
#'   Results are also printed to the screen.
#'
#' @examples
#' \dontrun{
#' # Search for mortality-related indicators
#' search_indicators("mortality")
#'
#' # List all nutrition indicators
#' search_indicators(category = "NUTRITION")
#'
#' # Search for stunting across all categories
#' search_indicators("stunting")
#'
#' # List all indicators (first 50)
#' search_indicators()
#'
#' # List all CME indicators without limit
#' search_indicators(category = "CME", limit = 0)
#' }
#'
#' @export
search_indicators <- function(query = NULL, category = NULL, limit = 50, show_description = TRUE) {
  indicators <- .ensure_cache_loaded()
  
  # Convert query to lowercase for case-insensitive matching
  query_lower <- if (!is.null(query)) tolower(query) else NULL
  
  # Filter indicators
  matches <- list()
  
  for (code in names(indicators)) {
    info <- indicators[[code]]
    
    # Apply category filter
    if (!is.null(category)) {
      info_cat <- if (!is.null(info$category)) toupper(info$category) else ""
      if (info_cat != toupper(category)) {
        next
      }
    }
    
    # Apply query filter (search in code, name, and description)
    if (!is.null(query_lower)) {
      code_match <- grepl(query_lower, tolower(code), fixed = TRUE)
      name_match <- grepl(query_lower, tolower(info$name %||% ""), fixed = TRUE)
      desc_match <- grepl(query_lower, tolower(info$description %||% ""), fixed = TRUE)
      
      if (!(code_match || name_match || desc_match)) {
        next
      }
    }
    
    matches[[length(matches) + 1]] <- list(
      code = code,
      name = info$name %||% "",
      category = info$category %||% "",
      description = info$description %||% ""
    )
  }
  
  # Sort by category, then by code
  if (length(matches) > 0) {
    sort_keys <- sapply(matches, function(m) paste(m$category, m$code, sep = "_"))
    matches <- matches[order(sort_keys)]
  }
  
  # Store total count before limiting
  total_matches <- length(matches)
  
  # Apply limit
  if (!is.null(limit) && limit > 0 && length(matches) > limit) {
    matches <- matches[1:limit]
  }
  
  # Print header
  cat("\n")
  cat(strrep("=", 100), "\n")
  if (!is.null(query) && !is.null(category)) {
    cat(sprintf("  UNICEF Indicators matching '%s' in category '%s'\n", query, category))
  } else if (!is.null(query)) {
    cat(sprintf("  UNICEF Indicators matching '%s'\n", query))
  } else if (!is.null(category)) {
    cat(sprintf("  UNICEF Indicators in category '%s'\n", category))
  } else {
    cat("  All UNICEF Indicators\n")
  }
  cat(strrep("=", 100), "\n")
  
  if (length(matches) == 0) {
    cat("\n  No indicators found matching your criteria.\n\n")
    cat("  Tips:\n")
    cat("  - Try a different search term\n")
    cat("  - Use list_categories() to see available categories\n")
    cat("  - Use search_indicators() with no arguments to see all indicators\n\n")
    return(invisible(data.frame()))
  }
  
  # Print result count
  cat(sprintf("\n  Found %d indicator(s)", total_matches))
  if (!is.null(limit) && limit > 0 && total_matches > limit) {
    cat(sprintf(" (showing first %d)", limit))
  }
  cat("\n")
  cat(strrep("-", 100), "\n")
  
  # Calculate column widths
  code_width <- max(sapply(matches, function(m) nchar(m$code)))
  code_width <- max(code_width, 15)
  cat_width <- max(sapply(matches, function(m) nchar(m$category)))
  cat_width <- max(cat_width, 10)
  
  if (show_description) {
    name_width <- 35
    desc_width <- 100 - code_width - cat_width - name_width - 10
  } else {
    name_width <- 100 - code_width - cat_width - 6
    desc_width <- 0
  }
  
  # Print column headers
  header <- sprintf("  %-*s  %-*s  %-*s", code_width, "CODE", cat_width, "CATEGORY", name_width, "NAME")
  if (show_description) {
    header <- paste0(header, sprintf("  %-*s", desc_width, "DESCRIPTION"))
  }
  cat(header, "\n")
  cat(strrep("-", 100), "\n")
  
  # Print each indicator
  for (m in matches) {
    name <- m$name
    if (nchar(name) > name_width) {
      name <- paste0(substr(name, 1, name_width - 2), "..")
    }
    
    row <- sprintf("  %-*s  %-*s  %-*s", code_width, m$code, cat_width, m$category, name_width, name)
    
    if (show_description) {
      desc <- m$description
      if (nchar(desc) > desc_width) {
        desc <- paste0(substr(desc, 1, desc_width - 2), "..")
      }
      row <- paste0(row, sprintf("  %s", desc))
    }
    
    cat(row, "\n")
  }
  
  cat(strrep("-", 100), "\n")
  
  # Print footer with tips
  if (total_matches > length(matches)) {
    cat(sprintf("\n  Showing %d of %d results. Use limit = 0 to see all.\n", length(matches), total_matches))
  }
  
  cat("\n  Usage tips:\n")
  cat("  - unicefData(indicator = 'CODE') to fetch data for an indicator\n")
  cat("  - get_indicator_info('CODE') to see full metadata for an indicator\n")
  cat("  - list_categories() to see all available categories\n\n")
  
  # Return data frame invisibly
  df <- do.call(rbind, lapply(matches, function(m) {
    data.frame(
      code = m$code,
      name = m$name,
      category = m$category,
      description = m$description,
      stringsAsFactors = FALSE
    )
  }))
  
  return(invisible(df))
}


#' Resolve indicator category through multiple fallback strategies
#'
#' Tries: explicit category field -> parent code -> prefix-based inference.
#' Used by list_categories() for accurate category counts.
#'
#' @param indicator_code Character. The indicator code
#' @param info Named list. The indicator metadata from cache
#' @return Character. Resolved category name
#' @keywords internal
.resolve_indicator_category <- function(indicator_code, info) {
  # 1. Explicit category in metadata
  if (!is.null(info$category) && nzchar(info$category)) {
    return(info$category)
  }

  # 2. Parent code (top-level codes often map to categories)
  if (!is.null(info$parent) && nzchar(info$parent)) {
    return(info$parent)
  }

  # 3. Prefix-based inference via .infer_category()
  .infer_category(indicator_code)
}


#' List Categories
#'
#' List all available indicator categories (dataflows) with counts.
#' Prints a formatted table of categories showing how many indicators
#' are in each category.
#'
#' @return Invisibly returns a data.frame with category counts.
#'
#' @examples
#' \dontrun{
#' list_categories()
#' }
#'
#' @export
list_categories <- function() {
  indicators <- .ensure_cache_loaded()

  # Count indicators per category, resolving missing categories
  category_counts <- list()
  for (code in names(indicators)) {
    info <- indicators[[code]]
    cat_name <- .resolve_indicator_category(code, info)
    category_counts[[cat_name]] <- (category_counts[[cat_name]] %||% 0) + 1
  }
  
  # Sort by count (descending)
  counts <- unlist(category_counts)
  sorted_cats <- names(sort(counts, decreasing = TRUE))
  
  cat("\n")
  cat(strrep("=", 50), "\n")
  cat("  Available Indicator Categories\n")
  cat(strrep("=", 50), "\n")
  cat(sprintf("\n  %-25s %10s\n", "CATEGORY", "COUNT"))
  cat(strrep("-", 50), "\n")
  
  for (cat_name in sorted_cats) {
    cat(sprintf("  %-25s %10d\n", cat_name, counts[cat_name]))
  }
  
  cat(strrep("-", 50), "\n")
  cat(sprintf("  %-25s %10d\n", "TOTAL", sum(counts)))
  cat("\n")
  cat("  Use search_indicators(category = 'CATEGORY_NAME') to see indicators\n\n")
  
  # Return data frame invisibly
  df <- data.frame(
    category = sorted_cats,
    count = counts[sorted_cats],
    row.names = NULL,
    stringsAsFactors = FALSE
  )
  
  return(invisible(df))
}


#' Refresh Indicator Cache
#'
#' Force refresh of the indicator cache from UNICEF SDMX API.
#'
#' @return Integer. Number of indicators in the refreshed cache
#'
#' @examples
#' \dontrun{
#' n <- refresh_indicator_cache()
#' message(sprintf("Refreshed cache with %d indicators", n))
#' }
#'
#' @export
refresh_indicator_cache <- function() {
  indicators <- .ensure_cache_loaded(force_refresh = TRUE)
  return(length(indicators))
}


#' Get Cache Info
#'
#' Get information about the current cache state.
#'
#' @return Named list with cache metadata
#'
#' @examples
#' \dontrun{
#' info <- get_cache_info()
#' print(info$cache_path)
#' print(info$indicator_count)
#' }
#'
#' @export
get_cache_info <- function() {
  cache_path <- .get_cache_path()
  cached <- .load_cache()
  
  list(
    cache_path = cache_path,
    exists = file.exists(cache_path),
    last_updated = if (!is.null(cached$last_updated)) format(cached$last_updated) else NULL,
    is_stale = .is_cache_stale(cached$last_updated),
    max_age_days = CACHE_MAX_AGE_DAYS,
    indicator_count = if (!is.null(.indicator_cache$data)) length(.indicator_cache$data) else 0
  )
}


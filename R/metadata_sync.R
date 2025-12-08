# =============================================================================
# metadata_sync.R - Sync consolidated metadata from SDMX API
# =============================================================================
#
# This module syncs all metadata from the UNICEF SDMX API and saves to YAML files
# with standardized watermarks matching Python format.
#
# Generated files:
#   - _unicefdata_dataflows.yaml   - Dataflow definitions
#   - _unicefdata_codelists.yaml   - Dimension codelists
#   - _unicefdata_countries.yaml   - Country ISO3 codes
#   - _unicefdata_regions.yaml     - Regional aggregate codes
#   - _unicefdata_indicators.yaml  - Indicator → dataflow mappings
#
# Usage:
#   source("R/metadata_sync.R")
#   sync_all_metadata()
#
# =============================================================================

library(httr)
library(xml2)
library(yaml)

# =============================================================================
# Configuration
# =============================================================================

SDMX_BASE_URL <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
AGENCY <- "UNICEF"
METADATA_VERSION <- "2.0.0"

# File names (matching Python convention)
FILE_DATAFLOWS <- "_unicefdata_dataflows.yaml"
FILE_INDICATORS <- "_unicefdata_indicators.yaml"
FILE_CODELISTS <- "_unicefdata_codelists.yaml"
FILE_COUNTRIES <- "_unicefdata_countries.yaml"
FILE_REGIONS <- "_unicefdata_regions.yaml"
FILE_SYNC_HISTORY <- "_unicefdata_sync_history.yaml"

# SDMX namespaces
SDMX_NS <- c(
  message = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message",
  str = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure",
  com = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common"
)

# =============================================================================
# Helper Functions
# =============================================================================

#' Get metadata directory path
#' @return Path to R/metadata/current/
#' @keywords internal
.get_metadata_dir <- function() {
  # Try relative to working directory
  candidates <- c(
    file.path(getwd(), "metadata", "current"),           # If in R/
    file.path(getwd(), "R", "metadata", "current"),      # If in project root
    file.path(dirname(getwd()), "metadata", "current")   # If in R subdirectory
  )
  
  for (path in candidates) {
    if (dir.exists(dirname(path))) {
      if (!dir.exists(path)) {
        dir.create(path, recursive = TRUE, showWarnings = FALSE)
      }
      return(path)
    }
  }
  
  # Default fallback
  path <- file.path(getwd(), "metadata", "current")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  return(path)
}

#' Create watermarked metadata structure
#' @param content_type Type of content
#' @param source_url Source URL
#' @param content Content list
#' @param counts Count statistics
#' @param extra_metadata Additional metadata fields
#' @return List with _metadata watermark and content
#' @keywords internal
.create_watermarked <- function(content_type, source_url, content, counts, extra_metadata = NULL) {
  metadata <- list(
    `_metadata` = c(
      list(
        platform = "R",
        version = METADATA_VERSION,
        synced_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        source = source_url,
        agency = AGENCY,
        content_type = content_type
      ),
      counts,
      extra_metadata
    )
  )
  c(metadata, content)
}

#' Load shared indicators from config/common_indicators.yaml
#' 
#' This ensures consistency across Python, R, and Stata platforms.
#' 
#' @return List of indicators or NULL if not found
#' @keywords internal
.load_shared_indicators <- function() {
  # Try to find the shared config file
  candidates <- c(
    file.path(getwd(), "..", "config", "common_indicators.yaml"),       # If in R/
    file.path(getwd(), "config", "common_indicators.yaml"),              # If in project root
    file.path(dirname(getwd()), "config", "common_indicators.yaml")      # If in R subdirectory
  )
  
  for (path in candidates) {
    if (file.exists(path)) {
      tryCatch({
        config <- yaml::read_yaml(path)
        if (!is.null(config$COMMON_INDICATORS)) {
          return(config$COMMON_INDICATORS)
        }
      }, error = function(e) {
        message(sprintf("Warning: Could not read shared config: %s", e$message))
      })
    }
  }
  
  NULL
}

#' Get fallback indicators if shared config not available
#' @return List of common indicators
#' @keywords internal
.get_fallback_indicators <- function() {
  list(
    CME_MRM0 = list(code = "CME_MRM0", name = "Neonatal mortality rate", dataflow = "CME", sdg = "3.2.2", unit = "Deaths per 1,000 live births"),
    CME_MRY0T4 = list(code = "CME_MRY0T4", name = "Under-5 mortality rate", dataflow = "CME", sdg = "3.2.1", unit = "Deaths per 1,000 live births"),
    NT_ANT_HAZ_NE2_MOD = list(code = "NT_ANT_HAZ_NE2_MOD", name = "Stunting prevalence (moderate + severe)", dataflow = "NUTRITION", sdg = "2.2.1", unit = "Percentage"),
    NT_ANT_WHZ_NE2 = list(code = "NT_ANT_WHZ_NE2", name = "Wasting prevalence (moderate + severe)", dataflow = "NUTRITION", sdg = "2.2.2", unit = "Percentage"),
    NT_ANT_WHZ_PO2_MOD = list(code = "NT_ANT_WHZ_PO2_MOD", name = "Overweight prevalence (moderate + severe)", dataflow = "NUTRITION", sdg = "2.2.2", unit = "Percentage"),
    ED_ANAR_L02 = list(code = "ED_ANAR_L02", name = "Adjusted net attendance rate, lower secondary", dataflow = "EDUCATION_UIS_SDG", sdg = "4.1.1", unit = "Percentage"),
    ED_CR_L1_UIS_MOD = list(code = "ED_CR_L1_UIS_MOD", name = "Completion rate, primary education", dataflow = "EDUCATION_UIS_SDG", sdg = "4.1.2", unit = "Percentage"),
    ED_CR_L2_UIS_MOD = list(code = "ED_CR_L2_UIS_MOD", name = "Completion rate, lower secondary education", dataflow = "EDUCATION_UIS_SDG", sdg = "4.1.2", unit = "Percentage"),
    ED_MAT_L2 = list(code = "ED_MAT_L2", name = "Minimum proficiency in mathematics, lower secondary", dataflow = "EDUCATION_UIS_SDG", sdg = "4.1.1", unit = "Percentage"),
    ED_READ_L2 = list(code = "ED_READ_L2", name = "Minimum proficiency in reading, lower secondary", dataflow = "EDUCATION_UIS_SDG", sdg = "4.1.1", unit = "Percentage"),
    IM_DTP3 = list(code = "IM_DTP3", name = "DTP3 immunisation coverage", dataflow = "IMMUNISATION", sdg = "3.b.1", unit = "Percentage"),
    IM_MCV1 = list(code = "IM_MCV1", name = "Measles 1st dose coverage", dataflow = "IMMUNISATION", sdg = "3.b.1", unit = "Percentage"),
    HVA_EPI_INF_RT = list(code = "HVA_EPI_INF_RT", name = "HIV incidence rate", dataflow = "HIV_AIDS", sdg = "3.3.1", unit = "Per 1,000 uninfected population"),
    `WS_PPL_W-SM` = list(code = "WS_PPL_W-SM", name = "Population using safely managed drinking water services", dataflow = "WASH_HOUSEHOLDS", sdg = "6.1.1", unit = "Percentage"),
    `WS_PPL_S-SM` = list(code = "WS_PPL_S-SM", name = "Population using safely managed sanitation services", dataflow = "WASH_HOUSEHOLDS", sdg = "6.2.1", unit = "Percentage"),
    `WS_PPL_H-B` = list(code = "WS_PPL_H-B", name = "Population with basic handwashing facilities", dataflow = "WASH_HOUSEHOLDS", sdg = "6.2.1", unit = "Percentage"),
    MNCH_ABR = list(code = "MNCH_ABR", name = "Adolescent birth rate", dataflow = "MNCH", sdg = "3.7.2", unit = "Births per 1,000 women aged 15-19"),
    MNCH_MMR = list(code = "MNCH_MMR", name = "Maternal mortality ratio", dataflow = "MNCH", sdg = "3.1.1", unit = "Deaths per 100,000 live births"),
    MNCH_SAB = list(code = "MNCH_SAB", name = "Skilled attendant at birth", dataflow = "MNCH", sdg = "3.1.2", unit = "Percentage"),
    PT_CHLD_Y0T4_REG = list(code = "PT_CHLD_Y0T4_REG", name = "Birth registration (children under 5)", dataflow = "PT", sdg = "16.9.1", unit = "Percentage"),
    `PT_CHLD_1-14_PS-PSY-V_CGVR` = list(code = "PT_CHLD_1-14_PS-PSY-V_CGVR", name = "Children experiencing violent discipline", dataflow = "PT", sdg = "16.2.1", unit = "Percentage"),
    `PT_F_20-24_MRD_U18_TND` = list(code = "PT_F_20-24_MRD_U18_TND", name = "Child marriage (women married by 18)", dataflow = "PT_CM", sdg = "5.3.1", unit = "Percentage"),
    `PT_F_15-49_FGM` = list(code = "PT_F_15-49_FGM", name = "Female genital mutilation prevalence (15-49)", dataflow = "PT_FGM", sdg = "5.3.2", unit = "Percentage"),
    ECD_CHLD_LMPSL = list(code = "ECD_CHLD_LMPSL", name = "Children developmentally on track", dataflow = "ECD", sdg = "4.2.1", unit = "Percentage"),
    `PV_CHLD_DPRV-S-L1-HS` = list(code = "PV_CHLD_DPRV-S-L1-HS", name = "Children in severe deprivation (health and shelter)", dataflow = "CHLD_PVTY", sdg = "1.2.1", unit = "Percentage")
  )
}

#' Save YAML with proper formatting
#' @param filename Filename
#' @param data Data to save
#' @param output_dir Output directory
#' @keywords internal
.save_yaml <- function(filename, data, output_dir) {
  filepath <- file.path(output_dir, filename)
  yaml_content <- yaml::as.yaml(data, indent.mapping.sequence = TRUE)
  # Standardize null representation: use 'null' instead of '~' (matching Python)
  yaml_content <- gsub(": ~$", ": null", yaml_content)
  yaml_content <- gsub(": ~\n", ": null\n", yaml_content)
  # Remove trailing newlines and use cat to avoid extra newline from writeLines
  yaml_content <- sub("\n+$", "", yaml_content)
  # Ensure UTF-8 encoding when writing (important for special characters from API)
  con <- file(filepath, "w", encoding = "UTF-8")
  on.exit(close(con))
  cat(yaml_content, "\n", file = con, sep = "")
  invisible(filepath)
}

#' Fetch with retries
#' @param url URL to fetch
#' @param max_retries Number of retries
#' @return Response content or NULL
#' @keywords internal
.fetch_with_retry <- function(url, max_retries = 3) {
  ua <- httr::user_agent("unicefData-R/1.0")
  
  for (attempt in seq_len(max_retries)) {
    tryCatch({
      response <- httr::GET(url, ua, httr::timeout(120))
      
      if (httr::status_code(response) == 404) {
        return(NULL)
      }
      
      httr::stop_for_status(response)
      return(httr::content(response, as = "text", encoding = "UTF-8"))
      
    }, error = function(e) {
      if (attempt < max_retries) {
        message(sprintf("  Attempt %d failed: %s. Retrying...", attempt, e$message))
        Sys.sleep(2^(attempt - 1))
      } else {
        warning(sprintf("Failed after %d attempts: %s", max_retries, e$message))
        return(NULL)
      }
    })
  }
  
  NULL
}

# =============================================================================
# Sync Functions
# =============================================================================

#' Sync dataflow definitions
#' @param verbose Print progress
#' @param output_dir Output directory
#' @return List of dataflows
#' @export
sync_dataflows <- function(verbose = TRUE, output_dir = NULL) {
  if (is.null(output_dir)) output_dir <- .get_metadata_dir()
  
  if (verbose) cat("  Fetching dataflows...\n")
  
  url <- paste0(SDMX_BASE_URL, "/dataflow/", AGENCY, "?references=none&detail=full")
  xml_content <- .fetch_with_retry(url)
  
  if (is.null(xml_content)) {
    warning("Failed to fetch dataflows")
    return(list())
  }
  
  doc <- xml2::read_xml(xml_content)
  
  # Register namespaces
  ns <- xml2::xml_ns(doc)
  
  # Find all Dataflow elements
  df_nodes <- xml2::xml_find_all(doc, ".//str:Dataflow", ns)
  
  dataflows <- list()
  for (node in df_nodes) {
    df_id <- xml2::xml_attr(node, "id")
    agency <- xml2::xml_attr(node, "agencyID") %||% AGENCY
    version <- xml2::xml_attr(node, "version") %||% "1.0"
    
    name_node <- xml2::xml_find_first(node, ".//com:Name", ns)
    name <- if (!is.na(name_node)) xml2::xml_text(name_node) else df_id
    
    desc_node <- xml2::xml_find_first(node, ".//com:Description", ns)
    description <- if (!is.na(desc_node)) xml2::xml_text(desc_node) else NA
    
    dataflows[[df_id]] <- list(
      id = df_id,
      name = name,
      agency = agency,
      version = version,
      description = if (is.na(description)) NULL else description,
      dimensions = NULL,
      indicators = NULL,
      last_updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    )
  }
  
  # Save with watermark
  data <- .create_watermarked(
    content_type = "dataflows",
    source_url = url,
    content = list(dataflows = dataflows),
    counts = list(total_dataflows = length(dataflows))
  )
  .save_yaml(FILE_DATAFLOWS, data, output_dir)
  
  if (verbose) cat(sprintf("    Found %d dataflows\n", length(dataflows)))
  
  dataflows
}

#' Fetch a single codelist
#' @param codelist_id Codelist ID
#' @return List with codes and metadata
#' @keywords internal
.fetch_codelist <- function(codelist_id) {
  url <- paste0(SDMX_BASE_URL, "/codelist/", AGENCY, "/", codelist_id, "/latest")
  xml_content <- .fetch_with_retry(url)
  
  if (is.null(xml_content)) {
    return(NULL)
  }
  
  doc <- xml2::read_xml(xml_content)
  ns <- xml2::xml_ns(doc)
  
  # Get codelist name
  cl_name_node <- xml2::xml_find_first(doc, ".//str:Codelist/com:Name", ns)
  codelist_name <- if (!is.na(cl_name_node)) xml2::xml_text(cl_name_node) else codelist_id
  
  # Find all Code elements
  code_nodes <- xml2::xml_find_all(doc, ".//str:Code", ns)
  
  codes <- list()
  for (node in code_nodes) {
    code_id <- xml2::xml_attr(node, "id")
    name_node <- xml2::xml_find_first(node, ".//com:Name", ns)
    name <- if (!is.na(name_node)) xml2::xml_text(name_node) else code_id
    codes[[code_id]] <- name
  }
  
  list(
    id = codelist_id,
    name = codelist_name,
    agency = AGENCY,
    version = "latest",
    codes = codes,
    last_updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
}

#' Sync codelists (excluding countries/regions)
#' @param codelist_ids Vector of codelist IDs
#' @param verbose Print progress
#' @param output_dir Output directory
#' @return List of codelists
#' @export
sync_codelists <- function(codelist_ids = NULL, verbose = TRUE, output_dir = NULL) {
  if (is.null(output_dir)) output_dir <- .get_metadata_dir()
  
  if (is.null(codelist_ids)) {
    codelist_ids <- c(
      "CL_AGE",
      "CL_WEALTH_QUINTILE",
      "CL_RESIDENCE",
      "CL_UNIT_MEASURE",
      "CL_OBS_STATUS"
    )
  }
  
  if (verbose) cat("  Fetching codelists...\n")
  
  codelists <- list()
  codes_per_list <- list()
  
  for (cl_id in codelist_ids) {
    tryCatch({
      cl <- .fetch_codelist(cl_id)
      if (!is.null(cl)) {
        codelists[[cl_id]] <- cl
        codes_per_list[[cl_id]] <- length(cl$codes)
      }
    }, error = function(e) {
      if (verbose) cat(sprintf("    Warning: Could not fetch %s: %s\n", cl_id, e$message))
    })
  }
  
  # Save with watermark
  data <- .create_watermarked(
    content_type = "codelists",
    source_url = paste0(SDMX_BASE_URL, "/codelist/", AGENCY),
    content = list(codelists = codelists),
    counts = list(
      total_codelists = length(codelists),
      codes_per_list = codes_per_list
    )
  )
  .save_yaml(FILE_CODELISTS, data, output_dir)
  
  if (verbose) cat(sprintf("    Found %d codelists\n", length(codelists)))
  
  codelists
}

#' Sync country codes from CL_COUNTRY
#' @param verbose Print progress
#' @param output_dir Output directory
#' @return Named list of countries (code -> name)
#' @export
sync_countries <- function(verbose = TRUE, output_dir = NULL) {
  if (is.null(output_dir)) output_dir <- .get_metadata_dir()
  
  if (verbose) cat("  Fetching country codes...\n")
  
  cl <- .fetch_codelist("CL_COUNTRY")
  
  countries <- list()
  codelist_name <- NULL
  if (!is.null(cl)) {
    countries <- cl$codes
    codelist_name <- cl$name
  }
  
  # Save with watermark
  data <- .create_watermarked(
    content_type = "countries",
    source_url = paste0(SDMX_BASE_URL, "/codelist/", AGENCY, "/CL_COUNTRY/latest"),
    content = list(countries = countries),
    counts = list(total_countries = length(countries)),
    extra_metadata = list(codelist_id = "CL_COUNTRY", codelist_name = codelist_name)
  )
  .save_yaml(FILE_COUNTRIES, data, output_dir)
  
  if (verbose) cat(sprintf("    Found %d country codes\n", length(countries)))
  
  countries
}

#' Sync regional codes from CL_WORLD_REGIONS
#' @param verbose Print progress
#' @param output_dir Output directory
#' @return Named list of regions (code -> name)
#' @export
sync_regions <- function(verbose = TRUE, output_dir = NULL) {
  if (is.null(output_dir)) output_dir <- .get_metadata_dir()
  
  if (verbose) cat("  Fetching regional codes...\n")
  
  cl <- .fetch_codelist("CL_WORLD_REGIONS")
  
  regions <- list()
  codelist_name <- NULL
  if (!is.null(cl)) {
    regions <- cl$codes
    codelist_name <- cl$name
  }
  
  # Save with watermark
  data <- .create_watermarked(
    content_type = "regions",
    source_url = paste0(SDMX_BASE_URL, "/codelist/", AGENCY, "/CL_WORLD_REGIONS/latest"),
    content = list(regions = regions),
    counts = list(total_regions = length(regions)),
    extra_metadata = list(codelist_id = "CL_WORLD_REGIONS", codelist_name = codelist_name)
  )
  .save_yaml(FILE_REGIONS, data, output_dir)
  
  if (verbose) cat(sprintf("    Found %d regional codes\n", length(regions)))
  
  regions
}

#' Sync indicator mappings (indicator -> dataflow)
#' 
#' Uses the shared common_indicators.yaml config file to ensure consistency
#' across Python, R, and Stata platforms.
#'
#' @param dataflows List of dataflows (from sync_dataflows)
#' @param verbose Print progress
#' @param output_dir Output directory
#' @return List with indicators and indicators_by_dataflow
#' @export
sync_indicators <- function(dataflows = NULL, verbose = TRUE, output_dir = NULL) {
  if (is.null(output_dir)) output_dir <- .get_metadata_dir()
  
  if (verbose) cat("  Building indicator catalog from shared config...\n")
  
  # Try to load from shared config file (same as Python)
  COMMON_INDICATORS <- .load_shared_indicators()
  
  if (is.null(COMMON_INDICATORS) || length(COMMON_INDICATORS) == 0) {
    warning("Could not load shared config. Using fallback indicators.")
    COMMON_INDICATORS <- .get_fallback_indicators()
  }
  
  indicators <- list()
  indicators_by_dataflow <- list()
  
  for (ind_code in names(COMMON_INDICATORS)) {
    ind_info <- COMMON_INDICATORS[[ind_code]]
    df_id <- ind_info$dataflow
    
    indicators[[ind_code]] <- list(
      code = ind_code,
      name = ind_info$name,
      dataflow = df_id,
      sdg_target = if (!is.null(ind_info$sdg)) ind_info$sdg else NULL,
      unit = if (!is.null(ind_info$unit)) ind_info$unit else NULL,
      description = NULL,
      dimensions = NULL,
      source = "config"
    )
    
    if (is.null(indicators_by_dataflow[[df_id]])) {
      indicators_by_dataflow[[df_id]] <- list()
    }
    indicators_by_dataflow[[df_id]] <- c(indicators_by_dataflow[[df_id]], ind_code)
  }
  
  # Save with watermark - note source is now shared config
  # Use named list for indicators_per_dataflow (matching Python format)
  ind_counts <- as.list(sapply(indicators_by_dataflow, length))
  
  data <- .create_watermarked(
    content_type = "indicators",
    source_url = "unicef_api.config + SDMX API",
    content = list(
      indicators = indicators
    ),
    counts = list(
      total_indicators = length(indicators),
      dataflows_covered = length(indicators_by_dataflow),
      indicators_per_dataflow = ind_counts
    )
  )
  .save_yaml(FILE_INDICATORS, data, output_dir)
  
  if (verbose) cat(sprintf("    Mapped %d indicators to %d dataflows\n", 
                           length(indicators), length(indicators_by_dataflow)))
  
  list(indicators = indicators, indicators_by_dataflow = indicators_by_dataflow)
}

# =============================================================================
# Main Sync Function
# =============================================================================

#' Sync all metadata from UNICEF SDMX API
#'
#' Downloads dataflows, codelists, countries, regions, indicator
#' definitions, and optionally dataflow schemas, saving them as YAML files 
#' with standardized watermarks.
#'
#' @param verbose Print progress messages
#' @param output_dir Output directory (default: R/metadata/current/)
#' @param include_schemas Sync dataflow schemas (default: TRUE). This generates
#'   dataflow_index.yaml and individual dataflow YAML files in dataflows/
#' @param include_sample_values Include sample values in schemas (default: TRUE)
#' @return List with sync summary
#' @export
#'
#' @examples
#' \dontrun{
#' # Sync all metadata including schemas
#' results <- sync_all_metadata()
#' 
#' # Sync without schemas (faster)
#' results <- sync_all_metadata(include_schemas = FALSE)
#' 
#' # Sync with custom output directory
#' results <- sync_all_metadata(output_dir = "./my_metadata/")
#' }
sync_all_metadata <- function(verbose = TRUE, output_dir = NULL, 
                               include_schemas = TRUE, include_sample_values = TRUE) {
  if (is.null(output_dir)) output_dir <- .get_metadata_dir()
  
  results <- list(
    synced_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    output_dir = output_dir,
    dataflows = 0,
    codelists = 0,
    countries = 0,
    regions = 0,
    indicators = 0,
    schemas = NULL,
    schemas_failed = NULL,
    files_created = character(),
    errors = character()
  )
  
  if (verbose) {
    cat(strrep("=", 80), "\n")
    cat("UNICEF Metadata Sync (R)\n")
    cat(strrep("=", 80), "\n")
    cat(sprintf("Output location: %s\n", output_dir))
    cat(sprintf("Timestamp: %s\n", results$synced_at))
    cat(strrep("-", 80), "\n")
  }
  
  # 1. Sync dataflows
  tryCatch({
    dataflows <- sync_dataflows(verbose = verbose, output_dir = output_dir)
    results$dataflows <- length(dataflows)
    results$files_created <- c(results$files_created, FILE_DATAFLOWS)
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Dataflows:", e$message))
    if (verbose) cat(sprintf("    Error: %s\n", e$message))
  })
  
  # 2. Sync codelists
  tryCatch({
    codelists <- sync_codelists(verbose = verbose, output_dir = output_dir)
    results$codelists <- length(codelists)
    results$files_created <- c(results$files_created, FILE_CODELISTS)
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Codelists:", e$message))
    if (verbose) cat(sprintf("    Error: %s\n", e$message))
  })
  
  # 3. Sync countries
  tryCatch({
    countries <- sync_countries(verbose = verbose, output_dir = output_dir)
    results$countries <- length(countries)
    results$files_created <- c(results$files_created, FILE_COUNTRIES)
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Countries:", e$message))
    if (verbose) cat(sprintf("    Error: %s\n", e$message))
  })
  
  # 4. Sync regions
  tryCatch({
    regions <- sync_regions(verbose = verbose, output_dir = output_dir)
    results$regions <- length(regions)
    results$files_created <- c(results$files_created, FILE_REGIONS)
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Regions:", e$message))
    if (verbose) cat(sprintf("    Error: %s\n", e$message))
  })
  
  # 5. Sync indicators
  tryCatch({
    ind_result <- sync_indicators(verbose = verbose, output_dir = output_dir)
    results$indicators <- length(ind_result$indicators)
    results$files_created <- c(results$files_created, FILE_INDICATORS)
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Indicators:", e$message))
    if (verbose) cat(sprintf("    Error: %s\n", e$message))
  })
  
  # 6. Sync dataflow schemas (if requested)
  if (include_schemas) {
    tryCatch({
      # Source the schema_sync.R if not already loaded
      schema_sync_path <- file.path(dirname(sys.frame(1)$ofile %||% "."), "schema_sync.R")
      if (!file.exists(schema_sync_path)) {
        # Try relative to output_dir
        schema_sync_path <- file.path(dirname(output_dir), "..", "schema_sync.R")
      }
      if (!file.exists(schema_sync_path)) {
        # Try relative to working directory
        schema_sync_path <- file.path(getwd(), "schema_sync.R")
      }
      if (!file.exists(schema_sync_path)) {
        schema_sync_path <- file.path(getwd(), "R", "schema_sync.R")
      }
      
      if (file.exists(schema_sync_path)) {
        source(schema_sync_path, local = FALSE)
      }
      
      if (exists("sync_dataflow_schemas")) {
        if (verbose) cat("  Syncing dataflow schemas...\n")
        schema_result <- sync_dataflow_schemas(
          output_dir = output_dir, 
          verbose = verbose, 
          include_sample_values = include_sample_values
        )
        results$schemas <- schema_result$success
        results$schemas_failed <- schema_result$failed
        results$files_created <- c(results$files_created, "dataflow_index.yaml", "dataflows/")
      } else {
        if (verbose) cat("  Warning: sync_dataflow_schemas not available\n")
      }
    }, error = function(e) {
      results$errors <<- c(results$errors, paste("Schemas:", e$message))
      if (verbose) cat(sprintf("    Error syncing schemas: %s\n", e$message))
    })
  }
  
  # Summary
  if (verbose) {
    cat(strrep("-", 80), "\n")
    cat("Sync Complete:\n")
    cat(sprintf("  - %s - %d dataflows\n", FILE_DATAFLOWS, results$dataflows))
    cat(sprintf("  - %s - %d codelists\n", FILE_CODELISTS, results$codelists))
    cat(sprintf("  - %s - %d countries\n", FILE_COUNTRIES, results$countries))
    cat(sprintf("  - %s - %d regions\n", FILE_REGIONS, results$regions))
    cat(sprintf("  - %s - %d indicators\n", FILE_INDICATORS, results$indicators))
    if (!is.null(results$schemas)) {
      cat(sprintf("  - dataflow_index.yaml + dataflows/ - %d schemas", results$schemas))
      if (!is.null(results$schemas_failed) && results$schemas_failed > 0) {
        cat(sprintf(" (%d failed)", results$schemas_failed))
      }
      cat("\n")
    }
    if (length(results$errors) > 0) {
      cat(sprintf("  Errors: %d\n", length(results$errors)))
      for (err in results$errors) {
        cat(sprintf("    - %s\n", err))
      }
    }
    cat(strrep("=", 80), "\n")
  }
  
  invisible(results)
}

# =============================================================================
# Null coalescing operator (if not already defined)
# =============================================================================
if (!exists("%||%")) {
  `%||%` <- function(x, y) if (is.null(x) || is.na(x)) y else x
}

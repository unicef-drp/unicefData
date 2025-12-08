# R/metadata.R
# Metadata synchronization and validation for UNICEF SDMX API
#
# This module provides functionality to:
# 1. Sync dataflow and indicator metadata from the UNICEF SDMX API
# 2. Cache metadata locally as YAML files for offline use
# 3. Validate downloaded data against cached metadata
# 4. Track metadata versions for triangulation and auditing
#
# File naming convention: _unicefdata_<name>.yaml
# All files include standardized watermark with platform, version, timestamp
#
# Usage:
#   source("R/unicef_api/metadata.R")
#   sync_metadata()  # Downloads and caches all metadata
#   validate_data(df, "CME_MRY0T4")  # Validate data

# Required packages
if (!requireNamespace("yaml", quietly = TRUE)) {
  message("Installing yaml package...")
  install.packages("yaml", repos = "https://cloud.r-project.org")
}

# ============================================================================
# Configuration
# ============================================================================

.metadata_config <- new.env()
.metadata_config$BASE_URL <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
.metadata_config$AGENCY <- "UNICEF"
.metadata_config$CACHE_DIR <- NULL
.metadata_config$METADATA_VERSION <- "2.0.0"

# Standard file names with _unicefdata_ prefix (matches Python)
.metadata_config$FILE_DATAFLOWS <- "_unicefdata_dataflows.yaml"
.metadata_config$FILE_INDICATORS <- "_unicefdata_indicators.yaml"
.metadata_config$FILE_CODELISTS <- "_unicefdata_codelists.yaml"
.metadata_config$FILE_COUNTRIES <- "_unicefdata_countries.yaml"
.metadata_config$FILE_REGIONS <- "_unicefdata_regions.yaml"
.metadata_config$FILE_SYNC_HISTORY <- "_unicefdata_sync_history.yaml"

#' Set metadata cache directory
#' @param path Path to cache directory
#' @export
set_metadata_cache <- function(path = NULL) {

  if (is.null(path)) {
    wd <- getwd()
    # Check if we are in the R directory (heuristic: contains get_unicef.R)
    if (file.exists(file.path(wd, "get_unicef.R")) || file.exists(file.path(wd, "unicef_api", "get_unicef.R"))) {
       path <- file.path(wd, "metadata")
    } else {
       # Assume we are in root or somewhere else, try to target R/metadata
       if (dir.exists(file.path(wd, "R"))) {
         path <- file.path(wd, "R", "metadata")
       } else {
         # Fallback to current directory/metadata
         path <- file.path(wd, "metadata")
       }
    }
  }
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  # Create current/ subdirectory for active metadata (matches Python structure)
  current_dir <- file.path(path, "current")
  if (!dir.exists(current_dir)) {
    dir.create(current_dir, recursive = TRUE)
  }
  .metadata_config$CACHE_DIR <- path
  invisible(path)
}

#' Get metadata cache directory
#' @return Path to cache directory
#' @export
get_metadata_cache <- function() {
  if (is.null(.metadata_config$CACHE_DIR)) {
    set_metadata_cache()
  }
  .metadata_config$CACHE_DIR
}

#' Get current metadata directory
#' @return Path to current/ subdirectory
#' @export
get_current_dir <- function() {
  file.path(get_metadata_cache(), "current")
}

# ============================================================================
# Sync Functions
# ============================================================================

#' Sync all metadata from UNICEF SDMX API
#'
#' Downloads dataflows, codelists, countries, regions, and indicator definitions,
#' then saves them as YAML files in the cache directory with standardized watermarks.
#'
#' @param cache_dir Path to cache directory (default: ./metadata/)
#' @param verbose Print progress messages (default: TRUE)
#' @return List with sync summary including counts and timestamps
#' @export
#' @examples
#' \dontrun{
#' sync_metadata()
#' sync_metadata(cache_dir = "./my_cache/")
#' }
sync_metadata <- function(cache_dir = NULL, verbose = TRUE) {
  if (!is.null(cache_dir)) {
    set_metadata_cache(cache_dir)
  }
  cache_dir <- get_metadata_cache()
  current_dir <- get_current_dir()
  
  results <- list(
    synced_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    vintage_date = format(Sys.Date(), "%Y-%m-%d"),
    dataflows = 0,
    codelists = 0,
    countries = 0,
    regions = 0,
    indicators = 0,
    files_created = character(),
    errors = character()
  )
  
  if (verbose) {
    message(strrep("=", 80))
    message("UNICEF Metadata Sync")
    message(strrep("=", 80))
    message(sprintf("Output location: %s", current_dir))
    message(sprintf("Timestamp: %s", results$synced_at))
    message(strrep("-", 80))
  }
  
  # 1. Sync dataflows
  tryCatch({
    if (verbose) message("  \U0001F4C1 Fetching dataflows...")
    dataflows <- sync_dataflows(verbose = FALSE)
    results$dataflows <- length(dataflows$dataflows)
    results$files_created <- c(results$files_created, .metadata_config$FILE_DATAFLOWS)
    if (verbose) {
      message(sprintf("     \u2713 %s - %d dataflows", 
                      .metadata_config$FILE_DATAFLOWS, results$dataflows))
    }
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Dataflows:", e$message))
    if (verbose) message(sprintf("     \u2717 Dataflows error: %s", e$message))
  })
  
  # 2. Sync codelists (excluding CL_COUNTRY and CL_WORLD_REGIONS)
  tryCatch({
    if (verbose) message("  \U0001F4C1 Fetching codelists...")
    codelists <- sync_codelists(verbose = FALSE)
    results$codelists <- length(codelists$codelists)
    results$files_created <- c(results$files_created, .metadata_config$FILE_CODELISTS)
    if (verbose) {
      codes_summary <- sapply(codelists$codelists, function(cl) length(cl$codes))
      summary_text <- paste(names(codes_summary)[1:min(3, length(codes_summary))], 
                           codes_summary[1:min(3, length(codes_summary))], 
                           sep = ": ", collapse = ", ")
      message(sprintf("     \u2713 %s - %d codelists", 
                      .metadata_config$FILE_CODELISTS, results$codelists))
      message(sprintf("       \u2022 %s...", summary_text))
    }
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Codelists:", e$message))
    if (verbose) message(sprintf("     \u2717 Codelists error: %s", e$message))
  })
  
  # 3. Sync countries
  tryCatch({
    if (verbose) message("  \U0001F4C1 Fetching country codes...")
    countries <- sync_countries(verbose = FALSE)
    results$countries <- length(countries$countries)
    results$files_created <- c(results$files_created, .metadata_config$FILE_COUNTRIES)
    if (verbose) {
      message(sprintf("     \u2713 %s - %d country codes", 
                      .metadata_config$FILE_COUNTRIES, results$countries))
    }
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Countries:", e$message))
    if (verbose) message(sprintf("     \u2717 Countries error: %s", e$message))
  })
  
  # 4. Sync regions
  tryCatch({
    if (verbose) message("  \U0001F4C1 Fetching regional codes...")
    regions <- sync_regions(verbose = FALSE)
    results$regions <- length(regions$regions)
    results$files_created <- c(results$files_created, .metadata_config$FILE_REGIONS)
    if (verbose) {
      message(sprintf("     \u2713 %s - %d regional codes", 
                      .metadata_config$FILE_REGIONS, results$regions))
    }
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Regions:", e$message))
    if (verbose) message(sprintf("     \u2717 Regions error: %s", e$message))
  })
  
  # 5. Build indicators
  tryCatch({
    if (verbose) message("  \U0001F4C1 Building indicator catalog...")
    indicators <- build_indicator_catalog(verbose = FALSE)
    results$indicators <- length(indicators$indicators)
    results$files_created <- c(results$files_created, .metadata_config$FILE_INDICATORS)
    if (verbose) {
      # Group by dataflow for summary
      by_dataflow <- list()
      for (ind in indicators$indicators) {
        df <- ind$dataflow
        if (is.null(by_dataflow[[df]])) by_dataflow[[df]] <- character()
        by_dataflow[[df]] <- c(by_dataflow[[df]], ind$code)
      }
      message(sprintf("     \u2713 %s - %d indicators", 
                      .metadata_config$FILE_INDICATORS, results$indicators))
      shown <- 0
      for (df_name in names(by_dataflow)[1:min(5, length(by_dataflow))]) {
        codes <- by_dataflow[[df_name]]
        message(sprintf("       \u2022 %s: %s indicators", df_name, 
                       paste(codes[1:min(3, length(codes))], collapse = ", ")))
        shown <- shown + 1
      }
      if (length(by_dataflow) > 5) {
        message(sprintf("       \u2022 ... and %d more dataflows", length(by_dataflow) - 5))
      }
    }
  }, error = function(e) {
    results$errors <<- c(results$errors, paste("Indicators:", e$message))
    if (verbose) message(sprintf("     \u2717 Indicators error: %s", e$message))
  })
  
  # 6. Create vintage snapshot
  .create_vintage(results$vintage_date, results, verbose = FALSE)
  
  # 7. Update sync history
  .update_sync_history(results$vintage_date, results)
  results$files_created <- c(results$files_created, .metadata_config$FILE_SYNC_HISTORY)
  
  # Summary
  if (verbose) {
    message(strrep("-", 80))
    message("Summary:")
    message(sprintf("  Total files created: %d", length(results$files_created)))
    message(sprintf("  - Dataflows:   %d", results$dataflows))
    message(sprintf("  - Indicators:  %d", results$indicators))
    message(sprintf("  - Codelists:   %d", results$codelists))
    message(sprintf("  - Countries:   %d", results$countries))
    message(sprintf("  - Regions:     %d", results$regions))
    if (length(results$errors) > 0) {
      message(sprintf("  \u26A0\uFE0F  Errors: %d", length(results$errors)))
      for (err in results$errors) {
        message(sprintf("     - %s", err))
      }
    }
    message(sprintf("  Vintage: %s", results$vintage_date))
    message(strrep("=", 80))
  }
  
  invisible(results)
}

#' Sync dataflow definitions from SDMX API
#'
#' @param verbose Print progress messages
#' @return List with dataflow metadata
#' @export
sync_dataflows <- function(verbose = TRUE) {
  if (verbose) message("  Fetching dataflows...")
  
  url <- sprintf("%s/dataflow/%s?references=none&detail=full",
                 .metadata_config$BASE_URL, .metadata_config$AGENCY)
  
  response <- .fetch_xml(url)
  doc <- xml2::read_xml(response)
  
  # Parse dataflows
  ns <- xml2::xml_ns(doc)
  dfs <- xml2::xml_find_all(doc, ".//str:Dataflow", ns)
  
  dataflows <- list()
  for (df in dfs) {
    df_id <- xml2::xml_attr(df, "id")
    agency <- xml2::xml_attr(df, "agencyID")
    version <- xml2::xml_attr(df, "version")
    
    # Get name
    name_node <- xml2::xml_find_first(df, ".//com:Name", ns)
    name <- if (!is.na(name_node)) xml2::xml_text(name_node) else df_id
    
    # Get description (use NULL for missing values to align with Python's null)
    desc_node <- xml2::xml_find_first(df, ".//com:Description", ns)
    description <- if (!is.na(desc_node)) xml2::xml_text(desc_node) else NULL
    
    # Structure aligned with Python DataflowMetadata
    dataflows[[df_id]] <- list(
      id = df_id,
      name = name,
      agency = agency,
      version = version,
      description = description,
      dimensions = NULL,   # Placeholder for future expansion
      indicators = NULL,   # Placeholder for future expansion
      last_updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    )
  }
  
  # Save with watermark (matches Python format)
  result <- .create_watermarked_list(
    content_type = "dataflows",
    source_url = url,
    content = list(dataflows = dataflows),
    counts = list(total_dataflows = length(dataflows))
  )
  .save_yaml(.metadata_config$FILE_DATAFLOWS, result)
  
  if (verbose) message(sprintf("    Found %d dataflows", length(dataflows)))
  
  invisible(result)
}

#' Sync codelist definitions from SDMX API (excluding countries/regions)
#'
#' @param codelist_ids Vector of codelist IDs to sync (default: common codelists, excluding CL_COUNTRY/CL_WORLD_REGIONS)
#' @param verbose Print progress messages
#' @return List with codelist metadata
#' @export
sync_codelists <- function(codelist_ids = NULL, verbose = TRUE) {
  if (is.null(codelist_ids)) {
    # Codelists excluding CL_COUNTRY and CL_WORLD_REGIONS (handled separately)
    # Note: CL_SEX does not exist on UNICEF SDMX API
    codelist_ids <- c(
      "CL_AGE",                # Age groups
      "CL_WEALTH_QUINTILE",    # Wealth quintiles
      "CL_RESIDENCE",          # Urban/rural
      "CL_UNIT_MEASURE",       # Units of measure
      "CL_OBS_STATUS"          # Observation status
    )
  }
  
  if (verbose) message("  Fetching codelists...")
  
  codelists <- list()
  for (cl_id in codelist_ids) {
    tryCatch({
      cl <- .fetch_codelist(cl_id)
      if (!is.null(cl)) {
        codelists[[cl_id]] <- cl
      }
    }, error = function(e) {
      if (verbose) message(sprintf("    [WARNING] Could not fetch %s: %s", cl_id, e$message))
    })
  }
  
  # Build codes_per_list for watermark
  codes_per_list <- lapply(codelists, function(cl) length(cl$codes))
  
  # Save with watermark (matches Python format)
  result <- .create_watermarked_list(
    content_type = "codelists",
    source_url = sprintf("%s/codelist/%s", .metadata_config$BASE_URL, .metadata_config$AGENCY),
    content = list(codelists = codelists),
    counts = list(
      total_codelists = length(codelists),
      codes_per_list = codes_per_list
    )
  )
  .save_yaml(.metadata_config$FILE_CODELISTS, result)
  
  if (verbose) message(sprintf("    Found %d codelists", length(codelists)))
  
  invisible(result)
}

#' Sync country codes from CL_COUNTRY
#'
#' @param verbose Print progress messages
#' @return List with country codes
#' @export
sync_countries <- function(verbose = TRUE) {
  if (verbose) message("  Fetching country codes...")
  
  cl <- .fetch_codelist("CL_COUNTRY")
  
  countries <- list()
  codelist_name <- NULL
  if (!is.null(cl)) {
    countries <- cl$codes
    codelist_name <- cl$name
  }
  
  # Save with watermark (codelist_name stored in metadata)
  result <- .create_watermarked_list(
    content_type = "countries",
    source_url = sprintf("%s/codelist/%s/CL_COUNTRY/latest", 
                         .metadata_config$BASE_URL, .metadata_config$AGENCY),
    content = list(countries = countries),
    counts = list(total_countries = length(countries)),
    extra_metadata = list(codelist_id = "CL_COUNTRY", codelist_name = codelist_name)
  )
  .save_yaml(.metadata_config$FILE_COUNTRIES, result)
  
  if (verbose) message(sprintf("    Found %d country codes", length(countries)))
  
  invisible(result)
}

#' Sync regional/aggregate codes from CL_WORLD_REGIONS
#'
#' @param verbose Print progress messages
#' @return List with regional codes
#' @export
sync_regions <- function(verbose = TRUE) {
  if (verbose) message("  Fetching regional codes...")
  
  cl <- .fetch_codelist("CL_WORLD_REGIONS")
  
  regions <- list()
  codelist_name <- NULL
  if (!is.null(cl)) {
    regions <- cl$codes
    codelist_name <- cl$name
  }
  
  # Save with watermark (codelist_name stored in metadata)
  result <- .create_watermarked_list(
    content_type = "regions",
    source_url = sprintf("%s/codelist/%s/CL_WORLD_REGIONS/latest", 
                         .metadata_config$BASE_URL, .metadata_config$AGENCY),
    content = list(regions = regions),
    counts = list(total_regions = length(regions)),
    extra_metadata = list(codelist_id = "CL_WORLD_REGIONS", codelist_name = codelist_name)
  )
  .save_yaml(.metadata_config$FILE_REGIONS, result)
  
  if (verbose) message(sprintf("    Found %d regional codes", length(regions)))
  
  invisible(result)
}

#' Build indicator catalog
#'
#' Builds indicator catalog from common SDG indicators.
#' Tries to load from shared config/indicators.yaml first, 
#' falls back to hardcoded definitions if not found.
#'
#' @param verbose Print progress messages
#' @param use_shared_config Try to load from shared YAML config (default: TRUE)
#' @return List with indicator metadata
#' @export
build_indicator_catalog <- function(verbose = TRUE, use_shared_config = TRUE) {
  if (verbose) message("  Building indicator catalog...")
  
  # Try to load from shared config first
  indicators <- NULL
  if (use_shared_config) {
    tryCatch({
      source_file <- file.path(dirname(sys.frame(1)$ofile %||% "."), "config_loader.R")
      if (file.exists(source_file)) {
        source(source_file, local = TRUE)
        indicators <- load_shared_indicators()
        if (verbose && length(indicators) > 0) {
          message("    Loaded indicators from shared config")
        }
      }
    }, error = function(e) {
      if (verbose) message("    Could not load shared config, using fallback")
    })
  }
  
  # Fallback to hardcoded indicators if shared config not available
  if (is.null(indicators) || length(indicators) == 0) {
    indicators <- .get_fallback_indicators()
  }
  
  # Add optional fields for consistency with Python output
  for (ind_name in names(indicators)) {
    ind <- indicators[[ind_name]]
    indicators[[ind_name]] <- list(
      code = ind$code,
      name = ind$name,
      dataflow = ind$dataflow,
      sdg_target = ind$sdg_target,
      unit = ind$unit,
      description = ind$description,  # Will be NULL/~ if not set
      dimensions = NULL,
      source = "config"
    )
  }
  
  # Group by dataflow for counts
  indicators_by_dataflow <- list()
  for (ind in indicators) {
    df <- ind$dataflow
    if (is.null(indicators_by_dataflow[[df]])) indicators_by_dataflow[[df]] <- character()
    indicators_by_dataflow[[df]] <- c(indicators_by_dataflow[[df]], ind$code)
  }
  indicators_per_dataflow <- lapply(indicators_by_dataflow, length)
  
  # Save with watermark (matches Python format)
  result <- .create_watermarked_list(
    content_type = "indicators",
    source_url = "unicef_api.config + SDMX API",
    content = list(indicators = indicators),
    counts = list(
      total_indicators = length(indicators),
      dataflows_covered = length(indicators_by_dataflow),
      indicators_per_dataflow = indicators_per_dataflow
    )
  )
  .save_yaml(.metadata_config$FILE_INDICATORS, result)
  
  if (verbose) message(sprintf("    Cataloged %d indicators", length(indicators)))
  
  invisible(result)
}

#' Get fallback indicator definitions (hardcoded)
#' @keywords internal
.get_fallback_indicators <- function() {
  list(
    # Child Mortality (SDG 3.2)
    CME_MRM0 = list(
      code = "CME_MRM0",
      name = "Neonatal mortality rate",
      dataflow = "CME",
      sdg_target = "3.2.2",
      unit = "Deaths per 1,000 live births"
    ),
    CME_MRY0T4 = list(
      code = "CME_MRY0T4",
      name = "Under-5 mortality rate",
      dataflow = "CME",
      sdg_target = "3.2.1",
      unit = "Deaths per 1,000 live births"
    ),
    
    # Nutrition (SDG 2.2)
    NT_ANT_HAZ_NE2_MOD = list(
      code = "NT_ANT_HAZ_NE2_MOD",
      name = "Stunting prevalence (moderate + severe)",
      dataflow = "NUTRITION",
      sdg_target = "2.2.1",
      unit = "Percentage"
    ),
    NT_ANT_WHZ_NE2 = list(
      code = "NT_ANT_WHZ_NE2",
      name = "Wasting prevalence",
      dataflow = "NUTRITION",
      sdg_target = "2.2.2",
      unit = "Percentage"
    ),
    NT_ANT_WHZ_PO2_MOD = list(
      code = "NT_ANT_WHZ_PO2_MOD",
      name = "Overweight prevalence (moderate + severe)",
      dataflow = "NUTRITION",
      sdg_target = "2.2.2",
      unit = "Percentage"
    ),
    
    # Education (SDG 4.1)
    ED_ANAR_L02 = list(
      code = "ED_ANAR_L02",
      name = "Adjusted net attendance rate, primary education",
      dataflow = "EDUCATION_UIS_SDG",
      sdg_target = "4.1.1",
      unit = "Percentage"
    ),
    ED_CR_L1_UIS_MOD = list(
      code = "ED_CR_L1_UIS_MOD",
      name = "Completion rate, primary education",
      dataflow = "EDUCATION_UIS_SDG",
      sdg_target = "4.1.1",
      unit = "Percentage"
    ),
    ED_CR_L2_UIS_MOD = list(
      code = "ED_CR_L2_UIS_MOD",
      name = "Completion rate, lower secondary education",
      dataflow = "EDUCATION_UIS_SDG",
      sdg_target = "4.1.1",
      unit = "Percentage"
    ),
    ED_READ_L2 = list(
      code = "ED_READ_L2",
      name = "Reading proficiency, end of lower secondary",
      dataflow = "EDUCATION_UIS_SDG",
      sdg_target = "4.1.1",
      unit = "Percentage"
    ),
    ED_MAT_L2 = list(
      code = "ED_MAT_L2",
      name = "Mathematics proficiency, end of lower secondary",
      dataflow = "EDUCATION_UIS_SDG",
      sdg_target = "4.1.1",
      unit = "Percentage"
    ),
    
    # Immunization (SDG 3.b)
    IM_DTP3 = list(
      code = "IM_DTP3",
      name = "DTP3 immunization coverage",
      dataflow = "IMMUNISATION",
      sdg_target = "3.b.1",
      unit = "Percentage"
    ),
    IM_MCV1 = list(
      code = "IM_MCV1",
      name = "Measles immunization coverage (MCV1)",
      dataflow = "IMMUNISATION",
      sdg_target = "3.b.1",
      unit = "Percentage"
    ),
    
    # HIV/AIDS (SDG 3.3)
    HVA_EPI_INF_RT = list(
      code = "HVA_EPI_INF_RT",
      name = "HIV incidence rate",
      dataflow = "HIV_AIDS",
      sdg_target = "3.3.1",
      unit = "Per 1,000 uninfected population"
    ),
    
    # WASH (SDG 6.1, 6.2)
    `WS_PPL_W-SM` = list(
      code = "WS_PPL_W-SM",
      name = "Population using safely managed drinking water services",
      dataflow = "WASH_HOUSEHOLDS",
      sdg_target = "6.1.1",
      unit = "Percentage"
    ),
    `WS_PPL_S-SM` = list(
      code = "WS_PPL_S-SM",
      name = "Population using safely managed sanitation services",
      dataflow = "WASH_HOUSEHOLDS",
      sdg_target = "6.2.1",
      unit = "Percentage"
    ),
    `WS_PPL_H-B` = list(
      code = "WS_PPL_H-B",
      name = "Population with basic handwashing facilities",
      dataflow = "WASH_HOUSEHOLDS",
      sdg_target = "6.2.1",
      unit = "Percentage"
    ),
    
    # Maternal and Child Health (SDG 3.1, 3.7)
    MNCH_MMR = list(
      code = "MNCH_MMR",
      name = "Maternal mortality ratio",
      dataflow = "MNCH",
      sdg_target = "3.1.1",
      unit = "Deaths per 100,000 live births"
    ),
    MNCH_SAB = list(
      code = "MNCH_SAB",
      name = "Skilled attendance at birth",
      dataflow = "MNCH",
      sdg_target = "3.1.2",
      unit = "Percentage"
    ),
    MNCH_ABR = list(
      code = "MNCH_ABR",
      name = "Adolescent birth rate",
      dataflow = "MNCH",
      sdg_target = "3.7.2",
      unit = "Births per 1,000 women aged 15-19"
    ),
    
    # Child Protection (SDG 5.3, 16.2, 16.9)
    PT_CHLD_Y0T4_REG = list(
      code = "PT_CHLD_Y0T4_REG",
      name = "Birth registration (children under 5)",
      dataflow = "PT",
      sdg_target = "16.9.1",
      unit = "Percentage"
    ),
    `PT_CHLD_1-14_PS-PSY-V_CGVR` = list(
      code = "PT_CHLD_1-14_PS-PSY-V_CGVR",
      name = "Violent discipline (children 1-14)",
      dataflow = "PT",
      sdg_target = "16.2.1",
      unit = "Percentage"
    ),
    `PT_F_20-24_MRD_U18_TND` = list(
      code = "PT_F_20-24_MRD_U18_TND",
      name = "Child marriage before age 18 (women 20-24)",
      dataflow = "PT_CM",
      sdg_target = "5.3.1",
      unit = "Percentage"
    ),
    `PT_F_15-49_FGM` = list(
      code = "PT_F_15-49_FGM",
      name = "Female genital mutilation prevalence (women 15-49)",
      dataflow = "PT_FGM",
      sdg_target = "5.3.2",
      unit = "Percentage"
    ),
    
    # Early Childhood Development (SDG 4.2)
    ECD_CHLD_LMPSL = list(
      code = "ECD_CHLD_LMPSL",
      name = "Children developmentally on track (literacy-numeracy, physical, social-emotional)",
      dataflow = "ECD",
      sdg_target = "4.2.1",
      unit = "Percentage"
    ),
    
    # Child Poverty (SDG 1.2)
    `PV_CHLD_DPRV-S-L1-HS` = list(
      code = "PV_CHLD_DPRV-S-L1-HS",
      name = "Child multidimensional poverty (severe deprivation in at least 1 dimension)",
      dataflow = "CHLD_PVTY",
      sdg_target = "1.2.1",
      unit = "Percentage"
    )
  )
}

# ============================================================================
# Load Functions
# ============================================================================

#' Load cached dataflow metadata from YAML
#' @return List with dataflow metadata
#' @export
load_dataflows <- function() {
  .load_yaml("dataflows.yaml")
}

#' Load cached codelist metadata from YAML
#' @return List with codelist metadata
#' @export
load_codelists <- function() {
  .load_yaml("codelists.yaml")
}

#' Load cached indicator metadata from YAML
#' @return List with indicator metadata
#' @export
load_indicators <- function() {
  .load_yaml("indicators.yaml")
}

#' Load sync history
#' @return List with sync history (matches Python structure)
#' @export
load_sync_history <- function() {
  cache_dir <- get_metadata_cache()
  history_file <- file.path(cache_dir, "sync_history.yaml")
  if (!file.exists(history_file)) {
    return(list(vintages = list()))
  }
  yaml::read_yaml(history_file)
}

#' Load last sync summary (deprecated, use load_sync_history)
#' @return List with sync summary from latest vintage
#' @export
load_sync_summary <- function() {
  history <- load_sync_history()
  if (length(history$vintages) > 0) {
    return(history$vintages[[1]])
  }
  list()
}

#' Get metadata for a specific dataflow
#' @param dataflow_id Dataflow identifier
#' @return List with dataflow metadata or NULL
#' @export
get_dataflow_meta <- function(dataflow_id) {
  dataflows <- load_dataflows()
  dataflows$dataflows[[dataflow_id]]
}

#' Get metadata for a specific indicator
#' @param indicator_code Indicator code
#' @return List with indicator metadata or NULL
#' @export
get_indicator_meta <- function(indicator_code) {
  indicators <- load_indicators()
  indicators$indicators[[indicator_code]]
}

#' Get metadata for a specific codelist
#' @param codelist_id Codelist identifier
#' @return List with codelist metadata or NULL
#' @export
get_codelist_meta <- function(codelist_id) {
  codelists <- load_codelists()
  codelists$codelists[[codelist_id]]
}

# ============================================================================
# Validation Functions
# ============================================================================

#' Validate a data frame against cached metadata
#'
#' Checks:
#' - Indicator code exists in catalog
#' - Required columns are present
#' - Country codes are valid
#' - Values are within expected ranges
#'
#' @param df Data frame to validate
#' @param indicator_code Expected indicator code
#' @param strict If TRUE, fail on any warning
#' @return List with is_valid (logical) and issues (character vector)
#' @export
#' @examples
#' \dontrun{
#' result <- validate_data(df, "CME_MRY0T4")
#' if (result$is_valid) {
#'   message("Data is valid!")
#' } else {
#'   message("Issues found:")
#'   print(result$issues)
#' }
#' }
validate_data <- function(df, indicator_code, strict = FALSE) {
  issues <- character()
  
  # Check indicator exists
  indicator <- get_indicator_meta(indicator_code)
  if (is.null(indicator)) {
    issues <- c(issues, sprintf("Indicator '%s' not found in catalog", indicator_code))
  }
  
  # Check required columns
  required_cols <- c("REF_AREA", "TIME_PERIOD", "OBS_VALUE")
  for (col in required_cols) {
    if (!col %in% names(df)) {
      issues <- c(issues, sprintf("Missing required column: %s", col))
    }
  }
  
  # Validate country codes if codelist available
  codelists <- load_codelists()
  ref_area_codes <- names(codelists$codelists$CL_REF_AREA$codes)
  if (length(ref_area_codes) > 0 && "REF_AREA" %in% names(df)) {
    invalid_countries <- setdiff(unique(df$REF_AREA), ref_area_codes)
    if (length(invalid_countries) > 0) {
      sample_invalid <- head(invalid_countries, 5)
      issues <- c(issues, sprintf("Invalid country codes: %s...", 
                                  paste(sample_invalid, collapse = ", ")))
    }
  }
  
  # Check for empty data
  if (nrow(df) == 0) {
    issues <- c(issues, "Data frame is empty")
  }
  
  # Check for null values in key columns
  if ("OBS_VALUE" %in% names(df)) {
    null_pct <- sum(is.na(df$OBS_VALUE)) / nrow(df) * 100
    if (null_pct > 50) {
      issues <- c(issues, sprintf("High null rate in OBS_VALUE: %.1f%%", null_pct))
    }
  }
  
  is_valid <- if (strict) {
    length(issues) == 0
  } else {
    !any(grepl("Missing", issues))
  }
  
  list(is_valid = is_valid, issues = issues)
}

#' Compute hash of data frame for version tracking
#' @param df Data frame to hash
#' @return Character hash string (16 characters)
#' @export
compute_data_hash <- function(df) {
  # Sort for consistent hashing
  df_sorted <- df[order(as.matrix(df)), ]
  content <- paste(capture.output(write.csv(df_sorted, row.names = FALSE)), collapse = "\n")
  substr(digest::digest(content, algo = "sha256"), 1, 16)
}

#' Create version record for a downloaded dataset
#'
#' @param df Downloaded data frame
#' @param indicator_code Indicator code
#' @param version_id Optional version identifier
#' @param notes Optional notes about this version
#' @return List with version metadata
#' @export
create_data_version <- function(df, indicator_code, version_id = NULL, notes = NULL) {
  if (is.null(version_id)) {
    version_id <- format(Sys.time(), "v%Y%m%d_%H%M%S")
  }
  
  version <- list(
    version_id = version_id,
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    indicator_code = indicator_code,
    data_hash = compute_data_hash(df),
    row_count = nrow(df),
    column_count = ncol(df),
    columns = names(df),
    notes = notes
  )
  
  # Add summary statistics
  if ("REF_AREA" %in% names(df)) {
    version$unique_countries <- length(unique(df$REF_AREA))
  }
  if ("TIME_PERIOD" %in% names(df)) {
    version$year_range <- c(
      min(as.integer(df$TIME_PERIOD), na.rm = TRUE),
      max(as.integer(df$TIME_PERIOD), na.rm = TRUE)
    )
  }
  if ("OBS_VALUE" %in% names(df)) {
    version$value_range <- c(
      min(df$OBS_VALUE, na.rm = TRUE),
      max(df$OBS_VALUE, na.rm = TRUE)
    )
  }
  
  version
}

# ============================================================================
# Vintage Control Functions
# ============================================================================

#' List available metadata vintages
#'
#' Returns dates of all metadata snapshots stored in the vintages/ directory.
#' Vintages are sorted newest first.
#'
#' @param cache_dir Optional cache directory path
#' @return Character vector of vintage dates (YYYY-MM-DD format)
#' @export
#' @examples
#' \dontrun{
#' list_vintages()
#' # [1] "2025-12-02" "2025-11-15" "2025-10-01"
#' }
list_vintages <- function(cache_dir = NULL) {
  if (!is.null(cache_dir)) {
    set_metadata_cache(cache_dir)
  }
  cache_dir <- get_metadata_cache()
  
  vintages_dir <- file.path(cache_dir, "vintages")
  if (!dir.exists(vintages_dir)) {
    return(character())
  }
  
  vintages <- list.dirs(vintages_dir, full.names = FALSE, recursive = FALSE)
  # Sort newest first
  sort(vintages, decreasing = TRUE)
}

#' Get path to a specific vintage
#'
#' @param vintage Vintage date (YYYY-MM-DD) or NULL for current
#' @param cache_dir Optional cache directory path
#' @return Path to vintage directory
#' @export
get_vintage_path <- function(vintage = NULL, cache_dir = NULL) {
  if (!is.null(cache_dir)) {
    set_metadata_cache(cache_dir)
  }
  cache_dir <- get_metadata_cache()
  
  if (is.null(vintage)) {
    return(cache_dir)  # Current metadata
  }
  
  vintage_path <- file.path(cache_dir, "vintages", vintage)
  if (!dir.exists(vintage_path)) {
    stop(sprintf("Vintage '%s' not found. Available: %s", 
                 vintage, paste(list_vintages(), collapse = ", ")))
  }
  vintage_path
}

#' Load metadata from a specific vintage
#'
#' @param vintage Vintage date (YYYY-MM-DD) or NULL for current
#' @param cache_dir Optional cache directory path
#' @return List with dataflows, codelists, and indicators
#' @export
#' @examples
#' \dontrun{
#' # Load current metadata
#' meta <- load_vintage()
#' 
#' # Load from specific vintage
#' meta <- load_vintage("2025-11-15")
#' }
load_vintage <- function(vintage = NULL, cache_dir = NULL) {
  vintage_path <- get_vintage_path(vintage, cache_dir)
  
  list(
    dataflows = .load_yaml_from_path(file.path(vintage_path, "dataflows.yaml")),
    codelists = .load_yaml_from_path(file.path(vintage_path, "codelists.yaml")),
    indicators = .load_yaml_from_path(file.path(vintage_path, "indicators.yaml"))
  )
}

#' Compare two metadata vintages
#'
#' Compares dataflows between two vintages to identify additions,
#' removals, and modifications.
#'
#' @param vintage1 Earlier vintage date (YYYY-MM-DD)
#' @param vintage2 Later vintage date (YYYY-MM-DD) or NULL for current
#' @param cache_dir Optional cache directory path
#' @return List with added, removed, and changed items
#' @export
#' @examples
#' \dontrun{
#' # Compare historical vintage to current
#' changes <- compare_vintages("2025-11-15")
#' 
#' # Compare two historical vintages
#' changes <- compare_vintages("2025-10-01", "2025-11-15")
#' 
#' if (length(changes$added) > 0) {
#'   message(sprintf("New dataflows: %s", paste(changes$added, collapse = ", ")))
#' }
#' }
compare_vintages <- function(vintage1, vintage2 = NULL, cache_dir = NULL) {
  if (!is.null(cache_dir)) {
    set_metadata_cache(cache_dir)
  }
  
  meta1 <- load_vintage(vintage1)
  meta2 <- load_vintage(vintage2)
  
  # Compare dataflows
  df_ids1 <- names(meta1$dataflows$dataflows)
  df_ids2 <- names(meta2$dataflows$dataflows)
  
  added <- setdiff(df_ids2, df_ids1)
  removed <- setdiff(df_ids1, df_ids2)
  
  # Check for changes in common dataflows
  common <- intersect(df_ids1, df_ids2)
  changed <- character()
  
  for (df_id in common) {
    v1 <- meta1$dataflows$dataflows[[df_id]]$version
    v2 <- meta2$dataflows$dataflows[[df_id]]$version
    if (!identical(v1, v2)) {
      changed <- c(changed, df_id)
    }
  }
  
  list(
    vintage1 = vintage1,
    vintage2 = if (is.null(vintage2)) "current" else vintage2,
    dataflows = list(
      added = added,
      removed = removed,
      changed = changed
    ),
    indicators = list(
      added = setdiff(names(meta2$indicators$indicators), 
                      names(meta1$indicators$indicators)),
      removed = setdiff(names(meta1$indicators$indicators), 
                        names(meta2$indicators$indicators))
    )
  )
}

#' Ensure metadata is synced and fresh
#'
#' Checks if metadata exists and is within max_age_days.
#' If not, performs a sync automatically.
#'
#' @param max_age_days Maximum age in days before re-sync (default: 30)
#' @param verbose Print messages
#' @param cache_dir Optional cache directory path
#' @return Logical indicating if sync was performed
#' @export
#' @examples
#' \dontrun{
#' # Check every 30 days (default)
#' ensure_metadata()
#' 
#' # Check every 7 days
#' ensure_metadata(max_age_days = 7)
#' }
ensure_metadata <- function(max_age_days = 30, verbose = FALSE, cache_dir = NULL) {
  if (!is.null(cache_dir)) {
    set_metadata_cache(cache_dir)
  }
  cache_dir <- get_metadata_cache()
  
  # Use _unicefdata_sync_history.yaml to check freshness (matches Python structure)
  history_file <- file.path(cache_dir, .metadata_config$FILE_SYNC_HISTORY)
  
  needs_sync <- TRUE
  
  if (file.exists(history_file)) {
    history <- yaml::read_yaml(history_file)
    vintages <- history$vintages
    
    if (!is.null(vintages) && length(vintages) > 0) {
      latest <- vintages[[1]]
      synced_at <- latest$synced_at
      
      if (!is.null(synced_at)) {
        sync_date <- as.Date(substr(synced_at, 1, 10))
        age_days <- as.numeric(Sys.Date() - sync_date)
        needs_sync <- age_days > max_age_days
        
        if (verbose && !needs_sync) {
          message(sprintf("Metadata is fresh (synced %d days ago)", age_days))
        }
      }
    }
  }
  
  if (needs_sync) {
    if (verbose) message("Metadata is stale or missing, syncing...")
    sync_metadata(verbose = verbose)
    return(TRUE)
  }
  
  invisible(FALSE)
}

# ============================================================================
# Private Helpers
# ============================================================================

.fetch_xml <- function(url, retries = 3L) {
  ua <- httr::user_agent("unicefData/0.2.0 (+https://github.com/unicef-drp/unicefData)")
  
  for (attempt in seq_len(retries)) {
    tryCatch({
      response <- httr::GET(url, ua, httr::timeout(30))
      httr::stop_for_status(response)
      return(httr::content(response, as = "text", encoding = "UTF-8"))
    }, error = function(e) {
      if (attempt == retries) stop(e)
      Sys.sleep(2^attempt)
    })
  }
}

.fetch_codelist <- function(codelist_id) {
  url <- sprintf("%s/codelist/%s/%s/latest",
                 .metadata_config$BASE_URL, .metadata_config$AGENCY, codelist_id)
  
  tryCatch({
    response <- .fetch_xml(url)
    doc <- xml2::read_xml(response)
    ns <- xml2::xml_ns(doc)
    
    # Extract codelist's own name (from Codelist element, not Code elements)
    codelist_name <- NULL
    codelist_elem <- xml2::xml_find_first(doc, ".//str:Codelist", ns)
    if (!is.na(codelist_elem)) {
      name_elem <- xml2::xml_find_first(codelist_elem, "com:Name", ns)
      if (!is.na(name_elem)) {
        codelist_name <- xml2::xml_text(name_elem)
      }
    }
    
    codes <- list()
    for (code_elem in xml2::xml_find_all(doc, ".//str:Code", ns)) {
      code_id <- xml2::xml_attr(code_elem, "id")
      name_elem <- xml2::xml_find_first(code_elem, ".//com:Name", ns)
      name <- if (!is.na(name_elem)) xml2::xml_text(name_elem) else code_id
      codes[[code_id]] <- name
    }
    
    list(
      id = codelist_id,
      agency = .metadata_config$AGENCY,
      version = "latest",
      codes = codes,
      last_updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      name = codelist_name  # Codelist's own descriptive name
    )
  }, error = function(e) {
    NULL
  })
}

#' Create a list with standardized watermark header (matches Python format)
#' @param extra_metadata Optional list of additional metadata fields (e.g., codelist_name)
#' @keywords internal
.create_watermarked_list <- function(content_type, source_url, content, counts, extra_metadata = NULL) {
  metadata_list <- c(
    list(
      platform = "R",
      version = .metadata_config$METADATA_VERSION,
      synced_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      source = source_url,
      agency = .metadata_config$AGENCY,
      content_type = content_type
    ),
    counts
  )
  # Add extra metadata fields if provided
  if (!is.null(extra_metadata)) {
    metadata_list <- c(metadata_list, extra_metadata)
  }
  
  watermark <- list(`_metadata` = metadata_list)
  # Merge watermark with content
  c(watermark, content)
}

.save_yaml <- function(filename, data) {
  current_dir <- get_current_dir()
  if (!dir.exists(current_dir)) {
    dir.create(current_dir, recursive = TRUE)
  }
  filepath <- file.path(current_dir, filename)
  # Write YAML without line wrapping for cross-platform consistency
  yaml_lines <- .yaml_no_wrap(data)
  writeLines(yaml_lines, filepath, useBytes = TRUE)
  invisible(filepath)
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

.load_yaml <- function(filename) {
  current_dir <- get_current_dir()
  filepath <- file.path(current_dir, filename)
  if (!file.exists(filepath)) {
    return(list())
  }
  yaml::read_yaml(filepath)
}

.load_yaml_from_path <- function(filepath) {
  if (!file.exists(filepath)) {
    return(list())
  }
  yaml::read_yaml(filepath)
}

.create_vintage <- function(vintage_date, results, verbose = TRUE) {
  cache_dir <- get_metadata_cache()
  current_dir <- get_current_dir()
  
  # Create vintages directory structure
  vintage_dir <- file.path(cache_dir, "vintages", vintage_date)
  
  # Skip if vintage already exists (don't overwrite)
  if (dir.exists(vintage_dir)) {
    return(invisible(vintage_dir))
  }
  
  dir.create(vintage_dir, recursive = TRUE)
  
  # Copy current YAML files to vintage (using new naming convention)
  vintage_files <- c(
    .metadata_config$FILE_DATAFLOWS,
    .metadata_config$FILE_INDICATORS,
    .metadata_config$FILE_CODELISTS,
    .metadata_config$FILE_COUNTRIES,
    .metadata_config$FILE_REGIONS
  )
  for (filename in vintage_files) {
    src <- file.path(current_dir, filename)
    if (file.exists(src)) {
      dst <- file.path(vintage_dir, filename)
      file.copy(src, dst, overwrite = TRUE)
    }
  }
  
  # Save vintage summary
  summary <- list(
    vintage_date = vintage_date,
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    dataflows = results$dataflows,
    codelists = results$codelists,
    indicators = results$indicators,
    countries = results$countries,
    regions = results$regions
  )
  yaml::write_yaml(summary, file.path(vintage_dir, "summary.yaml"))
  
  invisible(vintage_dir)
}

.update_sync_history <- function(vintage_date, results) {
  cache_dir <- get_metadata_cache()
  history_file <- file.path(cache_dir, .metadata_config$FILE_SYNC_HISTORY)
  
  # Load existing history
  if (file.exists(history_file)) {
    history <- yaml::read_yaml(history_file)
  } else {
    history <- list(vintages = list())
  }
  
  # Add new entry at front (field order aligned with Python)
  entry <- list(
    vintage_date = vintage_date,
    synced_at = results$synced_at,
    dataflows = results$dataflows,
    indicators = results$indicators,
    codelists = results$codelists,
    countries = results$countries,
    regions = results$regions,
    errors = results$errors
  )
  
  history$vintages <- c(list(entry), history$vintages)
  
  # Keep only last 50 entries
  if (length(history$vintages) > 50) {
    history$vintages <- history$vintages[1:50]
  }
  
  yaml::write_yaml(history, history_file)
  invisible(history_file)
}

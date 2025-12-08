# =============================================================================
# schema_sync.R - Sync dataflow schemas from SDMX API
# =============================================================================
#
# Fetches the Data Structure Definition (DSD) for each UNICEF dataflow
# and saves the dimensions and attributes to metadata/dataflow_schemas.yaml
#
# This provides:
# - Documentation of expected columns for each dataflow
# - Validation reference for outputs
# - Consistency between Python and R packages
#
# Usage:
#   source("R/unicef_api/schema_sync.R")
#   sync_dataflow_schemas()
#
# =============================================================================

library(httr)
library(xml2)
library(yaml)
library(tibble)
library(dplyr)

# =============================================================================
# Configuration
# =============================================================================

SDMX_BASE_URL <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"

#' Get R package root directory
#'
#' Attempts to locate the root of the R package by checking for specific files
#' (get_unicef.R or DESCRIPTION) in the current directory, R/ subdirectory,
#' or parent directories.
#'
#' @return Character path to the package root.
#' @keywords internal
get_package_root <- function() {

  # Try to find R package root
  candidates <- c(
    getwd(),
    file.path(getwd(), "R"),
    dirname(sys.frame(1)$ofile %||% ".")
  )
  
  for (path in candidates) {
    if (file.exists(file.path(path, "get_unicef.R")) || file.exists(file.path(path, "unicef_api", "get_unicef.R")) || file.exists(file.path(path, "DESCRIPTION"))) {
      return(normalizePath(path))
    }
  }
  
  # Default to working directory
  normalizePath(getwd())
}

# =============================================================================
# Helper Functions
# =============================================================================

#' Fetch with retries
#' @param url URL to fetch
#' @param max_retries Number of retries
#' @return Response object or NULL
fetch_with_retry <- function(url, max_retries = 3) {
  ua <- httr::user_agent("unicefData/1.0")
  
  for (attempt in seq_len(max_retries)) {
    tryCatch({
      response <- httr::GET(url, ua, httr::timeout(120))
      
      if (httr::status_code(response) == 404) {
        return(NULL)
      }
      
      httr::stop_for_status(response)
      return(response)
      
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
# Main Functions
# =============================================================================

#' Get list of all UNICEF dataflows
#' @param max_retries Number of retries
#' @return Tibble with dataflow info
get_dataflow_list <- function(max_retries = 3) {
  url <- paste0(SDMX_BASE_URL, "/dataflow/UNICEF?references=none&detail=full")
  
  response <- fetch_with_retry(url, max_retries)
  if (is.null(response)) {
    stop("Failed to fetch dataflow list")
  }
  
  doc <- xml2::read_xml(httr::content(response, "text", encoding = "UTF-8"))
  
  # Find all Dataflow elements
  dfs <- xml2::xml_find_all(doc, ".//str:Dataflow", 
                            ns = c(str = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure"))
  
  tibble::tibble(
    id = xml2::xml_attr(dfs, "id"),
    name = xml2::xml_text(xml2::xml_find_first(dfs, ".//com:Name",
                          ns = c(com = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common"))),
    version = xml2::xml_attr(dfs, "version") %||% "1.0",
    agency = xml2::xml_attr(dfs, "agencyID") %||% "UNICEF"
  )
}

#' Get schema for a specific dataflow
#' @param dataflow_id Dataflow ID
#' @param version Dataflow version
#' @param max_retries Number of retries
#' @return List with dimensions, attributes, etc. or NULL
get_dataflow_schema <- function(dataflow_id, version = "1.0", max_retries = 3) {
  url <- sprintf("%s/dataflow/UNICEF/%s/%s?references=all", 
                 SDMX_BASE_URL, dataflow_id, version)
  
  response <- fetch_with_retry(url, max_retries)
  if (is.null(response)) {
    return(NULL)
  }
  
  doc <- xml2::read_xml(httr::content(response, "text", encoding = "UTF-8"))
  
  # Namespaces
  ns <- c(str = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure")
  
  # Extract dimensions (filter out those without id attribute)
  dims <- xml2::xml_find_all(doc, ".//str:Dimension", ns)
  
  dimensions <- lapply(dims, function(dim) {
    dim_id <- xml2::xml_attr(dim, "id")
    if (is.na(dim_id) || dim_id == "") return(NULL)  # Skip invalid dimensions
    
    codelist_ref <- xml2::xml_find_first(dim, ".//str:Enumeration/Ref", ns)
    list(
      id = dim_id,
      position = as.integer(xml2::xml_attr(dim, "position")),
      codelist = if (!is.na(xml2::xml_attr(codelist_ref, "id"))) 
                   xml2::xml_attr(codelist_ref, "id") else NULL
    )
  })
  
  # Remove NULL entries (invalid dimensions)
  dimensions <- Filter(Negate(is.null), dimensions)
  
  # Sort by position
  positions <- sapply(dimensions, function(d) d$position %||% 999L)
  dimensions <- dimensions[order(positions)]
  
  # Extract time dimension
  time_dim <- xml2::xml_find_first(doc, ".//str:TimeDimension", ns)
  time_dimension <- if (!is.na(xml2::xml_attr(time_dim, "id"))) 
                      xml2::xml_attr(time_dim, "id") else "TIME_PERIOD"
  
  # Extract attributes
  attrs <- xml2::xml_find_all(doc, ".//str:Attribute", ns)
  
  attributes <- lapply(attrs, function(attr) {
    codelist_ref <- xml2::xml_find_first(attr, ".//str:Enumeration/Ref", ns)
    list(
      id = xml2::xml_attr(attr, "id"),
      codelist = if (!is.na(xml2::xml_attr(codelist_ref, "id"))) 
                   xml2::xml_attr(codelist_ref, "id") else NULL
    )
  })
  
  # Extract primary measure
  primary <- xml2::xml_find_first(doc, ".//str:PrimaryMeasure", ns)
  primary_measure <- if (!is.na(xml2::xml_attr(primary, "id"))) 
                       xml2::xml_attr(primary, "id") else "OBS_VALUE"
  
  list(
    dimensions = dimensions,
    time_dimension = time_dimension,
    primary_measure = primary_measure,
    attributes = attributes
  )
}

#' Get sample data from a dataflow to extract values
#' @param dataflow_id Dataflow ID
#' @param max_rows Maximum rows to fetch
#' @param max_retries Number of retries
#' @param exhaustive_cols Columns to extract ALL values for
#' @return Named list mapping column names to value statistics
get_sample_data <- function(dataflow_id, max_rows = 10000, max_retries = 3,
                            exhaustive_cols = NULL) {
  
  if (is.null(exhaustive_cols)) {
    exhaustive_cols <- c('INDICATOR', 'SEX', 'AGE', 'WEALTH_QUINTILE', 
                         'RESIDENCE', 'MATERNAL_EDU_LVL', 'UNIT_MEASURE')
  }
  
  known_numeric_cols <- c('OBS_VALUE', 'LOWER_BOUND', 'UPPER_BOUND', 
                          'WGTD_SAMPL_SIZE', 'STD_ERR', 'TIME_PERIOD')

  url <- sprintf(
    "%s/data/UNICEF,%s,1.0/?format=csv&startPeriod=2020",
    SDMX_BASE_URL, dataflow_id
  )
  
  response <- fetch_with_retry(url, max_retries)
  if (is.null(response)) {
    return(NULL)
  }
  
  tryCatch({
    # Parse CSV
    content <- httr::content(response, "text", encoding = "UTF-8")
    df <- utils::read.csv(text = content, stringsAsFactors = FALSE, nrows = max_rows)
    
    # Process each column
    result <- lapply(names(df), function(col) {
      vals <- df[[col]]
      # Remove empty values and NAs
      vals <- vals[!is.na(vals) & vals != "" & vals != ".." & vals != "nan" & vals != "NA"]
      
      total_unique <- length(unique(vals))
      
      if (length(vals) == 0) {
        return(list(
          type = "categorical",
          values = list(),
          total_count = 0,
          is_exhaustive = TRUE
        ))
      }
      
      # Determine if numeric
      is_numeric <- FALSE
      numeric_vals <- numeric(0)
      
      # 1. Check if known numeric column
      if (col %in% known_numeric_cols) {
        is_numeric <- TRUE
        # Force conversion, suppressing warnings for non-numeric values
        numeric_vals <- suppressWarnings(as.numeric(vals))
        numeric_vals <- numeric_vals[!is.na(numeric_vals)]
      } else if (!(col %in% exhaustive_cols)) {
        # 2. Try parsing if not exhaustive col
        parsed <- suppressWarnings(as.numeric(vals))
        if (sum(is.na(parsed)) == 0) { # All values parsed successfully
          is_numeric <- TRUE
          numeric_vals <- parsed
        }
      }
      
      if (is_numeric && length(numeric_vals) > 0) {
        # Numerical handling
        list(
          type = "numerical",
          min = min(numeric_vals),
          max = max(numeric_vals),
          total_count = total_unique
        )
      } else {
        # Categorical handling
        is_exhaustive_col <- col %in% exhaustive_cols
        
        if (is_exhaustive_col) {
          # Get ALL values, sorted
          values <- sort(unique(vals))
          is_exhaustive <- TRUE
        } else {
          # Get top 10 most frequent
          freq_table <- sort(table(vals), decreasing = TRUE)
          values <- head(names(freq_table), 10)
          is_exhaustive <- total_unique <= 10
        }
        
        list(
          type = "categorical",
          values = as.list(values),
          total_count = total_unique,
          is_exhaustive = is_exhaustive
        )
      }
    })
    
    names(result) <- names(df)
    result
    
  }, error = function(e) {
    warning(sprintf("Failed to parse sample data for %s: %s", dataflow_id, e$message))
    NULL
  })
}

#' Sync dataflow schemas from SDMX API to YAML file
#' 
#' @param output_dir Directory to save schemas (default: ../metadata/current)
#' @param verbose Print progress messages
#' @param dataflows Character vector of specific dataflow IDs to sync (default: all)
#' @param include_sample_values Fetch sample data and include top 10 most frequent values per column
#' @return List with sync results
#' @export
sync_dataflow_schemas <- function(output_dir = NULL, verbose = TRUE, dataflows = NULL, 
                                   include_sample_values = TRUE) {
  
  if (is.null(output_dir)) {
    # Default to R/metadata/current
    pkg_root <- get_package_root()
    
    # Check if pkg_root is the R directory or the project root
    if (file.exists(file.path(pkg_root, "get_unicef.R")) || file.exists(file.path(pkg_root, "unicef_api", "get_unicef.R"))) {
      # It is the R directory
      output_dir <- file.path(pkg_root, "metadata", "current")
    } else {
      # It is likely the project root
      output_dir <- file.path(pkg_root, "R", "metadata", "current")
    }
  }
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Get list of dataflows
  if (verbose) message("Fetching dataflow list...")
  
  all_dataflows <- get_dataflow_list()
  
  if (!is.null(dataflows)) {
    all_dataflows <- all_dataflows %>% dplyr::filter(id %in% dataflows)
  }
  
  if (verbose) message(sprintf("Found %d dataflows to process", nrow(all_dataflows)))
  
  # Fetch schema for each dataflow
  index_entries <- list()
  success_count <- 0
  fail_count <- 0
  
  # Create dataflows subdirectory
  dataflows_dir <- file.path(output_dir, "dataflows")
  if (!dir.exists(dataflows_dir)) {
    dir.create(dataflows_dir, recursive = TRUE)
  }
  
  for (i in seq_len(nrow(all_dataflows))) {
    df_row <- all_dataflows[i, ]
    df_id <- df_row$id
    df_version <- df_row$version %||% "1.0"
    
    if (verbose) {
      # Use message() for immediate stderr output (unbuffered)
      message(sprintf("  [%d/%d] Fetching schema for %s... ", 
                  i, nrow(all_dataflows), df_id), appendLF = FALSE)
    }
    
    schema <- get_dataflow_schema(df_id, df_version)
    
    if (!is.null(schema)) {
      schema_entry <- list(
        id = df_id,
        name = df_row$name,
        version = df_version,
        agency = df_row$agency %||% "UNICEF",
        synced_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        dimensions = schema$dimensions,
        time_dimension = schema$time_dimension,
        primary_measure = schema$primary_measure,
        attributes = schema$attributes
      )
      
      # Fetch sample values if requested
      if (include_sample_values) {
        if (verbose) {
          message("fetching samples... ", appendLF = FALSE)
        }
        sample_data <- get_sample_data(df_id)
        
        if (!is.null(sample_data)) {
          # Add sample info to each dimension
          for (j in seq_along(schema_entry$dimensions)) {
            dim_id <- schema_entry$dimensions[[j]]$id
            if (dim_id %in% names(sample_data)) {
              info <- sample_data[[dim_id]]
              if (info$type == "numerical") {
                schema_entry$dimensions[[j]]$values_min <- info$min
                schema_entry$dimensions[[j]]$values_max <- info$max
              } else {
                schema_entry$dimensions[[j]]$values <- info$values
                schema_entry$dimensions[[j]]$is_exhaustive <- info$is_exhaustive
              }
              schema_entry$dimensions[[j]]$total_values_count <- info$total_count
            }
          }
          
          # Add sample info to each attribute
          for (j in seq_along(schema_entry$attributes)) {
            attr_id <- schema_entry$attributes[[j]]$id
            if (attr_id %in% names(sample_data)) {
              info <- sample_data[[attr_id]]
              if (info$type == "numerical") {
                schema_entry$attributes[[j]]$values_min <- info$min
                schema_entry$attributes[[j]]$values_max <- info$max
              } else {
                schema_entry$attributes[[j]]$values <- info$values
                schema_entry$attributes[[j]]$is_exhaustive <- info$is_exhaustive
              }
              schema_entry$attributes[[j]]$total_values_count <- info$total_count
            }
          }
          
          # Add sample info to primary measure
          pm_id <- schema_entry$primary_measure
          if (pm_id %in% names(sample_data)) {
            schema_entry$primary_measure_summary <- sample_data[[pm_id]]
          }
          
          # Add sample info to time dimension
          time_id <- schema_entry$time_dimension
          if (time_id %in% names(sample_data)) {
            schema_entry$time_dimension_summary <- sample_data[[time_id]]
          }
        }
      }
      
      # Save individual dataflow schema
      df_path <- file.path(dataflows_dir, sprintf("%s.yaml", df_id))
      yaml::write_yaml(schema_entry, df_path)
      
      # Add to index
      index_entries[[length(index_entries) + 1]] <- list(
        id = df_id,
        name = df_row$name,
        version = df_version,
        dimensions_count = length(schema$dimensions),
        attributes_count = length(schema$attributes)
      )
      
      success_count <- success_count + 1
      if (verbose) {
        message(sprintf("OK (%d dims, %d attrs)", 
                    length(schema$dimensions), length(schema$attributes)))
      }
    } else {
      fail_count <- fail_count + 1
      if (verbose) message("FAILED")
    }
    
    # Small delay to avoid rate limiting
    Sys.sleep(0.2)
  }
  
  # Save index file
  index <- list(
    metadata_version = "1.0",
    synced_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    source = "SDMX API Data Structure Definitions",
    agency = "UNICEF",
    total_dataflows = length(index_entries),
    dataflows = index_entries
  )
  
  index_path <- file.path(output_dir, "dataflow_index.yaml")
  yaml::write_yaml(index, index_path)
  
  if (verbose) {
    message(sprintf("\nSaved %d schemas to %s/", success_count, dataflows_dir))
    message(sprintf("Index saved to %s", index_path))
    if (fail_count > 0) {
      message(sprintf("  (%d dataflows failed)", fail_count))
    }
  }
  
  list(
    success = success_count,
    failed = fail_count,
    output_dir = dataflows_dir,
    index_path = index_path
  )
}

#' Load schema for a specific dataflow from cached YAML
#' 
#' @param dataflow_id Dataflow ID (e.g., 'CME', 'NUTRITION')
#' @param metadata_dir Directory containing dataflows/ subdirectory
#' @return Schema list or NULL if not found
#' @export
load_dataflow_schema <- function(dataflow_id, metadata_dir = NULL) {
  if (is.null(metadata_dir)) {
    # Default to R/metadata/current
    pkg_root <- get_package_root()
    
    # Check if pkg_root is the R directory or the project root
    if (file.exists(file.path(pkg_root, "get_unicef.R"))) {
      # It is the R directory
      metadata_dir <- file.path(pkg_root, "metadata", "current")
    } else {
      # It is likely the project root
      metadata_dir <- file.path(pkg_root, "R", "metadata", "current")
    }
  }
  
  # Look for individual dataflow file
  schema_path <- file.path(metadata_dir, "dataflows", sprintf("%s.yaml", dataflow_id))
  
  if (!file.exists(schema_path)) {
    return(NULL)
  }
  
  yaml::read_yaml(schema_path)
}

#' Get list of expected column names for a dataflow
#' 
#' @param dataflow_id Dataflow ID (e.g., 'CME', 'NUTRITION')
#' @param metadata_dir Directory containing dataflow_schemas.yaml
#' @return Character vector of column names (dimensions + time + attributes)
#' @export
get_expected_columns <- function(dataflow_id, metadata_dir = NULL) {
  schema <- load_dataflow_schema(dataflow_id, metadata_dir)
  
  if (is.null(schema)) {
    return(character(0))
  }
  
  columns <- character(0)
  
  # Add dimensions
  for (dim in schema$dimensions) {
    columns <- c(columns, dim$id)
  }
  
  # Add time dimension
  time_dim <- schema$time_dimension %||% "TIME_PERIOD"
  if (!time_dim %in% columns) {
    columns <- c(columns, time_dim)
  }
  
  # Add primary measure
  primary <- schema$primary_measure %||% "OBS_VALUE"
  columns <- c(columns, primary)
  
  # Add attributes
  for (attr in schema$attributes) {
    columns <- c(columns, attr$id)
  }
  
  columns
}

# =============================================================================
# Run if executed directly
# =============================================================================

if (sys.nframe() == 0) {
  # Running as script
  args <- commandArgs(trailingOnly = TRUE)
  
  dataflows <- if (length(args) > 0) args else NULL
  
  if (!is.null(dataflows)) {
    message(sprintf("Syncing specific dataflows: %s", paste(dataflows, collapse = ", ")))
  }
  
  result <- sync_dataflow_schemas(dataflows = dataflows)
  message(sprintf("\nDone! %d schemas synced.", result$success))
}

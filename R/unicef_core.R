# =============================================================================
# unicef_core.R - Core composable functions for UNICEF API
# =============================================================================

#' @import dplyr
#' @importFrom magrittr %>%
NULL

# Ensure required packages are loaded
if (!requireNamespace("magrittr", quietly = TRUE)) stop("Package 'magrittr' required")
if (!requireNamespace("dplyr", quietly = TRUE)) stop("Package 'dplyr' required")
if (!requireNamespace("httr", quietly = TRUE)) stop("Package 'httr' required")
if (!requireNamespace("readr", quietly = TRUE)) stop("Package 'readr' required")

`%>%` <- magrittr::`%>%`

# --- Helper: Fetch SDMX ---

#' Fetch SDMX content as text
#'
#' @param url URL to fetch
#' @param ua User agent string
#' @param retry Number of retries
#' @return Content as text
#' @keywords internal
fetch_sdmx_text <- function(url, ua, retry) {
  resp <- httr::RETRY("GET", url, ua, times = retry, pause_base = 1)
  httr::stop_for_status(resp)
  httr::content(resp, as = "text", encoding = "UTF-8")
}

#' @title Detect Dataflow from Indicator
#' @description Auto-detects the correct dataflow for a given indicator code.
#' @param indicator Indicator code (e.g. "CME_MRY0T4")
#' @return Character string of dataflow ID
#' @export
detect_dataflow <- function(indicator) {
  if (is.null(indicator)) return(NULL)
  
  # 1. Try registry if available
  if (exists("get_dataflow_for_indicator", mode = "function")) {
    return(get_dataflow_for_indicator(indicator))
  }
  
  # 2. Check known overrides
  indicator_overrides <- list(
    "PT_F_20-24_MRD_U18_TND" = "PT_CM", "PT_F_20-24_MRD_U15" = "PT_CM",
    "PT_F_15-49_FGM" = "PT_FGM", "PT_F_0-14_FGM" = "PT_FGM",
    "PT_F_15-19_FGM_TND" = "PT_FGM", "PT_F_15-49_FGM_TND" = "PT_FGM",
    "PT_F_15-49_FGM_ELIM" = "PT_FGM",
    "ED_CR_L1_UIS_MOD" = "EDUCATION_UIS_SDG", "ED_CR_L2_UIS_MOD" = "EDUCATION_UIS_SDG",
    "ED_CR_L3_UIS_MOD" = "EDUCATION_UIS_SDG", "ED_ROFST_L1_UIS_MOD" = "EDUCATION_UIS_SDG",
    "ED_ROFST_L2_UIS_MOD" = "EDUCATION_UIS_SDG", "ED_ROFST_L3_UIS_MOD" = "EDUCATION_UIS_SDG",
    "ED_ANAR_L02" = "EDUCATION_UIS_SDG", "ED_MAT_G23" = "EDUCATION_UIS_SDG",
    "ED_MAT_L1" = "EDUCATION_UIS_SDG", "ED_MAT_L2" = "EDUCATION_UIS_SDG",
    "ED_READ_G23" = "EDUCATION_UIS_SDG", "ED_READ_L1" = "EDUCATION_UIS_SDG",
    "ED_READ_L2" = "EDUCATION_UIS_SDG",
    "PV_CHLD_DPRV-S-L1-HS" = "CHLD_PVTY"
  )
  
  if (indicator %in% names(indicator_overrides)) {
    return(indicator_overrides[[indicator]])
  }
  
  # 3. Infer from prefix
  parts <- strsplit(indicator, "_")[[1]]
  prefix <- parts[1]
  
  prefix_map <- list(
    CME = "CME", NT = "NUTRITION", IM = "IMMUNISATION", ED = "EDUCATION",
    WS = "WASH_HOUSEHOLDS", HVA = "HIV_AIDS", MNCH = "MNCH", PT = "PT",
    ECD = "ECD", PV = "CHLD_PVTY"
  )
  
  if (prefix %in% names(prefix_map)) {
    return(prefix_map[[prefix]])
  }
  
  return("GLOBAL_DATAFLOW")
}

#' @title Fetch Raw UNICEF Data
#' @description Low-level fetcher for UNICEF SDMX API.
#' @export
get_unicef_raw <- function(
    indicator = NULL,
    dataflow = NULL,
    countries = NULL,
    start_year = NULL,
    end_year = NULL,
    max_retries = 3,
    version = NULL,
    page_size = 100000,
    verbose = TRUE
) {
  # Validate inputs
  if (is.null(dataflow) && is.null(indicator)) {
    stop("Either 'indicator' or 'dataflow' must be specified.")
  }
  
  # Auto-detect dataflow if missing
  if (is.null(dataflow)) {
    dataflow <- detect_dataflow(indicator[1])
    if (verbose) message(sprintf("Auto-detected dataflow '%s'", dataflow))
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
  
  # Build URL
  base <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
  indicator_str <- if (!is.null(indicator)) paste0(".", paste(indicator, collapse = "+"), ".") else "."
  rel_path <- sprintf("data/UNICEF,%s,%s/%s", dataflow, ver, indicator_str)
  full_url <- paste0(base, "/", rel_path, "?format=csv&labels=both")
  
  if (!is.null(start_year_str)) full_url <- paste0(full_url, "&startPeriod=", start_year_str)
  if (!is.null(end_year_str)) full_url <- paste0(full_url, "&endPeriod=", end_year_str)
  
  # Paging
  ua <- httr::user_agent("get_unicef/1.0")
  pages <- list()
  page <- 0L
  
  repeat {
    page_url <- paste0(full_url, "&startIndex=", page * page_size, "&count=", page_size)
    if (verbose) message(sprintf("Fetching page %d...", page + 1))
    
    df <- tryCatch(
      readr::read_csv(fetch_sdmx_text(page_url, ua, max_retries), show_col_types = FALSE),
      error = function(e) NULL
    )
    
    if (is.null(df) || nrow(df) == 0) break
    pages[[length(pages) + 1L]] <- df
    if (nrow(df) < page_size) break
    page <- page + 1L
    Sys.sleep(0.2)
  }
  
  df_all <- dplyr::bind_rows(pages)
  
  # Filter countries
  if (!is.null(countries) && nrow(df_all) > 0 && "REF_AREA" %in% names(df_all)) {
    df_all <- df_all %>% dplyr::filter(REF_AREA %in% countries)
  }
  
  return(df_all)
}

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

#' @title Clean and Standardize UNICEF Data
#' @description Renames columns and converts types.
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
  
  # Add geo_type (country vs aggregate)
  if ("iso3" %in% names(df_clean)) {
    valid_iso3 <- countrycode::codelist$iso3c
    df_clean <- df_clean %>%
      dplyr::mutate(
        geo_type = dplyr::if_else(iso3 %in% valid_iso3, "country", "aggregate")
      )
  }
  
  return(df_clean)
}

#' @title Filter UNICEF Data (Sex, Age, Wealth, etc.)
#' @description Filters data to specific disaggregations or defaults to totals.
#' @export
filter_unicef_data <- function(df, sex = NULL, age = NULL, wealth = NULL, residence = NULL, maternal_edu = NULL, verbose = TRUE) {
  if (nrow(df) == 0) return(df)
  
  available_disaggregations <- c()
  applied_filters <- c()
  
  # Filter by sex (default is "_T" for total)
  if ("SEX" %in% names(df)) {
    sex_values <- unique(na.omit(df$SEX))
    if (length(sex_values) > 1 || (length(sex_values) == 1 && sex_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations, 
                                     paste0("sex: ", paste(sex_values, collapse = ", ")))
    }
    if (!is.null(sex) && sex != "ALL") {
      df <- df %>% dplyr::filter(SEX == sex)
      applied_filters <- c(applied_filters, paste0("sex: ", sex))
    }
  }
  
  # Filter by age (default: keep only total age groups)
  if ("AGE" %in% names(df)) {
    age_values <- unique(na.omit(df$AGE))
    if (length(age_values) > 1) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("age: ", paste(age_values, collapse = ", ")))
      if (is.null(age)) {
        # Keep only total age groups
        total_ages <- c("_T", "Y0T4", "Y0T14", "Y0T17", "Y15T49", "ALLAGE")
        age_totals <- intersect(total_ages, age_values)
        if (length(age_totals) > 0) {
          df <- df %>% dplyr::filter(AGE %in% age_totals)
          applied_filters <- c(applied_filters, paste0("age: ", paste(age_totals, collapse = ", "), " (Default)"))
        }
      } else if (age != "ALL") {
        df <- df %>% dplyr::filter(AGE == age)
        applied_filters <- c(applied_filters, paste0("age: ", age))
      }
    }
  }
  
  # Filter by wealth quintile (default: total)
  if ("WEALTH_QUINTILE" %in% names(df)) {
    wq_values <- unique(na.omit(df$WEALTH_QUINTILE))
    if (length(wq_values) > 1 || (length(wq_values) == 1 && wq_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("wealth_quintile: ", paste(wq_values, collapse = ", ")))
    }
    if (is.null(wealth) && "_T" %in% wq_values) {
      df <- df %>% dplyr::filter(WEALTH_QUINTILE == "_T")
      applied_filters <- c(applied_filters, "wealth_quintile: _T (Default)")
    } else if (!is.null(wealth) && wealth != "ALL") {
      df <- df %>% dplyr::filter(WEALTH_QUINTILE == wealth)
      applied_filters <- c(applied_filters, paste0("wealth_quintile: ", wealth))
    }
  }
  
  # Filter by residence (default: total)
  if ("RESIDENCE" %in% names(df)) {
    res_values <- unique(na.omit(df$RESIDENCE))
    if (length(res_values) > 1 || (length(res_values) == 1 && res_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("residence: ", paste(res_values, collapse = ", ")))
    }
    if (is.null(residence) && "_T" %in% res_values) {
      df <- df %>% dplyr::filter(RESIDENCE == "_T")
      applied_filters <- c(applied_filters, "residence: _T (Default)")
    } else if (!is.null(residence) && residence != "ALL") {
      df <- df %>% dplyr::filter(RESIDENCE == residence)
      applied_filters <- c(applied_filters, paste0("residence: ", residence))
    }
  }
  
  # Filter by maternal education level (default: total)
  if ("MATERNAL_EDU_LVL" %in% names(df)) {
    edu_values <- unique(na.omit(df$MATERNAL_EDU_LVL))
    if (length(edu_values) > 1 || (length(edu_values) == 1 && edu_values[1] != "_T")) {
      available_disaggregations <- c(available_disaggregations,
                                     paste0("maternal_edu_lvl: ", paste(edu_values, collapse = ", ")))
    }
    if (is.null(maternal_edu) && "_T" %in% edu_values) {
      df <- df %>% dplyr::filter(MATERNAL_EDU_LVL == "_T")
      applied_filters <- c(applied_filters, "maternal_edu_lvl: _T (Default)")
    } else if (!is.null(maternal_edu) && maternal_edu != "ALL") {
      df <- df %>% dplyr::filter(MATERNAL_EDU_LVL == maternal_edu)
      applied_filters <- c(applied_filters, paste0("maternal_edu_lvl: ", maternal_edu))
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
  }
  
  return(df)
}

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

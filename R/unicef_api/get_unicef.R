# Load required packages for pipe operator
#' @import dplyr
#' @importFrom magrittr %>%
NULL

# Ensure required packages are loaded when sourcing directly
if (!requireNamespace("magrittr", quietly = TRUE)) {
  stop("Package 'magrittr' is required. Install with: install.packages('magrittr')")
}
if (!requireNamespace("dplyr", quietly = TRUE)) {
  stop("Package 'dplyr' is required. Install with: install.packages('dplyr')")
}
if (!requireNamespace("purrr", quietly = TRUE)) {
  stop("Package 'purrr' is required. Install with: install.packages('purrr')")
}
if (!requireNamespace("httr", quietly = TRUE)) {
  stop("Package 'httr' is required. Install with: install.packages('httr')")
}

# Import pipe operator for direct sourcing
`%>%` <- magrittr::`%>%`

# Null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Source core functions
if (!exists("get_unicef_raw", mode = "function")) {
  script_file <- sys.frame(1)$ofile
  script_dir <- if (is.null(script_file)) "." else dirname(script_file)
  core_path <- file.path(script_dir, "unicef_core.R")
  if (file.exists(core_path)) {
    source(core_path, local = FALSE)
  } else {
    warning("unicef_core.R not found. Some functionality may be missing.")
  }
}

# Internal helper to perform HTTP GET and return text
#' Fetch SDMX content from URL
#'
#' @param url URL to fetch
#' @param ua User agent string
#' @param retry Number of retries
#' @return Content as text
#' @keywords internal
fetch_sdmx <- function(url, ua, retry) {
  resp <- httr::RETRY("GET", url, ua, times = retry, pause_base = 1)
  httr::stop_for_status(resp)
  httr::content(resp, as = "text", encoding = "UTF-8")
}

#' @title List available UNICEF SDMX “flows”
#' @description
#' Download and cache the SDMX data-flow definitions from UNICEF’s REST endpoint.
#' @return A tibble with columns \code{id}, \code{agency}, and \code{version}
#' @export
list_unicef_flows <- memoise::memoise(
  function(cache_dir = tools::R_user_dir("get_unicef","cache"), retry = 3) {
    ua <- httr::user_agent("get_unicef/1.0 (+https://github.com/jpazvd/get_unicef)")
    url <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF?references=none&detail=full"
    xml_text <- fetch_sdmx(url, ua, retry)
    doc <- xml2::read_xml(xml_text)
    # Use namespace-aware XPath
    ns <- xml2::xml_ns(doc)
    dfs <- xml2::xml_find_all(doc, ".//str:Dataflow", ns)
    tibble::tibble(
      id      = xml2::xml_attr(dfs, "id"),
      agency  = xml2::xml_attr(dfs, "agencyID"),
      version = xml2::xml_attr(dfs, "version"),
      name    = xml2::xml_text(xml2::xml_find_first(dfs, "./com:Name[@xml:lang='en']", ns))
    )
  }
)

#' @title List SDMX codelist for a given flow + dimension
#' @param flow character flow ID, e.g. "NUTRITION"
#' @param dimension character dimension ID within that flow, e.g. "INDICATOR"
#' @return A tibble with columns \code{code} and \code{description}
#' @export
list_unicef_codelist <- memoise::memoise(
  function(flow, dimension, cache_dir = tools::R_user_dir("get_unicef","cache"), retry = 3) {
    stopifnot(is.character(flow), is.character(dimension), length(flow) == 1, length(dimension) == 1)
    ua <- httr::user_agent("get_unicef/1.0 (+https://github.com/jpazvd/get_unicef)")
    url <- sprintf(
      "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/structure/codelist/UNICEF.%s.%s?references=none&detail=full",
      flow, dimension
    )
    xml_text <- fetch_sdmx(url, ua, retry)
    doc <- xml2::read_xml(xml_text)
    codes <- xml2::xml_find_all(doc, ".//Code")
    tibble::tibble(
      code        = xml2::xml_attr(codes, "value"),
      description = xml2::xml_text(xml2::xml_find_first(codes, "./Description"))
    )
  }
)

#' @title Fetch UNICEF SDMX data or structure
#' @description
#' Download UNICEF indicator data from the SDMX data warehouse.
#' Supports automatic paging, retrying on transient failure, memoisation, and tidy-up.
#' 
#' This function uses unified parameter names consistent with the Python package.
#'
#' @section Time Period Handling:
#' The UNICEF SDMX API returns TIME_PERIOD values in various formats (annual "2020" 
#' or monthly "2020-03"). This function automatically converts monthly periods to 
#' decimal years for consistent time-series analysis:
#' \itemize{
#'   \item "2020" becomes 2020.0 (integer year)
#'   \item "2020-01" becomes 2020.0833 (2020 + 1/12, January)
#'   \item "2020-06" becomes 2020.5000 (2020 + 6/12, June)
#'   \item "2020-11" becomes 2020.9167 (2020 + 11/12, November)
#' }
#' Formula: decimal_year = year + month/12
#'
#' @param indicator Character vector of indicator codes (e.g., "CME_MRY0T4").
#'   Previously called 'key'. Both parameter names are supported.
#' @param dataflow Character vector of dataflow IDs (e.g., "CME", "NUTRITION").
#'   Previously called 'flow'. Both parameter names are supported.
#' @param countries Character vector of ISO3 country codes (e.g., c("ALB", "USA")).
#'   If NULL (default), fetches all countries.
#' @param start_year Optional starting year (e.g., 2015).
#'   Previously called 'start_period'. Both parameter names are supported.
#' @param end_year Optional ending year (e.g., 2023).
#'   Previously called 'end_period'. Both parameter names are supported.
#' @param sex Sex disaggregation: "_T" (total, default), "F" (female), "M" (male).
#' @param age Filter by age group. Default is NULL (keeps totals).
#' @param wealth Filter by wealth quintile. Default is NULL (keeps totals).
#' @param residence Filter by residence (e.g. "URBAN", "RURAL"). Default is NULL (keeps totals).
#' @param maternal_edu Filter by maternal education. Default is NULL (keeps totals).
#' @param tidy Logical; if TRUE (default), returns cleaned tibble with standardized column names.
#' @param country_names Logical; if TRUE (default), adds country name column.
#' @param max_retries Number of retry attempts on failure (default: 3).
#'   Previously called 'retry'. Both parameter names are supported.
#' @param cache Logical; if TRUE, memoises results.
#' @param page_size Integer rows per page (default: 100000).
#' @param detail "data" (default) or "structure" for metadata.
#' @param version Optional SDMX version; if NULL, auto-detected.
#' @param format Output format: "long" (default), "wide" (years as columns), 
#'   "wide_indicators" (indicators as columns), or wide by dimension:
#'   "wide_sex", "wide_age", "wide_wealth", "wide_residence", "wide_maternal_edu".
#' @param latest Logical; if TRUE, keep only the most recent non-missing value per country.
#'   The year may differ by country. Useful for cross-sectional analysis.
#' @param add_metadata Character vector of metadata to add: "region", "income_group", 
#'   "continent", "indicator_name", "indicator_category".
#' @param dropna Logical; if TRUE, remove rows with missing values.
#' @param simplify Logical; if TRUE, keep only essential columns.
#' @param mrv Integer; keep only the N most recent values per country (Most Recent Values).
#' @param raw Logical; if TRUE, return raw SDMX data without column standardization.
#'   Default is FALSE (clean, standardized output matching Python package).
#' @param ignore_duplicates Logical; if FALSE (default), raises an error when exact
#'   duplicate rows are found (all column values identical). Set to TRUE to allow 
#'   automatic removal of duplicates.
#' @param flow Deprecated. Use 'dataflow' instead.
#' @param key Deprecated. Use 'indicator' instead.
#' @param start_period Deprecated. Use 'start_year' instead.
#' @param end_period Deprecated. Use 'end_year' instead.
#' @param retry Deprecated. Use 'max_retries' instead.
#' @return Tibble with indicator data, or xml_document if detail="structure".
#'   The 'period' column contains decimal years (see Time Period Handling section).
#' 
#' @examples
#' \dontrun{
#' # Fetch under-5 mortality for specific countries (clean output)
#' df <- get_unicef(
#'   indicator = "CME_MRY0T4",
#'   countries = c("ALB", "USA", "BRA"),
#'   start_year = 2015,
#'   end_year = 2023
#' )
#' 
#' # Get raw SDMX data with all original columns
#' df_raw <- get_unicef(
#'   indicator = "CME_MRY0T4",
#'   countries = c("ALB", "USA"),
#'   raw = TRUE
#' )
#' 
#' # Get latest value per country (cross-sectional)
#' df <- get_unicef(
#'   indicator = "CME_MRY0T4",
#'   latest = TRUE
#' )
#' 
#' # Wide format with region metadata
#' df <- get_unicef(
#'   indicator = "CME_MRY0T4",
#'   format = "wide",
#'   add_metadata = c("region", "income_group")
#' )
#' 
#' # Multiple indicators merged automatically
#' df <- get_unicef(
#'   indicator = c("CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"),
#'   format = "wide_indicators",
#'   latest = TRUE
#' )
#' 
#' # Legacy syntax (still supported)
#' df <- get_unicef(flow = "CME", key = "CME_MRY0T4")
#' }
#' @export
get_unicef <- function(
    # New unified parameter names
    indicator     = NULL,
    dataflow      = NULL,
    countries     = NULL,
    start_year    = NULL,
    end_year      = NULL,
    sex           = "_T",
    age           = NULL,
    wealth        = NULL,
    residence     = NULL,
    maternal_edu  = NULL,
    tidy          = TRUE,
    country_names = TRUE,
    max_retries   = 3,
    cache         = FALSE,
    page_size     = 100000,
    detail        = c("data", "structure"),
    version       = NULL,
    # NEW: Post-production options
    format        = c("long", "wide", "wide_indicators", "wide_sex", "wide_age", "wide_wealth", "wide_residence", "wide_maternal_edu"),
    latest        = FALSE,
    add_metadata  = NULL,
    dropna        = FALSE,
    simplify      = FALSE,
    mrv           = NULL,
    raw           = FALSE,
    ignore_duplicates = FALSE,
    # Legacy parameter names (deprecated but supported)
    flow          = NULL,
    key           = NULL,
    start_period  = NULL,
    end_period    = NULL,
    retry         = NULL
) {
  # Handle legacy parameter names with deprecation warnings
  if (!is.null(flow) && is.null(dataflow)) {
    dataflow <- flow
  }
  if (!is.null(key) && is.null(indicator)) {
    indicator <- key
  }
  if (!is.null(start_period) && is.null(start_year)) {
    start_year <- start_period
  }
  if (!is.null(end_period) && is.null(end_year)) {
    end_year <- end_period
  }
  if (!is.null(retry) && max_retries == 3) {
    max_retries <- retry
  }
  
  format <- match.arg(format)
  detail <- match.arg(detail)

  # Auto-adjust filters for wide formats
  if (format == "wide_sex") sex <- "ALL"
  if (format == "wide_age") age <- "ALL"
  if (format == "wide_wealth") wealth <- "ALL"
  if (format == "wide_residence") residence <- "ALL"
  if (format == "wide_maternal_edu") maternal_edu <- "ALL"
  
  # Handle structure request
  if (detail == "structure") {
    if (is.null(dataflow)) stop("Dataflow must be specified for structure request.")
    # Use legacy fetch_sdmx for structure as get_unicef_raw is for data
    ua <- httr::user_agent("get_unicef/1.0")
    base <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    url <- sprintf("%s/structure/dataflow/UNICEF.%s?references=all&detail=full", base, dataflow[1])
    return(xml2::read_xml(fetch_sdmx(url, ua, max_retries)))
  }
  
  # 1. Fetch Raw Data
  # Use memoise if cache=TRUE
  fetcher <- if (cache) memoise::memoise(get_unicef_raw) else get_unicef_raw
  
  # Handle multiple dataflows if provided, otherwise auto-detect inside get_unicef_raw
  # But get_unicef_raw takes single dataflow usually, or auto-detects from indicator.
  # If multiple dataflows provided, we need to loop.
  
  if (!is.null(dataflow) && length(dataflow) > 1) {
    result <- purrr::map_dfr(dataflow, function(df_id) {
      fetcher(
        indicator = indicator,
        dataflow = df_id,
        countries = countries,
        start_year = start_year,
        end_year = end_year,
        max_retries = max_retries,
        version = version,
        page_size = page_size,
        verbose = FALSE
      )
    })
  } else {
    message("")
    result <- fetcher(
      indicator = indicator,
      dataflow = if (!is.null(dataflow)) dataflow[1] else NULL,
      countries = countries,
      start_year = start_year,
      end_year = end_year,
      max_retries = max_retries,
      version = version,
      page_size = page_size,
      verbose = TRUE
    )
  }
  
  if (is.null(result) || nrow(result) == 0) return(result)
  
  # 2. Filter Data (Sex, Age, Wealth, etc.)
  # Only apply if not raw, or if user explicitly asked for filters?
  # Original behavior: always filtered to totals unless specified.
  # We should apply filter_unicef_data unless raw=TRUE AND user didn't specify filters?
  # Actually, raw usually means "give me everything as is".
  # But if user specified sex="F", they expect filtering even in raw mode?
  # Let's apply filtering if not raw OR if specific filters are provided.
  
  # Check if filters are default
  is_default_filters <- (sex == "_T") # Add others if they were params
  
  if (!raw || !is_default_filters) {
    result <- filter_unicef_data(result, sex = sex, age = age, wealth = wealth, residence = residence, maternal_edu = maternal_edu)
  }

  # Add spacing after logs for single dataflow (verbose mode)
  if (is.null(dataflow) || length(dataflow) <= 1) {
    message("")
  }
  
  # 3. Clean/Tidy Data
  if (tidy && !raw) {
    result <- clean_unicef_data(result)
    
    # Validate Schema
    if (!is.null(dataflow)) {
      # We might have multiple dataflows, just validate against the first one
      if (exists("validate_unicef_schema", mode = "function")) {
         result <- validate_unicef_schema(result, dataflow[1])
      }
    }
  } else if (raw) {
    # Minimal processing for raw (rename core cols)
     result <- result %>%
        dplyr::rename(
          iso3      = REF_AREA,
          indicator = INDICATOR,
          period    = TIME_PERIOD,
          value     = OBS_VALUE
        ) %>%
        dplyr::mutate(
          period = as.numeric(period), # Simple conversion
          value = as.numeric(value)
        )
      
      if (country_names && "iso3" %in% names(result)) {
         result <- result %>%
          dplyr::left_join(
            countrycode::codelist %>% dplyr::select(iso3 = iso3c, country = country.name.en),
            by = "iso3"
          )
      }
  }
  
  # 4. Post-processing (Metadata, MRV, Latest, Format)
  
  # Add metadata columns
  if (!is.null(add_metadata) && "iso3" %in% names(result)) {
    result <- add_country_metadata(result, add_metadata)
    result <- add_indicator_metadata(result, add_metadata)
  }
  
  # Drop NA values
  if (dropna && "value" %in% names(result)) {
    result <- result %>% dplyr::filter(!is.na(value))
  }
  
  # Most Recent Values (MRV)
  if (!is.null(mrv) && mrv > 0 && "iso3" %in% names(result)) {
    result <- apply_mrv(result, mrv)
  }
  
  # Latest value per country
  if (latest && "iso3" %in% names(result)) {
    result <- apply_latest(result)
  }
  
  # Format transformation
  if (format != "long" && "iso3" %in% names(result)) {
    result <- apply_format(result, format)
  }
  
  # Simplify columns
  if (simplify) {
    result <- simplify_columns(result, format)
  }
  
  return(result)
}

#' Add country-level metadata columns
#' @keywords internal
add_country_metadata <- function(df, metadata_list) {
  if ("region" %in% metadata_list) {
    region_map <- get_country_regions()
    df <- df %>% dplyr::mutate(region = region_map[iso3])
  }
  
  if ("income_group" %in% metadata_list) {
    income_map <- get_income_groups()
    df <- df %>% dplyr::mutate(income_group = income_map[iso3])
  }
  
  if ("continent" %in% metadata_list) {
    continent_map <- get_continents()
    df <- df %>% dplyr::mutate(continent = continent_map[iso3])
  }
  
  df
}


#' Add indicator-level metadata columns
#' @keywords internal
add_indicator_metadata <- function(df, metadata_list) {
  if (!"indicator" %in% names(df)) return(df)
  
  if ("indicator_name" %in% metadata_list || "indicator_category" %in% metadata_list) {
    unique_inds <- unique(df$indicator)
    
    for (ind in unique_inds) {
      info <- tryCatch(get_indicator_info(ind), error = function(e) NULL)
      if (!is.null(info)) {
        if ("indicator_name" %in% metadata_list) {
          df <- df %>% dplyr::mutate(
            indicator_name = dplyr::if_else(indicator == ind, info$name, indicator_name)
          )
        }
        if ("indicator_category" %in% metadata_list) {
          df <- df %>% dplyr::mutate(
            indicator_category = dplyr::if_else(indicator == ind, info$category, indicator_category)
          )
        }
      }
    }
  }
  
  df
}


#' Apply Most Recent Values filter
#' @keywords internal
apply_mrv <- function(df, n) {
  if ("indicator" %in% names(df)) {
    df %>%
      dplyr::arrange(iso3, indicator, dplyr::desc(period)) %>%
      dplyr::group_by(iso3, indicator) %>%
      dplyr::slice_head(n = n) %>%
      dplyr::ungroup()
  } else {
    df %>%
      dplyr::arrange(iso3, dplyr::desc(period)) %>%
      dplyr::group_by(iso3) %>%
      dplyr::slice_head(n = n) %>%
      dplyr::ungroup()
  }
}


#' Apply latest value filter
#' @keywords internal
apply_latest <- function(df) {
  if ("value" %in% names(df)) {
    df <- df %>% dplyr::filter(!is.na(value))
  }
  
  if ("indicator" %in% names(df)) {
    df %>%
      dplyr::group_by(iso3, indicator) %>%
      dplyr::filter(period == max(period, na.rm = TRUE)) %>%
      dplyr::ungroup()
  } else {
    df %>%
      dplyr::group_by(iso3) %>%
      dplyr::filter(period == max(period, na.rm = TRUE)) %>%
      dplyr::ungroup()
  }
}


#' Apply format transformation
#' @keywords internal
apply_format <- function(df, format) {
  if (format == "wide") {
    # Countries as rows, years as columns
    n_indicators <- dplyr::n_distinct(df$indicator)
    if (n_indicators > 1) {
      message("Warning: 'wide' format with multiple indicators may produce complex output.")
      message("         Consider using 'wide_indicators' format instead.")
    }
    
    # Identify columns to keep as index
    id_cols <- c("iso3")
    if ("country" %in% names(df)) id_cols <- c(id_cols, "country")
    for (col in c("region", "income_group", "continent")) {
      if (col %in% names(df)) id_cols <- c(id_cols, col)
    }
    if (n_indicators > 1 && "indicator" %in% names(df)) {
      id_cols <- c(id_cols, "indicator")
    }
    
    df %>%
      tidyr::pivot_wider(
        id_cols = dplyr::all_of(id_cols),
        names_from = period,
        values_from = value,
        names_prefix = "y"
      )
    
  } else if (format == "wide_indicators") {
    # Years as rows, indicators as columns
    n_indicators <- dplyr::n_distinct(df$indicator)
    if (n_indicators == 1) {
      message("Warning: 'wide_indicators' format is designed for multiple indicators.")
      return(df)
    }
    
    # Identify columns to keep as index
    id_cols <- c("iso3", "period")
    if ("country" %in% names(df)) id_cols <- c(id_cols[1], "country", id_cols[2])
    for (col in c("region", "income_group", "continent")) {
      if (col %in% names(df)) id_cols <- c(id_cols, col)
    }
    
    df %>%
      tidyr::pivot_wider(
        id_cols = dplyr::all_of(id_cols),
        names_from = indicator,
        values_from = value
      )
    
  } else if (format %in% c("wide_sex", "wide_age", "wide_wealth", "wide_residence", "wide_maternal_edu")) {
    
    # Map format to column name
    pivot_col <- switch(format,
      "wide_sex" = "sex",
      "wide_age" = "age",
      "wide_wealth" = "wealth_quintile",
      "wide_residence" = "residence",
      "wide_maternal_edu" = "maternal_edu_lvl"
    )
    
    if (!pivot_col %in% names(df)) {
      warning(sprintf("Column '%s' not found in data. Cannot pivot.", pivot_col))
      return(df)
    }
    
    # Identify columns to keep as index (same as wide_indicators)
    id_cols <- c("iso3", "period")
    if ("country" %in% names(df)) id_cols <- c(id_cols[1], "country", id_cols[2])
    for (col in c("region", "income_group", "continent")) {
      if (col %in% names(df)) id_cols <- c(id_cols, col)
    }

    df %>%
      tidyr::pivot_wider(
        id_cols = dplyr::all_of(id_cols),
        names_from = c("indicator", pivot_col),
        values_from = value,
        names_sep = "_"
      )
      
  } else {
    df
  }
}


#' Simplify columns to essentials
#' @keywords internal
simplify_columns <- function(df, format) {
  if (format == "long") {
    essential <- c("iso3", "country", "indicator", "period", "value")
    metadata_cols <- c("region", "income_group", "continent", "indicator_name")
    available <- intersect(c(essential, metadata_cols), names(df))
    df %>% dplyr::select(dplyr::all_of(available))
  } else {
    df
  }
}


#' Get ISO3 to UNICEF region mapping
#' @keywords internal
get_country_regions <- function() {
  c(
    # East Asia and Pacific
    'AUS' = 'East Asia and Pacific', 'BRN' = 'East Asia and Pacific', 'KHM' = 'East Asia and Pacific',
    'CHN' = 'East Asia and Pacific', 'PRK' = 'East Asia and Pacific', 'FJI' = 'East Asia and Pacific',
    'IDN' = 'East Asia and Pacific', 'JPN' = 'East Asia and Pacific', 'KIR' = 'East Asia and Pacific',
    'LAO' = 'East Asia and Pacific', 'MYS' = 'East Asia and Pacific', 'MHL' = 'East Asia and Pacific',
    'FSM' = 'East Asia and Pacific', 'MNG' = 'East Asia and Pacific', 'MMR' = 'East Asia and Pacific',
    'NRU' = 'East Asia and Pacific', 'NZL' = 'East Asia and Pacific', 'PLW' = 'East Asia and Pacific',
    'PNG' = 'East Asia and Pacific', 'PHL' = 'East Asia and Pacific', 'WSM' = 'East Asia and Pacific',
    'SGP' = 'East Asia and Pacific', 'SLB' = 'East Asia and Pacific', 'KOR' = 'East Asia and Pacific',
    'THA' = 'East Asia and Pacific', 'TLS' = 'East Asia and Pacific', 'TON' = 'East Asia and Pacific',
    'TUV' = 'East Asia and Pacific', 'VUT' = 'East Asia and Pacific', 'VNM' = 'East Asia and Pacific',
    # Europe and Central Asia
    'ALB' = 'Europe and Central Asia', 'ARM' = 'Europe and Central Asia', 'AUT' = 'Europe and Central Asia',
    'AZE' = 'Europe and Central Asia', 'BLR' = 'Europe and Central Asia', 'BEL' = 'Europe and Central Asia',
    'BIH' = 'Europe and Central Asia', 'BGR' = 'Europe and Central Asia', 'HRV' = 'Europe and Central Asia',
    'CYP' = 'Europe and Central Asia', 'CZE' = 'Europe and Central Asia', 'DNK' = 'Europe and Central Asia',
    'EST' = 'Europe and Central Asia', 'FIN' = 'Europe and Central Asia', 'FRA' = 'Europe and Central Asia',
    'GEO' = 'Europe and Central Asia', 'DEU' = 'Europe and Central Asia', 'GRC' = 'Europe and Central Asia',
    'HUN' = 'Europe and Central Asia', 'ISL' = 'Europe and Central Asia', 'IRL' = 'Europe and Central Asia',
    'ITA' = 'Europe and Central Asia', 'KAZ' = 'Europe and Central Asia', 'KGZ' = 'Europe and Central Asia',
    'LVA' = 'Europe and Central Asia', 'LTU' = 'Europe and Central Asia', 'LUX' = 'Europe and Central Asia',
    'MKD' = 'Europe and Central Asia', 'MLT' = 'Europe and Central Asia', 'MDA' = 'Europe and Central Asia',
    'MNE' = 'Europe and Central Asia', 'NLD' = 'Europe and Central Asia', 'NOR' = 'Europe and Central Asia',
    'POL' = 'Europe and Central Asia', 'PRT' = 'Europe and Central Asia', 'ROU' = 'Europe and Central Asia',
    'RUS' = 'Europe and Central Asia', 'SRB' = 'Europe and Central Asia', 'SVK' = 'Europe and Central Asia',
    'SVN' = 'Europe and Central Asia', 'ESP' = 'Europe and Central Asia', 'SWE' = 'Europe and Central Asia',
    'CHE' = 'Europe and Central Asia', 'TJK' = 'Europe and Central Asia', 'TUR' = 'Europe and Central Asia',
    'TKM' = 'Europe and Central Asia', 'UKR' = 'Europe and Central Asia', 'GBR' = 'Europe and Central Asia',
    'UZB' = 'Europe and Central Asia',
    # Latin America and Caribbean
    'ATG' = 'Latin America and Caribbean', 'ARG' = 'Latin America and Caribbean', 'BHS' = 'Latin America and Caribbean',
    'BRB' = 'Latin America and Caribbean', 'BLZ' = 'Latin America and Caribbean', 'BOL' = 'Latin America and Caribbean',
    'BRA' = 'Latin America and Caribbean', 'CHL' = 'Latin America and Caribbean', 'COL' = 'Latin America and Caribbean',
    'CRI' = 'Latin America and Caribbean', 'CUB' = 'Latin America and Caribbean', 'DMA' = 'Latin America and Caribbean',
    'DOM' = 'Latin America and Caribbean', 'ECU' = 'Latin America and Caribbean', 'SLV' = 'Latin America and Caribbean',
    'GRD' = 'Latin America and Caribbean', 'GTM' = 'Latin America and Caribbean', 'GUY' = 'Latin America and Caribbean',
    'HTI' = 'Latin America and Caribbean', 'HND' = 'Latin America and Caribbean', 'JAM' = 'Latin America and Caribbean',
    'MEX' = 'Latin America and Caribbean', 'NIC' = 'Latin America and Caribbean', 'PAN' = 'Latin America and Caribbean',
    'PRY' = 'Latin America and Caribbean', 'PER' = 'Latin America and Caribbean', 'KNA' = 'Latin America and Caribbean',
    'LCA' = 'Latin America and Caribbean', 'VCT' = 'Latin America and Caribbean', 'SUR' = 'Latin America and Caribbean',
    'TTO' = 'Latin America and Caribbean', 'URY' = 'Latin America and Caribbean', 'VEN' = 'Latin America and Caribbean',
    # Middle East and North Africa
    'DZA' = 'Middle East and North Africa', 'BHR' = 'Middle East and North Africa', 'DJI' = 'Middle East and North Africa',
    'EGY' = 'Middle East and North Africa', 'IRN' = 'Middle East and North Africa', 'IRQ' = 'Middle East and North Africa',
    'ISR' = 'Middle East and North Africa', 'JOR' = 'Middle East and North Africa', 'KWT' = 'Middle East and North Africa',
    'LBN' = 'Middle East and North Africa', 'LBY' = 'Middle East and North Africa', 'MAR' = 'Middle East and North Africa',
    'OMN' = 'Middle East and North Africa', 'QAT' = 'Middle East and North Africa', 'SAU' = 'Middle East and North Africa',
    'SDN' = 'Middle East and North Africa', 'SYR' = 'Middle East and North Africa', 'TUN' = 'Middle East and North Africa',
    'ARE' = 'Middle East and North Africa', 'YEM' = 'Middle East and North Africa', 'PSE' = 'Middle East and North Africa',
    # North America
    'CAN' = 'North America', 'USA' = 'North America',
    # South Asia
    'AFG' = 'South Asia', 'BGD' = 'South Asia', 'BTN' = 'South Asia', 'IND' = 'South Asia',
    'MDV' = 'South Asia', 'NPL' = 'South Asia', 'PAK' = 'South Asia', 'LKA' = 'South Asia',
    # Sub-Saharan Africa
    'AGO' = 'Sub-Saharan Africa', 'BEN' = 'Sub-Saharan Africa', 'BWA' = 'Sub-Saharan Africa',
    'BFA' = 'Sub-Saharan Africa', 'BDI' = 'Sub-Saharan Africa', 'CPV' = 'Sub-Saharan Africa',
    'CMR' = 'Sub-Saharan Africa', 'CAF' = 'Sub-Saharan Africa', 'TCD' = 'Sub-Saharan Africa',
    'COM' = 'Sub-Saharan Africa', 'COG' = 'Sub-Saharan Africa', 'COD' = 'Sub-Saharan Africa',
    'CIV' = 'Sub-Saharan Africa', 'GNQ' = 'Sub-Saharan Africa', 'ERI' = 'Sub-Saharan Africa',
    'SWZ' = 'Sub-Saharan Africa', 'ETH' = 'Sub-Saharan Africa', 'GAB' = 'Sub-Saharan Africa',
    'GMB' = 'Sub-Saharan Africa', 'GHA' = 'Sub-Saharan Africa', 'GIN' = 'Sub-Saharan Africa',
    'GNB' = 'Sub-Saharan Africa', 'KEN' = 'Sub-Saharan Africa', 'LSO' = 'Sub-Saharan Africa',
    'LBR' = 'Sub-Saharan Africa', 'MDG' = 'Sub-Saharan Africa', 'MWI' = 'Sub-Saharan Africa',
    'MLI' = 'Sub-Saharan Africa', 'MRT' = 'Sub-Saharan Africa', 'MUS' = 'Sub-Saharan Africa',
    'MOZ' = 'Sub-Saharan Africa', 'NAM' = 'Sub-Saharan Africa', 'NER' = 'Sub-Saharan Africa',
    'NGA' = 'Sub-Saharan Africa', 'RWA' = 'Sub-Saharan Africa', 'STP' = 'Sub-Saharan Africa',
    'SEN' = 'Sub-Saharan Africa', 'SYC' = 'Sub-Saharan Africa', 'SLE' = 'Sub-Saharan Africa',
    'SOM' = 'Sub-Saharan Africa', 'ZAF' = 'Sub-Saharan Africa', 'SSD' = 'Sub-Saharan Africa',
    'TZA' = 'Sub-Saharan Africa', 'TGO' = 'Sub-Saharan Africa', 'UGA' = 'Sub-Saharan Africa',
    'ZMB' = 'Sub-Saharan Africa', 'ZWE' = 'Sub-Saharan Africa'
  )
}


#' Get ISO3 to World Bank income group mapping
#' @keywords internal
get_income_groups <- function() {
  c(
    # High income
    'AUS' = 'High income', 'AUT' = 'High income', 'BEL' = 'High income', 'CAN' = 'High income',
    'CHE' = 'High income', 'CHL' = 'High income', 'CZE' = 'High income', 'DEU' = 'High income',
    'DNK' = 'High income', 'ESP' = 'High income', 'EST' = 'High income', 'FIN' = 'High income',
    'FRA' = 'High income', 'GBR' = 'High income', 'GRC' = 'High income', 'HUN' = 'High income',
    'IRL' = 'High income', 'ISL' = 'High income', 'ISR' = 'High income', 'ITA' = 'High income',
    'JPN' = 'High income', 'KOR' = 'High income', 'LTU' = 'High income', 'LUX' = 'High income',
    'LVA' = 'High income', 'NLD' = 'High income', 'NOR' = 'High income', 'NZL' = 'High income',
    'POL' = 'High income', 'PRT' = 'High income', 'SAU' = 'High income', 'SGP' = 'High income',
    'SVK' = 'High income', 'SVN' = 'High income', 'SWE' = 'High income', 'USA' = 'High income',
    'URY' = 'High income', 'ARE' = 'High income', 'BHR' = 'High income', 'KWT' = 'High income',
    'OMN' = 'High income', 'QAT' = 'High income', 'HRV' = 'High income', 'CYP' = 'High income',
    'MLT' = 'High income', 'BRN' = 'High income', 'PAN' = 'High income', 'TTO' = 'High income',
    'BHS' = 'High income', 'BRB' = 'High income', 'ATG' = 'High income', 'KNA' = 'High income',
    'SYC' = 'High income', 'PLW' = 'High income', 'NRU' = 'High income',
    # Upper middle income
    'ARG' = 'Upper middle income', 'BGR' = 'Upper middle income', 'BRA' = 'Upper middle income',
    'CHN' = 'Upper middle income', 'COL' = 'Upper middle income', 'CRI' = 'Upper middle income',
    'DOM' = 'Upper middle income', 'ECU' = 'Upper middle income', 'GAB' = 'Upper middle income',
    'GNQ' = 'Upper middle income', 'GTM' = 'Upper middle income', 'IRN' = 'Upper middle income',
    'IRQ' = 'Upper middle income', 'JAM' = 'Upper middle income', 'JOR' = 'Upper middle income',
    'KAZ' = 'Upper middle income', 'LBN' = 'Upper middle income', 'LBY' = 'Upper middle income',
    'MEX' = 'Upper middle income', 'MKD' = 'Upper middle income', 'MNE' = 'Upper middle income',
    'MUS' = 'Upper middle income', 'MYS' = 'Upper middle income', 'NAM' = 'Upper middle income',
    'PER' = 'Upper middle income', 'ROU' = 'Upper middle income', 'RUS' = 'Upper middle income',
    'SRB' = 'Upper middle income', 'THA' = 'Upper middle income', 'TUR' = 'Upper middle income',
    'TKM' = 'Upper middle income', 'VEN' = 'Upper middle income', 'ZAF' = 'Upper middle income',
    'ALB' = 'Upper middle income', 'ARM' = 'Upper middle income', 'AZE' = 'Upper middle income',
    'BIH' = 'Upper middle income', 'BWA' = 'Upper middle income', 'CUB' = 'Upper middle income',
    'DMA' = 'Upper middle income', 'FJI' = 'Upper middle income', 'GEO' = 'Upper middle income',
    'GRD' = 'Upper middle income', 'GUY' = 'Upper middle income', 'LCA' = 'Upper middle income',
    'MDV' = 'Upper middle income', 'MHL' = 'Upper middle income', 'PRY' = 'Upper middle income',
    'SUR' = 'Upper middle income', 'TON' = 'Upper middle income', 'TUV' = 'Upper middle income',
    'VCT' = 'Upper middle income',
    # Lower middle income
    'AGO' = 'Lower middle income', 'BEN' = 'Lower middle income', 'BGD' = 'Lower middle income',
    'BLZ' = 'Lower middle income', 'BOL' = 'Lower middle income', 'BTN' = 'Lower middle income',
    'CIV' = 'Lower middle income', 'CMR' = 'Lower middle income', 'COG' = 'Lower middle income',
    'COM' = 'Lower middle income', 'CPV' = 'Lower middle income', 'DJI' = 'Lower middle income',
    'DZA' = 'Lower middle income', 'EGY' = 'Lower middle income', 'GHA' = 'Lower middle income',
    'HND' = 'Lower middle income', 'HTI' = 'Lower middle income', 'IDN' = 'Lower middle income',
    'IND' = 'Lower middle income', 'KEN' = 'Lower middle income', 'KGZ' = 'Lower middle income',
    'KHM' = 'Lower middle income', 'KIR' = 'Lower middle income', 'LAO' = 'Lower middle income',
    'LKA' = 'Lower middle income', 'LSO' = 'Lower middle income', 'MAR' = 'Lower middle income',
    'MDA' = 'Lower middle income', 'MMR' = 'Lower middle income', 'MNG' = 'Lower middle income',
    'MRT' = 'Lower middle income', 'NGA' = 'Lower middle income', 'NIC' = 'Lower middle income',
    'NPL' = 'Lower middle income', 'PAK' = 'Lower middle income', 'PHL' = 'Lower middle income',
    'PNG' = 'Lower middle income', 'PSE' = 'Lower middle income', 'SEN' = 'Lower middle income',
    'SLB' = 'Lower middle income', 'SLV' = 'Lower middle income', 'STP' = 'Lower middle income',
    'SWZ' = 'Lower middle income', 'TJK' = 'Lower middle income', 'TLS' = 'Lower middle income',
    'TUN' = 'Lower middle income', 'TZA' = 'Lower middle income', 'UKR' = 'Lower middle income',
    'UZB' = 'Lower middle income', 'VNM' = 'Lower middle income', 'VUT' = 'Lower middle income',
    'WSM' = 'Lower middle income', 'ZMB' = 'Lower middle income', 'ZWE' = 'Lower middle income',
    # Low income
    'AFG' = 'Low income', 'BDI' = 'Low income', 'BFA' = 'Low income', 'CAF' = 'Low income',
    'COD' = 'Low income', 'ERI' = 'Low income', 'ETH' = 'Low income', 'GMB' = 'Low income',
    'GIN' = 'Low income', 'GNB' = 'Low income', 'LBR' = 'Low income', 'MDG' = 'Low income',
    'MLI' = 'Low income', 'MOZ' = 'Low income', 'MWI' = 'Low income', 'NER' = 'Low income',
    'PRK' = 'Low income', 'RWA' = 'Low income', 'SDN' = 'Low income', 'SLE' = 'Low income',
    'SOM' = 'Low income', 'SSD' = 'Low income', 'SYR' = 'Low income', 'TCD' = 'Low income',
    'TGO' = 'Low income', 'UGA' = 'Low income', 'YEM' = 'Low income'
  )
}


#' Get ISO3 to continent mapping
#' @keywords internal
get_continents <- function() {
  c(
    # Africa
    'DZA' = 'Africa', 'AGO' = 'Africa', 'BEN' = 'Africa', 'BWA' = 'Africa', 'BFA' = 'Africa',
    'BDI' = 'Africa', 'CPV' = 'Africa', 'CMR' = 'Africa', 'CAF' = 'Africa', 'TCD' = 'Africa',
    'COM' = 'Africa', 'COG' = 'Africa', 'COD' = 'Africa', 'CIV' = 'Africa', 'DJI' = 'Africa',
    'EGY' = 'Africa', 'GNQ' = 'Africa', 'ERI' = 'Africa', 'SWZ' = 'Africa', 'ETH' = 'Africa',
    'GAB' = 'Africa', 'GMB' = 'Africa', 'GHA' = 'Africa', 'GIN' = 'Africa', 'GNB' = 'Africa',
    'KEN' = 'Africa', 'LSO' = 'Africa', 'LBR' = 'Africa', 'LBY' = 'Africa', 'MDG' = 'Africa',
    'MWI' = 'Africa', 'MLI' = 'Africa', 'MRT' = 'Africa', 'MUS' = 'Africa', 'MAR' = 'Africa',
    'MOZ' = 'Africa', 'NAM' = 'Africa', 'NER' = 'Africa', 'NGA' = 'Africa', 'RWA' = 'Africa',
    'STP' = 'Africa', 'SEN' = 'Africa', 'SYC' = 'Africa', 'SLE' = 'Africa', 'SOM' = 'Africa',
    'ZAF' = 'Africa', 'SSD' = 'Africa', 'SDN' = 'Africa', 'TZA' = 'Africa', 'TGO' = 'Africa',
    'TUN' = 'Africa', 'UGA' = 'Africa', 'ZMB' = 'Africa', 'ZWE' = 'Africa',
    # Asia
    'AFG' = 'Asia', 'ARM' = 'Asia', 'AZE' = 'Asia', 'BHR' = 'Asia', 'BGD' = 'Asia',
    'BTN' = 'Asia', 'BRN' = 'Asia', 'KHM' = 'Asia', 'CHN' = 'Asia', 'CYP' = 'Asia',
    'GEO' = 'Asia', 'IND' = 'Asia', 'IDN' = 'Asia', 'IRN' = 'Asia', 'IRQ' = 'Asia',
    'ISR' = 'Asia', 'JPN' = 'Asia', 'JOR' = 'Asia', 'KAZ' = 'Asia', 'KWT' = 'Asia',
    'KGZ' = 'Asia', 'LAO' = 'Asia', 'LBN' = 'Asia', 'MYS' = 'Asia', 'MDV' = 'Asia',
    'MNG' = 'Asia', 'MMR' = 'Asia', 'NPL' = 'Asia', 'PRK' = 'Asia', 'OMN' = 'Asia',
    'PAK' = 'Asia', 'PSE' = 'Asia', 'PHL' = 'Asia', 'QAT' = 'Asia', 'SAU' = 'Asia',
    'SGP' = 'Asia', 'KOR' = 'Asia', 'LKA' = 'Asia', 'SYR' = 'Asia', 'TJK' = 'Asia',
    'THA' = 'Asia', 'TLS' = 'Asia', 'TUR' = 'Asia', 'TKM' = 'Asia', 'ARE' = 'Asia',
    'UZB' = 'Asia', 'VNM' = 'Asia', 'YEM' = 'Asia',
    # Europe
    'ALB' = 'Europe', 'AUT' = 'Europe', 'BLR' = 'Europe', 'BEL' = 'Europe',
    'BIH' = 'Europe', 'BGR' = 'Europe', 'HRV' = 'Europe', 'CZE' = 'Europe', 'DNK' = 'Europe',
    'EST' = 'Europe', 'FIN' = 'Europe', 'FRA' = 'Europe', 'DEU' = 'Europe', 'GRC' = 'Europe',
    'HUN' = 'Europe', 'ISL' = 'Europe', 'IRL' = 'Europe', 'ITA' = 'Europe', 'LVA' = 'Europe',
    'LTU' = 'Europe', 'LUX' = 'Europe', 'MLT' = 'Europe', 'MDA' = 'Europe',
    'MNE' = 'Europe', 'NLD' = 'Europe', 'MKD' = 'Europe', 'NOR' = 'Europe',
    'POL' = 'Europe', 'PRT' = 'Europe', 'ROU' = 'Europe', 'RUS' = 'Europe',
    'SRB' = 'Europe', 'SVK' = 'Europe', 'SVN' = 'Europe', 'ESP' = 'Europe', 'SWE' = 'Europe',
    'CHE' = 'Europe', 'UKR' = 'Europe', 'GBR' = 'Europe',
    # North America
    'ATG' = 'North America', 'BHS' = 'North America', 'BRB' = 'North America', 'BLZ' = 'North America',
    'CAN' = 'North America', 'CRI' = 'North America', 'CUB' = 'North America', 'DMA' = 'North America',
    'DOM' = 'North America', 'SLV' = 'North America', 'GRD' = 'North America', 'GTM' = 'North America',
    'HTI' = 'North America', 'HND' = 'North America', 'JAM' = 'North America', 'MEX' = 'North America',
    'NIC' = 'North America', 'PAN' = 'North America', 'KNA' = 'North America', 'LCA' = 'North America',
    'VCT' = 'North America', 'TTO' = 'North America', 'USA' = 'North America',
    # South America
    'ARG' = 'South America', 'BOL' = 'South America', 'BRA' = 'South America', 'CHL' = 'South America',
    'COL' = 'South America', 'ECU' = 'South America', 'GUY' = 'South America', 'PRY' = 'South America',
    'PER' = 'South America', 'SUR' = 'South America', 'URY' = 'South America', 'VEN' = 'South America',
    # Oceania
    'AUS' = 'Oceania', 'FJI' = 'Oceania', 'KIR' = 'Oceania', 'MHL' = 'Oceania', 'FSM' = 'Oceania',
    'NRU' = 'Oceania', 'NZL' = 'Oceania', 'PLW' = 'Oceania', 'PNG' = 'Oceania', 'WSM' = 'Oceania',
    'SLB' = 'Oceania', 'TON' = 'Oceania', 'TUV' = 'Oceania', 'VUT' = 'Oceania'
  )
}


#' @title List available UNICEF dataflows
#' @description Alias for list_unicef_flows() with consistent naming.
#' @param max_retries Number of retry attempts (default: 3)
#' @return Tibble with columns: id, agency, version
#' @export
list_dataflows <- function(max_retries = 3) {
  list_unicef_flows(retry = max_retries)
}

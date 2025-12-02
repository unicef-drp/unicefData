# Internal helper to perform HTTP GET and return text
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
    url <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/structure/dataflow?references=none&detail=full"
    xml_text <- fetch_sdmx(url, ua, retry)
    doc <- xml2::read_xml(xml_text)
    dfs <- xml2::xml_find_all(doc, ".//Dataflow")
    tibble::tibble(
      id      = xml2::xml_attr(dfs, "id"),
      agency  = xml2::xml_attr(dfs, "agencyID"),
      version = xml2::xml_attr(dfs, "version")
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
#' @param tidy Logical; if TRUE (default), returns cleaned tibble with standardized column names.
#' @param country_names Logical; if TRUE (default), adds country name column.
#' @param max_retries Number of retry attempts on failure (default: 3).
#'   Previously called 'retry'. Both parameter names are supported.
#' @param cache Logical; if TRUE, memoises results.
#' @param page_size Integer rows per page (default: 100000).
#' @param detail "data" (default) or "structure" for metadata.
#' @param version Optional SDMX version; if NULL, auto-detected.
#' @param flow Deprecated. Use 'dataflow' instead.
#' @param key Deprecated. Use 'indicator' instead.
#' @param start_period Deprecated. Use 'start_year' instead.
#' @param end_period Deprecated. Use 'end_year' instead.
#' @param retry Deprecated. Use 'max_retries' instead.
#' @return Tibble with indicator data, or xml_document if detail="structure".
#' 
#' @examples
#' \dontrun{
#' # Fetch under-5 mortality for specific countries
#' df <- get_unicef(
#'   indicator = "CME_MRY0T4",
#'   countries = c("ALB", "USA", "BRA"),
#'   start_year = 2015,
#'   end_year = 2023
#' )
#' 
#' # Fetch multiple indicators
#' df <- get_unicef(
#'   indicator = c("CME_MRY0T4", "CME_MRM0"),
#'   dataflow = "CME",
#'   start_year = 2020
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
    tidy          = TRUE,
    country_names = TRUE,
    max_retries   = 3,
    cache         = FALSE,
    page_size     = 100000,
    detail        = c("data", "structure"),
    version       = NULL,
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
    # message("Note: 'flow' is deprecated. Use 'dataflow' instead.")
  }
  if (!is.null(key) && is.null(indicator)) {
    indicator <- key
    # message("Note: 'key' is deprecated. Use 'indicator' instead.")
  }
  if (!is.null(start_period) && is.null(start_year)) {
    start_year <- start_period
    # message("Note: 'start_period' is deprecated. Use 'start_year' instead.")
  }
  if (!is.null(end_period) && is.null(end_year)) {
    end_year <- end_period
    # message("Note: 'end_period' is deprecated. Use 'end_year' instead.")
  }
  if (!is.null(retry) && max_retries == 3) {
    max_retries <- retry
    # message("Note: 'retry' is deprecated. Use 'max_retries' instead.")
  }
  
  # Validate required parameters
  if (is.null(dataflow)) {
    stop("'dataflow' is required. Use list_dataflows() to see available options.", call. = FALSE)
  }
  detail <- match.arg(detail)
  stopifnot(is.character(dataflow), length(dataflow) >= 1)
  
  validate_year <- function(x, name) {
    if (!is.null(x)) {
      x_chr <- as.character(x)
      if (length(x_chr) != 1 || !grepl("^\\d{4}$", x_chr))
        stop(sprintf("`%s` must be a single 4-digit year.", name), call. = FALSE)
      return(x_chr)
    }
    NULL
  }
  start_year_str <- validate_year(start_year, "start_year")
  end_year_str   <- validate_year(end_year,   "end_year")
  
  if (is.null(version) && detail == "data") flows_meta <- list_unicef_flows(retry = max_retries)
  
  fetch_flow <- function(fl) {
    ua <- httr::user_agent("get_unicef/1.0 (+https://github.com/jpazvd/get_unicef)")
    base <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    
    if (detail == "structure") {
      ver <- if (!is.null(version)) version else {
        idx <- match(fl, flows_meta$id)
        if (is.na(idx)) stop(sprintf("Dataflow '%s' not found.", fl), call. = FALSE)
        flows_meta$version[idx]
      }
      url <- sprintf("%s/structure/dataflow/UNICEF.%s?references=all&detail=full", base, fl)
      return(xml2::read_xml(fetch_sdmx(url, ua, max_retries)))
    }
    
    ver <- if (!is.null(version)) version else {
      idx <- match(fl, flows_meta$id)
      if (is.na(idx)) stop(sprintf("Dataflow '%s' not found.", fl), call. = FALSE)
      flows_meta$version[idx]
    }
    indicator_str  <- if (!is.null(indicator)) paste0(".", paste(indicator, collapse = "+")) else ""
    date_str <- if (!is.null(start_year_str) || !is.null(end_year_str))
      sprintf(".%s/%s", start_year_str %||% "", end_year_str %||% "") else ""
    
    rel_path <- sprintf("data/UNICEF.%s.%s%s%s", fl, ver, indicator_str, date_str)
    full_url <- paste0(base, "/", rel_path, "?format=csv&labels=both")
    
    # paging
    pages <- list(); page <- 0L
    repeat {
      page_url <- paste0(full_url, "&startIndex=", page * page_size,
                         "&count=", page_size)
      df <- tryCatch(
        readr::read_csv(fetch_sdmx(page_url, ua, max_retries), show_col_types = FALSE),
        error = function(e) NULL
      )
      if (is.null(df) || nrow(df) == 0) break
      pages[[length(pages) + 1L]] <- df
      if (nrow(df) < page_size) break
      page <- page + 1L; Sys.sleep(0.2)
    }
    df_all <- dplyr::bind_rows(pages)
    
    # Filter by countries if specified
    if (!is.null(countries) && nrow(df_all) > 0) {
      if ("REF_AREA" %in% names(df_all)) {
        df_all <- df_all %>% dplyr::filter(REF_AREA %in% countries)
      }
    }
    
    # Filter by sex if specified (default is "_T" for total)
    if (!is.null(sex) && nrow(df_all) > 0) {
      if ("SEX" %in% names(df_all)) {
        df_all <- df_all %>% dplyr::filter(SEX == sex)
      }
    }
    
    if (tidy && nrow(df_all) > 0) {
      df_all <- df_all %>%
        dplyr::rename(
          iso3      = REF_AREA,
          indicator = INDICATOR,
          period    = TIME_PERIOD,
          value     = OBS_VALUE
        ) %>%
        dplyr::mutate(period = as.integer(period)) %>%
        dplyr::select(iso3, dplyr::everything())
      if (country_names) {
        df_all <- df_all %>%
          dplyr::left_join(
            countrycode::countrycode_df %>% dplyr::select(iso3 = iso3c, country = country.name.en),
            by = "iso3"
          ) %>% dplyr::select(iso3, country, dplyr::everything())
      }
    }
    df_all
  }
  
  executor <- if (cache) memoise::memoise(fetch_flow) else fetch_flow
  result <- purrr::map(dataflow, executor)
  if (length(result) == 1) result[[1]] else setNames(result, dataflow)
}


#' @title List available UNICEF dataflows
#' @description Alias for list_unicef_flows() with consistent naming.
#' @param max_retries Number of retry attempts (default: 3)
#' @return Tibble with columns: id, agency, version
#' @export
list_dataflows <- function(max_retries = 3) {
  list_unicef_flows(retry = max_retries)
}

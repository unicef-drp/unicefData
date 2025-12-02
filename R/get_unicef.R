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
#' Download one or more SDMX "flows" (and optional keys) from the UNICEF data warehouse.
#' Supports automatic paging, retrying on transient failure, memoisation, and tidy-up.
#'
#' @param flow Character vector of flow IDs.
#' @param key Optional character vector of codes.
#' @param start_period,end_period Optional single 4-digit years.
#' @param detail "data" or "structure".
#' @param version Optional SDMX version; if NULL, auto-detected.
#' @param tidy Logical; if TRUE, rename and select key columns.
#' @param country_names Logical; if TRUE, join ISO3 to country names.
#' @param page_size Integer rows per page.
#' @param retry Number of retries.
#' @param cache Logical; if TRUE, memoise per flow.
#' @return Tibble or list of tibbles (data) or xml_document(s) (structure).
#' @export
get_unicef <- function(
    flow,
    key           = NULL,
    start_period  = NULL,
    end_period    = NULL,
    detail        = c("data","structure"),
    version       = NULL,
    tidy          = TRUE,
    country_names = TRUE,
    page_size     = 100000,
    retry         = 3,
    cache         = FALSE
) {
  detail <- match.arg(detail)
  stopifnot(is.character(flow), length(flow) >= 1)
  validate_year <- function(x, name) {
    if (!is.null(x)) {
      x_chr <- as.character(x)
      if (length(x_chr) != 1 || !grepl("^\\d{4}$", x_chr))
        stop(sprintf("`%s` must be a single 4-digit year.", name), call. = FALSE)
      return(x_chr)
    }
    NULL
  }
  start_period <- validate_year(start_period, "start_period")
  end_period   <- validate_year(end_period,   "end_period")
  
  if (is.null(version) && detail == "data") flows_meta <- list_unicef_flows(retry = retry)
  
  fetch_flow <- function(fl) {
    ua <- httr::user_agent("get_unicef/1.0 (+https://github.com/jpazvd/get_unicef)")
    base <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    
    if (detail == "structure") {
      ver <- if (!is.null(version)) version else {
        idx <- match(fl, flows_meta$id)
        if (is.na(idx)) stop(sprintf("Flow '%s' not found.", fl), call. = FALSE)
        flows_meta$version[idx]
      }
      url <- sprintf("%s/structure/dataflow/UNICEF.%s?references=all&detail=full", base, fl)
      return(xml2::read_xml(fetch_sdmx(url, ua, retry)))
    }
    
    ver <- if (!is.null(version)) version else {
      idx <- match(fl, flows_meta$id)
      if (is.na(idx)) stop(sprintf("Flow '%s' not found.", fl), call. = FALSE)
      flows_meta$version[idx]
    }
    key_str  <- if (!is.null(key)) paste0(".", paste(key, collapse = "+")) else ""
    date_str <- if (!is.null(start_period) || !is.null(end_period))
      sprintf(".%s/%s", start_period %||% "", end_period %||% "") else ""
    
    rel_path <- sprintf("data/UNICEF.%s.%s%s%s", fl, ver, key_str, date_str)
    full_url <- paste0(base, "/", rel_path, "?format=csv&labels=both")
    
    # paging
    pages <- list(); page <- 0L
    repeat {
      page_url <- paste0(full_url, "&startIndex=", page * page_size,
                         "&count=", page_size)
      df <- tryCatch(
        readr::read_csv(fetch_sdmx(page_url, ua, retry), show_col_types = FALSE),
        error = function(e) NULL
      )
      if (is.null(df) || nrow(df) == 0) break
      pages[[length(pages) + 1L]] <- df
      if (nrow(df) < page_size) break
      page <- page + 1L; Sys.sleep(0.2)
    }
    df_all <- dplyr::bind_rows(pages)
    
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
  result <- purrr::map(flow, executor)
  if (length(result) == 1) result[[1]] else setNames(result, flow)
}

# R/get_sdmx.R

#' @title Fetch SDMX data or structure from any agency
#' @description Download one or more SDMX flows from a specified agency,
#'   with paging, retries, caching, format & labels options, and post-processing.
#'
#' @param agency Character agency ID (e.g., "UNICEF").
#' @param flow Character vector of flow IDs; length ≥ 1.
#' @param key Optional character vector of codes to filter the flow.
#' @param start_period Optional single 4-digit year for start (e.g., 2000).
#' @param end_period Optional single 4-digit year for end (e.g., 2020).
#' @param detail One of "data" or "structure"; default "data".
#' @param version Optional SDMX version; if NULL, auto-detected via list_sdmx_flows().
#' @param format One of "csv", "sdmx-xml", "sdmx-json"; default "csv".
#' @param labels One of "both","id","none"; default "both".
#' @param tidy Logical; if TRUE, rename core columns and retain metadata; default TRUE.
#' @param country_names Logical; if TRUE, join ISO3 to country names; default TRUE.
#' @param page_size Rows per page for CSV; default 100000L.
#' @param retry Number of retries; default 3L.
#' @param cache Logical; if TRUE, cache per flow on disk; default FALSE.
#' @param sleep Pause (in seconds) between pages; default 0.2.
#' @param post_process Optional function to apply to raw tibble before tidy-up.
#'
#' @return A tibble (or list of tibbles) for data, or xml_document(s) for structure.
#' @export
#' @importFrom httr RETRY stop_for_status content user_agent
#' @importFrom readr read_csv
#' @importFrom xml2 read_xml
#' @importFrom dplyr bind_rows rename mutate select left_join everything
#' @importFrom purrr map
#' @importFrom countrycode countrycode_df
#' @importFrom memoise memoise cache_filesystem
#' @importFrom tools R_user_dir
#' @importFrom jsonlite fromJSON
#' @importFrom rlang %||%
get_sdmx <- function(
  agency        = "UNICEF",
  flow,
  key           = NULL,
  start_period  = NULL,
  end_period    = NULL,
  detail        = c("data","structure"),
  version       = NULL,
  format        = c("csv","sdmx-xml","sdmx-json"),
  labels        = c("both","id","none"),
  tidy          = TRUE,
  country_names = TRUE,
  page_size     = 100000L,
  retry         = 3L,
  cache         = FALSE,
  sleep         = 0.2,
  post_process  = NULL
) {
  detail <- match.arg(detail)
  format <- match.arg(format)
  labels <- match.arg(labels)
  stopifnot(is.character(agency), length(agency)==1L,
            is.character(flow), length(flow)>=1L)

  validate_year <- function(x,name) {
    if(is.null(x)) return(NULL)
    xc <- as.character(x)
    if(length(xc)!=1L || !grepl("^\\d{4}$", xc))
      stop(sprintf("`%s` must be a single 4-digit year.", name), call.=FALSE)
    xc
  }
  start_period <- validate_year(start_period, "start_period")
  end_period   <- validate_year(end_period,   "end_period")

  if(is.null(version) && detail=="data") {
    flows_meta <- list_sdmx_flows(agency, retry)
  }

  fetch_flow <- function(fl) {
    ua   <- .get_unicef_ua
    base <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"

    ver <- version %||% {
      idx <- match(fl, flows_meta$id)
      if(is.na(idx)) stop(sprintf("Flow '%s' not found.", fl), call.=FALSE)
      flows_meta$version[idx]
    }

    if(detail=="structure") {
      url <- sprintf("%s/structure/dataflow/%s.%s?references=all&detail=full",
                     base, agency, fl)
      return(xml2::read_xml(.fetch_sdmx(url, ua=ua, retry=retry)))
    }

    # Build the data key - format: .INDICATOR1+INDICATOR2..
    # Following the UNICEF production pattern from PROD-SDG-REP-2025
    key_str <- if(!is.null(key)) {
      paste0(".", paste(key, collapse="+"), "..")
    } else {
      ""
    }
    
    # Build the URL: data/AGENCY,FLOW,VERSION/KEY?params
    rel <- sprintf("data/%s,%s,%s/%s", agency, fl, ver, key_str)
    
    # Build query parameters
    query_parts <- c(
      sprintf("format=%s", if(format=="csv") "csv" else format),
      sprintf("labels=%s", labels)
    )
    if(!is.null(start_period)) query_parts <- c(query_parts, sprintf("startPeriod=%s", start_period))
    if(!is.null(end_period))   query_parts <- c(query_parts, sprintf("endPeriod=%s", end_period))
    query <- paste(query_parts, collapse = "&")
    
    url <- paste0(base, "/", rel, "?", query)

    if(format=="sdmx-json") {
      j <- jsonlite::fromJSON(.fetch_sdmx(url, ua=ua, retry=retry))
      df <- j$dataSets[[1]]$series %>%
        tibble::enframe(name="key", value="observations") %>%
        tidyr::unnest_wider(observations)
    } else {
      df <- readr::read_csv(.fetch_sdmx(url, ua=ua, retry=retry), show_col_types=FALSE)
      if(format=="csv") {
        pages <- list(df); p <- 0L
        while(nrow(df)==page_size) {
          Sys.sleep(sleep)
          p <- p+1L
          next_url <- paste0(url, "&startIndex=", p*page_size)
          df <- readr::read_csv(.fetch_sdmx(next_url, ua=ua, retry=retry), show_col_types=FALSE)
          if(nrow(df)==0L) break
          pages[[length(pages)+1L]] <- df
        }
        df <- dplyr::bind_rows(pages)
      }
    }

    if(is.function(post_process)) df <- post_process(df)

    if(tidy && format=="csv" && nrow(df)>0L) {
      df <- df %>%
        dplyr::rename(
          iso3      = REF_AREA,
          indicator = INDICATOR,
          period    = TIME_PERIOD,
          value     = OBS_VALUE
        ) %>%
        dplyr::mutate(period=as.integer(period)) %>%
        dplyr::select(iso3, dplyr::everything())
      if(country_names) {
        # Use countrycode function instead of deprecated countrycode_df
        df <- df %>%
          dplyr::mutate(
            country = countrycode::countrycode(iso3, "iso3c", "country.name", warn = FALSE)
          ) %>%
          dplyr::select(iso3, country, dplyr::everything())
      }
    }
    df
  }

  executor <- if(cache) memoise::memoise(fetch_flow,
      cache=memoise::cache_filesystem(tools::R_user_dir("get_sdmx","cache"))) else fetch_flow

  # Ensure flow is a proper character vector (not iterating over characters)
  flow <- as.character(flow)
  
  out <- tryCatch(
    purrr::map(flow, executor),
    error = function(e) {
      message("Error in purrr::map: ", e$message)
      message("flow = ", paste(flow, collapse = ", "))
      stop(e)
    }
  )
  if(length(out)==1L) out[[1]] else setNames(out, flow)
}

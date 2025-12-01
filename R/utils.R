# R/utils.R

#' @keywords internal
#' @importFrom rlang %||%
`%||%` <- function(x, y) if (!is.null(x)) x else y

#' @keywords internal
.get_unicef_ua <- httr::user_agent("get_unicef/1.0 (+https://github.com/jpazvd/get_unicef)")

#' @keywords internal
.fetch_sdmx <- function(url, ua = .get_unicef_ua, retry = 3L) {
  resp <- httr::RETRY("GET", url, ua, times = retry, pause_base = 1)
  httr::stop_for_status(resp, paste("Error fetching", url))
  httr::content(resp, as = "text", encoding = "UTF-8")
}
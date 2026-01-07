# R/utils.R

#' @keywords internal
#' @importFrom rlang %||%
`%||%` <- function(x, y) if (!is.null(x)) x else y

#' @keywords internal
.build_user_agent <- function() {
  pkg_ver <- tryCatch(as.character(utils::packageVersion("unicefData")), error = function(e) "dev")
  r_ver <- as.character(getRversion())
  os <- tryCatch(Sys.info()[["sysname"]], error = function(e) NA_character_)
  os_part <- if (!is.na(os)) paste0("; ", os) else ""
  paste0("unicefData-R/", pkg_ver, " (R/", r_ver, os_part, ") (+https://github.com/unicef-drp/unicefData)")
}

#' @keywords internal
.unicefData_ua <- httr::user_agent(.build_user_agent())

#' @keywords internal
.fetch_sdmx <- function(url, ua = .unicefData_ua, retry = 3L) {
  resp <- httr::RETRY("GET", url, ua, times = retry, pause_base = 1)
  httr::stop_for_status(resp, paste("Error fetching", url))
  httr::content(resp, as = "text", encoding = "UTF-8")
}

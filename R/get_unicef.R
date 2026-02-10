# Wrapper to maintain backward compatibility with older test scripts
# Maps legacy get_unicef() to new unicefData() API

#' get_unicef
#' 
#' Backward-compatible wrapper for unicefData(). Supports legacy parameters
#' start_year/end_year and forwards additional options.
#' 
#' @param indicator Character or vector of indicator codes
#' @param countries Character vector of ISO3 codes (optional)
#' @param start_year Integer start year (optional)
#' @param end_year Integer end year (optional)
#' @param year Character or integer specifying years (optional). If missing,
#'             constructed from start_year/end_year.
#' @param dataflow Optional explicit dataflow ID
#' @param ignore_duplicates Logical, removed duplicated rows after fetch
#' @param ... Additional arguments forwarded to unicefData()
#' @return Tibble with standardized columns
get_unicef <- function(
  indicator,
  countries = NULL,
  start_year = NULL,
  end_year = NULL,
  year = NULL,
  dataflow = NULL,
  ignore_duplicates = FALSE,
  ...
) {
  # Build year parameter if not provided
  if (is.null(year)) {
    if (!is.null(start_year) && !is.null(end_year)) {
      year <- paste0(start_year, ":", end_year)
    } else if (!is.null(start_year) && is.null(end_year)) {
      year <- as.integer(start_year)
    } else if (!is.null(end_year) && is.null(start_year)) {
      year <- as.integer(end_year)
    } else {
      year <- NULL
    }
  }
  
  # Ensure unicefData function is available
  # When used as a package, this will already be loaded via NAMESPACE
  # For standalone usage, require the package explicitly
  if (!exists("unicefData", mode = "function")) {
    if (!requireNamespace("unicefData", quietly = TRUE)) {
      stop("unicefData package is required but not installed. Install with: install.packages('unicefData')")
    }
  }

  df <- unicefData(
    indicator = indicator,
    dataflow = dataflow,
    countries = countries,
    year = year,
    ignore_duplicates = ignore_duplicates,
    ...
  )
  
  # Optional duplicate cleanup for older callers
  if (isTRUE(ignore_duplicates) && !is.null(df) && nrow(df) > 0) {
    df <- dplyr::distinct(df)
  }
  
  return(df)
}

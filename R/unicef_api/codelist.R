# R/codelist.R

#' @title List SDMX codelist for a given agency and codelist identifier
#' @description Download and cache the SDMX codelist definitions from a specified agency's REST endpoint.
#'
#' @param agency Character agency ID (e.g., "UNICEF").
#' @param codelist_id Character codelist identifier (e.g., "CL_UNICEF_INDICATOR").
#' @param retry Number of retries for HTTP failures; default is 3.
#' @param cache_dir Directory for on-disk cache; created if it does not exist.
#'
#' @return A tibble with columns `code`, `description`, and `name`.
#' @export
#' @importFrom xml2 read_xml xml_find_all xml_attr xml_find_first xml_text
#' @importFrom tibble tibble
#' @importFrom memoise memoise cache_filesystem
#' @importFrom tools R_user_dir
list_sdmx_codelist <- local({
  fn <- function(
    agency       = "UNICEF",
    codelist_id,                  # full codelist identifier, e.g. CL_UNICEF_INDICATOR
    retry        = 3L,
    cache_dir    = tools::R_user_dir("get_sdmx", "cache")
  ) {
    stopifnot(is.character(agency), length(agency) == 1L,
              is.character(codelist_id), length(codelist_id) == 1L)
    if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
    # Use the REST codelist endpoint
    url <- sprintf(
      "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/%s/%s/latest?format=sdmx-2.1&detail=full&references=none",
      agency, codelist_id
    )
    xml_text <- .fetch_sdmx(url, retry = retry)
    doc <- xml2::read_xml(xml_text)
    # match Code elements irrespective of namespace
    codes <- xml2::xml_find_all(doc, "//*[local-name()='Code']")
    tibble::tibble(
      code        = xml2::xml_attr(codes, "value"),
      description = xml2::xml_text(
        xml2::xml_find_first(codes, "./*[local-name()='Description' and @xml:lang='en']")
      ),
      name        = xml2::xml_text(
        xml2::xml_find_first(codes, "./*[local-name()='Name' and @xml:lang='en']")
      )
    )
  }
  cache <- memoise::cache_filesystem(tools::R_user_dir("get_sdmx", "cache"))
  memoise::memoise(fn, cache = cache)
})

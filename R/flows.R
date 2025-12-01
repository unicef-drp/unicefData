# R/flows.R

#' @title List available SDMX “flows” for an agency
#' @description Download and cache the SDMX dataflow definitions from a specified agency's REST endpoint.
#' @param agency Character agency ID (e.g., "UNICEF").
#' @param retry Number of retries for transient HTTP failures; default is 3.
#' @param cache_dir Directory for on-disk cache; created if it does not exist.
#' @return A tibble with columns `id`, `agency`, `version`, and `name`.
#' @export
#' @importFrom xml2 read_xml xml_find_all xml_attr xml_find_first xml_text
#' @importFrom tibble tibble
#' @importFrom memoise memoise cache_filesystem
#' @importFrom tools R_user_dir
list_sdmx_flows <- local({
  fn <- function(
    agency    = "UNICEF",
    retry     = 3L,
    cache_dir = tools::R_user_dir("get_sdmx", "cache")
  ) {
    if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
    # Use the dataflow endpoint to list all flows for an agency
    url <- sprintf(
      "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/%s?references=none&detail=full",
      agency
    )
    xml_text <- .fetch_sdmx(url, retry = retry)
    doc <- xml2::read_xml(xml_text)
    dfs <- xml2::xml_find_all(doc, ".//str:Dataflow")
    tibble::tibble(
      id      = xml2::xml_attr(dfs, "id"),
      agency  = xml2::xml_attr(dfs, "agencyID"),
      version = xml2::xml_attr(dfs, "version"),
      # Extract the English name/label of each flow
      name    = xml2::xml_text(
        xml2::xml_find_first(
          dfs,
          "./com:Name[@xml:lang='en']"
        )
      )
    )
  }
  cache <- memoise::cache_filesystem(tools::R_user_dir("get_sdmx", "cache"))
  memoise::memoise(fn, cache = cache)
})

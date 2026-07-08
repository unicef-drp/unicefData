# R/regions.R
# Country and Region Grouping Functions
#
# Retrieves dynamic country and region grouping data from the Solr index.

.get_solr_credentials <- function() {
  user <- Sys.getenv("UNICEF_SOLR_USER", "DAPMRead")
  pass <- Sys.getenv("UNICEF_SOLR_PASS", "solrread!")
  if (user == "") user <- "DAPMRead"
  if (pass == "") pass <- "solrread!"
  list(user = user, pass = pass)
}

#' Get all available source_agency, aggregate_type, and aggregate_type_id
#'
#' @return A tibble containing source_agency, aggregate_type, and aggregate_type_id columns.
#' @importFrom httr GET authenticate timeout stop_for_status content
#' @importFrom jsonlite fromJSON
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @export
get_regions_metadata <- function() {
  creds <- .get_solr_credentials()
  url <- "https://ss529626-pa5e13zk-westeurope-azure.searchstax.com/solr/country_regions_metadata/select"
  
  query <- list(
    q = "*:*",
    rows = 0,
    facet = "true",
    `facet.pivot` = "source_agency,aggregate_type,aggregate_type_id",
    wt = "json"
  )
  
  res <- httr::GET(
    url,
    query = query,
    httr::authenticate(creds$user, creds$pass),
    httr::timeout(60)
  )
  httr::stop_for_status(res)
  
  data <- jsonlite::fromJSON(
    httr::content(res, as = "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )
  pivots <- data$facet_counts$facet_pivot$`source_agency,aggregate_type,aggregate_type_id`
  
  records <- list()
  if (!is.null(pivots)) {
    for (agency_node in pivots) {
      agency <- agency_node$value
      if (!is.null(agency_node$pivot)) {
        for (type_node in agency_node$pivot) {
          agg_type <- type_node$value
          if (!is.null(type_node$pivot)) {
            for (id_node in type_node$pivot) {
              agg_type_id <- id_node$value
              records[[length(records) + 1]] <- tibble::tibble(
                source_agency = agency,
                aggregate_type = agg_type,
                aggregate_type_id = agg_type_id
              )
            }
          }
        }
      }
    }
  }
  
  if (length(records) == 0) {
    return(tibble::tibble(
      source_agency = character(),
      aggregate_type = character(),
      aggregate_type_id = character()
    ))
  }
  
  dplyr::bind_rows(records)
}

#' Get country and region grouping data from the Solr index
#'
#' @param source_agency Optional source agency filter (e.g., 'UNICEF').
#' @param aggregate_type_id Optional aggregate type ID filter (e.g., 'UNICEF_PROG_REG_GLOBAL').
#' @param is_latest Optional logical filter. If TRUE, returns only the latest active data.
#' @return A tibble containing regions and component countries.
#' @importFrom httr GET authenticate timeout stop_for_status content
#' @importFrom readr read_csv
#' @export
get_regions <- function(source_agency = NULL, aggregate_type_id = NULL, is_latest = FALSE) {
  creds <- .get_solr_credentials()
  url <- "https://ss529626-pa5e13zk-westeurope-azure.searchstax.com/solr/country_regions_metadata/select"
  
  query <- list(
    q = "*:*",
    rows = 1000000L,
    wt = "csv"
  )
  
  fq <- character()
  if (isTRUE(is_latest)) {
    fq <- c(fq, "is_latest:true")
  }
  if (!is.null(source_agency)) {
    fq <- c(fq, paste0("source_agency:", source_agency))
  }
  if (!is.null(aggregate_type_id)) {
    fq <- c(fq, paste0("aggregate_type_id:", aggregate_type_id))
  }
  
  # httr::GET expects multiple fq parameters in a list format for identical names
  # or query parameters. We can pass fq as a list when multiple, or pass one.
  if (length(fq) > 0) {
    # If there are multiple fq parameters, httr list query format handles multiple keys with same name
    # e.g., query = list(q = "*:*", fq = "is_latest:true", fq = "source_agency:UNICEF") is not valid R list,
    # but query = c(list(q = "*:*"), as.list(setNames(fq, rep("fq", length(fq))))) works!
    fq_list <- as.list(fq)
    names(fq_list) <- rep("fq", length(fq))
    query <- c(query, fq_list)
  }
  
  res <- httr::GET(
    url,
    query = query,
    httr::authenticate(creds$user, creds$pass),
    httr::timeout(60)
  )
  httr::stop_for_status(res)
  
  csv_text <- httr::content(res, as = "text", encoding = "UTF-8")
  readr::read_csv(
    csv_text,
    col_types = readr::cols(country_m49 = readr::col_character()),
    show_col_types = FALSE
  )
}

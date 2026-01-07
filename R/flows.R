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
  memo_env <- new.env(parent = emptyenv())

  fetch_flows <- function(
    agency    = "UNICEF",
    retry     = 3L,
    cache_dir = tools::R_user_dir("unicefdata", "cache")
  ) {
    if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)

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
      name    = xml2::xml_text(
        xml2::xml_find_first(dfs, "./com:Name[@xml:lang='en']")
      )
    )
  }

  get_memoised <- function(cache_dir) {
    key <- normalizePath(cache_dir, winslash = "/", mustWork = FALSE)
    if (!nzchar(key)) key <- cache_dir

    if (!exists(key, envir = memo_env, inherits = FALSE)) {
      cache <- memoise::cache_filesystem(cache_dir)
      assign(key, memoise::memoise(fetch_flows, cache = cache), envir = memo_env)
    }

    get(key, envir = memo_env, inherits = FALSE)
  }

  function(
    agency    = "UNICEF",
    retry     = 3L,
    cache_dir = tools::R_user_dir("unicefdata", "cache")
  ) {
    memoised_fn <- get_memoised(cache_dir)
    memoised_fn(agency = agency, retry = retry, cache_dir = cache_dir)
  }
})


#' @title Get dataflow schema information
#' @description Display the dimensions and attributes for a UNICEF dataflow.
#'   Reads from local YAML schema files in metadata/current/dataflows/.
#' @param dataflow Character. The dataflow ID (e.g., "CME", "EDUCATION").
#' @param metadata_dir Optional path to metadata directory. Auto-detected if NULL.
#' @return A list with components: id, name, version, agency, dimensions, attributes.
#' @export
#' @examples
#' \dontrun{
#' # Get schema for Child Mortality dataflow
#' schema <- dataflow_schema("CME")
#' print(schema$dimensions)
#' print(schema$attributes)
#' }
dataflow_schema <- function(dataflow, metadata_dir = NULL) {

  # Null coalescing operator
  `%||%` <- function(x, y) if (is.null(x)) y else x

  # Convert to uppercase
  df_upper <- toupper(dataflow)

  # Find metadata directory
  if (is.null(metadata_dir)) {
    metadata_dir <- .find_metadata_dir()
  }

  # Look for schema file
  schema_path <- file.path(metadata_dir, "dataflows", paste0(df_upper, ".yaml"))

  if (!file.exists(schema_path)) {
    # Fall back to _unicefdata_dataflows.yaml for basic info
    basic <- .get_basic_dataflow_info(df_upper, metadata_dir)
    if (!is.null(basic)) {
      message(sprintf("Note: Detailed schema not available for '%s'. Showing basic info.", df_upper))
      return(basic)
    }
    stop(sprintf("Dataflow '%s' not found. Use list_sdmx_flows() to see available dataflows.", df_upper))
  }

  # Parse YAML schema
  schema <- yaml::read_yaml(schema_path)

  # Extract dimensions (list of id values)
  dimensions <- if (!is.null(schema$dimensions)) {
    sapply(schema$dimensions, function(d) d$id)
  } else {
    character(0)
  }

  # Extract attributes (list of id values)
  attributes <- if (!is.null(schema$attributes)) {
    sapply(schema$attributes, function(a) a$id)
  } else {
    character(0)
  }

  result <- list(
    id = schema$id %||% df_upper,
    name = schema$name %||% "",
    version = schema$version %||% "",
    agency = schema$agency %||% "UNICEF",
    dimensions = dimensions,
    attributes = attributes,
    time_dimension = schema$time_dimension %||% "TIME_PERIOD",
    primary_measure = schema$primary_measure %||% "OBS_VALUE"
  )

  class(result) <- c("unicef_dataflow_schema", "list")
  result
}


#' Print method for dataflow schema
#' @param x A unicef_dataflow_schema object
#' @param ... Additional arguments (ignored)
#' @export
print.unicef_dataflow_schema <- function(x, ...) {
  cat("\n")
  cat(strrep("-", 70), "\n")
  cat("Dataflow Schema:", x$id, "\n")
  cat(strrep("-", 70), "\n")
  cat("\n")

  if (nzchar(x$name)) cat("Name:", x$name, "\n")
  if (nzchar(x$version)) cat("Version:", x$version, "\n")
  if (nzchar(x$agency)) cat("Agency:", x$agency, "\n")
  cat("\n")

  if (length(x$dimensions) > 0) {
    cat("Dimensions (", length(x$dimensions), "):\n", sep = "")
    for (d in x$dimensions) {
      cat("  ", d, "\n", sep = "")
    }
    cat("\n")
  }

  if (length(x$attributes) > 0) {
    cat("Attributes (", length(x$attributes), "):\n", sep = "")
    for (a in x$attributes) {
      cat("  ", a, "\n", sep = "")
    }
  }

  cat("\n")
  cat(strrep("-", 70), "\n")
  invisible(x)
}


#' Find metadata directory
#' @keywords internal
.find_metadata_dir <- function() {
  # 1. Environment override
  env_home <- Sys.getenv("UNICEF_DATA_HOME_R", Sys.getenv("UNICEF_DATA_HOME", ""))
  if (nzchar(env_home)) {
    metadata_dir <- file.path(env_home, "metadata", "current")
    if (dir.exists(metadata_dir)) return(metadata_dir)
  }

  # 2. Relative to working directory
  script_dir <- getwd()
  candidates <- c(
    file.path(script_dir, "R", "metadata", "current"),
    file.path(script_dir, "metadata", "current"),
    file.path(script_dir, "..", "R", "metadata", "current"),
    file.path(script_dir, "..", "metadata", "current")
  )
  for (path in candidates) {
    if (dir.exists(path)) return(normalizePath(path))
  }

  # 3. User cache directory
  if (exists("R_user_dir", envir = asNamespace("tools"))) {
    base_dir <- tryCatch(tools::R_user_dir("unicefdata", "cache"), error = function(e) "")
    if (nzchar(base_dir)) {
      metadata_dir <- file.path(base_dir, "metadata", "current")
      if (dir.exists(metadata_dir)) return(metadata_dir)
    }
  }

  # 4. Home directory fallback
  home_dir <- file.path(Sys.getenv("HOME"), ".unicef_data", "r", "metadata", "current")
  if (dir.exists(home_dir)) return(home_dir)

  stop("Could not find metadata directory. Run sync_metadata() first.")
}


#' Get basic dataflow info from _unicefdata_dataflows.yaml
#' @keywords internal
.get_basic_dataflow_info <- function(dataflow, metadata_dir) {
  `%||%` <- function(x, y) if (is.null(x)) y else x

  df_file <- file.path(metadata_dir, "_unicefdata_dataflows.yaml")
  if (!file.exists(df_file)) return(NULL)

  all_flows <- yaml::read_yaml(df_file)
  if (dataflow %in% names(all_flows)) {
    info <- all_flows[[dataflow]]
    return(list(
      id = dataflow,
      name = info$name %||% "",
      version = info$version %||% "",
      agency = "UNICEF",
      dimensions = character(0),
      attributes = character(0)
    ))
  }
  NULL
}

# =============================================================================
# Shared fixture path utilities for testthat tests
#
# Place this file in tests/testthat/ and source it from tests that need fixtures.
# Uses testthat::test_path() which works correctly during R CMD check.
# =============================================================================

#' Get the path to the deterministic fixtures directory
#'
#' Tries multiple locations to handle both interactive use and R CMD check.
#' During R CMD check, test_path() resolves paths relative to tests/testthat/.
#'
#' @return Character string path to fixtures directory
get_fixtures_dir <- function() {
  candidates <- c(
    testthat::test_path("..", "fixtures", "deterministic"),
    "tests/fixtures/deterministic",
    "fixtures/deterministic",
    file.path("..", "fixtures", "deterministic")
  )
  for (path in candidates) {
    if (dir.exists(path)) return(path)
  }
  # Return first candidate (will produce informative error if missing)
  candidates[1]
}

#' Get the path to the API fixtures directory (api_responses)
#'
#' @return Character string path to API fixtures directory
get_api_fixtures_dir <- function() {
  candidates <- c(
    testthat::test_path("..", "fixtures", "api_responses"),
    "tests/fixtures/api_responses",
    "fixtures/api_responses",
    file.path("..", "fixtures", "api_responses")
  )
  for (path in candidates) {
    if (dir.exists(path)) return(path)
  }
  candidates[1]
}

#' Get the path to the XML fixtures directory
#'
#' @return Character string path to XML fixtures directory
get_xml_fixtures_dir <- function() {
  candidates <- c(
    testthat::test_path("..", "fixtures", "xml"),
    "tests/fixtures/xml",
    "fixtures/xml",
    file.path("..", "fixtures", "xml")
  )
  for (path in candidates) {
    if (dir.exists(path)) return(path)
  }
  candidates[1]
}

#' Get the path to the YAML fixtures directory
#'
#' @return Character string path to YAML fixtures directory
get_yaml_fixtures_dir <- function() {
  candidates <- c(
    testthat::test_path("..", "fixtures", "yaml"),
    "tests/fixtures/yaml",
    "fixtures/yaml",
    file.path("..", "fixtures", "yaml")
  )
  for (path in candidates) {
    if (dir.exists(path)) return(path)
  }
  candidates[1]
}

#' Read a deterministic fixture CSV file
#'
#' @param filename Character. Filename within fixtures/deterministic/
#' @return data.frame
read_fixture <- function(filename) {
  path <- file.path(get_fixtures_dir(), filename)
  if (!file.exists(path)) {
    testthat::skip(paste("Fixture not found:", path))
  }
  read.csv(path, stringsAsFactors = FALSE)
}

#' Skip test if fixture directory is missing
#'
#' @param fixtures_dir Character. Path to fixtures directory to check
skip_if_no_fixtures <- function(fixtures_dir = get_fixtures_dir()) {
  if (!dir.exists(fixtures_dir)) {
    testthat::skip(paste("Fixtures directory not found:", fixtures_dir))
  }
}

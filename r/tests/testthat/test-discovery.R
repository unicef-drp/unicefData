# ===========================================================================
# Discovery Pipeline Tests (YAML -> output)
# ===========================================================================
# Tests that discovery functions correctly read YAML metadata and return
# consistent, accurate results. Uses shared YAML fixtures from
# tests/fixtures/yaml/.
#
# These tests verify Pipeline 2: YAML metadata -> user-facing discovery.
# All tests run offline using pre-loaded test YAML caches.
#
# Test IDs: DISC-01 through DISC-18
# ===========================================================================

library(testthat)

# ---------------------------------------------------------------------------
# Fixture paths and helpers
# ---------------------------------------------------------------------------
# helper-fixtures.R is auto-loaded by testthat from tests/testthat/
YAML_FIXTURES <- get_yaml_fixtures_dir()

load_test_indicators <- function() {
  yaml::read_yaml(file.path(YAML_FIXTURES, "unicef_indicators_metadata.yaml"))
}

load_test_dataflows <- function() {
  yaml::read_yaml(file.path(YAML_FIXTURES, "_unicefdata_dataflows.yaml"))
}

# ---------------------------------------------------------------------------
# Portable discovery functions (mirror indicator_registry.R logic)
# These work directly on YAML data without requiring the R package installed.
# ---------------------------------------------------------------------------

disc_get_dataflow_for_indicator <- function(indicator_code, indicators,
                                            default = "GLOBAL_DATAFLOW") {
  if (indicator_code %in% names(indicators)) {
    cat <- indicators[[indicator_code]]$category
    if (!is.null(cat) && nzchar(cat)) return(cat)
  }
  # Prefix inference
  prefix <- sub("_.*", "", indicator_code)
  prefix_map <- list(
    CME = "CME", NT = "NUTRITION", IM = "IMMUNISATION",
    ED = "EDUCATION", PT = "CHILD_PROTECTION", WS = "WASH_HOUSEHOLDS",
    HVA = "HIV_AIDS", DM = "DEMOGRAPHICS", ECD = "ECD",
    FT = "GENDER", PV = "CHLD_PVTY"
  )
  if (prefix %in% names(prefix_map)) return(prefix_map[[prefix]])
  default
}

disc_get_indicator_info <- function(indicator_code, indicators) {
  indicators[[indicator_code]]
}

disc_list_indicators <- function(indicators, dataflow = NULL, name_contains = NULL) {
  result <- indicators
  if (!is.null(dataflow)) {
    result <- Filter(function(x) identical(x$category, dataflow), result)
  }
  if (!is.null(name_contains)) {
    pattern <- tolower(name_contains)
    result <- Filter(function(x) grepl(pattern, tolower(x$name), fixed = TRUE), result)
  }
  result
}

disc_search_indicators <- function(indicators, query = NULL, category = NULL, limit = 50) {
  result <- indicators

  if (!is.null(category)) {
    result <- Filter(function(x) toupper(x$category) == toupper(category), result)
  }

  if (!is.null(query)) {
    q <- tolower(query)
    result <- Filter(function(x) {
      grepl(q, tolower(x$code), fixed = TRUE) ||
        grepl(q, tolower(x$name), fixed = TRUE) ||
        grepl(q, tolower(x$description %||% ""), fixed = TRUE)
    }, result)
  }

  if (limit > 0 && length(result) > limit) {
    result <- result[seq_len(limit)]
  }

  result
}


# ===========================================================================
# DISC-01 to DISC-05: get_dataflow_for_indicator
# ===========================================================================

test_that("DISC-01: CME_MRY0T4 resolves to CME dataflow", {
  indicators <- load_test_indicators()
  result <- disc_get_dataflow_for_indicator("CME_MRY0T4", indicators)
  expect_equal(result, "CME")
})

test_that("DISC-02: NT_ANT_HAZ_NE2 resolves to NUTRITION dataflow", {
  indicators <- load_test_indicators()
  result <- disc_get_dataflow_for_indicator("NT_ANT_HAZ_NE2", indicators)
  expect_equal(result, "NUTRITION")
})

test_that("DISC-03: IM_MCV1 resolves to IMMUNISATION dataflow", {
  indicators <- load_test_indicators()
  result <- disc_get_dataflow_for_indicator("IM_MCV1", indicators)
  expect_equal(result, "IMMUNISATION")
})

test_that("DISC-04: unknown indicator returns GLOBAL_DATAFLOW default", {
  indicators <- load_test_indicators()
  result <- disc_get_dataflow_for_indicator("NONEXISTENT_CODE", indicators)
  expect_equal(result, "GLOBAL_DATAFLOW")
})

test_that("DISC-05: prefix inference works for codes not in cache", {
  indicators <- load_test_indicators()
  # ED prefix not in test cache, but prefix map should resolve it
  result <- disc_get_dataflow_for_indicator("ED_SOME_NEW_IND", indicators)
  expect_equal(result, "EDUCATION")
})


# ===========================================================================
# DISC-06 to DISC-09: get_indicator_info
# ===========================================================================

test_that("DISC-06: known indicator returns list with name", {
  indicators <- load_test_indicators()
  info <- disc_get_indicator_info("CME_MRY0T4", indicators)
  expect_false(is.null(info))
  expect_equal(info$name, "Under-five mortality rate")
})

test_that("DISC-07: indicator info includes category", {
  indicators <- load_test_indicators()
  info <- disc_get_indicator_info("CME_MRY0T4", indicators)
  expect_equal(info$category, "CME")
})

test_that("DISC-08: unknown indicator returns NULL", {
  indicators <- load_test_indicators()
  info <- disc_get_indicator_info("TOTALLY_FAKE_IND", indicators)
  expect_null(info)
})

test_that("DISC-09: indicator info includes description", {
  indicators <- load_test_indicators()
  info <- disc_get_indicator_info("NT_ANT_HAZ_NE2", indicators)
  expect_true(grepl("stunted", info$description, ignore.case = TRUE))
})


# ===========================================================================
# DISC-10 to DISC-13: list_indicators
# ===========================================================================

test_that("DISC-10: list all indicators returns 5", {
  indicators <- load_test_indicators()
  result <- disc_list_indicators(indicators)
  expect_equal(length(result), 5)
})

test_that("DISC-11: filter by dataflow CME returns 2 indicators", {
  indicators <- load_test_indicators()
  result <- disc_list_indicators(indicators, dataflow = "CME")
  expect_equal(length(result), 2)
  expect_true("CME_MRY0T4" %in% names(result))
  expect_true("CME_MRY0" %in% names(result))
  expect_false("IM_MCV1" %in% names(result))
})

test_that("DISC-12: filter by name 'mortality' returns 2 matches", {
  indicators <- load_test_indicators()
  result <- disc_list_indicators(indicators, name_contains = "mortality")
  expect_equal(length(result), 2)
  expect_true("CME_MRY0T4" %in% names(result))
  expect_true("CME_MRY0" %in% names(result))
})

test_that("DISC-13: combined filters narrow results correctly", {
  indicators <- load_test_indicators()
  result <- disc_list_indicators(indicators, dataflow = "IMMUNISATION",
                                 name_contains = "measles")
  expect_equal(length(result), 1)
  expect_true("IM_MCV1" %in% names(result))
})


# ===========================================================================
# DISC-14 to DISC-16: search_indicators
# ===========================================================================

test_that("DISC-14: search 'mortality' finds CME indicators", {
  indicators <- load_test_indicators()
  result <- disc_search_indicators(indicators, query = "mortality")
  expect_true(length(result) >= 2)
  expect_true("CME_MRY0T4" %in% names(result))
})

test_that("DISC-15: search by category IMMUNISATION returns only IM indicators", {
  indicators <- load_test_indicators()
  result <- disc_search_indicators(indicators, category = "IMMUNISATION")
  expect_equal(length(result), 2)
  expect_true("IM_MCV1" %in% names(result))
  expect_true("IM_DTP3" %in% names(result))
  expect_false("CME_MRY0T4" %in% names(result))
})

test_that("DISC-16: search 'xyznonexistent' returns empty", {
  indicators <- load_test_indicators()
  result <- disc_search_indicators(indicators, query = "xyznonexistent")
  expect_equal(length(result), 0)
})


# ===========================================================================
# DISC-17 to DISC-18: Cross-format consistency
# ===========================================================================

test_that("DISC-17: indicator categories match dataflow IDs", {
  indicators <- load_test_indicators()
  dataflows <- load_test_dataflows()

  categories <- unique(vapply(indicators, function(x) x$category, character(1)))
  for (cat in categories) {
    expect_true(cat %in% names(dataflows),
                info = paste("Category", cat, "not found in dataflows YAML"))
  }
})

test_that("DISC-18: all CME indicators share same parent", {
  indicators <- load_test_indicators()
  cme_inds <- disc_list_indicators(indicators, dataflow = "CME")
  parents <- vapply(cme_inds, function(x) x$parent, character(1))
  expect_true(all(parents == "CME"))
})

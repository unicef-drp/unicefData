# ===========================================================================
# Sync Pipeline Tests (XML -> YAML)
# ===========================================================================
# Tests that SDMX XML codelist responses are parsed correctly into structured
# R objects. Uses shared XML fixtures from tests/fixtures/xml/.
#
# These tests verify Pipeline 1: XML -> YAML metadata sync.
# All tests run offline using XML fixture files (no HTTP calls).
#
# Test IDs: SYNC-01 through SYNC-12
# ===========================================================================

library(testthat)

# ---------------------------------------------------------------------------
# Fixture paths (using shared helper for R CMD check compatibility)
# ---------------------------------------------------------------------------
# helper-fixtures.R is auto-loaded by testthat from tests/testthat/
XML_FIXTURES <- get_xml_fixtures_dir()
API_FIXTURES <- get_api_fixtures_dir()
YAML_FIXTURES <- get_yaml_fixtures_dir()


# ---------------------------------------------------------------------------
# XML parsing helper (mirrors what metadata_sync.R does internally)
# ---------------------------------------------------------------------------

parse_codelist_xml <- function(xml_path) {
  if (!requireNamespace("xml2", quietly = TRUE)) {
    skip("xml2 package not available")
  }

  doc <- xml2::read_xml(xml_path)

  ns <- c(
    mes = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message",
    str = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure",
    com = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common"
  )

  codes <- xml2::xml_find_all(doc, ".//str:Code", ns)

  result <- list()
  for (code_node in codes) {
    id <- xml2::xml_attr(code_node, "id")
    name_node <- xml2::xml_find_first(code_node, ".//com:Name", ns)
    name <- if (!is.na(xml2::xml_text(name_node))) xml2::xml_text(name_node) else ""

    desc_node <- xml2::xml_find_first(code_node, ".//com:Description", ns)
    description <- if (!is.null(desc_node) && !is.na(xml2::xml_text(desc_node))) {
      xml2::xml_text(desc_node)
    } else {
      ""
    }

    parent_node <- xml2::xml_find_first(code_node, "str:Parent/Ref", ns)
    parent <- if (!is.null(parent_node) && !is.na(xml2::xml_attr(parent_node, "id"))) {
      xml2::xml_attr(parent_node, "id")
    } else {
      NA_character_
    }

    result[[id]] <- list(
      code = id,
      name = name,
      description = description,
      parent = parent
    )
  }

  result
}

parse_dataflows_xml <- function(xml_path) {
  if (!requireNamespace("xml2", quietly = TRUE)) {
    skip("xml2 package not available")
  }

  doc <- xml2::read_xml(xml_path)

  # The test fixture uses different namespace prefixes than the real API
  # but the URIs are the same. Try both prefix sets.
  ns_real <- c(
    str = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure",
    com = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common"
  )
  ns_test <- c(
    s = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure",
    common = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common"
  )

  # Try with str: prefix first
  flows <- xml2::xml_find_all(doc, ".//str:Dataflow", ns_real)
  ns_used <- ns_real
  name_prefix <- "com"

  # Fall back to s: prefix
  if (length(flows) == 0) {
    flows <- xml2::xml_find_all(doc, ".//s:Dataflow", ns_test)
    ns_used <- ns_test
    name_prefix <- "common"
  }

  result <- list()
  for (flow in flows) {
    id <- xml2::xml_attr(flow, "id")
    agency <- xml2::xml_attr(flow, "agencyID")
    version <- xml2::xml_attr(flow, "version")
    name_node <- xml2::xml_find_first(flow, paste0(".//", name_prefix, ":Name"), ns_used)
    name <- if (!is.na(xml2::xml_text(name_node))) xml2::xml_text(name_node) else ""

    result[[id]] <- list(
      id = id,
      name = name,
      version = version,
      agency = agency
    )
  }

  result
}

# ===========================================================================
# SYNC-01 to SYNC-04: Dataflow list parsing
# ===========================================================================

test_that("SYNC-01: dataflows XML parsed into list of 4 dataflows", {
  skip_if(!file.exists(file.path(API_FIXTURES, "dataflows.xml")),
          "dataflows.xml fixture not found")

  result <- parse_dataflows_xml(file.path(API_FIXTURES, "dataflows.xml"))
  expect_equal(length(result), 4)
  expect_true("CME" %in% names(result))
  expect_true("NUTRITION" %in% names(result))
  expect_true("GLOBAL_DATAFLOW" %in% names(result))
})

test_that("SYNC-02: each dataflow has id, name, version, agency", {
  skip_if(!file.exists(file.path(API_FIXTURES, "dataflows.xml")),
          "dataflows.xml fixture not found")

  result <- parse_dataflows_xml(file.path(API_FIXTURES, "dataflows.xml"))
  for (nm in names(result)) {
    expect_true("id" %in% names(result[[nm]]), info = paste("Missing 'id' in", nm))
    expect_true("name" %in% names(result[[nm]]), info = paste("Missing 'name' in", nm))
    expect_true("version" %in% names(result[[nm]]), info = paste("Missing 'version' in", nm))
    expect_true("agency" %in% names(result[[nm]]), info = paste("Missing 'agency' in", nm))
  }
})

test_that("SYNC-03: dataflow names parsed correctly", {
  skip_if(!file.exists(file.path(API_FIXTURES, "dataflows.xml")),
          "dataflows.xml fixture not found")

  result <- parse_dataflows_xml(file.path(API_FIXTURES, "dataflows.xml"))
  expect_equal(result[["CME"]]$name, "Child Mortality Estimates")
  expect_equal(result[["NUTRITION"]]$name, "Nutrition")
})

test_that("SYNC-04: dataflow agency is UNICEF for all entries", {
  skip_if(!file.exists(file.path(API_FIXTURES, "dataflows.xml")),
          "dataflows.xml fixture not found")

  result <- parse_dataflows_xml(file.path(API_FIXTURES, "dataflows.xml"))
  for (nm in names(result)) {
    expect_equal(result[[nm]]$agency, "UNICEF", info = paste("Wrong agency for", nm))
  }
})


# ===========================================================================
# SYNC-05 to SYNC-09: Codelist XML parsing
# ===========================================================================

test_that("SYNC-05: indicator codelist XML extracts all 5 indicators", {
  skip_if(!file.exists(file.path(XML_FIXTURES, "codelist_indicators.xml")),
          "codelist_indicators.xml fixture not found")

  result <- parse_codelist_xml(file.path(XML_FIXTURES, "codelist_indicators.xml"))
  expect_equal(length(result), 5)
  expect_true("CME_MRY0T4" %in% names(result))
  expect_true("NT_ANT_HAZ_NE2" %in% names(result))
  expect_true("IM_MCV1" %in% names(result))
})

test_that("SYNC-06: indicator has name and description", {
  skip_if(!file.exists(file.path(XML_FIXTURES, "codelist_indicators.xml")),
          "codelist_indicators.xml fixture not found")

  result <- parse_codelist_xml(file.path(XML_FIXTURES, "codelist_indicators.xml"))
  cme <- result[["CME_MRY0T4"]]
  expect_equal(cme$name, "Under-five mortality rate")
  expect_true(grepl("birth", cme$description, ignore.case = TRUE))
})

test_that("SYNC-07: indicator parent hierarchy parsed", {
  skip_if(!file.exists(file.path(XML_FIXTURES, "codelist_indicators.xml")),
          "codelist_indicators.xml fixture not found")

  result <- parse_codelist_xml(file.path(XML_FIXTURES, "codelist_indicators.xml"))
  expect_equal(result[["CME_MRY0T4"]]$parent, "CME")
  expect_equal(result[["NT_ANT_HAZ_NE2"]]$parent, "NUTRITION")
  expect_equal(result[["IM_MCV1"]]$parent, "IMMUNISATION")
})

test_that("SYNC-08: country codelist XML extracts 5 countries", {
  skip_if(!file.exists(file.path(XML_FIXTURES, "codelist_countries.xml")),
          "codelist_countries.xml fixture not found")

  result <- parse_codelist_xml(file.path(XML_FIXTURES, "codelist_countries.xml"))
  expect_equal(length(result), 5)
  expect_true("USA" %in% names(result))
  expect_true("BRA" %in% names(result))
  expect_equal(result[["USA"]]$name, "United States of America")
})

test_that("SYNC-09: region codelist XML extracts 3 regions with parents", {
  skip_if(!file.exists(file.path(XML_FIXTURES, "codelist_regions.xml")),
          "codelist_regions.xml fixture not found")

  result <- parse_codelist_xml(file.path(XML_FIXTURES, "codelist_regions.xml"))
  expect_equal(length(result), 3)
  expect_true("UNDEV_002" %in% names(result))
  expect_equal(result[["UNDEV_002"]]$name, "Africa")
  expect_equal(result[["UNDEV_002"]]$parent, "UNDEV_LD")
})


# ===========================================================================
# SYNC-10 to SYNC-12: Cross-format consistency (XML vs YAML fixtures)
# ===========================================================================

test_that("SYNC-10: XML and YAML dataflow counts match", {
  skip_if(!file.exists(file.path(API_FIXTURES, "dataflows.xml")),
          "dataflows.xml fixture not found")
  skip_if(!file.exists(file.path(YAML_FIXTURES, "_unicefdata_dataflows.yaml")),
          "YAML dataflows fixture not found")

  xml_result <- parse_dataflows_xml(file.path(API_FIXTURES, "dataflows.xml"))
  yaml_data <- yaml::read_yaml(file.path(YAML_FIXTURES, "_unicefdata_dataflows.yaml"))

  expect_equal(length(xml_result), length(yaml_data))
})

test_that("SYNC-11: XML and YAML indicator counts match", {
  skip_if(!file.exists(file.path(XML_FIXTURES, "codelist_indicators.xml")),
          "codelist_indicators.xml fixture not found")
  skip_if(!file.exists(file.path(YAML_FIXTURES, "unicef_indicators_metadata.yaml")),
          "YAML indicators fixture not found")

  xml_result <- parse_codelist_xml(file.path(XML_FIXTURES, "codelist_indicators.xml"))
  yaml_data <- yaml::read_yaml(file.path(YAML_FIXTURES, "unicef_indicators_metadata.yaml"))

  expect_equal(length(xml_result), length(yaml_data))
})

test_that("SYNC-12: XML and YAML indicator names match", {
  skip_if(!file.exists(file.path(XML_FIXTURES, "codelist_indicators.xml")),
          "codelist_indicators.xml fixture not found")
  skip_if(!file.exists(file.path(YAML_FIXTURES, "unicef_indicators_metadata.yaml")),
          "YAML indicators fixture not found")

  xml_result <- parse_codelist_xml(file.path(XML_FIXTURES, "codelist_indicators.xml"))
  yaml_data <- yaml::read_yaml(file.path(YAML_FIXTURES, "unicef_indicators_metadata.yaml"))

  for (code in names(yaml_data)) {
    expect_true(code %in% names(xml_result),
                info = paste("Indicator", code, "in YAML but not XML"))
    expect_equal(xml_result[[code]]$name, yaml_data[[code]]$name,
                 info = paste("Name mismatch for", code))
  }
})

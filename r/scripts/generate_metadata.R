#!/usr/bin/env Rscript
# ============================================================================
# R Metadata Generation Script
#
# Generates R metadata YAMLs following the common schema.
# Writes to: R/metadata/current/
#
# Each language maintains independent YAMLs with native generation.
# All follow the same schema, logic, and collect the same data.
#
# Date: 2026-01-25
# Version: 2.0.0
# ============================================================================

cat("\n")
cat("========================================================================\n")
cat("R Metadata Generation\n")
cat("========================================================================\n")
cat("\n")

# Load required packages
suppressPackageStartupMessages({
  library(yaml)
  library(httr)
  library(xml2)
})

# Configuration
BASE_URL <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
AGENCY <- "UNICEF"
METADATA_VERSION <- "2.0.0"

# Determine output directory
# Use R/metadata/current/ relative to repo root

# Get script directory (works with both source() and Rscript)
get_script_dir <- function() {
  if (!is.null(sys.frames()[[1]]$ofile)) {
    # Running via source()
    return(dirname(sys.frames()[[1]]$ofile))
  } else {
    # Running via Rscript
    cmdArgs <- commandArgs(trailingOnly = FALSE)
    needle <- "--file="
    match <- grep(needle, cmdArgs)
    if (length(match) > 0) {
      return(dirname(normalizePath(sub(needle, "", cmdArgs[match]))))
    } else {
      # Fallback to current directory
      return(getwd())
    }
  }
}

script_dir <- get_script_dir()
repo_root <- dirname(dirname(script_dir))
output_dir <- file.path(repo_root, "R", "metadata", "current")

# Create output directory if it doesn't exist
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat(sprintf("Created directory: %s\n", output_dir))
}

cat(sprintf("Output directory: %s\n", output_dir))
cat("\n")

# Get current timestamp (ISO 8601)
synced_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
vintage_date <- format(Sys.Date(), "%Y-%m-%d")

cat(sprintf("Timestamp: %s\n", synced_at))
cat(sprintf("Vintage: %s\n", vintage_date))
cat("========================================================================\n")
cat("\n")

# ============================================================================
# Helper Functions
# ============================================================================

# Fetch XML from API
fetch_xml <- function(url) {
  cat(sprintf("  Fetching: %s\n", url))

  response <- tryCatch({
    GET(url, timeout(60))
  }, error = function(e) {
    stop(sprintf("Failed to fetch URL: %s\nError: %s", url, e$message))
  })

  if (status_code(response) != 200) {
    stop(sprintf("HTTP %d: %s", status_code(response), url))
  }

  content(response, as = "text", encoding = "UTF-8")
}

# Parse SDMX XML to extract dataflows
parse_dataflows <- function(xml_text) {
  doc <- read_xml(xml_text)

  # Register namespace
  ns <- xml_ns(doc)
  if (length(ns) == 0) {
    ns <- c(str = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure",
            com = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common")
  }

  # Extract dataflows
  dataflow_nodes <- xml_find_all(doc, ".//str:Dataflow", ns)

  dataflows <- list()
  for (node in dataflow_nodes) {
    df_id <- xml_attr(node, "id")
    df_version <- xml_attr(node, "version")
    df_name_node <- xml_find_first(node, ".//com:Name[@xml:lang='en']", ns)
    df_name <- if (!is.na(df_name_node)) xml_text(df_name_node) else ""
    df_desc_node <- xml_find_first(node, ".//com:Description[@xml:lang='en']", ns)
    df_desc <- if (!is.na(df_desc_node)) xml_text(df_desc_node) else NULL

    if (!is.null(df_id) && !is.na(df_id)) {
      dataflows[[df_id]] <- list(
        id = df_id,
        name = df_name,
        agency = AGENCY,
        version = df_version,
        description = df_desc,
        dimensions = NULL,
        indicators = NULL,
        last_updated = synced_at
      )
    }
  }

  dataflows
}

# Parse SDMX codelist XML
parse_codelist <- function(xml_text, codelist_id) {
  doc <- read_xml(xml_text)

  ns <- xml_ns(doc)
  if (length(ns) == 0) {
    ns <- c(str = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure",
            com = "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common")
  }

  # Get codelist name
  codelist_node <- xml_find_first(doc, ".//str:Codelist", ns)
  codelist_name_node <- xml_find_first(codelist_node, ".//com:Name[@xml:lang='en']", ns)
  codelist_name <- if (!is.na(codelist_name_node)) xml_text(codelist_name_node) else codelist_id

  # Extract codes
  code_nodes <- xml_find_all(doc, ".//str:Code", ns)

  codes <- list()
  for (node in code_nodes) {
    code_id <- xml_attr(node, "id")
    name_node <- xml_find_first(node, ".//com:Name[@xml:lang='en']", ns)
    code_name <- if (!is.na(name_node)) xml_text(name_node) else code_id

    if (!is.null(code_id) && !is.na(code_id)) {
      codes[[code_id]] <- code_name
    }
  }

  list(
    id = codelist_id,
    name = codelist_name,
    codes = codes
  )
}

# ============================================================================
# 1. Generate Dataflows YAML
# ============================================================================

cat("1. Generating dataflows metadata...\n")

url <- sprintf("%s/dataflow/%s?references=none&detail=full", BASE_URL, AGENCY)
xml_text <- fetch_xml(url)
dataflows <- parse_dataflows(xml_text)

cat(sprintf("  Found %d dataflows\n", length(dataflows)))

# Write dataflows YAML
outfile <- file.path(output_dir, "_unicefdata_dataflows.yaml")
dataflows_yaml <- list(
  `_metadata` = list(
    platform = "R",
    version = METADATA_VERSION,
    synced_at = synced_at,
    source = url,
    agency = AGENCY,
    content_type = "dataflows",
    total_dataflows = length(dataflows)
  ),
  dataflows = dataflows
)

write_yaml(dataflows_yaml, outfile)
cat(sprintf("  ✓ Written: %s\n", outfile))
cat("\n")

# ============================================================================
# 2. Generate Indicators YAML
# ============================================================================

cat("2. Generating indicators metadata...\n")

url <- sprintf("%s/codelist/%s/CL_UNICEF_INDICATOR/latest", BASE_URL, AGENCY)
xml_text <- fetch_xml(url)
codelist_data <- parse_codelist(xml_text, "CL_UNICEF_INDICATOR")

cat(sprintf("  Found %d indicators\n", length(codelist_data$codes)))

# Build indicators structure
indicators <- list()
for (code_id in names(codelist_data$codes)) {
  indicators[[code_id]] <- list(
    code = code_id,
    name = codelist_data$codes[[code_id]],
    dataflow = NULL  # Phase 1: No dataflow mapping yet
  )
}

# Write indicators YAML
outfile <- file.path(output_dir, "_unicefdata_indicators.yaml")
indicators_yaml <- list(
  `_metadata` = list(
    platform = "R",
    version = METADATA_VERSION,
    synced_at = synced_at,
    source = url,
    agency = AGENCY,
    content_type = "indicators",
    total_indicators = length(indicators),
    codelist_id = "CL_UNICEF_INDICATOR",
    codelist_name = codelist_data$name
  ),
  indicators = indicators
)

write_yaml(indicators_yaml, outfile)
cat(sprintf("  ✓ Written: %s\n", outfile))
cat("\n")

# ============================================================================
# 3. Generate Countries YAML
# ============================================================================

cat("3. Generating countries metadata...\n")

url <- sprintf("%s/codelist/%s/CL_COUNTRY/latest", BASE_URL, AGENCY)
xml_text <- fetch_xml(url)
codelist_data <- parse_codelist(xml_text, "CL_COUNTRY")

cat(sprintf("  Found %d countries\n", length(codelist_data$codes)))

# Write countries YAML
outfile <- file.path(output_dir, "_unicefdata_countries.yaml")
countries_yaml <- list(
  `_metadata` = list(
    platform = "R",
    version = METADATA_VERSION,
    synced_at = synced_at,
    source = url,
    agency = AGENCY,
    content_type = "countries",
    total_countries = length(codelist_data$codes),
    codelist_id = "CL_COUNTRY",
    codelist_name = codelist_data$name
  ),
  countries = codelist_data$codes
)

write_yaml(countries_yaml, outfile)
cat(sprintf("  ✓ Written: %s\n", outfile))
cat("\n")

# ============================================================================
# 4. Generate Regions YAML
# ============================================================================

cat("4. Generating regions metadata...\n")

url <- sprintf("%s/codelist/%s/CL_WORLD_REGIONS/latest", BASE_URL, AGENCY)
xml_text <- fetch_xml(url)
codelist_data <- parse_codelist(xml_text, "CL_WORLD_REGIONS")

cat(sprintf("  Found %d regions\n", length(codelist_data$codes)))

# Write regions YAML
outfile <- file.path(output_dir, "_unicefdata_regions.yaml")
regions_yaml <- list(
  `_metadata` = list(
    platform = "R",
    version = METADATA_VERSION,
    synced_at = synced_at,
    source = url,
    agency = AGENCY,
    content_type = "regions",
    total_regions = length(codelist_data$codes),
    codelist_id = "CL_WORLD_REGIONS",
    codelist_name = codelist_data$name
  ),
  regions = codelist_data$codes
)

write_yaml(regions_yaml, outfile)
cat(sprintf("  ✓ Written: %s\n", outfile))
cat("\n")

# ============================================================================
# 5. Generate Codelists YAML
# ============================================================================

cat("5. Generating codelists metadata...\n")

# Standard codelists (matching Python/Stata)
codelist_ids <- c("CL_AGE", "CL_WEALTH_QUINTILE", "CL_RESIDENCE",
                  "CL_UNIT_MEASURE", "CL_OBS_STATUS")

all_codelists <- list()
for (cl_id in codelist_ids) {
  tryCatch({
    url <- sprintf("%s/codelist/%s/%s/latest", BASE_URL, AGENCY, cl_id)
    xml_text <- fetch_xml(url)
    cl_data <- parse_codelist(xml_text, cl_id)

    all_codelists[[cl_id]] <- list(
      id = cl_id,
      agency = AGENCY,
      version = "latest",
      codes = cl_data$codes
    )

    cat(sprintf("  ✓ %s: %d codes\n", cl_id, length(cl_data$codes)))
  }, error = function(e) {
    cat(sprintf("  ✗ %s: %s\n", cl_id, e$message))
  })
}

# Write codelists YAML
outfile <- file.path(output_dir, "_unicefdata_codelists.yaml")

codes_per_list <- lapply(all_codelists, function(cl) length(cl$codes))

codelists_yaml <- list(
  `_metadata` = list(
    platform = "R",
    version = METADATA_VERSION,
    synced_at = synced_at,
    source = sprintf("%s/codelist/%s", BASE_URL, AGENCY),
    agency = AGENCY,
    content_type = "codelists",
    total_codelists = length(all_codelists),
    codes_per_list = codes_per_list
  ),
  codelists = all_codelists
)

write_yaml(codelists_yaml, outfile)
cat(sprintf("  ✓ Written: %s\n", outfile))
cat("\n")

# ============================================================================
# Summary
# ============================================================================

cat("========================================================================\n")
cat("Summary\n")
cat("========================================================================\n")
cat(sprintf("  Dataflows:   %d\n", length(dataflows)))
cat(sprintf("  Indicators:  %d\n", length(indicators)))
cat(sprintf("  Countries:   %d\n", length(countries_yaml$countries)))
cat(sprintf("  Regions:     %d\n", length(regions_yaml$regions)))
cat(sprintf("  Codelists:   %d\n", length(all_codelists)))
cat(sprintf("  Vintage:     %s\n", vintage_date))
cat(sprintf("  Output:      %s\n", output_dir))
cat("========================================================================\n")
cat("\nR metadata generation complete! ✓\n")
cat("\n")

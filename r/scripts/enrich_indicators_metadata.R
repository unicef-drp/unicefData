#!/usr/bin/env Rscript
#' R Indicator Metadata Enrichment Script
#' =======================================
#'
#' Enriches indicator metadata with:
#' - dataflows: List of dataflows containing each indicator
#' - tier: Classification (1=verified, 4=no dataflow)
#' - tier_reason: Explanation of tier assignment
#' - disaggregations: Available disaggregation dimensions
#' - disaggregations_with_totals: Dimensions that have total values
#'
#' Based on Stata's enrichment pipeline but adapted for R.
#'
#' Usage:
#'     Rscript enrich_indicators_metadata.R
#'
#' This will:
#' 1. Load base indicators from Stata (source of truth)
#' 2. Load dataflow mapping from Stata
#' 3. Load dataflow metadata from Stata
#' 4. Generate enriched metadata in R format
#' 5. Save to R/metadata/current/_unicefdata_indicators_metadata.yaml
#'
#' Author: Claude Code
#' Date: 2026-01-25

library(yaml)

cat("\n================================================================================\n")
cat("R INDICATOR METADATA ENRICHMENT\n")
cat("================================================================================\n\n")

# Determine paths
if (sys.nframe() == 0) {
  # Running via Rscript
  script_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", script_args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg)
    script_dir <- dirname(normalizePath(script_path))
  } else {
    script_dir <- getwd()
  }
} else {
  # Running interactively
  script_dir <- dirname(sys.frame(1)$ofile)
}
repo_root <- normalizePath(file.path(script_dir, "..", ".."))

# Input files (Stata is source of truth)
stata_dir <- file.path(repo_root, "stata", "src", "_")
r_dir <- file.path(repo_root, "R", "metadata", "current")

base_indicators_file <- file.path(stata_dir, "_unicefdata_indicators.yaml")
dataflow_map_file <- file.path(stata_dir, "_indicator_dataflow_map.yaml")
dataflow_metadata_file <- file.path(stata_dir, "_unicefdata_dataflow_metadata.yaml")
output_file <- file.path(r_dir, "_unicefdata_indicators_metadata.yaml")

cat("Inputs:\n")
cat(sprintf("  Base indicators:  %s\n", base_indicators_file))
cat(sprintf("  Dataflow map:     %s\n", dataflow_map_file))
cat(sprintf("  Dataflow dims:    %s\n", dataflow_metadata_file))
cat("Output:\n")
cat(sprintf("  Enriched file:    %s\n", output_file))
cat("\n")

# =========================================================================
# Helper functions
# =========================================================================

normalize_dataflows_to_list <- function(value) {
  if (is.null(value)) {
    return(list())
  } else if (is.character(value)) {
    return(as.list(value))
  } else if (is.list(value)) {
    return(value)
  } else {
    return(list())
  }
}

sort_dataflows_global_last <- function(dataflows) {
  #' Sort dataflows alphabetically but always put GLOBAL_DATAFLOW last.
  #'
  #' GLOBAL_DATAFLOW is the generic catch-all dataflow with fewer disaggregation
  #' dimensions. More specific dataflows (NUTRITION, EDUCATION, etc.) should be
  #' listed first so auto-detection picks the richer dataflow.

  # Handle NULL or empty
  if (is.null(dataflows) || length(dataflows) == 0) {
    return(dataflows)
  }

  # Handle single string value
  if (is.character(dataflows) && length(dataflows) == 1) {
    return(dataflows)
  }

  # Convert to vector if list
  df_vector <- unlist(dataflows)

  # Separate GLOBAL_DATAFLOW from others
  other_flows <- sort(df_vector[df_vector != "GLOBAL_DATAFLOW"])

  # Append GLOBAL_DATAFLOW at the end if present
  if ("GLOBAL_DATAFLOW" %in% df_vector) {
    other_flows <- c(other_flows, "GLOBAL_DATAFLOW")
  }

  return(as.list(other_flows))
}

classify_tier <- function(indicator_code, has_metadata, has_data) {
  #' Classify indicator into tier based on metadata and data availability.
  #'
  #' Tier system (revised):
  #'   tier 1: Has metadata + Has data (in codelist + has dataflow mapping)
  #'   tier 2: Has metadata - No data (in codelist, no dataflow mapping)
  #'   tier 3: No metadata + Has data (in dataflows but not in codelist)
  #'
  #' Args:
  #'   indicator_code: Indicator code
  #'   has_metadata: TRUE if indicator exists in CL_UNICEF_INDICATOR codelist
  #'   has_data: TRUE if indicator has dataflow mapping
  #'
  #' Returns:
  #'   list(tier, tier_reason)

  if (has_metadata && has_data) {
    return(list(tier = 1, tier_reason = "metadata_and_data"))
  } else if (has_metadata && !has_data) {
    return(list(tier = 2, tier_reason = "metadata_only_no_data"))
  } else if (!has_metadata && has_data) {
    return(list(tier = 3, tier_reason = "data_only_no_metadata"))
  } else {
    # Edge case: neither metadata nor data (shouldn't happen)
    return(list(tier = NA, tier_reason = "invalid_state"))
  }
}

# =========================================================================
# Step 1: Load base indicator metadata
# =========================================================================
cat("[Step 1/5] Loading base indicator metadata...\n")

if (!file.exists(base_indicators_file)) {
  stop(sprintf("ERROR: File not found: %s", base_indicators_file))
}

base_data <- yaml::yaml.load_file(base_indicators_file)

if (!"indicators" %in% names(base_data)) {
  stop("ERROR: No 'indicators' key in base metadata")
}

indicators_dict <- base_data$indicators
cat(sprintf("  Loaded %d indicators\n", length(indicators_dict)))

# =========================================================================
# Step 2: Add `dataflows` field from indicator_dataflow_map
# =========================================================================
cat("\n[Step 2/5] Adding dataflows field...\n")

if (!file.exists(dataflow_map_file)) {
  warning(sprintf("File not found: %s", dataflow_map_file))
  indicator_to_dataflow <- list()
} else {
  dataflow_map <- yaml::yaml.load_file(dataflow_map_file)
  indicator_to_dataflow <- dataflow_map$indicator_to_dataflow
  if (is.null(indicator_to_dataflow)) {
    indicator_to_dataflow <- list()
  }
}

dataflows_added <- 0
for (indicator_code in names(indicators_dict)) {
  if (indicator_code %in% names(indicator_to_dataflow)) {
    # Sort dataflows with GLOBAL_DATAFLOW always last
    indicators_dict[[indicator_code]]$dataflows <- sort_dataflows_global_last(indicator_to_dataflow[[indicator_code]])
    dataflows_added <- dataflows_added + 1
  }
}

cat(sprintf("  Added dataflows to %d indicators\n", dataflows_added))

# =========================================================================
# Step 3: Add `tier` and `tier_reason` fields
# =========================================================================
cat("\n[Step 3/5] Adding tier classification...\n")

tier_counts <- list(tier_1 = 0, tier_2 = 0, tier_3 = 0)

for (indicator_code in names(indicators_dict)) {
  # All indicators from base file have metadata (from CL_UNICEF_INDICATOR)
  has_metadata <- TRUE
  # Has data if dataflow mapping exists
  has_data <- indicator_code %in% names(indicator_to_dataflow) && !is.null(indicator_to_dataflow[[indicator_code]])

  tier_result <- classify_tier(indicator_code, has_metadata, has_data)

  indicators_dict[[indicator_code]]$tier <- tier_result$tier
  indicators_dict[[indicator_code]]$tier_reason <- tier_result$tier_reason

  tier_key <- paste0("tier_", tier_result$tier)
  tier_counts[[tier_key]] <- tier_counts[[tier_key]] + 1
}

cat(sprintf("  Tier 1 (metadata + data):     %d\n", tier_counts$tier_1))
cat(sprintf("  Tier 2 (metadata, no data):   %d\n", tier_counts$tier_2))
cat(sprintf("  Tier 3 (data, no metadata):   %d\n", tier_counts$tier_3))

# =========================================================================
# Step 4: Add `disaggregations` and `disaggregations_with_totals` fields
# =========================================================================
cat("\n[Step 4/5] Adding disaggregations...\n")

if (!file.exists(dataflow_metadata_file)) {
  warning(sprintf("File not found: %s", dataflow_metadata_file))
  dataflows_dict <- list()
} else {
  dataflows_metadata <- yaml::yaml.load_file(dataflow_metadata_file)
  dataflows_dict <- dataflows_metadata$dataflows
  if (is.null(dataflows_dict)) {
    dataflows_dict <- list()
  }
}

enriched_count <- 0
skipped_count <- 0

for (indicator_code in names(indicators_dict)) {
  dataflows_value <- indicators_dict[[indicator_code]]$dataflows

  if (is.null(dataflows_value) || length(dataflows_value) == 0) {
    skipped_count <- skipped_count + 1
    next
  }

  # Normalize to list
  dataflows_list <- normalize_dataflows_to_list(dataflows_value)

  # Use first dataflow (primary)
  dataflow_id <- dataflows_list[[1]]

  if (!dataflow_id %in% names(dataflows_dict)) {
    skipped_count <- skipped_count + 1
    next
  }

  # Get dimensions for this dataflow
  dataflow_data <- dataflows_dict[[dataflow_id]]
  if (is.null(dataflow_data$dimensions)) {
    skipped_count <- skipped_count + 1
    next
  }

  # Build disaggregations lists
  dimensions <- dataflow_data$dimensions
  all_disaggregations <- c()
  disaggregations_with_totals <- c()

  for (dim_name in sort(names(dimensions))) {
    if (dim_name == "INDICATOR") {
      next  # Skip INDICATOR dimension
    }

    dim_values <- dimensions[[dim_name]]$values
    if (is.null(dim_values)) {
      dim_values <- c()
    }

    has_total <- "_T" %in% dim_values

    all_disaggregations <- c(all_disaggregations, dim_name)

    if (has_total) {
      disaggregations_with_totals <- c(disaggregations_with_totals, dim_name)
    }
  }

  # Add to indicator
  if (length(all_disaggregations) > 0) {
    indicators_dict[[indicator_code]]$disaggregations <- as.list(all_disaggregations)
    indicators_dict[[indicator_code]]$disaggregations_with_totals <- as.list(disaggregations_with_totals)
    enriched_count <- enriched_count + 1
  } else {
    skipped_count <- skipped_count + 1
  }
}

cat(sprintf("  Enriched: %d indicators\n", enriched_count))
cat(sprintf("  Skipped:  %d indicators (no dataflow/dimensions)\n", skipped_count))

# =========================================================================
# Step 5: Create metadata header
# =========================================================================
cat("\n[Step 5/5] Creating metadata header...\n")

# Create enriched data structure
timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
enriched_data <- list(
  `_metadata` = list(
    # Standard metadata fields
    platform = "R",
    version = "2.1.0",
    synced_at = timestamp,
    source = "UNICEF SDMX Codelist CL_UNICEF_INDICATOR",
    agency = "UNICEF",
    content_type = "indicators",
    # Enrichment-specific fields
    description = "Enriched UNICEF indicators metadata with tier classification",
    total_indicators = length(indicators_dict),
    indicators_with_dataflows = dataflows_added,
    orphan_indicators = length(indicators_dict) - dataflows_added,
    indicators_with_disaggregations = enriched_count,
    tier_counts = tier_counts
  ),
  indicators = indicators_dict
)

cat("  Metadata header created\n")

# =========================================================================
# Save enriched metadata
# =========================================================================
cat("\nSaving enriched metadata...\n")

yaml::write_yaml(enriched_data, output_file)

cat("\n================================================================================\n")
cat("ENRICHMENT COMPLETE!\n")
cat("================================================================================\n")
cat(sprintf("  Output: %s\n", output_file))
cat("\n")
cat("Summary:\n")
cat(sprintf("  Total indicators:          %d\n", length(indicators_dict)))
cat(sprintf("  With dataflows:            %d\n", dataflows_added))
cat(sprintf("  With disaggregations:      %d\n", enriched_count))
cat(sprintf("  Tier 1 (metadata + data):  %d\n", tier_counts$tier_1))
cat(sprintf("  Tier 2 (metadata, no data):%d\n", tier_counts$tier_2))
cat(sprintf("  Tier 3 (data, no metadata):%d\n", tier_counts$tier_3))
cat("================================================================================\n")

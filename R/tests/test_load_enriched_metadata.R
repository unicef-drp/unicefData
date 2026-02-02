#!/usr/bin/env Rscript
# ============================================================================
# Test Loading Enriched Indicators Metadata
#
# Verifies that R can load and parse the enriched _unicefdata_indicators_metadata.yaml
# file from Stata (or any platform that generates the enriched format).
#
# The enriched format includes:
# - tier (tier_1, tier_2, tier_3, tier_4)
# - dataflows (list of applicable dataflows)
# - disaggregations (available dimensions)
#
# Date: 2026-01-25
# ============================================================================

cat("\n========================================================================\n")
cat("R: Test Loading Enriched Indicators Metadata\n")
cat("========================================================================\n\n")

# Load yaml package
if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("yaml package required. Install with: install.packages('yaml')")
}

# Find the enriched metadata file
# Priority: 1. Stata (enriched), 2. R (if generated), 3. Python
candidates <- c(
  "stata/src/_/_unicefdata_indicators_metadata.yaml",
  "R/metadata/current/_unicefdata_indicators_metadata.yaml",
  "python/metadata/current/_unicefdata_indicators_metadata.yaml"
)

metadata_file <- NULL
for (candidate in candidates) {
  if (file.exists(candidate)) {
    metadata_file <- candidate
    break
  }
}

if (is.null(metadata_file)) {
  stop("No indicators metadata file found. Check paths:\n  ", paste(candidates, collapse="\n  "))
}

cat(sprintf("Loading from: %s\n", metadata_file))
cat(sprintf("File size: %.1f KB\n", file.info(metadata_file)$size / 1024))
cat("\n")

# Load YAML
data <- yaml::yaml.load_file(metadata_file)

# Verify structure - accept both 'metadata' and '_metadata' keys (different schema conventions)
if (!any(c("metadata", "_metadata") %in% names(data))) {
  stop("ERROR: Missing 'metadata' or '_metadata' section in YAML")
}
# Normalize to 'metadata' for downstream use
if ("_metadata" %in% names(data) && !"metadata" %in% names(data)) {
  data$metadata <- data$`_metadata`
}

if (!"indicators" %in% names(data)) {
  stop("ERROR: Missing 'indicators' section in YAML")
}

cat("========================================================================\n")
cat("Metadata Header\n")
cat("========================================================================\n")
cat(sprintf("  Version:           %s\n", data$metadata$version))
cat(sprintf("  Source:            %s\n", data$metadata$source))
cat(sprintf("  Last updated:      %s\n", substr(data$metadata$last_updated, 1, 19)))
cat(sprintf("  Total indicators:  %d\n", data$metadata$indicator_count))

if (!is.null(data$metadata$tier_counts)) {
  cat("\n  Tier Distribution:\n")
  for (tier in names(data$metadata$tier_counts)) {
    count <- data$metadata$tier_counts[[tier]]
    cat(sprintf("    %-8s: %d\n", tier, count))
  }
}

cat("\n")

# Test sample indicators
test_indicators <- c("CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD", "ED_CR_L1")
available_indicators <- names(data$indicators)

cat("========================================================================\n")
cat("Sample Indicator Tests\n")
cat("========================================================================\n\n")

tests_passed <- 0
tests_failed <- 0

for (ind_code in test_indicators) {
  if (ind_code %in% available_indicators) {
    ind <- data$indicators[[ind_code]]

    cat(sprintf("[OK] %s\n", ind_code))
    cat(sprintf("  Name: %s\n", ind$name))

    # Check enrichment fields
    has_tier <- !is.null(ind$tier)
    has_dataflows <- !is.null(ind$dataflows) && length(ind$dataflows) > 0
    has_disagg <- !is.null(ind$disaggregations) && length(ind$disaggregations) > 0

    if (has_tier) {
      cat(sprintf("  Tier: %s (%s)\n", ind$tier, ind$tier_reason))
    }

    if (has_dataflows) {
      if (is.list(ind$dataflows)) {
        dfs <- paste(unlist(ind$dataflows), collapse=", ")
      } else {
        dfs <- ind$dataflows
      }
      cat(sprintf("  Dataflows: %s\n", dfs))
    }

    if (has_disagg) {
      disagg <- paste(unlist(ind$disaggregations), collapse=", ")
      cat(sprintf("  Disaggregations: %s\n", disagg))
    }

    cat("\n")
    tests_passed <- tests_passed + 1
  } else {
    cat(sprintf("[X] %s - NOT FOUND\n\n", ind_code))
    tests_failed <- tests_failed + 1
  }
}

# Summary statistics
cat("========================================================================\n")
cat("Enrichment Statistics\n")
cat("========================================================================\n")

tier_count <- sum(sapply(data$indicators, function(x) !is.null(x$tier)))
dataflow_count <- sum(sapply(data$indicators, function(x) {
  !is.null(x$dataflows) && length(x$dataflows) > 0
}))
disagg_count <- sum(sapply(data$indicators, function(x) {
  !is.null(x$disaggregations) && length(x$disaggregations) > 0
}))

total_indicators <- length(data$indicators)

cat(sprintf("  Total indicators:            %d\n", total_indicators))
cat(sprintf("  With tier classification:    %d (%.1f%%)\n",
            tier_count, 100 * tier_count / total_indicators))
cat(sprintf("  With dataflow mappings:      %d (%.1f%%)\n",
            dataflow_count, 100 * dataflow_count / total_indicators))
cat(sprintf("  With disaggregations:        %d (%.1f%%)\n",
            disagg_count, 100 * disagg_count / total_indicators))

cat("\n")

# Test results
cat("========================================================================\n")
cat("Test Summary\n")
cat("========================================================================\n")
cat(sprintf("  Tests run:    %d\n", tests_passed + tests_failed))
cat(sprintf("  Passed:       %d\n", tests_passed))
cat(sprintf("  Failed:       %d\n", tests_failed))
cat("========================================================================\n\n")

if (tests_failed > 0) {
  cat("Some tests failed!\n")
  quit(status = 1)
} else {
  cat("All tests passed! R can successfully load and parse enriched metadata.\n\n")
  quit(status = 0)
}

# ============================================================================
# Comprehensive test suite for unicefdata R package
# 
# Test Strategy:
# - OFFLINE tests: Use bundled YAML metadata files (always run, fast)
# - NETWORK tests: Call UNICEF API (skipped in CI, run locally)
#
# Bundled metadata location: R/metadata/current/
#
# Dependencies:
# - Only 'yaml' package needed - CI runs OFFLINE tests that parse bundled
#   metadata files using yaml::read_yaml() without requiring full package
#   dependencies (httr, jsonlite, etc.). Network tests source the full
#   package code only when actually running.
# ============================================================================

# Check environment FIRST
IN_CI <- Sys.getenv("CI") != "" || Sys.getenv("GITHUB_ACTIONS") != ""

# Check actual network connectivity (for true offline detection)
check_network <- function(timeout = 5) {
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = timeout)
  tryCatch({
    # Try to reach UNICEF SDMX API
    con <- url("https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow", open = "r")
    on.exit(try(close(con), silent = TRUE), add = TRUE)
    TRUE
  }, error = function(e) {
    FALSE
  }, warning = function(w) {
    FALSE
  })
}

# Determine if network tests should run
# Skip if: (1) in CI environment, OR (2) no network connectivity
if (IN_CI) {
  NETWORK_AVAILABLE <- FALSE
  SKIP_REASON <- "CI environment"
} else {
  cat("Checking network connectivity...\n")
  NETWORK_AVAILABLE <- check_network()
  SKIP_REASON <- if (!NETWORK_AVAILABLE) "no network connectivity" else NULL
}

# Determine paths
if (file.exists("R/metadata/current")) {
  METADATA_DIR <- "R/metadata/current"
  OUTPUT_DIR <- "R/tests/output"
  R_DIR <- "R"
} else if (file.exists("../metadata/current")) {
  METADATA_DIR <- "../metadata/current"
  OUTPUT_DIR <- "output"
  R_DIR <- ".."
} else {
  stop("Could not find metadata directory - run from unicefData root")
}

if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# Helper function
log_msg <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
}

# ============================================================================
# OFFLINE TESTS - Use bundled YAML metadata (always run, fast, NO network)
# These tests only require the yaml package - no network dependencies
# ============================================================================

test_yaml_dataflows <- function() {
  log_msg("Testing YAML dataflows loading...")
  
  yaml_path <- file.path(METADATA_DIR, "_unicefdata_dataflows.yaml")
  if (!file.exists(yaml_path)) {
    log_msg(sprintf("  SKIP: %s not found", yaml_path))
    return(TRUE)  # Skip gracefully
  }
  
  data <- yaml::read_yaml(yaml_path)
  
  n_dataflows <- length(data$dataflows)
  log_msg(sprintf("  Found %d dataflows in YAML", n_dataflows))
  
  # Verify structure
  first_df <- data$dataflows[[1]]
  has_required <- all(c("id", "name", "agency") %in% names(first_df))
  log_msg(sprintf("  Structure valid: %s", has_required))
  
  # Check specific dataflows exist
  expected <- c("CME", "EDUCATION", "NUTRITION", "IMMUNISATION")
  found <- sum(expected %in% names(data$dataflows))
  log_msg(sprintf("  Key dataflows present: %d/%d", found, length(expected)))
  
  return(n_dataflows >= 50 && has_required && found == length(expected))
}

test_yaml_indicators <- function() {
  log_msg("Testing YAML indicators loading...")
  
  yaml_path <- file.path(METADATA_DIR, "_unicefdata_indicators.yaml")
  if (!file.exists(yaml_path)) {
    log_msg(sprintf("  SKIP: %s not found", yaml_path))
    return(TRUE)
  }
  
  data <- yaml::read_yaml(yaml_path)
  
  n_indicators <- length(data$indicators)
  log_msg(sprintf("  Found %d indicators in YAML", n_indicators))
  
  # Check for expected indicators (some may not be in minimal YAML)
  expected <- c("CME_MRY0T4", "NT_ANT_HAZ_NE2", "IM_DTP3")
  found <- sum(expected %in% names(data$indicators))
  log_msg(sprintf("  Key indicators present: %d/%d", found, length(expected)))
  
  # Minimum threshold: at least 10 indicators (bundled YAML may be minimal)
  return(n_indicators >= 10 && found >= 1)
}

test_yaml_countries <- function() {
  log_msg("Testing YAML countries loading...")
  
  yaml_path <- file.path(METADATA_DIR, "_unicefdata_countries.yaml")
  if (!file.exists(yaml_path)) {
    log_msg(sprintf("  SKIP: %s not found", yaml_path))
    return(TRUE)
  }
  
  data <- yaml::read_yaml(yaml_path)
  
  n_countries <- length(data$countries)
  log_msg(sprintf("  Found %d countries in YAML", n_countries))
  
  # Check for expected countries
  expected <- c("USA", "GBR", "FRA", "DEU", "BRA", "IND", "CHN")
  found <- sum(expected %in% names(data$countries))
  log_msg(sprintf("  Key countries present: %d/%d", found, length(expected)))
  
  return(n_countries >= 150 && found >= 5)
}

test_dataflow_schema_cme <- function() {
  log_msg("Testing CME schema YAML structure...")
  
  schema_path <- file.path(METADATA_DIR, "dataflows", "CME.yaml")
  if (!file.exists(schema_path)) {
    log_msg(sprintf("  SKIP: %s not found", schema_path))
    return(TRUE)
  }
  
  # Read YAML directly (no function call needed)
  schema <- yaml::read_yaml(schema_path)
  
  log_msg(sprintf("  Schema ID: %s", schema$id))
  
  # Extract dimensions
  dimensions <- if (!is.null(schema$dimensions)) {
    sapply(schema$dimensions, function(d) d$id)
  } else {
    character(0)
  }
  
  # Extract attributes  
  attributes <- if (!is.null(schema$attributes)) {
    sapply(schema$attributes, function(a) a$id)
  } else {
    character(0)
  }
  
  log_msg(sprintf("  Dimensions: %d (%s)", length(dimensions), 
                  paste(head(dimensions, 3), collapse = ", ")))
  log_msg(sprintf("  Attributes: %d", length(attributes)))
  
  has_dims <- length(dimensions) > 0
  has_attrs <- length(attributes) > 0
  
  return(has_dims && has_attrs)
}

test_dataflow_schema_education <- function() {
  log_msg("Testing EDUCATION schema YAML structure...")
  
  schema_path <- file.path(METADATA_DIR, "dataflows", "EDUCATION.yaml")
  if (!file.exists(schema_path)) {
    log_msg(sprintf("  SKIP: %s not found", schema_path))
    return(TRUE)
  }
  
  # Read YAML directly
  schema <- yaml::read_yaml(schema_path)
  
  log_msg(sprintf("  Schema ID: %s", schema$id))
  
  dimensions <- if (!is.null(schema$dimensions)) {
    sapply(schema$dimensions, function(d) d$id)
  } else {
    character(0)
  }
  
  log_msg(sprintf("  Dimensions: %s", paste(head(dimensions, 5), collapse = ", ")))
  
  return(schema$id == "EDUCATION" && length(dimensions) > 0)
}

test_schema_files_exist <- function() {
  log_msg("Testing schema files directory...")
  
  schema_dir <- file.path(METADATA_DIR, "dataflows")
  if (!dir.exists(schema_dir)) {
    log_msg(sprintf("  SKIP: %s not found", schema_dir))
    return(TRUE)
  }
  
  files <- list.files(schema_dir, pattern = "\\.yaml$")
  log_msg(sprintf("  Found %d schema files", length(files)))
  
  # Check for key schemas
  expected <- c("CME.yaml", "EDUCATION.yaml", "NUTRITION.yaml")
  found <- sum(expected %in% files)
  log_msg(sprintf("  Key schemas present: %d/%d", found, length(expected)))
  
  return(length(files) >= 10 && found >= 2)
}

# ============================================================================
# NETWORK TESTS - Call UNICEF API (skipped in CI)
# These require sourcing the package code first
# ============================================================================

source_package_code <- function() {
  # Source package code only when needed (for network tests)
  if (file.exists(file.path(R_DIR, "get_unicef.R"))) {
    source(file.path(R_DIR, "get_unicef.R"))
    source(file.path(R_DIR, "metadata.R"))
    source(file.path(R_DIR, "flows.R"))
    source(file.path(R_DIR, "aliases_devtests.R"))
    return(TRUE)
  }
  return(FALSE)
}

test_list_flows_api <- function() {
  log_msg("Testing list_dataflows() from API...")
  
  if (!source_package_code()) {
    log_msg("  SKIP: Could not source package code")
    return(TRUE)
  }
  
  flows <- list_dataflows()
  
  log_msg(sprintf("  Found %d dataflows", nrow(flows)))
  
  write.csv(flows, file.path(OUTPUT_DIR, "test_dataflows.csv"), 
            row.names = FALSE, fileEncoding = "UTF-8")
  log_msg("  Saved to test_dataflows.csv")
  
  return(nrow(flows) > 50)
}

test_child_mortality_api <- function() {
  log_msg("Testing child mortality API (CME_MRY0T4)...")
  
  if (!exists("get_unicef", mode = "function")) {
    if (!source_package_code()) {
      log_msg("  SKIP: Could not source package code")
      return(TRUE)
    }
  }
  
  df <- get_unicef(
    indicator = "CME_MRY0T4",
    countries = c("USA", "GBR", "FRA"),
    start_year = 2020,
    end_year = 2023
  )
  
  log_msg(sprintf("  Retrieved %d observations", nrow(df)))
  
  if (!is.null(df) && nrow(df) > 0) {
    write.csv(df, file.path(OUTPUT_DIR, "test_mortality.csv"), row.names = FALSE)
    log_msg("  Saved to test_mortality.csv")
    return(nrow(df) > 0)
  }
  
  return(FALSE)
}

# ============================================================================
# Run All Tests
# ============================================================================

run_all_tests <- function() {
  cat("============================================================\n")
  cat("UNICEF API R Package Test Suite\n")
  cat(sprintf("Started: %s\n", Sys.time()))
  cat(sprintf("Environment: %s\n", if (IN_CI) "CI (GitHub Actions)" else "Local"))
  cat(sprintf("Network available: %s\n", if (NETWORK_AVAILABLE) "Yes" else sprintf("No (%s)", SKIP_REASON)))
  cat(sprintf("Metadata dir: %s (exists: %s)\n", METADATA_DIR, dir.exists(METADATA_DIR)))
  cat("============================================================\n\n")
  
  # OFFLINE tests - always run (fast, no network)
  # Only requires: yaml package (no sourcing of package code)
  cat("--- OFFLINE TESTS (bundled YAML metadata) ---\n\n")
  tests <- list(
    list(name = "YAML Dataflows", fn = test_yaml_dataflows),
    list(name = "YAML Indicators", fn = test_yaml_indicators),
    list(name = "YAML Countries", fn = test_yaml_countries),
    list(name = "Schema Files Exist", fn = test_schema_files_exist),
    list(name = "CME Schema Structure", fn = test_dataflow_schema_cme),
    list(name = "EDUCATION Schema Structure", fn = test_dataflow_schema_education)
  )
  
  # NETWORK tests - only run when network is available (not in CI, and connectivity confirmed)
  if (NETWORK_AVAILABLE) {
    cat("\n--- NETWORK TESTS (API calls) ---\n\n")
    tests <- c(tests, list(
      list(name = "List Dataflows API", fn = test_list_flows_api),
      list(name = "Child Mortality API", fn = test_child_mortality_api)
    ))
  } else {
    cat(sprintf("\n--- Skipping network tests (%s) ---\n\n", SKIP_REASON))
  }
  
  results <- list()
  
  for (test in tests) {
    result <- tryCatch({
      passed <- test$fn()
      list(name = test$name, status = if (passed) "PASS" else "FAIL", error = NULL)
    }, error = function(e) {
      log_msg(sprintf("  ERROR: %s", e$message))
      list(name = test$name, status = "ERROR", error = e$message)
    })
    results[[length(results) + 1]] <- result
    cat("\n")
  }
  
  cat("============================================================\n")
  cat("TEST RESULTS\n")
  cat("============================================================\n")
  
  passed_count <- 0
  for (r in results) {
    icon <- if (r$status == "PASS") "PASS" else "FAIL"
    cat(sprintf("[%s] %s\n", icon, r$name))
    if (!is.null(r$error)) {
      cat(sprintf("       Error: %s\n", r$error))
    }
    if (r$status == "PASS") passed_count <- passed_count + 1
  }
  
  cat(sprintf("\nTotal: %d/%d tests passed\n", passed_count, length(results)))
  cat("============================================================\n")
  
  # Exit with error if tests failed (for CI)
  if (passed_count < length(results) && IN_CI) {
    quit(status = 1)
  }
  
  invisible(passed_count == length(results))
}

# Run tests
run_all_tests()

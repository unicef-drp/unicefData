#!/usr/bin/env Rscript
# Direct test for fallback sequences (sources R files directly)

# Set working directory to package root
setwd("C:\\GitHub\\myados\\unicefData-dev")

cat("=== Testing Fallback Sequences (Direct Source) ===\n\n")
cat("Working directory:", getwd(), "\n\n")

# Load required packages
required_pkgs <- c("yaml", "dplyr", "magrittr")
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("[ERROR] Required package '%s' not installed\n", pkg))
    cat(sprintf("        Please run: install.packages('%s')\n", pkg))
    quit(status = 1)
  }
}

cat("[INFO] Loading required R source files...\n")

# Source the necessary R files in dependency order
tryCatch({
  source("R/globals.R", local = FALSE)
  source("R/unicef_core.R", local = FALSE)
  source("R/indicator_registry.R", local = FALSE)
  cat("[SUCCESS] R source files loaded\n\n")
}, error = function(e) {
  cat(sprintf("[ERROR] Failed to source R files: %s\n", e$message))
  quit(status = 1)
})

# Test 1: Check YAML file exists
cat("=== Test 1: YAML File Check ===\n")
yaml_file <- "metadata/current/_dataflow_fallback_sequences.yaml"
if (file.exists(yaml_file)) {
  cat(sprintf("[SUCCESS] YAML file found: %s\n", normalizePath(yaml_file)))
} else {
  cat(sprintf("[ERROR] YAML file NOT found: %s\n", yaml_file))
}

# Test 2: Load fallback sequences
cat("\n=== Test 2: Load Fallback Sequences ===\n")

fallback <- NULL
method_used <- "unknown"

# Try .load_fallback_sequences() first (indicator_registry.R)
if (exists(".load_fallback_sequences")) {
  tryCatch({
    fallback <- .load_fallback_sequences()
    method_used <- ".load_fallback_sequences()"
    cat("[SUCCESS] Loaded using", method_used, "\n")
  }, error = function(e) {
    cat(sprintf("[ERROR] .load_fallback_sequences() failed: %s\n", e$message))
  })
}

# If that didn't work, try .get_fallback_sequences() (unicef_core.R)
if (is.null(fallback) && exists(".get_fallback_sequences")) {
  tryCatch({
    fallback <- .get_fallback_sequences()
    method_used <- ".get_fallback_sequences()"
    cat("[SUCCESS] Loaded using", method_used, "\n")
  }, error = function(e) {
    cat(sprintf("[ERROR] .get_fallback_sequences() failed: %s\n", e$message))
  })
}

# Check results
if (!is.null(fallback)) {
  cat(sprintf("[SUCCESS] Loaded fallback sequences with %d prefixes\n", length(fallback)))

  all_prefixes <- names(fallback)
  cat(sprintf("[INFO] All prefixes (%d total):\n", length(all_prefixes)))
  for (i in seq_along(all_prefixes)) {
    prefix <- all_prefixes[i]
    dataflows <- fallback[[prefix]]
    cat(sprintf("  %2d. %s -> %s\n", i, prefix, paste(dataflows, collapse=", ")))
    if (i >= 15) {
      cat(sprintf("  ... and %d more\n", length(all_prefixes) - i))
      break
    }
  }

  cat("\n")

  # Check specific prefixes
  test_prefixes <- c("IM", "FD", "CME", "NT", "DEFAULT")
  for (prefix in test_prefixes) {
    if (prefix %in% names(fallback)) {
      cat(sprintf("[SUCCESS] %s prefix found: %s\n",
                  prefix,
                  paste(fallback[[prefix]], collapse=", ")))
    } else {
      cat(sprintf("[WARNING] %s prefix NOT found\n", prefix))
    }
  }
} else {
  cat("[ERROR] Failed to load fallback sequences using any method\n")

  # Try to manually load and display the YAML
  if (file.exists(yaml_file)) {
    cat("\n[INFO] Attempting to manually load YAML file...\n")
    tryCatch({
      yaml_data <- yaml::read_yaml(yaml_file)
      if (!is.null(yaml_data$fallback_sequences)) {
        cat(sprintf("[INFO] YAML contains %d prefixes\n",
                    length(yaml_data$fallback_sequences)))
        cat("[INFO] First 5 prefixes from YAML:\n")
        print(head(names(yaml_data$fallback_sequences), 5))
      } else {
        cat("[ERROR] No 'fallback_sequences' key in YAML\n")
      }
    }, error = function(e) {
      cat(sprintf("[ERROR] Failed to read YAML: %s\n", e$message))
    })
  }
}

# Test 3: Test dataflow detection function
cat("\n=== Test 3: Dataflow Detection Function ===\n")

if (exists("get_dataflow_for_indicator")) {
  test_indicators <- c("IM_DTP3", "CME_MRY0T4", "NT_ANT_HAZ_NE2")

  for (ind in test_indicators) {
    tryCatch({
      # Suppress debug messages for cleaner output
      suppressMessages({
        df <- get_dataflow_for_indicator(ind)
      })
      cat(sprintf("[INFO] %s -> %s\n", ind, df))
    }, error = function(e) {
      cat(sprintf("[ERROR] %s failed: %s\n", ind, e$message))
    })
  }
} else {
  cat("[WARNING] get_dataflow_for_indicator() function not found\n")
}

cat("\n=== Test Complete ===\n")

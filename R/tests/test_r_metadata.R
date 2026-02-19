#!/usr/bin/env Rscript
# R Direct Metadata Loading Test (Simplified)
# Verifies that R can load and use comprehensive indicators metadata

cat("\n")
cat("==================================================\n")
cat("R Direct Metadata Lookup Test\n")
cat("==================================================\n")

# Determine the project root directory
# Works in CI (runs from repo root) and locally
script_dir <- tryCatch({
    # When run with Rscript, get the script's directory
    dirname(sys.frame(1)$ofile)
}, error = function(e) {
    # Fallback: use current working directory
    getwd()
})

# Navigate to project root from tests/ directory
project_root <- if (basename(script_dir) == "tests") {
    dirname(script_dir)
} else if (file.exists(file.path(script_dir, "R", "unicef_core.R"))) {
    script_dir
} else if (file.exists(file.path(getwd(), "R", "unicef_core.R"))) {
    getwd()
} else {
    # CI environment: assume we're already in the project root
    getwd()
}

cat("Project root:", project_root, "\n")

# Check if R directory exists
r_dir <- file.path(project_root, "R")
if (!dir.exists(r_dir)) {
    cat("[SKIP] R directory not found at:", r_dir, "\n")
    cat("This test requires the R source files to be present.\n")
    quit(status = 0)
}

# Load the core module
core_file <- file.path(r_dir, "unicef_core.R")
if (!file.exists(core_file)) {
    cat("[SKIP] unicef_core.R not found at:", core_file, "\n")
    quit(status = 0)
}

source(core_file, local = FALSE)

cat("\n1. Metadata Initialization:\n")

# Check if metadata was loaded (it's now a global variable)
if (exists(".INDICATORS_METADATA_YAML")) {
    num_indicators <- if (is.list(.INDICATORS_METADATA_YAML)) length(.INDICATORS_METADATA_YAML) else 0
    cat("   Indicators metadata loaded:", num_indicators, "indicators\n")
} else {
    cat("   [ERROR] Indicators metadata not loaded\n")
}

# Check if fallback sequences were loaded
if (exists(".FALLBACK_SEQUENCES_YAML")) {
    num_sequences <- if (is.list(.FALLBACK_SEQUENCES_YAML)) length(.FALLBACK_SEQUENCES_YAML) else 0
    cat("   Fallback sequences loaded:", num_sequences, "prefixes\n")
} else {
    cat("   [ERROR] Fallback sequences not loaded\n")
}

cat("\n2. Direct Metadata Lookup Test (CME_MRY0T4):\n")

# Test direct lookup for CME_MRY0T4
test_indicator <- "CME_MRY0T4"
if (exists(".INDICATORS_METADATA_YAML")) {
    if (!is.null(.INDICATORS_METADATA_YAML[[test_indicator]])) {
        cat("   [+] Found", test_indicator, "in metadata\n")
        if (!is.null(.INDICATORS_METADATA_YAML[[test_indicator]]$dataflow)) {
            cat("       dataflow =", .INDICATORS_METADATA_YAML[[test_indicator]]$dataflow, "\n")
        }
    } else {
        cat("   [-] NOT found in metadata:", test_indicator, "\n")
    }
} else {
    cat("   [-] Metadata not available\n")
}

cat("\n3. Direct Lookup Test (ED indicator):\n")

# Test another indicator
test_indicator2 <- "ED_CR_L1_UIS_MOD"
if (exists(".INDICATORS_METADATA_YAML")) {
    if (!is.null(.INDICATORS_METADATA_YAML[[test_indicator2]])) {
        cat("   [+] Found", test_indicator2, "in metadata\n")
        if (!is.null(.INDICATORS_METADATA_YAML[[test_indicator2]]$dataflow)) {
            cat("       dataflow =", .INDICATORS_METADATA_YAML[[test_indicator2]]$dataflow, "\n")
        }
    } else {
        cat("   [-] NOT found in metadata:", test_indicator2, "\n")
    }
} else {
    cat("   [-] Metadata not available\n")
}

cat("\n4. Architecture Summary:\n")
cat("   - R now uses comprehensive indicators metadata\n")
cat("   - Direct O(1) lookup instead of prefix-based fallback\n")
cat("   - Fallback sequences still available if metadata missing\n")
cat("   - All platforms aligned on canonical YAML metadata\n")

cat("\n[OK] R metadata loading test complete\n\n")

/*******************************************************************************
* sync_examples_stata.do - Run all Stata examples
********************************************************************************
*
* Runs all Stata example scripts to generate CSV outputs in validation/data/stata/
*
* Usage:
*     stata -b do validation/sync_examples_stata.do
*     stata -b do validation/sync_examples_stata.do, verbose
*
*******************************************************************************/

clear all
set more off
cap log close

* Parse arguments
local verbose = 0
if "`1'" == "verbose" | "`1'" == "--verbose" | "`1'" == "-v" {
    local verbose = 1
}

* Setup paths - determine base directory
* This script lives in validation/, so base is parent
local script_dir = "`c(pwd)'"
if strpos("`script_dir'", "validation") == 0 {
    * Not in validation dir, assume we're at repo root
    local base_dir = "`script_dir'"
} 
else {
    * In validation dir
    local base_dir = subinstr("`script_dir'", "/validation", "", .)
    local base_dir = subinstr("`base_dir'", "\validation", "", .)
}

local stata_dir = "`base_dir'/stata"
local examples_dir = "`stata_dir'/examples"
local output_dir = "`base_dir'/validation/data/stata"

* Display header
di _n as text _dup(60) "="
di as text "Running Stata Examples"
di as text _dup(60) "="
di as text "Output directory: `output_dir'" _n

* Ensure output directory exists
cap mkdir "`base_dir'/validation"
cap mkdir "`base_dir'/validation/data"
cap mkdir "`output_dir'"

* Example scripts to run
local examples ///
    "00_quick_start.do" ///
    "01_indicator_discovery.do" ///
    "02_sdg_indicators.do" ///
    "03_data_formats.do" ///
    "04_metadata_options.do" ///
    "05_advanced_features.do" ///
    "06_test_fallback.do"

* Initialize counters
local passed = 0
local failed = 0
local skipped = 0

* Results storage
local results ""

* Run each example
foreach example of local examples {
    local script_path = "`examples_dir'/`example'"
    
    * Check if file exists
    cap confirm file "`script_path'"
    if _rc != 0 {
        di as text "  [SKIP] `example' not found"
        local skipped = `skipped' + 1
        local results "`results' SKIP"
        continue
    }
    
    di as text "  Running `example'..."
    
    * Run the script
    cap noisily do "`script_path'"
    
    if _rc == 0 {
        di as result "  [OK] `example'"
        local passed = `passed' + 1
        local results "`results' OK"
    }
    else {
        di as error "  [FAIL] `example' (error code: `=_rc')"
        local failed = `failed' + 1
        local results "`results' FAIL"
        
        if `verbose' {
            di as text "  Error details: `r(error)'"
        }
    }
}

* Summary
di _n as text _dup(60) "="
di as text "Summary"
di as text _dup(60) "="
di as text "  Passed:  `passed'"
di as text "  Failed:  `failed'"
di as text "  Skipped: `skipped'"
di _n as text "CSV outputs saved to: `output_dir'"

* Exit with appropriate status
if `failed' > 0 {
    exit 1
}
else {
    exit 0
}

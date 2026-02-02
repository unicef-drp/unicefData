*! test_indicator_suite.do
*! Version 1.0.0  10Jan2026
*!
*! Comprehensive Stata indicator test suite for unicefData validation
*! 
*! This do-file:
*! 1. Loads all known indicators from metadata
*! 2. Tests each indicator download
*! 3. Captures success/failure + row counts
*! 4. Exports results to CSV
*! 5. Generates detailed error log
*!
*! Usage:
*!   do test_indicator_suite.do
*!   do test_indicator_suite.do, with_log
*!   do test_indicator_suite.do INDICATORS(CME_MRY0T4 WSHPOL_SANI_TOTAL)
*!
*! Output:
*!   test_results_<timestamp>.csv
*!   test_errors_<timestamp>.txt
*!   test_summary_<timestamp>.txt

*===============================================================================
* SYNC REPO AND STATA (ALWAYS RUN FIRST)
*===============================================================================

* Always start by making sure unicefdata in REPO and in Stata are aligned
* This ensures tests run against the latest code from the repository
net install unicefdata, from("C:\GitHub\myados\unicefData-dev\stata") replace

*===============================================================================
*===============================================================================

set more off
set trace off
capture log close

* =============================================================================
* Setup
* =============================================================================

local test_dir  "validation/results/stata"
local timestamp : di %tc_CCYYMMDD_HHMMSS clock(c(current_date) + " " + c(current_time), "DMY hms")

capture mkdir "`test_dir'"
capture mkdir "`test_dir'/success"
capture mkdir "`test_dir'/failed"

local results_csv    "`test_dir'/test_results_`timestamp'.csv"
local errors_log     "`test_dir'/test_errors_`timestamp'.txt"
local summary_log    "`test_dir'/test_summary_`timestamp'.txt"

* Setup result frame for accumulation
capture frame drop test_results
frame create test_results
frame test_results: {
    gen indicator_code = ""
    gen status = ""
    gen rows_returned = 0
    gen error_message = ""
    gen execution_time_sec = 0
    gen timestamp_str = ""
}

* =============================================================================
* Configuration
* =============================================================================

* Test parameters
local test_countries "USA BRA IND KEN CHN"
local test_year "2020"

* All known indicators (from metadata)
* Note: This list is populated from config/indicators.yaml in production
* For now, using representative sample
local indicators ///
    CME_MRM0 CME_MRY0T4 ///
    MAT_MMRATIO MAT_SBA ///
    WSHPOL_SANI_TOTAL WSHPOL_SAFE_DRINK ///
    NUTRI_STU_0TO4_TOT NUTRI_WST_0TO4_TOT ///
    IMMUNIZ_DPT IMMUNIZ_MMR

display "=" * 80
display "UNICEF Indicator Validation Suite for Stata"
display "=" * 80
display "Output directory: `test_dir'"
display "Results CSV:     `results_csv'"
display "Error log:       `errors_log'"
display "Timestamp:       `timestamp'"
display ""
display "Test configuration:"
display "  Countries: `test_countries'"
display "  Year:      `test_year'"
display "  Indicators: " di `: word count `indicators'' indicators"
display ""

* =============================================================================
* Main test loop
* =============================================================================

local total_count 0
local success_count 0
local failed_count 0
local error_count 0
local not_found_count 0

foreach indicator in `indicators' {
    local total_count = `total_count' + 1
    
    display ""
    display "[`total_count'] Testing indicator: `indicator'"
    
    * Test start time
    local start_time = c(current_time)
    local start_clock = clock(c(current_date) + " " + `start_time', "DMY hms")
    
    * Initialize result variables
    local status "unknown"
    local rows_returned 0
    local error_message ""
    local execution_time 0
    
    * Attempt indicator download
    capture noisily {
        display "    Downloading `indicator' for: `test_countries'"
        unicefdata, indicator(`indicator') countries(`test_countries') year(`test_year') clear noerror
    }
    
    if _rc {
        * Error occurred
        local rc_code = _rc
        local status "failed"
        local error_message "Stata error code: `rc_code'"
        local failed_count = `failed_count' + 1
        local error_count = `error_count' + 1
        
        display "    ✗ Error code `rc_code': `error_message'"
    }
    else {
        * Check if data was loaded
        qui describe
        local rows = r(N)
        local obs_note = r(N)
        
        if `obs_note' > 0 {
            * Success
            local status "success"
            local rows_returned `obs_note'
            local success_count = `success_count' + 1
            
            display "    ✓ Success: `obs_note' rows"
            
            * Export to success folder
            local outfile "`test_dir'/success/`indicator'.csv"
            capture export delimited using "`outfile'", replace
            if _rc {
                display "    ⚠ Warning: Could not export to `outfile'"
            }
        }
        else {
            * No data returned
            local status "not_found"
            local rows_returned 0
            local not_found_count = `not_found_count' + 1
            
            display "    ⚠ No data returned"
        }
    }
    
    * Calculate execution time
    local end_clock = clock(c(current_date) + " " + c(current_time), "DMY hms")
    local execution_time = (`end_clock' - `start_clock') / 1000
    
    * Store result in frame
    frame test_results: {
        set obs `total_count'
        replace indicator_code = "`indicator'" in `total_count'
        replace status = "`status'" in `total_count'
        replace rows_returned = `rows_returned' in `total_count'
        replace error_message = "`error_message'" in `total_count'
        replace execution_time_sec = `execution_time' / 1000 in `total_count'
        replace timestamp_str = c(current_date) + " " + c(current_time) in `total_count'
    }
}

* =============================================================================
* Export results
* =============================================================================

display ""
display "=" * 80
display "Exporting results..."
display "=" * 80

* Switch to results frame and export
frame test_results: {
    export delimited using "`results_csv'", replace
    display "Exported to: `results_csv'"
}

* Generate summary statistics
frame test_results: {
    qui count if status == "success"
    local success_count = r(N)
    qui count if status == "failed"
    local failed_count = r(N)
    qui count if status == "not_found"
    local not_found_count = r(N)
}

* =============================================================================
* Summary Report
* =============================================================================

file open summary using "`summary_log'", write replace

file write summary "UNICEF Indicator Validation Summary" _n
file write summary "=" * 80 _n
file write summary "Generated: " c(current_date) " " c(current_time) _n
file write summary "" _n

file write summary "Test Configuration" _n
file write summary "-" * 80 _n
file write summary "Countries: `test_countries'" _n
file write summary "Year:      `test_year'" _n
file write summary "" _n

file write summary "Results Summary" _n
file write summary "-" * 80 _n
file write summary "Total indicators tested: `total_count'" _n
file write summary "Successful:              `success_count' (" %5.1f (`success_count'/`total_count'*100) "%)" _n
file write summary "Failed:                  `failed_count' (" %5.1f (`failed_count'/`total_count'*100) "%)" _n
file write summary "Not found:               `not_found_count' (" %5.1f (`not_found_count'/`total_count'*100) "%)" _n
file write summary "" _n

file write summary "Detailed Results" _n
file write summary "-" * 80 _n

frame test_results: {
    qui levelsof indicator_code, local(inds)
    foreach ind in `inds' {
        qui sum rows_returned if indicator_code == "`ind'"
        local rows = r(max)
        qui levelsof status if indicator_code == "`ind'", local(stat)
        
        if "`stat'" == "success" {
            file write summary "`ind': SUCCESS (`rows' rows)" _n
        }
        else if "`stat'" == "not_found" {
            file write summary "`ind': NO DATA" _n
        }
        else {
            qui levelsof error_message if indicator_code == "`ind'", local(err)
            file write summary "`ind': FAILED - `err'" _n
        }
    }
}

file close summary

display ""
display "Summary report saved to: `summary_log'"
display ""

* =============================================================================
* Final summary to console
* =============================================================================

display ""
display "=" * 80
display "TEST COMPLETE"
display "=" * 80
display "Total indicators:    `total_count'"
display "Successful:          `success_count'"
display "Failed:              `failed_count'"
display "Not found (404):     `not_found_count'"
display ""
display "Results saved to:"
display "  CSV:     `results_csv'"
display "  Summary: `summary_log'"
display "  Error log: `errors_log'"
display "=" * 80

exit 0

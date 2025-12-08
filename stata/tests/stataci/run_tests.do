*******************************************************************************
* run_tests.do
* Master test runner for unicefdata Stata package using stataci framework
* Mirrors Python/R test suites for cross-platform validation
*
* Author: Joao Pedro Azevedo
* Date: December 2025
*******************************************************************************

version 15.0

clear all
set more off

* ============================================================================
* SETUP
* ============================================================================

* Ensure log directory exists
capture mkdir "logs"

* Close any existing logs
capture log close _all

* Start test log
local logdate = string(date(c(current_date), "DMY"), "%tdCYND")
local logtime = subinstr(c(current_time), ":", "", .)
log using "logs/test_run_`logdate'_`logtime'.log", replace text name(test_main)

di as txt "=============================================================================="
di as txt "     UNICEFDATA STATA PACKAGE - TEST SUITE (stataci)"
di as txt "     Date: `c(current_date)'  Time: `c(current_time)'"
di as txt "     Stata: `c(stata_version)'  OS: `c(os)'"
di as txt "=============================================================================="
di as txt ""

* Add paths - unicefdata package and assertion utilities
adopath ++ "../../src/u"
adopath ++ "."

* ============================================================================
* TEST EXECUTION
* ============================================================================

* List of test files (without .do extension)
local tests ///
    test_config ///
    test_indicators_basic ///
    test_indicators_prod_sdg ///
    test_data_validation ///
    test_api_comparison

* Initialize counters
local passed 0
local failed 0
local total : word count `tests'

foreach t of local tests {
    di as txt ""
    di as txt "----------------------------------------------------------------------"
    di as txt "Running test: `t'"
    di as txt "----------------------------------------------------------------------"
    
    capture noisily do `t'.do
    local rc = _rc
    
    if (`rc' != 0) {
        di as error "[FAIL] `t' (rc = `rc')"
        local ++failed
    }
    else {
        di as result "[PASS] `t'"
        local ++passed
    }
    
    di as txt ""
}

* ============================================================================
* SUMMARY
* ============================================================================

di as txt ""
di as txt "=============================================================================="
di as txt "                           TEST SUMMARY"
di as txt "=============================================================================="
di as txt ""

if (`failed' == 0) {
    di as result "     ALL TESTS PASSED SUCCESSFULLY"
    di as txt ""
    di as txt "     Total:  `total'"
    di as txt "     Passed: `passed'"
    di as txt "     Failed: `failed'"
    
    * Create success stamp
    file open stamp using "logs/_PASSED.txt", write replace
    file write stamp "All tests passed on `c(current_date)' at `c(current_time)'" _n
    file write stamp "Stata version: `c(stata_version)'" _n
    file write stamp "Tests run: `total'" _n
    file close stamp
    
    log close test_main
    exit 0
}
else {
    di as error "     TEST SUITE FAILED"
    di as txt ""
    di as txt "     Total:  `total'"
    di as txt "     Passed: `passed'"
    di as error "     Failed: `failed'"
    
    log close test_main
    exit 9
}

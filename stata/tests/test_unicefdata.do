*******************************************************************************
* test_unicefdata.do
* Test script for unicefdata Stata command
* Created: 03Dec2025
* Author: Joao Pedro Azevedo
*******************************************************************************

clear all
set more off
set trace off
set tracedepth 5

*******************************************************************************
* SETUP
*******************************************************************************

* Add the parent directory to adopath so Stata can find unicefdata.ado
adopath + "../"

* Set up log file
local logdate = string(date(c(current_date), "DMY"), "%tdCYND")
local logtime = subinstr(c(current_time), ":", "", .)
cap log close _all
log using "log/test_unicefdata_`logdate'_`logtime'.log", replace text name(test)

* Initialize global counters
global tests_passed = 0
global tests_failed = 0
global total_tests = 9

*******************************************************************************
* HELPER PROGRAM: Run a test with describe and summarize
*******************************************************************************

capture program drop run_test
program define run_test
    syntax , TEstnum(integer) TItle(string) CMd(string asis)
    
    * Strip leading/trailing quotes from cmd if present
    local cmd_clean = subinstr(`"`cmd'"', `"""', "", .)
    
    noi di as text ""
    noi di as text "=============================================================================="
    noi di as result "TEST `testnum': `title'"
    noi di as text "=============================================================================="
    noi di as text "Command: `cmd_clean'"
    noi di as text ""
    
    * Time the command
    timer clear `testnum'
    timer on `testnum'
    
    * Run the command (without quotes)
    capture noisily `cmd_clean'
    local rc = _rc
    
    timer off `testnum'
    qui timer list `testnum'
    local exec_time = r(t`testnum')
    
    if (`rc' == 0) {
        noi di as text ""
        noi di as result "STATUS: PASSED" as text " | Observations: " as result _N as text " | Time: " as result %5.2f `exec_time' as text "s"
        noi di as text "------------------------------------------------------------------------------"
        
        * Show describe
        noi di as text ""
        noi di as text "{bf:DESCRIBE}"
        noi describe
        
        * Show summarize
        noi di as text ""
        noi di as text "{bf:SUMMARIZE}"
        noi summarize
        noi di as text ""
        
        global tests_passed = $tests_passed + 1
    }
    else {
        noi di as text ""
        noi di as err "STATUS: FAILED (Error code: `rc')"
        noi di as text "------------------------------------------------------------------------------"
        noi di as text ""
        
        global tests_failed = $tests_failed + 1
    }
end

*******************************************************************************
* HEADER
*******************************************************************************

noi di as text ""
noi di as text "{hline 78}"
noi di as text "{bf:{center 78:UNICEFDATA STATA COMMAND - TEST SUITE}}"
noi di as text "{hline 78}"
noi di as text ""
noi di as text "  Date:          `c(current_date)' `c(current_time)'"
noi di as text "  Stata version: `c(stata_version)'"
noi di as text "  OS:            `c(os)'"
noi di as text ""
noi di as text "{hline 78}"

*******************************************************************************
* TESTS
*******************************************************************************

* -----------------------------------------------------------------------------
* TEST 1: Basic download - all countries
* -----------------------------------------------------------------------------
run_test, testnum(1) ///
    title("Download under-5 mortality rate for all countries") ///
    cmd("unicefdata, indicator(CME_MRY0T4) clear")

* -----------------------------------------------------------------------------
* TEST 2: Download for specific countries
* -----------------------------------------------------------------------------
run_test, testnum(2) ///
    title("Download for specific countries (ALB USA BRA)") ///
    cmd("unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear")

* Verify country filter
if (_N > 0) {
    noi di as text "{bf:VERIFICATION: Country filter}"
    noi tab iso3
    noi di as text ""
}

* -----------------------------------------------------------------------------
* TEST 3: Download with year range
* -----------------------------------------------------------------------------
run_test, testnum(3) ///
    title("Download with year range (2010-2023)") ///
    cmd("unicefdata, indicator(CME_MRY0T4) startyear(2010) endyear(2023) clear")

* Verify year filter
if (_N > 0) {
    noi di as text "{bf:VERIFICATION: Year range}"
    noi tab period
    noi di as text ""
}

* -----------------------------------------------------------------------------
* TEST 4: Get latest value per country
* -----------------------------------------------------------------------------
run_test, testnum(4) ///
    title("Get latest value per country") ///
    cmd("unicefdata, indicator(CME_MRY0T4) latest clear")

* Show sample
if (_N > 0) {
    noi di as text "{bf:SAMPLE: Latest values (first 10)}"
    noi list iso3 country period value in 1/10, clean noobs abbrev(20)
    noi di as text ""
}

* -----------------------------------------------------------------------------
* TEST 5: Get female-only data
* -----------------------------------------------------------------------------
run_test, testnum(5) ///
    title("Get female-only data (sex=F)") ///
    cmd("unicefdata, indicator(CME_MRY0T4) sex(F) clear")

* Verify sex filter
if (_N > 0) {
    noi di as text "{bf:VERIFICATION: Sex filter}"
    cap noi tab sex
    noi di as text ""
    noi di as text "{bf:SAMPLE: Female data (first 10)}"
    noi list iso3 country period value in 1/10, clean noobs abbrev(20)
    noi di as text ""
}

* -----------------------------------------------------------------------------
* TEST 6: Download from dataflow
* -----------------------------------------------------------------------------
run_test, testnum(6) ///
    title("Download NUTRITION dataflow for Ethiopia") ///
    cmd("unicefdata, dataflow(NUTRITION) countries(ETH) clear verbose")

* Show indicators
if (_N > 0) {
    noi di as text "{bf:VERIFICATION: Indicators in dataflow}"
    cap noi tab indicator
    noi di as text ""
}

* -----------------------------------------------------------------------------
* TEST 7: Most recent values (MRV)
* -----------------------------------------------------------------------------
run_test, testnum(7) ///
    title("Get 5 most recent values per country (MRV=5)") ///
    cmd("unicefdata, indicator(CME_MRY0T4) mrv(5) clear")

* Verify MRV
if (_N > 0) {
    bysort iso3: gen _n_obs = _N
    qui sum _n_obs
    local max_obs = r(max)
    drop _n_obs
    
    noi di as text "{bf:VERIFICATION: MRV filter}"
    noi di as text "  Max obs per country: " as result `max_obs' as text " (should be <= 5)"
    if (`max_obs' <= 5) {
        noi di as result "  [OK] MRV filter working correctly"
    }
    else {
        noi di as err "  [FAIL] MRV filter not working - max obs > 5"
    }
    noi di as text ""
    noi di as text "{bf:SAMPLE: USA data}"
    noi list iso3 country period value if iso3 == "USA", clean noobs abbrev(20)
    noi di as text ""
}

* -----------------------------------------------------------------------------
* TEST 8: Verbose mode
* -----------------------------------------------------------------------------
run_test, testnum(8) ///
    title("Verbose mode with multiple options") ///
    cmd("unicefdata, indicator(CME_MRY0T4) countries(BRA) startyear(2020) clear verbose")

* Show full dataset
if (_N > 0 & _N <= 50) {
    noi di as text "{bf:FULL DATASET}"
    noi list, clean noobs abbrev(15)
    noi di as text ""
}

* -----------------------------------------------------------------------------
* TEST 9: Return values
* -----------------------------------------------------------------------------
noi di as text ""
noi di as text "=============================================================================="
noi di as result "TEST 9: Check return values"
noi di as text "=============================================================================="
noi di as text "Command: " as input "unicefdata, indicator(CME_MRY0T4) countries(USA) clear"
noi di as text ""

timer clear 9
timer on 9

unicefdata, indicator(CME_MRY0T4) countries(USA) clear

timer off 9
qui timer list 9

noi di as result "STATUS: PASSED" as text " | Observations: " as result _N as text " | Time: " as result %5.2f r(t9) as text "s"
noi di as text "------------------------------------------------------------------------------"

* Show describe
noi di as text ""
noi di as text "{bf:DESCRIBE}"
noi describe

* Show summarize
noi di as text ""
noi di as text "{bf:SUMMARIZE}"
noi summarize

noi di as text ""
noi di as text "{bf:RETURN VALUES}"
noi return list
noi di as text ""

global tests_passed = $tests_passed + 1

*******************************************************************************
* SUMMARY
*******************************************************************************

noi di as text ""
noi di as text "{hline 78}"
noi di as text "{bf:{center 78:TEST SUITE SUMMARY}}"
noi di as text "{hline 78}"
noi di as text ""
noi di as text "  Completed:    `c(current_date)' `c(current_time)'"
noi di as text ""
noi di as text "  Total tests:  " as result $total_tests
noi di as text "  Passed:       " as result $tests_passed
noi di as text "  Failed:       " as result $tests_failed
noi di as text ""
noi di as text "  {bf:Execution Times:}"

local total_time = 0
forvalues i = 1/9 {
    cap timer list `i'
    if (_rc == 0 & r(t`i') != .) {
        local total_time = `total_time' + r(t`i')
        noi di as text "    Test `i': " as result %6.2f r(t`i') as text " seconds"
    }
}
noi di as text "    {hline 20}"
noi di as text "    Total:  " as result %6.2f `total_time' as text " seconds"

noi di as text ""
noi di as text "{hline 78}"

if ($tests_failed == 0) {
    noi di as result "{bf:{center 78:ALL TESTS PASSED SUCCESSFULLY}}"
}
else {
    noi di as err "{bf:{center 78:SOME TESTS FAILED - PLEASE REVIEW}}"
}

noi di as text "{hline 78}"
noi di as text ""

* Clean up
cap program drop run_test
macro drop tests_passed tests_failed total_tests

log close test

noi di as text "Log file saved."

*******************************************************************************
* End of test script
*******************************************************************************

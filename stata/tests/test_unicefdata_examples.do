discard
********************************************************************************
* test_unicefdata_examples.do
* 
* Comprehensive test suite for unicefdata command
* Tests all examples from unicefdata.sthlp with timestamps and logging
*
* Author: Generated for unicefData package validation
* Date: December 2025
* Version: 1.3.2
********************************************************************************

clear all
set more off
capture log close _all

* =============================================================================
* DEBUG OPTIONS - Set to "on" for detailed trace output in log
* =============================================================================
local debug_mode "on"   // Change to "off" for production runs

if ("`debug_mode'" == "on") {
    set trace on
    set tracedepth 2    // Limit depth to avoid excessive output
    set traceexpand on  // Show macro expansion
    set tracesep on     // Separator between trace lines
}

* =============================================================================
* CONFIGURATION
* =============================================================================

* Set output directory for test results
local test_dir "c:\GitHub\others\unicefData\stata\tests"
cd "`test_dir'"

* Create timestamped log file
local datetime = subinstr("`c(current_date)'", " ", "", .) + "_" + subinstr("`c(current_time)'", ":", "", .)
local logfile "test_unicefdata_`datetime'.log"

log using "`logfile'", replace text name(testlog)

* =============================================================================
* HELPER PROGRAMS
* =============================================================================

capture program drop log_test_header
program define log_test_header
    args test_name test_num
    di ""
    di as text "{hline 80}"
    di as result "[`test_num'] `test_name'"
    di as text "Timestamp: " as result "`c(current_date)' `c(current_time)'"
    di as text "{hline 80}"
end

capture program drop log_test_result
program define log_test_result
    args test_name status elapsed_time obs_count
    if ("`status'" == "PASS") {
        di as result "[PASS] " as text "`test_name' - " as result "`elapsed_time's" as text " (`obs_count' obs)"
    }
    else if ("`status'" == "SKIP") {
        di as text "[SKIP] `test_name' - `elapsed_time'"
    }
    else {
        di as error "[FAIL] `test_name' - `elapsed_time'"
    }
end

capture program drop run_timed_test
program define run_timed_test, rclass
    syntax , CMD(string asis) NAME(string)
    
    local start = clock("`c(current_date)' `c(current_time)'", "DMY hms")
    di as text "Command: " as input `"`cmd'"'
    
    capture noisily `cmd'
    local rc = _rc
    
    local end = clock("`c(current_date)' `c(current_time)'", "DMY hms")
    local elapsed = (`end' - `start') / 1000
    
    if (`rc' == 0) {
        local obs = _N
        return local status "PASS"
        return local obs "`obs'"
    }
    else {
        return local status "FAIL"
        return local obs "0"
    }
    return local elapsed "`elapsed'"
end

* =============================================================================
* INITIALIZATION
* =============================================================================

di as text ""
di as text "{hline 80}"
di as text "|" _col(5) as result "UNICEFDATA COMPREHENSIVE TEST SUITE" _col(80) as text "|"
di as text "|" _col(5) as text "Version: 1.3.2" _col(80) "|"
di as text "|" _col(5) as text "Date: `c(current_date)' `c(current_time)'" _col(80) "|"
di as text "{hline 80}"
di ""

* Initialize counters
local test_num = 0
local pass_count = 0
local fail_count = 0
local skip_count = 0

* Store start time
local suite_start = clock("`c(current_date)' `c(current_time)'", "DMY hms")

* =============================================================================
* SECTION 1: DISCOVERY COMMANDS
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 1: DISCOVERY COMMANDS" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 1.1: List available dataflows
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "List available dataflows" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, flows
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "unicefdata, flows" "PASS" "`elapsed'" "`r(n_dataflows)' dataflows"
    local ++pass_count
}
else {
    log_test_result "unicefdata, flows" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 1.2: List dataflows with detail
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "List dataflows with detail" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, flows detail
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "unicefdata, flows detail" "PASS" "`elapsed'" ""
    local ++pass_count
}
else {
    log_test_result "unicefdata, flows detail" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 1.3: List all indicator categories
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "List all indicator categories" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, categories
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "unicefdata, categories" "PASS" "`elapsed'" ""
    local ++pass_count
}
else {
    log_test_result "unicefdata, categories" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 1.4: Search for mortality-related indicators
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Search for mortality indicators" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, search(mortality)
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "unicefdata, search(mortality)" "PASS" "`elapsed'" "`r(n_matches)' matches"
    local ++pass_count
}
else {
    log_test_result "unicefdata, search(mortality)" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 1.5: Search within specific dataflow
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Search within CME dataflow" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, search(rate) dataflow(CME)
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "unicefdata, search(rate) dataflow(CME)" "PASS" "`elapsed'" "`r(n_matches)' matches"
    local ++pass_count
}
else {
    log_test_result "unicefdata, search(rate) dataflow(CME)" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 1.6: List indicators in CME dataflow
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "List indicators in CME dataflow" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicators(CME)
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "unicefdata, indicators(CME)" "PASS" "`elapsed'" "`r(n_indicators)' indicators"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicators(CME)" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 1.7: Get detailed info about indicator
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Get indicator info" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, info(CME_MRY0T4)
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "unicefdata, info(CME_MRY0T4)" "PASS" "`elapsed'" ""
    local ++pass_count
}
else {
    log_test_result "unicefdata, info(CME_MRY0T4)" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 2: BASIC DATA RETRIEVAL
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 2: BASIC DATA RETRIEVAL" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 2.1: Download under-5 mortality rate (all countries)
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Download U5MR (all countries)" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    di as text "Variables: " as result "`c(k)'"
    describe, short
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 2.2: Download for specific countries
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Download for specific countries" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    tab iso3
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 2.3: Download with year range
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Download with year range" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) year(2010:2023) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) year(2010:2023) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    sum period
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) year(2010:2023) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 2.4: Download specific years (non-contiguous)
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Download specific years (list)" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) year(2015,2018,2020) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) year(2015,2018,2020) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    tab period
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) year(2015,2018,2020) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 2.5: Get latest value per country
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Get latest value per country" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) latest clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) latest clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) latest clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 2.6: Get female-only data
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Get female-only data" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) sex(F) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) sex(F) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    tab sex
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) sex(F) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 2.7: Download entire dataflow with verbose
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Download entire dataflow (verbose)" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, dataflow(CME) countries(ETH) clear verbose
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, dataflow(CME) countries(ETH) clear verbose" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    tab indicator
}
else {
    log_test_result "unicefdata, dataflow(CME) countries(ETH) clear verbose" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 2.8: Get N most recent values
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Get 5 most recent values (mrv)" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) mrv(5) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) mrv(5) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) mrv(5) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 2.9: Simplify and dropna
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Simplify output and drop NA" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) simplify dropna clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) simplify dropna clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    describe, short
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) simplify dropna clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 3: NEW v1.3.0 FEATURES
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 3: NEW v1.3.0 FEATURES" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 3.1: Wide format with indicators as columns
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Wide format (indicators as columns)" "`test_num'"

timer clear 1
timer on 1

* First fetch the data WITHOUT wide_indicators to capture diagnostics
capture noisily {
    unicefdata, dataflow(CME) countries(AFG BGD) clear
    local initial_obs = _N
    di as text "DEBUG: Initial fetch returned `initial_obs' observations"
    
    * Show disaggregation variables present
    capture confirm variable age
    if (_rc == 0) {
        di as text "DEBUG: age variable values:"
        tab age, missing
    }
    capture confirm variable sex  
    if (_rc == 0) {
        di as text "DEBUG: sex variable values:"
        tab sex, missing
    }
}

* Now test wide_indicators WITH VERBOSE to see filter diagnostics
capture noisily unicefdata, dataflow(CME) countries(AFG BGD) wide_indicators verbose clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    if (`obs' > 0) {
        log_test_result "unicefdata, dataflow(CME) countries(AFG BGD) wide_indicators clear" "PASS" "`elapsed'" "`obs'"
        local ++pass_count
        describe, short
    }
    else {
        di as error "DEBUG: wide_indicators returned 0 observations (filter may be too strict)"
        log_test_result "unicefdata, dataflow(CME) countries(AFG BGD) wide_indicators clear" "FAIL" "`elapsed'" "0"
        local ++fail_count
    }
}
else {
    di as error "DEBUG: Command failed with error code `rc'"
    log_test_result "unicefdata, dataflow(CME) countries(AFG BGD) wide_indicators clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 3.2: Add regional and income metadata
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Add regional and income metadata" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    capture tab region
    capture tab income_group
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 3.3: Circa matching
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Circa matching (closest year)" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4) year(2020) circa clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(CME_MRY0T4) year(2020) circa clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(CME_MRY0T4) year(2020) circa clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 4: NUTRITION INDICATORS
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 4: NUTRITION INDICATORS" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 4.1: Stunting prevalence
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Stunting prevalence" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(NT_ANT_HAZ_NE2) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(NT_ANT_HAZ_NE2) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(NT_ANT_HAZ_NE2) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 4.2: Stunting by wealth quintile
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Stunting by wealth quintile (Q1)" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(NT_ANT_HAZ_NE2) wealth(Q1) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(NT_ANT_HAZ_NE2) wealth(Q1) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(NT_ANT_HAZ_NE2) wealth(Q1) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 4.3: Stunting by residence (rural)
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Stunting by residence (rural)" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(NT_ANT_HAZ_NE2) residence(RURAL) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(NT_ANT_HAZ_NE2) residence(RURAL) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(NT_ANT_HAZ_NE2) residence(RURAL) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 5: IMMUNIZATION INDICATORS
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 5: IMMUNIZATION INDICATORS" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 5.1: DTP3 immunization coverage
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "DTP3 immunization coverage" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(IM_DTP3) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(IM_DTP3) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(IM_DTP3) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 5.2: Measles immunization coverage
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Measles immunization coverage" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(IM_MCV1) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(IM_MCV1) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(IM_MCV1) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 6: WASH INDICATORS
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 6: WASH INDICATORS" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 6.1: Basic drinking water services
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Basic drinking water services" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(WS_PPL_W-B) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(WS_PPL_W-B) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(WS_PPL_W-B) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 6.2: Basic sanitation services
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Basic sanitation services" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(WS_PPL_S-B) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(WS_PPL_S-B) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(WS_PPL_S-B) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 7: EDUCATION INDICATORS
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 7: EDUCATION INDICATORS" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 7.1: Completion rate, primary
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Completion rate, primary" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(ED_CR_L1) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(ED_CR_L1) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(ED_CR_L1) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 7.2: Net attendance rate, primary
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Net attendance rate, primary" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(ED_ANAR_L1) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "unicefdata, indicator(ED_ANAR_L1) clear" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "unicefdata, indicator(ED_ANAR_L1) clear" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 8: EXPORT EXAMPLES
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 8: EXPORT EXAMPLES" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 8.1: Download and export to Excel
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Export to Excel" "`test_num'"

timer clear 1
timer on 1

* Ensure fresh data load - independent of previous tests
local export_rc = 0
capture noisily {
    * Clear any existing data
    clear
    
    * Fresh fetch - use IM_DTP3 which is more reliably available
    unicefdata, indicator(IM_DTP3) countries(ALB USA BRA) clear
    local fetch_obs = _N
    di as text "DEBUG: Export test - fetched `fetch_obs' observations"
    
    if (`fetch_obs' == 0) {
        di as error "DEBUG: No data fetched, export will fail"
        error 2000
    }
    
    * Attempt export
    export excel using "test_mortality_data.xlsx", firstrow(variables) replace
}
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "Export to Excel" "PASS" "`elapsed'" "`fetch_obs'"
    local ++pass_count
    capture erase "test_mortality_data.xlsx"
}
else {
    di as error "DEBUG: Export to Excel failed with rc=`rc'"
    di as error "DEBUG: Current observation count: " _N
    log_test_result "Export to Excel" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 8.2: Download and export to CSV
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Export to CSV" "`test_num'"

timer clear 1
timer on 1
capture noisily {
    unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear
    export delimited using "test_mortality_data.csv", replace
}
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "Export to CSV" "PASS" "`elapsed'" ""
    local ++pass_count
    capture erase "test_mortality_data.csv"
}
else {
    log_test_result "Export to CSV" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 9: MULTIPLE INDICATORS
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 9: MULTIPLE INDICATORS" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 9.1: Multiple mortality indicators
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Multiple mortality indicators" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(CME_MRY0T4 CME_MRY0 CME_MRM0) countries(BRA MEX ARG) year(2020:2023) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "Multiple indicators (CME_MRY0T4 CME_MRY0 CME_MRM0)" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
    tab indicator
}
else {
    log_test_result "Multiple indicators (CME_MRY0T4 CME_MRY0 CME_MRM0)" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* -----------------------------------------------------------------------------
* Test 9.2: Multiple immunization indicators
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Multiple immunization indicators" "`test_num'"

timer clear 1
timer on 1
capture noisily unicefdata, indicator(IM_DTP3 IM_MCV1) year(2000:2023) clear
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    local obs = _N
    log_test_result "Multiple indicators (IM_DTP3 IM_MCV1)" "PASS" "`elapsed'" "`obs'"
    local ++pass_count
}
else {
    log_test_result "Multiple indicators (IM_DTP3 IM_MCV1)" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* SECTION 10: STORED RESULTS
* =============================================================================

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "SECTION 10: STORED RESULTS VALIDATION" _col(80) as text "|"
di as text "{hline 80}"

* -----------------------------------------------------------------------------
* Test 10.1: Verify stored results after data retrieval
* -----------------------------------------------------------------------------
local ++test_num
log_test_header "Verify stored results" "`test_num'"

timer clear 1
timer on 1
capture noisily {
    unicefdata, indicator(CME_MRY0T4) countries(BRA) year(2020:2023) clear
    
    * Check stored results
    assert "`r(indicator)'" == "CME_MRY0T4"
    assert "`r(dataflow)'" == "CME"
    assert "`r(countries)'" == "BRA"
    assert `r(obs_count)' > 0
    assert "`r(url)'" != ""
}
local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' == 0) {
    log_test_result "Verify stored results" "PASS" "`elapsed'" ""
    local ++pass_count
    di as text "  r(indicator): " as result "`r(indicator)'"
    di as text "  r(dataflow):  " as result "`r(dataflow)'"
    di as text "  r(obs_count): " as result "`r(obs_count)'"
}
else {
    log_test_result "Verify stored results" "FAIL" "`elapsed'" ""
    local ++fail_count
}

* =============================================================================
* FINAL SUMMARY
* =============================================================================

local suite_end = clock("`c(current_date)' `c(current_time)'", "DMY hms")
local suite_elapsed = (`suite_end' - `suite_start') / 1000

di ""
di as text "{hline 80}"
di as text "|" _col(5) as result "TEST SUITE SUMMARY" _col(80) as text "|"
di as text "{hline 80}"
di as text "|" _col(5) as text "Total tests:  " as result %4.0f `test_num' _col(80) as text "|"
di as text "|" _col(5) as text "Passed:       " as result %4.0f `pass_count' _col(30) as text " (" as result %5.1f 100*`pass_count'/`test_num' as text "%)" _col(80) "|"
di as text "|" _col(5) as text "Failed:       " as error %4.0f `fail_count' _col(80) as text "|"
di as text "|" _col(5) as text "Skipped:      " as text %4.0f `skip_count' _col(80) "|"
di as text "{hline 80}"
di as text "|" _col(5) as text "Total time:   " as result %8.2f `suite_elapsed' as text " seconds" _col(80) "|"
di as text "|" _col(5) as text "Completed:    " as result "`c(current_date)' `c(current_time)'" _col(80) as text "|"
di as text "{hline 80}"

* Store summary in scalars (accessible after do-file runs)
scalar total_tests = `test_num'
scalar passed = `pass_count'
scalar failed = `fail_count'
scalar skipped = `skip_count'
scalar elapsed = `suite_elapsed'

* Turn off trace before closing
set trace off

* Close log
di ""
di as text "Log saved to: " as result "`logfile'"

log close testlog

* Display final status (don't use exit to avoid closing Stata)
if (`fail_count' > 0) {
    di as error "Some tests failed. Review log for details."
}
else {
    di as result "All tests passed!"
}
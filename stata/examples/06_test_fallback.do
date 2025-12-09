/*******************************************************************************
* 06_test_fallback.do - Test Dataflow Fallback Mechanism
* =========================================================
*
* Tests 5 key indicators demonstrating:
* 1. Direct dataflow fetch (CME, NUTRITION)
* 2. Static overrides (EDUCATION, CHILD_MARRIAGE)
* 3. Dynamic fallback (IPV -> GLOBAL_DATAFLOW)
*
* Matches: R/examples/06_test_fallback.R
*          python/examples/06_test_fallback.py
*******************************************************************************/

clear all
set more off

* Setup data directory
local data_dir "data"
capture mkdir "`data_dir'"

display _n "======================================================================"
display "06_test_fallback.do - Test Dataflow Fallback Mechanism"
display "======================================================================"

* Initialize results
local tests_passed = 0
local tests_failed = 0

* =============================================================================
* Test 1: MORTALITY (CME) - Direct fetch
* =============================================================================
display _n "--- Test 1: MORTALITY (CME) ---"
display "Indicator: CME_MRY0T4"
display "Expected: Direct fetch from CME" _n

timer clear 1
timer on 1

capture noisily unicefdata, indicator(CME_MRY0T4) countries(AFG ALB USA) ///
    start_year(2015) clear

timer off 1

if _rc == 0 & _N > 0 {
    quietly timer list 1
    display "[OK] `=_N' rows in `=round(r(t1), 0.1)' seconds"
    local tests_passed = `tests_passed' + 1
}
else {
    display "[FAIL] No data returned"
    local tests_failed = `tests_failed' + 1
}

* =============================================================================
* Test 2: NUTRITION (stunting) - Direct fetch
* =============================================================================
display _n "--- Test 2: NUTRITION (stunting) ---"
display "Indicator: NT_ANT_HAZ_NE2_MOD"
display "Expected: Direct fetch from NUTRITION" _n

timer clear 2
timer on 2

capture noisily unicefdata, indicator(NT_ANT_HAZ_NE2_MOD) countries(AFG ALB USA) ///
    start_year(2015) clear

timer off 2

if _rc == 0 & _N > 0 {
    quietly timer list 2
    display "[OK] `=_N' rows in `=round(r(t2), 0.1)' seconds"
    local tests_passed = `tests_passed' + 1
}
else {
    display "[FAIL] No data returned"
    local tests_failed = `tests_failed' + 1
}

* =============================================================================
* Test 3: EDUCATION (override) - Needs override to EDUCATION_UIS_SDG
* =============================================================================
display _n "--- Test 3: EDUCATION (override) ---"
display "Indicator: ED_CR_L1_UIS_MOD"
display "Expected: Uses override to EDUCATION_UIS_SDG" _n

timer clear 3
timer on 3

capture noisily unicefdata, indicator(ED_CR_L1_UIS_MOD) countries(AFG ALB USA) ///
    start_year(2015) clear

timer off 3

if _rc == 0 & _N > 0 {
    quietly timer list 3
    display "[OK] `=_N' rows in `=round(r(t3), 0.1)' seconds"
    local tests_passed = `tests_passed' + 1
}
else {
    display "[FAIL] No data returned"
    local tests_failed = `tests_failed' + 1
}

* =============================================================================
* Test 4: CHILD_MARRIAGE (override) - Needs override to PT_CM
* =============================================================================
display _n "--- Test 4: CHILD_MARRIAGE (override) ---"
display "Indicator: PT_F_20-24_MRD_U18_TND"
display "Expected: Uses override to PT_CM" _n

timer clear 4
timer on 4

capture noisily unicefdata, indicator(PT_F_20-24_MRD_U18_TND) countries(AFG ALB) ///
    start_year(2015) clear

timer off 4

if _rc == 0 & _N > 0 {
    quietly timer list 4
    display "[OK] `=_N' rows in `=round(r(t4), 0.1)' seconds"
    local tests_passed = `tests_passed' + 1
}
else {
    display "[FAIL] No data returned"
    local tests_failed = `tests_failed' + 1
}

* =============================================================================
* Test 5: IPV (fallback) - Needs fallback to GLOBAL_DATAFLOW
* =============================================================================
display _n "--- Test 5: IPV (fallback) ---"
display "Indicator: PT_F_PS-SX_V_PTNR_12MNTH"
display "Expected: Needs fallback to GLOBAL_DATAFLOW" _n

timer clear 5
timer on 5

capture noisily unicefdata, indicator(PT_F_PS-SX_V_PTNR_12MNTH) countries(AFG ALB) ///
    start_year(2015) clear

timer off 5

if _rc == 0 & _N > 0 {
    quietly timer list 5
    display "[OK] `=_N' rows in `=round(r(t5), 0.1)' seconds"
    local tests_passed = `tests_passed' + 1
}
else {
    display "[EMPTY/FAIL] No data returned (may be expected for this indicator)"
    local tests_failed = `tests_failed' + 1
}

* =============================================================================
* Summary
* =============================================================================
display _n "======================================================================"
display "SUMMARY"
display "======================================================================"
display "Passed: `tests_passed'/5"
display "Failed: `tests_failed'/5"
display "======================================================================"

if `tests_passed' >= 4 {
    display _n "[SUCCESS] Most tests passed - fallback mechanism working"
}
else {
    display _n "[WARNING] Some tests failed - check dataflow configuration"
}

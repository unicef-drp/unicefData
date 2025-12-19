/*******************************************************************************
* test_multi_indicator.do - Test multiple indicator fetch
* Tests the fix for multiple indicators being fetched separately and appended
*******************************************************************************/

clear all
set more off

display _n "======================================================================"
display "Testing Multiple Indicator Fetch"
display "======================================================================"

* Test: Multiple indicators from same dataflow (CME)
display _n "--- Test 1: Multiple CME indicators ---"
unicefdata, indicator(CME_MRM0 CME_MRY0T4) countries(ALB USA) ///
    start_year(2020) end_year(2022) clear verbose

if (_N > 0) {
    display as result "SUCCESS: " _N " rows fetched"
    tab indicator
}
else {
    display as error "FAILED: No data returned"
}

* Test: Multiple indicators from different dataflows
display _n "--- Test 2: Indicators from different dataflows ---"
unicefdata, indicator(CME_MRY0T4 NT_ANT_WHZ_NE2) countries(ALB) ///
    start_year(2015) end_year(2020) clear verbose

if (_N > 0) {
    display as result "SUCCESS: " _N " rows fetched"
    tab indicator
}
else {
    display as error "FAILED: No data returned"
}

display _n "======================================================================"
display "Multi-indicator tests complete"
display "======================================================================"

* Quick test of wide_indicators fix
* Tests the expanded age filter and verbose diagnostics

clear all
set more off
local timestamp = subinstr("`c(current_date)'`c(current_time)'", " ", "", .)
local timestamp = subinstr("`timestamp'", ":", "", .)
log using "quick_test_wide_`timestamp'.log", replace text

di as text "{hline 80}"
di as result "Testing wide_indicators with verbose diagnostics"
di as text "{hline 80}"

* Test 1: Fetch CME data without wide_indicators to see what age codes are present
di ""
di as text "=== Test 1: Fetch CME data for AFG BGD (no wide_indicators) ==="
unicefdata, dataflow(CME) countries(AFG BGD) clear
di "Total observations: " _N

di ""
di as text "Age variable distribution:"
capture confirm variable age
if (_rc == 0) {
    tab age, missing
}
else {
    di as text "(age variable not present)"
}

di ""
di as text "Sex variable distribution:"  
capture confirm variable sex
if (_rc == 0) {
    tab sex, missing
}
else {
    di as text "(sex variable not present)"
}

di ""
di as text "Wealth variable distribution:"  
capture confirm variable wealth
if (_rc == 0) {
    tab wealth, missing
}
else {
    di as text "(wealth variable not present)"
}

di ""
di as text "Residence variable distribution:"  
capture confirm variable residence
if (_rc == 0) {
    tab residence, missing
}
else {
    di as text "(residence variable not present)"
}

di ""
di as text "All variables in dataset:"
describe, short

* Test 2: Now with wide_indicators and verbose
di ""
di as text "{hline 80}"
di as text "=== Test 2: wide_indicators with VERBOSE ==="
unicefdata, dataflow(CME) countries(AFG BGD) wide_indicators verbose clear
di "Resulting observations: " _N

if (_N > 0) {
    di as result "SUCCESS: wide_indicators produced data"
    describe, short
}
else {
    di as error "FAILURE: wide_indicators produced 0 observations"
}

* Test 3: Export test to ensure data is available
di ""
di as text "{hline 80}"
di as text "=== Test 3: Export to Excel test ==="

* Use a more reliable indicator for export test (immunization data)
unicefdata, indicator(IM_DTP3) countries(ALB USA BRA) clear
di "Fetched observations: " _N

if (_N > 0) {
    export excel using "quick_test_export.xlsx", firstrow(variables) replace
    di as result "SUCCESS: Export to Excel completed"
    capture erase "quick_test_export.xlsx"
}
else {
    di as error "FAILURE: No data to export"
    di as text "Note: Try a different indicator if this fails consistently"
}

log close
di ""
di as result "Quick test completed - check quick_test_wide.log for details"

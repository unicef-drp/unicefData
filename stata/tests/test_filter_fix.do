* Test the filter vector fix
clear all
set more off

adopath ++ "c:\GitHub\myados\unicefData-dev\stata\src"

di ""
di "=========================================="
di "Test: CME_MRY0T4 with sex(ALL) and year(2020)"
di "Expected URL should have: CME,1.0/...CME_MRY0T4._T"
di "NOT: CME_MRY0T4..CME_MRY0T4...."
di "=========================================="
di ""

discard
capture noisily unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) sex(ALL) clear
if _rc == 0 {
    di ""
    di "Result: Data retrieved successfully"
    di "Returned URL: " r(url)
}
else {
    di ""
    di "Result: Command failed with error code " _rc
}

di ""
di "=========================================="

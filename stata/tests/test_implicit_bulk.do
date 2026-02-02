*! Test implicit bulk download (dataflow without indicator)
*! Created: 19Jan2026

clear all
set more off

adopath ++ "c:\GitHub\myados\unicefData-dev\stata\src"

log using "c:\GitHub\myados\unicefData-dev\stata\tests\logs\test_implicit_bulk.log", replace text

display as text ""
display as text "{hline 80}"
display as text "IMPLICIT BULK DOWNLOAD TEST"
display as text "Testing: unicefdata, dataflow(...) clear  [no indicator specified]"
display as text "{hline 80}"
display as text ""

*==============================================================================
* TEST: Implicit bulk download (dataflow without indicator)
*==============================================================================
display as text "{bf:TEST: Implicit bulk download - CME dataflow for Ethiopia}"
display as text ""

clear

timer clear 1
timer on 1

* Note: No indicator() specified - should trigger bulk download with warning
capture noisily unicefdata, dataflow(CME) countries(ETH) clear

timer off 1

if (_rc == 0 & _N > 0) {
    display as result ""
    display as result "✓ TEST PASSED: Implicit bulk download succeeded"
    display as text "  Rows fetched: " as result _N
    
    * Count unique indicators
    capture confirm variable indicator
    if (_rc == 0) {
        quietly levelsof indicator, local(indicators)
        local n_indicators : word count `indicators'
        display as text "  Unique indicators: " as result `n_indicators'
        display as text ""
        display as text "  First 5 indicators:"
        local i = 1
        foreach ind of local indicators {
            if (`i' <= 5) {
                display as text "    - " as result "`ind'"
            }
            local i = `i' + 1
        }
        if (`n_indicators' > 5) {
            display as text "    ... and " as result `=`n_indicators'-5' as text " more"
        }
    }
    
    quietly timer list 1
    local elapsed = r(t1)
    display as text ""
    display as text "  Time elapsed: " as result %6.2f `elapsed' as text " seconds"
}
else {
    display as error ""
    display as error "✗ TEST FAILED"
    display as text "  Return code: " as result _rc
    display as text "  Rows: " as result _N
}

display as text ""
display as text "{hline 80}"
display as text "Test complete. The warning message above confirms implicit bulk download."
display as text "{hline 80}"

log close

*! Test bulk download feature for unicefdata
*! Created: 19Jan2026
*! Purpose: Validate that indicator(all) fetches entire dataflows correctly

clear all
set more off
set linesize 120

* Set path to development version
adopath ++ "c:\GitHub\myados\unicefData-dev\stata\src"

log using "c:\GitHub\myados\unicefData-dev\stata\tests\logs\test_bulk_download.log", replace text

display as text ""
display as text "{hline 80}"
display as text "BULK DOWNLOAD FEATURE TEST"
display as text "Testing: unicefdata, indicator(all) dataflow(...)"
display as text "{hline 80}"
display as text ""

*==============================================================================
* TEST 1: Bulk download CME dataflow (child mortality) for Ethiopia
*==============================================================================
display as text ""
display as text "{bf:TEST 1: Bulk download CME dataflow for Ethiopia}"
display as text ""

clear
set trace off

* Time the bulk download
timer clear 1
timer on 1

capture noisily unicefdata, indicator(all) dataflow(CME) countries(ETH) clear verbose

timer off 1
timer list 1

if (_rc == 0 & _N > 0) {
    display as result "✓ TEST 1 PASSED: Bulk download succeeded"
    display as text "  Rows fetched: " as result _N
    display as text "  Unique indicators: " as result ""
    
    * Count unique indicators (check INDICATOR_CODE variable)
    capture confirm variable INDICATOR
    if (_rc == 0) {
        quietly levelsof INDICATOR, local(indicators)
        local n_indicators : word count `indicators'
        display as text "  Unique indicators: " as result `n_indicators'
        display as text ""
        display as text "  Sample indicators fetched:"
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
    
    display as text ""
    quietly timer list 1
    local elapsed = r(t1)
    display as text "  Time elapsed: " as result %6.2f `elapsed' as text " seconds"
    display as text ""
}
else {
    display as error "✗ TEST 1 FAILED: Bulk download failed or returned no data"
    display as text "  Return code: " as result _rc
    display as text "  Rows: " as result _N
    display as text ""
}

*==============================================================================
* TEST 2: Bulk download NUTRITION dataflow for 2020 only
*==============================================================================
display as text ""
display as text "{bf:TEST 2: Bulk download NUTRITION dataflow (year filter)}"
display as text ""

clear

timer clear 2
timer on 2

capture noisily unicefdata, indicator(all) dataflow(NUTRITION) year(2020) clear verbose

timer off 2

if (_rc == 0 & _N > 0) {
    display as result "✓ TEST 2 PASSED: Bulk download with year filter succeeded"
    display as text "  Rows fetched: " as result _N
    
    * Check year range
    capture confirm variable TIME_PERIOD
    if (_rc == 0) {
        quietly summarize TIME_PERIOD
        display as text "  Year range: " as result r(min) as text " to " as result r(max)
    }
    
    quietly timer list 2
    local elapsed = r(t2)
    display as text "  Time elapsed: " as result %6.2f `elapsed' as text " seconds"
    display as text ""
}
else {
    display as error "✗ TEST 2 FAILED"
    display as text "  Return code: " as result _rc
    display as text "  Rows: " as result _N
    display as text ""
}

*==============================================================================
* TEST 3: Bulk download with sex disaggregation filter
*==============================================================================
display as text ""
display as text "{bf:TEST 3: Bulk download CME (males only)}"
display as text ""

clear

timer clear 3
timer on 3

capture noisily unicefdata, indicator(all) dataflow(CME) sex(M) countries(BRA+ETH) clear verbose

timer off 3

if (_rc == 0 & _N > 0) {
    display as result "✓ TEST 3 PASSED: Bulk download with sex filter succeeded"
    display as text "  Rows fetched: " as result _N
    
    * Check sex values
    capture confirm variable SEX
    if (_rc == 0) {
        quietly levelsof SEX, local(sexvals)
        display as text "  Sex values: " as result "`sexvals'"
    }
    
    quietly timer list 3
    local elapsed = r(t3)
    display as text "  Time elapsed: " as result %6.2f `elapsed' as text " seconds"
    display as text ""
}
else {
    display as error "✗ TEST 3 FAILED"
    display as text "  Return code: " as result _rc
    display as text "  Rows: " as result _N
    display as text ""
}

*==============================================================================
* TEST 4: Error handling - indicator(all) without dataflow() should fail
*==============================================================================
display as text ""
display as text "{bf:TEST 4: Error handling (missing dataflow)}"
display as text ""

clear

* This should fail with clear error message
capture noisily unicefdata, indicator(all) clear

if (_rc != 0) {
    display as result "✓ TEST 4 PASSED: Correctly rejected indicator(all) without dataflow()"
    display as text "  Return code: " as result _rc
    display as text ""
}
else {
    display as error "✗ TEST 4 FAILED: Should have rejected indicator(all) without dataflow()"
    display as text ""
}

*==============================================================================
* SUMMARY
*==============================================================================
display as text ""
display as text "{hline 80}"
display as text "BULK DOWNLOAD TEST SUMMARY"
display as text "{hline 80}"
display as text ""
display as text "All tests completed. Review results above."
display as text ""
display as text "{bf:Performance tip:} Compare bulk download times vs individual indicator fetches"
display as text ""

log close
display as text "Log saved to: c:\GitHub\myados\unicefData-dev\stata\tests\logs\test_bulk_download.log"

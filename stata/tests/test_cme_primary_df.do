* Quick test of CME primary dataflow selection
clear all
set more off

* Add ado path
adopath ++ "c:\GitHub\myados\unicefData-dev\stata\src"

* Test: CME indicator should use CME dataflow (not GLOBAL_DATAFLOW)
di "Testing CME_TMY20T24 indicator..."
di "Expected: dataflow should be 'CME'"
di ""

capture noisily unicefdata, indicator(CME_TMY20T24) sex(all) clear verbose
if _rc == 0 {
    di ""
    di "✓ Success! Data fetched"
    di "  Returned dataflow: " r(dataflow)
    di "  Returned indicator: " r(indicator)
    di "  Returned URL: " r(url)
    di "  Observations: " r(obs_count)
}
else {
    di "✗ Error fetching CME_TMY20T24"
    di "  Error code: " _rc
}

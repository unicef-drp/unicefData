// Test sync with both parsers
clear all
set more off

// Add ado paths
adopath ++ "D:/jazevedo/GitHub/unicefData/stata/src/u"
adopath ++ "D:/jazevedo/GitHub/unicefData/stata/src/_"

cap log close
log using "D:/jazevedo/GitHub/unicefData/stata/log/test_sync_both.log", replace text

di as text _n "=============================================="
di as text "Testing unicefdata_sync with both parsers"
di as text "=============================================="

// Test 1: Stata-only parser
di as text _n "--- Test 1: Stata-only parser (forcestata) ---"
unicefdata_sync, verbose forcestata suffix("_test_stataonly")

// Test 2: Python parser  
di as text _n "--- Test 2: Python parser (forcepython) ---"
unicefdata_sync, verbose forcepython suffix("_test_python")

di as text _n "=============================================="
di as text "Both tests completed"
di as text "=============================================="

log close

exit, clear STATA

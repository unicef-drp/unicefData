*! Quick pagination test with file logging
clear all
set more off

* Start log
log using "test_paging_output.log", replace text

* Add ado path
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

* Test basic fetch
display as text "Testing unicefdata with verbose..."
unicefdata, indicator(CME_MRY0T4) startyear(2020) endyear(2023) clear verbose

display as result _n "Dataset loaded: `=_N' observations"
display as text "Variables: `: word count `r(varlist)''"
list in 1/5

* Check if paging was triggered
display as text _n "Schema check:"
describe, simple

* Close log
log close
display as text "Log saved to test_paging_output.log"

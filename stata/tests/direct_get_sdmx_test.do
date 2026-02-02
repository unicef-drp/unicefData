*! Direct get_sdmx test to isolate paging logic
clear all
set more off

log using "direct_get_sdmx_test.log", replace text

* Add ado path
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

* Test get_sdmx directly (bypasses unicefdata.ado wrapper logic)
display as text "{hline 60}"
display as text "Direct get_sdmx test with paging"
display as text "{hline 60}"

get_sdmx CME_MRY0T4, ///
  dataflow(CME) ///
  version(1.0) ///
  start_period(2020) ///
  end_period(2023) ///
  verbose ///
  clear

* Check results
display as result _n "✓ get_sdmx completed successfully"
display as result "Rows loaded: `=_N'"
display as result "Variables: `: word count `c(varlist)''"

* Show first few rows
list in 1/5, clean noobs

* Summarize
describe, simple
summarize

log close
display as text "Test complete - see direct_get_sdmx_test.log"

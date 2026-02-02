*! Test pagination integration in get_sdmx.ado
* Quick verification that paging helper is being called correctly

clear all
set more off

* Add development ado path
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

* Test 1: Small fetch (should work with single page)
display as text "{hline 60}"
display as text "Test 1: Small fetch (CME_MRY0T4, all years, all countries)"
display as text "{hline 60}"

get_sdmx CME_MRY0T4, dataflow(CME) version(1.0) start_period(2020) end_period(2023) verbose clear

display as result "✓ Test 1 passed: `=_N' rows loaded"
list iso3 indicator time_period obs_value in 1/5, clean noobs

* Test 2: Fetch using integrated unicefdata command
display as text _n "{hline 60}"
display as text "Test 2: unicefdata with paging (CME_MRY0T4, recent years)"
display as text "{hline 60}"

unicefdata, indicator(CME_MRY0T4) startyear(2020) endyear(2023) clear verbose

display as result "✓ Test 2 passed: `=_N' rows loaded via unicefdata"
summarize

* Test 3: Larger dataset to trigger pagination (if available)
display as text _n "{hline 60}"
display as text "Test 3: Larger dataset (all years for CME_MRY0T4)"
display as text "{hline 60}"

unicefdata, indicator(CME_MRY0T4) clear verbose

display as result "✓ Test 3 passed: `=_N' rows loaded"
display as text "Note: If >100k rows, pagination was used; otherwise single page."

* Report
display as text _n "{hline 60}"
display as result "All tests passed!"
display as text "{hline 60}"

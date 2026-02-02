* Manual test for get_sdmx wide option with clear

adopath ++ "c:\GitHub\myados\unicefData-dev\stata\src"
discard

di as text "Testing: get_sdmx wide option with clear"
di as text "========================================="

* Create some data first to test that clear works
clear
set obs 10
gen x = _n
di "Initial data created: " _N " observations"

di ""
di as text "Now calling get_sdmx with wide and clear options..."
get_sdmx, indicator(CME_MRY0T4) countries(USA) start_period(2020) end_period(2020) wide clear verbose

di as result "SUCCESS: get_sdmx wide clear option worked!"
di ""
di as text "Variables created:"
desc
di ""
di as text "Data:"
list

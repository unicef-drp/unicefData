* test_diagnose.do — Quick test for the diagnose option
* Run: stata -b do test_diagnose.do

clear all
set more off

di "=== Test: diagnose option ==="
di "Date: `c(current_date)' `c(current_time)'"
di "Stata: `c(stata_version)'"
di ""

* Use adopath to load repo version instead of installed version
local statadir = subinstr(c(pwd), "/qa", "", 1)
local statadir = subinstr("`statadir'", "\qa", "", 1)
di "Repo: `statadir'"

* Drop any cached programs so Stata reloads from the new adopath
cap program drop unicefdata
cap program drop _unicef_indicator_info
cap program drop _unicef_build_schema_key
cap program drop _unicef_search_indicators
cap program drop __unicef_parse_ind_yaml_v2

* Prepend repo paths BEFORE PLUS
adopath ++ "`statadir'/src"
adopath ++ "`statadir'/src/u"
adopath ++ "`statadir'/src/_"
adopath ++ "`statadir'/src/g"
adopath ++ "`statadir'/src/y"

* Verify we're running the repo version
which unicefdata

di ""
di "=== TEST 1: Basic fetch without diagnose ==="
cap noi unicefdata, indicator(CME_MRY0T4) countries(BRA) year(2020) clear
di "RC: `=_rc'"
di "N: `=_N'"

di ""
di "=== TEST 2: Fetch with diagnose (year with data) ==="
cap noi unicefdata, indicator(CME_MRY0T4) countries(BRA) year(2020) diagnose clear
di "RC: `=_rc'"
di "N: `=_N'"
cap return list

di ""
di "=== TEST 3: Fetch with diagnose (year beyond range - 2029) ==="
cap noi unicefdata, indicator(CME_MRY0T4) countries(BRA) year(2029) diagnose clear
di "RC: `=_rc'"
di "N: `=_N'"
cap return list

di ""
di "=== TEST 4: Survey indicator MNCH_CSEC with diagnose ==="
cap noi unicefdata, indicator(MNCH_CSEC) countries(BRA) year(2020) diagnose clear
di "RC: `=_rc'"
di "N: `=_N'"
cap return list

di ""
di "=== ALL TESTS COMPLETE ==="
exit

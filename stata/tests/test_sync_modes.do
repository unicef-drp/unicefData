/*******************************************************************************
* Test: unicefdata_sync with forcepython and forcestata options
* Tests both parsing modes and compares output
*******************************************************************************/

clear all
set more off

* Set up adopath
adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\u"
adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\_"

* Output directory
local outdir "D:\jazevedo\GitHub\unicefData\stata\metadata\current"

di _n _dup(80) "="
di "TEST 1: Sync with FORCEPYTHON (Python parser)"
di _dup(80) "="

* Clear existing files
capture shell del "`outdir'\*.yaml" /Q

* Run sync with Python
unicefdata_sync, path("`outdir'\..") verbose forcepython

di _n "Files created with Python parser:"
local files : dir "`outdir'" files "*.yaml"
foreach f of local files {
    di "  - `f'"
}

* Save Python results
local py_dataflows = r(n_dataflows)
local py_countries = r(n_countries)
local py_regions = r(n_regions)

di _n "Python results: `py_dataflows' dataflows, `py_countries' countries, `py_regions' regions"

di _n _dup(80) "="
di "TEST 2: Sync with FORCESTATA (Pure Stata parser)"
di _dup(80) "="

* Clear existing files
capture shell del "`outdir'\*.yaml" /Q

* Run sync with Stata-only
unicefdata_sync, path("`outdir'\..") verbose forcestata

di _n "Files created with Stata parser:"
local files : dir "`outdir'" files "*.yaml"
foreach f of local files {
    di "  - `f'"
}

* Save Stata results
local st_dataflows = r(n_dataflows)
local st_countries = r(n_countries)
local st_regions = r(n_regions)

di _n "Stata results: `st_dataflows' dataflows, `st_countries' countries, `st_regions' regions"

di _n _dup(80) "="
di "COMPARISON"
di _dup(80) "="
di "Dataflows: Python=`py_dataflows' vs Stata=`st_dataflows'"
di "Countries: Python=`py_countries' vs Stata=`st_countries'"
di "Regions:   Python=`py_regions' vs Stata=`st_regions'"

if (`py_dataflows' == `st_dataflows' & `py_countries' == `st_countries' & `py_regions' == `st_regions') {
    di _n as result "✓ SUCCESS: Both parsers produced identical counts!"
}
else {
    di _n as error "✗ WARNING: Parser outputs differ - review generated files"
}

di _n "Test completed."
exit, clear

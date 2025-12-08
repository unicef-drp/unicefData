/*******************************************************************************
* Test: unicefdata_sync with forcepython and forcestata options
* Tests both parsing modes and compares output
* 
* Run this test from Stata:
*   do "D:\jazevedo\GitHub\unicefData\stata\tests\test_sync_parser_modes.do"
*******************************************************************************/

clear all
set more off
set trace off

* Set up adopath
adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\u"
adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\_"

* Output directories
local outdir_stata "D:\jazevedo\GitHub\unicefData\stata\metadata\test_stata"
local outdir_python "D:\jazevedo\GitHub\unicefData\stata\metadata\test_python"
local logdir "D:\jazevedo\GitHub\unicefData\stata\log"

* Create test directories
capture mkdir "`outdir_stata'"
capture mkdir "`outdir_stata'/current"
capture mkdir "`outdir_python'"
capture mkdir "`outdir_python'/current"

* Start log
log using "`logdir'/test_sync_parser_modes.log", replace text

di _n _dup(80) "="
di "TEST: Parser Mode Comparison"
di "Date: `c(current_date)' `c(current_time)'"
di _dup(80) "="

*-------------------------------------------------------------------------------
* TEST 1: Sync with FORCESTATA (Pure Stata parser)
*-------------------------------------------------------------------------------

di _n _dup(80) "-"
di "TEST 1: FORCESTATA (Pure Stata parser)"
di _dup(80) "-"

* Clear existing files
capture shell del "`outdir_stata'\current\*.yaml" /Q 2>nul

* Run sync with pure Stata parser
capture noisily unicefdata_sync, path("`outdir_stata'") verbose forcestata

local st_rc = _rc
if (`st_rc' == 0) {
    local st_dataflows = r(dataflows)
    local st_countries = r(countries)
    local st_regions = r(regions)
    local st_indicators = r(indicators)
    
    di _n as result "✓ FORCESTATA completed successfully"
    di as text "  Dataflows:  " as result "`st_dataflows'"
    di as text "  Countries:  " as result "`st_countries'"
    di as text "  Regions:    " as result "`st_regions'"
    di as text "  Indicators: " as result "`st_indicators'"
}
else {
    di as err "✗ FORCESTATA failed with error `st_rc'"
    local st_dataflows = .
    local st_countries = .
    local st_regions = .
    local st_indicators = .
}

di _n "Files created with Stata parser:"
local files : dir "`outdir_stata'/current" files "*.yaml"
foreach f of local files {
    di "  - `f'"
}

*-------------------------------------------------------------------------------
* TEST 2: Sync with FORCEPYTHON (Python parser)
*-------------------------------------------------------------------------------

di _n _dup(80) "-"
di "TEST 2: FORCEPYTHON (Python parser via unicefdata_xmltoyaml)"
di _dup(80) "-"

* Clear existing files
capture shell del "`outdir_python'\current\*.yaml" /Q 2>nul

* Run sync with Python parser
capture noisily unicefdata_sync, path("`outdir_python'") verbose forcepython

local py_rc = _rc
if (`py_rc' == 0) {
    local py_dataflows = r(dataflows)
    local py_countries = r(countries)
    local py_regions = r(regions)
    local py_indicators = r(indicators)
    
    di _n as result "✓ FORCEPYTHON completed successfully"
    di as text "  Dataflows:  " as result "`py_dataflows'"
    di as text "  Countries:  " as result "`py_countries'"
    di as text "  Regions:    " as result "`py_regions'"
    di as text "  Indicators: " as result "`py_indicators'"
}
else {
    di as err "✗ FORCEPYTHON failed with error `py_rc'"
    di as text "  (This is expected if Python/unicefdata_xmltoyaml is not available)"
    local py_dataflows = .
    local py_countries = .
    local py_regions = .
    local py_indicators = .
}

di _n "Files created with Python parser:"
local files : dir "`outdir_python'/current" files "*.yaml"
foreach f of local files {
    di "  - `f'"
}

*-------------------------------------------------------------------------------
* COMPARISON
*-------------------------------------------------------------------------------

di _n _dup(80) "="
di "COMPARISON SUMMARY"
di _dup(80) "="

di _n "                    Stata       Python"
di    "  Dataflows:        `st_dataflows'          `py_dataflows'"
di    "  Countries:        `st_countries'         `py_countries'"
di    "  Regions:          `st_regions'         `py_regions'"
di    "  Indicators:       `st_indicators'          `py_indicators'"

if (`st_rc' == 0 & `py_rc' == 0) {
    if (`st_dataflows' == `py_dataflows' & `st_countries' == `py_countries' & `st_regions' == `py_regions') {
        di _n as result "✓ SUCCESS: Both parsers produced identical counts!"
    }
    else {
        di _n as error "⚠ WARNING: Parser outputs differ - review generated files"
    }
}
else if (`st_rc' == 0) {
    di _n as text "Note: Only Stata parser succeeded. Python parser may require additional setup."
}
else {
    di _n as error "✗ Both parsers failed - check configuration"
}

di _n "Test completed at `c(current_date)' `c(current_time)'"
log close

exit, clear

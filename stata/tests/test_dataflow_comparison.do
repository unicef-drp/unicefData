/*******************************************************************************
* Test: Compare dataflow extraction with forcestata vs forcepython
*******************************************************************************/

clear all
set more off
set trace off

* Change to project directory
cd "D:\jazevedo\GitHub\unicefData"

* Set up adopath
adopath ++ "stata/src/u"
adopath ++ "stata/src/_"

* Start log
log using "stata/log/test_dataflow_comparison.log", replace text

di _n _dup(80) "="
di "TEST: Dataflow Extraction Comparison"
di "Date: `c(current_date)' `c(current_time)'"
di _dup(80) "="

*-------------------------------------------------------------------------------
* TEST 1: forcestata with suffix
*-------------------------------------------------------------------------------

di _n _dup(80) "-"
di "TEST 1: unicefdata_sync, verbose forcestata suffix(_stataonly)"
di _dup(80) "-"

timer clear 1
timer on 1

unicefdata_sync, verbose forcestata suffix("_stataonly")

timer off 1

local st_dataflows = r(dataflows)
local st_countries = r(countries)
local st_regions = r(regions)

di _n "FORCESTATA Results:"
di "  Dataflows:  `st_dataflows'"
di "  Countries:  `st_countries'"
di "  Regions:    `st_regions'"

timer list 1
local st_time = r(t1)

*-------------------------------------------------------------------------------
* TEST 2: forcepython (no suffix - standard files)
*-------------------------------------------------------------------------------

di _n _dup(80) "-"
di "TEST 2: unicefdata_sync, verbose forcepython"
di _dup(80) "-"

timer clear 2
timer on 2

capture noisily unicefdata_sync, verbose forcepython

local py_rc = _rc
timer off 2

if (`py_rc' == 0) {
    local py_dataflows = r(dataflows)
    local py_countries = r(countries)
    local py_regions = r(regions)
    
    di _n "FORCEPYTHON Results:"
    di "  Dataflows:  `py_dataflows'"
    di "  Countries:  `py_countries'"
    di "  Regions:    `py_regions'"
    
    timer list 2
    local py_time = r(t2)
}
else {
    di as err "FORCEPYTHON failed with error `py_rc'"
    di as text "(This may be expected if Python/unicefdata_xmltoyaml is not configured)"
    local py_dataflows = .
    local py_countries = .
    local py_regions = .
    local py_time = .
}

*-------------------------------------------------------------------------------
* COMPARISON
*-------------------------------------------------------------------------------

di _n _dup(80) "="
di "COMPARISON SUMMARY"
di _dup(80) "="

di _n "                    Stata-only     Python"
di    "  Dataflows:        `st_dataflows'             `py_dataflows'"
di    "  Countries:        `st_countries'            `py_countries'"
di    "  Regions:          `st_regions'            `py_regions'"
di    "  Time (seconds):   " %6.2f `st_time' "         " %6.2f `py_time'

if (`py_rc' == 0) {
    if (`st_dataflows' == `py_dataflows' & `st_countries' == `py_countries' & `st_regions' == `py_regions') {
        di _n as result "✓ SUCCESS: Both parsers produced identical counts!"
    }
    else {
        di _n as error "⚠ WARNING: Parser outputs differ"
    }
}

di _n "Files created:"
di _n "Stata-only files (*_stataonly.yaml):"
dir "stata/metadata/current/*_stataonly.yaml"

di _n "Standard files (no suffix):"
dir "stata/metadata/current/_unicefdata_dataflows.yaml"
dir "stata/metadata/current/_unicefdata_countries.yaml"
dir "stata/metadata/current/_unicefdata_regions.yaml"

log close
exit, clear

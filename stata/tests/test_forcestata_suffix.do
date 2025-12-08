/*******************************************************************************
* Test: unicefdata_sync with forcestata and suffix options
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
log using "stata/log/test_forcestata_suffix.log", replace text

di _n _dup(80) "="
di "TEST: unicefdata_sync, verbose forcestata suffix(_stataonly)"
di "Date: `c(current_date)' `c(current_time)'"
di _dup(80) "="

* Run sync with pure Stata parser and suffix
unicefdata_sync, verbose forcestata suffix("_stataonly")

di _n _dup(80) "-"
di "Results:"
di "  Dataflows:  " r(dataflows)
di "  Countries:  " r(countries)
di "  Regions:    " r(regions)
di "  Indicators: " r(indicators)
di _dup(80) "-"

di _n "Files created:"
dir "stata/metadata/current/*_stataonly.yaml"

log close
exit, clear

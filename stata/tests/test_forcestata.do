/*******************************************************************************
* Quick test for forcestata option
*******************************************************************************/

clear all
set more off
set trace off

adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\u"
adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\_"

log using "D:\jazevedo\GitHub\unicefData\stata\log\test_forcestata.log", replace text

di _n "Testing unicefdata_sync with FORCESTATA option"
di _dup(60) "="

unicefdata_sync, path("stata/metadata/") verbose forcestata

di _n "Result: " r(dataflows) " dataflows, " r(countries) " countries, " r(regions) " regions"

log close
exit, clear

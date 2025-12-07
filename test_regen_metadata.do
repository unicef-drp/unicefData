* Test metadata regeneration with fixes
* This script regenerates all metadata files to verify the fixes

clear all
set more off

* Add ado path
adopath ++ "D:/jazevedo/GitHub/unicefData/stata/src/u"

* Display Stata version
di "Stata version: " c(stata_version)
di "Current date: " c(current_date)
di ""

* Regenerate standard metadata (Python-assisted)
di _dup(80) "="
di "Regenerating STANDARD metadata files..."
di _dup(80) "="

unicefdata_sync, path("D:/jazevedo/GitHub/unicefData/stata/metadata/") verbose

di ""
di _dup(80) "="
di "Regenerating STATAONLY metadata files..."
di _dup(80) "="

unicefdata_sync, path("D:/jazevedo/GitHub/unicefData/stata/metadata/") suffix("_stataonly") verbose

di ""
di _dup(80) "="
di "DONE - Check metadata files for consistency"
di _dup(80) "="

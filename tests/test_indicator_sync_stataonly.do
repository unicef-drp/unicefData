* Test indicator metadata sync with pure Stata parser (no Python)
* Run from: C:\GitHub\others\unicefData
* This tests the forcestata option to verify it properly handles
* the indicator metadata file (which may hit macro limits)

clear all
set more off
discard

* Change to repo directory first
cd "C:\GitHub\others\unicefData"

* Start logging
log using "tests/test_indicator_sync_stataonly.log", replace text

* Add stata source directories to adopath
adopath ++ "stata/src/u"
adopath ++ "stata/src/p"
adopath ++ "stata/src/_"

* Discard again after adopath changes to ensure fresh load
discard

* Explicitly load the ado file to define all subprograms
* (discard clears programs, so we need to reload)
run "stata/src/u/unicefdata_sync.ado"

* Display current working directory
pwd

* Run sync with forcestata and force (to regenerate)
* Note: The indicator metadata file (unicef_indicators_metadata_stataonly.yaml)
* may fail because it exceeds Stata's macro length limits (~730+ indicators)
* Other files should work fine with pure Stata parser
unicefdata_sync, verbose forcestata suffix("_stataonly") force

* Show results
di "Sync completed (pure Stata parser)"
di "Note: unicef_indicators_metadata_stataonly.yaml may be missing"
di "      if macro limits were exceeded. This is expected behavior."

log close


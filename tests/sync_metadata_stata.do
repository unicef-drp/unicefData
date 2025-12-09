* Sync metadata with Python helper
* Run from: C:\GitHub\others\unicefData
* Usage: do tests/sync_metadata_stata.do

clear all
set more off
discard

* Change to repo directory first
cd "C:\GitHub\others\unicefData"

* Close any existing log and start fresh
capture log close _all
log using "tests/logs/sync_metadata_stata.log", replace text name(synctest)

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

* Run sync with forcepython and force (to regenerate)
unicefdata_sync, verbose forcepython force

* Show results
di "Sync completed"

log close synctest

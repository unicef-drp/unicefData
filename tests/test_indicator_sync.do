* Test indicator metadata sync with Python helper
* Run from: C:\GitHub\others\unicefData

clear all
set more off
discard

* Change to repo directory first
cd "C:\GitHub\others\unicefData"

* Start logging
log using "tests/test_indicator_sync.log", replace text

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

log close

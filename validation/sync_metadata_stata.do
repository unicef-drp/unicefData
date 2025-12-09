* ==============================================================================
* sync_metadata_stata.do - Sync Stata metadata from UNICEF SDMX API (Python-assisted)
* ==============================================================================
*
* This is a standalone script for syncing Stata metadata using Python helpers.
* For syncing all languages, use the orchestrator:
*     python validation/orchestrator_metadata.py --all
*
* Usage:
*     do validation/sync_metadata_stata.do
*
* Run from: C:\GitHub\others\unicefData
* Log output: validation/logs/sync_metadata_stata.log
* ==============================================================================

clear all
set more off
discard

* Change to repo directory first
cd "C:\GitHub\others\unicefData"

* Close any existing log and start fresh
capture log close _all
log using "validation/logs/sync_metadata_stata.log", replace text name(synctest)

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

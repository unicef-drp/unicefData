* ==============================================================================
* sync_metadata_stataonly.do - Sync Stata metadata (pure Stata parser)
* ==============================================================================
*
* This is a standalone script for syncing Stata metadata using ONLY Stata
* (no Python dependency). Note: May hit Stata macro limits for large files.
*
* Output goes to: stataonly/metadata/current/
* This separate folder makes it easy to track pure-Stata output in git commits.
*
* For syncing all languages, use the orchestrator:
*     python validation/orchestrator_metadata.py --all
*
* Usage:
*     do validation/sync_metadata_stataonly.do
*
* Run from: C:\GitHub\others\unicefData
* Log output: validation/logs/sync_metadata_stataonly.log
* ==============================================================================

clear all
set more off
discard

* Change to repo directory first
cd "C:\GitHub\others\unicefData"

* Close any existing log and start fresh
capture log close _all
log using "validation/logs/sync_metadata_stataonly.log", replace text name(stataonly)

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
* Output to separate stataonly/metadata folder for clean git tracking
* Note: Some files may fail due to Stata's macro length limits (~730+ indicators)
* Core files (dataflows, codelists, countries, regions, indicators) should work
unicefdata_sync, path("stataonly/metadata") verbose forcestata force

* Show results
di "Sync completed (pure Stata parser)"
di "Output saved to: stataonly/metadata/current/"
di "Note: Some extended files may be missing if macro limits were exceeded."

log close stataonly


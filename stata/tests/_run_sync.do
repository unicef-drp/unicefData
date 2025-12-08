* Temporary do-file to run unicefdata_sync
* Run from unicefData root directory

clear all
set more off
set trace on

* Change to project directory
cd "D:\jazevedo\GitHub\unicefData"

* start log
log using "stata/log/unicefdata_sync_log.txt", replace text
di as text "{hline 70}"
di as text "{bf:RUNNING unicefdata_sync DO-FILE}"
di as text "{hline 70}"

* Create metadata directories if they don't exist
capture mkdir "stata/metadata"
capture mkdir "stata/metadata/current"
capture mkdir "stata/metadata/vintages"

* Add ado path
adopath + "stata/src/u"
adopath + "stata/src/y"

* Source the ado file first to define the programs
do "stata/src/u/unicefdata_sync.ado"

* Now run sync command
unicefdata_sync, path("stata/metadata/") verbose

* Show what was created
di _n "Files in stata/metadata/current/:"
dir "stata/metadata/current/*.yaml"

* end log
log close

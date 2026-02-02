
*===============================================================================
* SYNC REPO AND STATA (ALWAYS RUN FIRST)
*===============================================================================

* Always start by making sure unicefdata in REPO and in Stata are aligned
* This ensures tests run against the latest code from the repository
net install unicefdata, from("C:\GitHub\myados\unicefData-dev\stata") replace

*===============================================================================
*===============================================================================

clear all
set more off
capture log close

* Open a text log in validation folder
log using "C:/GitHub/myados/unicefData/validation/stata_smoke_test.log", text replace

* Create a small dataset
set obs 1
generate indicator = "SMOKE_TEST"
generate rows = 1

* Write a CSV in validation folder (demonstration)
export delimited using "C:/GitHub/myados/unicefData/validation/smoke_success.csv", replace

display "OK: 1 row"
log close
exit, clear

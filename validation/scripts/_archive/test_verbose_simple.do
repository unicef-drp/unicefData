* Simple test to capture verbose output
clear all
set more off
discard

* Set up logging
log using "C:\GitHub\myados\unicefData-dev\validation\results\verbose_test.log", replace text

* Install unicefdata from dev folder
net install unicefdata, from("C:\GitHub\myados\unicefData-dev\stata") replace

* Test 1: ED_MAT_G23 with verbose
di _n(2) as text "{hline 80}"
di "TEST 1: ED_MAT_G23 (should match across platforms - 39 rows)"
di as text "{hline 80}"
unicefdata, indicator(ED_MAT_G23) verbose clear
di "Rows fetched: " _N
list in 1/3, clean noobs

* Test 2: ECD_CHLD_U5_BKS-HM with verbose
di _n(2) as text "{hline 80}"
di "TEST 2: ECD_CHLD_U5_BKS-HM (Python/R=118, Stata previously=377)"
di as text "{hline 80}"
unicefdata, indicator(ECD_CHLD_U5_BKS-HM) verbose clear
di "Rows fetched: " _N
tab sex
list in 1/3, clean noobs

log close

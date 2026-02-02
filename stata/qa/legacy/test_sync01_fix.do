* Test SYNC-01 fix
* Quick test to verify SYNC-01 now passes

clear all
set more off

cd "C:\GitHub\myados\unicefData-dev\stata\qa"

di as result _newline "Testing SYNC-01 fix..." _newline

* Enable SYNC tests
global run_sync = 1

* Run just SYNC-01
do run_tests.do SYNC-01

di _newline as result "Test complete. Check output above for PASS/FAIL."

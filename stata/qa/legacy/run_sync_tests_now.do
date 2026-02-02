/*******************************************************************************
* Run Tests with SYNC - Record Results to test_history.txt
* Date: 2026-01-24
* Auto-generated: Will run all 37 tests (34 + 3 SYNC) and append to history
*******************************************************************************/

clear all
set more off

* Enable SYNC tests
global run_sync = 1

* Display what we're doing
di as text "{hline 78}"
di as result "{bf:{center 78:RUNNING TESTS WITH SYNC ENABLED}}"
di as text "{hline 78}"
di as text ""
di as text "SYNC tests enabled: global run_sync = $run_sync"
di as text "Expected tests: 37 (34 existing + 3 SYNC)"
di as text "Results will be appended to: test_history.txt"
di as text ""
di as text "{hline 78}"
di as text ""

* Run main test suite
do run_tests.do

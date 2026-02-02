/*******************************************************************************
* Run Tests with SYNC Tests Enabled
* Date: 2026-01-24
* Purpose: Run full test suite including newly added SYNC tests
*******************************************************************************/

* Enable SYNC tests before running main test suite
global run_sync = 1

* Run main test suite
do run_tests.do

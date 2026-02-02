* Execute tests with SYNC enabled
* Simple launcher - just runs run_tests.do
* Date: 2026-01-24

clear all
set more off

* Confirm we're in the right directory
pwd

* Show that SYNC will be enabled
di as result "Running tests with SYNC enabled..."
di as text "Expected: 37 tests (34 + 3 SYNC)"
di ""

* Run the tests
do run_tests.do

* Done
di ""
di as result "Test execution complete!"
di as text "Check test_history.txt for results"

exit

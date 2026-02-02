*! Stata Test Runner
*! Runs all test files in stata/tests/
*! Date: 2026-01-25

clear all
set more off

di as result _n "========================================================================"
di as result "Stata Test Suite - Mock API Fixtures"
di as result "========================================================================"

* Track test results
local total_tests = 0
local passed_tests = 0
local failed_tests = 0

* Test 1: Mock Data Tests
di as text _n "Running: test_mock_data.do"
local total_tests = `total_tests' + 1

capture noisily do test_mock_data.do

if _rc == 0 {
    di as result "  ✓ test_mock_data.do PASSED"
    local passed_tests = `passed_tests' + 1
}
else {
    di as error "  ✗ test_mock_data.do FAILED (rc=`_rc')"
    local failed_tests = `failed_tests' + 1
}

* Add more test files here as they are created
* Example:
* di as text _n "Running: test_data_processing.do"
* local total_tests = `total_tests' + 1
* capture noisily do test_data_processing.do
* if _rc == 0 {
*     di as result "  ✓ test_data_processing.do PASSED"
*     local passed_tests = `passed_tests' + 1
* }
* else {
*     di as error "  ✗ test_data_processing.do FAILED"
*     local failed_tests = `failed_tests' + 1
* }

* Summary
di as result _n "========================================================================"
di as result "Test Summary"
di as result "========================================================================"
di as text "Total tests:  " as result `total_tests'
di as text "Passed:       " as result `passed_tests'
if `failed_tests' > 0 {
    di as text "Failed:       " as error `failed_tests'
}
else {
    di as text "Failed:       " as result `failed_tests'
}
di as result "========================================================================"

* Exit with error code if any tests failed
if `failed_tests' > 0 {
    di as error _n "Some tests failed!"
    exit 1
}
else {
    di as result _n "All tests passed! ✓"
    exit 0
}

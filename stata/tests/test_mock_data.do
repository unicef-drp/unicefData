*! Test unicefData using mock API fixtures
*! Uses shared fixtures from tests/fixtures/api_responses/
*! Date: 2026-01-25

clear all
set more off

* Get root directory
local root_dir = subinstr("`c(pwd)'", "\stata\tests", "", .)
local fixtures_dir "`root_dir'/tests/fixtures/api_responses"

* Verify fixtures directory exists
capture confirm file "`fixtures_dir'/cme_albania_valid.csv"
if _rc != 0 {
    di as error "Fixtures directory not found: `fixtures_dir'"
    di as error "Run this test from stata/tests/ directory"
    exit 601
}

di as result _n "========================================================================"
di as result "Testing unicefData with Mock API Fixtures"
di as result "========================================================================"

* Test 1: Load valid CME data for Albania
di as text _n "Test 1: Load valid CME data (Albania)"
di as text "File: cme_albania_valid.csv"
import delimited "`fixtures_dir'/cme_albania_valid.csv", clear

* Verify expected structure
assert _N == 3
assert "`c(varlist)'" != ""

* Check required columns exist
foreach var in dataflow ref_area indicator time_period obs_value {
    capture confirm variable `var'
    if _rc != 0 {
        di as error "  ✗ Missing column: `var'"
        exit 111
    }
}
di as result "  ✓ All required columns present"

* Verify data values
assert dataflow[1] == "CME"
assert ref_area[1] == "ALB"
assert indicator[1] == "CME_MRY0T4"
assert obs_value[1] == 8.5
di as result "  ✓ Data values correct"

* Test 2: Load valid USA data
di as text _n "Test 2: Load valid CME data (USA)"
di as text "File: cme_usa_valid.csv"
import delimited "`fixtures_dir'/cme_usa_valid.csv", clear

assert _N == 2
assert ref_area[1] == "USA"
assert obs_value[1] == 6.7
di as result "  ✓ USA data loaded correctly"

* Test 3: Load empty response
di as text _n "Test 3: Load empty response (invalid indicator)"
di as text "File: empty_response.csv"
import delimited "`fixtures_dir'/empty_response.csv", clear

* Should have headers but no data rows
assert _N == 0
local ncols : word count `c(varlist)'
assert `ncols' > 0
di as result "  ✓ Empty response has headers, no data"

* Test 4: Verify time series structure (Albania)
di as text _n "Test 4: Verify time series structure"
import delimited "`fixtures_dir'/cme_albania_valid.csv", clear

* Check years are in sequence
assert time_period[1] == 2020
assert time_period[2] == 2021
assert time_period[3] == 2022
di as result "  ✓ Time series years correct"

* Check mortality trend (should decrease)
assert obs_value[1] > obs_value[2]
assert obs_value[2] > obs_value[3]
di as result "  ✓ Mortality trend decreasing (expected)"

* Test 5: Verify data types
di as text _n "Test 5: Verify data types"
import delimited "`fixtures_dir'/cme_albania_valid.csv", clear

* time_period should be numeric
capture confirm numeric variable time_period
if _rc == 0 {
    di as result "  ✓ time_period is numeric"
} else {
    di as error "  ✗ time_period should be numeric"
    exit 109
}

* obs_value should be numeric
capture confirm numeric variable obs_value
if _rc == 0 {
    di as result "  ✓ obs_value is numeric"
} else {
    di as error "  ✗ obs_value should be numeric"
    exit 109
}

* Test 6: Check unit measure
di as text _n "Test 6: Check unit measure"
import delimited "`fixtures_dir'/cme_albania_valid.csv", clear

assert unit_measure[1] == "PER_1000_LIVEBIRTHS"
di as result "  ✓ Unit measure correct"

* Test 7: Check observation status
di as text _n "Test 7: Check observation status"
assert obs_status[1] == "AVAILABLE"
di as result "  ✓ Observation status correct"

* Test 8: Compare Albania vs USA values
di as text _n "Test 8: Compare Albania vs USA mortality rates"
preserve
    import delimited "`fixtures_dir'/cme_albania_valid.csv", clear
    local alb_rate_2020 = obs_value[1]
restore

preserve
    import delimited "`fixtures_dir'/cme_usa_valid.csv", clear
    local usa_rate_2020 = obs_value[1]
restore

* Albania (8.5) should have higher mortality than USA (6.7)
assert `alb_rate_2020' > `usa_rate_2020'
di as result "  ✓ ALB (8.5) > USA (6.7) as expected"

* Summary
di as result _n "========================================================================"
di as result "All Mock Data Tests Passed ✓"
di as result "========================================================================"
di as result "Fixtures used:"
di as text "  - cme_albania_valid.csv"
di as text "  - cme_usa_valid.csv"
di as text "  - empty_response.csv"
di as result _n "Tests verify:"
di as text "  ✓ CSV structure matches SDMX format"
di as text "  ✓ Required columns present"
di as text "  ✓ Data types correct (numeric time_period, obs_value)"
di as text "  ✓ Time series ordering"
di as text "  ✓ Empty responses handled"
di as text "  ✓ Cross-country comparisons"
di as result "========================================================================"

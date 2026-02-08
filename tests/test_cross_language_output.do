*! Cross-Language Output Validation Tests (Phase 7) - Stata Implementation
*!
*! Validates that fixture data is structurally consistent across all three
*! language implementations using the shared fixtures.
*!
*! Run: do tests/test_cross_language_output.do
*! ============================================================================

clear all
set more off

local tests_run    0
local tests_passed 0
local tests_failed 0

* Resolve fixture directories
local fixtures_dir ""
if ("`c(pwd)'" != "") {
    capture confirm file "tests/fixtures/api_responses/cme_albania_valid.csv"
    if _rc == 0 {
        local fixtures_dir "tests/fixtures/api_responses"
        local expected_dir "tests/fixtures/expected"
    }
    else {
        capture confirm file "fixtures/api_responses/cme_albania_valid.csv"
        if _rc == 0 {
            local fixtures_dir "fixtures/api_responses"
            local expected_dir "fixtures/expected"
        }
        else {
            capture confirm file "../tests/fixtures/api_responses/cme_albania_valid.csv"
            if _rc == 0 {
                local fixtures_dir "../tests/fixtures/api_responses"
                local expected_dir "../tests/fixtures/expected"
            }
        }
    }
}

if "`fixtures_dir'" == "" {
    noi di as error "Fixtures directory not found. Run from repo root."
    exit 601
}

noi di _n "{hline 72}"
noi di "{bf:Cross-Language Output Validation Tests (Stata)}"
noi di "{hline 72}"
noi di "Fixtures: `fixtures_dir'"

* ============================================================================
* 7.2.1 - Output Structure Validation
* ============================================================================

noi di _n "{bf:--- 7.2.1: Output Structure ---}"

* --- Test: Fixture files exist ---
local ++tests_run
cap noi {
    confirm file "`fixtures_dir'/cme_albania_valid.csv"
    confirm file "`fixtures_dir'/cme_usa_valid.csv"
    confirm file "`fixtures_dir'/empty_response.csv"
    confirm file "`fixtures_dir'/nutrition_multi_country.csv"
    confirm file "`fixtures_dir'/cme_disaggregated_sex.csv"
    confirm file "`fixtures_dir'/vaccination_multi_indicator.csv"
    confirm file "`expected_dir'/expected_columns.csv"
    confirm file "`expected_dir'/expected_cme_albania_output.csv"
    confirm file "`expected_dir'/expected_nutrition_multi_output.csv"
    confirm file "`expected_dir'/expected_error_messages.csv"
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Fixture files exist"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Fixture files exist"
}

* --- Test: CME Albania column structure ---
local ++tests_run
cap noi {
    qui import delimited using "`fixtures_dir'/cme_albania_valid.csv", clear
    assert _N == 3

    * Check required columns exist
    confirm variable dataflow
    confirm variable ref_area
    confirm variable indicator
    confirm variable time_period
    confirm variable obs_value
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  CME Albania column structure"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  CME Albania column structure"
}

* --- Test: CME Albania data values ---
local ++tests_run
cap noi {
    qui import delimited using "`fixtures_dir'/cme_albania_valid.csv", clear

    * Load expected
    preserve
    qui import delimited using "`expected_dir'/expected_cme_albania_output.csv", clear
    local exp_n = _N
    local exp_iso3_1 = iso3[1]
    local exp_value_1 = value[1]
    local exp_period_1 = period[1]
    restore

    assert _N == `exp_n'
    assert ref_area[1] == "`exp_iso3_1'"
    assert abs(obs_value[1] - `exp_value_1') < 0.001
    assert time_period[1] == `exp_period_1'
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  CME Albania data values"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  CME Albania data values"
}

* --- Test: Nutrition multi-country structure ---
local ++tests_run
cap noi {
    qui import delimited using "`fixtures_dir'/nutrition_multi_country.csv", clear
    assert _N == 6
    confirm variable age

    * Check country variety
    qui levelsof ref_area, local(countries)
    local n_countries : word count `countries'
    assert `n_countries' == 3
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Nutrition multi-country structure"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Nutrition multi-country structure"
}

* --- Test: Nutrition values match expected ---
local ++tests_run
cap noi {
    qui import delimited using "`fixtures_dir'/nutrition_multi_country.csv", clear

    preserve
    qui import delimited using "`expected_dir'/expected_nutrition_multi_output.csv", clear
    local exp_n = _N
    local exp_value_1 = value[1]
    local exp_iso3_1 = iso3[1]
    restore

    assert _N == `exp_n'
    assert ref_area[1] == "`exp_iso3_1'"
    assert abs(obs_value[1] - `exp_value_1') < 0.001
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Nutrition values match expected"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Nutrition values match expected"
}

* --- Test: Disaggregated sex structure ---
local ++tests_run
cap noi {
    qui import delimited using "`fixtures_dir'/cme_disaggregated_sex.csv", clear
    assert _N == 6

    qui levelsof sex, local(sex_vals)
    local n_sex : word count `sex_vals'
    assert `n_sex' == 3

    * Male mortality > Female (biological pattern)
    qui su obs_value if sex == "M" & time_period == 2020
    local male_2020 = r(mean)
    qui su obs_value if sex == "F" & time_period == 2020
    local female_2020 = r(mean)
    assert `male_2020' > `female_2020'
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Disaggregated sex structure"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Disaggregated sex structure"
}

* --- Test: Multi-indicator structure ---
local ++tests_run
cap noi {
    qui import delimited using "`fixtures_dir'/vaccination_multi_indicator.csv", clear
    assert _N == 8

    qui levelsof indicator, local(indicators)
    local n_ind : word count `indicators'
    assert `n_ind' == 2

    qui levelsof ref_area, local(countries)
    local n_cty : word count `countries'
    assert `n_cty' == 2
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Multi-indicator structure"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Multi-indicator structure"
}

* --- Test: Empty response structure ---
local ++tests_run
cap noi {
    qui import delimited using "`fixtures_dir'/empty_response.csv", clear
    assert _N == 0
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Empty response structure"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Empty response structure"
}

* --- Test: Data types numeric ---
local ++tests_run
cap noi {
    foreach f in cme_albania_valid cme_disaggregated_sex vaccination_multi_indicator nutrition_multi_country {
        qui import delimited using "`fixtures_dir'/`f'.csv", clear
        confirm numeric variable obs_value
        confirm numeric variable time_period
    }
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Data types numeric"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Data types numeric"
}

* --- Test: Column mapping completeness ---
local ++tests_run
cap noi {
    * Canonical SDMX columns (from expected_columns.csv)
    local expected_cols "DATAFLOW REF_AREA INDICATOR SEX AGE TIME_PERIOD OBS_VALUE UNIT_MEASURE OBS_STATUS DATA_SOURCE"

    * Check each fixture has only expected columns
    foreach f in cme_albania_valid nutrition_multi_country vaccination_multi_indicator {
        qui import delimited using "`fixtures_dir'/`f'.csv", clear
        foreach var of varlist * {
            local vname = upper("`var'")
            local found 0
            foreach ecol in `expected_cols' {
                if "`vname'" == "`ecol'" local found 1
            }
            if `found' == 0 {
                noi di as error "Column `vname' in `f' not in expected SDMX columns"
                exit 9
            }
        }
    }
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Column mapping completeness"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Column mapping completeness"
}

* ============================================================================
* 7.2.2 - Error Message Validation
* ============================================================================

noi di _n "{bf:--- 7.2.2: Error Validation ---}"

* --- Test: Error message patterns ---
local ++tests_run
cap noi {
    qui import delimited using "`expected_dir'/expected_error_messages.csv", clear
    assert _N >= 3

    * Check we have at least 4 variables (scenario, error_type, message_pattern, languages)
    qui ds
    local n_vars : word count `r(varlist)'
    assert `n_vars' >= 4

    * Get last variable name (languages column) and verify Stata coverage
    local last_var : word `n_vars' of `r(varlist)'
    qui count if strpos(`last_var', "stata") > 0
    assert r(N) >= 2
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  Error message patterns"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  Error message patterns"
}

* ============================================================================
* 7.2.3 - Cache Validation
* ============================================================================

noi di _n "{bf:--- 7.2.3: Cache Validation ---}"

* --- Test: clearcache subcommand documented ---
local ++tests_run
cap noi {
    * Find the help file
    local sthlp_paths ""
    local sthlp_paths "`sthlp_paths' stata/src/u/unicefdata.sthlp"
    local sthlp_paths "`sthlp_paths' ../stata/src/u/unicefdata.sthlp"

    local found 0
    foreach p in `sthlp_paths' {
        capture confirm file "`p'"
        if _rc == 0 {
            * Read and check for clearcache
            qui file open fh using "`p'", read text
            local has_clearcache 0
            file read fh line
            while r(eof) == 0 {
                if strpos(`"`line'"', "clearcache") > 0 {
                    local has_clearcache 1
                }
                file read fh line
            }
            file close fh
            if `has_clearcache' local found 1
        }
    }
    assert `found' == 1
}
if _rc == 0 {
    local ++tests_passed
    noi di "  {result:PASS}  clearcache subcommand documented"
}
else {
    local ++tests_failed
    noi di "  {error:FAIL}  clearcache subcommand documented"
}

* ============================================================================
* Summary
* ============================================================================

noi di _n "{hline 72}"
noi di "{bf:Results: `tests_passed'/`tests_run' passed, `tests_failed' failed}"
noi di "{hline 72}"

if `tests_failed' > 0 {
    noi di _n "{error:Some tests failed!}"
    exit 1
}
else {
    noi di _n "{result:All tests passed!}"
}

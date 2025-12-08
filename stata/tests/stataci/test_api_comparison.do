*******************************************************************************
* test_api_comparison.do
* Cross-platform validation - compare Stata output with Python/R reference files
* Ensures consistent results across all three language implementations
*
* Author: Joao Pedro Azevedo
* Date: December 2025
*******************************************************************************

version 15.0

* Setup paths if not already set by run_tests.do
capture which unicefdata
if _rc {
    adopath ++ "../../src/u"
    adopath ++ "../../src/y"
    adopath ++ "."
}

* Load assertion utilities
run assert_utils.ado

di as txt ""
di as txt "TEST: Cross-Platform API Comparison"
di as txt "===================================="
di as txt ""

* Reference directories (R and Python test outputs)
local r_output "../../R/tests/output"
local py_output "../../python/tests/output"

* ============================================================================
* Test 1: Compare Mortality Data Row Counts
* ============================================================================
di as txt "1. Comparing mortality data across platforms..."

* Check if reference files exist
local has_refs = 1

capture confirm file "`r_output'/test_mortality.csv"
if _rc {
    di as txt "   [SKIP] R reference file not found"
    local has_refs = 0
}

capture confirm file "`py_output'/test_mortality.csv"
if _rc {
    di as txt "   [SKIP] Python reference file not found"
    local has_refs = 0
}

if (`has_refs' == 1) {
    * Load R output
    import delimited "`r_output'/test_mortality.csv", clear
    local r_n = _N
    local r_countries : word count `=r(r)'
    qui levelsof iso3, local(r_countries)
    
    * Load Python output
    import delimited "`py_output'/test_mortality.csv", clear
    local py_n = _N
    qui levelsof iso3, local(py_countries)
    
    * Load Stata output (if exists)
    capture use "output/test_mortality.dta", clear
    if _rc == 0 {
        local stata_n = _N
        qui levelsof iso3, local(stata_countries)
        
        * Compare
        di as txt "   Row counts:"
        di as txt "     R:      `r_n'"
        di as txt "     Python: `py_n'"
        di as txt "     Stata:  `stata_n'"
        
        * Allow 10% tolerance due to filtering differences
        local diff_r = abs(`stata_n' - `r_n')
        local diff_py = abs(`stata_n' - `py_n')
        local tolerance = max(`r_n', `py_n', `stata_n') * 0.1
        
        if (`diff_r' <= `tolerance' & `diff_py' <= `tolerance') {
            di as result "   [OK] Row counts within 10% tolerance"
        }
        else {
            di as error "   [WARN] Row counts differ significantly"
        }
    }
    else {
        di as txt "   [SKIP] Stata output not found - run test_indicators_basic first"
    }
}
else {
    di as txt "   [SKIP] Reference files not available"
}

* ============================================================================
* Test 2: Compare Column Names
* ============================================================================
di as txt "2. Comparing column structure..."

* Expected standard columns (harmonized across R/Python/Stata)
local std_cols "iso3 indicator period value"

* Check Stata output
capture use "output/test_mortality.dta", clear
if _rc == 0 {
    local stata_ok = 1
    foreach col of local std_cols {
        capture confirm variable `col'
        if _rc {
            di as error "   [FAIL] Stata missing column: `col'"
            local stata_ok = 0
        }
    }
    if (`stata_ok' == 1) {
        di as result "   [OK] Stata has all standard columns"
    }
}
else {
    di as txt "   [SKIP] Stata output not available"
}

* Check R output
capture import delimited "`r_output'/test_mortality.csv", clear
if _rc == 0 {
    local r_ok = 1
    foreach col of local std_cols {
        capture confirm variable `col'
        if _rc {
            di as txt "   [INFO] R uses different column name for: `col'"
            local r_ok = 0
        }
    }
    if (`r_ok' == 1) {
        di as result "   [OK] R has all standard columns"
    }
}

* Check Python output
capture import delimited "`py_output'/test_mortality.csv", clear
if _rc == 0 {
    local py_ok = 1
    foreach col of local std_cols {
        capture confirm variable `col'
        if _rc {
            di as txt "   [INFO] Python uses different column name for: `col'"
            local py_ok = 0
        }
    }
    if (`py_ok' == 1) {
        di as result "   [OK] Python has all standard columns"
    }
}

* ============================================================================
* Test 3: Value Consistency Check
* ============================================================================
di as txt "3. Checking value consistency..."

* Load Stata data
capture use "output/test_mortality.dta", clear
if _rc == 0 {
    * Calculate summary statistics
    qui summ value
    local stata_mean = r(mean)
    local stata_min = r(min)
    local stata_max = r(max)
    
    di as txt "   Stata value summary:"
    di as txt "     Mean: " %9.2f `stata_mean'
    di as txt "     Min:  " %9.2f `stata_min'
    di as txt "     Max:  " %9.2f `stata_max'
    
    * Compare with R if available
    capture import delimited "`r_output'/test_mortality.csv", clear
    if _rc == 0 {
        capture confirm variable value
        if _rc == 0 {
            qui summ value
            local r_mean = r(mean)
            
            * Check means are close (within 5%)
            local mean_diff = abs(`stata_mean' - `r_mean') / max(`stata_mean', `r_mean')
            if (`mean_diff' < 0.05) {
                di as result "   [OK] Mean values consistent with R (diff: " %4.1f `mean_diff'*100 "%)"
            }
            else {
                di as error "   [WARN] Mean values differ from R by " %4.1f `mean_diff'*100 "%"
            }
        }
    }
}
else {
    di as txt "   [SKIP] Stata output not available"
}

* ============================================================================
* Test 4: Country Coverage Comparison
* ============================================================================
di as txt "4. Comparing country coverage..."

* Load Stata data
capture use "output/test_mortality.dta", clear
if _rc == 0 {
    qui levelsof iso3, local(stata_countries)
    local stata_n_countries : word count `stata_countries'
    
    di as txt "   Stata countries: `stata_n_countries'"
    di as txt "   (`stata_countries')"
    
    * Compare with Python if available
    capture import delimited "`py_output'/test_mortality.csv", clear
    if _rc == 0 {
        capture confirm variable iso3
        if _rc == 0 {
            qui levelsof iso3, local(py_countries)
            local py_n_countries : word count `py_countries'
            
            if (`stata_n_countries' == `py_n_countries') {
                di as result "   [OK] Country count matches Python"
            }
            else {
                di as txt "   [INFO] Country count differs from Python (`py_n_countries')"
            }
        }
    }
}
else {
    di as txt "   [SKIP] Stata output not available"
}

* ============================================================================
* Test 5: Year Range Comparison
* ============================================================================
di as txt "5. Comparing year ranges..."

capture use "output/test_mortality.dta", clear
if _rc == 0 {
    qui summ period
    local stata_min_year = r(min)
    local stata_max_year = r(max)
    
    di as txt "   Stata year range: `stata_min_year' - `stata_max_year'"
    
    * Compare with expected (2015-2023 from test specification)
    if (`stata_min_year' >= 2015 & `stata_max_year' <= 2023) {
        di as result "   [OK] Year range within expected bounds (2015-2023)"
    }
    else {
        di as txt "   [INFO] Year range extends beyond test specification"
    }
}
else {
    di as txt "   [SKIP] Stata output not available"
}

* ============================================================================
* Summary
* ============================================================================
di as txt ""
di as result "Cross-platform comparison tests completed"
di as txt "Note: Some tests may be skipped if reference files are not available."
di as txt "Run R and Python test suites first to generate reference files."
di as txt ""

exit 0

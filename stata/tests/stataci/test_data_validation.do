*******************************************************************************
* test_data_validation.do
* Data quality and structure validation tests
* Mirrors Python test_metadata_manager.py validation tests
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
di as txt "TEST: Data Validation"
di as txt "====================="
di as txt ""

* ============================================================================
* Test 1: Column Structure Validation
* ============================================================================
di as txt "1. Testing column structure..."

* Download sample data
capture noisily unicefdata, ///
    indicator(CME_MRY0T4) ///
    countries(ALB) ///
    startyear(2020) ///
    endyear(2023) ///
    clear

if (_rc != 0) {
    di as error "   [FAIL] Could not download test data"
    exit 9
}

* Check required columns exist (SDMX standard)
local required_cols "iso3 indicator period value"
foreach col of local required_cols {
    capture confirm variable `col'
    if _rc {
        di as error "   [FAIL] Required column '`col'' not found"
        exit 9
    }
}
di as result "   [OK] All required columns present: `required_cols'"

* ============================================================================
* Test 2: Variable Type Validation
* ============================================================================
di as txt "2. Testing variable types..."

* iso3 should be string
assert_vartype iso3, type(string)
di as result "   [OK] iso3 is string type"

* period should be numeric
assert_vartype period, type(numeric)
di as result "   [OK] period is numeric type"

* value should be numeric
assert_vartype value, type(numeric)
di as result "   [OK] value is numeric type"

* ============================================================================
* Test 3: Value Range Validation
* ============================================================================
di as txt "3. Testing value ranges..."

* Under-5 mortality rate should be 0-1000 per 1000 live births
qui summ value
assert_inrange `r(min)' 0 1000
assert_inrange `r(max)' 0 1000
di as result "   [OK] value in valid range [" r(min) ", " r(max) "]"

* Period should be reasonable years (1950-2030)
qui summ period
assert_inrange `r(min)' 1950 2030
assert_inrange `r(max)' 1950 2030
di as result "   [OK] period in valid range [" r(min) ", " r(max) "]"

* ============================================================================
* Test 4: ISO3 Code Validation
* ============================================================================
di as txt "4. Testing ISO3 codes..."

* ISO3 codes should be exactly 3 characters
gen iso3_len = strlen(iso3)
qui summ iso3_len
if (r(min) != 3 | r(max) != 3) {
    di as error "   [FAIL] ISO3 codes not all 3 characters"
    exit 9
}
drop iso3_len
di as result "   [OK] All ISO3 codes are 3 characters"

* ISO3 codes should be uppercase
gen iso3_upper = upper(iso3)
qui count if iso3 != iso3_upper
if (r(N) > 0) {
    di as error "   [FAIL] Some ISO3 codes not uppercase"
    exit 9
}
drop iso3_upper
di as result "   [OK] All ISO3 codes are uppercase"

* ============================================================================
* Test 5: Missing Value Handling
* ============================================================================
di as txt "5. Testing missing value handling..."

* iso3 and period should never be missing
assert_nomissing iso3 period
di as result "   [OK] No missing values in key fields (iso3, period)"

* value can have missing values, but count them
qui count if missing(value)
local n_missing = r(N)
local pct_missing = `n_missing' / _N * 100
di as result "   [INFO] value: `n_missing' missing (" %4.1f `pct_missing' "%)"

* ============================================================================
* Test 6: Duplicate Detection
* ============================================================================
di as txt "6. Testing for duplicates..."

* Download data that might have duplicates
capture noisily unicefdata, ///
    indicator(CME_MRY0T4) ///
    countries(USA GBR FRA) ///
    startyear(2015) ///
    endyear(2023) ///
    clear

if (_rc != 0) {
    di as error "   [FAIL] Could not download test data"
    exit 9
}

* Check for duplicates on key variables
* Note: May have duplicates by sex, wealth quintile - that's expected
duplicates tag iso3 indicator period, gen(dup)
qui count if dup > 0
local n_dup = r(N)

if (`n_dup' > 0) {
    di as txt "   [INFO] Found `n_dup' duplicates by iso3/indicator/period"
    di as txt "          (May be due to sex/wealth dimensions - expected)"
}
else {
    di as result "   [OK] No duplicates by iso3/indicator/period"
}
drop dup

* ============================================================================
* Test 7: Cross-Country Comparison Data Quality
* ============================================================================
di as txt "7. Testing cross-country comparison readiness..."

* For cross-country analysis, need multiple countries with overlapping years
qui levelsof iso3, local(countries)
local n_countries : word count `countries'

qui levelsof period, local(years)
local n_years : word count `years'

di as result "   [OK] Data covers `n_countries' countries and `n_years' years"

* Check at least some overlap
if (`n_countries' < 2) {
    di as error "   [WARN] Only 1 country - limited cross-country analysis possible"
}

if (`n_years' < 2) {
    di as error "   [WARN] Only 1 year - limited time-series analysis possible"
}

* ============================================================================
* Summary
* ============================================================================
di as txt ""
di as result "Data validation tests completed successfully"
di as txt ""

exit 0

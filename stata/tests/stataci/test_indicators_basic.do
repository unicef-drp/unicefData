*******************************************************************************
* test_indicators_basic.do
* Basic indicator download tests
* Mirrors Python test_unicef_api.py and R run_tests.R basic tests
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
di as txt "TEST: Basic Indicator Downloads"
di as txt "================================"
di as txt ""

* Ensure output directory exists
capture mkdir "output"

* ----------------------------------------------------------------------------
* Test 1: Child Mortality (CME_MRY0T4)
* Mirrors: Python test_child_mortality(), R test_child_mortality()
* ----------------------------------------------------------------------------
di as txt "1. Testing child mortality (CME_MRY0T4)..."
di as txt "   Countries: USA, GBR, FRA, DEU, JPN"
di as txt "   Years: 2015-2023"

timer clear 1
timer on 1

capture noisily unicefdata, ///
    indicator(CME_MRY0T4) ///
    countries(USA GBR FRA DEU JPN) ///
    startyear(2015) ///
    endyear(2023) ///
    clear

local rc = _rc
timer off 1
qui timer list 1
local elapsed = r(t1)

if (`rc' != 0) {
    di as error "   [FAIL] Command failed with rc=`rc'"
    exit 9
}

* Validate results
assert_nobs_min 1, msg("Child mortality should return data")

* Check required columns exist (using actual variable names from unicefdata)
assert_varexists iso3 indicator period value, ///
    msg("Required columns missing")

* Check country filter worked
qui levelsof iso3, local(countries) clean
local n_countries : word count `countries'
assert_inrange `n_countries' 1 5

* Save for cross-platform comparison
qui save "output/test_mortality.dta", replace
qui export delimited "output/test_mortality.csv", replace

di as result "   [OK] Retrieved " _N " observations in " %5.2f `elapsed' "s"
di as txt "   Countries: `countries'"
di as txt ""

* ----------------------------------------------------------------------------
* Test 2: Stunting (NT_ANT_HAZ_NE2)
* Mirrors: Python test_stunting(), R test_stunting()
* ----------------------------------------------------------------------------
di as txt "2. Testing stunting (NT_ANT_HAZ_NE2)..."
di as txt "   Countries: IND, BGD, PAK, NPL, ETH"
di as txt "   Years: 2010-2023"

timer clear 2
timer on 2

capture noisily unicefdata, ///
    indicator(NT_ANT_HAZ_NE2) ///
    dataflow(NUTRITION) ///
    countries(IND BGD PAK NPL ETH) ///
    startyear(2010) ///
    endyear(2023) ///
    clear

local rc = _rc
timer off 2
qui timer list 2
local elapsed = r(t2)

if (`rc' != 0) {
    di as error "   [FAIL] Command failed with rc=`rc'"
    exit 9
}

assert_nobs_min 1, msg("Stunting should return data")
assert_varexists iso3 indicator period value

qui save "output/test_stunting.dta", replace
qui export delimited "output/test_stunting.csv", replace

di as result "   [OK] Retrieved " _N " observations in " %5.2f `elapsed' "s"
di as txt ""

* ----------------------------------------------------------------------------
* Test 3: Immunization (IM_DTP3)
* Mirrors: Python test_immunization(), R test_immunization()
* ----------------------------------------------------------------------------
di as txt "3. Testing immunization (IM_DTP3)..."
di as txt "   Countries: NGA, COD, BRA, IDN, MEX"
di as txt "   Years: 2015-2023"

timer clear 3
timer on 3

capture noisily unicefdata, ///
    indicator(IM_DTP3) ///
    dataflow(IMMUNISATION) ///
    countries(NGA COD BRA IDN MEX) ///
    startyear(2015) ///
    endyear(2023) ///
    clear

local rc = _rc
timer off 3
qui timer list 3
local elapsed = r(t3)

if (`rc' != 0) {
    di as error "   [FAIL] Command failed with rc=`rc'"
    exit 9
}

assert_nobs_min 1, msg("Immunization should return data")
assert_varexists iso3 indicator period value

qui save "output/test_immunization.dta", replace
qui export delimited "output/test_immunization.csv", replace

di as result "   [OK] Retrieved " _N " observations in " %5.2f `elapsed' "s"
di as txt ""

* ----------------------------------------------------------------------------
* Test 4: Large Country Set
* Tests downloading data for many countries at once
* ----------------------------------------------------------------------------
di as txt "4. Testing large country set (CME_MRY0T4)..."
di as txt "   Countries: BRA, IND, CHN, NGA, IDN, PAK, BGD, MEX, ETH, PHL"
di as txt "   Years: 2020-2023"

timer clear 4
timer on 4

capture noisily unicefdata, ///
    indicator(CME_MRY0T4) ///
    countries(BRA IND CHN NGA IDN PAK BGD MEX ETH PHL) ///
    startyear(2020) ///
    endyear(2023) ///
    clear

local rc = _rc
timer off 4
qui timer list 4
local elapsed = r(t4)

if (`rc' != 0) {
    di as error "   [FAIL] Command failed with rc=`rc'"
    exit 9
}

assert_nobs_min 1, msg("Large country set should return data")

* Check number of countries
qui levelsof iso3, local(countries) clean
local n_countries : word count `countries'
assert_inrange `n_countries' 5 10

qui save "output/test_large_countries.dta", replace
qui export delimited "output/test_large_countries.csv", replace

di as result "   [OK] Retrieved " _N " observations in " %5.2f `elapsed' "s"
di as txt "   Countries: `countries'"
di as txt ""

* ----------------------------------------------------------------------------
* Summary
* ----------------------------------------------------------------------------
di as txt ""
di as result "Basic indicator tests completed successfully"
di as txt ""

exit 0

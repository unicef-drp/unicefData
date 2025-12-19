/*==============================================================================
    Test Integrated Features in unicefdata v1.3.0
    
    Tests all features through the main command syntax (not helpers directly)
    
    Tests:
    1. Discovery via main command (flows, search, indicators, info)
    2. wide_indicators reshape
    3. addmeta(region income_group continent)
    4. geo_type classification
==============================================================================*/

clear all
set more off

// Set path to the ado files
adopath ++ "C:\GitHub\others\unicefData\stata\src\_"
adopath ++ "C:\GitHub\others\unicefData\stata\src\u"
adopath ++ "C:\GitHub\others\unicefData\stata\src\y"

// Define metadata path for testing
global UNICEF_METAPATH "C:\GitHub\others\unicefData\stata\metadata\vintages\"

di as txt _n "======================================================================"
di as txt "Testing unicefdata v1.3.0 Integrated Features"
di as txt "======================================================================"

local test_pass = 0
local test_fail = 0

/*------------------------------------------------------------------------------
    Test 1: FLOWS via main command
------------------------------------------------------------------------------*/
di as txt _n "TEST 1: unicefdata, flows"
di as txt "----------------------------------------"

capture noisily unicefdata, flows verbose

if _rc == 0 {
    di as result "PASSED: flows command executed"
    local test_pass = `test_pass' + 1
}
else {
    di as err "FAILED: flows command returned error `_rc'"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 2: SEARCH via main command  
------------------------------------------------------------------------------*/
di as txt _n "TEST 2: unicefdata, search(mortality)"
di as txt "----------------------------------------"

capture noisily unicefdata, search(mortality) 

if _rc == 0 {
    di as result "PASSED: search command executed"
    local test_pass = `test_pass' + 1
}
else {
    di as err "FAILED: search command returned error `_rc'"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 3: INDICATORS via main command
------------------------------------------------------------------------------*/
di as txt _n "TEST 3: unicefdata, indicators(CME)"
di as txt "----------------------------------------"

capture noisily unicefdata, indicators(CME)

if _rc == 0 {
    di as result "PASSED: indicators command executed"
    local test_pass = `test_pass' + 1
}
else {
    di as err "FAILED: indicators command returned error `_rc'"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 4: INFO via main command
------------------------------------------------------------------------------*/
di as txt _n "TEST 4: unicefdata, info(CME_MRY0T4)"
di as txt "----------------------------------------"

capture noisily unicefdata, info(CME_MRY0T4)

if _rc == 0 {
    di as txt _n "Return values:"
    return list
    di as result "PASSED: info command executed"
    local test_pass = `test_pass' + 1
}
else {
    di as err "FAILED: info command returned error `_rc'"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 5: wide_indicators format
------------------------------------------------------------------------------*/
di as txt _n "TEST 5: wide_indicators format"
di as txt "----------------------------------------"

// First get data with multiple indicators
capture noisily unicefdata, dataflow(CME) countries(AFG BGD) start_year(2020) end_year(2022) clear verbose

if _rc == 0 & _N > 0 {
    di as txt "Got " _N " observations"
    di as txt "Variables before reshape:"
    describe, short
    
    // Check if indicator variable exists
    capture confirm variable indicator
    if _rc == 0 {
        tab indicator, missing
        
        // Now test wide_indicators
        di as txt _n "Testing wide_indicators reshape..."
        capture noisily unicefdata, dataflow(CME) countries(AFG BGD) start_year(2020) end_year(2022) wide_indicators clear verbose
        
        if _rc == 0 {
            di as txt "Variables after wide_indicators:"
            describe, short
            list in 1/5, abbrev(12)
            di as result "PASSED: wide_indicators executed"
            local test_pass = `test_pass' + 1
        }
        else {
            di as err "FAILED: wide_indicators returned error `_rc'"
            local test_fail = `test_fail' + 1
        }
    }
    else {
        di as err "FAILED: indicator variable not found"
        local test_fail = `test_fail' + 1
    }
}
else {
    di as err "FAILED: Could not get data for wide_indicators test (rc=`_rc')"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 6: addmeta(region) 
------------------------------------------------------------------------------*/
di as txt _n "TEST 6: addmeta(region)"
di as txt "----------------------------------------"

capture noisily unicefdata, indicator(CME_MRY0T4) countries(AFG BGD BRA USA) start_year(2022) addmeta(region) clear verbose

if _rc == 0 & _N > 0 {
    capture confirm variable region
    if _rc == 0 {
        di as txt "Region values:"
        tab region, missing
        di as result "PASSED: addmeta(region) created region variable"
        local test_pass = `test_pass' + 1
    }
    else {
        di as err "FAILED: region variable not created"
        local test_fail = `test_fail' + 1
    }
}
else {
    di as err "FAILED: addmeta(region) query failed (rc=`_rc')"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 7: addmeta(income_group)
------------------------------------------------------------------------------*/
di as txt _n "TEST 7: addmeta(income_group)"
di as txt "----------------------------------------"

capture noisily unicefdata, indicator(CME_MRY0T4) countries(AFG BGD BRA USA) start_year(2022) addmeta(income_group) clear

if _rc == 0 & _N > 0 {
    capture confirm variable income_group
    if _rc == 0 {
        di as txt "Income group values:"
        tab income_group, missing
        di as result "PASSED: addmeta(income_group) created income_group variable"
        local test_pass = `test_pass' + 1
    }
    else {
        di as err "FAILED: income_group variable not created"
        local test_fail = `test_fail' + 1
    }
}
else {
    di as err "FAILED: addmeta(income_group) query failed (rc=`_rc')"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 8: addmeta(continent)
------------------------------------------------------------------------------*/
di as txt _n "TEST 8: addmeta(continent)"
di as txt "----------------------------------------"

capture noisily unicefdata, indicator(CME_MRY0T4) countries(AFG BGD BRA USA) start_year(2022) addmeta(continent) clear

if _rc == 0 & _N > 0 {
    capture confirm variable continent
    if _rc == 0 {
        di as txt "Continent values:"
        tab continent, missing
        di as result "PASSED: addmeta(continent) created continent variable"
        local test_pass = `test_pass' + 1
    }
    else {
        di as err "FAILED: continent variable not created"
        local test_fail = `test_fail' + 1
    }
}
else {
    di as err "FAILED: addmeta(continent) query failed (rc=`_rc')"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 9: Combined addmeta(region income_group continent)
------------------------------------------------------------------------------*/
di as txt _n "TEST 9: addmeta(region income_group continent)"
di as txt "----------------------------------------"

capture noisily unicefdata, indicator(CME_MRY0T4) countries(AFG BGD BRA USA DEU) start_year(2022) addmeta(region income_group continent) clear

if _rc == 0 & _N > 0 {
    local has_all = 1
    foreach v in region income_group continent {
        capture confirm variable `v'
        if _rc != 0 {
            local has_all = 0
            di as err "Missing variable: `v'"
        }
    }
    
    if `has_all' == 1 {
        di as txt "All metadata variables created:"
        list iso3 country region income_group continent in 1/10, abbrev(15)
        di as result "PASSED: Combined addmeta created all variables"
        local test_pass = `test_pass' + 1
    }
    else {
        di as err "FAILED: Some metadata variables not created"
        local test_fail = `test_fail' + 1
    }
}
else {
    di as err "FAILED: Combined addmeta query failed (rc=`_rc')"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Test 10: geo_type classification
------------------------------------------------------------------------------*/
di as txt _n "TEST 10: geo_type classification"
di as txt "----------------------------------------"

// Get data with both countries and aggregates
capture noisily unicefdata, indicator(CME_MRY0T4) start_year(2022) clear

if _rc == 0 & _N > 0 {
    capture confirm variable geo_type
    if _rc == 0 {
        di as txt "geo_type distribution:"
        tab geo_type, missing
        
        // Check if we have both types
        count if geo_type == "country"
        local n_country = r(N)
        count if geo_type == "aggregate"
        local n_agg = r(N)
        
        if `n_country' > 0 & `n_agg' > 0 {
            di as result "PASSED: geo_type has both countries (`n_country') and aggregates (`n_agg')"
            local test_pass = `test_pass' + 1
        }
        else if `n_country' > 0 {
            di as result "PASSED: geo_type working (countries found, no aggregates in this query)"
            local test_pass = `test_pass' + 1
        }
        else {
            di as err "FAILED: geo_type not classifying properly"
            local test_fail = `test_fail' + 1
        }
    }
    else {
        di as err "FAILED: geo_type variable not created"
        local test_fail = `test_fail' + 1
    }
}
else {
    di as err "FAILED: Query for geo_type test failed (rc=`_rc')"
    local test_fail = `test_fail' + 1
}

/*------------------------------------------------------------------------------
    Summary
------------------------------------------------------------------------------*/
di as txt _n "======================================================================"
di as txt "TEST SUMMARY"
di as txt "======================================================================"
di as txt "Passed: " as result `test_pass'
di as txt "Failed: " as err `test_fail'
di as txt "Total:  " as txt (`test_pass' + `test_fail')

if `test_fail' == 0 {
    di as result _n "ALL TESTS PASSED!"
}
else {
    di as err _n "SOME TESTS FAILED"
}

di as txt _n "======================================================================"

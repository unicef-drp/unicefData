*! Test: sex(ALL) filter returns all sex codes (M, F, _T), not just _T
*! Purpose: Verify centralized filter architecture with early normalization
*! Test date: 2025-01-15

clear all
set more off
set linesize 120

* Add unicefData to path
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

* Test parameters
local test_indicator "CME_MRY0T4"
local test_country "USA"
local test_year 2020

noi di _newline
noi di as text "================================================================"
noi di as text "TEST: Centralized Filter Architecture with sex(ALL)"
noi di as text "================================================================"

*-----------------------------------------------------------------------
* TEST 1: sex(ALL) should return multiple sex codes (M, F, _T)
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 1: sex(ALL) - Expected: M, F, _T"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(`test_indicator') ///
        country(`test_country') year(`test_year') ///
        sex(ALL) ///
        verbose nofilter clear
    
    if _rc == 0 {
        * Check what sex codes are present
        unique sex if sex != ""
        local sex_count = r(N)
        levelsof sex if sex != "", local(sex_codes)
        
        noi di as text "  ✓ Query successful"
        noi di as text "  Data returned: " as result "`= _N' rows"
        noi di as text "  Unique sex codes: " as result "`sex_count'"
        noi di as text "  Sex values present: " as result "`sex_codes'"
        
        * Verify we have more than just _T
        if `sex_count' > 1 {
            noi di as text "  ✓ PASS: Multiple sex codes returned (not just _T)"
        }
        else {
            noi di as error "  ✗ FAIL: Only " `sex_count' " sex code(s) returned - expected M, F, _T"
        }
    }
    else {
        noi di as error "  ✗ FAIL: Query failed with rc = " _rc
    }
}

*-----------------------------------------------------------------------
* TEST 2: sex(_T) should return only _T (totals)
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 2: sex(_T) - Expected: Only _T"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(`test_indicator') ///
        country(`test_country') year(`test_year') ///
        sex(_T) ///
        verbose nofilter clear
    
    if _rc == 0 {
        unique sex if sex != ""
        local sex_count = r(N)
        levelsof sex if sex != "", local(sex_codes)
        
        noi di as text "  ✓ Query successful"
        noi di as text "  Data returned: " as result "`= _N' rows"
        noi di as text "  Unique sex codes: " as result "`sex_count'"
        noi di as text "  Sex values present: " as result "`sex_codes'"
        
        if "`sex_codes'" == "_T" {
            noi di as text "  ✓ PASS: Only _T returned (as expected)"
        }
        else {
            noi di as error "  ✗ FAIL: Expected _T only, got: `sex_codes'"
        }
    }
    else {
        noi di as error "  ✗ FAIL: Query failed with rc = " _rc
    }
}

*-----------------------------------------------------------------------
* TEST 3: sex(M) should return only M
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 3: sex(M) - Expected: Only M"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(`test_indicator') ///
        country(`test_country') year(`test_year') ///
        sex(M) ///
        verbose nofilter clear
    
    if _rc == 0 {
        unique sex if sex != ""
        local sex_count = r(N)
        levelsof sex if sex != "", local(sex_codes)
        
        noi di as text "  ✓ Query successful"
        noi di as text "  Data returned: " as result "`= _N' rows"
        noi di as text "  Unique sex codes: " as result "`sex_count'"
        noi di as text "  Sex values present: " as result "`sex_codes'"
        
        if "`sex_codes'" == "M" {
            noi di as text "  ✓ PASS: Only M returned (as expected)"
        }
        else {
            noi di as error "  ✗ FAIL: Expected M only, got: `sex_codes'"
        }
    }
    else {
        noi di as error "  ✗ FAIL: Query failed with rc = " _rc
    }
}

*-----------------------------------------------------------------------
* TEST 4: sex(M F) should return M and F
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 4: sex(M F) - Expected: M, F"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(`test_indicator') ///
        country(`test_country') year(`test_year') ///
        sex(M F) ///
        verbose nofilter clear
    
    if _rc == 0 {
        unique sex if sex != ""
        local sex_count = r(N)
        levelsof sex if sex != "", local(sex_codes)
        
        noi di as text "  ✓ Query successful"
        noi di as text "  Data returned: " as result "`= _N' rows"
        noi di as text "  Unique sex codes: " as result "`sex_count'"
        noi di as text "  Sex values present: " as result "`sex_codes'"
        
        if `sex_count' == 2 & strpos("`sex_codes'", "M") > 0 & strpos("`sex_codes'", "F") > 0 {
            noi di as text "  ✓ PASS: M and F returned (as expected)"
        }
        else {
            noi di as error "  ✗ FAIL: Expected M and F, got: `sex_codes'"
        }
    }
    else {
        noi di as error "  ✗ FAIL: Query failed with rc = " _rc
    }
}

*-----------------------------------------------------------------------
* TEST 5: Default (no sex option) should use _T for all sex
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 5: No sex option - Expected: _T (default)"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(`test_indicator') ///
        country(`test_country') year(`test_year') ///
        verbose nofilter clear
    
    if _rc == 0 {
        unique sex if sex != ""
        local sex_count = r(N)
        levelsof sex if sex != "", local(sex_codes)
        
        noi di as text "  ✓ Query successful"
        noi di as text "  Data returned: " as result "`= _N' rows"
        noi di as text "  Unique sex codes: " as result "`sex_count'"
        noi di as text "  Sex values present: " as result "`sex_codes'"
        
        if "`sex_codes'" == "_T" {
            noi di as text "  ✓ PASS: Default _T returned (as expected)"
        }
        else {
            noi di as error "  ✗ FAIL: Expected _T by default, got: `sex_codes'"
        }
    }
    else {
        noi di as error "  ✗ FAIL: Query failed with rc = " _rc
    }
}

*-----------------------------------------------------------------------
* TEST SUMMARY
*-----------------------------------------------------------------------
noi di as text _newline(2) "================================================================"
noi di as text "All tests completed - check results above"
noi di as text "✓ If all tests passed, the centralized filter architecture is working"
noi di as text "================================================================"


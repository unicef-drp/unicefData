*! Test: filtervector() option validation
*! Purpose: Verify that filtervector() cannot be used with individual filters
*! Test date: 2025-01-19

clear all
set more off

* Add unicefData to path
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

noi di _newline
noi di as text "================================================================"
noi di as text "TEST: filtervector() Validation"
noi di as text "================================================================"

*-----------------------------------------------------------------------
* TEST 1: Individual filters work (baseline)
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 1: Individual filters only - sex(M)"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
        sex(M) ///
        verbose nofilter clear
    
    if _rc == 0 {
        noi di as text "  ✓ PASS: Individual filter accepted"
    }
    else {
        noi di as error "  ✗ FAIL: Individual filter rejected (rc = " _rc ")"
    }
}

*-----------------------------------------------------------------------
* TEST 2: filtervector() alone works
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 2: filtervector() only - .INDICATOR..M"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
        filtervector(".INDICATOR..M") ///
        verbose nofilter clear
    
    if _rc == 0 {
        noi di as text "  ✓ PASS: filtervector() accepted"
    }
    else {
        noi di as error "  ✗ FAIL: filtervector() rejected (rc = " _rc ")"
    }
}

*-----------------------------------------------------------------------
* TEST 3: Both specified should error
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 3: Both filtervector() AND sex() - Should ERROR"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
        filtervector(".INDICATOR..M") ///
        sex(M) ///
        verbose nofilter clear
    
    if _rc == 198 {
        noi di as text "  ✓ PASS: Correctly rejected both options (rc = 198)"
    }
    else if _rc == 0 {
        noi di as error "  ✗ FAIL: Should have errored but accepted both"
    }
    else {
        noi di as text "  ✓ PASS: Errored with rc = " _rc " (expected non-zero)"
    }
}

*-----------------------------------------------------------------------
* TEST 4: filtervector() + age() should error
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 4: Both filtervector() AND age() - Should ERROR"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
        filtervector(".INDICATOR..M") ///
        age(Y0T4) ///
        verbose nofilter clear
    
    if _rc == 198 {
        noi di as text "  ✓ PASS: Correctly rejected both options (rc = 198)"
    }
    else if _rc == 0 {
        noi di as error "  ✗ FAIL: Should have errored but accepted both"
    }
    else {
        noi di as text "  ✓ PASS: Errored with rc = " _rc " (expected non-zero)"
    }
}

*-----------------------------------------------------------------------
* TEST 5: filtervector() + wealth() should error
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 5: Both filtervector() AND wealth() - Should ERROR"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
        filtervector(".INDICATOR..M") ///
        wealth(Q1) ///
        verbose nofilter clear
    
    if _rc == 198 {
        noi di as text "  ✓ PASS: Correctly rejected both options (rc = 198)"
    }
    else if _rc == 0 {
        noi di as error "  ✗ FAIL: Should have errored but accepted both"
    }
    else {
        noi di as text "  ✓ PASS: Errored with rc = " _rc " (expected non-zero)"
    }
}

*-----------------------------------------------------------------------
* TEST 6: Multiple individual filters work together
*-----------------------------------------------------------------------
noi di as text _newline(1) "TEST 6: Multiple individual filters - sex(M) age(Y0T4)"
noi di as text "--------"

capture noisily {
    unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
        sex(M) age(Y0T4) ///
        verbose nofilter clear
    
    if _rc == 0 {
        noi di as text "  ✓ PASS: Multiple individual filters accepted"
    }
    else {
        noi di as error "  ✗ FAIL: Multiple individual filters rejected (rc = " _rc ")"
    }
}

*-----------------------------------------------------------------------
* TEST SUMMARY
*-----------------------------------------------------------------------
noi di as text _newline(2) "================================================================"
noi di as text "Validation tests completed"
noi di as text "✓ If tests 1, 2, and 6 passed: Individual filters work"
noi di as text "✓ If tests 3, 4, and 5 passed: Validation prevents mixed usage"
noi di as text "================================================================"


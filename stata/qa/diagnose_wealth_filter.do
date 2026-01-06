/**
 * Diagnosis Script: Wealth Filter Bug
 * Purpose: Compare working sex() filter with broken wealth() filter
 * 
 * Expected:
 * - sex(F) returns only female observations
 * - wealth(Q1 Q5) returns only Q1 and Q5 quintiles
 * 
 * Actual:
 * - sex(F) works ✓
 * - wealth(Q1 Q5) returns ALL quintiles ✗
 */

clear all
set trace off

di _newline "{bf:=== DIAGNOSIS: Wealth Filter Bug ==}"

* ===========================================================================
* TEST 1: Sex Filter (WORKS)
* ===========================================================================
di _newline "{bf:Test 1: Sex Filter (should work)}"
di "{p 4 4 2}Command: unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) sex(F){p_end}"

clear
cap noi unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) sex(F) clear

if _rc == 0 {
    di _newline "{bf:Downloaded data:}"
    di "  Observations: " _N
    
    cap confirm variable sex
    if _rc == 0 {
        di "  Sex values present:"
        qui tab sex, missing
        
        qui count if sex != "F" & !missing(sex)
        if r(N) == 0 {
            di _newline "{result:✓ PASS}: sex(F) filter works - only F returned"
        }
        else {
            di _newline "{error:✗ FAIL}: sex(F) filter broken - found `r(N)' non-F observations"
        }
    }
    else {
        di "{error:ERROR}: sex variable not found"
    }
}
else {
    di "{error:ERROR}: Download failed (rc=`=_rc')"
}

* ===========================================================================
* TEST 2: Wealth Filter (BROKEN)
* ===========================================================================
di _newline "{bf:Test 2: Wealth Filter (broken)}"
di "{p 4 4 2}Command: unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) wealth(Q1 Q5){p_end}"

clear
cap noi unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) wealth(Q1 Q5) clear

if _rc == 0 {
    di _newline "{bf:Downloaded data:}"
    di "  Observations: " _N
    
    cap confirm variable wealth
    if _rc == 0 {
        di "  Wealth values present:"
        qui tab wealth, missing
        
        * Count Q1 and Q5 (expected)
        qui count if inlist(wealth, "Q1", "Q5")
        local q_count = r(N)
        
        * Count unexpected quintiles
        qui count if inlist(wealth, "Q2", "Q3", "Q4")
        local unexpected = r(N)
        
        di _newline "  Requested: Q1, Q5 only"
        di "  Found Q1/Q5: " `q_count' " observations"
        di "  Found Q2/Q3/Q4: " `unexpected' " observations (UNEXPECTED)"
        
        if `unexpected' == 0 {
            di _newline "{result:✓ PASS}: wealth(Q1 Q5) filter works"
        }
        else {
            di _newline "{error:✗ FAIL}: wealth(Q1 Q5) filter broken - found Q2, Q3, Q4 also"
        }
    }
    else {
        di "{error:ERROR}: wealth variable not found"
    }
}
else {
    di "{error:ERROR}: Download failed (rc=`=_rc')"
}

* ===========================================================================
* TEST 3: Wealth Filter Without Restriction (diagnostic)
* ===========================================================================
di _newline "{bf:Test 3: No wealth filter (diagnostic baseline)}"
di "{p 4 4 2}Command: unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019){p_end}"

clear
cap noi unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) clear

if _rc == 0 {
    di _newline "{bf:All wealth values (unfiltered):}"
    di "  Total observations: " _N
    
    * Show breakdown by wealth
    tab wealth, missing
}

* ===========================================================================
* CONCLUSION
* ===========================================================================
di _newline "{bf:{hline 70}}"
di "{bf:SUMMARY}"
di "{hline 70}"
di ""
di "The wealth() filter is NOT restricting returned data to requested"
di "quintiles. When requesting wealth(Q1 Q5), all quintiles are returned."
di ""
di "Possible causes:"
di "  1. UNICEF SDMX server ignores wealth dimension filters"
di "  2. Incorrect SDMX syntax in URL construction"
di "  3. Missing post-import filtering in Stata"
di ""
di "Next steps:"
di "  - Check verbose mode output to see actual SDMX URL"
di "  - Compare with Python unicef_api on same query"
di "  - Review SDMX wealth dimension documentation"
di ""


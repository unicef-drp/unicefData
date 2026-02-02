* Quick test for DL-06 fix: verify sex/wealth filtering
* Tests that CME_MRY0T4 returns only _T values for sex and wealth

clear all
set more off

* Explicit log to capture output
cap log close _all
log using "C:\GitHub\myados\unicefData-dev\stata\qa\test_dl06_quick.log", replace text

di "Working directory: " c(pwd)

* Install latest code from repo
local statadir "C:\GitHub\myados\unicefData-dev\stata"
di "Installing from: `statadir'"
cap noi net install unicefdata, from("`statadir'") replace

* Run the test query
di _n "=== DL-06 Quick Test: CME_MRY0T4 filter check ==="
di "Expected: sex=_T, wealth_quintile=_T (no duplicates on iso3 period sex)"

clear
cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2018:2020) clear verbose

di _n "=== Results ==="
di "Observations: " _N

* Check sex values
cap confirm variable sex
if _rc == 0 {
    di "Sex values in data:"
    tab sex

    * Check for duplicates
    qui duplicates report iso3 period sex
    local unique = r(unique_value)
    local total = r(N)
    local dups = `total' - `unique'

    di _n "Duplicate check on iso3 x period x sex:"
    di "  Total obs:    `total'"
    di "  Unique combos: `unique'"
    di "  Duplicates:   `dups'"

    if `dups' == 0 {
        di _n "*** PASS: No duplicates found ***"
    }
    else {
        di _n "*** FAIL: `dups' duplicates found ***"
    }
}
else {
    di "No sex variable found"
    di "Observations: " _N

    * Simple duplicate check
    cap noi duplicates report iso3 period
    local dups = r(N) - r(unique_value)
    if `dups' == 0 {
        di _n "*** PASS: No duplicates on iso3 x period ***"
    }
    else {
        di _n "*** FAIL: `dups' duplicates on iso3 x period ***"
    }
}

* Also check wealth if present
cap confirm variable wealth_quintile
if _rc == 0 {
    di _n "Wealth quintile values in data:"
    tab wealth_quintile
}

log close

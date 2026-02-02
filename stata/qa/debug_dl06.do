/*******************************************************************************
* Debug DL-06: Duplicate Detection Failure
* Date: 27 Jan 2026
* 
* Purpose: Investigate why DL-06 finds 30 duplicate observations
*******************************************************************************/

clear all
set more off

* Sync repo code
local thisdir = c(pwd)
local statadir = subinstr("`thisdir'", "/qa", "", 1)
local statadir = subinstr("`statadir'", "\qa", "", 1)
net install unicefdata, from("`statadir'") replace

* Download the same data as DL-06 test
di as text _n "Downloading CME_MRY0T4 data for USA, BRA, IND (2018-2020)..."
unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2018:2020) clear

* Show basic info
di as text _n "Dataset info:"
di as text "  Observations: " as result _N
di as text "  Variables: " as result c(k)
list in 1/10

* Check for sex variable
cap confirm variable sex
if _rc == 0 {
    di as text _n "sex variable exists"
    
    * Show sex values
    tab sex, missing
    
    * Check duplicates on iso3 × period × sex
    di as text _n "Checking duplicates on iso3 × period × sex..."
    duplicates report iso3 period sex
    
    * List duplicate observations
    di as text _n "Listing duplicate observations:"
    duplicates tag iso3 period sex, gen(dup_flag)
    
    if r(unique_value) < r(N) {
        di as err _n "Found " as result r(N) - r(unique_value) as err " duplicates"
        di as text _n "First 20 duplicate pairs:"
        list iso3 period sex indicator obs_value dup_flag if dup_flag > 0 in 1/20, sepby(iso3 period sex)
        
        * Show one example in detail
        sum dup_flag
        if r(max) > 0 {
            di as text _n "Detailed view of first duplicate group:"
            preserve
            keep if dup_flag > 0
            sort iso3 period sex
            list in 1/5, clean
            restore
        }
    }
    else {
        di as text "No duplicates found!"
    }
}
else {
    di as text _n "sex variable does NOT exist"
    di as text "Checking duplicates on iso3 × period × indicator..."
    duplicates report iso3 period indicator
    
    if r(unique_value) < r(N) {
        di as err "Found duplicates!"
        duplicates tag iso3 period indicator, gen(dup_flag)
        list iso3 period indicator obs_value if dup_flag > 0 in 1/20
    }
}

* Check all variables
di as text _n "All variables in dataset:"
describe

* Save dataset for inspection
save "debug_dl06_data.dta", replace
di as text _n "Data saved to debug_dl06_data.dta for manual inspection"

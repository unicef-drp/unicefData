/*******************************************************************************
* 05_advanced_features.do - Advanced Features
* =============================================
*
* Demonstrates advanced query features.
* Matches: R/examples/05_advanced_features.R
*          python/examples/05_advanced_features.py
*
* Examples:
*   1. Disaggregation by sex
*   2. Disaggregation by wealth quintile
*   3. Time series with specific year range
*   4. Multiple countries with latest values
*   5. Combining filters
*******************************************************************************/

clear all
set more off

* Setup data directory - centralized for cross-language validation
local data_dir "../../validation/data/stata"
capture mkdir "`data_dir'"

display _n "======================================================================"
display "05_advanced_features.do - Advanced Features"
display "======================================================================"

* =============================================================================
* Example 1: Disaggregation by Sex
* =============================================================================
display _n "--- Example 1: Disaggregation by Sex ---"
display "Under-5 mortality by sex" _n

unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) ///
    year(2020:2024) sex(M F) clear

display "Result: `=_N' rows"
list iso3 period sex value in 1/15, clean

export delimited using "`data_dir'/05_ex1_by_sex.csv", replace

* =============================================================================
* Example 2: Disaggregation by Wealth Quintile
* =============================================================================
display _n "--- Example 2: Disaggregation by Wealth ---"
display "Stunting by wealth quintile (poorest vs richest)" _n

* Get all wealth quintiles
unicefdata, indicator(NT_ANT_HAZ_NE2_MOD) countries(IND NGA ETH) ///
    year(2015:2024) clear

* Check if wealth data is available
capture confirm variable wealth
if _rc == 0 {
    display "Wealth quintiles available:"
    tab wealth
    
    * Keep only Q1 and Q5 for comparison
    keep if inlist(wealth, "Q1", "Q5")
    list iso3 period wealth value in 1/10, clean
}
else {
    display "No wealth-disaggregated data available for these indicators/countries"
}

export delimited using "`data_dir'/05_ex2_by_wealth.csv", replace

* =============================================================================
* Example 3: Time Series
* =============================================================================
display _n "--- Example 3: Time Series ---"
display "Mortality trends 2000-2023" _n

unicefdata, indicator(CME_MRY0T4) countries(ALB) ///
    year(2000:2023) clear

display "Time series: `=_N' observations"
list period value in 1/10, clean

* Plot if graph available
capture {
    twoway line value period, ///
        title("Under-5 Mortality Rate: Albania") ///
        ytitle("Deaths per 1,000") xtitle("Year")
    graph export "`data_dir'/05_ex3_timeseries.png", replace
}

export delimited using "`data_dir'/05_ex3_timeseries.csv", replace

* =============================================================================
* Example 4: Multiple Countries Latest
* =============================================================================
display _n "--- Example 4: Multiple Countries Latest ---"
display "Latest immunization rates for many countries" _n

unicefdata, indicator(IM_DTP3) ///
    countries(AFG ALB USA BRA IND CHN NGA ETH) ///
    year(2015:2024) latest clear

display "Result: `=_N' countries"
list iso3 country period value, clean

export delimited using "`data_dir'/05_ex4_latest_multi.csv", replace

* =============================================================================
* Example 5: Combining Filters
* =============================================================================
display _n "--- Example 5: Combining Filters ---"
display "Complex query with multiple filters" _n

unicefdata, indicator(CME_MRY0T4 CME_MRM0) ///
    countries(ALB USA BRA IND) ///
    year(2015:2023) ///
    sex(_T) ///
    simplify clear

display "Combined query: `=_N' rows"
display "Indicators:"
tab indicator

display _n "By country:"
tab iso3 indicator

export delimited using "`data_dir'/05_ex5_combined.csv", replace

* =============================================================================
* Example 6: Residence (Urban/Rural)
* =============================================================================
display _n "--- Example 6: Urban vs Rural ---"
display "Nutrition by residence type" _n

unicefdata, indicator(NT_ANT_HAZ_NE2_MOD) countries(IND BGD) ///
    year(2015:2024) residence(URBAN RURAL) clear

capture confirm variable residence
if _rc == 0 {
    display "Residence disaggregation:"
    tab residence
    list iso3 period residence value in 1/10, clean
}
else {
    display "No residence-disaggregated data for these indicators/countries"
}

export delimited using "`data_dir'/05_ex6_residence.csv", replace

display _n "======================================================================"
display "Advanced Features Complete!"
display "Files saved to: `data_dir'/"
display "======================================================================"

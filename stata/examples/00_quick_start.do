/*******************************************************************************
* 00_quick_start.do - Quick Start Guide
* ======================================
*
* Demonstrates the basic unicefdata command with 5 simple examples.
* Matches: R/examples/00_quick_start.R
*          python/examples/00_quick_start.py
*
* Examples:
*   1. Single indicator, specific countries
*   2. Multiple indicators
*   3. Nutrition data
*   4. Immunization data  
*   5. All countries (large download)
*******************************************************************************/

clear all
set more off

* Setup data directory - centralized for cross-language validation
local data_dir "../../validation/data/stata"
capture mkdir "`data_dir'"

display _n "======================================================================"
display "00_quick_start.do - UNICEF API Quick Start Guide"
display "======================================================================"

* =============================================================================
* Example 1: Single Indicator - Under-5 Mortality
* =============================================================================
display _n "--- Example 1: Single Indicator (Under-5 Mortality) ---"
display "Indicator: CME_MRY0T4"
display "Countries: Albania, USA, Brazil"
display "Years: 2015-2023" _n

unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) ///
    year(2015:2023) clear

display "Result: `=_N' rows, `=r(N_countries)' countries"
list iso3 country period value in 1/6, clean

export delimited using "`data_dir'/00_ex1_mortality.csv", replace

* =============================================================================
* Example 2: Multiple Indicators - Mortality Comparison
* =============================================================================
display _n "--- Example 2: Multiple Indicators (Mortality) ---"
display "Indicators: CME_MRM0 (Neonatal), CME_MRY0T4 (Under-5)"
display "Years: 2020-2023" _n

unicefdata, indicator(CME_MRM0 CME_MRY0T4) countries(ALB USA BRA) ///
    year(2020:2023) clear

display "Result: `=_N' rows"
tab indicator

export delimited using "`data_dir'/00_ex2_multi_indicators.csv", replace

* =============================================================================
* Example 3: Nutrition Data
* =============================================================================
display _n "--- Example 3: Nutrition Data ---"
display "Indicator: NT_ANT_HAZ_NE2_MOD (Stunting)"
display "Countries: Afghanistan, India, Nigeria"
display "Years: 2015+" _n

unicefdata, indicator(NT_ANT_HAZ_NE2_MOD) countries(AFG IND NGA) ///
    year(2015:2024) clear

display "Result: `=_N' rows"
if (_N > 0) {
    list iso3 country period value in 1/6, clean
    export delimited using "`data_dir'/00_ex3_nutrition.csv", replace
}
else {
    display "Note: No data available for this query"
}

* =============================================================================
* Example 4: Immunization Data
* =============================================================================
display _n "--- Example 4: Immunization Data ---"
display "Indicator: IM_DTP3 (DTP3 coverage)"
display "Countries: Nigeria, Kenya, South Africa"
display "Years: 2015-2023" _n

unicefdata, indicator(IM_DTP3) countries(NGA KEN ZAF) ///
    year(2015:2023) clear

display "Result: `=_N' rows"
if (_N > 0) {
    list iso3 country period value in 1/6, clean
    export delimited using "`data_dir'/00_ex4_immunization.csv", replace
}
else {
    display "Note: No data available for this query"
}

* =============================================================================
* Example 5: All Countries (Large Download)
* =============================================================================
display _n "--- Example 5: All Countries (Latest Values) ---"
display "Indicator: CME_MRY0T4"
display "Filter: latest value only" _n

unicefdata, indicator(CME_MRY0T4) year(2020:2024) latest clear

display "Result: `=_N' observations"
if (_N > 0) {
    summarize value
    export delimited using "`data_dir'/00_ex5_all_countries.csv", replace
}
else {
    display "Note: No data available for this query"
}

display _n "======================================================================"
display "Quick Start Complete!"
display "Files saved to: `data_dir'/"
display "======================================================================"

/*******************************************************************************
* 02_sdg_indicators.do - SDG Indicator Examples
* ==============================================
*
* Demonstrates fetching SDG-related indicators across different domains.
* Matches: R/examples/02_sdg_indicators.R
*          python/examples/02_sdg_indicators.py
*
* Examples:
*   1. Child Mortality (SDG 3.2)
*   2. Stunting/Wasting (SDG 2.2)
*   3. Education Completion (SDG 4.1)
*   4. Child Marriage (SDG 5.3)
*   5. WASH indicators (SDG 6)
*******************************************************************************/

clear all
set more off

* Setup data directory - centralized for cross-language validation
local data_dir "../../validation/data/stata"
capture mkdir "`data_dir'"

display _n "======================================================================"
display "02_sdg_indicators.do - SDG Indicator Examples"
display "======================================================================"

* Common parameters
local COUNTRIES "AFG BGD BRA ETH IND NGA PAK"
local START_YEAR 2015

* =============================================================================
* Example 1: Child Mortality (SDG 3.2)
* =============================================================================
display _n "--- Example 1: Child Mortality (SDG 3.2) ---"
display "Under-5 and Neonatal mortality rates" _n

unicefdata, indicator(CME_MRY0T4 CME_MRM0) countries(`COUNTRIES') ///
    start_year(`START_YEAR') clear

display "Result: `=_N' rows"
tab indicator
export delimited using "`data_dir'/02_ex1_child_mortality.csv", replace

* =============================================================================
* Example 2: Nutrition (SDG 2.2)
* =============================================================================
display _n "--- Example 2: Nutrition (SDG 2.2) ---"
display "Stunting, Wasting, Overweight" _n

unicefdata, indicator(NT_ANT_HAZ_NE2_MOD NT_ANT_WHZ_NE2 NT_ANT_WHZ_PO2_MOD) ///
    countries(`COUNTRIES') start_year(`START_YEAR') clear

display "Result: `=_N' rows"
tab indicator
export delimited using "`data_dir'/02_ex2_nutrition.csv", replace

* =============================================================================
* Example 3: Education Completion (SDG 4.1)
* =============================================================================
display _n "--- Example 3: Education (SDG 4.1) ---"
display "Completion rates - Primary, Lower Secondary, Upper Secondary" _n

* Education indicators require explicit dataflow for reliability
unicefdata, indicator(ED_CR_L1_UIS_MOD ED_CR_L2_UIS_MOD ED_CR_L3_UIS_MOD) ///
    dataflow(EDUCATION_UIS_SDG) countries(`COUNTRIES') ///
    start_year(`START_YEAR') clear

display "Result: `=_N' rows"
tab indicator
export delimited using "`data_dir'/02_ex3_education.csv", replace

* =============================================================================
* Example 4: Child Marriage (SDG 5.3)
* =============================================================================
display _n "--- Example 4: Child Marriage (SDG 5.3) ---"
display "Women married before age 18" _n

unicefdata, indicator(PT_F_20-24_MRD_U18_TND) countries(`COUNTRIES') ///
    start_year(`START_YEAR') clear

display "Result: `=_N' rows"
list iso3 country period value in 1/10, clean
export delimited using "`data_dir'/02_ex4_child_marriage.csv", replace

* =============================================================================
* Example 5: WASH (SDG 6)
* =============================================================================
display _n "--- Example 5: WASH (SDG 6) ---"
display "Safely managed water and sanitation" _n

unicefdata, indicator(WS_PPL_W-SM WS_PPL_S-SM) countries(`COUNTRIES') ///
    start_year(`START_YEAR') clear

display "Result: `=_N' rows"
tab indicator
export delimited using "`data_dir'/02_ex5_wash.csv", replace

display _n "======================================================================"
display "SDG Indicators Complete!"
display "Files saved to: `data_dir'/"
display "======================================================================"

/*******************************************************************************
* 04_metadata_options.do - Working with Metadata
* ================================================
*
* Demonstrates metadata options and variable labels.
* Matches: R/examples/04_metadata_options.R
*          python/examples/04_metadata_options.py
*
* Examples:
*   1. View variable labels (metadata)
*   2. Filter by sex
*   3. Filter by wealth quintile
*   4. Raw SDMX output
*   5. Simplified output columns
*   6. Add region classification (UNICEF regions)
*   7. Add income group (World Bank classification)
*   8. Multiple metadata (region + income + continent)
*   9. Verbose mode for debugging
*
* Note: Stata includes metadata as variable labels by default.
*       Use 'describe' or 'codebook' to view labels.
*       Use addmeta() option to add country classifications.
*******************************************************************************/

clear all
set more off

* Setup data directory - centralized for cross-language validation
local data_dir "../../validation/data/stata"
capture mkdir "`data_dir'"

display _n "======================================================================"
display "04_metadata_options.do - Working with Metadata"
display "======================================================================"

local COUNTRIES "ALB USA BRA IND NGA ETH CHN"

* =============================================================================
* Example 1: View Variable Labels (Metadata)
* =============================================================================
display _n "--- Example 1: View Variable Labels ---"
display "Stata includes descriptive labels on all variables" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    year(2020:2024) latest clear

describe

display _n "Selected variable labels:"
foreach var in iso3 country indicator period value {
    local lbl : variable label `var'
    display "  `var': `lbl'"
}

* =============================================================================
* Example 2: Filter by Sex
* =============================================================================
display _n "--- Example 2: Filter by Sex ---"
display "Get female-only data" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    year(2020:2024) sex(F) clear

display "Result: `=_N' rows (female only)"
tab sex

export delimited using "`data_dir'/04_ex2_female.csv", replace

* =============================================================================
* Example 3: Filter by Wealth Quintile
* =============================================================================
display _n "--- Example 3: Filter by Wealth Quintile ---"
display "Compare poorest vs richest quintiles" _n

* Get poorest quintile
unicefdata, indicator(NT_ANT_HAZ_NE2_MOD) countries(IND BGD) ///
    year(2015:2024) wealth(Q1) clear
    
display "Poorest quintile (Q1): `=_N' rows"
list iso3 period wealth value if _n <= 5, clean

* Get richest quintile
unicefdata, indicator(NT_ANT_HAZ_NE2_MOD) countries(IND BGD) ///
    year(2015:2024) wealth(Q5) clear
    
display "Richest quintile (Q5): `=_N' rows"
list iso3 period wealth value if _n <= 5, clean

* =============================================================================
* Example 4: Raw Output
* =============================================================================
display _n "--- Example 4: Raw SDMX Output ---"
display "Original variable names without standardization" _n

unicefdata, indicator(CME_MRY0T4) countries(ALB) ///
    year(2020:2024) raw clear

display "Raw variable names:"
describe, short

export delimited using "`data_dir'/04_ex4_raw.csv", replace

* =============================================================================
* Example 5: Simplified Output
* =============================================================================
display _n "--- Example 5: Simplified Output ---"
display "Essential columns only" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    year(2020:2024) simplify clear

display "Simplified columns:"
describe, short
list in 1/5, clean

export delimited using "`data_dir'/04_ex5_simplified.csv", replace

* =============================================================================
* Example 6: Add Region Classification
* =============================================================================
display _n "--- Example 6: Add Region Classification ---"
display "UNICEF regional classification" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    year(2020) addmeta(region) latest clear

display "Columns with region:"
describe, short
list iso3 country region value in 1/5, clean

export delimited using "`data_dir'/04_ex6_region.csv", replace

* =============================================================================
* Example 7: Add Income Group
* =============================================================================
display _n "--- Example 7: Add Income Group ---"
display "World Bank income classification" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    year(2020) addmeta(income_group) latest clear

display "Columns with income group:"
list iso3 country income_group value, clean

export delimited using "`data_dir'/04_ex7_income.csv", replace

* =============================================================================
* Example 8: Multiple Metadata
* =============================================================================
display _n "--- Example 8: Multiple Metadata ---"
display "Combine region, income group, and continent" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    year(2020) addmeta(region income_group continent) latest clear

display "Columns with all metadata:"
describe, short
list iso3 country region income_group continent value in 1/5, clean

export delimited using "`data_dir'/04_ex8_multiple.csv", replace

* =============================================================================
* Example 9: Verbose Mode for Debugging
* =============================================================================
display _n "--- Example 9: Verbose Mode ---"
display "Show API request details" _n

unicefdata, indicator(CME_MRY0T4) countries(ALB USA) ///
    year(2020:2024) verbose clear

display _n "======================================================================"
display "Metadata Options Complete!"
display "Files saved to: `data_dir'/"
display "======================================================================"

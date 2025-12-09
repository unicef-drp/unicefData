/*******************************************************************************
* 03_data_formats.do - Output Format Options
* ==========================================
*
* Demonstrates different output formats and data transformations.
* Matches: R/examples/03_data_formats.R
*          python/examples/03_data_formats.py
*
* Examples:
*   1. Long format (default)
*   2. Wide format (indicators as columns)
*   3. Simplified output
*   4. Latest value per country
*   5. Most recent N values (MRV)
*******************************************************************************/

clear all
set more off

* Setup data directory - centralized for cross-language validation
local data_dir "../../validation/data/stata"
capture mkdir "`data_dir'"

display _n "======================================================================"
display "03_data_formats.do - Output Format Options"
display "======================================================================"

local COUNTRIES "ALB USA BRA IND NGA"

* =============================================================================
* Example 1: Long Format (Default)
* =============================================================================
display _n "--- Example 1: Long Format (Default) ---"
display "One row per observation" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    start_year(2020) clear

display "Shape: `=_N' rows x `=c(k)' columns"
list iso3 country period value in 1/10, clean

export delimited using "`data_dir'/03_ex1_long.csv", replace

* =============================================================================
* Example 2: Wide Format (Indicators as Columns)
* =============================================================================
display _n "--- Example 2: Wide Format (Indicators as Columns) ---"
display "Multiple indicators reshaped to columns" _n

unicefdata, indicator(CME_MRY0T4 CME_MRM0) countries(`COUNTRIES') ///
    start_year(2020) wide clear

display "Shape: `=_N' rows x `=c(k)' columns"
describe, short
list in 1/10, clean

export delimited using "`data_dir'/03_ex2_wide.csv", replace

* =============================================================================
* Example 3: Simplified Output
* =============================================================================
display _n "--- Example 3: Simplified Output ---"
display "Essential columns only (iso3, country, indicator, period, value, lb, ub)" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    start_year(2020) simplify clear

display "Shape: `=_N' rows x `=c(k)' columns"
describe, short
list in 1/10, clean

export delimited using "`data_dir'/03_ex3_simplified.csv", replace

* =============================================================================
* Example 4: Latest Value Per Country
* =============================================================================
display _n "--- Example 4: Latest Value Per Country ---"
display "Cross-sectional analysis (one value per country)" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    start_year(2015) latest clear

display "Shape: `=_N' rows (one row per country)"
list iso3 country period value, clean

export delimited using "`data_dir'/03_ex4_latest.csv", replace

* =============================================================================
* Example 5: Most Recent N Values (MRV)
* =============================================================================
display _n "--- Example 5: Most Recent 3 Values (MRV=3) ---"
display "Keep only 3 most recent years per country" _n

unicefdata, indicator(CME_MRY0T4) countries(ALB USA) ///
    start_year(2010) mrv(3) clear

display "Result: `=_N' rows"
bysort iso3 (period): list iso3 country period value, sepby(iso3)

export delimited using "`data_dir'/03_ex5_mrv3.csv", replace

* =============================================================================
* Example 6: Drop Missing Values
* =============================================================================
display _n "--- Example 6: Drop Missing Values ---"
display "Remove observations with missing values" _n

unicefdata, indicator(CME_MRY0T4) countries(`COUNTRIES') ///
    start_year(2020) dropna clear

display "Result: `=_N' rows (no missing values)"
summarize value

export delimited using "`data_dir'/03_ex6_dropna.csv", replace

display _n "======================================================================"
display "Data Formats Complete!"
display "Files saved to: `data_dir'/"
display "======================================================================"

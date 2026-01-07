*! -unicefdata_examples-: Auxiliary program for -unicefdata-
*! Version 1.5.2 - 07 January 2026
*! Version 1.0.0 - 17 December 2025
*! Author: Joao Pedro Azevedo
*! UNICEF
*! Repo: https://github.com/unicef-drp/unicefData
*
* This auxiliary program provides interactive examples for unicefdata command.
* Examples cover discovery, data retrieval, reshape options, and common analyses.
*
* Link to main help: help unicefdata
* For all examples: unicefdata_examples [exampleNN]
* Interactive examples can also be run from the help file's Examples section.

*  ----------------------------------------------------------------------------
*  1. Main program
*  ----------------------------------------------------------------------------

capture program drop unicefdata_examples
program unicefdata_examples
version 14.0
args EXAMPLE
set more off
`EXAMPLE'
end


*  ============================================================================
*  DISCOVERY EXAMPLES (List available dataflows, indicators, search)
*  ============================================================================

*  ----------------------------------------------------------------------------
*  Example 01: List all available dataflows
*  Link: help unicefdata > Discovery Commands > flows option
*  ----------------------------------------------------------------------------

capture program drop example01
program example01
    di as text "{title:EXAMPLE 01: List Available Dataflows}"
    di as text ""
    di as text "Command: unicefdata, flows detail"
    di as text "Purpose: Discover all UNICEF SDMX dataflows"
    di as text ""
    
    unicefdata, flows detail
    
    di as text ""
    di as text "Use 'help unicefdata' and search for 'flows' to see more discovery options."
end


*  ----------------------------------------------------------------------------
*  Example 02: Search indicators by keyword
*  Link: help unicefdata > Discovery Commands > search option
*  ----------------------------------------------------------------------------

capture program drop example02
program example02
    di as text "{title:EXAMPLE 02: Search for Mortality Indicators}"
    di as text ""
    di as text "Command: unicefdata, search(mortality)"
    di as text "Purpose: Find all indicators matching a keyword"
    di as text ""
    
    unicefdata, search(mortality) limit(15)
    
    di as text ""
    di as text "Note: Use search(keyword) dataflow(ID) to limit search to a specific dataflow."
end


*  ----------------------------------------------------------------------------
*  Example 03: List indicators in a specific dataflow
*  Link: help unicefdata > Discovery Commands > indicators option
*  ----------------------------------------------------------------------------

capture program drop example03
program example03
    di as text "{title:EXAMPLE 03: List Indicators in CME Dataflow}"
    di as text ""
    di as text "Command: unicefdata, indicators(CME)"
    di as text "Purpose: See all indicators available in a dataflow (Child Mortality Estimates)"
    di as text ""
    
    unicefdata, indicators(CME)
    
    di as text ""
    di as text "CME = Child Mortality Estimates (UNICEF, WHO, WB, UN)"
end


*  ============================================================================
*  DATA RETRIEVAL EXAMPLES (Download indicators with various filters)
*  ============================================================================

*  ----------------------------------------------------------------------------
*  Example 04: Basic data retrieval - Under-5 mortality
*  Link: help unicefdata > Data Retrieval > Basic indicator download
*  ----------------------------------------------------------------------------

capture program drop example04
program example04
    di as text "{title:EXAMPLE 04: Download Under-5 Mortality Data}"
    di as text ""
    di as text "Command: unicefdata, indicator(CME_MRY0T4) countries(AFG BGD IND) clear"
    di as text "Purpose: Download a single indicator for specific countries"
    di as text ""
    
    unicefdata, indicator(CME_MRY0T4) countries(AFG BGD IND) clear
    
    di as text ""
    di as text "Variables returned: iso3, country, indicator, indicator_name, period, value, sex, age,"
    di as text "                  wealth, residence, unit, lb, ub, status, source, notes"
    di as text ""
    
    describe
    di as text ""
    list iso3 country indicator period value sex in 1/10, sep(5) noobs
end


*  ----------------------------------------------------------------------------
*  Example 05: Multiple indicators for comparison
*  Link: help unicefdata > Data Retrieval > Reshape > wide_indicators
*  NEW in v1.5.2: wide_indicators now creates empty columns for all requested indicators
*  ----------------------------------------------------------------------------

capture program drop example05
program example05
    di as text "{title:EXAMPLE 05: Compare Multiple Child Mortality Indicators}"
    di as text ""
    di as text "Command: unicefdata, indicator(CME_MRY0T4 CME_MRY0) countries(BRA MEX ARG) latest clear"
    di as text "Purpose: Download multiple indicators for side-by-side comparison"
    di as text ""
    
    unicefdata, indicator(CME_MRY0T4 CME_MRY0) countries(BRA MEX ARG) latest clear
    
    di as text ""
    di as text "Current data structure (long format, ready for reshape):"
    di as text ""
    
    list iso3 country indicator period value if sex == "_T", sep(6) noobs
    
    di as text ""
    di as text "TIP: Use 'wide_indicators' option to reshape indicators as columns for easier analysis"
    di as text "     See Example 09 for reshape demonstration"
end


*  ============================================================================
*  FILTERING & DISAGGREGATION EXAMPLES
*  ============================================================================

*  ----------------------------------------------------------------------------
*  Example 06: Filter by sex disaggregation
*  Link: help unicefdata > Options > sex(string)
*  ----------------------------------------------------------------------------

capture program drop example06
program example06
    di as text "{title:EXAMPLE 06: Gender-Disaggregated Data}"
    di as text ""
    di as text "Command: unicefdata, indicator(CME_MRY0T4) countries(ETH KEN UGA) year(2020) sex(ALL) clear"
    di as text "Purpose: Download data disaggregated by sex (Total, Male, Female)"
    di as text ""
    
    unicefdata, indicator(CME_MRY0T4) countries(ETH KEN UGA) year(2020) sex(ALL) clear
    
    di as text ""
    list iso3 country sex period value, sep(9) noobs
    
    di as text ""
    di as text "Sex codes: _T (Total), _M (Male), _F (Female)"
    di as text "Use 'wide_attributes attributes(_T _M _F)' to create gender comparison columns"
end


*  ----------------------------------------------------------------------------
*  Example 07: Filter by wealth quintile
*  Link: help unicefdata > Options > wealth(string)
*  Link: help unicefdata > Options > attributes(string)
*  NEW in v1.5.2: attributes() filtering now robust for wide_indicators reshape
*  ----------------------------------------------------------------------------

capture program drop example07
program example07
    di as text "{title:EXAMPLE 07: Wealth-Based Equity Analysis}"
    di as text ""
    di as text "Command: unicefdata, indicator(NT_ANT_HAZ_NE2) countries(PAK NGA ZWE) latest attributes(_T _Q1 _Q5) clear"
    di as text "Purpose: Compare richest vs. poorest for equity analysis (stunting prevalence)"
    di as text ""
    
    unicefdata, indicator(NT_ANT_HAZ_NE2) countries(PAK NGA ZWE) latest attributes(_T _Q1 _Q5) clear
    
    di as text ""
    list iso3 country period value, sep(3) noobs
    
    di as text ""
    di as text "Wealth codes: _T (Total), _Q1 (Poorest), _Q2, _Q3, _Q4, _Q5 (Richest)"
    di as text "This example shows inequality in child stunting by wealth quintile"
end


*  ============================================================================
*  RESHAPE & OUTPUT FORMAT EXAMPLES (v1.5.1+)
*  ============================================================================

*  ----------------------------------------------------------------------------
*  Example 08: Reshape to wide format (years as columns)
*  Link: help unicefdata > Options > wide
*  Reference: Stata Journal example wbopendata_examples for inspiration
*  ----------------------------------------------------------------------------

capture program drop example08
program example08
    di as text "{title:EXAMPLE 08: Wide Format - Years as Columns (Time Series)}"
    di as text ""
    di as text "Command: unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2015:2020) wide clear"
    di as text "Purpose: Create time-series format with years as columns (yr2015, yr2016, ...)"
    di as text ""
    
    unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2015:2020) wide clear
    
    di as text ""
    list iso3 country yr*, sep(0) noobs
    
    di as text ""
    di as text "Structure: One row per iso3 × indicator, columns are years (yr2015, yr2016, ...)"
    di as text "Use this format for time-series regression, correlation analysis, or plotting trends"
end


*  ----------------------------------------------------------------------------
*  Example 09: Reshape with indicators as columns (v1.5.2: enhanced)
*  Link: help unicefdata > Options > wide_indicators
*  NEW in v1.5.2: Now creates empty columns for all requested indicators
*  Reference: MULTI-01 test validates this feature
*  ----------------------------------------------------------------------------

capture program drop example09
program example09
    di as text "{title:EXAMPLE 09: wide_indicators - Indicators as Columns (NEW v1.5.2)}"
    di as text ""
    di as text "Command: unicefdata, indicator(CME_MRY0T4 IM_DTP3) countries(USA MEX BRA) latest wide_indicators clear"
    di as text "Purpose: Create cross-indicator format with indicators as separate columns"
    di as text ""
    di as text "NEW in v1.5.2: Even if one indicator has no data for some countries,"
    di as text "an empty numeric column is created to prevent reshape failures."
    di as text ""
    
    unicefdata, indicator(CME_MRY0T4 IM_DTP3) countries(USA MEX BRA) latest wide_indicators clear
    
    di as text ""
    describe
    di as text ""
    list iso3 country CME_MRY0T4 IM_DTP3, sep(0) noobs
    
    di as text ""
    di as text "Structure: One row per iso3 × country × period, columns are indicators (CME_MRY0T4, IM_DTP3, ...)"
    di as text "Use this format for correlation analysis, multi-indicator comparisons"
end


*  ----------------------------------------------------------------------------
*  Example 10: Reshape with disaggregation attributes as columns (v1.5.1)
*  Link: help unicefdata > Options > wide_attributes
*  Link: help unicefdata > Options > attributes(string)
*  NEW in v1.5.1: Separate reshape strategy for disaggregation attributes
*  ----------------------------------------------------------------------------

capture program drop example10
program example10
    di as text "{title:EXAMPLE 10: wide_attributes - Disaggregations as Columns (v1.5.1)}"
    di as text ""
    di as text "Command: unicefdata, indicator(CME_MRY0T4) countries(ETH KEN) year(2020) sex(ALL) wide_attributes clear"
    di as text "Purpose: Create attribute format with sex/wealth/residence as column suffixes"
    di as text ""
    
    unicefdata, indicator(CME_MRY0T4) countries(ETH KEN) year(2020) sex(ALL) wide_attributes clear
    
    di as text ""
    list iso3 country CME_MRY0T4*, sep(0) noobs
    
    di as text ""
    di as text "Structure: One row per iso3 × country × period"
    di as text "Columns: indicator_T (total), indicator_M (male), indicator_F (female), etc."
    di as text "Use this format for gender/equity gap analysis, comparing disaggregations"
end


*  ============================================================================
*  ANALYTICAL EXAMPLES (Common workflows)
*  ============================================================================

*  ----------------------------------------------------------------------------
*  Example 11: Trend analysis - Under-5 mortality in South Asia
*  Link: help unicefdata > Examples (in help file)
*  Workflow: Discovery → Download → Reshape → Graph
*  ----------------------------------------------------------------------------

capture program drop example11
program example11
    di as text "{title:EXAMPLE 11: Trend Analysis - Under-5 Mortality in South Asia}"
    di as text ""
    di as text "Workflow: (1) Get indicator info  (2) Download  (3) Visualize trends"
    di as text ""
    
    * (1) Get indicator info
    di as text "Step 1: Get indicator information"
    unicefdata, info(CME_MRY0T4)
    
    * (2) Download data
    di as text ""
    di as text "Step 2: Download data for South Asian countries (latest 10 years)"
    unicefdata, indicator(CME_MRY0T4) countries(AFG BGD BTN IND MDV NPL PAK LKA) year(2014:2023) clear
    
    keep if sex == "_T"
    
    * (3) Create visualization
    di as text ""
    di as text "Step 3: Create trend comparison"
    
    graph twoway ///
        (connected value period if iso3 == "AFG", lcolor(red) mcolor(red)) ///
        (connected value period if iso3 == "BGD", lcolor(blue) mcolor(blue)) ///
        (connected value period if iso3 == "IND", lcolor(green) mcolor(green)) ///
        (connected value period if iso3 == "PAK", lcolor(orange) mcolor(orange)), ///
            legend(order(1 "Afghanistan" 2 "Bangladesh" 3 "India" 4 "Pakistan") rows(1)) ///
            ytitle("Under-5 Mortality (per 1,000 live births)") ///
            xtitle("Year") ///
            title("Under-5 Mortality Trends: South Asia") ///
            note("Source: UNICEF Data Warehouse via unicefdata (Azevedo 2026)")
    
    di as text ""
    di as text "Graph displayed. Use 'graph export' to save as .png, .pdf, etc."
end


*  ----------------------------------------------------------------------------
*  Example 12: Equity gap analysis - Stunting by wealth quintile
*  Link: help unicefdata > Examples > Patterns > Equity gap analysis
*  Workflow: Download → Filter → Reshape → Calculate gaps → Visualize
*  NEW in v1.5.2: wide_attributes with attributes filtering ensures robust reshape
*  ----------------------------------------------------------------------------

capture program drop example12
program example12
    di as text "{title:EXAMPLE 12: Equity Analysis - Stunting by Wealth Quintile}"
    di as text ""
    di as text "Workflow: (1) Download with ALL wealth disaggregations  (2) Reshape  (3) Analyze gaps"
    di as text ""
    
    * (1) Download stunting with wealth disaggregations
    di as text "Step 1: Download stunting indicator with wealth disaggregations"
    unicefdata, indicator(NT_ANT_HAZ_NE2) countries(PAK NGA ZWE BEN) latest attributes(ALL) wide_attributes clear
    
    * (2) Calculate wealth-based statistics
    di as text ""
    di as text "Step 2: Compare richest (Q5) vs. poorest (Q1)"
    
    keep iso3 country *_Q1 *_Q5
    rename *_Q1 poorest
    rename *_Q5 richest
    
    gen gap = richest - poorest
    
    list iso3 country poorest richest gap, sep(0) noobs
    
    di as text ""
    di as text "Interpretation: Positive gap = richest children more likely to be stunted"
    di as text "               Negative gap = poorest children more stunted (typical pattern)"
end


*  ============================================================================
*  ADVANCED EXAMPLES (Cross-platform consistency, batch processing)
*  ============================================================================

*  ----------------------------------------------------------------------------
*  Example 13: Export to Excel for presentation
*  Link: help unicefdata > Workflow > Export
*  Integration: unicefdata + export excel for policy briefs/dashboards
*  ----------------------------------------------------------------------------

capture program drop example13
program example13
    di as text "{title:EXAMPLE 13: Export Data to Excel for Presentation}"
    di as text ""
    di as text "Workflow: Download → Select columns → Export"
    di as text ""
    
    * Download latest CME indicators for selected countries
    unicefdata, indicator(CME_MRY0T4 CME_MRY0 CME_MRM0) countries(ETH NGA PAK ZWE) latest clear
    
    * Keep total only
    keep if sex == "_T"
    
    * Select key variables for export
    keep iso3 country indicator period value lb ub
    
    * Rename for user-friendly Excel headers
    rename value estimate
    rename lb lower_bound
    rename ub upper_bound
    
    * Sort for presentation
    sort country indicator period
    
    * Export
    di as text "Step 1: Create Excel file"
    export excel using "unicef_mortality_indicators.xlsx", firstrow(variables) replace
    
    di as text ""
    di as result "✓ Data exported to: unicef_mortality_indicators.xlsx"
    di as text "  Variables: iso3, country, indicator, period, estimate, lower_bound, upper_bound"
end


*  ============================================================================
*  HELP & REFERENCE
*  ============================================================================

*  ----------------------------------------------------------------------------
*  Example 14: Getting help and exploring options
*  Link: help unicefdata
*  ----------------------------------------------------------------------------

capture program drop example14
program example14
    di as text "{title:EXAMPLE 14: Help & Reference}"
    di as text ""
    di as text "To get help on unicefdata:"
    di as text ""
    di as text "  help unicefdata          - Full command documentation"
    di as text "  help unicefdata_sync     - Synchronize metadata from SDMX"
    di as text "  help yaml                - For YAML metadata parsing"
    di as text ""
    di as text "To run these examples:"
    di as text ""
    di as text "  unicefdata_examples example01  - List available dataflows"
    di as text "  unicefdata_examples example04  - Download a single indicator"
    di as text "  unicefdata_examples example11  - Trend analysis workflow"
    di as text ""
    di as text "To view all examples:"
    di as text ""
    di as text "  unicefdata_examples          - Show this help text"
    di as text ""
    di as text "Key resources:"
    di as text ""
    di as text "  UNICEF Data: https://data.unicef.org/"
    di as text "  SDMX API:    https://sdmx.data.unicef.org/"
    di as text "  GitHub:      https://github.com/unicef-drp/unicefData"
end

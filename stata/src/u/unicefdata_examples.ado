*! -unicefdata_examples-: Auxiliary program for -unicefdata-
*! Version 1.5.2 - 07 January 2026
*! Version 1.0.0 - 17 December 2025
*! Author: Joao Pedro Azevedo
*! UNICEF
*! Repo: https://github.com/unicef-drp/unicefData
*
* This auxiliary program provides multi-line interactive examples for unicefdata.
* These examples demonstrate complete analytical workflows requiring multiple steps.
* Single-command examples are available in: help unicefdata
*
* To run: unicefdata_examples example01 (example02, example03, etc.)

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


*  ----------------------------------------------------------------------------
*  Example 01: Under-5 mortality trend analysis
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Graph
*  ----------------------------------------------------------------------------

capture program drop example01
program example01
    * Download under-5 mortality data for South Asian countries
    unicefdata, indicator(CME_MRY0T4) countries(AFG BGD BTN IND MDV NPL PAK LKA) clear
    
    * Keep only total (both sexes)
    keep if sex == "_T"
    
    * Create trend graph
    graph twoway ///
        (connected value period if iso3 == "AFG", lcolor(red) mcolor(red)) ///
        (connected value period if iso3 == "BGD", lcolor(blue) mcolor(blue)) ///
        (connected value period if iso3 == "IND", lcolor(green) mcolor(green)) ///
        (connected value period if iso3 == "PAK", lcolor(orange) mcolor(orange)), ///
            legend(order(1 "Afghanistan" 2 "Bangladesh" 3 "India" 4 "Pakistan") rows(1)) ///
            ytitle("Under-5 mortality rate (per 1,000 live births)") xtitle("Year") ///
            title("Under-5 Mortality Trends in South Asia") ///
            note("Source: UNICEF Data Warehouse via unicefdata")
end


*  ----------------------------------------------------------------------------
*  Example 02: Stunting by wealth quintile
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Create variables → Collapse → Graph
*  ----------------------------------------------------------------------------

capture program drop example02
program example02
    * Download stunting data with all wealth disaggregations
    unicefdata, indicator(NT_ANT_HAZ_NE2) sex(ALL) latest clear
    
    * Keep observations with wealth quintile data
    keep if inlist(wealth, "Q1", "Q2", "Q3", "Q4", "Q5")
    
    * Create numeric wealth variable
    gen wealth_num = real(substr(wealth, 2, 1))
    
    * Calculate mean stunting by wealth quintile
    collapse (mean) mean_stunting = value, by(wealth wealth_num)
    
    * Create bar chart
    graph bar mean_stunting, over(wealth, label(labsize(small))) ///
        ytitle("Stunting prevalence (%)") ///
        title("Child Stunting by Wealth Quintile") ///
        subtitle("Global average, latest available data") ///
        note("Q1=Poorest, Q5=Richest. Source: UNICEF Data Warehouse via unicefdata", size(*.7)) ///
        bar(1, color(navy))
end


*  ----------------------------------------------------------------------------
*  Example 03: Multiple indicators comparison
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Keep latest → Reshape → Graph
*  ----------------------------------------------------------------------------

capture program drop example03
program example03
    * Download multiple CME indicators for comparison
    unicefdata, indicator(CME_MRY0T4 CME_MRY0 CME_MRM0) ///
        countries(BRA MEX ARG COL PER CHL) year(2020:2023) clear
    
    * Keep only total values
    keep if sex == "_T"
    
    * Keep latest year per country-indicator
    bysort iso3 indicator (period): keep if _n == _N
    
    * Reshape to wide format
    keep iso3 country indicator value
    reshape wide value, i(iso3 country) j(indicator) string
    
    * Create grouped bar chart
    graph bar valueCME_MRY0T4 valueCME_MRY0 valueCME_MRM0, ///
        over(country, label(angle(45) labsize(small))) ///
        legend(order(1 "Under-5" 2 "Infant" 3 "Neonatal") rows(1)) ///
        ytitle("Mortality rate (per 1,000 live births)") ///
        title("Child Mortality Indicators in Latin America") ///
        subtitle("Most recent year available") ///
        note("Source: UNICEF Child Mortality Estimates via unicefdata", size(*.7))
end


*  ----------------------------------------------------------------------------
*  Example 04: Immunization coverage trends
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Collapse → Reshape → Graph
*  ----------------------------------------------------------------------------

capture program drop example04
program example04
    * Download DTP3 and MCV1 immunization data
    unicefdata, indicator(IM_DTP3 IM_MCV1) year(2000:2023) clear
    
    * Keep only total
    keep if sex == "_T"
    
    * Calculate global average by year and indicator
    collapse (mean) coverage = value, by(period indicator)
    
    * Reshape for graphing
    reshape wide coverage, i(period) j(indicator) string
    rename coverageIM_DTP3 dtp3
    rename coverageIM_MCV1 mcv1
    
    * Create trend comparison
    graph twoway ///
        (line dtp3 period, lcolor(blue) lwidth(medium)) ///
        (line mcv1 period, lcolor(red) lwidth(medium)), ///
            legend(order(1 "DTP3" 2 "MCV1") rows(1)) ///
            ytitle("Coverage (%)") xtitle("Year") ///
            title("Global Immunization Coverage Trends") ///
            subtitle("DTP3 and Measles (MCV1) vaccines") ///
            note("Source: UNICEF/WHO Immunization Estimates via unicefdata", size(*.7))
end


*  ----------------------------------------------------------------------------
*  Example 05: Regional comparison with metadata
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Collapse → Sort → Graph
*  ----------------------------------------------------------------------------

capture program drop example05
program example05
    * Download under-5 mortality with regional metadata
    unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) latest clear
    
    * Keep only country-level data (exclude aggregates)
    keep if geo_type == "country" & sex == "_T"
    
    * Calculate regional averages
    collapse (mean) avg_u5mr = value, by(region)
    
    * Sort by mortality rate
    gsort -avg_u5mr
    
    * Create bar chart
    graph hbar avg_u5mr, over(region, sort(1) descending label(labsize(small))) ///
        ytitle("Under-5 mortality rate (per 1,000)") ///
        title("Under-5 Mortality by UNICEF Region") ///
        subtitle("Latest available year, country averages") ///
        note("Source: UNICEF Data Warehouse via unicefdata", size(*.7)) ///
        bar(1, color(navy))
end


*  ----------------------------------------------------------------------------
*  Example 06: Export to Excel with formatting
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Select columns → Rename → Export
*  ----------------------------------------------------------------------------

capture program drop example06
program example06
    * Download comprehensive data
    unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA IND CHN NGA) ///
        year(2015:2023) addmeta(region income_group) clear
    
    * Keep essential columns
    keep iso3 country region income_group period value lb ub
    
    * Rename for export
    rename value u5mr
    rename lb lower_bound
    rename ub upper_bound
    
    * Sort for presentation
    sort country period
    
    * Export to Excel
    export excel using "unicef_mortality_data.xlsx", ///
        firstrow(variables) replace sheet("U5MR Data")
    
    di as text ""
    di as result "Data exported to unicef_mortality_data.xlsx"
    di as text "Variables: iso3, country, region, income_group, period, u5mr, lower_bound, upper_bound"
end


*  ----------------------------------------------------------------------------
*  Example 07: WASH indicators urban-rural gap
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Standardize → Reshape → Calculate gap
*  ----------------------------------------------------------------------------

capture program drop example07
program example07
    * Download water access data
    unicefdata, indicator(WS_PPL_W-B) sex(ALL) latest clear
    
    * Keep only urban/rural breakdown
    keep if inlist(residence, "U", "R", "URBAN", "RURAL")
    
    * Standardize residence codes
    replace residence = "Urban" if inlist(residence, "U", "URBAN")
    replace residence = "Rural" if inlist(residence, "R", "RURAL")
    
    * Keep countries with both urban and rural data
    bysort iso3 : egen n_res = nvals(residence)
    keep if n_res == 2
    
    * Reshape to calculate gap
    keep iso3 country residence value
    reshape wide value, i(iso3 country) j(residence) string
    
    * Calculate gap
    gen gap = valueUrban - valueRural
    
    * Keep countries with meaningful gaps
    drop if gap == .
    
    * Show top 10 gaps
    gsort -gap
    list iso3 country valueUrban valueRural gap in 1/10, sep(0)
    
    di as text ""
    di as result "Top 10 countries with largest urban-rural gap in basic water access"
end


*  ----------------------------------------------------------------------------
*  Example 08: Using wide option - Time series format
*  Link: help unicefdata > Options > wide
*  Multi-line workflow: Download with wide option → Analyze time trends
*  ----------------------------------------------------------------------------

capture program drop example08
program example08
    * Download data with years as columns using wide option
    unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND CHN) ///
        year(2015:2023) wide clear
    
    * Keep only total values
    keep if sex == "_T"
    
    * Show time series structure
    list iso3 country yr2015 yr2020 yr2023, sep(0) noobs
    
    * Calculate change over time
    gen change_2015_2023 = yr2023 - yr2015
    gen pct_change = (change_2015_2023 / yr2015) * 100
    
    di as text ""
    di as result "Under-5 Mortality Change 2015-2023:"
    list iso3 country yr2015 yr2023 change_2015_2023 pct_change, sep(0) noobs
    
    di as text ""
    di as text "Note: wide option creates yr#### columns automatically"
end


*  ----------------------------------------------------------------------------
*  Example 09: Using wide_indicators - Multiple indicators as columns (v1.5.2)
*  Link: help unicefdata > Options > wide_indicators
*  Multi-line workflow: Download multiple indicators → Automatic column creation
*  NEW in v1.5.2: Creates empty columns even if indicator has no observations
*  ----------------------------------------------------------------------------

capture program drop example09
program example09
    * Download multiple indicators with wide_indicators option
    unicefdata, indicator(CME_MRY0T4 CME_MRY0 IM_DTP3 IM_MCV1) ///
        countries(AFG ETH PAK NGA) latest wide_indicators clear
    
    * Keep only total values
    keep if sex == "_T"
    
    * Show indicators as columns
    describe CME_MRY0T4 CME_MRY0 IM_DTP3 IM_MCV1
    
    di as text ""
    di as result "Multiple indicators downloaded as separate columns:"
    list iso3 country CME_MRY0T4 CME_MRY0 IM_DTP3 IM_MCV1, sep(0) noobs
    
    * Calculate correlation between mortality and immunization
    correlate CME_MRY0T4 IM_DTP3
    
    di as text ""
    di as text "v1.5.2 improvement: All requested indicators create columns even if no data"
    di as text "Use wide_indicators for cross-indicator analysis, correlations, scatter plots"
end


*  ----------------------------------------------------------------------------
*  Example 10: Using wide_attributes - Disaggregations as columns (v1.5.1)
*  Link: help unicefdata > Options > wide_attributes
*  Multi-line workflow: Download with disaggregations → Equity gap analysis
*  ----------------------------------------------------------------------------

capture program drop example10
program example10
    * Download with sex disaggregations using wide_attributes
    unicefdata, indicator(CME_MRY0T4) countries(IND PAK BGD) ///
        year(2020) sex(ALL) wide_attributes clear
    
    * Show disaggregations as column suffixes
    list iso3 country CME_MRY0T4_T CME_MRY0T4_M CME_MRY0T4_F, sep(0) noobs
    
    * Calculate male-female gap
    gen mf_gap = CME_MRY0T4_M - CME_MRY0T4_F
    
    di as text ""
    di as result "Gender gap in under-5 mortality (Male - Female):"
    list iso3 country CME_MRY0T4_M CME_MRY0T4_F mf_gap, sep(0) noobs
    
    di as text ""
    di as text "Note: wide_attributes creates indicator_T, indicator_M, indicator_F columns"
    di as text "Use for gender, wealth, or residence gap analysis"
end


*  ----------------------------------------------------------------------------
*  Example 11: Using attributes() filter - Targeted disaggregation
*  Link: help unicefdata > Options > attributes(string)
*  Multi-line workflow: Filter specific attributes → Compare equity
*  ----------------------------------------------------------------------------

capture program drop example11
program example11
    * Download only specific wealth quintiles using attributes() filter
    unicefdata, indicator(NT_ANT_HAZ_NE2) countries(IND PAK BGD ETH) ///
        latest attributes(_T _Q1 _Q5) wide_attributes clear
    
    * Show total, poorest, and richest only
    list iso3 country NT_ANT_HAZ_NE2_T NT_ANT_HAZ_NE2_Q1 NT_ANT_HAZ_NE2_Q5, ///
        sep(0) noobs
    
    * Calculate wealth gap in stunting
    gen wealth_gap = NT_ANT_HAZ_NE2_Q1 - NT_ANT_HAZ_NE2_Q5
    
    di as text ""
    di as result "Wealth equity gap in child stunting (Poorest Q1 - Richest Q5):"
    list iso3 country NT_ANT_HAZ_NE2_Q1 NT_ANT_HAZ_NE2_Q5 wealth_gap, sep(0) noobs
    
    di as text ""
    di as text "Positive gap = poorest children more stunted (expected)"
    di as text "Use attributes(_T _Q1 _Q5) to download only what you need for equity analysis"
end

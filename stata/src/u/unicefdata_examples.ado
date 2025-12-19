*! -unicefdata_examples-: Auxiliary program for -unicefdata-
*! Version 1.0.0 - 17 December 2025
*! Author: Joao Pedro Azevedo
*! UNICEF

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
*  2. Example 01: Under-5 mortality trend analysis
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
        (connected value period if iso3 == "PAK", lcolor(orange) mcolor(orange)) ///
        (connected value period if iso3 == "NPL", lcolor(purple) mcolor(purple)), ///
            legend(order(1 "Afghanistan" 2 "Bangladesh" 3 "India" 4 "Pakistan" 5 "Nepal") ///
                   rows(1) size(small)) ///
            ytitle("Under-5 mortality rate (per 1,000 live births)") ///
            xtitle("Year") ///
            title("Under-5 Mortality Trends in South Asia") ///
            note("Source: UNICEF Data Warehouse via unicefdata" ///
                 "Azevedo, J.P. (2025) unicefdata: Stata module to access UNICEF databases", size(*.7))
end


*  ----------------------------------------------------------------------------
*  3. Example 02: Stunting by wealth quintile
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
        note("Q1=Poorest, Q5=Richest" ///
             "Source: UNICEF Data Warehouse via unicefdata", size(*.7)) ///
        bar(1, color(navy))
end


*  ----------------------------------------------------------------------------
*  4. Example 03: Multiple indicators comparison
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
    
    * Rename for clarity
    rename valueCME_MRY0T4 u5mr
    rename valueCME_MRY0 imr
    rename valueCME_MRM0 nmr
    
    * Create grouped bar chart
    graph bar u5mr imr nmr, over(country, label(angle(45) labsize(small))) ///
        legend(order(1 "Under-5" 2 "Infant" 3 "Neonatal") rows(1)) ///
        ytitle("Mortality rate (per 1,000 live births)") ///
        title("Child Mortality Indicators in Latin America") ///
        subtitle("Most recent year available") ///
        note("Source: UNICEF Child Mortality Estimates via unicefdata", size(*.7)) ///
        bar(1, color(cranberry)) bar(2, color(navy)) bar(3, color(forest_green))
end


*  ----------------------------------------------------------------------------
*  5. Example 04: Immunization coverage trends
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
            ytitle("Coverage (%)") ///
            xtitle("Year") ///
            title("Global Immunization Coverage Trends") ///
            subtitle("DTP3 and Measles (MCV1) vaccines") ///
            note("Source: UNICEF/WHO Immunization Estimates via unicefdata", size(*.7))
end


*  ----------------------------------------------------------------------------
*  6. Example 05: Regional comparison with metadata
*  ----------------------------------------------------------------------------

capture program drop example05
program example05
    * Download under-5 mortality with regional metadata
    unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) latest clear
    
    * Keep only country-level data (exclude aggregates)
    keep if geo_type == "country"
    
    * Keep only total
    keep if sex == "_T"
    
    * Calculate regional averages
    collapse (mean) avg_u5mr = value (count) n_countries = value, by(region)
    
    * Sort by mortality rate
    gsort -avg_u5mr
    
    * Display results
    list region avg_u5mr n_countries, sep(0) noobs
    
    * Create bar chart
    graph hbar avg_u5mr, over(region, sort(1) descending label(labsize(small))) ///
        ytitle("Under-5 mortality rate (per 1,000)") ///
        title("Under-5 Mortality by UNICEF Region") ///
        subtitle("Latest available year, country averages") ///
        note("Source: UNICEF Data Warehouse via unicefdata", size(*.7)) ///
        bar(1, color(navy))
end


*  ----------------------------------------------------------------------------
*  7. Example 06: Export to Excel with formatting
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
*  8. Example 07: WASH indicators urban-rural gap
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

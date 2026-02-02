*! -unicefdata_examples-: Auxiliary program for -unicefdata-
*! Version 1.7.1 - 01 February 2026  - Fixed examples 07, 09, 10, 11 for robustness
*! Version 1.7.0 - 01 February 2026  - Added verbose option for debugging
*! Version 1.6.0 - 01 February 2026
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
* To run with verbose debugging: unicefdata_examples example01, verbose

*  ----------------------------------------------------------------------------
*  1. Main program
*  ----------------------------------------------------------------------------

capture program drop unicefdata_examples
program unicefdata_examples
    version 14.0
    syntax anything(name=EXAMPLE) [, Verbose]

    set more off

    * Store verbose flag in global for use by examples
    if ("`verbose'" != "") {
        global UNICEF_EXAMPLES_VERBOSE = 1
        di as text ""
        di as text "{hline 70}"
        di as result "VERBOSE MODE: Running `EXAMPLE' with step-by-step debugging"
        di as text "{hline 70}"
        di as text ""
    }
    else {
        global UNICEF_EXAMPLES_VERBOSE = 0
    }

    * Run the example
    `EXAMPLE'

    * Clean up global
    macro drop UNICEF_EXAMPLES_VERBOSE
end


*  ----------------------------------------------------------------------------
*  Helper: Run command with verbose output
*  Usage: _verbose_run "command to execute" ["description"]
*  ----------------------------------------------------------------------------

capture program drop _verbose_run
program _verbose_run
    args cmd desc

    if ($UNICEF_EXAMPLES_VERBOSE == 1) {
        di as text ""
        di as text "{hline 50}"
        if ("`desc'" != "") {
            di as result "STEP: `desc'"
        }
        di as text "COMMAND: " as input `"`cmd'"'
        di as text "{hline 50}"
    }

    * Execute the command
    `cmd'

    if ($UNICEF_EXAMPLES_VERBOSE == 1) {
        * Show data state after command
        quietly count
        local nobs = r(N)
        quietly describe, short
        local nvars = r(k)
        di as text "  -> Result: " as result "`nobs'" as text " observations, " as result "`nvars'" as text " variables"

        * Show variable list if few variables
        if (`nvars' <= 15 & `nvars' > 0) {
            di as text "  -> Variables: " _continue
            foreach v of varlist * {
                di as result "`v' " _continue
            }
            di ""
        }
    }
end


*  ----------------------------------------------------------------------------
*  Helper: Show verbose message
*  Usage: _verbose_msg "message"
*  ----------------------------------------------------------------------------

capture program drop _verbose_msg
program _verbose_msg
    args msg

    if ($UNICEF_EXAMPLES_VERBOSE == 1) {
        di as text "  [DEBUG] `msg'"
    }
end


*  ----------------------------------------------------------------------------
*  Helper: Show current data state
*  Usage: _verbose_state ["label"]
*  ----------------------------------------------------------------------------

capture program drop _verbose_state
program _verbose_state
    args label

    if ($UNICEF_EXAMPLES_VERBOSE == 1) {
        quietly count
        local nobs = r(N)
        quietly describe, short
        local nvars = r(k)

        if ("`label'" != "") {
            di as text "  [STATE after `label'] " _continue
        }
        else {
            di as text "  [STATE] " _continue
        }
        di as result "`nobs'" as text " obs, " as result "`nvars'" as text " vars"

        * Show key variable values if they exist
        capture confirm variable wealth_quintile
        if (_rc == 0) {
            quietly levelsof wealth_quintile, local(wvals) clean
            di as text "    wealth_quintile values: " as result "`wvals'"
        }
        capture confirm variable sex
        if (_rc == 0) {
            quietly levelsof sex, local(svals) clean
            di as text "    sex values: " as result "`svals'"
        }
        capture confirm variable residence
        if (_rc == 0) {
            quietly levelsof residence, local(rvals) clean
            di as text "    residence values: " as result "`rvals'"
        }
    }
end


*  ----------------------------------------------------------------------------
*  Example 01: Under-5 mortality trend analysis
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Graph
*  ----------------------------------------------------------------------------

capture program drop example01
program example01
    _verbose_msg "Starting Example 01: Under-5 mortality trend analysis"

    * Download under-5 mortality data for South Asian countries
    _verbose_msg "Downloading CME_MRY0T4 for South Asian countries"
    unicefdata, indicator(CME_MRY0T4) countries(AFG BGD BTN IND MDV NPL PAK LKA) clear
    _verbose_state "unicefdata"

    * Keep only total (both sexes)
    _verbose_msg "Filtering to keep sex == _T (totals only)"
    capture confirm variable sex
    if (_rc == 0) {
        keep if sex == "_T"
    }
    _verbose_state "filter sex"

    * Create trend graph
    _verbose_msg "Creating trend graph for 4 countries"
    graph twoway ///
        (connected value period if iso3 == "AFG", lcolor(red) mcolor(red)) ///
        (connected value period if iso3 == "BGD", lcolor(blue) mcolor(blue)) ///
        (connected value period if iso3 == "IND", lcolor(green) mcolor(green)) ///
        (connected value period if iso3 == "PAK", lcolor(orange) mcolor(orange)), ///
            legend(order(1 "Afghanistan" 2 "Bangladesh" 3 "India" 4 "Pakistan") rows(1)) ///
            ytitle("Under-5 mortality rate (per 1,000 live births)") xtitle("Year") ///
            title("Under-5 Mortality Trends in South Asia") ///
            note("Source: UNICEF Data Warehouse via unicefdata")

    _verbose_msg "Example 01 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 02: Stunting by wealth quintile
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Create variables → Collapse → Graph
*  ----------------------------------------------------------------------------

capture program drop example02
program example02
    _verbose_msg "Starting Example 02: Stunting by wealth quintile"

    * Download stunting data without any default filters
    * NOTE: nofilter downloads ALL disaggregations, then we filter in Stata
    _verbose_msg "Downloading NT_ANT_HAZ_NE2 with nofilter option"
    unicefdata, indicator(NT_ANT_HAZ_NE2) wealth(ALL) latest clear
    _verbose_state "unicefdata"

    * Keep observations with wealth quintile data (Q1-Q5 only)
    _verbose_msg "Filtering to keep only Q1-Q5 wealth quintiles"
    keep if inlist(wealth_quintile, "Q1", "Q2", "Q3", "Q4", "Q5", "_T")
    _verbose_state "keep Q1-Q5"

    * Create numeric wealth variable
    _verbose_msg "Creating numeric wealth_num variable"
    gen wealth_num = real(substr(wealth_quintile, 2, 1))

    * Calculate mean stunting by wealth quintile
    _verbose_msg "Collapsing to calculate mean stunting by wealth quintile"
    collapse (mean) mean_stunting = value, by(wealth_quintile wealth_num)
    _verbose_state "collapse"

    * Create bar chart
    _verbose_msg "Creating bar chart"
    graph bar mean_stunting, over(wealth_quintile, label(labsize(small))) ///
        ytitle("Stunting prevalence (%)") ///
        title("Child Stunting by Wealth Quintile") ///
        subtitle("Country Average, latest available year") ///
        note("Q1=Poorest, Q5=Richest. Source: UNICEF Data Warehouse via unicefdata", size(*.7)) ///
        bar(1, color(navy))

    _verbose_msg "Example 02 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 03: Multiple indicators comparison
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Keep latest → Reshape → Graph
*  ----------------------------------------------------------------------------

capture program drop example03
program example03
    _verbose_msg "Starting Example 03: Multiple indicators comparison"

    * Download multiple CME indicators for comparison
    _verbose_msg "Downloading CME_MRY0T4, CME_MRY0, CME_MRM0 for Latin American countries"
    unicefdata, indicator(CME_MRY0T4 CME_MRY0 CME_MRM0) ///
        countries(BRA MEX ARG COL PER CHL) year(2020:2023) clear
    _verbose_state "unicefdata"

    * Keep only total values
    _verbose_msg "Filtering to keep sex == _T (totals only)"
    capture confirm variable sex
    if (_rc == 0) {
        keep if sex == "_T"
    }
    _verbose_state "filter sex"

    * Keep latest year per country-indicator
    _verbose_msg "Keeping latest year per country-indicator combination"
    bysort iso3 indicator (period): keep if _n == _N
    _verbose_state "keep latest"

    * Reshape to wide format
    _verbose_msg "Reshaping to wide format"
    keep iso3 country indicator value
    reshape wide value, i(iso3 country) j(indicator) string
    _verbose_state "reshape"

    * Create grouped bar chart
    _verbose_msg "Creating grouped bar chart"
    graph bar valueCME_MRY0T4 valueCME_MRY0 valueCME_MRM0, ///
        over(country, label(angle(45) labsize(small))) ///
        legend(order(1 "Under-5" 2 "Infant" 3 "Neonatal") rows(1)) ///
        ytitle("Mortality rate (per 1,000 live births)") ///
        title("Child Mortality Indicators in Latin America") ///
        subtitle("Most recent year available") ///
        note("Source: UNICEF Child Mortality Estimates via unicefdata", size(*.7))

    _verbose_msg "Example 03 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 04: Immunization coverage trends
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Collapse → Reshape → Graph
*  ----------------------------------------------------------------------------

capture program drop example04
program example04
    _verbose_msg "Starting Example 04: Immunization coverage trends"

    * Download DTP3 and MCV1 immunization data
    * Note: IMMUNISATION dataflow does NOT have sex disaggregation
    _verbose_msg "Downloading IM_DTP3 and IM_MCV1 (no sex filter - dataflow doesn't support it)"
    unicefdata, indicator(IM_DTP3 IM_MCV1) year(2000:2023) clear
    _verbose_state "unicefdata"

    * Calculate global average by year and indicator
    _verbose_msg "Collapsing to calculate mean coverage by period and indicator"
    collapse (mean) coverage = value, by(period indicator)
    _verbose_state "collapse"

    * Reshape for graphing
    _verbose_msg "Reshaping from long to wide format"
    reshape wide coverage, i(period) j(indicator) string
    rename coverageIM_DTP3 dtp3
    rename coverageIM_MCV1 mcv1
    _verbose_state "reshape"

    * Create trend comparison
    _verbose_msg "Creating trend graph"
    graph twoway ///
        (line dtp3 period, lcolor(blue) lwidth(medium)) ///
        (line mcv1 period, lcolor(red) lwidth(medium)), ///
            legend(order(1 "DTP3" 2 "MCV1") rows(1)) ///
            ytitle("Coverage (%)") xtitle("Year") ///
            title("Global Immunization Coverage Trends") ///
            subtitle("DTP3 and Measles (MCV1) vaccines") ///
            note("Source: UNICEF/WHO Immunization Estimates via unicefdata", size(*.7))

    _verbose_msg "Example 04 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 05: Regional comparison with metadata
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Collapse → Sort → Graph
*  ----------------------------------------------------------------------------

capture program drop example05
program example05
    _verbose_msg "Starting Example 05: Regional comparison with metadata"

    * Download under-5 mortality with regional metadata
    _verbose_msg "Downloading CME_MRY0T4 with addmeta(region income_group)"
    unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) latest clear
    _verbose_state "unicefdata"

    * Keep only country-level data (exclude aggregates)
    * geo_type == 0 means country-level data
    _verbose_msg "Filtering: geo_type == 0 (countries only) & sex == _T (totals)"

    * Check variable types before filtering
    capture confirm numeric variable geo_type
    if (_rc != 0) {
        _verbose_msg "WARNING: geo_type is not numeric, converting..."
        destring geo_type, replace force
    }

    * Filter for country-level totals
    capture confirm variable sex
    if (_rc == 0) {
        keep if geo_type == 0 & sex == "_T"
    }
    else {
        _verbose_msg "NOTE: sex variable not found, filtering by geo_type only"
        keep if geo_type == 0
    }
    _verbose_state "filter countries"

    * Drop observations with missing region
    _verbose_msg "Dropping observations with missing region"
    drop if region == "" | missing(region)
    _verbose_state "drop missing region"

    * Calculate regional averages
    _verbose_msg "Calculating regional averages"
    collapse (mean) avg_u5mr = value, by(region)
    _verbose_state "collapse"

    * Sort by mortality rate
    gsort -avg_u5mr

    * Create bar chart
    _verbose_msg "Creating horizontal bar chart"
    graph hbar avg_u5mr, over(region, sort(1) descending label(labsize(small))) ///
        ytitle("Under-5 mortality rate (per 1,000)") ///
        title("Under-5 Mortality by UNICEF Region") ///
        subtitle("Latest available year, country averages") ///
        note("Source: UNICEF Data Warehouse via unicefdata", size(*.7)) ///
        bar(1, color(navy))

    _verbose_msg "Example 05 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 06: Export to Excel with formatting
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Select columns → Rename → Export
*  ----------------------------------------------------------------------------

capture program drop example06
program example06
    _verbose_msg "Starting Example 06: Export to Excel with formatting"

    * Download comprehensive data
    _verbose_msg "Downloading CME_MRY0T4 for selected countries with metadata"
    unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA IND CHN NGA) ///
        year(2015:2023) addmeta(region income_group) clear
    _verbose_state "unicefdata"

    * Build list of variables to keep (only those that exist)
    _verbose_msg "Selecting columns for export"
    local keepvars ""
    foreach v in iso3 country region income_group period value lower_bound upper_bound {
        capture confirm variable `v'
        if (_rc == 0) {
            local keepvars "`keepvars' `v'"
        }
        else {
            _verbose_msg "NOTE: Variable `v' not found, skipping"
        }
    }

    * Keep essential columns
    if ("`keepvars'" != "") {
        keep `keepvars'
    }
    _verbose_state "keep columns"

    * Rename for export (only if value exists)
    capture confirm variable value
    if (_rc == 0) {
        rename value u5mr
    }

    * Sort for presentation
    sort country period

    * Export to Excel
    _verbose_msg "Exporting to Excel"
    export excel using "unicef_mortality_data.xlsx", ///
        firstrow(variables) replace sheet("U5MR Data")

    di as text ""
    di as result "Data exported to unicef_mortality_data.xlsx"
    di as text "Variables exported: `keepvars'"

    _verbose_msg "Example 06 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 07: WASH indicators urban-rural gap
*  Link: help unicefdata > Advanced Examples
*  Multi-line workflow: Download → Filter → Standardize → Reshape → Calculate gap
*  ----------------------------------------------------------------------------

capture program drop example07
program example07
    _verbose_msg "Starting Example 07: WASH indicators urban-rural gap"

    * Download water access data with nofilter to get all disaggregations
    * NOTE: Using nofilter + manual filtering because residence(ALL) + latest
    * may not return both Urban and Rural for the same year/country
    _verbose_msg "Downloading WS_PPL_W-B with nofilter option"
    unicefdata, indicator(WS_PPL_W-B) nofilter clear
    _verbose_state "unicefdata"

    * Keep recent data only (post-2015)
    _verbose_msg "Filtering to keep period >= 2015"
    keep if period >= 2015
    _verbose_state "filter period"

    * Keep only urban/rural breakdown
    _verbose_msg "Filtering to Urban (U) and Rural (R) only"
    keep if inlist(residence, "U", "R")
    _verbose_state "filter residence"

    * Keep latest year per country-residence combination
    _verbose_msg "Keeping latest year per country-residence"
    bysort iso3 residence (period): keep if _n == _N
    _verbose_state "keep latest per residence"

    * Standardize residence codes (U=Urban, R=Rural in the data)
    _verbose_msg "Standardizing residence codes"
    replace residence = "Urban" if residence == "U"
    replace residence = "Rural" if residence == "R"

    * Keep countries with both urban and rural data
    * Note: Using tag method instead of nvals() which requires egenmore package
    _verbose_msg "Keeping countries with both urban and rural data"
    bysort iso3 residence: gen _first = (_n == 1)
    bysort iso3: egen n_res = total(_first)
    drop _first
    keep if n_res == 2
    _verbose_state "filter both U/R"

    * Reshape to calculate gap
    _verbose_msg "Reshaping to wide format"
    keep iso3 country residence value
    reshape wide value, i(iso3 country) j(residence) string
    _verbose_state "reshape"

    * Calculate gap
    _verbose_msg "Calculating urban-rural gap"
    gen gap = valueUrban - valueRural

    * Keep countries with meaningful gaps
    drop if gap == .
    _verbose_state "drop missing"

    * Show top 10 gaps
    gsort -gap
    list iso3 country valueUrban valueRural gap in 1/10, sep(0)

    di as text ""
    di as result "Top 10 countries with largest urban-rural gap in basic water access"

    _verbose_msg "Example 07 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 08: Using wide option - Time series format
*  Link: help unicefdata > Options > wide
*  Multi-line workflow: Download with wide option → Analyze time trends
*  ----------------------------------------------------------------------------

capture program drop example08
program example08
    _verbose_msg "Starting Example 08: Using wide option - Time series format"

    * Download data with years as columns using wide option
    _verbose_msg "Downloading CME_MRY0T4 with wide option (years as columns)"
    unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND CHN) ///
        year(2015:2023) wide clear
    _verbose_state "unicefdata wide"

    * Keep only total values
    _verbose_msg "Filtering to sex == _T"
    capture confirm variable sex
    if (_rc == 0) {
        keep if sex == "_T"
    }
    _verbose_state "filter sex"

    * Show time series structure
    _verbose_msg "Displaying time series structure"
    list iso3 country yr2015 yr2020 yr2023, sep(0) noobs

    * Calculate change over time
    _verbose_msg "Calculating change over time"
    gen change_2015_2023 = yr2023 - yr2015
    gen pct_change = (change_2015_2023 / yr2015) * 100

    di as text ""
    di as result "Under-5 Mortality Change 2015-2023:"
    list iso3 country yr2015 yr2023 change_2015_2023 pct_change, sep(0) noobs

    di as text ""
    di as text "Note: wide option creates yr#### columns automatically"

    _verbose_msg "Example 08 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 09: Using wide_indicators - Multiple indicators as columns (v1.5.2)
*  Link: help unicefdata > Options > wide_indicators
*  Multi-line workflow: Download multiple indicators → Automatic column creation
*  NEW in v1.5.2: Creates empty columns even if indicator has no observations
*  ----------------------------------------------------------------------------

capture program drop example09
program example09
    _verbose_msg "Starting Example 09: Using wide_indicators"

    * Download multiple CME indicators with wide_indicators option
    * Note: Mixing indicators from different dataflows may create separate rows
    _verbose_msg "Downloading CME indicators with wide_indicators option"
    unicefdata, indicator(CME_MRY0T4 CME_MRY0 CME_MRM0) ///
        countries(AFG ETH PAK NGA BGD IND) wide_indicators clear
    _verbose_state "unicefdata wide_indicators"

    * Keep only total values (if sex variable exists)
    _verbose_msg "Filtering to sex == _T (if variable exists)"
    capture confirm variable sex
    if (_rc == 0) {
        keep if sex == "_T"
    }
    _verbose_state "filter sex"

    * Show indicators as columns
    _verbose_msg "Describing indicator columns"
    capture describe CME_MRY0T4 CME_MRY0 CME_MRM0

    di as text ""
    di as result "Multiple CME indicators downloaded as separate columns:"
    capture noisily list iso3 country CME_MRY0T4 CME_MRY0 CME_MRM0, sep(0) noobs

    * Calculate correlation between mortality indicators
    _verbose_msg "Calculating correlation between mortality indicators"
    capture noisily correlate CME_MRY0T4 CME_MRY0 CME_MRM0

    di as text ""
    di as text "Note: wide_indicators works best with indicators from the same dataflow"
    di as text "Use wide_indicators for cross-indicator analysis within a dataflow"

    _verbose_msg "Example 09 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 10: Using wide_attributes - Disaggregations as columns (v1.5.1)
*  Link: help unicefdata > Options > wide_attributes
*  Multi-line workflow: Download with disaggregations → Equity gap analysis
*  ----------------------------------------------------------------------------

capture program drop example10
program example10
    _verbose_msg "Starting Example 10: Sex disaggregation analysis"

    * Download with sex disaggregations - standard long format approach
    * Note: wide_attributes may not work as expected in all versions
    _verbose_msg "Downloading CME_MRY0T4 with sex(ALL) for disaggregation analysis"
    unicefdata, indicator(CME_MRY0T4) countries(IND PAK BGD) ///
        year(2020) sex(ALL) clear
    _verbose_state "unicefdata"

    * Show available sex values
    _verbose_msg "Displaying available sex disaggregations"
    tab sex

    * Keep only total and sex-specific values
    keep if inlist(sex, "_T", "M", "F")
    _verbose_state "filter sex values"

    * Reshape to wide format for gap analysis
    _verbose_msg "Reshaping to wide format for gap analysis"
    keep iso3 country sex value
    reshape wide value, i(iso3 country) j(sex) string
    _verbose_state "reshape wide"

    * Calculate male-female gap (if both exist)
    _verbose_msg "Calculating male-female gap"
    capture gen mf_gap = valueM - valueF

    di as text ""
    di as result "Gender gap in under-5 mortality (Male - Female):"
    capture noisily list iso3 country valueM valueF mf_gap, sep(0) noobs

    di as text ""
    di as text "Note: Males typically have higher under-5 mortality than females"
    di as text "Use sex(ALL) to download all sex disaggregations for equity analysis"

    _verbose_msg "Example 10 completed successfully"
end


*  ----------------------------------------------------------------------------
*  Example 11: Using attributes() filter - Targeted disaggregation
*  Link: help unicefdata > Options > attributes(string)
*  Multi-line workflow: Filter specific attributes → Compare equity
*  ----------------------------------------------------------------------------

capture program drop example11
program example11
    _verbose_msg "Starting Example 11: Wealth equity gap analysis"

    * Download stunting data with nofilter to get all disaggregations
    * NOTE: Using nofilter because wealth(ALL) + latest may not return
    * both Q1 and Q5 for the same year/country due to data availability
    _verbose_msg "Downloading NT_ANT_HAZ_NE2 with nofilter option"
    unicefdata, indicator(NT_ANT_HAZ_NE2) countries(IND PAK BGD ETH) nofilter clear
    _verbose_state "unicefdata"

    * Keep recent data only (post-2015)
    _verbose_msg "Filtering to keep period >= 2015"
    keep if period >= 2015
    _verbose_state "filter period"

    * Show available wealth quintile values
    _verbose_msg "Displaying available wealth quintiles"
    tab wealth_quintile

    * Keep only Q1 (poorest) and Q5 (richest) for gap analysis
    _verbose_msg "Filtering to Q1 and Q5 for equity gap"
    keep if inlist(wealth_quintile, "Q1", "Q5")
    _verbose_state "filter Q1 Q5"

    * Keep latest year per country-wealth_quintile combination
    _verbose_msg "Keeping latest year per country-quintile"
    bysort iso3 wealth_quintile (period): keep if _n == _N
    _verbose_state "keep latest per quintile"

    * Keep countries with both Q1 and Q5 data
    _verbose_msg "Keeping countries with both Q1 and Q5 data"
    bysort iso3 wealth_quintile: gen _first = (_n == 1)
    bysort iso3: egen n_quint = total(_first)
    drop _first
    keep if n_quint == 2
    _verbose_state "filter both Q1/Q5"

    * Reshape to wide format for gap analysis
    _verbose_msg "Reshaping to wide format"
    keep iso3 country wealth_quintile value
    reshape wide value, i(iso3 country) j(wealth_quintile) string
    _verbose_state "reshape wide"

    * Calculate wealth gap in stunting
    _verbose_msg "Calculating wealth equity gap"
    capture gen wealth_gap = valueQ1 - valueQ5

    di as text ""
    di as result "Wealth equity gap in child stunting (Poorest Q1 - Richest Q5):"
    capture noisily list iso3 country valueQ1 valueQ5 wealth_gap, sep(0) noobs

    di as text ""
    di as text "Positive gap = poorest children have higher stunting (expected)"
    di as text "Use wealth(ALL) with reshape for equity analysis"

    _verbose_msg "Example 11 completed successfully"
end

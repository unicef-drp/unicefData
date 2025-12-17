*******************************************************************************
* unicefdata
*! v 1.3.1   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* Download indicators from UNICEF Data Warehouse via SDMX API
* Aligned with R get_unicef() and Python unicef_api
* Uses YAML metadata for dataflow detection and validation
*
* NEW in v1.3.1: categories subcommand, dataflow() filter in search
* NEW in v1.3.0: Discovery subcommands (flows, search, indicators, info)
*******************************************************************************

program define unicefdata, rclass

    version 14.0

    *---------------------------------------------------------------------------
    * Check for discovery subcommands FIRST (before regular syntax parsing)
    *---------------------------------------------------------------------------
    
    * Check for CATEGORIES subcommand (list categories with counts)
    if (strpos("`0'", "categor") > 0) {
        * Support both "categories" and "category"
        local has_verbose = (strpos("`0'", "verbose") > 0)
        _unicef_list_categories `=cond(`has_verbose', ", verbose", "")'
        exit
    }
    
    * Check for FLOWS subcommand
    if (strpos("`0'", "flows") > 0) {
        * Parse options (detail, verbose)
        local has_detail = (strpos("`0'", "detail") > 0)
        local has_verbose = (strpos("`0'", "verbose") > 0)
        
        if (`has_detail') {
            _unicef_list_dataflows, detail `=cond(`has_verbose', "verbose", "")'
        }
        else {
            _unicef_list_dataflows `=cond(`has_verbose', ", verbose", "")'
        }
        exit
    }
    
    * Check for SEARCH subcommand
    if (strpos("`0'", "search(") > 0) {
        * Extract search keyword
        local search_start = strpos("`0'", "search(") + 7
        local search_end = strpos(substr("`0'", `search_start', .), ")") + `search_start' - 2
        local search_keyword = substr("`0'", `search_start', `search_end' - `search_start' + 1)
        
        * Extract other options
        local remaining = subinstr("`0'", "search(`search_keyword')", "", 1)
        local remaining = subinstr("`remaining'", ",", "", 1)
        
        * Check for limit option
        local limit_val = 20
        if (strpos("`remaining'", "limit(") > 0) {
            local limit_start = strpos("`remaining'", "limit(") + 6
            local limit_end = strpos(substr("`remaining'", `limit_start', .), ")") + `limit_start' - 2
            local limit_val = substr("`remaining'", `limit_start', `limit_end' - `limit_start' + 1)
        }
        
        * Check for dataflow filter option
        local dataflow_filter = ""
        if (strpos("`remaining'", "dataflow(") > 0) {
            local df_start = strpos("`remaining'", "dataflow(") + 9
            local df_end = strpos(substr("`remaining'", `df_start', .), ")") + `df_start' - 2
            local dataflow_filter = substr("`remaining'", `df_start', `df_end' - `df_start' + 1)
        }
        
        if ("`dataflow_filter'" != "") {
            _unicef_search_indicators, keyword("`search_keyword'") limit(`limit_val') dataflow("`dataflow_filter'")
        }
        else {
            _unicef_search_indicators, keyword("`search_keyword'") limit(`limit_val')
        }
        exit
    }
    
    * Check for INDICATORS subcommand (list indicators in a dataflow)
    if (strpos("`0'", "indicators(") > 0) {
        * Extract dataflow
        local ind_start = strpos("`0'", "indicators(") + 11
        local ind_end = strpos(substr("`0'", `ind_start', .), ")") + `ind_start' - 2
        local ind_dataflow = substr("`0'", `ind_start', `ind_end' - `ind_start' + 1)
        
        * Check for verbose option
        local has_verbose = (strpos("`0'", "verbose") > 0)
        
        _unicef_list_indicators, dataflow("`ind_dataflow'") `=cond(`has_verbose', "verbose", "")'
        exit
    }
    
    * Check for INFO subcommand (get indicator details)
    if (strpos("`0'", "info(") > 0) {
        * Extract indicator code
        local info_start = strpos("`0'", "info(") + 5
        local info_end = strpos(substr("`0'", `info_start', .), ")") + `info_start' - 2
        local info_indicator = substr("`0'", `info_start', `info_end' - `info_start' + 1)
        
        _unicef_indicator_info, indicator("`info_indicator'")
        exit
    }

    *---------------------------------------------------------------------------
    * Regular syntax for data retrieval
    *---------------------------------------------------------------------------

    syntax                                          ///
                 [,                                 ///
                        INDICATOR(string)           /// Indicator code(s)
                        DATAFLOW(string)            /// SDMX dataflow ID
                        COUNTries(string)           /// ISO3 country codes
                        YEAR(string)                /// Year(s): single, range (2015:2023), or list (2015,2018,2020)
                        CIRCA                       /// Find closest available year
                        SEX(string)                 /// Sex: _T, F, M, ALL
                        AGE(string)                 /// Age group filter
                        WEALTH(string)              /// Wealth quintile filter
                        RESIDENCE(string)           /// Residence: URBAN, RURAL
                        MATERNAL_edu(string)        /// Maternal education filter
                        LONG                        /// Long format (default)
                        WIDE                        /// Wide format
                        WIDE_indicators             /// Wide format with indicators as columns
                        LATEST                      /// Most recent value only
                        MRV(integer 0)              /// N most recent values
                        DROPNA                      /// Drop missing values
                        SIMPLIFY                    /// Essential columns only
                        RAW                         /// Raw SDMX output
                        ADDmeta(string)             /// Add metadata columns (region, income_group)
                        VERSION(string)             /// SDMX version
                        PAGE_size(integer 100000)   /// Rows per request
                        MAX_retries(integer 3)      /// Retry attempts
                        CLEAR                       /// Replace data in memory
                        VERBOSE                     /// Show progress
                        VALIDATE                    /// Validate inputs against codelists
                        FALLBACK                    /// Try alternative dataflows on 404
                        NOFallback                  /// Disable dataflow fallback
                        *                           /// Legacy options
                 ]

    quietly {

        *-----------------------------------------------------------------------
        * Validate inputs
        *-----------------------------------------------------------------------
        
        if ("`indicator'" == "") & ("`dataflow'" == "") {
            noi di as err "You must specify either indicator() or dataflow()."
            noi di as text ""
            noi di as text "Discovery commands:"
            noi di as text "  unicefdata, categories                - List categories with indicator counts"
            noi di as text "  unicefdata, flows                     - List available dataflows"
            noi di as text "  unicefdata, search(mortality)         - Search indicators by keyword"
            noi di as text "  unicefdata, search(edu) dataflow(EDUCATION) - Search within a dataflow"
            noi di as text "  unicefdata, indicators(CME)           - List indicators in a dataflow"
            noi di as text "  unicefdata, info(CME_MRY0T4)          - Get indicator details"
            noi di as text ""
            noi di as text "Data retrieval:"
            noi di as text "  unicefdata, indicator(CME_MRY0T4) countries(BRA USA)"
            exit 198
        }
        
        if ("`clear'" == "") {
            if (_N > 0) {
                noi di as err "You must start with an empty dataset; or enable the clear option."
                exit 4
            }
        }
        
        *-----------------------------------------------------------------------
        * Set defaults
        *-----------------------------------------------------------------------
        
        if ("`sex'" == "") {
            local sex "_T"
        }
        
        if ("`version'" == "") {
            local version "1.0"
        }
        
        local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
        
        *-----------------------------------------------------------------------
        * Parse year parameter
        *-----------------------------------------------------------------------
        * Supports: single (2020), range (2015:2023), list (2015,2018,2020)
        
        local start_year = 0
        local end_year = 0
        local year_list ""
        local has_year_list = 0
        
        if ("`year'" != "") {
            * Check for range format: 2015:2023
            if (strpos("`year'", ":") > 0) {
                local colon_pos = strpos("`year'", ":")
                local start_year = real(substr("`year'", 1, `colon_pos' - 1))
                local end_year = real(substr("`year'", `colon_pos' + 1, .))
                if ("`verbose'" != "") {
                    noi di as text "Year range: " as result "`start_year' to `end_year'"
                }
            }
            * Check for list format: 2015,2018,2020
            else if (strpos("`year'", ",") > 0) {
                local year_list = subinstr("`year'", ",", " ", .)
                local has_year_list = 1
                * Get min and max for API query
                local min_year = 9999
                local max_year = 0
                foreach yr of local year_list {
                    if (`yr' < `min_year') local min_year = `yr'
                    if (`yr' > `max_year') local max_year = `yr'
                }
                local start_year = `min_year'
                local end_year = `max_year'
                if ("`verbose'" != "") {
                    noi di as text "Year list: " as result "`year_list'"
                    noi di as text "Query range: " as result "`start_year' to `end_year'"
                }
            }
            * Single year
            else {
                local start_year = real("`year'")
                local end_year = `start_year'
                if ("`verbose'" != "") {
                    noi di as text "Single year: " as result "`start_year'"
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Locate metadata directory (YAML files in src/_/ alongside helper ado)
        *-----------------------------------------------------------------------
        
        * Find the helper programs location (src/_/)
        local metadata_path ""
        
        * Try to find metadata relative to helper ado files in src/_/
        capture findfile _unicef_list_dataflows.ado
        if (_rc == 0) {
            local ado_path "`r(fn)'"
            * Extract directory containing the helper ado file
            local ado_dir = subinstr("`ado_path'", "\", "/", .)
            local ado_dir = subinstr("`ado_dir'", "_unicef_list_dataflows.ado", "", .)
            local metadata_path "`ado_dir'"
        }
        
        * Fallback to PLUS directory _/
        if ("`metadata_path'" == "") | (!fileexists("`metadata_path'_unicefdata_indicators.yaml")) {
            local metadata_path "`c(sysdir_plus)'_/"
        }
        
        if ("`verbose'" != "") {
            noi di as text "Metadata path: " as result "`metadata_path'"
        }
        
        *-----------------------------------------------------------------------
        * Auto-detect dataflow from indicator using YAML metadata
        *-----------------------------------------------------------------------
        
        * Check for multiple indicators (space-separated)
        local n_indicators : word count `indicator'
        
        if (`n_indicators' > 1) {
            * Multiple indicators: fetch each separately and append
            * (This matches Python/R behavior where each indicator is fetched individually)
            
            if ("`verbose'" != "") {
                noi di as text "Multiple indicators detected (`n_indicators'). Fetching each separately..."
            }
            
            tempfile combined_data
            local first_indicator = 1
            
            foreach ind of local indicator {
                if ("`verbose'" != "") {
                    noi di as text "  Fetching indicator: " as result "`ind'"
                }
                
                * Detect dataflow for this indicator
                _unicef_detect_dataflow_yaml "`ind'" "`metadata_path'"
                local ind_dataflow "`s(dataflow)'"
                
                * Build URL for this indicator
                local ind_key ".`ind'."
                local ind_rel_path "data/UNICEF,`ind_dataflow',`version'/`ind_key'"
                
                local ind_query "format=csv&labels=both"
                if (`start_year' > 0) {
                    local ind_query "`ind_query'&startPeriod=`start_year'"
                }
                if (`end_year' > 0) {
                    local ind_query "`ind_query'&endPeriod=`end_year'"
                }
                local ind_query "`ind_query'&startIndex=0&count=`page_size'"
                
                local ind_url "`base_url'/`ind_rel_path'?`ind_query'"
                
                * Try to fetch this indicator
                tempfile ind_tempdata
                local ind_success 0
                forvalues attempt = 1/`max_retries' {
                    capture copy "`ind_url'" "`ind_tempdata'", replace public
                    if (_rc == 0) {
                        local ind_success 1
                        continue, break
                    }
                    sleep 1000
                }
                
                * Try fallback if primary failed
                if (`ind_success' == 0) {
                    _unicef_fetch_with_fallback, indicator("`ind'") ///
                        dataflow("`ind_dataflow'") ///
                        base_url("`base_url'") ///
                        version("`version'") ///
                        start_year("`start_year'") ///
                        end_year("`end_year'") ///
                        page_size(`page_size') ///
                        max_retries(`max_retries') ///
                        `verbose'
                    
                    if ("`r(success)'" == "1") {
                        local ind_success 1
                        * Data is now in memory from fallback helper
                        * Convert types for safe appending
                        capture confirm variable time_period
                        if (_rc == 0) {
                            capture confirm string variable time_period
                            if (_rc != 0) {
                                tostring time_period, replace force
                            }
                        }
                        capture confirm variable obs_value
                        if (_rc == 0) {
                            capture confirm string variable obs_value
                            if (_rc != 0) {
                                tostring obs_value, replace force
                            }
                        }
                        
                        if (`first_indicator' == 1) {
                            save "`combined_data'", replace
                            local first_indicator = 0
                        }
                        else {
                            append using "`combined_data'", force
                            save "`combined_data'", replace
                        }
                        continue
                    }
                }
                
                if (`ind_success' == 1) {
                    * Import the data
                    preserve
                    import delimited using "`ind_tempdata'", clear varnames(1) encoding("utf-8")
                    
                    if (_N > 0) {
                        * Convert time_period to string to avoid type mismatch when appending
                        capture confirm variable time_period
                        if (_rc == 0) {
                            capture confirm string variable time_period
                            if (_rc != 0) {
                                tostring time_period, replace force
                            }
                        }
                        
                        * Convert obs_value to string initially for safe appending
                        capture confirm variable obs_value
                        if (_rc == 0) {
                            capture confirm string variable obs_value
                            if (_rc != 0) {
                                tostring obs_value, replace force
                            }
                        }
                        
                        if (`first_indicator' == 1) {
                            save "`combined_data'", replace
                            local first_indicator = 0
                        }
                        else {
                            append using "`combined_data'", force
                            save "`combined_data'", replace
                        }
                    }
                    restore
                }
                else {
                    if ("`verbose'" != "") {
                        noi di as text "  Warning: Could not fetch `ind'" as error " (skipped)"
                    }
                }
            }
            
            * Load combined data
            if (`first_indicator' == 0) {
                use "`combined_data'", clear
            }
            else {
                noi di as err "Could not fetch data for any of the specified indicators."
                exit 677
            }
            
            * Skip the single-indicator fetch logic below
            local skip_single_fetch 1
        }
        else {
            * Single indicator - use normal flow
            local skip_single_fetch 0
            
            if ("`dataflow'" == "") & ("`indicator'" != "") {
                _unicef_detect_dataflow_yaml "`indicator'" "`metadata_path'"
                local dataflow "`s(dataflow)'"
                local indicator_name "`s(indicator_name)'"
                if ("`verbose'" != "") {
                    noi di as text "Auto-detected dataflow: " as result "`dataflow'"
                    if ("`indicator_name'" != "") {
                        noi di as text "Indicator: " as result "`indicator_name'"
                    }
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Validate disaggregation filters against codelists (if requested)
        *-----------------------------------------------------------------------
        
        if ("`validate'" != "") {
            _unicef_validate_filters "`sex'" "`age'" "`wealth'" "`residence'" "`maternal_edu'" "`metadata_path'"
        }
        
        *-----------------------------------------------------------------------
        * Build the API query URL (single indicator only)
        *-----------------------------------------------------------------------
        
        if (`skip_single_fetch' == 0) {
        
        * Base path: data/UNICEF,{dataflow},{version}/{indicator_key}
        local indicator_key = cond("`indicator'" != "", "." + "`indicator'" + ".", ".")
        local rel_path "data/UNICEF,`dataflow',`version'/`indicator_key'"
        
        * Query parameters
        local query_params "format=csv&labels=both"
        
        if (`start_year' > 0) {
            local query_params "`query_params'&startPeriod=`start_year'"
        }
        
        if (`end_year' > 0) {
            local query_params "`query_params'&endPeriod=`end_year'"
        }
        
        local query_params "`query_params'&startIndex=0&count=`page_size'"
        
        * Full URL
        local full_url "`base_url'/`rel_path'?`query_params'"
        
        if ("`verbose'" != "") {
            noi di as text "Fetching from: " as result "`full_url'"
        }
        
        *-----------------------------------------------------------------------
        * Download data (with optional fallback)
        *-----------------------------------------------------------------------
        
        set checksum off
        
        tempfile tempdata
        
        * Determine if we should use fallback
        local use_fallback = ("`fallback'" != "" | ("`nofallback'" == "" & "`indicator'" != ""))
        
        * Try to copy the file with retries
        local success 0
        forvalues attempt = 1/`max_retries' {
            capture copy "`full_url'" "`tempdata'", replace public
            if (_rc == 0) {
                local success 1
                continue, break
            }
            if ("`verbose'" != "") {
                noi di as text "Attempt `attempt' failed. Retrying..."
            }
            sleep 1000
        }
        
        * If primary download failed and fallback is enabled, try alternatives
        if (`success' == 0 & `use_fallback' == 1 & "`indicator'" != "") {
            if ("`verbose'" != "") {
                noi di as text "Primary dataflow failed, trying alternatives..."
            }
            
            _unicef_fetch_with_fallback, indicator("`indicator'") ///
                dataflow("`dataflow'") ///
                base_url("`base_url'") ///
                version("`version'") ///
                start_year("`start_year'") ///
                end_year("`end_year'") ///
                page_size(`page_size') ///
                max_retries(`max_retries') ///
                `verbose'
            
            if ("`r(success)'" == "1") {
                local success 1
                local dataflow "`r(dataflow)'"
                local full_url "`r(url)'"
                if ("`verbose'" != "") {
                    noi di as text "Successfully used fallback dataflow: " as result "`dataflow'"
                }
            }
        }
        
        if (`success' == 0) {
            noi di ""
            noi di as err "{p 4 4 2}Could not download data from UNICEF SDMX API.{p_end}"
            noi di as text `"{p 4 4 2}(1) Please check your internet connection by {browse "https://data.unicef.org/" :clicking here}.{p_end}"'
            noi di as text `"{p 4 4 2}(2) Please check if the indicator code is correct.{p_end}"'
            noi di as text `"{p 4 4 2}(3) Please check your firewall settings.{p_end}"'
            noi di as text `"{p 4 4 2}(4) Consider adjusting Stata timeout: {help netio}.{p_end}"'
            if ("`indicator'" != "" & "`nofallback'" == "") {
                noi di as text `"{p 4 4 2}(5) Try specifying a different dataflow().{p_end}"'
            }
            exit 677
        }
        
        *-----------------------------------------------------------------------
        * Import the CSV data (if not already loaded by fallback)
        *-----------------------------------------------------------------------
        
        * Check if data is already loaded (from fallback helper)
        if (_N == 0) {
            import delimited using "`tempdata'", `clear' varnames(1) encoding("utf-8")
        }
        
        } // end skip_single_fetch
        
        local obs_count = _N
        if ("`verbose'" != "") {
            noi di as text "Downloaded " as result `obs_count' as text " observations."
        }
        
        if (`obs_count' == 0) {
            noi di as text "No data found for the specified query."
            exit 0
        }
        
        *-----------------------------------------------------------------------
        * Rename and standardize variables
        * (Aligned with R get_unicef() and Python unicef_api)
        * Using short names with descriptive variable labels
        *-----------------------------------------------------------------------
        
        if ("`raw'" == "") {
            
            * Rename core columns to standardized short names
            * Note: import delimited converts column names to lowercase
            capture rename ref_area iso3
            capture rename indicator indicator
            capture rename time_period period
            capture rename obs_value value
            capture rename geographicarea country
            
            * Rename descriptive columns (from API's "label" columns)
            * API returns pairs like INDICATOR/Indicator - Stata creates v4, v6 for duplicates
            capture rename v4 indicator_name
            capture rename unitofmeasure unit_name
            capture rename v6 sex_name
            capture rename wealthquintile wealth_name
            capture rename observationstatus status_name
            
            * Rename additional metadata columns (lowercase after import delimited)
            capture rename unit_measure unit
            capture rename wealth_quintile wealth
            capture rename lower_bound lb
            capture rename upper_bound ub
            capture rename obs_status status
            capture rename data_source source
            capture rename ref_period refper
            capture rename country_notes notes
            capture rename maternal_edu_lvl matedu
            
            * Add descriptive variable labels
            capture label variable iso3       "ISO3 country code"
            capture label variable country    "Country name"
            capture label variable indicator  "Indicator code"
            capture label variable indicator_name "Indicator name"
            capture label variable period     "Time period (year)"
            capture label variable value      "Observation value"
            capture label variable unit       "Unit of measure code"
            capture label variable unit_name  "Unit of measure"
            capture label variable sex        "Sex code"
            capture label variable sex_name   "Sex"
            capture label variable age        "Age group"
            capture label variable wealth     "Wealth quintile code"
            capture label variable wealth_name "Wealth quintile"
            capture label variable residence  "Residence type"
            capture label variable matedu     "Maternal education level"
            capture label variable lb         "Lower confidence bound"
            capture label variable ub         "Upper confidence bound"
            capture label variable status     "Observation status code"
            capture label variable status_name "Observation status"
            capture label variable source     "Data source"
            capture label variable refper     "Reference period"
            capture label variable notes      "Country notes"
            
            * Convert period to numeric (handle YYYY-MM format)
            capture {
                * Check if period contains "-" (YYYY-MM format)
                gen _has_month = strpos(period, "-") > 0
                gen _year = real(substr(period, 1, 4))
                gen _month = real(substr(period, 6, 2)) if _has_month == 1
                replace _month = 0 if _has_month == 0
                gen period_num = _year + _month/12
                drop period _has_month _year _month
                rename period_num period
                label variable period "Time period (year)"
            }
            
            * If the above fails, try simple numeric conversion
            capture {
                destring period, replace force
            }
            
            * Convert value to numeric
            capture {
                destring value, replace force
            }
            
            * Convert bounds to numeric
            capture destring lb, replace force
            capture destring ub, replace force
            
            * Filter by sex if specified
            if ("`sex'" != "" & "`sex'" != "ALL") {
                capture confirm variable sex
                if (_rc == 0) {
                    keep if sex == "`sex'"
                }
            }
            
            * Filter by age if specified
            if ("`age'" != "" & "`age'" != "ALL") {
                capture confirm variable age
                if (_rc == 0) {
                    keep if age == "`age'"
                }
            }
            
            * Filter by wealth quintile if specified
            if ("`wealth'" != "" & "`wealth'" != "ALL") {
                capture confirm variable wealth
                if (_rc == 0) {
                    keep if wealth == "`wealth'"
                }
            }
            
            * Filter by residence if specified
            if ("`residence'" != "" & "`residence'" != "ALL") {
                capture confirm variable residence
                if (_rc == 0) {
                    keep if residence == "`residence'"
                }
            }
            
            * Filter by maternal education if specified
            if ("`maternal_edu'" != "" & "`maternal_edu'" != "ALL") {
                capture confirm variable matedu
                if (_rc == 0) {
                    keep if matedu == "`maternal_edu'"
                }
            }
            
        }
        
        *-----------------------------------------------------------------------
        * Filter countries if specified
        *-----------------------------------------------------------------------
        
        if ("`countries'" != "") {
            capture confirm variable iso3
            if (_rc == 0) {
                local countries_upper = upper("`countries'")
                local countries_clean = subinstr("`countries_upper'", ",", " ", .)
                gen _keep = 0
                foreach c of local countries_clean {
                    replace _keep = 1 if iso3 == "`c'"
                }
                keep if _keep == 1
                drop _keep
            }
        }
        
        *-----------------------------------------------------------------------
        * Apply year list filter (non-contiguous years)
        *-----------------------------------------------------------------------
        
        if (`has_year_list' == 1) {
            capture confirm variable period
            if (_rc == 0) {
                if ("`circa'" != "") {
                    * Circa mode: find closest year for each country
                    * For each target year, find closest available period per country(-indicator)
                    
                    if ("`verbose'" != "") {
                        noi di as text "Applying circa matching for years: " as result "`year_list'"
                    }
                    
                    tempfile orig_data
                    save "`orig_data'", replace
                    
                    * Drop missing values before finding closest
                    capture confirm variable value
                    if (_rc == 0) {
                        drop if missing(value)
                    }
                    
                    * Generate group id
                    capture confirm variable indicator
                    local has_indicator = (_rc == 0)
                    
                    tempfile closest_results
                    local first_target = 1
                    
                    foreach target of local year_list {
                        use "`orig_data'", clear
                        capture confirm variable value
                        if (_rc == 0) {
                            drop if missing(value)
                        }
                        
                        * Calculate distance from target
                        gen double _dist = abs(period - `target')
                        
                        if (`has_indicator') {
                            bysort iso3 indicator (_dist): keep if _n == 1
                        }
                        else {
                            bysort iso3 (_dist): keep if _n == 1
                        }
                        
                        gen _target_year = `target'
                        drop _dist
                        
                        if (`first_target' == 1) {
                            save "`closest_results'", replace
                            local first_target = 0
                        }
                        else {
                            append using "`closest_results'"
                            save "`closest_results'", replace
                        }
                    }
                    
                    * Remove duplicates (same obs closest to multiple targets)
                    use "`closest_results'", clear
                    if (`has_indicator') {
                        duplicates drop iso3 indicator period, force
                    }
                    else {
                        duplicates drop iso3 period, force
                    }
                    drop _target_year
                }
                else {
                    * Strict filter: keep only exact matches
                    gen _keep_year = 0
                    foreach yr of local year_list {
                        replace _keep_year = 1 if period == `yr'
                    }
                    keep if _keep_year == 1
                    drop _keep_year
                    
                    if ("`verbose'" != "") {
                        noi di as text "Filtered to years: " as result "`year_list'"
                    }
                }
            }
        }
        else if ("`circa'" != "" & `start_year' > 0) {
            * Circa mode with single year or range (find closest to endpoints)
            capture confirm variable period
            if (_rc == 0) {
                if (`start_year' == `end_year') {
                    * Single year circa
                    local target_years "`start_year'"
                }
                else {
                    * Range circa - use start and end as targets
                    local target_years "`start_year' `end_year'"
                }
                
                if ("`verbose'" != "") {
                    noi di as text "Applying circa matching for: " as result "`target_years'"
                }
                
                tempfile orig_data
                save "`orig_data'", replace
                
                capture confirm variable value
                if (_rc == 0) {
                    drop if missing(value)
                }
                
                capture confirm variable indicator
                local has_indicator = (_rc == 0)
                
                tempfile closest_results
                local first_target = 1
                
                foreach target of local target_years {
                    use "`orig_data'", clear
                    capture confirm variable value
                    if (_rc == 0) {
                        drop if missing(value)
                    }
                    
                    gen double _dist = abs(period - `target')
                    
                    if (`has_indicator') {
                        bysort iso3 indicator (_dist): keep if _n == 1
                    }
                    else {
                        bysort iso3 (_dist): keep if _n == 1
                    }
                    
                    gen _target_year = `target'
                    drop _dist
                    
                    if (`first_target' == 1) {
                        save "`closest_results'", replace
                        local first_target = 0
                    }
                    else {
                        append using "`closest_results'"
                        save "`closest_results'", replace
                    }
                }
                
                use "`closest_results'", clear
                if (`has_indicator') {
                    duplicates drop iso3 indicator period, force
                }
                else {
                    duplicates drop iso3 period, force
                }
                drop _target_year
            }
        }
        
        *-----------------------------------------------------------------------
        * Apply latest value filter
        *-----------------------------------------------------------------------
        
        if ("`latest'" != "") {
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable value
            if (_rc == 0) {
                * Keep only non-missing values
                drop if missing(value)
                
                * Get latest period for each country-indicator
                capture confirm variable indicator
                if (_rc == 0) {
                    bysort iso3 indicator (period): keep if _n == _N
                }
                else {
                    bysort iso3 (period): keep if _n == _N
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Apply MRV (Most Recent Values) filter
        *-----------------------------------------------------------------------
        
        if (`mrv' > 0) {
            capture confirm variable iso3
            capture confirm variable period
            if (_rc == 0) {
                capture confirm variable indicator
                if (_rc == 0) {
                    gsort iso3 indicator -period
                    by iso3 indicator: gen _rank = _n
                    keep if _rank <= `mrv'
                    drop _rank
                    sort iso3 indicator period
                }
                else {
                    gsort iso3 -period
                    by iso3: gen _rank = _n
                    keep if _rank <= `mrv'
                    drop _rank
                    sort iso3 period
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Apply dropna filter (aligned with R/Python)
        *-----------------------------------------------------------------------
        
        if ("`dropna'" != "") {
            capture confirm variable value
            if (_rc == 0) {
                drop if missing(value)
            }
        }
        
        *-----------------------------------------------------------------------
        * Add metadata columns (region, income_group) - NEW in v1.3.0
        *-----------------------------------------------------------------------
        
        if ("`addmeta'" != "") {
            * Parse requested metadata columns
            local addmeta_lower = lower("`addmeta'")
            
            capture confirm variable iso3
            if (_rc == 0) {
                * Add region
                if (strpos("`addmeta_lower'", "region") > 0) {
                    _unicef_add_region
                }
                
                * Add income group
                if (strpos("`addmeta_lower'", "income") > 0) {
                    _unicef_add_income_group
                }
                
                * Add continent
                if (strpos("`addmeta_lower'", "continent") > 0) {
                    _unicef_add_continent
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Add geo_type classification (country vs aggregate) - NEW in v1.3.0
        *-----------------------------------------------------------------------
        
        capture confirm variable iso3
        if (_rc == 0) {
            capture drop geo_type
            gen geo_type = ""
            * Mark known aggregates (regional and global)
            replace geo_type = "aggregate" if inlist(iso3, "WLD", "WORLD", "UNICEF", "WB")
            replace geo_type = "aggregate" if length(iso3) > 3
            replace geo_type = "aggregate" if strpos(iso3, "_") > 0
            replace geo_type = "country" if geo_type == ""
            label variable geo_type "Geographic type (country/aggregate)"
        }
        
        *-----------------------------------------------------------------------
        * Format output (long/wide/wide_indicators) - aligned with R/Python
        *-----------------------------------------------------------------------
        
        if ("`wide_indicators'" != "") {
            * NEW: Reshape with indicators as columns (like Python wide_indicators)
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable indicator
            capture confirm variable value
            if (_rc == 0) {
                * First, collapse to handle duplicate disaggregations
                * Keep only the total/aggregate values where possible
                capture confirm variable sex
                if (_rc == 0) {
                    keep if sex == "_T" | sex == "TOTAL" | sex == ""
                }
                capture confirm variable age
                if (_rc == 0) {
                    keep if age == "_T" | age == "TOTAL" | age == "" | age == "Y0T4" | age == "Y0T17"
                }
                capture confirm variable wealth
                if (_rc == 0) {
                    keep if wealth == "_T" | wealth == "TOTAL" | wealth == ""
                }
                
                * Keep columns needed for reshape
                local keep_vars "iso3 country period indicator value"
                if ("`addmeta'" != "") {
                    foreach v in region income_group continent geo_type {
                        capture confirm variable `v'
                        if (_rc == 0) local keep_vars "`keep_vars' `v'"
                    }
                }
                keep `keep_vars'
                
                * Drop duplicates to ensure unique combinations
                duplicates drop iso3 country period indicator, force
                
                * Reshape: indicators become columns
                capture reshape wide value, i(iso3 country period) j(indicator) string
                if (_rc == 0) {
                    * Clean up column names (remove "value" prefix)
                    foreach v of varlist value* {
                        local newname = subinstr("`v'", "value", "", 1)
                        rename `v' `newname'
                    }
                    sort iso3 period
                    
                    if ("`verbose'" != "") {
                        noi di as text "Reshaped to wide_indicators format."
                    }
                }
                else {
                    noi di as text "Note: Could not reshape to wide_indicators format (may have duplicate observations)."
                }
            }
        }
        else if ("`wide'" != "") {
            * Reshape to wide format (years as columns)
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable indicator
            capture confirm variable value
            if (_rc == 0) {
                keep iso3 country period indicator value
                capture reshape wide value, i(iso3 country period) j(indicator) string
                if (_rc != 0) {
                    noi di as text "Note: Could not reshape to wide format."
                }
            }
        }
        else {
            * Data is already in long format from SDMX CSV (default)
            sort iso3 period
        }
        
        *-----------------------------------------------------------------------
        * Simplify output (aligned with R/Python) - keep essential columns only
        *-----------------------------------------------------------------------
        
        if ("`simplify'" != "") {
            * Keep only essential columns like R's simplify option
            local keepvars ""
            foreach v in iso3 country indicator period value lb ub {
                capture confirm variable `v'
                if (_rc == 0) {
                    local keepvars "`keepvars' `v'"
                }
            }
            * Also keep metadata if added
            foreach v in region income_group continent geo_type {
                capture confirm variable `v'
                if (_rc == 0) {
                    local keepvars "`keepvars' `v'"
                }
            }
            if ("`keepvars'" != "") {
                keep `keepvars'
            }
        }
        
        *-----------------------------------------------------------------------
        * Return values
        *-----------------------------------------------------------------------
        
        return local indicator "`indicator'"
        return local dataflow "`dataflow'"
        return local countries "`countries'"
        return local start_year "`start_year'"
        return local end_year "`end_year'"
        return local wide "`wide'"
        return local wide_indicators "`wide_indicators'"
        return local addmeta "`addmeta'"
        return local obs_count = _N
        return local url "`full_url'"
        
        if ("`verbose'" != "") {
            noi di ""
            noi di as text "Successfully loaded " as result _N as text " observations."
            noi di as text "Indicator: " as result "`indicator'"
            noi di as text "Dataflow:  " as result "`dataflow'"
        }
        
    }

end


*******************************************************************************
* Helper program: Add region metadata
*******************************************************************************

program define _unicef_add_region
    * UNICEF regions mapping (simplified - can be expanded)
    gen region = ""
    
    * East Asia and Pacific
    replace region = "East Asia and Pacific" if inlist(iso3, "AUS", "BRN", "KHM", "CHN", "FJI")
    replace region = "East Asia and Pacific" if inlist(iso3, "IDN", "JPN", "KOR", "LAO", "MYS")
    replace region = "East Asia and Pacific" if inlist(iso3, "MNG", "MMR", "NZL", "PNG", "PHL")
    replace region = "East Asia and Pacific" if inlist(iso3, "SGP", "THA", "TLS", "VNM")
    
    * Europe and Central Asia
    replace region = "Europe and Central Asia" if inlist(iso3, "ALB", "ARM", "AZE", "BLR", "BIH")
    replace region = "Europe and Central Asia" if inlist(iso3, "BGR", "HRV", "CZE", "EST", "GEO")
    replace region = "Europe and Central Asia" if inlist(iso3, "HUN", "KAZ", "KGZ", "LVA", "LTU")
    replace region = "Europe and Central Asia" if inlist(iso3, "MDA", "MNE", "MKD", "POL", "ROU")
    replace region = "Europe and Central Asia" if inlist(iso3, "RUS", "SRB", "SVK", "SVN", "TJK")
    replace region = "Europe and Central Asia" if inlist(iso3, "TUR", "TKM", "UKR", "UZB")
    
    * Latin America and Caribbean
    replace region = "Latin America and Caribbean" if inlist(iso3, "ARG", "BLZ", "BOL", "BRA", "CHL")
    replace region = "Latin America and Caribbean" if inlist(iso3, "COL", "CRI", "CUB", "DOM", "ECU")
    replace region = "Latin America and Caribbean" if inlist(iso3, "SLV", "GTM", "GUY", "HTI", "HND")
    replace region = "Latin America and Caribbean" if inlist(iso3, "JAM", "MEX", "NIC", "PAN", "PRY")
    replace region = "Latin America and Caribbean" if inlist(iso3, "PER", "SUR", "TTO", "URY", "VEN")
    
    * Middle East and North Africa
    replace region = "Middle East and North Africa" if inlist(iso3, "DZA", "BHR", "EGY", "IRN", "IRQ")
    replace region = "Middle East and North Africa" if inlist(iso3, "ISR", "JOR", "KWT", "LBN", "LBY")
    replace region = "Middle East and North Africa" if inlist(iso3, "MAR", "OMN", "PSE", "QAT", "SAU")
    replace region = "Middle East and North Africa" if inlist(iso3, "SYR", "TUN", "ARE", "YEM")
    
    * South Asia
    replace region = "South Asia" if inlist(iso3, "AFG", "BGD", "BTN", "IND", "MDV")
    replace region = "South Asia" if inlist(iso3, "NPL", "PAK", "LKA")
    
    * Sub-Saharan Africa
    replace region = "Sub-Saharan Africa" if inlist(iso3, "AGO", "BEN", "BWA", "BFA", "BDI")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "CMR", "CPV", "CAF", "TCD", "COM")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "COD", "COG", "CIV", "DJI", "GNQ")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "ERI", "SWZ", "ETH", "GAB", "GMB")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "GHA", "GIN", "GNB", "KEN", "LSO")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "LBR", "MDG", "MWI", "MLI", "MRT")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "MUS", "MOZ", "NAM", "NER", "NGA")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "RWA", "STP", "SEN", "SYC", "SLE")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "SOM", "ZAF", "SSD", "SDN", "TZA")
    replace region = "Sub-Saharan Africa" if inlist(iso3, "TGO", "UGA", "ZMB", "ZWE")
    
    * North America
    replace region = "North America" if inlist(iso3, "CAN", "USA")
    
    * Western Europe
    replace region = "Western Europe" if inlist(iso3, "AUT", "BEL", "DNK", "FIN", "FRA")
    replace region = "Western Europe" if inlist(iso3, "DEU", "GRC", "ISL", "IRL", "ITA")
    replace region = "Western Europe" if inlist(iso3, "LUX", "NLD", "NOR", "PRT", "ESP")
    replace region = "Western Europe" if inlist(iso3, "SWE", "CHE", "GBR")
    
    * Mark remaining as Unknown
    replace region = "Unknown" if region == ""
    
    label variable region "UNICEF Region"
end


*******************************************************************************
* Helper program: Add income group metadata
*******************************************************************************

program define _unicef_add_income_group
    * World Bank income groups (2023 classification, simplified)
    gen income_group = ""
    
    * High Income
    replace income_group = "High income" if inlist(iso3, "AUS", "AUT", "BEL", "CAN", "CHE")
    replace income_group = "High income" if inlist(iso3, "CHL", "CZE", "DEU", "DNK", "ESP")
    replace income_group = "High income" if inlist(iso3, "EST", "FIN", "FRA", "GBR", "GRC")
    replace income_group = "High income" if inlist(iso3, "HRV", "HUN", "IRL", "ISL", "ISR")
    replace income_group = "High income" if inlist(iso3, "ITA", "JPN", "KOR", "KWT", "LTU")
    replace income_group = "High income" if inlist(iso3, "LUX", "LVA", "NLD", "NOR", "NZL")
    replace income_group = "High income" if inlist(iso3, "POL", "PRT", "QAT", "SAU", "SGP")
    replace income_group = "High income" if inlist(iso3, "SVK", "SVN", "SWE", "TTO", "ARE")
    replace income_group = "High income" if inlist(iso3, "URY", "USA")
    
    * Upper-Middle Income
    replace income_group = "Upper middle income" if inlist(iso3, "ALB", "ARG", "ARM", "AZE", "BGR")
    replace income_group = "Upper middle income" if inlist(iso3, "BIH", "BLR", "BRA", "BWA", "CHN")
    replace income_group = "Upper middle income" if inlist(iso3, "COL", "CRI", "CUB", "DOM", "ECU")
    replace income_group = "Upper middle income" if inlist(iso3, "GEO", "GTM", "IDN", "IRN", "IRQ")
    replace income_group = "Upper middle income" if inlist(iso3, "JAM", "JOR", "KAZ", "LBN", "LBY")
    replace income_group = "Upper middle income" if inlist(iso3, "MEX", "MKD", "MNE", "MYS", "NAM")
    replace income_group = "Upper middle income" if inlist(iso3, "PER", "PRY", "ROU", "RUS", "SRB")
    replace income_group = "Upper middle income" if inlist(iso3, "THA", "TUR", "TKM", "ZAF")
    
    * Lower-Middle Income
    replace income_group = "Lower middle income" if inlist(iso3, "AGO", "BGD", "BEN", "BTN", "BOL")
    replace income_group = "Lower middle income" if inlist(iso3, "CMR", "CIV", "COG", "DJI", "EGY")
    replace income_group = "Lower middle income" if inlist(iso3, "GHA", "HND", "IND", "KEN", "KGZ")
    replace income_group = "Lower middle income" if inlist(iso3, "KHM", "LAO", "LKA", "MAR", "MDA")
    replace income_group = "Lower middle income" if inlist(iso3, "MMR", "MNG", "MRT", "NGA", "NIC")
    replace income_group = "Lower middle income" if inlist(iso3, "NPL", "PAK", "PHL", "PNG", "PSE")
    replace income_group = "Lower middle income" if inlist(iso3, "SEN", "SLV", "TJK", "TLS", "TUN")
    replace income_group = "Lower middle income" if inlist(iso3, "TZA", "UKR", "UZB", "VNM", "ZMB")
    replace income_group = "Lower middle income" if inlist(iso3, "ZWE")
    
    * Low Income
    replace income_group = "Low income" if inlist(iso3, "AFG", "BDI", "BFA", "CAF", "TCD")
    replace income_group = "Low income" if inlist(iso3, "COD", "ERI", "ETH", "GMB", "GIN")
    replace income_group = "Low income" if inlist(iso3, "GNB", "HTI", "LBR", "MDG", "MLI")
    replace income_group = "Low income" if inlist(iso3, "MOZ", "MWI", "NER", "RWA", "SLE")
    replace income_group = "Low income" if inlist(iso3, "SOM", "SSD", "SDN", "SYR", "TGO")
    replace income_group = "Low income" if inlist(iso3, "UGA", "YEM")
    
    * Mark remaining as Unknown
    replace income_group = "Unknown" if income_group == ""
    
    label variable income_group "World Bank Income Group"
end


*******************************************************************************
* Helper program: Add continent metadata
*******************************************************************************

program define _unicef_add_continent
    gen continent = ""
    
    * Africa
    replace continent = "Africa" if inlist(iso3, "DZA", "AGO", "BEN", "BWA", "BFA")
    replace continent = "Africa" if inlist(iso3, "BDI", "CMR", "CPV", "CAF", "TCD")
    replace continent = "Africa" if inlist(iso3, "COM", "COD", "COG", "CIV", "DJI")
    replace continent = "Africa" if inlist(iso3, "EGY", "GNQ", "ERI", "SWZ", "ETH")
    replace continent = "Africa" if inlist(iso3, "GAB", "GMB", "GHA", "GIN", "GNB")
    replace continent = "Africa" if inlist(iso3, "KEN", "LSO", "LBR", "LBY", "MDG")
    replace continent = "Africa" if inlist(iso3, "MWI", "MLI", "MRT", "MUS", "MAR")
    replace continent = "Africa" if inlist(iso3, "MOZ", "NAM", "NER", "NGA", "RWA")
    replace continent = "Africa" if inlist(iso3, "STP", "SEN", "SYC", "SLE", "SOM")
    replace continent = "Africa" if inlist(iso3, "ZAF", "SSD", "SDN", "TZA", "TGO")
    replace continent = "Africa" if inlist(iso3, "TUN", "UGA", "ZMB", "ZWE")
    
    * Asia
    replace continent = "Asia" if inlist(iso3, "AFG", "ARM", "AZE", "BHR", "BGD")
    replace continent = "Asia" if inlist(iso3, "BTN", "BRN", "KHM", "CHN", "CYP")
    replace continent = "Asia" if inlist(iso3, "GEO", "IND", "IDN", "IRN", "IRQ")
    replace continent = "Asia" if inlist(iso3, "ISR", "JPN", "JOR", "KAZ", "KWT")
    replace continent = "Asia" if inlist(iso3, "KGZ", "LAO", "LBN", "MYS", "MDV")
    replace continent = "Asia" if inlist(iso3, "MNG", "MMR", "NPL", "OMN", "PAK")
    replace continent = "Asia" if inlist(iso3, "PSE", "PHL", "QAT", "SAU", "SGP")
    replace continent = "Asia" if inlist(iso3, "KOR", "LKA", "SYR", "TWN", "TJK")
    replace continent = "Asia" if inlist(iso3, "THA", "TLS", "TUR", "TKM", "ARE")
    replace continent = "Asia" if inlist(iso3, "UZB", "VNM", "YEM")
    
    * Europe
    replace continent = "Europe" if inlist(iso3, "ALB", "AND", "AUT", "BLR", "BEL")
    replace continent = "Europe" if inlist(iso3, "BIH", "BGR", "HRV", "CZE", "DNK")
    replace continent = "Europe" if inlist(iso3, "EST", "FIN", "FRA", "DEU", "GRC")
    replace continent = "Europe" if inlist(iso3, "HUN", "ISL", "IRL", "ITA", "LVA")
    replace continent = "Europe" if inlist(iso3, "LTU", "LUX", "MDA", "MCO", "MNE")
    replace continent = "Europe" if inlist(iso3, "NLD", "MKD", "NOR", "POL", "PRT")
    replace continent = "Europe" if inlist(iso3, "ROU", "RUS", "SMR", "SRB", "SVK")
    replace continent = "Europe" if inlist(iso3, "SVN", "ESP", "SWE", "CHE", "UKR")
    replace continent = "Europe" if inlist(iso3, "GBR")
    
    * North America
    replace continent = "North America" if inlist(iso3, "CAN", "USA", "MEX", "GTM", "BLZ")
    replace continent = "North America" if inlist(iso3, "HND", "SLV", "NIC", "CRI", "PAN")
    replace continent = "North America" if inlist(iso3, "CUB", "DOM", "HTI", "JAM", "TTO")
    
    * South America
    replace continent = "South America" if inlist(iso3, "ARG", "BOL", "BRA", "CHL", "COL")
    replace continent = "South America" if inlist(iso3, "ECU", "GUY", "PRY", "PER", "SUR")
    replace continent = "South America" if inlist(iso3, "URY", "VEN")
    
    * Oceania
    replace continent = "Oceania" if inlist(iso3, "AUS", "FJI", "NZL", "PNG", "SLB")
    replace continent = "Oceania" if inlist(iso3, "VUT", "WSM", "TON")
    
    * Mark remaining as Unknown
    replace continent = "Unknown" if continent == ""
    
    label variable continent "Continent"
end


*******************************************************************************
* Helper program: Auto-detect dataflow from indicator code using YAML metadata
*******************************************************************************

program define _unicef_detect_dataflow_yaml, sclass
    args indicator metadata_path
    
    local dataflow ""
    local indicator_name ""
    
    * Try to load from YAML metadata first (files have _unicefdata_ prefix)
    local yaml_file "`metadata_path'_unicefdata_indicators.yaml"
    
    capture confirm file "`yaml_file'"
    if (_rc == 0) {
        * YAML file exists - try to read it using yaml command
        capture which yaml
        if (_rc == 0) {
            * yaml command is available
            preserve
            capture {
                yaml read "`yaml_file'", into(indicators_meta) clear
                
                * Look for indicator in the indicators mapping
                local indicator_clean = subinstr("`indicator'", "-", "_", .)
                
                * Try to get dataflow from YAML
                capture local dataflow = indicators_meta["indicators"]["`indicator'"]["dataflow"]
                capture local indicator_name = indicators_meta["indicators"]["`indicator'"]["name"]
            }
            restore
            
            if ("`dataflow'" != "") {
                sreturn local dataflow "`dataflow'"
                sreturn local indicator_name "`indicator_name'"
                exit
            }
        }
    }
    
    * Fallback to prefix-based detection if YAML not available or indicator not found
    _unicef_detect_dataflow_prefix "`indicator'"
    sreturn local dataflow "`s(dataflow)'"
    sreturn local indicator_name ""
    
end


*******************************************************************************
* Helper program: Fallback prefix-based dataflow detection
*******************************************************************************

program define _unicef_detect_dataflow_prefix, sclass
    args indicator
    
    * Extract prefix from indicator (first part before underscore)
    local prefix = word(subinstr("`indicator'", "_", " ", 1), 1)
    
    * Known indicator-to-dataflow mappings (aligned with R/Python)
    if ("`prefix'" == "CME") {
        sreturn local dataflow "CME"
    }
    else if ("`prefix'" == "NT") {
        sreturn local dataflow "NUTRITION"
    }
    else if ("`prefix'" == "IM") {
        sreturn local dataflow "IMMUNISATION"
    }
    else if inlist("`prefix'", "ED", "EDUNF") {
        sreturn local dataflow "EDUCATION"
    }
    else if ("`prefix'" == "WS") {
        sreturn local dataflow "WASH_HOUSEHOLDS"
    }
    else if ("`prefix'" == "HVA") {
        sreturn local dataflow "HIV_AIDS"
    }
    else if ("`prefix'" == "MNCH") {
        sreturn local dataflow "MNCH"
    }
    else if ("`prefix'" == "PT") {
        sreturn local dataflow "PT"
    }
    else if ("`prefix'" == "ECD") {
        sreturn local dataflow "ECD"
    }
    else if ("`prefix'" == "PV") {
        sreturn local dataflow "CHLD_PVTY"
    }
    else if ("`prefix'" == "CCRI") {
        sreturn local dataflow "CCRI"
    }
    else if ("`prefix'" == "SDG") {
        sreturn local dataflow "CHILD_RELATED_SDG"
    }
    else {
        * Default to GLOBAL_DATAFLOW if unknown
        sreturn local dataflow "GLOBAL_DATAFLOW"
    }
    
end


*******************************************************************************
* Helper program: Validate disaggregation filters against YAML codelists
*******************************************************************************

program define _unicef_validate_filters, sclass
    args sex age wealth residence maternal_edu metadata_path
    
    local yaml_file "`metadata_path'_unicefdata_codelists.yaml"
    local warnings ""
    
    capture confirm file "`yaml_file'"
    if (_rc != 0) {
        * YAML file not found - skip validation
        exit
    }
    
    capture which yaml
    if (_rc != 0) {
        * yaml command not available - skip validation
        exit
    }
    
    * Validate sex
    if ("`sex'" != "" & "`sex'" != "ALL") {
        if !inlist("`sex'", "_T", "F", "M") {
            noi di as text "Warning: sex value '`sex'' may not be valid. Expected: _T, F, M"
        }
    }
    
    * Validate wealth
    if ("`wealth'" != "" & "`wealth'" != "ALL") {
        if !inlist("`wealth'", "_T", "Q1", "Q2", "Q3", "Q4", "Q5") {
            noi di as text "Warning: wealth value '`wealth'' may not be valid. Expected: _T, Q1-Q5"
        }
    }
    
    * Validate residence
    if ("`residence'" != "" & "`residence'" != "ALL") {
        if !inlist("`residence'", "_T", "U", "R", "URBAN", "RURAL") {
            noi di as text "Warning: residence value '`residence'' may not be valid. Expected: _T, U, R"
        }
    }
    
end


*******************************************************************************
* Helper program: Legacy fallback (deprecated, kept for compatibility)
*******************************************************************************

program define _unicef_detect_dataflow, sclass
    args indicator
    
    * Call the new prefix-based detection
    _unicef_detect_dataflow_prefix "`indicator'"
    sreturn local dataflow "`s(dataflow)'"
    
end


*******************************************************************************
* Version history
*******************************************************************************
* v 1.3.1   17Dec2025   by Joao Pedro Azevedo
*   Feature parity improvements (aligned with Python/R list_categories)
*   - NEW: categories subcommand: unicefdata, categories
*         Lists all indicator categories (dataflows) with indicator counts
*   - NEW: dataflow() filter in search: unicefdata, search(edu) dataflow(EDUCATION)
*         Filter search results by dataflow/category
*   - Improved search results display with tips
*
* v 1.3.0   09Dec2025   by Joao Pedro Azevedo
*   Cross-language parity improvements (aligned with Python unicef_api v0.3.0)
*   - NEW: Discovery subcommands:
*       unicefdata, flows              - List available dataflows
*       unicefdata, search(keyword)    - Search indicators by keyword
*       unicefdata, indicators(CME)    - List indicators in a dataflow
*       unicefdata, info(CME_MRY0T4)   - Get indicator details
*   - NEW: wide_indicators option for reshaping with indicators as columns
*   - NEW: addmeta(region income_group continent) option
*   - NEW: geo_type variable (country vs aggregate classification)
*   - Improved error messages with usage hints
*
* v 1.2.0   04Dec2025   by Joao Pedro Azevedo
*   YAML-based metadata loading (aligned with R/Python)
*   - Added stata/metadata/*.yaml files for indicators, codelists, dataflows
*   - Auto-detect dataflow from YAML indicators.yaml
*   - Added validate option for codelist validation
*   - Uses yaml.ado for metadata parsing (with prefix fallback)
*
* v 1.1.0   04Dec2025   by Joao Pedro Azevedo
*   API alignment with R get_unicef() and Python unicef_api
*   - Renamed options: start_year, end_year, max_retries, page_size
*   - Added long/wide options for output format
*   - Added dropna option to drop missing values
*   - Added simplify option to keep essential columns only
*   - Backward compatible with legacy option syntax
*
* v 1.0.0   03Dec2025   by Joao Pedro Azevedo
*   Initial release
*   - Download UNICEF SDMX data via API
*   - Support for indicator and dataflow selection
*   - Country filtering
*   - Year range filtering
*   - Disaggregation filters (sex, age, wealth, residence, maternal education)
*   - Latest value and MRV options
*   - Auto-detect dataflow from indicator prefix
*******************************************************************************

*! v 1.5.2   06Jan2026               by Joao Pedro Azevedo (UNICEF)
cap program drop unicefdata
program define unicefdata, rclass
version 11
* Download indicators from UNICEF Data Warehouse via SDMX API
* Aligned with R get_unicef() and Python unicef_api
* Uses YAML metadata for dataflow detection and validation
*
* NEW in v1.5.2: 
* - Enhanced wide_indicators: now creates empty columns for all requested indicators
*   (prevents reshape failures when some indicators have zero observations)
* - Network robustness: curl with User-Agent header (better SSL/proxy/retry support)
* - Cross-platform consistency improvements
*
* NEW in v1.5.1: CI test improvements (offline YAML-based tests)
    
    * Check for FLOWS subcommand (list available dataflows)
    if (strpos("`0'", "flows") > 0) {
        local has_detail = (strpos("`0'", "detail") > 0)
        local has_verbose = (strpos("`0'", "verbose") > 0)
        if (`has_detail') {
            _unicef_list_dataflows, detail `=cond(`has_verbose', "verbose", "")'
        }
        else {
            _unicef_list_dataflows `=cond(`has_verbose', "verbose", "")'
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
        
        * Check if verbose option was specified
        local verbose_opt ""
        if (strpos(lower("`0'"), "verbose") > 0) {
            local verbose_opt "verbose"
        }
        
        _unicef_indicator_info, indicator("`info_indicator'") `verbose_opt'
        exit
    }
    
    * Check for DATAFLOW INFO subcommand (get dataflow schema details)
    * Accept both "dataflow(X)" and "dataflows(X)" syntax
    local has_df_param = (strpos("`0'", ", dataflow(") > 0 | strpos("`0'", ", dataflows(") > 0)
    if (`has_df_param' & strpos("`0'", "indicator") == 0 & strpos("`0'", "search") == 0) {
        * Extract dataflow code - this is for "unicefdata, dataflow(X)" without indicator()
        * Handle both dataflow( and dataflows( syntax
        local df_start = strpos("`0'", "dataflow(") + 9
        if (strpos("`0'", "dataflows(") > 0) {
            local df_start = strpos("`0'", "dataflows(") + 10
        }
        local df_end = strpos(substr("`0'", `df_start', .), ")") + `df_start' - 2
        local df_code = substr("`0'", `df_start', `df_end' - `df_start' + 1)
        
        * Check if this looks like a discovery command (no countries, no indicator)
        * If countries are present, it's a data retrieval command, not discovery
        if (strpos("`0'", "countr") == 0) {
            * Check if verbose option was specified
            local verbose_opt ""
            if (strpos(lower("`0'"), "verbose") > 0) {
                local verbose_opt "verbose"
            }
            
            _unicef_dataflow_info, dataflow("`df_code'") `verbose_opt'
            
            * Pass through return values
            return add
            exit
        }
    }
    
    * Check for SYNC subcommand (route to unicefdata_sync)
    if (strpos("`0'", "sync") > 0) {
        * Parse sync options: sync(all), sync(indicators), sync(dataflows), etc.
        local sync_target = "all"  // default
        if (strpos("`0'", "sync(") > 0) {
            local sync_start = strpos("`0'", "sync(") + 5
            local sync_end = strpos(substr("`0'", `sync_start', .), ")") + `sync_start' - 2
            local sync_target = substr("`0'", `sync_start', `sync_end' - `sync_start' + 1)
        }
        
        * Check for other options
        local has_verbose = (strpos("`0'", "verbose") > 0)
        local has_force = (strpos("`0'", "force") > 0)
        local has_forcepython = (strpos("`0'", "forcepython") > 0)
        local has_forcestata = (strpos("`0'", "forcestata") > 0)
        
        * Build option string
        local sync_opts ""
        if (`has_verbose') local sync_opts "`sync_opts' verbose"
        if (`has_force') local sync_opts "`sync_opts' force"
        if (`has_forcepython') local sync_opts "`sync_opts' forcepython"
        if (`has_forcestata') local sync_opts "`sync_opts' forcestata"
        
        * Route to unicefdata_sync
        unicefdata_sync, `sync_target' `sync_opts'
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
                        WIDE_attributes             /// Wide format with attributes as suffixes
                        ATTRIBUTES(string)          /// Attributes to keep for wide_indicators (_T _M _F _Q1 etc., or ALL)
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
                        NOMETAdata                  /// Show brief summary instead of full metadata
                        *                           /// Legacy options
                 ]

    quietly {

        *-----------------------------------------------------------------------
        * Validate inputs
        *-----------------------------------------------------------------------
        * Preserve the requested indicator list for later formatting steps
        local indicator_requested `indicator'
        
        if ("`indicator'" == "") & ("`dataflow'" == "") {
            noi di as err "You must specify either indicator() or dataflow()."
            noi di as text ""
            noi di as text "{bf:Discovery commands:}"
            noi di as text "  {stata unicefdata, categories}                " as text "- List categories with indicator counts"
            noi di as text "  {stata unicefdata, flows}                     " as text "- List available dataflows"
            noi di as text "  {stata unicefdata, search(mortality)}         " as text "- Search indicators by keyword"
            noi di as text "  {stata unicefdata, search(edu) dataflow(EDUCATION)} " as text "- Search within a dataflow"
            noi di as text "  {stata unicefdata, indicators(CME)}           " as text "- List indicators in a dataflow"
            noi di as text "  {stata unicefdata, info(CME_MRY0T4)}          " as text "- Get indicator details"
            noi di as text ""
            noi di as text "{bf:Data retrieval examples:}"
            noi di as text "  {stata unicefdata, indicator(CME_MRY0T4) clear}"
            noi di as text "  {stata unicefdata, indicator(CME_MRY0T4) countries(BRA) clear}"
            noi di as text "  {stata unicefdata, dataflow(NUTRITION) clear}"
            noi di as text ""
            noi di as text "{bf:Help:}"
            noi di as text "  {stata help unicefdata}                       " as text "- Full documentation"
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
        if ("`age'" == "") {
            local age "_T"
        }
        if ("`wealth'" == "") {
            local wealth "_T"
        }
        if ("`residence'" == "") {
            local residence "_T"
        }
        if ("`maternal_edu'" == "") {
            local maternal_edu "_T"
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
                * Always show auto-detected dataflow (matches R/Python behavior)
                noi di as text "Auto-detected dataflow '" as result "`dataflow'" as text "'"
                if ("`verbose'" != "" & "`indicator_name'" != "") {
                    noi di as text "Indicator: " as result "`indicator_name'"
                }
            }
            
            *-------------------------------------------------------------------
            * Check supported disaggregations (fast - reads dataflow schema directly)
            *-------------------------------------------------------------------
            
            * Get dimensions from dataflow schema (lightweight - doesn't parse indicator YAML)
            local has_sex = 0
            local has_age = 0
            local has_wealth = 0
            local has_residence = 0
            local has_maternal_edu = 0
            
            if ("`dataflow'" != "") {
                local schema_file "`metadata_path'_dataflows/`dataflow'.yaml"
                capture confirm file "`schema_file'"
                if (_rc == 0) {
                    * Read dataflow schema and extract dimensions (fast - small file)
                    tempname fh
                    local in_dimensions = 0
                    file open `fh' using "`schema_file'", read text
                    file read `fh' line
                    while r(eof) == 0 {
                        local trimmed_line = strtrim(`"`line'"')
                        if ("`trimmed_line'" == "dimensions:") {
                            local in_dimensions = 1
                        }
                        else if (`in_dimensions' == 1) {
                            * Check if we've left dimensions section
                            local first_char = substr(`"`line'"', 1, 1)
                            if ("`first_char'" != " " & "`first_char'" != "-" & "`first_char'" != "" & regexm(`"`line'"', "^[a-z_]+:")) {
                                local in_dimensions = 0
                            }
                            else if (regexm("`trimmed_line'", "^- id: *([A-Z_0-9]+)")) {
                                local dim_id = regexs(1)
                                if ("`dim_id'" == "SEX") local has_sex = 1
                                if ("`dim_id'" == "AGE") local has_age = 1
                                if ("`dim_id'" == "WEALTH_QUINTILE") local has_wealth = 1
                                if ("`dim_id'" == "RESIDENCE") local has_residence = 1
                                if ("`dim_id'" == "MATERNAL_EDU_LVL" | "`dim_id'" == "MOTHER_EDUCATION") local has_maternal_edu = 1
                            }
                        }
                        file read `fh' line
                    }
                    file close `fh'
                }
            }
            
            * Warn if user specified a filter that's not supported
            local unsupported_filters ""
            
            if ("`age'" != "" & "`age'" != "_T" & `has_age' == 0) {
                local unsupported_filters "`unsupported_filters' age"
            }
            if ("`wealth'" != "" & "`wealth'" != "_T" & `has_wealth' == 0) {
                local unsupported_filters "`unsupported_filters' wealth"
            }
            if ("`residence'" != "" & "`residence'" != "_T" & `has_residence' == 0) {
                local unsupported_filters "`unsupported_filters' residence"
            }
            if ("`maternal_edu'" != "" & "`maternal_edu'" != "_T" & `has_maternal_edu' == 0) {
                local unsupported_filters "`unsupported_filters' maternal_edu"
            }
            
            if ("`unsupported_filters'" != "") {
                noi di ""
                noi di as error "Warning: The following disaggregation(s) are NOT supported by `indicator':"
                noi di as error "        `unsupported_filters'"
                noi di as text "  This indicator's dataflow (`dataflow') does not include these dimensions."
                noi di as text "  Your filter(s) will be ignored. Use {stata unicefdata, info(`indicator')} for details."
                noi di ""
            }
            
            * Show brief info about what IS supported (in verbose mode)
            if ("`verbose'" != "") {
                noi di as text "Supported disaggregations: " _continue
                if (`has_sex' == 1) noi di as result "sex " _continue
                if (`has_age' == 1) noi di as result "age " _continue
                if (`has_wealth' == 1) noi di as result "wealth " _continue
                if (`has_residence' == 1) noi di as result "residence " _continue
                if (`has_maternal_edu' == 1) noi di as result "maternal_edu " _continue
                noi di ""
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
        
        * Show fetching message (matches R/Python behavior)
        noi di as text "Fetching page 1..."
        
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
            noi di as text `"{p 4 4 2}(6) {browse "https://github.com/unicef-drp/unicefData/issues/new":Report an issue on GitHub} with a detailed description and, if possible, a log with {bf:set trace on} enabled.{p_end}"'
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
            
            * =================================================================
            * OPTIMIZED: Batch rename, label, and destring operations
            * v1.3.2: Reduced from ~50 individual commands to batch operations
            * =================================================================
            
            quietly {
                * --- Batch rename: lowercase API columns to standard names ---
                * Check and rename in single pass (avoids 30+ separate rename calls)
                local renames ""
                local renames "`renames' ref_area:iso3 REF_AREA:iso3"
                local renames "`renames' time_period:period TIME_PERIOD:period"
                local renames "`renames' obs_value:value OBS_VALUE:value"
                local renames "`renames' geographicarea:country GEOGRAPHICAREA:country geographic_area:country"
                local renames "`renames' unit_measure:unit UNIT_MEASURE:unit"
                local renames "`renames' wealth_quintile:wealth WEALTH_QUINTILE:wealth"
                local renames "`renames' lower_bound:lb LOWER_BOUND:lb"
                local renames "`renames' upper_bound:ub UPPER_BOUND:ub"
                local renames "`renames' obs_status:status OBS_STATUS:status"
                local renames "`renames' data_source:source DATA_SOURCE:source"
                local renames "`renames' ref_period:refper REF_PERIOD:refper"
                local renames "`renames' country_notes:notes COUNTRY_NOTES:notes"
                local renames "`renames' maternal_edu_lvl:matedu MATERNAL_EDU_LVL:matedu"
                
                foreach pair of local renames {
                    gettoken oldname newname : pair, parse(":")
                    local newname = subinstr("`newname'", ":", "", 1)
                    capture confirm variable `oldname'
                    if (_rc == 0) {
                        rename `oldname' `newname'
                    }
                }
                
                * Handle special cases: API duplicate column naming creates v4, v6
                capture confirm variable v4
                if (_rc == 0) rename v4 indicator_name
                capture confirm variable unitofmeasure
                if (_rc == 0) rename unitofmeasure unit_name
                capture confirm variable v6
                if (_rc == 0) rename v6 sex_name
                capture confirm variable wealthquintile
                if (_rc == 0) rename wealthquintile wealth_name
                capture confirm variable observationstatus
                if (_rc == 0) rename observationstatus status_name
                
                * Handle case-sensitive columns (sex, age, residence)
                foreach v in sex age residence {
                    local V = upper("`v'")
                    capture confirm variable `V'
                    if (_rc == 0) rename `V' `v'
                }
            }
            
            * --- Batch label variables (single quietly block) ---
            quietly {
                * Define labels in compact format: varname "label"
                local varlabels `""iso3" "ISO3 country code""'
                local varlabels `"`varlabels' "country" "Country name""'
                local varlabels `"`varlabels' "indicator" "Indicator code""'
                local varlabels `"`varlabels' "indicator_name" "Indicator name""'
                local varlabels `"`varlabels' "period" "Time period (year)""'
                local varlabels `"`varlabels' "value" "Observation value""'
                local varlabels `"`varlabels' "unit" "Unit of measure code""'
                local varlabels `"`varlabels' "unit_name" "Unit of measure""'
                local varlabels `"`varlabels' "sex" "Sex code""'
                local varlabels `"`varlabels' "sex_name" "Sex""'
                local varlabels `"`varlabels' "age" "Age group""'
                local varlabels `"`varlabels' "wealth" "Wealth quintile code""'
                local varlabels `"`varlabels' "wealth_name" "Wealth quintile""'
                local varlabels `"`varlabels' "residence" "Residence type""'
                local varlabels `"`varlabels' "matedu" "Maternal education level""'
                local varlabels `"`varlabels' "lb" "Lower confidence bound""'
                local varlabels `"`varlabels' "ub" "Upper confidence bound""'
                local varlabels `"`varlabels' "status" "Observation status code""'
                local varlabels `"`varlabels' "status_name" "Observation status""'
                local varlabels `"`varlabels' "source" "Data source""'
                local varlabels `"`varlabels' "refper" "Reference period""'
                local varlabels `"`varlabels' "notes" "Country notes""'
                
                * Apply labels only if variable exists (22 pairs = 44 words)
                local i = 1
                while (`i' <= 44) {
                    local varname : word `i' of `varlabels'
                    local ++i
                    local varlbl : word `i' of `varlabels'
                    local ++i
                    capture confirm variable `varname'
                    if (_rc == 0) {
                        label variable `varname' `"`varlbl'"'
                    }
                }
            }
            
            * --- Optimized period conversion (handle YYYY-MM format) ---
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
            
            * --- OPTIMIZED: Single destring call for multiple variables ---
            * v1.3.2: Replaced 4 separate destring calls with one
            capture {
                * Build list of string variables that need conversion
                local to_destring ""
                foreach v in period value lb ub {
                    capture confirm string variable `v'
                    if (_rc == 0) local to_destring "`to_destring' `v'"
                }
                if ("`to_destring'" != "") {
                    destring `to_destring', replace force
                }
            }
            
            *-------------------------------------------------------------------
            * Show available disaggregations and applied filters
            * (Matches R/Python informative output)
            *-------------------------------------------------------------------
            
            * Build note about available disaggregations
            local avail_disagg ""
            local applied_filters ""
            
            * Check sex disaggregation
            capture confirm variable sex
            if (_rc == 0) {
                quietly levelsof sex, local(sex_vals) clean
                local n_sex : word count `sex_vals'
                if (`n_sex' > 1) {
                    local avail_disagg "`avail_disagg'sex: `sex_vals'; "
                }
            }
            
            * Check wealth disaggregation
            capture confirm variable wealth
            if (_rc == 0) {
                quietly levelsof wealth, local(wealth_vals) clean
                local n_wealth : word count `wealth_vals'
                if (`n_wealth' > 1) {
                    local avail_disagg "`avail_disagg'wealth_quintile: `wealth_vals'; "
                }
            }
            
            * Check age disaggregation
            capture confirm variable age
            if (_rc == 0) {
                quietly levelsof age, local(age_vals) clean
                local n_age : word count `age_vals'
                if (`n_age' > 1) {
                    local avail_disagg "`avail_disagg'age: `age_vals'; "
                }
            }
            
            * Check residence disaggregation
            capture confirm variable residence
            if (_rc == 0) {
                quietly levelsof residence, local(res_vals) clean
                local n_res : word count `res_vals'
                if (`n_res' > 1) {
                    local avail_disagg "`avail_disagg'residence: `res_vals'; "
                }
            }
            
            * Check maternal education disaggregation
            capture confirm variable matedu
            if (_rc == 0) {
                quietly levelsof matedu, local(matedu_vals) clean
                local n_matedu : word count `matedu_vals'
                if (`n_matedu' > 1) {
                    local avail_disagg "`avail_disagg'maternal_edu: `matedu_vals'; "
                }
            }
            
            * Show note if disaggregations are available
            if ("`avail_disagg'" != "") {
                noi di as text "Note: Disaggregated data available: " as result "`avail_disagg'"
                
                * Show applied filters (only for dimensions present in data)
                local applied_filters ""
                capture confirm variable sex
                if (_rc == 0) {
                    if ("`sex'" != "" & "`sex'" != "ALL") {
                        local is_default = cond("`sex'" == "_T", " (Default)", "")
                        local applied_filters "`applied_filters'sex: `sex'`is_default'; "
                    }
                }
                capture confirm variable wealth
                if (_rc == 0) {
                    if ("`wealth'" != "" & "`wealth'" != "ALL") {
                        local is_default = cond("`wealth'" == "_T", " (Default)", "")
                        local applied_filters "`applied_filters'wealth_quintile: `wealth'`is_default'; "
                    }
                }
                capture confirm variable age
                if (_rc == 0) {
                    if ("`age'" != "" & "`age'" != "ALL") {
                        local is_default = cond("`age'" == "_T", " (Default)", "")
                        local applied_filters "`applied_filters'age: `age'`is_default'; "
                    }
                }
                capture confirm variable residence
                if (_rc == 0) {
                    if ("`residence'" != "" & "`residence'" != "ALL") {
                        local is_default = cond("`residence'" == "_T", " (Default)", "")
                        local applied_filters "`applied_filters'residence: `residence'`is_default'; "
                    }
                }
                capture confirm variable matedu
                if (_rc == 0) {
                    if ("`maternal_edu'" != "" & "`maternal_edu'" != "ALL") {
                        local is_default = cond("`maternal_edu'" == "_T", " (Default)", "")
                        local applied_filters "`applied_filters'maternal_edu: `maternal_edu'`is_default'; "
                    }
                }
                
                if ("`applied_filters'" != "") {
                    noi di as text "Applied filters: " as result "`applied_filters'"
                }
            }
            
            * Filter by sex if specified
            if ("`sex'" != "" & "`sex'" != "ALL") {
                capture confirm variable sex
                if (_rc == 0) {
                    quietly count if sex == "`sex'"
                    local sex_keep = r(N)
                    if (`sex_keep' > 0) {
                        keep if sex == "`sex'"
                    }
                    else if ("`verbose'" != "") {
                        noi di as text "  sex filter: value `sex' not found; keeping all"
                    }
                }
            }
            
            * Filter by age if specified
            if ("`age'" != "" & "`age'" != "ALL") {
                capture confirm variable age
                if (_rc == 0) {
                    quietly count if age == "`age'"
                    local age_keep = r(N)
                    if (`age_keep' > 0) {
                        keep if age == "`age'"
                    }
                    else if ("`verbose'" != "") {
                        noi di as text "  age filter: value `age' not found; keeping all"
                    }
                }
            }
            
            * Filter by wealth quintile if specified
            if ("`wealth'" != "" & "`wealth'" != "ALL") {
                capture confirm variable wealth
                if (_rc == 0) {
                    quietly count if wealth == "`wealth'"
                    local wealth_keep = r(N)
                    if (`wealth_keep' > 0) {
                        keep if wealth == "`wealth'"
                    }
                    else if ("`verbose'" != "") {
                        noi di as text "  wealth filter: value `wealth' not found; keeping all"
                    }
                }
            }
            
            * Filter by residence if specified
            if ("`residence'" != "" & "`residence'" != "ALL") {
                capture confirm variable residence
                if (_rc == 0) {
                    quietly count if residence == "`residence'"
                    local residence_keep = r(N)
                    if (`residence_keep' > 0) {
                        keep if residence == "`residence'"
                    }
                    else if ("`verbose'" != "") {
                        noi di as text "  residence filter: value `residence' not found; keeping all"
                    }
                }
            }
            
            * Filter by maternal education if specified
            if ("`maternal_edu'" != "" & "`maternal_edu'" != "ALL") {
                capture confirm variable matedu
                if (_rc == 0) {
                    quietly count if matedu == "`maternal_edu'"
                    local matedu_keep = r(N)
                    if (`matedu_keep' > 0) {
                        keep if matedu == "`maternal_edu'"
                    }
                    else if ("`verbose'" != "") {
                        noi di as text "  maternal_edu filter: value `maternal_edu' not found; keeping all"
                    }
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
        
        * Check for conflicting options: cannot use wide_attributes and wide_indicators together
        if ("`wide_attributes'" != "" & "`wide_indicators'" != "") {
            noi di as error "Error: wide_attributes and wide_indicators cannot be used together."
            noi di as error "Choose one: wide_attributes (pivots disaggregation suffixes) OR wide_indicators (pivots indicators as columns)"
            error 198
        }
        
        * Apply attribute filtering FIRST (if specified with wide_attributes or wide_indicators)
        local pre_filter_n = _N
        if (("`wide_attributes'" != "" | "`wide_indicators'" != "") & "`attributes'" != "") {
            * Set default if attributes() is specified but empty string
            if (lower("`attributes'") == "all") {
                * Keep all attributes - no filtering
                if ("`verbose'" != "") {
                    noi di as text "  keeping all attributes (attributes=ALL)"
                }
            }
            else {
                * Filter: keep rows where ANY disaggregation variable matches ANY specified attribute
                tempvar attr_match
                gen `attr_match' = 0
                
                * Check sex
                capture confirm variable sex
                if (_rc == 0) {
                    foreach attr in `attributes' {
                        replace `attr_match' = 1 if upper(sex) == upper("`attr'")
                    }
                }
                
                * Check age
                capture confirm variable age
                if (_rc == 0) {
                    foreach attr in `attributes' {
                        replace `attr_match' = 1 if upper(age) == upper("`attr'")
                    }
                }
                
                * Check wealth
                capture confirm variable wealth
                if (_rc == 0) {
                    foreach attr in `attributes' {
                        replace `attr_match' = 1 if upper(wealth) == upper("`attr'")
                    }
                }
                
                * Check residence
                capture confirm variable residence
                if (_rc == 0) {
                    foreach attr in `attributes' {
                        replace `attr_match' = 1 if upper(residence) == upper("`attr'")
                    }
                }
                
                * Check maternal education
                capture confirm variable matedu
                if (_rc == 0) {
                    foreach attr in `attributes' {
                        replace `attr_match' = 1 if upper(matedu) == upper("`attr'")
                    }
                }
                
                * If no disaggregation variables exist (all missing), keep the row
                capture confirm variable sex
                local has_any_disag = (_rc == 0)
                capture confirm variable age
                if (_rc == 0) local has_any_disag = 1
                capture confirm variable wealth
                if (_rc == 0) local has_any_disag = 1
                capture confirm variable residence
                if (_rc == 0) local has_any_disag = 1
                capture confirm variable matedu
                if (_rc == 0) local has_any_disag = 1
                
                if (!`has_any_disag') {
                    replace `attr_match' = 1
                }
                
                count if `attr_match'
                local attr_match_n = r(N)
                if (`attr_match_n' > 0) {
                    keep if `attr_match'
                    if ("`verbose'" != "") {
                        noi di as text "  attributes filter: kept `attr_match_n' of `pre_filter_n' obs for attributes: `attributes'"
                    }
                }
                else if ("`verbose'" != "") {
                    noi di as text "  attributes filter: no matches for specified attributes `attributes', keeping all"
                }
                drop `attr_match'
            }
        }
        
        if ("`wide_indicators'" != "") {
            * Reshape with indicators as columns (like Python wide_indicators)
            
            * Warn if only one indicator (matches R/Python behavior)
            if (`n_indicators' <= 1) {
                noi di ""
                noi di as error "Warning: 'wide_indicators' format is designed for multiple indicators."
                noi di as text "  Consider using 'wide' format instead for a single indicator."
                noi di ""
            }
            
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable indicator
            capture confirm variable value
            if (_rc == 0) {
                if ("`verbose'" != "") {
                    noi di as text "wide_indicators: Starting with `pre_filter_n' observations"
                }
                
                * If attributes() not specified with wide_indicators, default to _T
                if ("`attributes'" == "") {
                    local attributes "_T"
                    local pre_filter_n = _N
                    
                    * Apply strict default filtering: require all present disaggregations == _T
                    tempvar all_tot
                    gen byte `all_tot' = 1
                    
                    * Constrain by sex if present
                    capture confirm variable sex
                    if (_rc == 0) {
                        replace `all_tot' = `all_tot' & (upper(sex) == "_T")
                    }
                    
                    * Constrain by age if present
                    capture confirm variable age
                    if (_rc == 0) {
                        replace `all_tot' = `all_tot' & (upper(age) == "_T")
                    }
                    
                    * Constrain by wealth if present
                    capture confirm variable wealth
                    if (_rc == 0) {
                        replace `all_tot' = `all_tot' & (upper(wealth) == "_T")
                    }
                    
                    * Constrain by residence if present
                    capture confirm variable residence
                    if (_rc == 0) {
                        replace `all_tot' = `all_tot' & (upper(residence) == "_T")
                    }
                    
                    * Constrain by maternal education if present
                    capture confirm variable matedu
                    if (_rc == 0) {
                        replace `all_tot' = `all_tot' & (upper(matedu) == "_T")
                    }
                    
                    * Keep only rows where all present disaggregations equal _T
                    count if `all_tot'
                    local attr_match_n = r(N)
                    if (`attr_match_n' > 0) {
                        keep if `all_tot'
                        if ("`verbose'" != "") {
                            noi di as text "  default attributes filter (_T across all present dims): kept `attr_match_n' of `pre_filter_n' obs"
                        }
                    }
                    drop `all_tot'
                }
                
                * Keep columns needed for reshape
                local keep_vars "iso3 country period indicator value"
                foreach var in sex age wealth residence matedu sex_name age_name wealth_name residence_name maternal_edu_name unit unit_name lb ub status status_name source refper notes {
                    capture confirm variable `var'
                    if (_rc == 0) local keep_vars "`keep_vars' `var'"
                }
                if ("`addmeta'" != "") {
                    foreach v in region income_group continent geo_type {
                        capture confirm variable `v'
                        if (_rc == 0) local keep_vars "`keep_vars' `v'"
                    }
                }
                keep `keep_vars'
                
                * Drop duplicates to ensure unique combinations
                duplicates drop iso3 country period indicator, force
                
                if (_N > 0) {
                    * Reshape: indicators become columns
                    capture reshape wide value, i(iso3 country period) j(indicator) string
                    if (_rc == 0) {
                        * Clean up column names (remove "value" prefix)
                        foreach v of varlist value* {
                            local newname = subinstr("`v'", "value", "", 1)
                            rename `v' `newname'
                        }

                        * Ensure columns exist for all requested indicators
                        * (create empty numeric columns when an indicator has no data)
                        local n_req : word count `indicator_requested'
                        if (`n_req' > 0) {
                            foreach ind of local indicator_requested {
                                capture confirm variable `ind'
                                if (_rc != 0) {
                                    gen double `ind' = .
                                }
                            }
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
                else {
                    noi di as error "Warning: No data remaining after applying attribute filters for wide_indicators."
                    noi di as text "Try without wide_indicators option or check the attributes() option."
                }
            }
        }
        if ("`wide_attributes'" != "") {
            * Reshape to wide format (disaggregation attributes as suffixes)
            * Result: iso3, country, period, and columns like CME_MRY0T4_T, CME_MRY0T4_M, etc.
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable indicator
            capture confirm variable value
            if (_rc == 0) {
                * Build composite suffix from available disaggregation variables
                tempvar disag_suffix
                gen `disag_suffix' = ""
                
                * Add sex suffix if present
                capture confirm variable sex
                if (_rc == 0) {
                    replace `disag_suffix' = `disag_suffix' + "_" + sex
                }
                
                * Add wealth suffix if present
                capture confirm variable wealth
                if (_rc == 0) {
                    replace `disag_suffix' = `disag_suffix' + "_" + wealth
                }
                
                * Add age suffix if present
                capture confirm variable age
                if (_rc == 0) {
                    replace `disag_suffix' = `disag_suffix' + "_" + age
                }
                
                * Add residence suffix if present
                capture confirm variable residence
                if (_rc == 0) {
                    replace `disag_suffix' = `disag_suffix' + "_" + residence
                }
                
                * Add maternal education suffix if present
                capture confirm variable matedu
                if (_rc == 0) {
                    replace `disag_suffix' = `disag_suffix' + "_" + matedu
                }
                
                * If no disaggregation variables, use empty suffix
                replace `disag_suffix' = "" if `disag_suffix' == ""
                
                * Create composite variable name: indicator + suffix
                tempvar ind_disag
                gen `ind_disag' = indicator + `disag_suffix'
                
                * Keep only essential columns for reshape
                keep iso3 country period `ind_disag' value
                
                * Reshape: each indicator+disaggregation combination becomes a column
                capture reshape wide value, i(iso3 country period) j(`ind_disag') string
                if (_rc == 0) {
                    * Rename value* variables to remove the "value" prefix
                    quietly ds value*
                    foreach var in `r(varlist)' {
                        local newname = subinstr("`var'", "value", "", 1)
                        rename `var' `newname'
                    }
                    sort iso3 period
                }
                else {
                    noi di as text "Note: Could not reshape to wide_attributes format."
                }
            }
        }
        else if ("`wide'" != "") {
            * Reshape to wide format (years as columns with yr prefix)
            * Result: iso3, country, indicator, sex, wealth, age, residence, etc., and columns like yr2019, yr2020, yr2021
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable indicator
            capture confirm variable value
            if (_rc == 0) {
                * Build alias_id from iso3, indicator, and any non-missing disaggregations
                capture confirm variable alias_id
                if (_rc != 0) {
                    gen str200 alias_id = iso3 + "_" + indicator
                    foreach v in sex age wealth residence matedu {
                        capture confirm variable `v'
                        if (_rc == 0) {
                            replace alias_id = alias_id + "_" + `v' if length(`v') > 0
                        }
                    }
                }

                * Preserve identifier metadata to merge back after reshape
                preserve
                local meta_vars "alias_id iso3 country indicator"
                foreach v in sex age wealth residence matedu {
                    capture confirm variable `v'
                    if (_rc == 0) local meta_vars "`meta_vars' `v'"
                }
                keep `meta_vars'
                duplicates drop alias_id, force
                tempfile alias_meta
                save `alias_meta', replace
                restore

                * Ensure period is numeric for reshape j()
                capture confirm numeric variable period
                if (_rc != 0) {
                    cap destring period, replace
                }

                * Keep only alias_id, period and value for pivot
                local __wide_ready 1
                capture keep alias_id period value
                if (_rc != 0) {
                    noi di as text "Note: Required variables missing for wide reshape; leaving data in long format."
                    local __wide_ready 0
                }

                if "`__wide_ready'" == "1" {
                    * Ensure uniqueness on alias_id × period
                    capture duplicates drop alias_id period, force
                    sort alias_id period
                    by alias_id period: gen byte __first_key = _n==1
                    keep if __first_key
                    drop __first_key
                }

                if "`__wide_ready'" == "1" {
                    * Reshape: years become columns (period is numeric)
                    capture reshape wide value, i(alias_id) j(period)
                    if (_rc == 0) {
                    * Rename value* variables to have yr prefix
                    quietly ds value*
                    foreach var in `r(varlist)' {
                        local year = subinstr("`var'", "value", "", 1)
                        rename `var' yr`year'
                    }
                    * Merge back metadata
                        capture merge 1:1 alias_id using `alias_meta'
                        if (_rc == 0) {
                            drop _merge
                            sort iso3 indicator
                        }
                        else {
                            noi di as text "Note: Metadata merge failed; proceeding without merged identifiers."
                        }
                    }
                    else {
                        noi di as text "Note: Could not reshape to wide format (years as columns)."
                    }
                }
            }
        }
        else {
            * Data is already in long format from SDMX CSV (default)
            * Sort by available key variables
            capture confirm variable iso3
            local has_iso3 = (_rc == 0)
            capture confirm variable period
            local has_period = (_rc == 0)
            
            if (`has_iso3' & `has_period') {
                sort iso3 period
            }
            else if (`has_iso3') {
                sort iso3
            }
            else if (`has_period') {
                sort period
            }
            * If neither exists, leave data unsorted
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
        
        *-----------------------------------------------------------------------
        * Display indicator metadata
        *-----------------------------------------------------------------------
        
        local n_indicators : word count `indicator'
        
        if (`n_indicators' == 1) {
            * Get indicator info (now fast - direct file search, no full YAML parse)
            capture _unicef_indicator_info, indicator("`indicator'") metapath("`metadata_path'") brief
            if (_rc == 0) {
                * Store metadata return values
                return local indicator_name "`r(name)'"
                return local indicator_category "`r(category)'"
                return local indicator_dataflow "`r(dataflow)'"
                return local indicator_description "`r(description)'"
                return local indicator_urn "`r(urn)'"
                return local has_sex "`r(has_sex)'"
                return local has_age "`r(has_age)'"
                return local has_wealth "`r(has_wealth)'"
                return local has_residence "`r(has_residence)'"
                return local has_maternal_edu "`r(has_maternal_edu)'"
                return local supported_dims "`r(supported_dims)'"
                
                if ("`nometadata'" == "") {
                    *-----------------------------------------------------------
                    * FULL METADATA DISPLAY (default)
                    *-----------------------------------------------------------
                    noi di ""
                    noi di as text "{hline 70}"
                    noi di as text "Indicator Information: " as result "`indicator'"
                    noi di as text "{hline 70}"
                    noi di ""
                    noi di as text _col(2) "Code:        " as result "`indicator'"
                    noi di as text _col(2) "Name:        " as result "`r(name)'"
                    noi di as text _col(2) "Category:    " as result "`r(category)'"
                    if ("`r(dataflow)'" != "" & "`r(dataflow)'" != "`r(category)'") {
                        noi di as text _col(2) "Dataflow:    " as result "`r(dataflow)'"
                    }
                    
                    if ("`r(description)'" != "" & "`r(description)'" != ".") {
                        noi di ""
                        noi di as text _col(2) "Description:"
                        noi di as result _col(4) "`r(description)'"
                    }
                    
                    if ("`r(urn)'" != "" & "`r(urn)'" != ".") {
                        noi di ""
                        noi di as text _col(2) "URN:         " as result "`r(urn)'"
                    }
                    
                    noi di ""
                    noi di as text _col(2) "Supported Disaggregations:"
                    noi di as text _col(4) "sex:          " as result cond("`r(has_sex)'" == "1", "Yes (SEX)", "No")
                    noi di as text _col(4) "age:          " as result cond("`r(has_age)'" == "1", "Yes (AGE)", "No")
                    noi di as text _col(4) "wealth:       " as result cond("`r(has_wealth)'" == "1", "Yes (WEALTH_QUINTILE)", "No")
                    noi di as text _col(4) "residence:    " as result cond("`r(has_residence)'" == "1", "Yes (RESIDENCE)", "No")
                    noi di as text _col(4) "maternal_edu: " as result cond("`r(has_maternal_edu)'" == "1", "Yes (MATERNAL_EDU_LVL)", "No")
                    
                    noi di ""
                    noi di as text _col(2) "Observations: " as result _N
                    noi di as text "{hline 70}"
                }
                else {
                    *-----------------------------------------------------------
                    * BRIEF DISPLAY (when nometadata specified)
                    *-----------------------------------------------------------
                    noi di ""
                    noi di as text "{hline 70}"
                    noi di as text "Indicator: " as result "`indicator'" as text " (Dataflow: " as result "`dataflow'" as text ")"
                    noi di as text "Observations: " as result _N
                    noi di as text "{hline 70}"
                    noi di as text "{p 2 2 2}Use {stata unicefdata, info(`indicator')} for detailed metadata{p_end}"
                    noi di as text "{hline 70}"
                }
            }
            else {
                * Fallback if metadata lookup failed
                noi di ""
                noi di as text "{hline 70}"
                noi di as text "Indicator: " as result "`indicator'" as text " (Dataflow: " as result "`dataflow'" as text ")"
                noi di as text "Observations: " as result _N
                noi di as text "{hline 70}"
                noi di as text "{p 2 2 2}Use {stata unicefdata, info(`indicator')} for detailed metadata{p_end}"
                noi di as text "{hline 70}"
            }
        }
        else if (`n_indicators' > 1) {
            noi di ""
            noi di as text "{hline 70}"
            noi di as text "Retrieved " as result "`n_indicators'" as text " indicators from dataflow " as result "`dataflow'"
            noi di as text "{hline 70}"
            noi di as text " Observations: " as result _N
            noi di as text "{hline 70}"
        }
        else {
            noi di ""
            noi di as text "{hline 70}"
            noi di as text "Retrieved data from dataflow: " as result "`dataflow'"
            noi di as text "{hline 70}"
            noi di as text " Observations: " as result _N
            noi di as text "{hline 70}"
        }
        
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

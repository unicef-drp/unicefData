*! v 2.0.4  01Feb2026               by Joao Pedro Azevedo (UNICEF)
* v 2.0.4   01Feb2026  - FEATURE: NUTRITION dataflow now defaults age to Y0T4 (0-4 years) instead of _T
*                        because the AGE dimension in NUTRITION has no _T total
*                      - FEATURE: Added wealth_quintile() as alias for wealth() option
*                      - WARNING message displayed when Y0T4 default is used
*                      - ALIGNMENT: Same fix applied to R and Python implementations
* v 2.0.3   01Feb2026  - BUGFIX: latest and mrv options now include disaggregation dimensions in grouping
*                        so that sex(ALL)/wealth(ALL)/residence(ALL) work correctly with latest/mrv
*                      - BUGFIX: Use SHORT variable names (wealth, matedu) in latest/mrv filters
*                        as they exist at that point (renamed to long names later)
* v 2.0.2   01Feb2026  - Deprecate _unicefdata_indicators.yaml; use _unicefdata_indicators_metadata.yaml exclusively
* v 2.0.1   30Jan2026  - Patch: Fixed false warning about unsupported disaggregations
*                        (metadata_path was being reset at line 707, breaking dimension check)
cap program drop unicefdata
program define unicefdata, rclass
version 11
* Download indicators from UNICEF Data Warehouse via SDMX API
* Aligned with R get_unicef() and Python unicef_api
* Uses YAML metadata for dataflow detection and validation
*
* NEW in v2.0.0:
* - FEATURE: Metadata-driven filtering using disaggregations_with_totals from YAML
* - FEATURE: Dimensions not in disaggregations_with_totals are not defaulted to _T
* - FEATURE: DISABILITY_STATUS special handling - filters to PD (baseline) when no _T exists
* - ALIGNMENT: Now matches Python/R filtering behavior for cross-platform consistency
* - FIX: SYNC-02 enrichment path extraction bug resolved (all QA tests passing)
* - ENHANCEMENT: Improved metadata enrichment pipeline reliability
* - FIX: Multi-indicator wide format now includes geo_type in output
* - FIX: alias_id no longer appears in final wide format output
*

    * =========================================================================
    * Auto-setup: Check if YAML metadata files exist, install if missing
    * =========================================================================
    local plusdir : sysdir PLUS
    cap confirm file "`plusdir'_/_unicefdata_indicators_metadata.yaml"
    if _rc != 0 {
        * Metadata files not found - run setup
        di as text ""
        di as text "{hline 70}"
        di as text "{bf:First-time setup}: Metadata files not found."
        di as text "Running {cmd:unicefdata_setup} to install required YAML files..."
        di as text "{hline 70}"
        
        cap noi unicefdata_setup, replace
        if _rc != 0 {
            di as error ""
            di as error "Setup failed. Please run {cmd:unicefdata_setup} manually."
            di as error "Or download metadata files from GitHub:"
            di as error "  https://github.com/jpazvd/unicefData"
            error 601
        }
    }
    * =========================================================================

    
    * Check for FLOWS/DATAFLOWS subcommand (list available dataflows with counts)
    * Accept both "flows" and "dataflows" for user convenience
    if (strpos("`0'", "flows") > 0 | strpos("`0'", "dataflows") > 0) {
        * Don't match "dataflow(" which is the filter option
        if (strpos("`0'", "dataflow(") == 0) {
            local has_detail = (strpos("`0'", "detail") > 0)
            local has_verbose = (strpos("`0'", "verbose") > 0)
            local has_dups = (strpos("`0'", "dups") > 0)
            local has_showtier2 = (strpos(lower("`0'"), "showtier2") > 0)
            local has_showtier3 = (strpos(lower("`0'"), "showtier3") > 0)
            local has_showall = (strpos(lower("`0'"), "showall") > 0)
            local has_showlegacy = (strpos(lower("`0'"), "showlegacy") > 0)
            local opts ""
            if (`has_detail') local opts "`opts' detail"
            if (`has_verbose') local opts "`opts' verbose"
            if (`has_dups') local opts "`opts' dups"
            if (`has_showtier2') local opts "`opts' showtier2"
            if (`has_showtier3' | `has_showlegacy') local opts "`opts' showtier3"
            if (`has_showall') local opts "`opts' showall"
            local opts = strtrim("`opts'")
            if ("`opts'" != "") {
                _unicef_list_dataflows, `opts'
            }
            else {
                _unicef_list_dataflows
            }
            exit
        }
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
        
        * Check for category option (search by category instead of dataflow)
        local has_category = (strpos("`remaining'", "category") > 0)
        
        * Check for tier filter options
        local has_showtier2 = (strpos(lower("`remaining'"), "showtier2") > 0)
        local has_showtier3 = (strpos(lower("`remaining'"), "showtier3") > 0)
        local has_showall = (strpos(lower("`remaining'"), "showall") > 0)
        local has_showorphans = (strpos(lower("`remaining'"), "showorphan") > 0)
        local has_showlegacy = (strpos(lower("`remaining'"), "showlegacy") > 0)
        local has_byflow = (strpos(lower("`remaining'"), "byflow") > 0)
        
        * Build options string
        local search_opts = ""
        if ("`dataflow_filter'" != "") {
            local search_opts "`search_opts' dataflow(`dataflow_filter')"
        }
        if (`has_category') {
            local search_opts "`search_opts' category"
        }
        if (`has_showtier2') {
            local search_opts "`search_opts' showtier2"
        }
        if (`has_showtier3' | `has_showlegacy') {
            local search_opts "`search_opts' showtier3"
        }
        if (`has_showall') {
            local search_opts "`search_opts' showall"
        }
        if (`has_showorphans') {
            local search_opts "`search_opts' showorphans"
        }
        if (`has_byflow') {
            local search_opts "`search_opts' byflow"
        }
        local search_opts = strtrim("`search_opts'")
        
        if ("`search_opts'" != "") {
            _unicef_search_indicators, keyword("`search_keyword'") limit(`limit_val') `search_opts'
        }
        else {
            _unicef_search_indicators, keyword("`search_keyword'") limit(`limit_val')
        }
        
        * Preserve return values from helper
        return add
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
        
        * Check for tier filter options
        local has_showtier2 = (strpos(lower("`0'"), "showtier2") > 0)
        local has_showtier3 = (strpos(lower("`0'"), "showtier3") > 0)
        local has_showall = (strpos(lower("`0'"), "showall") > 0)
        local has_showorphans = (strpos(lower("`0'"), "showorphan") > 0)
        local has_showlegacy = (strpos(lower("`0'"), "showlegacy") > 0)
        
        * Build options string
        local ind_opts = ""
        if (`has_verbose') local ind_opts "`ind_opts' verbose"
        if (`has_showtier2') local ind_opts "`ind_opts' showtier2"
        if (`has_showtier3' | `has_showlegacy') local ind_opts "`ind_opts' showtier3"
        if (`has_showall') local ind_opts "`ind_opts' showall"
        if (`has_showorphans') local ind_opts "`ind_opts' showorphans"
        local ind_opts = strtrim("`ind_opts'")
        
        if ("`ind_opts'" == "") {
            _unicef_list_indicators, dataflow("`ind_dataflow'")
        }
        else {
            _unicef_list_indicators, dataflow("`ind_dataflow'") `ind_opts'
        }
        
        * Preserve return values from helper
        return add
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

    * Check for CATEGORIES subcommand (list categories with indicator counts)
    if (strpos("`0'", "categories") > 0) {
        local has_detail = (strpos("`0'", "detail") > 0)
        local has_verbose = (strpos("`0'", "verbose") > 0)

        local opts ""
        if (`has_detail') local opts "detail"
        if (`has_verbose') local opts "`opts' verbose"

        if ("`opts'" == "") {
            _unicef_list_categories
        }
        else {
            _unicef_list_categories, `opts'
        }

        exit
    }

    *---------------------------------------------------------------------------
    * Regular syntax for data retrieval
    *---------------------------------------------------------------------------

    syntax                                          ///
                 [,                                 ///
                        SEARCH(string)              /// Search indicators by keyword (discovery)
                        INDICATOR(string)           /// Indicator code(s)
                        DATAFLOW(string)            /// SDMX dataflow ID
                        COUNTries(string)           /// ISO3 country codes
                        YEAR(string)                /// Year(s): single, range (2015:2023), or list (2015,2018,2020)
                        CIRCA                       /// Find closest available year
                        FILTERvector(string)        /// Pre-constructed SDMX filter key (alternative to individual filters)
                        SEX(string)                 /// Sex: _T, F, M, ALL
                        AGE(string)                 /// Age group filter
                        WEALTH(string)              /// Wealth quintile filter
                        WEALTH_QUINTILE(string)     /// Alias for wealth() - for user convenience
                        RESIDENCE(string)           /// Residence: URBAN, RURAL
                        MATERNAL_edu(string)        /// Maternal education filter
                        LONG                        /// Long format (default)
                        WIDE                        /// Wide format (uses csv-ts API format) - years as columns
                        WIDE_indicators             /// Wide format with indicators as columns
                        WIDE_attributes(string)     /// Wide format pivoting on dimension(s): sex, age, wealth, residence, maternal_edu
                        ATTRIBUTES(string)          /// Attributes to keep for wide_indicators (_T _M _F _Q1 etc., or ALL)
                        LATEST                      /// Most recent value only
                        MRV(integer 0)              /// N most recent values
                        DROPNA                      /// Drop missing values
                        SIMPLIFY                    /// Essential columns only
                        noSPARSE                    /// Keep all standard columns (default: sparse)
                        RAW                         /// Raw SDMX output
                        ADDmeta(string)             /// Add metadata columns (region, income_group)
                        VERSION(string)             /// SDMX version
                        LABELS(string)              /// Column labels: id (default), both, none
                        METAdata(string)            /// Column selection: light (critical columns, default), full (all columns)
                        PAGE_size(integer 100000)   /// Rows per request
                        MAX_retries(integer 3)      /// Retry attempts
                        CLEAR                       /// Replace data in memory
                        VERBOSE                     /// Show progress
                        VALIDATE                    /// Validate inputs against codelists
                        FALLBACK                    /// Try alternative dataflows on 404
                        NOFallback                  /// Disable dataflow fallback
                        NOFILTER                    /// Fetch ALL disaggregations (50-100x more data)
                        NOMETAdata                  /// Show brief summary instead of full metadata
                        NOERROR                     /// Undocumented: suppress printed error messages
                        SUBNATIONAL                 /// Enable access to subnational dataflows
                        DEBUG                       /// Enable maximum debugging output
                        TRACE                       /// Enable Stata trace on network calls
                        FROMFILE(string)            /// Load from CSV file (skip API) for CI testing
                        TOFILE(string)              /// Save API response to CSV for test fixtures
                        SHOWTIER2                   /// Include Tier 2 indicators (officially defined, no data)
                        SHOWTIER3                   /// Include Tier 3 indicators (legacy/undocumented)
                        SHOWALL                     /// Include all tiers (1-3)
                        SHOWORphans                 /// Include orphan indicators (not mapped to dataflows)
                        SHOWLEGacy                  /// Alias for showtier3
                        *                           /// Legacy options
                 ]

    quietly {

                 * Allow caller to suppress printed error messages (undocumented)
                 local noerror_flag 0
                 if ("`noerror'" != "") local noerror_flag 1
        *-----------------------------------------------------------------------
        * Validate filter options: cannot specify both filtervector() AND individual filters
        *-----------------------------------------------------------------------
        if ("`filtervector'" != "") {
            if ("`sex'" != "" | "`age'" != "" | "`wealth'" != "" | "`residence'" != "" | "`maternal_edu'" != "") {
                if (`noerror_flag' == 0) {
                    noi di as error "Cannot specify both {bf:filtervector()} and individual filters (sex, age, wealth, residence, maternal_edu)"
                    noi di as text ""
                    noi di as text "{bf:Choose one approach:}"
                    noi di as text "  {bf:Option 1:} Use individual filters (default, flexible for common cases)"
                    noi di as text "    {stata unicefdata, indicator(CME_MRY0T4) sex(M) age(ALL) clear}"
                    noi di as text ""
                    noi di as text "  {bf:Option 2:} Use pre-constructed SDMX filter key (advanced, for custom dataflows)"
                    noi di as text "    {stata unicefdata, indicator(CME_MRY0T4) filtervector(\".INDICATOR..M\") clear}"
                    noi di as text ""
                }
                error 198
            }
        }
        *-----------------------------------------------------------------------
        * Validate inputs
        *-----------------------------------------------------------------------
        * Preserve the requested indicator list for later formatting steps
        local indicator_requested `indicator'
        
        * Check for bulk download request (indicator(all) OR dataflow without indicator)
        local bulk_download = 0
        
        * Case 1: Explicit indicator(all)
        if (lower("`indicator'") == "all") {
            local bulk_download = 1
            if ("`dataflow'" == "") {
                if (`noerror_flag' == 0) {
                    noi di as err "indicator(all) requires dataflow() to be specified."
                    noi di as text ""
                    noi di as text "{bf:Bulk download examples:}"
                    noi di as text "  {stata unicefdata, dataflow(CME) indicator(all) clear}                  " as text "- Download all CME indicators"
                    noi di as text "  {stata unicefdata, dataflow(NUTRITION) indicator(all) countries(ETH) clear} " as text "- All nutrition data for Ethiopia"
                    noi di as text "  {stata unicefdata, dataflow(EDUCATION) indicator(all) sex(M) clear}      " as text "- All education data for males"
                    noi di as text ""
                    noi di as text "{bf:Performance tip:} Bulk downloads are faster when fetching multiple indicators from same dataflow."
                }
                return scalar success = 0
                return scalar successcode = 198
                error 198
            }
            if ("`verbose'" != "") {
                noi di as text "{bf:Bulk download mode:} Fetching all indicators from dataflow `dataflow'"
            }
        }
        
        * Case 2: Dataflow specified without indicator (implicit bulk download)
        else if ("`indicator'" == "" & "`dataflow'" != "") {
            local bulk_download = 1
            local indicator "all"
            * Warn user about bulk download
            if (`noerror_flag' == 0) {
                noi di as text "{bf:Note:} No indicator specified - bulk download mode activated."
                noi di as text "         Fetching {bf:all} indicators from dataflow `dataflow'."
                noi di as text "         This may take longer than a single indicator request."
                if ("`verbose'" == "") {
                    noi di as text "         Use {bf:verbose} option to see download progress."
                }
                noi di as text ""
            }
        }
        
        if ("`indicator'" == "" ) & ("`dataflow'" == "") {
            if (`noerror_flag' == 0) {
                noi di as err "You must specify either indicator() or dataflow()."
                noi di as text ""
                noi di as text "{bf:Discovery commands:}"
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
            }
            return scalar success = 0
            return scalar successcode = 198
            return local fail_message "Missing indicator() or dataflow()"
            if (`noerror_flag' == 0) exit 198
            return
        }
        
        if ("`clear'" == "") {
            if (_N > 0) {
                if (`noerror_flag' == 0) noi di as err "You must start with an empty dataset; or enable the clear option."
                return scalar success = 0
                return scalar successcode = 4
                return local fail_message "Existing dataset in memory; use clear option"
                if (`noerror_flag' == 0) exit 4
                return
            }
        }
        
        *-----------------------------------------------------------------------
        * Auto-detect dataflow from indicator (needed for schema-aware filters)
        *-----------------------------------------------------------------------
        
        * First try to find metadata location
        local metadata_path ""
        
        * Check if metadata helper is available
        capture which _unicef_list_dataflows
        if (_rc == 0) {
            local ado_path "`r(fn)'"
            * Extract directory containing the helper ado file
            local ado_dir = subinstr("`ado_path'", "\", "/", .)
            local ado_dir = subinstr("`ado_dir'", "_unicef_list_dataflows.ado", "", .)
            local metadata_path "`ado_dir'"
        }
        
        * Fallback to PLUS directory _/
        if ("`metadata_path'" == "") | (!fileexists("`metadata_path'_unicefdata_indicators_metadata.yaml")) {
            local metadata_path "`c(sysdir_plus)'_/"
        }
        
        * Detect the primary dataflow for this indicator
        _unicef_detect_dataflow_yaml "`indicator'" "`metadata_path'"
        local primary_dataflow "`s(dataflow)'"

        if ("`verbose'" != "") {
            noi di as text "Auto-detected dataflow '" as result "`primary_dataflow'" as text "' for indicator `indicator'"
        }

        *-----------------------------------------------------------------------
        * Get disaggregations_with_totals from metadata (for smart filtering)
        *-----------------------------------------------------------------------
        * This tells us which dimensions have _T totals and which don't
        * Dimensions NOT in this list (e.g., DISABILITY_STATUS) need special handling
        local disagg_totals ""
        capture {
            _unicef_get_disagg_totals, indicator("`indicator'") metadatapath("`metadata_path'") `verbose'
            local disagg_totals = r(disagg_totals)
        }
        if ("`verbose'" != "" & "`disagg_totals'" != "") {
            noi di as text "  disaggregations_with_totals: " as result "`disagg_totals'"
        }

        *-----------------------------------------------------------------------
        * Handle option aliases (user-friendly alternative names)
        *-----------------------------------------------------------------------
        * wealth_quintile() is an alias for wealth() - merge if user used long form
        if ("`wealth_quintile'" != "" & "`wealth'" == "") {
            local wealth "`wealth_quintile'"
        }
        else if ("`wealth_quintile'" != "" & "`wealth'" != "") {
            noi di as error "Cannot specify both wealth() and wealth_quintile() options"
            exit 198
        }

        * Track whether user explicitly provided each filter (before normalization)
        local user_spec_sex = ("`sex'" != "")
        local user_spec_age = ("`age'" != "")
        local user_spec_wealth = ("`wealth'" != "")
        local user_spec_residence = ("`residence'" != "")
        local user_spec_matedu = ("`maternal_edu'" != "")

        *-----------------------------------------------------------------------
        * Normalize filter values early (ALL -> empty, _T/T -> _T, etc.)
        *-----------------------------------------------------------------------
        * This ensures consistent filter handling throughout

        foreach filt in sex age wealth residence maternal_edu {
            local filt_val = "``filt''"
            if ("`filt_val'" != "") {
                local filt_lower = lower("`filt_val'")
                if (strpos(" `filt_lower' ", " all ") > 0 | "`filt_lower'" == "all") {
                    local `filt' ""
                }
                else if ("`filt_lower'" == "_t" | "`filt_lower'" == "t") {
                    local `filt' "_T"
                }
                else {
                    * Convert spaces to plus for multiple values
                    local `filt' = subinstr("``filt''", " ", "+", .)
                }
            }
        }

        *-----------------------------------------------------------------------
        * Schema-aware filter construction (Stage 1 of 3)
        *-----------------------------------------------------------------------
        * THREE-STAGE DEPENDENCY:
        *   Stage 1: Query schema → get filter_dim_names (available dimensions)
        *   Stage 2: Apply default totals → uses filter_dim_names to check existence
        *   Stage 3: Build filter_option → uses normalized filter values from Stage 2
        *
        * Query dataflow schema to extract actual dimensions
        * Skip: REF_AREA, INDICATOR, TIME_PERIOD (handled separately)
        * Include: SEX, AGE, WEALTH_QUINTILE, RESIDENCE, MATERNAL_EDU_LVL, etc.

        local filter_vector ""
        local filter_dimensions_detected = 0
        local filter_dim_names ""
        capture {
            __unicef_get_indicator_filters, dataflow("`primary_dataflow'") verbose
            if _rc == 0 {
                local filter_dimensions_detected = r(filter_dimensions)
                local filter_dim_names = lower(r(filter_eligible_dimensions))
            }
        }

        *-----------------------------------------------------------------------
        * Determine nofilter state early (needed for default totals logic)
        *-----------------------------------------------------------------------
        local nofilter_option ""
        if ("`nofilter'" != "") {
            local nofilter_option "nofilter"
        }

        *-----------------------------------------------------------------------
        * Apply default totals when user did not supply a filter
        *-----------------------------------------------------------------------
        * Only set defaults when not using nofilter() and no custom filtervector()
        * NOTE: This must come BEFORE building filter_option, so that default
        *       values like sex="_T" are included in the API request.
        * Uses disaggregations_with_totals from metadata to determine which
        * dimensions have _T totals. Only default to _T for those dimensions.
        if ("`nofilter_option'" == "" & "`filtervector'" == "") {
            foreach dim in sex age wealth residence maternal_edu {
                local dimflag 0
                if ("`dim'" == "sex") local dimflag = `user_spec_sex'
                else if ("`dim'" == "age") local dimflag = `user_spec_age'
                else if ("`dim'" == "wealth") local dimflag = `user_spec_wealth'
                else if ("`dim'" == "residence") local dimflag = `user_spec_residence'
                else local dimflag = `user_spec_matedu'
                * Map filter name to YAML dimension name for disagg_totals lookup
                * NOTE: yaml_dim_name uses uppercase SDMX names (for disagg_totals matching)
                *       yaml_dim_lower uses lowercase (for filter_dim_names matching)
                local yaml_dim_name ""
                if ("`dim'" == "sex") local yaml_dim_name "SEX"
                else if ("`dim'" == "age") local yaml_dim_name "AGE"
                else if ("`dim'" == "wealth") local yaml_dim_name "WEALTH_QUINTILE"
                else if ("`dim'" == "residence") local yaml_dim_name "RESIDENCE"
                else if ("`dim'" == "maternal_edu") local yaml_dim_name "MATERNAL_EDU_LVL"
                local yaml_dim_lower = lower("`yaml_dim_name'")

                if (`dimflag' == 0) {
                    * Only default to totals if dimension exists in schema
                    * Use full SDMX dimension name (lowercased) for matching
                    * e.g., "wealth_quintile" not "wealth" to match filter_dim_names
                    if (strpos(" `filter_dim_names' ", " `yaml_dim_lower' ") > 0) {
                        * Check if dimension is in disaggregations_with_totals
                        * If yes: default to _T (dimension has totals)
                        * If no: leave empty (dimension doesn't have _T, e.g., DISABILITY_STATUS)
                        local has_total = 0
                        if ("`disagg_totals'" == "") {
                            * No metadata available - use legacy behavior (default to _T)
                            local has_total = 1
                        }
                        else if (strpos(" `disagg_totals' ", " `yaml_dim_name' ") > 0) {
                            * Dimension is in disaggregations_with_totals
                            local has_total = 1
                        }

                        if (`has_total' == 1) {
                            * Special case: NUTRITION dataflow uses Y0T4 for age, not _T
                            * The AGE dimension in NUTRITION has specific age groups (Y0T4, M0T59, etc.)
                            * but no _T total. Y0T4 (0-4 years) is the standard for under-5 data.
                            local use_special_default = 0
                            if ("`dim'" == "age") {
                                local df_upper = upper("`primary_dataflow'")
                                if ("`df_upper'" == "NUTRITION") {
                                    local use_special_default = 1
                                    local `dim' "Y0T4"
                                    noi di as text "{bf:Note:} NUTRITION dataflow uses age=Y0T4 (0-4 years) as default instead of _T"
                                }
                            }
                            if (`use_special_default' == 0) {
                                local `dim' "_T"
                            }
                        }
                        else if ("`verbose'" != "") {
                            noi di as text "  Note: `dim' not in disaggregations_with_totals, not defaulting to _T"
                        }
                    }
                }
            }
        }

        if ("`verbose'" != "") {
            noi di as text "  Normalized filters: sex='" as result "`sex'" as text "', age='" as result "`age'" as text "', wealth='" as result "`wealth'" as text "'"
        }

        *-----------------------------------------------------------------------
        * Build reusable options for get_sdmx
        *-----------------------------------------------------------------------
        * nofilter: pass through directly
        * filter_option: prefer user-supplied filtervector(); otherwise, build a
        * schema-aware filtervector using normalized filters and detected dataflow
        * NOTE: Default totals have already been applied above, so filter values
        *       like sex="_T" are now set correctly.
        *-----------------------------------------------------------------------

        local filter_option ""
        if ("`nofilter_option'" == "") {
            if ("`filtervector'" != "") {
                local filter_option `"filtervector("`filtervector'")"'
            }
            else {
                * Use explicit dataflow if provided; otherwise fall back to detected
                local schema_dataflow "`dataflow'"
                if ("`schema_dataflow'" == "") {
                    local schema_dataflow "`primary_dataflow'"
                }
                if ("`schema_dataflow'" != "") {
                    local schema_opts ""
                    if (`bulk_download' == 1) local schema_opts "`schema_opts' bulk"
                    _unicef_build_schema_key "`indicator'" "`schema_dataflow'" "`metadata_path'" ///
                        sex("`sex'") age("`age'") wealth("`wealth'") residence("`residence'") maternal_edu("`maternal_edu'") ///
                        `schema_opts' `verbose'
                    local schema_key = r(key)
                    local filter_option `"filtervector("`schema_key'")"'
                }
            }
        }

        * Countries option reused across get_sdmx calls (normalize spaces to plus)
        local countries_option ""
        if ("`countries'" != "") {
            local countries_sdmx = subinstr("`countries'", " ", "+", .)
            local countries_option "countries(`countries_sdmx')"
        }

        * Labels option: default to "id" for cross-platform consistency
        local labels_option ""
        if ("`labels'" != "") {
            local labels_option "labels(`labels')"
        }

        *-----------------------------------------------------------------------
        * Note: The SDMX key with proper filter construction is now built in
        * _unicef_build_schema_key, which receives the normalized filter values.
        * Filter values are already normalized at this point:
        *   - ALL → empty string (fetch all from API)
        *   - _T/T → _T (fetch totals only)
        *   - space-separated codes → plus-separated ("M+F")
        *-----------------------------------------------------------------------
        
        if ("`verbose'" != "") {
            noi di as text "  Filter option for get_sdmx: " as result `"`filter_option'"'
            noi di as text "  Nofilter option: " as result "`nofilter_option'"
        }
        
        *-----------------------------------------------------------------------
        * Build filter vector for get_sdmx (dimension order: sex age wealth residence maternal_edu)
        *-----------------------------------------------------------------------
        
        local filter_vector "`sex' `age' `wealth' `residence' `maternal_edu'"
        
        if ("`verbose'" != "") {
            noi di as text "Filter vector: " as result "`filter_vector'"
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
        * NOTE: metadata_path should already be set from lines 429-443
        * Do NOT reset it here - that was causing dimension check bugs
        *-----------------------------------------------------------------------
        
        * Fallback: if metadata_path wasn't set earlier, try to find it now
        if ("`metadata_path'" == "") | (!fileexists("`metadata_path'_unicefdata_indicators_metadata.yaml")) {
            capture which _unicef_list_dataflows
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                local ado_dir = subinstr("`ado_path'", "\", "/", .)
                local ado_dir = subinstr("`ado_dir'", "_unicef_list_dataflows.ado", "", .)
                local metadata_path "`ado_dir'"
            }
            * Ultimate fallback to PLUS directory _/
            if ("`metadata_path'" == "") | (!fileexists("`metadata_path'_unicefdata_indicators_metadata.yaml")) {
                local metadata_path "`c(sysdir_plus)'_/"
            }
        }
        
        * Check for multiple indicators (space-separated)
        local n_indicators : word count `indicator'
        
        * Skip multi-indicator processing if bulk download
        if (`bulk_download' == 1) {
            local n_indicators = 1
        }
        
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

                * Get disaggregations_with_totals for this indicator
                local ind_disagg_totals ""
                capture {
                    _unicef_get_disagg_totals, indicator("`ind'") metadatapath("`metadata_path'")
                    local ind_disagg_totals = r(disagg_totals)
                }
                * Update disagg_totals for post-fetch filtering
                local disagg_totals "`ind_disagg_totals'"
                
                * Check for subnational dataflows and warn/block accordingly
                * Patterns: *_SUBNAT, *_SUB, *_SUBNATIONAL, *_SUBNAT_* (country-specific)
                local is_subnat = 0
                if (strmatch(upper("`ind_dataflow'"), "*_SUBNAT") | strmatch(upper("`ind_dataflow'"), "*_SUB") | strmatch(upper("`ind_dataflow'"), "*_SUBNATIONAL") | strmatch(upper("`ind_dataflow'"), "*_SUBNAT_*")) {
                    local is_subnat = 1
                }
                
                if (`is_subnat' == 1) {
                    if ("`subnational'" == "") {
                        * Block: skip this indicator
                        noi di as text "  {bf:⚠} Skipping `ind': subnational dataflow `ind_dataflow' requires {bf:subnational} option"
                        continue
                    }
                    else {
                        * Warn: proceeding with subnational data
                        noi di as text "  {bf:⚠} `ind' uses subnational dataflow `ind_dataflow' (large dataset)"
                    }
                }
                
                * Build URL key using schema-aware dimension construction with user filters
                * Extract dataflow schema and build key with explicit dimension filters
                * Pass normalized filter values (empty string for ALL, _T for total, etc.)
                _unicef_build_schema_key "`ind'" "`ind_dataflow'" "`metadata_path'" ///
                    sex("`sex'") age("`age'") wealth("`wealth'") residence("`residence'") maternal_edu("`maternal_edu'") ///
                    `nofilter' `verbose'
                local ind_key = r(key)
                local ind_rel_path "data/UNICEF,`ind_dataflow',`version'/`ind_key'"
                
                local ind_query "format=csv&labels=id"
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
                local last_rc 0
                forvalues attempt = 1/`max_retries' {
                    capture copy "`ind_url'" "`ind_tempdata'", replace public
                    local last_rc = _rc
                    if (_rc == 0) {
                        local ind_success 1
                        continue, break
                    }
                    if ("`verbose'" != "" & `attempt' < `max_retries') {
                        noi di as text "  Network attempt `attempt'/`max_retries' failed (r=" _rc "), retrying..."
                    }
                    sleep 1000
                }
                
                * Report final network failure with details
                if (`ind_success' == 0 & "`verbose'" != "") {
                    noi di as error "  ✗ Network error after `max_retries' attempts (r=`last_rc')"
                    if (`last_rc' == 677) {
                        noi di as text "    Error 677 = 'could not connect to server'"
                        noi di as text "    Possible causes: Firewall, SSL/TLS, proxy, or network timeout"
                        noi di as text "    Run: do test_stata_network.do for diagnostics"
                    }
                    noi di as text "    URL: `ind_url'"
                }
                
                * Try fallback if primary failed - use direct get_sdmx loop
                if (`ind_success' == 0) {
                    * Get list of fallback dataflows from YAML metadata
                    _get_dataflow_direct `ind'
                    local ind_fallback_dataflows "`r(dataflows)'"
                    
                    if ("`ind_fallback_dataflows'" == "") {
                        local ind_fallback_dataflows "GLOBAL_DATAFLOW"
                    }
                    
                    * Try each dataflow directly with get_sdmx
                    local fallback_attempt 0
                    foreach ind_fallback_df of local ind_fallback_dataflows {
                        local fallback_attempt = `fallback_attempt' + 1
                        
                        if ("`verbose'" != "") {
                            noi di as text "  Fallback attempt `fallback_attempt' for `ind': trying dataflow `ind_fallback_df'..."
                        }
                        
                        * Build dataflow-specific filtervector for this indicator (unless user supplied one)
                        local ind_filter_option ""
                        if ("`nofilter_option'" == "") {
                            if ("`filtervector'" != "") {
                                local ind_filter_option `"filtervector("`filtervector'")"'
                            }
                            else {
                                _unicef_build_schema_key "`ind'" "`ind_fallback_df'" "`metadata_path'" ///
                                    sex("`sex'") age("`age'") wealth("`wealth'") residence("`residence'") maternal_edu("`maternal_edu'") ///
                                    `verbose'
                                local ind_schema_key = r(key)
                                local ind_filter_option `"filtervector("`ind_schema_key'")"'
                            }
                        }

                        * Call get_sdmx directly (filter is now built into the schema key)
                        capture noisily get_sdmx, ///
                            indicator("`ind'") ///
                            dataflow("`ind_fallback_df'") ///
                            `countries_option' ///
                            `ind_filter_option' ///
                            start_period("`start_year'") ///
                            end_period("`end_year'") ///
                            `nofilter_option' ///
                            `labels_option' ///
                            `wide' ///
                            `verbose' ///
                            `debug' ///
                            `trace' ///
                            `clear'
                        
                        if (_rc == 0 & _N > 0) {
                            local ind_success = 1
                            if ("`verbose'" != "") {
                                noi di as text "✓ Successfully fetched `ind' from fallback dataflow: " as result "`ind_fallback_df'"
                            }
                            
                            * Data is now in memory from get_sdmx
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
                            continue, break
                        }
                        else {
                            if ("`verbose'" != "") {
                                noi di as text "  Fallback dataflow `ind_fallback_df' failed or returned no data for `ind'"
                            }
                        }
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
                if (`noerror_flag' == 0) noi di as err "Could not fetch data for any of the specified indicators."
                return scalar success = 0
                return scalar successcode = 677
                return local fail_message "Could not fetch data for any of the specified indicators"
                if (`noerror_flag' == 0) exit 677
                return
            }
            
            * Skip the single-indicator fetch logic below
            local skip_single_fetch 1
        }
        else {
            * Single indicator - use normal flow
            local skip_single_fetch 0
            
            if ("`dataflow'" == "") & ("`indicator'" != "") {
                * Detect primary dataflow from indicator metadata
                _unicef_indicator_info, indicator("`indicator'") brief
                local detected_primary = upper("`r(dataflow)'")
                * Extract first dataflow (primary) from comma-separated list
                local first_dataflow = word("`detected_primary'", 1)
                * Remove trailing comma if present (word() keeps it)
                local first_dataflow = subinstr("`first_dataflow'", ",", "", .)
                local dataflow "`first_dataflow'"
                local all_dataflows "`r(dataflow)'"
                local indicator_name "`r(name)'"
                * Always show auto-detected dataflow (matches R/Python behavior)
                noi di as text "Auto-detected dataflow '" as result "`dataflow'" as text "'"
                if ("`verbose'" != "" & "`indicator_name'" != "") {
                    noi di as text "Indicator: " as result "`indicator_name'"
                }
            }
            
            *-------------------------------------------------------------------
            * Check for subnational dataflows and warn/block accordingly
            *-------------------------------------------------------------------
            
            if ("`dataflow'" != "") {
                * Check if this is a subnational dataflow
                * Patterns: *_SUBNAT, *_SUB, *_SUBNATIONAL, *_SUBNAT_* (country-specific)
                local is_subnat = 0
                if (strmatch(upper("`dataflow'"), "*_SUBNAT") | strmatch(upper("`dataflow'"), "*_SUB") | strmatch(upper("`dataflow'"), "*_SUBNATIONAL") | strmatch(upper("`dataflow'"), "*_SUBNAT_*")) {
                    local is_subnat = 1
                }
                
                if (`is_subnat' == 1) {
                    if ("`subnational'" == "") {
                        * Block: subnational option not specified
                        if (`noerror_flag' == 0) {
                            noi di as err ""
                            noi di as err "{p 4 4 2}Dataflow '{bf:`dataflow'}' contains subnational data.{p_end}"
                            noi di as err "{p 4 4 2}Subnational dataflows are restricted by default due to large data volumes.{p_end}"
                            noi di as text ""
                            noi di as text "{p 4 4 2}To access this dataflow, add the {bf:subnational} option:{p_end}"
                            noi di as text ""
                            noi di as text `"  {stata unicefdata, indicator(`indicator') subnational clear}"'
                            noi di as text ""
                        }
                        return scalar success = 0
                        return scalar successcode = 198
                        return local fail_message "Subnational dataflow requires subnational option"
                        if (`noerror_flag' == 0) exit 198
                        return
                    }
                    else {
                        * Warn: subnational option specified, proceed with warning
                        noi di as text ""
                        noi di as result "{bf:⚠ Subnational data warning:}"
                        noi di as text "{p 4 4 2}Dataflow '{bf:`dataflow'}' contains subnational data.{p_end}"
                        noi di as text "{p 4 4 2}These datasets can be very large and may take considerable time to download.{p_end}"
                        noi di as text ""
                    }
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
                    * Use simple string matching for robustness
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
                            * Check if we've left dimensions section (next top-level key)
                            local first_char = substr(`"`line'"', 1, 1)
                            if ("`first_char'" != " " & "`first_char'" != "-" & "`first_char'" != "" & regexm(`"`line'"', "^[a-z_]+:")) {
                                local in_dimensions = 0
                            }
                            else {
                                * Simple string matching for dimension IDs (more robust than regex)
                                if (strpos("`trimmed_line'", "id: SEX") > 0) local has_sex = 1
                                if (strpos("`trimmed_line'", "id: AGE") > 0) local has_age = 1
                                if (strpos("`trimmed_line'", "id: WEALTH_QUINTILE") > 0) local has_wealth = 1
                                if (strpos("`trimmed_line'", "id: RESIDENCE") > 0) local has_residence = 1
                                if (strpos("`trimmed_line'", "id: MATERNAL_EDU_LVL") > 0 | strpos("`trimmed_line'", "id: MOTHER_EDUCATION") > 0) local has_maternal_edu = 1
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
        
        *-----------------------------------------------------------------------
        * FROMFILE: Load from CSV file instead of API (for CI/offline testing)
        *-----------------------------------------------------------------------
        
        if ("`fromfile'" != "") {
            * Validate file exists
            capture confirm file "`fromfile'"
            if (_rc != 0) {
                noi di as err "fromfile() error: File not found: `fromfile'"
                return scalar success = 0
                return scalar successcode = 601
                return local fail_message "File not found: `fromfile'"
                exit 601
            }
            
            noi di as text "Loading from file: " as result "`fromfile'" as text " (skipping API)"
            clear
            capture import delimited "`fromfile'", clear varnames(1) stringcols(_all) encoding("utf-8")
            if _rc != 0 {
                * Fallback: Try without encoding (for older Stata versions or non-UTF-8 files)
                capture import delimited "`fromfile'", clear varnames(1) stringcols(_all)
            }
            
            if (_N == 0) {
                noi di as text "No data in file."
                return scalar success = 0
                return scalar successcode = 0
                return local fail_message "No data in file"
                return
            }
            
            local obs_count = _N
            noi di as text "Loaded " as result `obs_count' as text " observations from file."
            
            * Skip all API fetch logic - data is already in memory
            local success 1
        }
        else {
        
        *-----------------------------------------------------------------------
        * Primary fetch using get_sdmx (with filter vector)
        *-----------------------------------------------------------------------
        
        set checksum off
        
        * Determine if we should use fallback
        local use_fallback = ("`fallback'" != "" | ("`nofallback'" == "" & "`indicator'" != ""))
        local fallback_used 0  // Track if fallback successfully provided data
        
        * Show fetching message (matches R/Python behavior)
        noi di as text "Fetching page 1..."
        
        * Clear dataset before fetching (get_sdmx doesn't have clear option)
        clear
        
        * Try primary dataflow with get_sdmx (includes filter vector in URL)
        local success 0
        local full_url ""
        
        * Build get_sdmx call with conditional year parameters
        local year_opts ""
        if (`start_year' > 0) local year_opts "`year_opts' start_period(`start_year')"
        if (`end_year' > 0) local year_opts "`year_opts' end_period(`end_year')"

        * Ensure we always have a dataflow for primary fetch
        local dataflow_for_fetch "`dataflow'"
        if ("`dataflow_for_fetch'" == "") local dataflow_for_fetch "`primary_dataflow'"

        * Recompute filter option for the primary dataflow if needed
        local filter_option_primary "`filter_option'"
        local schema_key_primary ""
        if ("`nofilter_option'" == "" & "`filtervector'" == "") {
            if ("`dataflow_for_fetch'" != "") {
                * When using a specific indicator with a filtered dataflow,
                * only filter disaggregation dimensions (sex, age, wealth, etc)
                * NOT the indicator dimension - it's already in the URL
                _unicef_build_schema_key "`indicator'" "`dataflow_for_fetch'" "`metadata_path'" ///
                    sex("`sex'") age("`age'") wealth("`wealth'") residence("`residence'") maternal_edu("`maternal_edu'") ///
                    filterdisagg ///
                    `verbose'
                local schema_key_primary = r(key)
                local filter_option_primary filtervector("`schema_key_primary'")
            }
        }
        
        * Construct URL for documentation (what will be executed)
        if ("`dataflow_for_fetch'" != "") {
            local version_str = cond("`version'" == "", "1.0", "`version'")
            local key_str = cond("`schema_key_primary'" != "", "`schema_key_primary'", "...")
            local full_url "`base_url'/data/UNICEF,`dataflow_for_fetch',`version_str'/`key_str'?..."
        }
        
        * Do NOT pass wide option to get_sdmx - unicefdata will do its own reshape
        * This avoids issues with csv-ts format creating wrong column names
        capture noisily get_sdmx, ///
            indicator("`indicator'") ///
            dataflow("`dataflow_for_fetch'") ///
            `countries_option' ///
            `filter_option_primary' ///
            `year_opts' ///
            `nofilter_option' ///
            `labels_option' ///
            `clear' ///
            `verbose' ///
            `debug' ///
            `trace'
        
        if (_rc == 0 & _N > 0) {
            local success 1
            local dataflow "`dataflow_for_fetch'"
            if ("`verbose'" != "") {
                noi di as text "✓ Successfully fetched from primary dataflow: " as result "`dataflow_for_fetch'"
            }
        }
        else {
            if ("`verbose'" != "") {
                noi di as text "Primary dataflow `dataflow' failed or returned no data"
            }
        }
        
        * If primary download failed and fallback is enabled, try alternatives
        if (`success' == 0 & `use_fallback' == 1 & "`indicator'" != "") {
            if ("`verbose'" != "") {
                noi di as text "Primary dataflow failed, trying alternatives..."
            }
            
            * Use all detected dataflows, skip the primary (already tried above)
            local fallback_dataflows "`all_dataflows'"
            * Normalize delimiters so foreach gets clean tokens
            local fallback_dataflows : subinstr local fallback_dataflows "," " " , all
            
            * If no dataflows detected, add defaults
            if ("`fallback_dataflows'" == "") {
                local fallback_dataflows "GLOBAL_DATAFLOW"
            }
            
            * Try each dataflow directly with get_sdmx
            local fallback_attempt 0
            local fallback_year_opts "`year_opts'"
            foreach fallback_df of local fallback_dataflows {
                * Skip the primary dataflow (already tried)
                if ("`fallback_df'" == "`dataflow_for_fetch'") continue
                
                local fallback_attempt = `fallback_attempt' + 1
                
                if ("`verbose'" != "") {
                    noi di as text "  Fallback attempt `fallback_attempt': trying dataflow `fallback_df'..."
                }
                
                * Build filter option for the fallback dataflow (unless user supplied one)
                local filter_option_fb ""
                if ("`nofilter_option'" == "") {
                    if ("`filtervector'" != "") {
                        local filter_option_fb filtervector("`filtervector'")
                    }
                    else {
                        _unicef_build_schema_key "`indicator'" "`fallback_df'" "`metadata_path'" ///
                            sex("`sex'") age("`age'") wealth("`wealth'") residence("`residence'") maternal_edu("`maternal_edu'") ///
                            `verbose'
                        local schema_key_fb = r(key)
                        local filter_option_fb filtervector("`schema_key_fb'")
                    }
                }

                * Call get_sdmx directly with filter vector
                capture noisily get_sdmx, ///
                    indicator("`indicator'") ///
                    dataflow("`fallback_df'") ///
                    `countries_option' ///
                    `filter_option_fb' ///
                    `fallback_year_opts' ///
                    `nofilter_option' ///
                    `labels_option' ///
                    `wide' ///
                    `verbose' ///
                    `clear' ///
                    `debug' ///
                    `trace'
                
                if (_rc == 0 & _N > 0) {
                    local success 1
                    local dataflow "`fallback_df'"
                    local fallback_used 1
                    if ("`verbose'" != "") {
                        noi di as text "✓ Successfully fetched from fallback dataflow: " as result "`fallback_df'"
                    }
                    continue, break
                }
                else {
                    if ("`verbose'" != "") {
                        noi di as text "  Fallback dataflow `fallback_df' failed or returned no data"
                    }
                }
            }
        }
        
        if (`success' == 0) {
            if (`noerror_flag' == 0) {
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
            }
            * Return structured failure info for callers that capture this program
            return scalar success = 0
            return scalar successcode = 677
            return local fail_message "Could not download data from UNICEF SDMX API"
            if (`noerror_flag' == 0) exit 677
            return
        }
        
        *-----------------------------------------------------------------------
        * TOFILE: Save raw API response to CSV for test fixtures
        *-----------------------------------------------------------------------
        
        if ("`tofile'" != "") {
            noi di as text "Saving to file: " as result "`tofile'"
            export delimited "`tofile'", replace encoding("utf-8")
            noi di as text "Saved " as result _N as text " observations to " as result "`tofile'"
        }
        
        *-----------------------------------------------------------------------
        * Note: Data is already in memory from get_sdmx (which uses insheet)
        * The previous import delimited block using `tempdata' was removed
        * because get_sdmx loads data directly into memory.
        *-----------------------------------------------------------------------
        
        } // end else (API fetch path)
        
        } // end skip_single_fetch
        
        local obs_count = _N
        if ("`verbose'" != "") {
            noi di as text "Downloaded " as result `obs_count' as text " observations."
        }
        
        if (`obs_count' == 0) {
            noi di as text "No data found for the specified query."
            return scalar success = 0
            return scalar successcode = 0
            return local fail_message "No data found for the specified query"
            * Note: successcode=0 means no error, just empty result
            return
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
                local renames "`renames' INDICATOR:indicator"
                local renames "`renames' ref_area:iso3 REF_AREA:iso3"
                local renames "`renames' time_period:period TIME_PERIOD:period"
                local renames "`renames' obs_value:value OBS_VALUE:value"
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
            
            * --- Add country names from dataset (efficient, no API overhead) ---
            quietly {
                capture confirm variable iso3
                if (_rc == 0) {
                    * Determine metadata path
                    local meta_path "`c(sysdir_plus)'_"
                    
                    * Check if country dataset exists
                    capture confirm file "`meta_path'/_unicefdata_countries.dta"
                    if (_rc == 0) {
                        * Use frames for efficient merge (Stata 16+) or traditional merge
                        local stata_version = c(stata_version)
                        if (`stata_version' >= 16) {
                            * Frame-based merge (Stata 16+)
                            frame create countries
                            frame countries: use "`meta_path'/_unicefdata_countries.dta", clear
                            frlink m:1 iso3, frame(countries)
                            frget country, from(countries)
                            frame drop countries
                            drop countries
                        }
                        else {
                            * Traditional merge for Stata 11-15
                            tempfile original_data
                            save `original_data', replace
                            use "`meta_path'/_unicefdata_countries.dta", clear
                            tempfile country_lookup
                            save `country_lookup', replace
                            use `original_data', clear
                            merge m:1 iso3 using `country_lookup', keep(master match) nogen
                        }
                        * Move country to appear after iso3 and add label
                        capture confirm variable country
                        if (_rc == 0) {
                            order iso3 country
                            label variable country "Country name"
                        }
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

            *-------------------------------------------------------------------
            * DISABILITY_STATUS handling (metadata-driven filtering)
            *-------------------------------------------------------------------
            * If DISABILITY_STATUS exists but is NOT in disaggregations_with_totals,
            * it means this dimension has no _T total. Filter to PD (baseline:
            * persons without disabilities) to match Python/R behavior.
            capture confirm variable disability_status
            if (_rc == 0) {
                * Check if DISABILITY_STATUS is in disaggregations_with_totals
                local dis_has_total = 0
                if ("`disagg_totals'" != "") {
                    if (strpos(" `disagg_totals' ", " DISABILITY_STATUS ") > 0) {
                        local dis_has_total = 1
                    }
                }

                if (`dis_has_total' == 0) {
                    * DISABILITY_STATUS doesn't have _T total
                    * Check if PD (persons without disabilities) exists
                    quietly count if disability_status == "PD"
                    local pd_count = r(N)
                    quietly count if disability_status == "_T"
                    local t_count = r(N)

                    if (`pd_count' > 0 & `t_count' == 0) {
                        * Filter to PD (baseline population)
                        keep if disability_status == "PD"
                        if ("`verbose'" != "") {
                            noi di as text "  disability_status: filtered to PD (no _T total available)"
                        }
                    }
                    else if (`t_count' > 0) {
                        * _T exists - filter to it
                        keep if disability_status == "_T"
                        if ("`verbose'" != "") {
                            noi di as text "  disability_status: filtered to _T"
                        }
                    }
                }
                else {
                    * DISABILITY_STATUS has _T total - filter to it if available
                    quietly count if disability_status == "_T"
                    if (r(N) > 0) {
                        keep if disability_status == "_T"
                        if ("`verbose'" != "") {
                            noi di as text "  disability_status: filtered to _T (in disaggregations_with_totals)"
                        }
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
        * FIXED in v1.7.2: Include disaggregation dimensions in grouping so that
        * latest keeps one observation per country-indicator-disaggregation combo,
        * not just per country-indicator (which would drop all but one disagg value)
        *-----------------------------------------------------------------------

        if ("`latest'" != "") {
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable value
            if (_rc == 0) {
                * Keep only non-missing values
                drop if missing(value)

                * Build grouping variables: start with iso3
                local group_vars "iso3"

                * Add indicator if present
                capture confirm variable indicator
                if (_rc == 0) local group_vars "`group_vars' indicator"

                * Add disaggregation dimensions if present
                * This ensures latest keeps one obs per unique disaggregation combo
                * NOTE: Use SHORT variable names (wealth, matedu) as they exist at this point
                * They get renamed to long names (wealth_quintile, maternal_edu) later
                capture confirm variable sex
                if (_rc == 0) local group_vars "`group_vars' sex"

                capture confirm variable wealth
                if (_rc == 0) local group_vars "`group_vars' wealth"

                capture confirm variable age
                if (_rc == 0) local group_vars "`group_vars' age"

                capture confirm variable residence
                if (_rc == 0) local group_vars "`group_vars' residence"

                capture confirm variable matedu
                if (_rc == 0) local group_vars "`group_vars' matedu"

                * Get latest period for each group
                bysort `group_vars' (period): keep if _n == _N
            }
        }
        
        *-----------------------------------------------------------------------
        * Apply MRV (Most Recent Values) filter
        * FIXED in v2.0.3: Include disaggregation dimensions in grouping
        *-----------------------------------------------------------------------

        if (`mrv' > 0) {
            capture confirm variable iso3
            capture confirm variable period
            if (_rc == 0) {
                * Build grouping variables: start with iso3
                local mrv_group_vars "iso3"

                * Add indicator if present
                capture confirm variable indicator
                if (_rc == 0) local mrv_group_vars "`mrv_group_vars' indicator"

                * Add disaggregation dimensions if present
                * NOTE: Use SHORT variable names (wealth, matedu) as they exist at this point
                capture confirm variable sex
                if (_rc == 0) local mrv_group_vars "`mrv_group_vars' sex"

                capture confirm variable wealth
                if (_rc == 0) local mrv_group_vars "`mrv_group_vars' wealth"

                capture confirm variable age
                if (_rc == 0) local mrv_group_vars "`mrv_group_vars' age"

                capture confirm variable residence
                if (_rc == 0) local mrv_group_vars "`mrv_group_vars' residence"

                capture confirm variable matedu
                if (_rc == 0) local mrv_group_vars "`mrv_group_vars' matedu"

                * Sort by group and descending period, then rank within group
                gsort `mrv_group_vars' -period
                by `mrv_group_vars': gen _rank = _n
                keep if _rank <= `mrv'
                drop _rank
                sort `mrv_group_vars' period
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
            local regions_file ""
            capture noisily findfile "_unicefdata_regions.yaml"
            if (_rc == 0) local regions_file "`r(fn)'"

            if ("`regions_file'" == "") {
                foreach candidate in ///
                    "`c(pwd)'/metadata/current/_unicefdata_regions.yaml" ///
                    "`c(pwd)'/stata/src/_/_unicefdata_regions.yaml" ///
                    "`:sysdir PLUS'_/_unicefdata_regions.yaml" {
                    if (fileexists("`candidate'")) {
                        local regions_file "`candidate'"
                        continue, break
                    }
                }
            }

            local aggregates ""
            if ("`regions_file'" != "") {
                tempname fh
                file open `fh' using "`regions_file'", read text
                file read `fh' line
                local in_regions 0
                while (r(eof)==0) {
                    local trimmed = strtrim("`line'")
                    * Check if we're entering the regions section
                    if (regexm("`trimmed'", "^regions:")) {
                        local in_regions 1
                    }
                    * If we're in regions section, extract region codes
                    else if (`in_regions' == 1) {
                        * Check for end of regions section (unindented key or blank line)
                        if ("`trimmed'" == "" | (substr("`line'", 1, 1) != " " & regexm("`trimmed'", "^[a-z_]+:"))) {
                            local in_regions 0
                        }
                        * Extract region code (e.g., "  CODE: 'Region Name'" -> CODE)
                        else if (regexm("`trimmed'", "^([A-Za-z0-9_]+):")) {
                            local code = regexs(1)
                            local aggregates "`aggregates' `code'"
                        }
                    }
                    file read `fh' line
                }
                file close `fh'
            }

            capture drop geo_type
            gen byte geo_type = 0
            if ("`aggregates'" != "") {
                foreach code of local aggregates {
                    replace geo_type = 1 if iso3 == "`code'"
                }
            }
            capture label drop geo_type_lbl
            label define geo_type_lbl 0 "country" 1 "aggregate"
            label values geo_type geo_type_lbl
            label variable geo_type "Geographic type (1=aggregate, 0=country)"
            
            * Reorder geo_type before year columns (for wide format)
            * Find all yr#### variables and move geo_type before them
            capture {
                quietly ds yr*
                if "`r(varlist)'" != "" {
                    local first_yr : word 1 of `r(varlist)'
                    order geo_type, before(`first_yr')
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Format output (long/wide/wide_indicators) - aligned with R/Python
        *-----------------------------------------------------------------------
        
        * Check for conflicting wide format options
        * Note: wide option uses API csv-ts format (years as columns: yr2015, yr2016, etc.)
        * wide_indicators and wide_attributes use Stata reshape (traditional unicefdata behavior)
        if ("`wide'" != "" & ("`wide_indicators'" != "" | "`wide_attributes'" != "")) {
            noi di as error "Error: wide cannot be combined with wide_indicators or wide_attributes."
            noi di as error "Choose: wide (API csv-ts format) OR wide_indicators/wide_attributes (Stata reshape)"
            error 198
        }

        * Check for conflicting options: cannot use wide_attributes and wide_indicators together
        if ("`wide_attributes'" != "" & "`wide_indicators'" != "") {
            noi di as error "Error: wide_attributes and wide_indicators cannot be used together."
            noi di as error "Choose one: wide_attributes (pivots disaggregation suffixes) OR wide_indicators (pivots indicators as columns)"
            error 198
        }

        * Display informational message when wide format is used
        if ("`wide'" != "") {
            noi di as text ""
            noi di as text "Note: {bf:wide} returns years as columns (time-series format)."
            noi di as text "      Other options: {bf:wide_indicators} (indicators as columns),"
            noi di as text "                     {bf:wide_attributes(var)} (disaggregation dimension as columns)"
            noi di as text "      Valid dimensions for wide_attributes(): sex, age, wealth, residence, maternal_edu"
            noi di as text ""
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
                local drop_disag = 0
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

                    * Handle DISABILITY_STATUS specially (may not have _T total)
                    capture confirm variable disability_status
                    if (_rc == 0) {
                        * Check if _T exists for this column
                        quietly count if upper(disability_status) == "_T"
                        local dis_has_t = r(N)
                        if (`dis_has_t' > 0) {
                            * _T exists - require it
                            replace `all_tot' = `all_tot' & (upper(disability_status) == "_T")
                        }
                        else {
                            * No _T total - use PD (persons without disabilities) as baseline
                            quietly count if upper(disability_status) == "PD"
                            if (r(N) > 0) {
                                replace `all_tot' = `all_tot' & (upper(disability_status) == "PD")
                                if ("`verbose'" != "") {
                                    noi di as text "  disability_status: using PD (no _T total available)"
                                }
                            }
                        }
                    }

                    * Keep only rows where all present disaggregations equal _T (or PD for disability_status)
                    count if `all_tot'
                    local attr_match_n = r(N)
                    if (`attr_match_n' > 0) {
                        keep if `all_tot'
                        if ("`verbose'" != "") {
                            noi di as text "  default attributes filter (_T across all present dims): kept `attr_match_n' of `pre_filter_n' obs"
                        }
                    }
                    else {
                        * No totals available across disaggregations; drop disaggregation columns to allow wide reshape
                        local drop_disag = 1
                        if ("`verbose'" != "") {
                            noi di as text "  default attributes filter: no _T totals found; dropping disaggregation columns for wide_indicators"
                        }
                    }
                    drop `all_tot'
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

                if (`drop_disag') {
                    foreach v in sex age wealth wealth_quintile residence matedu maternal_edu_level sex_name age_name wealth_name residence_name maternal_edu_name {
                        capture drop `v'
                    }
                    if ("`debug'" != "") {
                        noi di as text "wide_indicators drop_disag applied: removed disaggregation columns"
                    }
                }
                else if ("`debug'" != "") {
                    noi di as text "wide_indicators drop_disag=0; keeping disaggregation columns"
                }
                
                * Drop duplicates to ensure unique combinations
                duplicates drop iso3 country period indicator, force
                
                if (_N > 0) {
                    * Reshape: indicators become columns
                    capture reshape wide value, i(iso3 country period) j(indicator) string
                    if (_rc == 0) {
                        if ("`debug'" != "") {
                            noi di as text "wide_indicators reshape rc=0, obs=" as result `=_N'
                        }
                        * Clean up column names (remove "value" prefix)
                        foreach v of varlist value* {
                            local newname = subinstr("`v'", "value", "", 1)
                            rename `v' `newname'
                        }

                        * Ensure columns exist for all requested indicators
                        * (create empty numeric columns when an indicator has no data)
                        local req_list "`indicator_requested'"
                        if ("`req_list'" == "") local req_list "`indicator'"
                        if ("`debug'" != "") {
                            noi di as text "wide_indicators req_list: " as result "`req_list'"
                        }
                        local n_req : word count `req_list'
                        if (`n_req' > 0) {
                            foreach ind of local req_list {
                                if ("`debug'" != "") {
                                    noi di as text "wide_indicators ensure column: " as result "`ind'"
                                }
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
            * Syntax: wide_attributes(var) where var = sex, age, wealth, residence, maternal_edu
            * If no var specified (empty string), uses all available disaggregation dimensions (backward compatible)
            * Result: iso3, country, period, and columns like value_T, value_M, value_F, etc.

            * Display informational message about wide_attributes
            if ("`wide_attributes'" != "") {
                noi di as text ""
                noi di as text "Note: {bf:wide_attributes(`wide_attributes')} pivots the specified dimension(s) into columns."
                noi di as text "      Valid dimensions: sex, age, wealth, residence, maternal_edu"
                noi di as text ""
            }

            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable indicator
            capture confirm variable value
            if (_rc == 0) {
                * Determine which dimensions to pivot
                local pivot_dims "`wide_attributes'"

                * Map dimension names to variable names
                * sex -> sex, age -> age, wealth -> wealth, residence -> residence, maternal_edu -> matedu
                local pivot_vars ""
                foreach dim of local pivot_dims {
                    local dim = lower("`dim'")
                    if ("`dim'" == "sex") {
                        capture confirm variable sex
                        if (_rc == 0) local pivot_vars "`pivot_vars' sex"
                    }
                    else if ("`dim'" == "age") {
                        capture confirm variable age
                        if (_rc == 0) local pivot_vars "`pivot_vars' age"
                    }
                    else if ("`dim'" == "wealth") {
                        capture confirm variable wealth
                        if (_rc == 0) local pivot_vars "`pivot_vars' wealth"
                    }
                    else if ("`dim'" == "residence") {
                        capture confirm variable residence
                        if (_rc == 0) local pivot_vars "`pivot_vars' residence"
                    }
                    else if ("`dim'" == "maternal_edu") {
                        capture confirm variable matedu
                        if (_rc == 0) local pivot_vars "`pivot_vars' matedu"
                    }
                    else {
                        noi di as error "Warning: Unknown dimension '`dim''. Valid: sex, age, wealth, residence, maternal_edu"
                    }
                }
                local pivot_vars = strtrim("`pivot_vars'")

                * If no valid pivot dimensions, check if we should use all (backward compatible)
                if ("`pivot_vars'" == "") {
                    * No specific dimensions requested - use all available (backward compatible behavior)
                    noi di as text "  Using all available disaggregation dimensions..."
                    capture confirm variable sex
                    if (_rc == 0) local pivot_vars "`pivot_vars' sex"
                    capture confirm variable wealth
                    if (_rc == 0) local pivot_vars "`pivot_vars' wealth"
                    capture confirm variable age
                    if (_rc == 0) local pivot_vars "`pivot_vars' age"
                    capture confirm variable residence
                    if (_rc == 0) local pivot_vars "`pivot_vars' residence"
                    capture confirm variable matedu
                    if (_rc == 0) local pivot_vars "`pivot_vars' matedu"
                    local pivot_vars = strtrim("`pivot_vars'")
                }

                if ("`pivot_vars'" != "") {
                    * Build composite suffix from specified pivot variables
                    tempvar disag_suffix
                    gen `disag_suffix' = ""

                    foreach pvar of local pivot_vars {
                        replace `disag_suffix' = `disag_suffix' + "_" + `pvar'
                    }

                    * Create composite variable name: indicator + suffix (or just suffix if single indicator)
                    tempvar ind_disag
                    gen `ind_disag' = indicator + `disag_suffix'

                    * Determine which columns to keep as identifiers (non-pivot dimensions)
                    local keep_cols "iso3 country period indicator"
                    local all_disag "sex wealth age residence matedu"
                    foreach dim of local all_disag {
                        capture confirm variable `dim'
                        if (_rc == 0) {
                            local is_pivot 0
                            foreach pvar of local pivot_vars {
                                if ("`dim'" == "`pvar'") local is_pivot 1
                            }
                            if (!`is_pivot') local keep_cols "`keep_cols' `dim'"
                        }
                    }

                    * Keep only essential columns for reshape
                    keep `keep_cols' `ind_disag' value

                    * Reshape: each indicator+disaggregation combination becomes a column
                    capture reshape wide value, i(`keep_cols') j(`ind_disag') string
                    if (_rc == 0) {
                        * Rename value* variables to remove the "value" prefix
                        quietly ds value*
                        foreach var in `r(varlist)' {
                            local newname = subinstr("`var'", "value", "", 1)
                            rename `var' `newname'
                        }
                        sort iso3 period
                        noi di as text "Reshaped to wide_attributes format (pivot: `pivot_vars')."
                    }
                    else {
                        noi di as text "Note: Could not reshape to wide_attributes format (may have duplicate observations)."
                    }
                }
                else {
                    noi di as error "Warning: No disaggregation variables found for wide_attributes."
                }
            }
        }
        else if ("`wide'" != "") {
            * Reshape to wide format (years as columns with yr prefix)
            * Result: iso3, country, indicator, sex, wealth, age, residence, etc., and columns like yr2019, yr2020, yr2021
            capture confirm variable iso3
            local rc_iso3 = _rc
            capture confirm variable period
            local rc_period = _rc
            capture confirm variable indicator
            local rc_indicator = _rc
            capture confirm variable value
            local rc_value = _rc
            if (`rc_iso3' == 0 & `rc_period' == 0 & `rc_indicator' == 0 & `rc_value' == 0) {
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
                foreach v in sex age wealth residence matedu geo_type {
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
                            * Drop alias_id - it was only needed for reshape
                            capture drop alias_id
                            
                            * Reorder variables: context/dimension columns before year columns
                            * Build list of non-year columns to place first
                            quietly ds yr*
                            local yr_vars `r(varlist)'
                            quietly ds
                            local all_vars `r(varlist)'
                            local context_vars ""
                            foreach v of local all_vars {
                                local is_yr = 0
                                foreach yr of local yr_vars {
                                    if ("`v'" == "`yr'") local is_yr = 1
                                }
                                if (`is_yr' == 0) local context_vars "`context_vars' `v'"
                            }
                            * Reorder: context variables first, then year columns
                            if ("`context_vars'" != "" & "`yr_vars'" != "") {
                                order `context_vars'
                                * Now move geo_type before year columns if it exists
                                capture confirm variable geo_type
                                if (_rc == 0) {
                                    local first_yr : word 1 of `yr_vars'
                                    order geo_type, before(`first_yr')
                                }
                            }
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
        * CRITICAL FOR CROSS-PLATFORM COMPATIBILITY:
        * Rename SHORT NAMES back to LONG NAMES before export/return
        * Ensures CSV exports match R schema: wealth_quintile not wealth, etc.
        * This maintains internal Stata convenience naming while fixing CSV output
        *-----------------------------------------------------------------------
        
        quietly {
            * Map short names back to long names for CSV export consistency
            * These were renamed to short names for Stata convenience (lines 794-807)
            * Now we reverse that ONLY for final export layer
            
            capture confirm variable wealth
            if (_rc == 0) rename wealth wealth_quintile
            
            capture confirm variable wealth_name
            if (_rc == 0) rename wealth_name wealth_quintile_name
            
            capture confirm variable matedu
            if (_rc == 0) rename matedu maternal_edu_lvl
            
            capture confirm variable lb
            if (_rc == 0) rename lb lower_bound
            
            capture confirm variable ub
            if (_rc == 0) rename ub upper_bound
            
            capture confirm variable status
            if (_rc == 0) rename status obs_status
            
            capture confirm variable status_name
            if (_rc == 0) rename status_name obs_status_name
            
            capture confirm variable source
            if (_rc == 0) rename source data_source
            
            capture confirm variable refper
            if (_rc == 0) rename refper ref_period
            
            capture confirm variable notes
            if (_rc == 0) rename notes country_notes
        }
        
        *-----------------------------------------------------------------------
        * Normalize known country name encoding issues (UTF-8 accent loss)
        *-----------------------------------------------------------------------
        
        capture confirm variable country
        if (_rc == 0) {
            // Fix common UTF-8 mojibake patterns from API responses
            // API may return UTF-8 characters mis-interpreted as latin1 by insheet
            // Replace mojibake patterns with correct accented characters
            
            // Côte d'Ivoire: mojibake "C├┤te" or "Cô‰Ût" → proper "Côte"
            replace country = "Côte d'Ivoire" if strpos(country, "Cô") > 0 | strpos(country, "C├") > 0 | iso3 == "CIV"
            
            // Curaçao: mojibake "Curaçao" variations
            replace country = "Curaçao" if strpos(country, "Cura") > 0 | iso3 == "CUW"
            
            // Réunion: mojibake "Réunion" variations  
            replace country = "Réunion" if strpos(country, "Réunion") > 0 | iso3 == "REU"
            
            // São Tomé and Príncipe: mojibake variations
            replace country = "São Tomé and Príncipe" if strpos(country, "S") > 0 & strpos(country, "Tom") > 0 | iso3 == "STP"
        }

        *-----------------------------------------------------------------------
        * Apply metadata column filtering (light vs full)
        * metadata=light (default): Keep only critical ~23 columns
        * metadata=full: Keep all API columns
        *-----------------------------------------------------------------------

        * Default to "light" if not specified
        if ("`metadata'" == "") local metadata "light"

        * Validate metadata parameter
        if ("`metadata'" != "light" & "`metadata'" != "full") {
            if (`noerror_flag' == 0) {
                noi di as error "metadata() must be 'light' or 'full', got '`metadata''"
            }
            exit 198
        }

        * Apply light filtering: keep only critical columns
        * Skip this filtering for wide_indicators (indicator columns must be preserved)
        if ("`metadata'" == "light" & "`wide_indicators'" == "" & "`wide'" == "" & "`wide_attributes'" == "") {
            * Critical columns for cross-platform consistency (~23 columns)
            local critical_cols "iso3 country period geo_type indicator indicator_name value unit unit_name sex age wealth_quintile residence maternal_edu_lvl lower_bound upper_bound obs_status obs_status_name data_source ref_period country_notes time_detail current_age"

            * Get list of existing columns
            quietly ds
            local all_cols `r(varlist)'

            * Keep only critical columns that exist
            local cols_to_keep ""
            foreach col of local critical_cols {
                local found = 0
                foreach existing of local all_cols {
                    if ("`col'" == "`existing'") {
                        local found = 1
                    }
                }
                if (`found' == 1) {
                    local cols_to_keep "`cols_to_keep' `col'"
                }
            }

            * Also keep any indicator-specific dimension columns (lowercase, no spaces)
            * These include: vaccine, ecd_domain, sub_sector, education_level, disability_status, etc.
            * But EXCLUDE label columns (controlled by labels parameter) and metadata annotation columns

            * Exclusion list: label columns and metadata annotation columns (not critical)
            local exclude_cols "sex_name age_name wealth_quintile_name residence_name maternal_edu_lvl_name unit_multiplier series_footnote rank coverage_time source_link obs_conf obs_footnote time_period_method data_source_priority custodian wgtd_sampl_size cause_group ethnic_group_name disability_status_name education_level_name admin_level_name ref_area_parent sowc_flag_a sowc_flag_b sowc_flag_c"

            foreach col of local all_cols {
                * Check if column is lowercase with underscores only (dimension pattern)
                if (regexm("`col'", "^[a-z][a-z0-9_]*$")) {
                    * Check if not already in critical list
                    local in_critical = 0
                    foreach crit of local critical_cols {
                        if ("`col'" == "`crit'") local in_critical = 1
                    }

                    * Check if in exclusion list
                    local in_exclude = 0
                    foreach excl of local exclude_cols {
                        if ("`col'" == "`excl'") local in_exclude = 1
                    }

                    * Keep if not in critical and not in exclude list (indicator-specific dimension)
                    if (`in_critical' == 0 & `in_exclude' == 0) {
                        local cols_to_keep "`cols_to_keep' `col'"
                    }
                }
            }

            * Keep only selected columns
            if ("`cols_to_keep'" != "") {
                keep `cols_to_keep'
            }
        }

        *-----------------------------------------------------------------------
        * Output format: Sparse (only columns with data) vs Full Schema
        * sparse (default): Drop columns that are entirely empty
        * nosparse: Keep all standard columns for cross-platform consistency
        *-----------------------------------------------------------------------
        
        * Default is sparse behavior (drop empty columns)
        * nosparse keeps all standard columns even if empty
        local do_sparse = 1
        if ("`wide_indicators'" != "") local do_sparse = 0
        if ("`sparse'" == "nosparse") local do_sparse = 0

        * Standard column schema - adjust based on metadata parameter
        * metadata=light: exclude label columns (sex_name, wealth_quintile_name, etc.)
        * metadata=full: include all columns
        if ("`metadata'" == "light") {
            * Standard columns without label columns (for metadata=light mode)
            local standard_cols "indicator indicator_name iso3 country geo_type period value unit unit_name sex age wealth_quintile residence maternal_edu_lvl lower_bound upper_bound obs_status obs_status_name data_source ref_period country_notes time_detail current_age"
        }
        else {
            * Full standard columns (for metadata=full mode)
            local standard_cols "indicator indicator_name iso3 country geo_type period value unit unit_name sex sex_name age wealth_quintile wealth_quintile_name residence maternal_edu_lvl lower_bound upper_bound obs_status obs_status_name data_source ref_period country_notes"
        }
        
        if (`do_sparse' == 0) {
            * nosparse: Add missing standard columns as empty
            * BUT: when metadata=light, only keep existing columns (match Python behavior)
            if ("`metadata'" != "light") {
                foreach col of local standard_cols {
                    capture confirm variable `col'
                    if (_rc != 0) {
                        * Column doesn't exist - add it as empty string
                        gen str1 `col' = ""
                    }
                }
            }
        }
        else {
            * sparse: Drop columns that are entirely empty/missing
            foreach v of varlist * {
                capture confirm string variable `v'
                if (_rc == 0) {
                    * String variable - check if all empty
                    quietly count if !missing(`v') & `v' != ""
                    if (r(N) == 0) {
                        drop `v'
                    }
                }
                else {
                    * Numeric variable - check if all missing
                    quietly count if !missing(`v')
                    if (r(N) == 0) {
                        drop `v'
                    }
                }
            }
        }
        
        if ("`simplify'" != "") {
            * Keep only essential columns like R's simplify option
            local keepvars ""
            foreach v in iso3 country indicator period value lower_bound upper_bound {
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
                * Store metadata return values (use compound quotes for text that may contain quotes)
                return local indicator_name `"`r(name)'"'
                return local indicator_category `"`r(category)'"'
                return local indicator_dataflow `"`r(dataflow)'"'
                return local indicator_description `"`r(description)'"'
                return local indicator_urn `"`r(urn)'"'
                return local has_sex "`r(has_sex)'"
                return local has_age "`r(has_age)'"
                return local has_wealth "`r(has_wealth)'"
                return local has_residence "`r(has_residence)'"
                return local has_maternal_edu "`r(has_maternal_edu)'"
                return local supported_dims `"`r(supported_dims)'"'
                
                if ("`nometadata'" == "") {
                    *-----------------------------------------------------------
                    * STREAMLINED DISPLAY (detailed info via info() option)
                    *-----------------------------------------------------------
                    noi di ""
                    noi di as text "{hline 70}"
                    noi di as text " Indicator: " as result "`indicator'" as text "  |  Dataflow: " as result "`dataflow'"
                    noi di as text "{hline 70}"
                    noi di as text _col(2) "Name:         " as result `"`r(name)'"'
                    if (`"`r(description)'"' != "" & `"`r(description)'"' != ".") {
                        noi di as text _col(2) "Description:  " as result `"`r(description)'"'
                    }
                    noi di as text _col(2) "Observations: " as result _N
                    noi di as text "{hline 70}"
                    noi di as text _col(2) "{p 0 2 2}{bf:Tip:} Use {stata unicefdata, info(`indicator')} for full metadata, API query, and disaggregation codes{p_end}"
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

        * Standardize column order for cross-platform consistency (match Python/R)
        * Standard order: iso3, country, period, geo_type, indicator, indicator_name, value, ...
        quietly {
            local standard_vars "iso3 country period geo_type indicator indicator_name value unit unit_name sex sex_name age wealth_quintile wealth_quintile_name residence maternal_edu_lvl lower_bound upper_bound obs_status obs_status_name data_source ref_period country_notes"
            local present_standard ""
            foreach v of local standard_vars {
                capture confirm variable `v'
                if (_rc == 0) local present_standard "`present_standard' `v'"
            }
            * Get all variables not in standard list (indicator-specific dimensions)
            local all_vars ""
            foreach v of varlist * {
                local all_vars "`all_vars' `v'"
            }
            local remaining ""
            foreach v of local all_vars {
                local in_standard = 0
                foreach s of local standard_vars {
                    if ("`v'" == "`s'") local in_standard = 1
                }
                if (!`in_standard') local remaining "`remaining' `v'"
            }
            * Reorder: standard columns first, then remaining
            order `present_standard' `remaining'
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

    *-----------------------------------------------------------------------
    * TIER 1: Direct lookup in comprehensive indicators metadata (PRIORITY)
    *-----------------------------------------------------------------------
    * This matches Python's 3-tier approach: check _unicefdata_indicators_metadata.yaml
    * first for the indicator's 'dataflows' field, which provides accurate mapping
    * for indicators like CME_COVID_CASES -> COVID_CASES dataflow

    capture _get_dataflow_direct "`indicator'"
    if (_rc == 0 & "`r(dataflows)'" != "") {
        * Extract FIRST dataflow from space-separated list (may contain fallbacks)
        local dataflows_list "`r(dataflows)'"
        local primary_only : word 1 of `dataflows_list'
        sreturn local dataflow "`primary_only'"
        sreturn local indicator_name ""
        exit
    }

    *-----------------------------------------------------------------------
    * TIER 2: YAML lookup fallback (if _get_dataflow_direct failed)
    *-----------------------------------------------------------------------
    * Try to load from comprehensive indicators metadata YAML
    local yaml_file "`metadata_path'_unicefdata_indicators_metadata.yaml"

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

                * Try to get dataflow from YAML (check both 'dataflows' and 'dataflow')
                capture local dataflow = indicators_meta["indicators"]["`indicator'"]["dataflows"]
                if ("`dataflow'" == "") {
                    capture local dataflow = indicators_meta["indicators"]["`indicator'"]["dataflow"]
                }
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

    * Final fallback: use GLOBAL_DATAFLOW if all else fails
    sreturn local dataflow "GLOBAL_DATAFLOW"
    sreturn local indicator_name ""

end


*******************************************************************************
* Helper program: Fallback prefix-based dataflow detection
* DEPRECATED: This function is kept for backward compatibility only.
* Use _get_dataflow_direct for metadata-driven lookup instead.
*******************************************************************************

program define _unicef_detect_dataflow_prefix, sclass
    args indicator
    
    * DEPRECATED: Redirect to direct YAML metadata lookup
    * This hardcoded approach is no longer used; keeping for backward compatibility
    capture _get_dataflow_direct "`indicator'"
    if (_rc == 0 & "`r(dataflows)'" != "") {
        sreturn local dataflow "`r(dataflows)'"
        exit
    }
    
    * If _get_dataflow_direct is not available, use cache-based fallback
    capture _get_dataflow_for_indicator `indicator'
    if (_rc == 0 & "`r(dataflows)'" != "") {
        sreturn local dataflow "`r(first)'"
        exit
    }
    
    * Final fallback: GLOBAL_DATAFLOW
    sreturn local dataflow "GLOBAL_DATAFLOW"
    
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
    
    * Use direct YAML metadata lookup (replaces hardcoded prefix mapping)
    capture _get_dataflow_direct "`indicator'"
    if (_rc == 0 & "`r(dataflows)'" != "") {
        sreturn local dataflow "`r(dataflows)'"
        exit
    }
    
    * Final fallback
    sreturn local dataflow "GLOBAL_DATAFLOW"
    
end


*******************************************************************************
* Version history
*******************************************************************************
* in v2.0.4:
* - FEATURE: NUTRITION dataflow now defaults age to Y0T4 (0-4 years) instead of _T
*   because the AGE dimension in NUTRITION has no _T total value
* - FEATURE: Added wealth_quintile() as alias for wealth() option
* - WARNING: Message displayed when Y0T4 default is used for NUTRITION
* - ALIGNMENT: Same fix applied to R and Python implementations
*
* in v2.0.0:
* - FEATURE: Metadata-driven filtering using disaggregations_with_totals from YAML
* - FEATURE: New helper _unicef_get_disagg_totals retrieves dims with _T totals
* - FEATURE: Dimensions NOT in disaggregations_with_totals are not defaulted to _T
* - FEATURE: DISABILITY_STATUS special handling - filters to PD when no _T exists
* - ALIGNMENT: Now matches Python/R filtering for cross-platform consistency
*   (Python: sdmx_client.py, R: unicef_core.R both use disaggregations_with_totals)
* - FIX: SYNC-02 enrichment path extraction bug resolved
* - ENHANCEMENT: Improved metadata enrichment pipeline reliability
*
* in v1.12.4:
* - FIX: All variable names now lowercase (INDICATOR → indicator)
* - FIX: All variables now have descriptive labels (including country)
* - DOCS: Updated help file with Default Behavior section
* - NOTE: wide option conflicts with wide_indicators and wide_attributes (different reshape methods)
*
*  in v1.12.0:
* - NEW: Tier filtering for discovery commands (search, indicators)
* - FIXED: Filter ALL handling—map to empty string to fetch all dimension values (e.g., sex(ALL) returns _T, M, F)
*   - showtier2: Include Tier 1-2 (verified + officially defined with no data)
*   - showtier3: Include Tier 1-3 (adds legacy/undocumented indicators)
*   - showall: Include all tiers (1-3)
*   - showorphans: Include orphan indicators (not mapped to dataflows)
*   - showlegacy: Alias for showtier3
* - NEW: Return values for tier filtering metadata
*   - r(tier_mode): Numeric tier level (1, 2, 3, or 999 for all)
*   - r(tier_filter): Descriptive string (tier_1_only, tier_1_and_2, etc.)
*   - r(show_orphans): Boolean flag for orphan inclusion
* - ENHANCEMENT: Tier warnings displayed in discovery results
* - Default behavior: Show Tier 1 only (verified and downloadable indicators)
* - BUGFIX: Normalize ALL/T/_T in disaggregation filters to SDMX total (_T)
*
*  in v1.10.0:
* - NEW: fromfile() option for offline/CI testing (skip API, load from CSV)
* - NEW: tofile() option to save API response for test fixtures
* - Enables deterministic, fast CI testing without network dependency
*
*  in v1.9.3:
* - BUGFIX: nofilter option now correctly skips filter_option (fetches all disaggregations)
*
*  in v1.9.2:
* - BUGFIX: filter_option and nofilter_option now properly passed to get_sdmx
* - BUGFIX: countries() option now passed to get_sdmx for API-level filtering
* - BUGFIX: Multi-value filters (e.g., sex(M F)) now converted to SDMX OR syntax (M+F)
*
*  in v1.9.1:
* - Integrated intelligent SDMX query filter engine (__unicef_get_indicator_filters)
* - Three query modes: auto-detect, bypass, validation
* - Automatic dimension extraction from dataflow schemas
* - Enhanced get_sdmx.ado with query mode detection
* - Indicator-to-dataflow mapping (748 indicators across 69 dataflows)
*
*  in v1.8.0:
* - Added SUBNATIONAL option to enable access to subnational dataflows
* - Without subnational option, WASH_HOUSEHOLD_SUBNAT and other *_SUBNAT dataflows are blocked
*
*  in v1.5.2: 
* - Enhanced wide_indicators: now creates empty columns for all requested indicators
*   (prevents reshape failures when some indicators have zero observations)
* - Network robustness: curl with User-Agent header (better SSL/proxy/retry support)
* - Cross-platform consistency improvements
*
*  in v1.5.1: CI test improvements (offline YAML-based tests)
*
* v 1.3.1   17Dec2025   by Joao Pedro Azevedo
*   Feature parity improvements
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

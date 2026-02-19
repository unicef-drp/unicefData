*******************************************************************************
* _unicef_search_indicators.ado
*! v 2.1.0   18Feb2026               by Joao Pedro Azevedo (UNICEF)
* Search UNICEF indicators by keyword using YAML metadata
* v2.1.0: Three-channel output (screen, r-class, dataset+char)
*         - New clear option: leaves results dataset in memory
*         - Dataset chars record search parameters and timestamp
*         - Enhanced r-class returns (cmd, cache_method, names)
* v2.0.0: Frame-based session caching for Stata 16+
*         - Parses YAML once per session, reuses cached frame
*         - Stata 14-15 falls back to direct file parsing
*         - Added nocache option to force re-parse
* v1.8.0: ENHANCEMENT - Grouped search results by dataflow
*         - Added byflow option to organize results by dataflow
*         - Default: flat table display (original behavior)
*         - With byflow: nested groups by dataflow for easier scanning
*         - Improves usability for large result sets
* v1.7.0: ENHANCEMENT - Tier filtering and return value metadata
*         - Added showtier2, showtier3, showall, showorphans options
*         - Default: Show Tier 1 only (verified and downloadable)
*         - Tier 2: Officially defined indicators with no data available
*         - Tier 3: Legacy/undocumented indicators
*         - Orphans: Indicators not mapped to current dataflows
*         - Return values: r(tier_mode), r(tier_filter), r(show_orphans)
*         - Tier warnings displayed in results
* v1.6.0: ENHANCEMENT - Search by dataflow by default, with category option
*         - Default: search keyword in code, name, OR dataflow list
*         - With category option: search keyword in code, name, OR category
*         - Aligns with typical use case (finding indicators by dataflow)
* v1.5.5: BUG FIX - Correct Stata quoting and indent detection
*         - Fixed regex patterns to use compound quotes (no backslash escaping)
*         - Fixed indicator key detection to check indent on orig_line
*         - Pattern ['\"] changed to ['"] with compound-quoted regex
*         - Prevents false detection of field names like "code: CME"
* v1.5.4: REFACTOR - Use numbered locals for names
*         - Store names as match_name1, match_name2, etc. instead of list
*         - Eliminates parsing issues with parentheses in names
* v1.5.3: BUG FIX - Compound quotes for all name processing
*         - Use compound quotes when calling lower(), strpos() on names
*         - Names with parentheses like "(aged 1-4)" require protection
* v1.5.2: BUG FIX - Use gettoken with bind for names with parentheses
*         - Names like "rate (aged 1-4 years)" were causing r(132) errors
*         - gettoken handles balanced parens/brackets properly
* v1.5.1: BUG FIXES - Apply same fixes as dataflows command
*         - Check original line for indent (not trimmed)
*         - Add hyphen to indicator regex for codes like PT_F_15-19_FGM_TND
*         - Add continue when exiting dataflows list
* v1.5.0: REWRITE - Direct file parsing instead of yaml.ado
*         - Scans YAML line-by-line to collect indicator data
*         - Searches code, name, and parent (category) fields
*         - Optional dataflow filter with direct list scanning
*         - No yaml.ado dependency (avoids list flattening issues)
*******************************************************************************

program define _unicef_search_indicators, rclass
    version 11.0
    
    syntax , Keyword(string) [Limit(integer 20) DATAFLOW(string) CATEGORY VERBOSE METApath(string) SHOWTIER2 SHOWTIER3 SHOWALL SHOWORphans BYFLOW NOCACHE CLEAR]
    
    quietly {

        *-----------------------------------------------------------------------
        * Tier filtering setup (shared by both code paths)
        *-----------------------------------------------------------------------

        local keyword_lower = lower("`keyword'")
        local df_filter_upper = upper("`dataflow'")
        local matches ""
        local match_dataflows ""
        local n_matches = 0
        local n_collected = 0

        local tier_mode = 1
        if ("`showall'" != "") {
            local tier_mode = 999
        }
        else if ("`showtier3'" != "") {
            local tier_mode = 3
        }
        else if ("`showtier2'" != "") {
            local tier_mode = 2
        }
        local show_orphans = ("`showorphans'" != "" | `tier_mode' >= 999)

        *-----------------------------------------------------------------------
        * Version-gated routing: Stata 16+ uses cached frame, else line-by-line
        *-----------------------------------------------------------------------

        local use_cache = 0
        if (c(stata_version) >= 16) {
            preserve
            capture _unicef_load_indicators_cache, ///
                metapath("`metapath'") `nocache' `verbose'
            if (_rc == 0) {
                local use_cache = 1
            }
            else {
                restore
                if ("`verbose'" != "") {
                    noi di as text "(Cache load failed, falling back to line-by-line)"
                }
            }
        }

        if (`use_cache') {
            *-------------------------------------------------------------------
            * CACHED PATH (Stata 16+): dataset-based search
            *-------------------------------------------------------------------

            * Normalize dataflows: replace semicolons with spaces for display
            replace field_dataflows = subinstr(field_dataflows, ";", " ", .)

            * Apply tier filtering
            gen _tier_num = real(field_tier)
            replace _tier_num = 3 if _tier_num == .
            if (`tier_mode' < 999) {
                drop if _tier_num > `tier_mode'
            }

            * Apply orphan filtering
            gen byte _is_orphan = (strtrim(field_dataflows) == "" | ///
                strpos(field_dataflows, "nodata") > 0)
            if (!`show_orphans') {
                drop if _is_orphan == 1
            }

            * Apply keyword matching
            gen byte _match = 0
            replace _match = 1 if strpos(lower(ind_code), "`keyword_lower'") > 0
            replace _match = 1 if strpos(lower(field_name), "`keyword_lower'") > 0
            if ("`category'" != "") {
                replace _match = 1 if strpos(lower(field_parent), "`keyword_lower'") > 0
            }
            else if ("`df_filter_upper'" == "") {
                replace _match = 1 if strpos(lower(field_dataflows), "`keyword_lower'") > 0
            }
            keep if _match == 1

            * Apply dataflow filter if specified
            if ("`df_filter_upper'" != "") {
                keep if strpos(upper(field_dataflows), "`df_filter_upper'") > 0
            }

            * Count total matches
            local n_matches = _N

            * Collect results into locals (up to limit)
            local n_to_show = min(`n_matches', `limit')
            forvalues i = 1/`n_to_show' {
                local n_collected = `n_collected' + 1
                local ind_i = ind_code[`i']
                local matches "`matches' `ind_i'"

                * Use scalar to safely extract strL name
                scalar _s_nm = field_name[`i']
                local match_name`n_collected' = _s_nm
                scalar drop _s_nm

                local df_i = strtrim(field_dataflows[`i'])
                if ("`df_i'" == "") local df_i = "N/A"
                local match_dataflows "`match_dataflows' `df_i'"
            }

            if ("`clear'" != "") {
                * Keep results dataset: rename columns for user-friendly output
                keep ind_code field_name field_dataflows field_tier ///
                    field_tier_reason field_desc field_urn field_parent
                rename ind_code indicator_code
                rename field_name indicator_name
                rename field_dataflows dataflows
                rename field_tier tier
                rename field_tier_reason tier_reason
                rename field_desc description
                rename field_urn urn
                rename field_parent parent

                * Label dataset
                label data "unicefdata search results: `keyword'"
                label variable indicator_code "Indicator code"
                label variable indicator_name "Indicator name"
                label variable dataflows "Dataflow(s)"
                label variable tier "Tier classification"
                label variable tier_reason "Tier reason"
                label variable description "Indicator description"
                label variable urn "SDMX URN"
                label variable parent "Parent category"

                * Store dataset characteristics
                char _dta[unicefdata_version]         "2.3.0"
                char _dta[unicefdata_command]          "search"
                char _dta[unicefdata_search_keyword]   "`keyword'"
                char _dta[unicefdata_search_n_matches] "`n_matches'"
                char _dta[unicefdata_search_limit]     "`limit'"
                char _dta[unicefdata_timestamp]         ///
                    "`c(current_date)' `c(current_time)'"
                if ("`dataflow'" != "") {
                    char _dta[unicefdata_search_dataflow] "`dataflow'"
                }
                char _dta[unicefdata_search_tier_filter] ///
                    "`tier_mode'"
                char _dta[unicefdata_cache_method] "frames"

                * Drop internal working variables
                capture drop _tier_num
                capture drop _is_orphan
                capture drop _match

                * Sort by indicator code
                sort indicator_code
                compress
            }
            else {
                restore
            }
            local matches = strtrim("`matches'")
        }
        else {
            *-------------------------------------------------------------------
            * LEGACY PATH (Stata 14-15): direct file parsing
            *-------------------------------------------------------------------

            * Locate metadata directory
            if ("`metapath'" == "") {
                capture findfile _unicef_search_indicators.ado
                if (_rc == 0) {
                    local ado_path "`r(fn)'"
                    local ado_dir = subinstr("`ado_path'", "\", "/", .)
                    local ado_dir = subinstr("`ado_dir'", ///
                        "_unicef_search_indicators.ado", "", .)
                    local metapath "`ado_dir'"
                }
                if ("`metapath'" == "") | ///
                    (!fileexists("`metapath'_unicefdata_indicators_metadata.yaml")) {
                    local metapath "`c(sysdir_plus)'_/"
                }
            }

            local yaml_file "`metapath'_unicefdata_indicators_metadata.yaml"

            capture confirm file "`yaml_file'"
            if (_rc != 0) {
                noi di as err "Indicators metadata not found at: `yaml_file'"
                noi di as err "Run 'unicefdata_sync' to download metadata."
                exit 601
            }

            if ("`verbose'" != "") {
                noi di as text "Searching indicators in: " as result "`yaml_file'"
            }

            * Parse YAML file directly (existing state-machine parser)
            tempname fh
            file open `fh' using "`yaml_file'", read text

            local in_indicators = 0
            local current_ind = ""
            local current_name = ""
            local current_parent = ""
            local current_dataflows = ""
            local current_tier = 1
            local current_tier_reason = ""
            local in_dataflows_list = 0

            file read `fh' line

            while r(eof) == 0 {
                local trimmed = strtrim(`"`macval(line)'"')

                if ("`trimmed'" == "indicators:") {
                    local in_indicators = 1
                    file read `fh' line
                    continue
                }

                if (`in_indicators' == 1) {

                    local orig_line `"`macval(line)'"'
                    if (substr("`orig_line'", 1, 1) != " " & "`trimmed'" != "" & !regexm("`trimmed'", "^#")) {
                        if (!regexm("`trimmed'", "^-")) {
                            if ("`current_ind'" != "" & `n_collected' < `limit') {
                                local code_lower = lower("`current_ind'")
                                local name_lower = lower(`"`current_name'"')
                                local parent_lower = lower("`current_parent'")

                                local is_match = 0
                                if (strpos("`code_lower'", "`keyword_lower'") > 0) local is_match = 1
                                if (strpos(`"`name_lower'"', "`keyword_lower'") > 0) local is_match = 1
                                if ("`category'" != "") {
                                    if (strpos("`parent_lower'", "`keyword_lower'") > 0) local is_match = 1
                                }
                                else if ("`df_filter_upper'" == "") {
                                    local df_lower = lower("`current_dataflows'")
                                    if (strpos("`df_lower'", "`keyword_lower'") > 0) local is_match = 1
                                }

                                if (`is_match' == 1 & "`df_filter_upper'" != "") {
                                    local df_upper = upper("`current_dataflows'")
                                    if (strpos("`df_upper'", "`df_filter_upper'") == 0) {
                                        local is_match = 0
                                    }
                                }

                                if (`is_match' == 1) {
                                    local n_matches = `n_matches' + 1
                                    local n_collected = `n_collected' + 1
                                    local matches "`matches' `current_ind'"
                                    local match_name`n_collected' "`current_name'"
                                    local df_display = strtrim("`current_dataflows'")
                                    if ("`df_display'" == "") local df_display = "N/A"
                                    local match_dataflows "`match_dataflows' `df_display'"
                                }
                            }
                            local in_indicators = 0
                            file read `fh' line
                            continue
                        }
                    }

                    local is_indicator_key = regexm(`"`orig_line'"', "^  [A-Za-z][A-Za-z0-9_-]*:[ ]*$")
                    if (`is_indicator_key') {

                        if ("`current_ind'" != "" & `n_collected' < `limit') {
                            local code_lower = lower("`current_ind'")
                            local name_lower = lower(`"`current_name'"')
                            local parent_lower = lower("`current_parent'")

                            local is_match = 0
                            if (strpos("`code_lower'", "`keyword_lower'") > 0) local is_match = 1
                            if (strpos(`"`name_lower'"', "`keyword_lower'") > 0) local is_match = 1
                            if ("`category'" != "") {
                                if (strpos("`parent_lower'", "`keyword_lower'") > 0) local is_match = 1
                            }
                            else if ("`df_filter_upper'" == "") {
                                local df_lower = lower("`current_dataflows'")
                                if (strpos("`df_lower'", "`keyword_lower'") > 0) local is_match = 1
                            }

                            if (`is_match' == 1 & "`df_filter_upper'" != "") {
                                local df_upper = upper("`current_dataflows'")
                                if (strpos("`df_upper'", "`df_filter_upper'") == 0) {
                                    local is_match = 0
                                }
                            }

                            if (`is_match' == 1) {
                                local n_matches = `n_matches' + 1

                                * Check tier filter (v2.2.1: was missing here)
                                local tier_ok = 0
                                if (`tier_mode' >= 999) {
                                    local tier_ok = 1
                                }
                                else if (`current_tier' <= `tier_mode') {
                                    local tier_ok = 1
                                }

                                * Check orphan status
                                local is_orphan = 0
                                if (strtrim("`current_dataflows'") == "" | strpos("`current_dataflows'", "nodata") > 0) {
                                    local is_orphan = 1
                                    if (!`show_orphans') local tier_ok = 0
                                }

                                if (`tier_ok' == 1) {
                                    local n_collected = `n_collected' + 1
                                    local matches "`matches' `current_ind'"
                                    local match_name`n_collected' `"`current_name'"'
                                    local df_display = strtrim("`current_dataflows'")
                                    if ("`df_display'" == "") local df_display = "N/A"
                                    local match_dataflows "`match_dataflows' `df_display'"
                                }
                            }
                        }

                        local current_ind = subinstr("`trimmed'", ":", "", .)
                        local current_name = ""
                        local current_parent = ""
                        local current_dataflows = ""
                        local current_tier = 1
                        local current_tier_reason = ""
                        local in_dataflows_list = 0

                        file read `fh' line
                        continue
                    }

                    if (regexm(`"`trimmed'"', `"^name:[ ]*['"](.*)['"]$"')) {
                        local current_name = regexs(1)
                        local in_dataflows_list = 0
                        file read `fh' line
                        continue
                    }
                    if (regexm(`"`trimmed'"', `"^name:[ ]*([^']+)$"')) {
                        local current_name = regexs(1)
                        local in_dataflows_list = 0
                        file read `fh' line
                        continue
                    }

                    if (regexm("`trimmed'", "^parent:[ ]*(.+)$")) {
                        local current_parent = regexs(1)
                        local in_dataflows_list = 0
                        file read `fh' line
                        continue
                    }

                    if (regexm("`trimmed'", "^tier:[ ]*([0-9]+)$")) {
                        local current_tier = regexs(1)
                        local in_dataflows_list = 0
                        file read `fh' line
                        continue
                    }

                    if (regexm("`trimmed'", "^tier_reason:[ ]*(.+)$")) {
                        local current_tier_reason = regexs(1)
                        local in_dataflows_list = 0
                        file read `fh' line
                        continue
                    }

                    if (regexm("`trimmed'", "^dataflows:[ ]*\[(.+)\]$")) {
                        local dflist = regexs(1)
                        local dflist = subinstr("`dflist'", ",", " ", .)
                        local dflist = subinstr("`dflist'", "'", "", .)
                        local dflist = subinstr("`dflist'", `"""', "", .)
                        local current_dataflows = strtrim("`dflist'")
                        local in_dataflows_list = 0
                        file read `fh' line
                        continue
                    }

                    if (regexm("`trimmed'", "^dataflows:[ ]*$")) {
                        local in_dataflows_list = 1
                        local current_dataflows = ""
                        file read `fh' line
                        continue
                    }

                    if (`in_dataflows_list' == 1) {
                        if (regexm("`trimmed'", "^- (.+)$")) {
                            local df_item = regexs(1)
                            local df_item = strtrim("`df_item'")
                            local current_dataflows "`current_dataflows' `df_item'"
                            file read `fh' line
                            continue
                        }
                        else if (!regexm("`trimmed'", "^-")) {
                            local in_dataflows_list = 0
                            continue
                        }
                    }
                }

                file read `fh' line
            }

            * Process final indicator
            if ("`current_ind'" != "" & `n_collected' < `limit' & `in_indicators' == 1) {
                local code_lower = lower("`current_ind'")
                local name_lower = lower(`"`current_name'"')
                local parent_lower = lower("`current_parent'")

                local is_match = 0
                if (strpos("`code_lower'", "`keyword_lower'") > 0) local is_match = 1
                if (strpos(`"`name_lower'"', "`keyword_lower'") > 0) local is_match = 1
                if ("`category'" != "") {
                    if (strpos("`parent_lower'", "`keyword_lower'") > 0) local is_match = 1
                }
                else if ("`df_filter_upper'" == "") {
                    local df_lower = lower("`current_dataflows'")
                    if (strpos("`df_lower'", "`keyword_lower'") > 0) local is_match = 1
                }

                if (`is_match' == 1 & "`df_filter_upper'" != "") {
                    local df_upper = upper("`current_dataflows'")
                    if (strpos("`df_upper'", "`df_filter_upper'") == 0) {
                        local is_match = 0
                    }
                }

                if (`is_match' == 1) {
                    local n_matches = `n_matches' + 1

                    local tier_ok = 0
                    if (`tier_mode' >= 999) {
                        local tier_ok = 1
                    }
                    else if (`current_tier' <= `tier_mode') {
                        local tier_ok = 1
                    }

                    local is_orphan = 0
                    if (strtrim("`current_dataflows'") == "" | strpos("`current_dataflows'", "nodata") > 0) {
                        local is_orphan = 1
                        if (!`show_orphans') local tier_ok = 0
                    }

                    if (`tier_ok' == 1) {
                        local n_collected = `n_collected' + 1
                        local matches "`matches' `current_ind'"
                        local match_name`n_collected' `"`current_name'"'
                        local df_display = strtrim("`current_dataflows'")
                        if ("`df_display'" == "") local df_display = "N/A"
                        local match_dataflows "`match_dataflows' `df_display'"
                    }
                }
            }

            file close `fh'
            local matches = strtrim("`matches'")

            * Build results dataset if clear specified (legacy path)
            if ("`clear'" != "" & `n_collected' > 0) {
                clear
                set obs `n_collected'
                gen str100 indicator_code = ""
                gen strL indicator_name = ""
                gen str244 dataflows = ""

                forvalues i = 1/`n_collected' {
                    local ind_i : word `i' of `matches'
                    replace indicator_code = "`ind_i'" in `i'
                    local nm_i `"`match_name`i''"'
                    replace indicator_name = `"`nm_i'"' in `i'
                    local df_i : word `i' of `match_dataflows'
                    replace dataflows = "`df_i'" in `i'
                }

                label data "unicefdata search results: `keyword'"
                label variable indicator_code "Indicator code"
                label variable indicator_name "Indicator name"
                label variable dataflows "Dataflow(s)"

                char _dta[unicefdata_version]         "2.3.0"
                char _dta[unicefdata_command]          "search"
                char _dta[unicefdata_search_keyword]   "`keyword'"
                char _dta[unicefdata_search_n_matches] "`n_matches'"
                char _dta[unicefdata_search_limit]     "`limit'"
                char _dta[unicefdata_timestamp]         ///
                    "`c(current_date)' `c(current_time)'"
                if ("`dataflow'" != "") {
                    char _dta[unicefdata_search_dataflow] "`dataflow'"
                }
                char _dta[unicefdata_search_tier_filter] ///
                    "`tier_mode'"
                char _dta[unicefdata_cache_method] "none"

                sort indicator_code
                compress
            }
        }

    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 70}"
    if ("`dataflow'" != "") {
        noi di as text "Search Results for: " as result "`keyword'" as text " in dataflow " as result "`dataflow'"
    }
    else if ("`category'" != "") {
        noi di as text "Search Results for: " as result "`keyword'" as text " in categories"
    }
    else {
        noi di as text "Search Results for: " as result "`keyword'" as text " in dataflows"
    }
    
    * Dynamic column widths based on screen size
    local linesize = c(linesize)
    local col_ind = 2
    local col_cat = 28
    local col_name = 48
    local name_width = `linesize' - `col_name' - 2
    if (`name_width' < 20) local name_width = 20
    
    noi di as text "{hline `linesize'}"
    noi di ""
    
    if (`n_matches' == 0) {
        if ("`dataflow'" != "") {
            noi di as text "  No indicators found matching '`keyword'' in dataflow '`dataflow''"
        }
        else {
            noi di as text "  No indicators found matching '`keyword''"
        }
        noi di ""
        noi di as text "  Tips:"
        noi di as text "  - Try a different search term"
        noi di as text "  - Use {bf:unicefdata, categories} to see available categories"
        noi di as text "  - Use {bf:unicefdata, search(keyword)} without dataflow filter"
    }
    else if ("`byflow'" != "") {
        * GROUPED DISPLAY - Organize by dataflow
        noi di as text "Results grouped by dataflow:"
        noi di ""
        
        * Build unique dataflows list
        local unique_dfs ""
        forvalues i = 1/`n_collected' {
            local df : word `i' of `match_dataflows'
            local already_found = 0
            foreach existing_df in `unique_dfs' {
                if ("`df'" == "`existing_df'") {
                    local already_found = 1
                }
            }
            if (!`already_found') {
                local unique_dfs "`unique_dfs' `df'"
            }
        }
        
        * Display by dataflow group
        foreach df in `unique_dfs' {
            noi di as result _col(2) "`df'"
            noi di as text _col(4) "{ul:Indicator}" _col(20) "{ul:Name}"
            
            forvalues i = 1/`n_collected' {
                local cat : word `i' of `match_dataflows'
                if ("`cat'" == "`df'") {
                    local ind : word `i' of `matches'
                    local nm `"`match_name`i''"'
                    
                    * Truncate name for grouped view (narrower)
                    local display_width = `linesize' - 24
                    if (`display_width' < 20) local display_width = 20
                    if (length(`"`nm'"') > `display_width') {
                        local nm = substr(`"`nm'"', 1, `display_width' - 3) + "..."
                    }
                    
                    * Display with hyperlinks
                    noi di as text _col(4) `"{stata unicefdata, indicator(`ind') countries(AFG BGD) clear:`ind'}"' _col(20) `"{stata unicefdata, info(`ind'):`nm'}"'
                }
            }
            noi di ""
        }
        
        if (`n_collected' >= `limit') {
            noi di as text "  (Showing first `limit' matches. Use limit() option for more.)"
        }
    }
    else {
        * FLAT DISPLAY (default) - Original table format
        noi di as text _col(`col_ind') "{ul:Indicator}" _col(`col_cat') "{ul:Dataflow}" _col(`col_name') "{ul:Name (click for metadata)}"
        noi di ""
        
        forvalues i = 1/`n_collected' {
            local ind : word `i' of `matches'
            local cat : word `i' of `match_dataflows'
            
            * Get name from numbered local (handles parens safely)
            local nm `"`match_name`i''"'
            
            * Truncate name based on available width
            if (length(`"`nm'"') > `name_width') {
                local nm = substr(`"`nm'"', 1, `name_width' - 3) + "..."
            }
            
            * Hyperlinks:
            * - Indicator: show sample usage with indicator() option
            * - Category: show indicators in category
            * - Name: show metadata with info() option
            if ("`cat'" != "" & "`cat'" != "N/A") {
                noi di as text _col(`col_ind') `"{stata unicefdata, indicator(`ind') countries(AFG BGD) clear:`ind'}"' as text _col(`col_cat') `"{stata unicefdata, indicators(`cat'):`cat'}"' _col(`col_name') `"{stata unicefdata, info(`ind'):`nm'}"'
            }
            else {
                noi di as text _col(`col_ind') `"{stata unicefdata, indicator(`ind') countries(AFG BGD) clear:`ind'}"' as text _col(`col_cat') "`cat'" _col(`col_name') `"{stata unicefdata, info(`ind'):`nm'}"'
            }
        }
        
        if (`n_collected' >= `limit') {
            noi di ""
            noi di as text "  (Showing first `limit' matches. Use limit() option for more.)"
        }
    }
    
    noi di ""
    noi di as text "{hline `linesize'}"
    noi di as text "Found: " as result `n_matches' as text " indicator(s)"
    noi di as text "{hline `linesize'}"
    if ("`dataflow'" != "") {
        noi di as text "{it:Note: Search matches keyword in code or name, filtered by dataflow.}"
    }
    else if ("`category'" != "") {
        noi di as text "{it:Note: Search matches keyword in code, name, or category.}"
    }
    else {
        noi di as text "{it:Note: Search matches keyword in code, name, or dataflow.}"
    }
    if ("`byflow'" != "") {
        noi di as text "{it:Results organized by dataflow. Use 'unicefdata, info(indicator)' for details.}"
    }
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------

    return scalar n_matches = `n_matches'
    return scalar n_displayed = `n_collected'
    return local indicators "`matches'"
    return local keyword "`keyword'"
    if ("`dataflow'" != "") {
        return local dataflow "`dataflow'"
    }

    * Return individual indicator names
    forvalues i = 1/`n_collected' {
        return local name`i' `"`match_name`i''"'
    }

    * Return first match for convenience
    if (`n_collected' > 0) {
        local first_code : word 1 of `matches'
        return local first_code "`first_code'"
    }

    * Return tier filtering metadata
    return scalar tier_mode = `tier_mode'
    if (`tier_mode' == 1) {
        return local tier_filter "tier_1_only"
    }
    else if (`tier_mode' == 2) {
        return local tier_filter "tier_1_and_2"
    }
    else if (`tier_mode' == 3) {
        return local tier_filter "tier_1_2_3"
    }
    else if (`tier_mode' >= 999) {
        return local tier_filter "all_tiers"
    }
    return scalar show_orphans = `show_orphans'

    * Return cache and command metadata
    if (`use_cache') {
        return local cache_method "frames"
    }
    else {
        return local cache_method "none"
    }
    return local cmd `"unicefdata, search(`keyword') limit(`limit')"'

end

*******************************************************************************
* Version history
*******************************************************************************
* v 1.5.0   16Jan2026   by Joao Pedro Azevedo
*   - REWRITE: Direct file parsing instead of yaml.ado
*   - Scans YAML line-by-line to collect indicator data
*   - Uses 'parent' field as category (matches YAML structure)
*   - Optional dataflow filter with direct list scanning
*   - No yaml.ado dependency (avoids list flattening issues)
*   - Version 11.0 compatible (no frames required)
*
* v 1.4.0   17Dec2025   by Joao Pedro Azevedo
*   - MAJOR REWRITE: Direct dataset query instead of 733 yaml get calls
*   - Performance: reshape + strpos filter vs individual lookups
*   - Robustness: Avoids frame context/return value propagation issues
*   - Idiomatic: Leverages Stata's dataset manipulation strengths
*
* v 1.3.2   17Dec2025   by Joao Pedro Azevedo
*   - Fixed frame naming (use explicit yaml_ prefix for clarity)
*
* v 1.3.1   17Dec2025   by Joao Pedro Azevedo
*   Added dataflow() filter option (aligned with Python/R category filter)
*   - Search can now be filtered by dataflow: search(keyword) dataflow(CME)
*   - Improved display with tips when no results found
*
* v 1.3.0   09Dec2025   by Joao Pedro Azevedo
*   Initial implementation with frames support
*   - Search indicators by keyword in code or name
*   - Uses frames for Stata 16+ for better isolation
*   - Returns r(indicators) list and r(n_matches) scalar
*******************************************************************************

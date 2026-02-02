*******************************************************************************
* _unicef_search_indicators.ado
*! v 1.8.0   01Feb2026               by Joao Pedro Azevedo (UNICEF)
* Search UNICEF indicators by keyword using YAML metadata
* Uses direct file parsing for robust, yaml.ado-independent operation
*
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
    
    syntax , Keyword(string) [Limit(integer 20) DATAFLOW(string) CATEGORY VERBOSE METApath(string) SHOWTIER2 SHOWTIER3 SHOWALL SHOWORphans BYFLOW]
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata directory (YAML files in src/_/ alongside this ado)
        *-----------------------------------------------------------------------
        
        if ("`metapath'" == "") {
            * Find the helper program location (src/_/)
            capture findfile _unicef_search_indicators.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                * Extract directory containing this ado file
                local ado_dir = subinstr("`ado_path'", "\", "/", .)
                local ado_dir = subinstr("`ado_dir'", "_unicef_search_indicators.ado", "", .)
                local metapath "`ado_dir'"
            }
            
            * Fallback to PLUS directory _/
            if ("`metapath'" == "") | (!fileexists("`metapath'_unicefdata_indicators_metadata.yaml")) {
                local metapath "`c(sysdir_plus)'_/"
            }
        }
        
        * Use full indicator catalog (733 indicators)
        local yaml_file "`metapath'_unicefdata_indicators_metadata.yaml"
        
        *-----------------------------------------------------------------------
        * Check YAML file exists
        *-----------------------------------------------------------------------
        
        capture confirm file "`yaml_file'"
        if (_rc != 0) {
            noi di as err "Indicators metadata not found at: `yaml_file'"
            noi di as err "Run 'unicefdata_sync' to download metadata."
            exit 601
        }
        
        if ("`verbose'" != "") {
            noi di as text "Searching indicators in: " as result "`yaml_file'"
        }
        
        *-----------------------------------------------------------------------
        * Search using direct file parsing
        * Scans YAML line-by-line to find matching indicators
        *-----------------------------------------------------------------------
        
        local keyword_lower = lower("`keyword'")
        local df_filter_upper = upper("`dataflow'")
        local matches ""
        * Use numbered locals for names (avoids issues with parens in names)
        * match_name1, match_name2, ... will be set during processing
        local match_dataflows ""
        local n_matches = 0
        local n_collected = 0        
        * Determine tier filtering mode
        local tier_mode = 1  // Default: Tier 1 only
        if ("`showall'" != "") {
            local tier_mode = 999  // Show all tiers
        }
        else if ("`showtier3'" != "") {
            local tier_mode = 3  // Show tiers 1-3
        }
        else if ("`showtier2'" != "") {
            local tier_mode = 2  // Show tiers 1-2
        }
        local show_orphans = ("`showorphans'" != "" | `tier_mode' >= 999)        
        *-----------------------------------------------------------------------
        * Parse YAML file directly
        *-----------------------------------------------------------------------
        
        tempname fh
        file open `fh' using "`yaml_file'", read text
        
        * State tracking
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
            
            * Check for indicators: section start
            if ("`trimmed'" == "indicators:") {
                local in_indicators = 1
                file read `fh' line
                continue
            }
            
            * Only process if in indicators section
            if (`in_indicators' == 1) {
                
                * Detect end of indicators section (new top-level key without indent)
                local orig_line `"`macval(line)'"'
                if (substr("`orig_line'", 1, 1) != " " & "`trimmed'" != "" & !regexm("`trimmed'", "^#")) {
                    if (!regexm("`trimmed'", "^-")) {
                        * Process final indicator if pending
                        if ("`current_ind'" != "" & `n_collected' < `limit') {
                            * Check if keyword matches
                            local code_lower = lower("`current_ind'")
                            local name_lower = lower(`"`current_name'"')
                            local parent_lower = lower("`current_parent'")
                            
                            local is_match = 0
                            if (strpos("`code_lower'", "`keyword_lower'") > 0) local is_match = 1
                            if (strpos(`"`name_lower'"', "`keyword_lower'") > 0) local is_match = 1
                            * Search in category or dataflow (unless dataflow filter specified)
                            if ("`category'" != "") {
                                if (strpos("`parent_lower'", "`keyword_lower'") > 0) local is_match = 1
                            }
                            else if ("`df_filter_upper'" == "") {
                                * Only search in dataflows if no dataflow filter specified
                                local df_lower = lower("`current_dataflows'")
                                if (strpos("`df_lower'", "`keyword_lower'") > 0) local is_match = 1
                            }
                            
                            * Apply dataflow filter if specified (check dataflows list)
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
                
                * Detect new indicator entry (2-space indent, ends with :)
                * Note: Stata regex doesn't support {2}, use literal two spaces
                local is_indicator_key = regexm(`"`orig_line'"', "^  [A-Za-z][A-Za-z0-9_-]*:[ ]*$")
                if (`is_indicator_key') {
                    
                    * Process previous indicator if exists
                    if ("`current_ind'" != "" & `n_collected' < `limit') {
                        local code_lower = lower("`current_ind'")
                        local name_lower = lower(`"`current_name'"')
                        local parent_lower = lower("`current_parent'")
                        
                        local is_match = 0
                        if (strpos("`code_lower'", "`keyword_lower'") > 0) local is_match = 1
                        if (strpos(`"`name_lower'"', "`keyword_lower'") > 0) local is_match = 1
                        * Search in category or dataflow (unless dataflow filter specified)
                        if ("`category'" != "") {
                            if (strpos("`parent_lower'", "`keyword_lower'") > 0) local is_match = 1
                        }
                        else if ("`df_filter_upper'" == "") {
                            * Only search in dataflows if no dataflow filter specified
                            local df_lower = lower("`current_dataflows'")
                            if (strpos("`df_lower'", "`keyword_lower'") > 0) local is_match = 1
                        }
                        
                        * Apply dataflow filter if specified (check dataflows list)
                        if (`is_match' == 1 & "`df_filter_upper'" != "") {
                            local df_upper = upper("`current_dataflows'")
                            if (strpos("`df_upper'", "`df_filter_upper'") == 0) {
                                local is_match = 0
                            }
                        }
                        
                        if (`is_match' == 1) {
                            local n_matches = `n_matches' + 1
                            
                            * Check tier filter
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
                    
                    * Start new indicator
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
                
                * Parse name field (format: name: 'text' or name: text)
                if (regexm(`"`trimmed'"', `"^name:[ ]*['"](.*)['"]$"')) {
                    local current_name = regexs(1)
                    local in_dataflows_list = 0
                    file read `fh' line
                    continue
                }
                * Handle unquoted names
                if (regexm(`"`trimmed'"', `"^name:[ ]*([^']+)$"')) {
                    local current_name = regexs(1)
                    local in_dataflows_list = 0
                    file read `fh' line
                    continue
                }
                
                * Parse parent field (this is the category)
                if (regexm("`trimmed'", "^parent:[ ]*(.+)$")) {
                    local current_parent = regexs(1)
                    local in_dataflows_list = 0
                    file read `fh' line
                    continue
                }
                
                * Parse tier field
                if (regexm("`trimmed'", "^tier:[ ]*([0-9]+)$")) {
                    local current_tier = regexs(1)
                    local in_dataflows_list = 0
                    file read `fh' line
                    continue
                }
                
                * Parse tier_reason field
                if (regexm("`trimmed'", "^tier_reason:[ ]*(.+)$")) {
                    local current_tier_reason = regexs(1)
                    local in_dataflows_list = 0
                    file read `fh' line
                    continue
                }
                
                * Parse dataflows field (may be list or inline)
                if (regexm("`trimmed'", "^dataflows:[ ]*\[(.+)\]$")) {
                    * Inline list: dataflows: [CME, GLOBAL_DATAFLOW]
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
                    * Block list starting - set flag
                    local in_dataflows_list = 1
                    local current_dataflows = ""
                    file read `fh' line
                    continue
                }
                
                * Parse dataflows list items
                if (`in_dataflows_list' == 1) {
                    if (regexm("`trimmed'", "^- (.+)$")) {
                        local df_item = regexs(1)
                        local df_item = strtrim("`df_item'")
                        local current_dataflows "`current_dataflows' `df_item'"
                        file read `fh' line
                        continue
                    }
                    else if (!regexm("`trimmed'", "^-")) {
                        * End of dataflows list - continue to re-process this line
                        local in_dataflows_list = 0
                        continue
                    }
                }
            }
            
            file read `fh' line
        }
        
        * Process final indicator if exists
        if ("`current_ind'" != "" & `n_collected' < `limit' & `in_indicators' == 1) {
            local code_lower = lower("`current_ind'")
            local name_lower = lower(`"`current_name'"')
            local parent_lower = lower("`current_parent'")
            
            local is_match = 0
            if (strpos("`code_lower'", "`keyword_lower'") > 0) local is_match = 1
            if (strpos(`"`name_lower'"', "`keyword_lower'") > 0) local is_match = 1
            * Search in category or dataflow (unless dataflow filter specified)
            if ("`category'" != "") {
                if (strpos("`parent_lower'", "`keyword_lower'") > 0) local is_match = 1
            }
            else if ("`df_filter_upper'" == "") {
                * Only search in dataflows if no dataflow filter specified
                local df_lower = lower("`current_dataflows'")
                if (strpos("`df_lower'", "`keyword_lower'") > 0) local is_match = 1
            }
            
            * Apply dataflow filter if specified (check dataflows list)
            if (`is_match' == 1 & "`df_filter_upper'" != "") {
                local df_upper = upper("`current_dataflows'")
                if (strpos("`df_upper'", "`df_filter_upper'") == 0) {
                    local is_match = 0
                }
            }
            
            if (`is_match' == 1) {
                local n_matches = `n_matches' + 1
                
                * Check tier filter
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
        
        file close `fh'
        
        local matches = strtrim("`matches'")
        
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
    return local indicators "`matches'"
    return local keyword "`keyword'"
    if ("`dataflow'" != "") {
        return local dataflow "`dataflow'"
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

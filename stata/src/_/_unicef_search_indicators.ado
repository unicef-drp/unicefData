*******************************************************************************
* _unicef_search_indicators.ado
*! v 1.6.0   16Jan2026               by Joao Pedro Azevedo (UNICEF)
* Search UNICEF indicators by keyword using YAML metadata
* Uses direct file parsing for robust, yaml.ado-independent operation
*
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
    
    syntax , Keyword(string) [Limit(integer 20) DATAFLOW(string) CATEGORY VERBOSE METApath(string)]
    
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
                            
                            * Apply dataflow filter if specified (check parent field)
                            if (`is_match' == 1 & "`df_filter_upper'" != "") {
                                local parent_upper = upper("`current_parent'")
                                if ("`parent_upper'" != "`df_filter_upper'") {
                                    local is_match = 0
                                }
                            }
                            
                            if (`is_match' == 1) {
                                local n_matches = `n_matches' + 1
                                local n_collected = `n_collected' + 1
                                local matches "`matches' `current_ind'"
                                local match_name`n_collected' `"`current_name'"'
                                * Use parent as the display "dataflow"
                                local match_dataflows "`match_dataflows' `current_parent'"
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
                        
                        * Apply dataflow filter if specified (check parent field)
                        if (`is_match' == 1 & "`df_filter_upper'" != "") {
                            local parent_upper = upper("`current_parent'")
                            if ("`parent_upper'" != "`df_filter_upper'") {
                                local is_match = 0
                            }
                        }
                        
                        if (`is_match' == 1) {
                            local n_matches = `n_matches' + 1
                            local n_collected = `n_collected' + 1
                            local matches "`matches' `current_ind'"
                            local match_name`n_collected' `"`current_name'"'
                            local match_dataflows "`match_dataflows' `current_parent'"
                        }
                    }
                    
                    * Start new indicator
                    local current_ind = subinstr("`trimmed'", ":", "", .)
                    local current_name = ""
                    local current_parent = ""
                    local current_dataflows = ""
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
            
            * Apply dataflow filter if specified (check parent field)
            if (`is_match' == 1 & "`df_filter_upper'" != "") {
                local parent_upper = upper("`current_parent'")
                if ("`parent_upper'" != "`df_filter_upper'") {
                    local is_match = 0
                }
            }
            
            if (`is_match' == 1) {
                local n_matches = `n_matches' + 1
                local n_collected = `n_collected' + 1
                local matches "`matches' `current_ind'"
                local match_name`n_collected' `"`current_name'"'
                local match_dataflows "`match_dataflows' `current_parent'"
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
    else {
        noi di as text _col(`col_ind') "{ul:Indicator}" _col(`col_cat') "{ul:Category}" _col(`col_name') "{ul:Name (click for metadata)}"
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
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar n_matches = `n_matches'
    return local indicators "`matches'"
    return local keyword "`keyword'"
    if ("`dataflow'" != "") {
        return local dataflow "`dataflow'"
    }
    
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

*******************************************************************************
* _unicef_list_dataflows.ado
*! v 1.6.0   20Jan2026               by Joao Pedro Azevedo (UNICEF)
* List available UNICEF SDMX dataflows with indicator counts
* Uses direct file parsing for robust, yaml.ado-independent operation
*
* v1.5.3: BUGFIX - Include hyphen in indicator pattern regex
*         - Indicator codes like PT_F_15-19_FGM_TND were being skipped
* v1.5.2: BUGFIX - Check dataflows patterns BEFORE indicator pattern
*         - "dataflows:" was matching indicator regex, being treated as new indicator
*         - Now correctly parses dataflows field before checking for indicator entry
* v1.5.1: BUGFIX - Fixed parsing loop that skipped indicators after dataflows list
*         - When exiting dataflows list, re-process current line as new indicator
* v1.5.0: MAJOR REWRITE - Count indicators per dataflow from metadata
*         - Direct file parsing (no yaml.ado dependency)
*         - Default: count each indicator in its FIRST dataflow only
*         - DUPS option: count indicator in ALL its dataflows
*         - Similar output format to _unicef_list_categories
* v1.4.0: Direct dataset query instead of yaml get loop
* v1.3.0: Initial version using yaml list + yaml get loop
*******************************************************************************

program define _unicef_list_dataflows, rclass
    version 11.0
    
    syntax [, DETail DUPS VERBOSE METApath(string) SHOWALL SHOWTIER2 SHOWTIER3]
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata directory (YAML files in src/_/ alongside this ado)
        *-----------------------------------------------------------------------
        
        if ("`metapath'" == "") {
            * Find the helper program location (src/_/)
            capture findfile _unicef_list_dataflows.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                * Extract directory containing this ado file
                local ado_dir = subinstr("`ado_path'", "\", "/", .)
                local ado_dir = subinstr("`ado_dir'", "_unicef_list_dataflows.ado", "", .)
                local metapath "`ado_dir'"
            }
            
            * Fallback to PLUS directory _/
            if ("`metapath'" == "") | (!fileexists("`metapath'_unicefdata_indicators_metadata.yaml")) {
                local metapath "`c(sysdir_plus)'_/"
            }
        }
        
        * Use indicator metadata (has dataflows per indicator)
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
        
        *-----------------------------------------------------------------------
        * Tier filter setup (default = Tier 1 only)
        *-----------------------------------------------------------------------
        local tier_mode = 1
        local tier_filter "tier_1_only"
        if ("`showtier2'" != "") {
            local tier_mode = 2
            local tier_filter "tier_1_and_2"
        }
        if ("`showtier3'" != "") {
            local tier_mode = 3
            local tier_filter "tier_1_to_3"
        }
        if ("`showall'" != "") {
            local tier_mode = 999
            local tier_filter "all_tiers"
        }
        
        if ("`verbose'" != "") {
            noi di as text "Reading dataflows from: " as result "`yaml_file'"
            if ("`dups'" != "") {
                noi di as text "Mode: count indicators in ALL dataflows (dups)"
            }
            else {
                noi di as text "Mode: count indicators in FIRST dataflow only"
            }
            noi di as text "Tier filter: " as result "`tier_filter'"
        }
        
        *-----------------------------------------------------------------------
        * Parse YAML file directly to count indicators per dataflow
        *-----------------------------------------------------------------------
        
        * Initialize dataflow tracking (we'll build a list of unique dataflows)
        local all_dataflows ""
        local total_indicators = 0
        local total_with_dataflows = 0
        
        tempname fh
        file open `fh' using "`yaml_file'", read text
        
        * State tracking
        local in_indicators = 0
        local current_ind = ""
        local current_dataflows = ""
        local in_dataflows_list = 0
        local current_tier = ""
        
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
                    * Process final indicator if pending
                    if ("`current_ind'" != "" & "`current_dataflows'" != "") {
                        * Determine if current indicator is included by tier filter
                        local itier = "`current_tier'"
                        if ("`itier'" == "") local itier = "3"
                        local include = 0
                        if (`tier_mode' == 999) local include = 1
                        else if (`tier_mode' == 3 & inlist(real("`itier'"),1,2,3)) local include = 1
                        else if (`tier_mode' == 2 & inlist(real("`itier'"),1,2)) local include = 1
                        else if (`tier_mode' == 1 & real("`itier'") == 1) local include = 1
                        
                        if (`include') {
                            local total_indicators = `total_indicators' + 1
                            local total_with_dataflows = `total_with_dataflows' + 1
                            local current_dataflows = strtrim("`current_dataflows'")
                            
                            if ("`dups'" != "") {
                                * Count in ALL dataflows
                                foreach df of local current_dataflows {
                                    if (strpos(" `all_dataflows' ", " `df' ") == 0) {
                                        local all_dataflows "`all_dataflows' `df'"
                                        local count_`df' = 1
                                    }
                                    else {
                                        local count_`df' = `count_`df'' + 1
                                    }
                                }
                            }
                            else {
                                * Count in FIRST dataflow only
                                local first_df : word 1 of `current_dataflows'
                                if (strpos(" `all_dataflows' ", " `first_df' ") == 0) {
                                    local all_dataflows "`all_dataflows' `first_df'"
                                    local count_`first_df' = 1
                                }
                                else {
                                    local count_`first_df' = `count_`first_df'' + 1
                                }
                            }
                        }
                    }
                    else if ("`current_ind'" != "") {
                        * Indicator without dataflows; still count it if included
                        local itier = "`current_tier'"
                        if ("`itier'" == "") local itier = "3"
                        if (`tier_mode' == 999 | (`tier_mode' == 3 & inlist(real("`itier'"),1,2,3)) | ///
                            (`tier_mode' == 2 & inlist(real("`itier'"),1,2)) | ///
                            (`tier_mode' == 1 & real("`itier'") == 1)) {
                            local total_indicators = `total_indicators' + 1
                        }
                    }
                    local in_indicators = 0
                    file read `fh' line
                    continue
                }
                
                * Parse dataflows field FIRST (before indicator check)
                * This prevents "dataflows:" from matching indicator pattern
                
                * Inline list: dataflows: [CME, GLOBAL_DATAFLOW]
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
                
                * Single value: dataflows: CME
                if (regexm("`trimmed'", "^dataflows:[ ]*([A-Za-z0-9_]+)$")) {
                    local current_dataflows = regexs(1)
                    local in_dataflows_list = 0
                    file read `fh' line
                    continue
                }
                
                * Block list starting: dataflows:
                if (regexm("`trimmed'", "^dataflows:[ ]*$")) {
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
                    else {
                        * Not a list item - end of dataflows list
                        * DO NOT read next line - current line needs to be re-processed
                        local in_dataflows_list = 0
                        continue
                    }
                }
                
                * NOW detect new indicator entry (after checking for dataflows)
                * Pattern includes hyphen for codes like PT_F_15-19_FGM_TND
                if (regexm("`trimmed'", "^[A-Za-z][A-Za-z0-9_-]*:$")) {
                    
                    * Process previous indicator if exists
                    if ("`current_ind'" != "") {
                        local itier = "`current_tier'"
                        if ("`itier'" == "") local itier = "3"
                        local include = 0
                        if (`tier_mode' == 999) local include = 1
                        else if (`tier_mode' == 3 & inlist(real("`itier'"),1,2,3)) local include = 1
                        else if (`tier_mode' == 2 & inlist(real("`itier'"),1,2)) local include = 1
                        else if (`tier_mode' == 1 & real("`itier'") == 1) local include = 1
                        
                        if (`include') {
                            local total_indicators = `total_indicators' + 1
                            
                            if ("`current_dataflows'" != "") {
                                local total_with_dataflows = `total_with_dataflows' + 1
                                local current_dataflows = strtrim("`current_dataflows'")
                                
                                if ("`dups'" != "") {
                                    * Count in ALL dataflows
                                    foreach df of local current_dataflows {
                                        if (strpos(" `all_dataflows' ", " `df' ") == 0) {
                                            local all_dataflows "`all_dataflows' `df'"
                                            local count_`df' = 1
                                        }
                                        else {
                                            local count_`df' = `count_`df'' + 1
                                        }
                                    }
                                }
                                else {
                                    * Count in FIRST dataflow only
                                    local first_df : word 1 of `current_dataflows'
                                    if (strpos(" `all_dataflows' ", " `first_df' ") == 0) {
                                        local all_dataflows "`all_dataflows' `first_df'"
                                        local count_`first_df' = 1
                                    }
                                    else {
                                        local count_`first_df' = `count_`first_df'' + 1
                                    }
                                }
                            }
                        }
                    }
                    
                    * Start new indicator
                    local current_ind = subinstr("`trimmed'", ":", "", .)
                    local current_dataflows = ""
                    local in_dataflows_list = 0
                    local current_tier = ""
                    
                    file read `fh' line
                    continue
                }
            }
            
            * Parse tier value for current indicator
            if (`in_indicators' == 1) {
                if (regexm("`trimmed'", "^tier:[ ]*([0-9]+)$")) {
                    local current_tier = regexs(1)
                    file read `fh' line
                    continue
                }
            }
            
            file read `fh' line
        }
        
        * Process final indicator if exists
        if ("`current_ind'" != "" & `in_indicators' == 1) {
            local itier = "`current_tier'"
            if ("`itier'" == "") local itier = "3"
            local include = 0
            if (`tier_mode' == 999) local include = 1
            else if (`tier_mode' == 3 & inlist(real("`itier'"),1,2,3)) local include = 1
            else if (`tier_mode' == 2 & inlist(real("`itier'"),1,2)) local include = 1
            else if (`tier_mode' == 1 & real("`itier'") == 1) local include = 1
            
            if (`include') {
                local total_indicators = `total_indicators' + 1
                
                if ("`current_dataflows'" != "") {
                    local total_with_dataflows = `total_with_dataflows' + 1
                    local current_dataflows = strtrim("`current_dataflows'")
                    
                    if ("`dups'" != "") {
                        foreach df of local current_dataflows {
                            if (strpos(" `all_dataflows' ", " `df' ") == 0) {
                                local all_dataflows "`all_dataflows' `df'"
                                local count_`df' = 1
                            }
                            else {
                                local count_`df' = `count_`df'' + 1
                            }
                        }
                    }
                    else {
                        local first_df : word 1 of `current_dataflows'
                        if (strpos(" `all_dataflows' ", " `first_df' ") == 0) {
                            local all_dataflows "`all_dataflows' `first_df'"
                            local count_`first_df' = 1
                        }
                        else {
                            local count_`first_df' = `count_`first_df'' + 1
                        }
                    }
                }
            }
        }
        
        file close `fh'
        
        local all_dataflows = strtrim("`all_dataflows'")
        local n_dataflows : word count `all_dataflows'
        
        *-----------------------------------------------------------------------
        * Sort dataflows by count (descending), then name
        *-----------------------------------------------------------------------
        
        * Build parallel lists for sorting
        local sorted_dataflows ""
        local sorted_counts ""
        
        * Simple bubble sort by count (descending)
        local remaining "`all_dataflows'"
        while ("`remaining'" != "") {
            local max_count = 0
            local max_df = ""
            foreach df of local remaining {
                if (`count_`df'' > `max_count') {
                    local max_count = `count_`df''
                    local max_df = "`df'"
                }
            }
            local sorted_dataflows "`sorted_dataflows' `max_df'"
            local sorted_counts "`sorted_counts' `max_count'"
            * Remove from remaining
            local remaining : list remaining - max_df
        }
        
        local sorted_dataflows = strtrim("`sorted_dataflows'")
        local sorted_counts = strtrim("`sorted_counts'")
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    * Dynamic column widths based on screen size
    local linesize = c(linesize)
    local col_df = 2
    local col_count = 28
    local col_pct = 38
    
    noi di ""
    noi di as text "{hline `linesize'}"
    if ("`dups'" != "") {
        noi di as text "UNICEF Dataflows with Indicator Counts (counting duplicates)"
    }
    else {
        noi di as text "UNICEF Dataflows with Indicator Counts (first dataflow only)"
    }
    noi di as text "{hline `linesize'}"
    noi di ""
    noi di as text "Tier filter: " as result "`tier_filter'"
    noi di ""
    
    if (`n_dataflows' == 0) {
        noi di as text "  No dataflows found with indicators."
        noi di as text "  Run 'unicefdata_sync' to download metadata."
    }
    else {
        noi di as text _col(`col_df') "{ul:Dataflow}" _col(`col_count') "{ul:Count}" _col(`col_pct') "{ul:Pct}"
        noi di ""
        
        * Calculate total for percentage
        local display_total = 0
        forvalues i = 1/`n_dataflows' {
            local cnt : word `i' of `sorted_counts'
            local display_total = `display_total' + `cnt'
        }
        
        forvalues i = 1/`n_dataflows' {
            local df : word `i' of `sorted_dataflows'
            local cnt : word `i' of `sorted_counts'
            local pct = 100 * `cnt' / `display_total'
            
            * Clickable link to show indicators in this dataflow
            noi di as text _col(`col_df') "{stata unicefdata, indicators(`df'):`df'}" _col(`col_count') as result %5.0f `cnt' _col(`col_pct') as text %5.1f `pct' "%"
        }
    }
    
    noi di ""
    noi di as text "{hline `linesize'}"
    if ("`dups'" != "") {
        noi di as text "Total: " as result `display_total' as text " indicator assignments across " as result `n_dataflows' as text " dataflows"
        noi di as text "{it:Note: Indicators counted in ALL their dataflows (use without dups for unique counts)}"
    }
    else {
        noi di as text "Total: " as result `total_with_dataflows' as text " indicators with dataflows, " as result `n_dataflows' as text " unique dataflows"
        noi di as text "{it:Note: Each indicator counted in FIRST dataflow only (use dups option to count in all)}"
    }
    noi di as text "{hline `linesize'}"
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar n_dataflows = `n_dataflows'
    return scalar n_indicators = `total_with_dataflows'
    return local dataflow_ids "`sorted_dataflows'"
    return local counts "`sorted_counts'"
    return local yaml_file "`yaml_file'"
    return scalar tier_mode = `tier_mode'
    return local tier_filter "`tier_filter'"
    
end

*******************************************************************************
* Version history
*******************************************************************************
* v 1.6.0   20Jan2026   by Joao Pedro Azevedo
*   - NEW: Tier-aware filtering (default Tier 1; showtier2/showtier3/showall)
*   - Display and return tier filter metadata (r(tier_mode), r(tier_filter))
*   - Parity with _unicef_list_categories tier behavior
*
* v 1.5.0   16Jan2026   by Joao Pedro Azevedo
*   - MAJOR REWRITE: Count indicators per dataflow from metadata
*   - Direct file parsing (no yaml.ado dependency)
*   - Default: count each indicator in its FIRST dataflow only
*   - DUPS option: count indicator in ALL its dataflows
*   - Similar output format to _unicef_list_categories
*   - Version 11.0 compatible
*
* v 1.4.0   19Dec2025   by Joao Pedro Azevedo
*   - Direct dataset query instead of yaml get loop
*
* v 1.3.0   by Joao Pedro Azevedo
*   - Initial version using yaml list + yaml get loop
*******************************************************************************

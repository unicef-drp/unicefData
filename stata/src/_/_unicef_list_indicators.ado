*******************************************************************************
* _unicef_list_indicators.ado
*! v 1.6.0   16Jan2026               by Joao Pedro Azevedo (UNICEF)
* List UNICEF indicators for a specific dataflow using YAML metadata
* v1.6.0: REWRITE - Direct file parsing (yaml.ado list flattening incompatible)
* v1.5.0: Fix: Use 'dataflows' field (not 'category') to filter by dataflow
* v1.4.0: PERFORMANCE - Direct dataset query instead of yaml get loop
*******************************************************************************

program define _unicef_list_indicators, rclass
    version 11
    
    syntax , Dataflow(string) [VERBOSE METApath(string)]
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata file
        *-----------------------------------------------------------------------
        
        local plus_dir "`c(sysdir_plus)'"
        local yaml_file ""
        
        * Try the most common location first
        capture confirm file "`plus_dir'_/_unicefdata_indicators_metadata.yaml"
        if !_rc {
            local yaml_file "`plus_dir'_/_unicefdata_indicators_metadata.yaml"
        }
        
        * Fallback paths
        if "`yaml_file'" == "" {
            local candidate_paths ///
                "_unicefdata_indicators_metadata.yaml" ///
                "`plus_dir'_unicefdata_indicators_metadata.yaml" ///
                "stata/src/_/_unicefdata_indicators_metadata.yaml"

            foreach path of local candidate_paths {
                capture confirm file "`path'"
                if !_rc {
                    local yaml_file "`path'"
                    continue, break
                }
            }
        }
        
        if "`yaml_file'" == "" {
            noi di as err "Indicators metadata not found."
            noi di as err "Run 'unicefdata_sync' to download metadata."
            exit 601
        }
        
        if ("`verbose'" != "") {
            noi di as text "Reading indicators from: " as result "`yaml_file'"
        }
        
        *-----------------------------------------------------------------------
        * Direct file parsing: scan for indicators with matching dataflow
        *-----------------------------------------------------------------------
        
        local dataflow_upper = upper("`dataflow'")
        local matches ""
        local match_names ""
        local n_matches = 0
        
        tempname fh
        local current_indicator ""
        local current_name ""
        local current_dataflows ""
        local in_indicator = 0
        local in_dataflows = 0
        
        file open `fh' using "`yaml_file'", read text
        file read `fh' line
        
        while r(eof) == 0 {
            local trimmed = strtrim(`"`line'"')
            
            * Look for indicator entries (2 spaces + code + colon, not 4 spaces)
            local is_indicator_line = 0
            if (substr(`"`line'"', 1, 2) == "  " & substr(`"`line'"', 3, 1) != " ") {
                if (strpos(`"`line'"', ":") > 0) {
                    local is_indicator_line = 1
                }
            }
            
            if (`is_indicator_line' == 1) {
                * Save previous indicator if it matches the dataflow
                if ("`current_indicator'" != "" & strpos(upper("`current_dataflows'"), "`dataflow_upper'") > 0) {
                    local ++n_matches
                    local matches "`matches' `current_indicator'"
                    local match_names `"`match_names' "`current_name'""'
                }
                
                * Start new indicator
                local current_indicator = subinstr(`"`trimmed'"', ":", "", 1)
                local current_name ""
                local current_dataflows ""
                local in_indicator = 1
                local in_dataflows = 0
            }
            else if (`in_indicator' == 1) {
                * Look for name field
                if (strmatch(`"`trimmed'"', "name:*")) {
                    local after_colon = subinstr(`"`trimmed'"', "name:", "", 1)
                    local current_name = strtrim("`after_colon'")
                    * Remove surrounding quotes if present
                    local current_name = subinstr("`current_name'", "'", "", .)
                    local current_name = subinstr("`current_name'", `"""', "", .)
                }
                * Look for dataflows field
                else if (strmatch(`"`trimmed'"', "dataflows:*")) {
                    local in_dataflows = 1
                    * Check for inline value (dataflows: CME)
                    local after_colon = subinstr(`"`trimmed'"', "dataflows:", "", 1)
                    local after_colon = strtrim("`after_colon'")
                    if ("`after_colon'" != "") {
                        local current_dataflows "`after_colon'"
                        local in_dataflows = 0
                    }
                }
                else if (`in_dataflows' == 1) {
                    * Collect dataflow list items
                    if (strmatch(`"`trimmed'"', "- *")) {
                        local df_value = subinstr(`"`trimmed'"', "- ", "", 1)
                        local df_value = strtrim("`df_value'")
                        local current_dataflows "`current_dataflows' `df_value'"
                    }
                    else if ("`trimmed'" != "" & !strmatch(`"`trimmed'"', "- *")) {
                        local in_dataflows = 0
                    }
                }
            }
            
            file read `fh' line
        }
        
        * Save last indicator if matches
        if ("`current_indicator'" != "" & strpos(upper("`current_dataflows'"), "`dataflow_upper'") > 0) {
            local ++n_matches
            local matches "`matches' `current_indicator'"
            local match_names `"`match_names' "`current_name'""'
        }
        
        file close `fh'
        
        local matches = strtrim("`matches'")
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    * Dynamic column widths based on screen size
    local linesize = c(linesize)
    local col_ind = 2
    local col_name = 27
    local name_width = `linesize' - `col_name' - 2
    if (`name_width' < 30) local name_width = 30
    
    noi di ""
    noi di as text "{hline `linesize'}"
    noi di as text "Indicators in Dataflow: " as result "`dataflow_upper'"
    noi di as text "{hline `linesize'}"
    noi di ""
    
    if (`n_matches' == 0) {
        noi di as text "  No indicators found for dataflow '`dataflow_upper'"
        noi di as text "  Use {stata unicefdata, flows:unicefdata, flows} to see available dataflows."
    }
    else {
        noi di as text _col(`col_ind') "{ul:Indicator}" _col(`col_name') "{ul:Name}"
        noi di ""
        
        forvalues i = 1/`n_matches' {
            local ind : word `i' of `matches'
            local nm : word `i' of `match_names'
            
            * Truncate name based on available width
            if (length("`nm'") > `name_width') {
                local nm = substr("`nm'", 1, `name_width' - 3) + "..."
            }
            
            * Use info() for safer navigation
            noi di as text _col(`col_ind') "{stata unicefdata, info(`ind'):`ind'}" as text _col(`col_name') "`nm'"
        }
    }
    
    noi di ""
    noi di as text "{hline `linesize'}"
    noi di as text "Total: " as result `n_matches' as text " indicator(s) in `dataflow_upper'"
    noi di as text "{hline `linesize'}"
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar n_indicators = `n_matches'
    return local indicators "`matches'"
    return local dataflow "`dataflow_upper'"
    
end

*! version 1.3.0  16jan2026
*! _get_dataflow_direct: Get dataflow for indicator(s) via direct YAML metadata lookup
*! Author: João Pedro Azevedo
*! Returns: Dataflow(s) from comprehensive indicators metadata
*! v1.3.0: Hybrid approach - direct parsing for few indicators, frames for many (Stata 16+)
*! v1.2.0: Direct file parsing for fast lookup (O(n) scan but no YAML load overhead)
*! v1.1.0: Properly reads 'dataflows' list field from enriched metadata

program define _get_dataflow_direct, rclass
    version 11
    syntax anything(name=indicators)

    * Count how many indicators
    local n_indicators : word count `indicators'
    
    * Find the comprehensive metadata YAML file
    local plus_dir "`c(sysdir_plus)'"
    
    local yaml_file ""
    
    * Try the most common location first (plus directory _ subfolder)
    capture confirm file "`plus_dir'_/_unicefdata_indicators_metadata.yaml"
    if !_rc {
        local yaml_file "`plus_dir'_/_unicefdata_indicators_metadata.yaml"
    }
    
    * If not found, try alternative paths
    if "`yaml_file'" == "" {
        local candidate_paths ///
            "`plus_dir'_\_unicefdata_indicators_metadata.yaml" ///
            "_unicefdata_indicators_metadata.yaml" ///
            "`plus_dir'_unicefdata_indicators_metadata.yaml" ///
            "stata/src/_/_unicefdata_indicators_metadata.yaml" ///
            "src/_/_unicefdata_indicators_metadata.yaml"

        foreach path of local candidate_paths {
            capture confirm file "`path'"
            if !_rc {
                local yaml_file "`path'"
                continue, break
            }
        }
    }

    * If YAML not found, fall back to old method for all indicators
    if "`yaml_file'" == "" {
        noisily di as text "Warning: Indicators metadata not found, using prefix-based fallback"
        local all_dataflows ""
        local first_dataflow ""
        foreach ind of local indicators {
            _get_dataflow_for_indicator `ind'
            if ("`first_dataflow'" == "") {
                local first_dataflow "`r(first)'"
            }
            local all_dataflows "`all_dataflows' `r(dataflows)'"
        }
        local all_dataflows = strtrim(stritrim("`all_dataflows'"))
        return local dataflows "`all_dataflows'"
        return local first "`first_dataflow'"
        return local source "fallback"
        exit 0
    }

    * Decide strategy based on number of indicators and Stata version
    * Frames available in Stata 16+ (version 16.0 = 16)
    local use_frames = 0
    local threshold = 3  // Use frames for 4+ indicators
    
    if (`n_indicators' > `threshold') {
        * Check if Stata supports frames (version 16+)
        if (c(stata_version) >= 16) {
            local use_frames = 1
        }
    }

    * =========================================================================
    * FRAMES APPROACH: Load once, query many (Stata 16+ with 4+ indicators)
    * =========================================================================
    if (`use_frames' == 1) {
        * Check if frame already exists from previous call
        local frame_exists = 0
        capture frame _unicef_meta_cache: describe, short
        if !_rc {
            local frame_exists = 1
        }
        
        * Load into frame if not already loaded
        if (`frame_exists' == 0) {
            * Create frame and build cache
            capture frame create _unicef_meta_cache str50 indicator str200 dataflows
            if _rc {
                * Frame creation failed, fall back to direct parsing
                local use_frames = 0
            }
            else {
                * Parse the YAML file and populate the frame
                quietly _get_dataflow_direct_build_cache "`yaml_file'"
            }
        }
        
        * Query from frame
        if (`use_frames' == 1) {
            local all_dataflows ""
            local first_dataflow ""
            local all_sources ""
            
            frame _unicef_meta_cache {
                foreach ind of local indicators {
                    quietly count if indicator == "`ind'"
                    if (r(N) > 0) {
                        quietly levelsof dataflows if indicator == "`ind'", local(df) clean
                        if ("`first_dataflow'" == "") {
                            local first_dataflow : word 1 of `df'
                        }
                        local all_dataflows "`all_dataflows' `df'"
                        local all_sources "`all_sources' metadata"
                    }
                    else {
                        * Not in cache, mark for fallback
                        local all_sources "`all_sources' fallback"
                    }
                }
            }
            
            * Handle any indicators not found in cache
            local i = 1
            foreach ind of local indicators {
                local src : word `i' of `all_sources'
                if ("`src'" == "fallback") {
                    _get_dataflow_for_indicator `ind'
                    if ("`first_dataflow'" == "") {
                        local first_dataflow "`r(first)'"
                    }
                    local all_dataflows "`all_dataflows' `r(dataflows)'"
                }
                local i = `i' + 1
            }
            
            local all_dataflows = strtrim(stritrim("`all_dataflows'"))
            return local dataflows "`all_dataflows'"
            return local first "`first_dataflow'"
            return local source "metadata_cached"
            return local method "frames"
            exit 0
        }
    }

    * =========================================================================
    * DIRECT PARSING APPROACH: Scan file for each indicator (Stata 11+ or few indicators)
    * =========================================================================
    local all_dataflows ""
    local first_dataflow ""
    local all_sources ""
    
    foreach indicator of local indicators {
        * Direct file scan: search for the indicator entry and extract dataflows
        tempname fh
        local found = 0
        local in_indicator = 0
        local in_dataflows = 0
        local dataflows_list ""
        
        file open `fh' using "`yaml_file'", read text
        file read `fh' line
        
        while r(eof) == 0 {
            local trimmed = strtrim(`"`line'"')
            
            * Look for the indicator entry (top-level key under indicators:)
            * Format: "  CME_ARR_10T19:" (2 spaces, code, colon)
            if (`in_indicator' == 0) {
                if (strmatch(`"`line'"', "  `indicator':")) {
                    local found = 1
                    local in_indicator = 1
                }
            }
            else {
                * We're inside the indicator block - check for end or dataflows
                
                * Check if we've left this indicator (another top-level key)
                * Top-level keys have exactly 2 leading spaces
                local first_chars = substr(`"`line'"', 1, 4)
                if ("`first_chars'" == "  " & substr(`"`line'"', 3, 1) != " " & strpos(`"`line'"', ":") > 0) {
                    * This is a new indicator entry - stop
                    continue, break
                }
                
                * Look for dataflows field (4 spaces: "    dataflows:")
                if (strmatch(`"`trimmed'"', "dataflows:*")) {
                    local in_dataflows = 1
                    * Check if it's an inline value (dataflows: CME)
                    local after_colon = subinstr(`"`trimmed'"', "dataflows:", "", 1)
                    local after_colon = strtrim("`after_colon'")
                    if ("`after_colon'" != "") {
                        * Inline scalar value
                        local dataflows_list "`after_colon'"
                        continue, break
                    }
                }
                else if (`in_dataflows' == 1) {
                    * We're in the dataflows list - collect items
                    * Format: "      - CME" (6 spaces, dash, space, value)
                    if (strmatch(`"`trimmed'"', "- *")) {
                        local df_value = subinstr(`"`trimmed'"', "- ", "", 1)
                        local df_value = strtrim("`df_value'")
                        if ("`dataflows_list'" == "") {
                            local dataflows_list "`df_value'"
                        }
                        else {
                            local dataflows_list "`dataflows_list' `df_value'"
                        }
                    }
                    else if ("`trimmed'" != "") {
                        * Non-list line after dataflows list - we're done
                        continue, break
                    }
                }
            }
            
            file read `fh' line
        }
        
        file close `fh'

        * Process results for this indicator
        if (`found' == 1 & "`dataflows_list'" != "") {
            if ("`first_dataflow'" == "") {
                local first_dataflow : word 1 of `dataflows_list'
            }
            local all_dataflows "`all_dataflows' `dataflows_list'"
            local all_sources "`all_sources' metadata"
        }
        else {
            * Fall back to prefix-based approach for this indicator
            if (`found' == 0) {
                noisily di as text "Warning: `indicator' not found in metadata, using prefix-based fallback"
            }
            else {
                noisily di as text "Warning: `indicator' has no dataflows in metadata, using prefix-based fallback"
            }
            
            _get_dataflow_for_indicator `indicator'
            if ("`first_dataflow'" == "") {
                local first_dataflow "`r(first)'"
            }
            local all_dataflows "`all_dataflows' `r(dataflows)'"
            local all_sources "`all_sources' fallback"
        }
    }

    * Return combined results
    local all_dataflows = strtrim(stritrim("`all_dataflows'"))
    return local dataflows "`all_dataflows'"
    return local first "`first_dataflow'"
    
    * Determine overall source
    if (strpos("`all_sources'", "fallback") > 0) {
        if (strpos("`all_sources'", "metadata") > 0) {
            return local source "mixed"
        }
        else {
            return local source "fallback"
        }
    }
    else {
        return local source "metadata"
    }
    return local method "direct"

end

* =============================================================================
* Helper program: Build the metadata cache frame (Stata 16+ only)
* =============================================================================
program define _get_dataflow_direct_build_cache
    version 16
    args yaml_file
    
    * Parse the entire YAML file and populate the cache frame
    tempname fh
    local current_indicator ""
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
            * Save previous indicator if we have one
            if ("`current_indicator'" != "" & "`current_dataflows'" != "") {
                frame post _unicef_meta_cache ("`current_indicator'") ("`current_dataflows'")
            }
            
            * Start new indicator
            local current_indicator = subinstr(`"`trimmed'"', ":", "", 1)
            local current_dataflows ""
            local in_indicator = 1
            local in_dataflows = 0
        }
        else if (`in_indicator' == 1) {
            * Look for dataflows field
            if (strmatch(`"`trimmed'"', "dataflows:*")) {
                local in_dataflows = 1
                local after_colon = subinstr(`"`trimmed'"', "dataflows:", "", 1)
                local after_colon = strtrim("`after_colon'")
                if ("`after_colon'" != "") {
                    local current_dataflows "`after_colon'"
                    local in_dataflows = 0
                }
            }
            else if (`in_dataflows' == 1) {
                if (strmatch(`"`trimmed'"', "- *")) {
                    local df_value = subinstr(`"`trimmed'"', "- ", "", 1)
                    local df_value = strtrim("`df_value'")
                    if ("`current_dataflows'" == "") {
                        local current_dataflows "`df_value'"
                    }
                    else {
                        local current_dataflows "`current_dataflows' `df_value'"
                    }
                }
                else if ("`trimmed'" != "" & !strmatch(`"`trimmed'"', "- *")) {
                    local in_dataflows = 0
                }
            }
        }
        
        file read `fh' line
    }
    
    * Save last indicator
    if ("`current_indicator'" != "" & "`current_dataflows'" != "") {
        frame post _unicef_meta_cache ("`current_indicator'") ("`current_dataflows'")
    }
    
    file close `fh'

end

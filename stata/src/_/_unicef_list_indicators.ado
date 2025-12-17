*******************************************************************************
* _unicef_list_indicators.ado
*! v 1.3.2   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* List UNICEF indicators for a specific dataflow using YAML metadata
* Uses yaml.ado for robust YAML parsing
* Uses Stata frames (v16+) for better isolation when available
* v1.3.2: Fix frame naming - use explicit yaml_ prefix for frame() option
*******************************************************************************

program define _unicef_list_indicators, rclass
    version 14.0
    
    syntax , Dataflow(string) [VERBOSE METApath(string)]
    
    * Check if frames are available (Stata 16+)
    local use_frames = (c(stata_version) >= 16)
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata directory (YAML files in src/_/ alongside this ado)
        *-----------------------------------------------------------------------
        
        if ("`metapath'" == "") {
            * Find the helper program location (src/_/)
            capture findfile _unicef_list_indicators.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                * Extract directory containing this ado file
                local ado_dir = subinstr("`ado_path'", "\", "/", .)
                local ado_dir = subinstr("`ado_dir'", "_unicef_list_indicators.ado", "", .)
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
            noi di as text "Reading indicators from: " as result "`yaml_file'"
        }
        
        *-----------------------------------------------------------------------
        * Read YAML file and filter by category (frames for Stata 16+)
        *-----------------------------------------------------------------------
        
        local dataflow_upper = upper("`dataflow'")
        local matches ""
        local match_names ""
        local n_matches = 0
        
        if (`use_frames') {
            * Stata 16+ - use frames for better isolation
            * Note: yaml.ado prefixes frame names with "yaml_"
            local yaml_frame_base "unicef_indicators"
            local yaml_frame "yaml_`yaml_frame_base'"
            capture frame drop `yaml_frame'
            
            * Read YAML into a frame (yaml.ado will prefix with "yaml_")
            yaml read using "`yaml_file'", frame(`yaml_frame_base')
            
            * Use the actual frame name (with yaml_ prefix)
            frame `yaml_frame' {
                * Get all indicator codes under 'indicators' parent
                yaml list indicators, keys children frame(`yaml_frame_base')
                local all_indicators "`r(keys)'"
                
                foreach ind of local all_indicators {
                    * Get category attribute for this indicator
                    capture yaml get indicators:`ind', attributes(category name) quiet frame(`yaml_frame_base')
                    if (_rc == 0) {
                        local ind_df = upper("`r(category)'")
                        if ("`ind_df'" == "`dataflow_upper'") {
                            local ++n_matches
                            local matches "`matches' `ind'"
                            local match_names `"`match_names' "`r(name)'""'
                        }
                    }
                }
            }
            
            * Clean up frame
            capture frame drop `yaml_frame'
        }
        else {
            * Stata 14/15 - use preserve/restore
            preserve
            
            yaml read using "`yaml_file'", replace
            
            * Get all indicator codes under 'indicators' parent
            yaml list indicators, keys children
            local all_indicators "`r(keys)'"
            
            foreach ind of local all_indicators {
                * Get category attribute for this indicator
                capture yaml get indicators:`ind', attributes(category name) quiet
                if (_rc == 0) {
                    local ind_df = upper("`r(category)'")
                    if ("`ind_df'" == "`dataflow_upper'") {
                        local ++n_matches
                        local matches "`matches' `ind'"
                        local match_names `"`match_names' "`r(name)'""'
                    }
                }
            }
            
            restore
        }
        
        local matches = strtrim("`matches'")
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Indicators in Dataflow: " as result "`dataflow_upper'"
    noi di as text "{hline 70}"
    noi di ""
    
    if (`n_matches' == 0) {
        noi di as text "  No indicators found for dataflow '`dataflow_upper'"
        noi di as text "  Use 'unicefdata, flows' to see available dataflows."
    }
    else {
        noi di as text _col(2) "{ul:Indicator}" _col(25) "{ul:Name}"
        noi di ""
        
        forvalues i = 1/`n_matches' {
            local ind : word `i' of `matches'
            local nm : word `i' of `match_names'
            
            * Truncate name if too long
            if (length("`nm'") > 45) {
                local nm = substr("`nm'", 1, 42) + "..."
            }
            
            noi di as result _col(2) "`ind'" as text _col(25) "`nm'"
        }
    }
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Total: " as result `n_matches' as text " indicator(s) in `dataflow_upper'"
    noi di as text "{hline 70}"
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar n_indicators = `n_matches'
    return local indicators "`matches'"
    return local dataflow "`dataflow_upper'"
    
end

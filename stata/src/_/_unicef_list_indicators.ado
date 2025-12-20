*******************************************************************************
* _unicef_list_indicators.ado
*! v 1.4.0   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* List UNICEF indicators for a specific dataflow using YAML metadata
* v1.4.0: PERFORMANCE - Direct dataset query instead of yaml get loop
*         Reduces 733 yaml get calls to single dataset filter (~50x faster)
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
        * Read YAML file and filter by category using direct dataset query
        * v1.4.0: Much faster than iterating with yaml get
        * yaml.ado creates dataset with: key, value, level, parent, type
        * Keys are flattened paths like: indicators_CME_MRY0T4_category
        *-----------------------------------------------------------------------
        
        local dataflow_upper = upper("`dataflow'")
        local matches ""
        local match_names ""
        local n_matches = 0
        
        if (`use_frames') {
            * Stata 16+ - use frames for better isolation
            local yaml_frame_base "unicef_indicators"
            local yaml_frame "yaml_`yaml_frame_base'"
            capture frame drop `yaml_frame'
            
            * Read YAML into a frame (yaml.ado will prefix with "yaml_")
            yaml read using "`yaml_file'", frame(`yaml_frame_base')
            
            * Use the actual frame name (with yaml_ prefix)
            frame `yaml_frame' {
                * v1.4.0: Direct dataset query using flattened key structure
                * Category keys look like: indicators_CME_MRY0T4_category
                * Name keys look like: indicators_CME_MRY0T4_name
                * EXCLUDE: description metadata like indicators_CME_ARR_U5MR_description_category
                
                * Keep only rows where value matches the requested dataflow (category rows)
                * First identify category rows for our dataflow
                * Exclude keys containing "_description_" which are metadata entries
                gen is_match = regexm(key, "^indicators_[A-Za-z0-9_]+_category$") & upper(value) == "`dataflow_upper'" & !strpos(key, "_description_")
                
                * Get the indicator codes from matching category rows
                * Extract indicator code: indicators_CODE_category -> CODE
                gen indicator_code = regexs(1) if regexm(key, "^indicators_([A-Za-z0-9_]+)_category$")
                
                * Save matching indicator codes (exclude any that end with _description)
                levelsof indicator_code if is_match == 1 & !regexm(indicator_code, "_description$"), local(matching_indicators) clean
                
                * For each matching indicator, get its name
                foreach ind of local matching_indicators {
                    local ++n_matches
                    local matches "`matches' `ind'"
                    
                    * Get name: key = indicators_`ind'_name
                    capture levelsof value if key == "indicators_`ind'_name", local(ind_name) clean
                    if (_rc != 0) local ind_name ""
                    local match_names `"`match_names' "`ind_name'""'
                }
            }
            
            * Clean up frame
            capture frame drop `yaml_frame'
        }
        else {
            * Stata 14/15 - use preserve/restore
            preserve
            
            yaml read using "`yaml_file'", replace
            
            * v1.4.0: Direct dataset query using flattened key structure
            * Exclude keys containing "_description_" which are metadata entries
            gen is_match = regexm(key, "^indicators_[A-Za-z0-9_]+_category$") & upper(value) == "`dataflow_upper'" & !strpos(key, "_description_")
            gen indicator_code = regexs(1) if regexm(key, "^indicators_([A-Za-z0-9_]+)_category$")
            
            levelsof indicator_code if is_match == 1 & !regexm(indicator_code, "_description$"), local(matching_indicators) clean
            
            foreach ind of local matching_indicators {
                local ++n_matches
                local matches "`matches' `ind'"
                
                capture levelsof value if key == "indicators_`ind'_name", local(ind_name) clean
                if (_rc != 0) local ind_name ""
                local match_names `"`match_names' "`ind_name'""'
            }
            
            restore
        }
        
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
            
            * Use info() for safer navigation (doesn't fail for meta-indicators)
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

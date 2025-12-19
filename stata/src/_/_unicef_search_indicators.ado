*******************************************************************************
* _unicef_search_indicators.ado
*! v 1.4.0   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* Search UNICEF indicators by keyword using YAML metadata
* Uses yaml.ado for robust YAML parsing
* Uses Stata frames (v16+) for better isolation when available
*
* v1.4.0: MAJOR REWRITE - Direct dataset query instead of 733 yaml get calls
*         - Much faster: single dataset operations vs individual lookups
*         - More robust: avoids frame context/return value issues
* v1.3.2: Fixed frame naming (use explicit yaml_ prefix for clarity)
* v1.3.1: Added dataflow() filter option (aligned with Python/R category filter)
*******************************************************************************

program define _unicef_search_indicators, rclass
    version 14.0
    
    syntax , Keyword(string) [Limit(integer 20) DATAFLOW(string) VERBOSE METApath(string)]
    
    * Check if frames are available (Stata 16+)
    local use_frames = (c(stata_version) >= 16)
    
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
        * Read YAML and search using direct dataset operations
        * This is MUCH faster than calling yaml get for each indicator
        *-----------------------------------------------------------------------
        
        local keyword_lower = lower("`keyword'")
        local matches ""
        local match_names ""
        local match_dataflows ""
        local n_matches = 0
        
        if (`use_frames') {
            *-------------------------------------------------------------------
            * Stata 16+ - use frames for better isolation
            *-------------------------------------------------------------------
            local yaml_frame_base "unicef_search"
            local yaml_frame "yaml_`yaml_frame_base'"
            capture frame drop `yaml_frame'
            
            * Read YAML into a frame (yaml.ado stores as key/value dataset)
            yaml read using "`yaml_file'", frame(`yaml_frame_base')
            
            * Work directly with the dataset in the frame
            frame `yaml_frame' {
                * yaml.ado creates keys like: indicators_CME_MRM0_code, indicators_CME_MRM0_name, etc.
                * Keep only code, name, category rows under indicators
                keep if regexm(key, "^indicators_[A-Za-z0-9_]+_(code|name|category)$")
                
                * Extract indicator ID and attribute type from key
                * Key format: indicators_<INDICATOR_ID>_<attribute>
                * We need to extract INDICATOR_ID (which may contain underscores)
                
                * Get the attribute (last part after final underscore)
                gen attribute = ""
                replace attribute = "code" if regexm(key, "_code$")
                replace attribute = "name" if regexm(key, "_name$")
                replace attribute = "category" if regexm(key, "_category$")
                
                * Extract indicator ID (between "indicators_" and "_code/name/category")
                gen ind_id = regexs(1) if regexm(key, "^indicators_(.+)_(code|name|category)$")
                
                * Reshape to wide: one row per indicator with code, name, category columns
                keep ind_id attribute value
                reshape wide value, i(ind_id) j(attribute) string
                
                * Rename for clarity
                capture rename valuecode code
                capture rename valuename name
                capture rename valuecategory category
                
                * Handle missing values
                capture replace code = ind_id if missing(code) | code == ""
                capture replace name = "" if missing(name)
                capture replace category = "N/A" if missing(category) | category == ""
                
                * Create lowercase versions for case-insensitive search
                gen code_lower = lower(code)
                gen name_lower = lower(name)
                
                * Search for keyword in code or name
                gen found = (strpos(code_lower, "`keyword_lower'") > 0) | ///
                            (strpos(name_lower, "`keyword_lower'") > 0)
                
                * Apply dataflow filter if specified
                if ("`dataflow'" != "") {
                    local df_upper = upper("`dataflow'")
                    gen cat_upper = upper(category)
                    replace found = 0 if cat_upper != "`df_upper'"
                    drop cat_upper
                }
                
                * Keep only matches
                keep if found == 1
                
                * Sort by code for consistent output
                sort code
                
                * Limit results
                local n_matches = _N
                if (`n_matches' > `limit') {
                    keep in 1/`limit'
                    local n_matches = `limit'
                }
                
                * Extract results into locals
                forvalues i = 1/`n_matches' {
                    local ind_code = code[`i']
                    local ind_name = name[`i']
                    local ind_cat = category[`i']
                    
                    local matches "`matches' `ind_code'"
                    local match_names `"`match_names' "`ind_name'""'
                    local match_dataflows "`match_dataflows' `ind_cat'"
                }
            }
            
            * Clean up frame
            capture frame drop `yaml_frame'
        }
        else {
            *-------------------------------------------------------------------
            * Stata 14/15 - use preserve/restore
            *-------------------------------------------------------------------
            preserve
            
            * Read YAML (replaces current dataset)
            yaml read using "`yaml_file'", replace
            
            * Keep only code, name, category rows under indicators
            keep if regexm(key, "^indicators_[A-Za-z0-9_]+_(code|name|category)$")
            
            * Extract attribute type from key
            gen attribute = ""
            replace attribute = "code" if regexm(key, "_code$")
            replace attribute = "name" if regexm(key, "_name$")
            replace attribute = "category" if regexm(key, "_category$")
            
            * Extract indicator ID
            gen ind_id = regexs(1) if regexm(key, "^indicators_(.+)_(code|name|category)$")
            
            * Reshape to wide
            keep ind_id attribute value
            reshape wide value, i(ind_id) j(attribute) string
            
            * Rename for clarity
            capture rename valuecode code
            capture rename valuename name
            capture rename valuecategory category
            
            * Handle missing values
            capture replace code = ind_id if missing(code) | code == ""
            capture replace name = "" if missing(name)
            capture replace category = "N/A" if missing(category) | category == ""
            
            * Search
            gen code_lower = lower(code)
            gen name_lower = lower(name)
            gen found = (strpos(code_lower, "`keyword_lower'") > 0) | ///
                        (strpos(name_lower, "`keyword_lower'") > 0)
            
            * Apply dataflow filter if specified
            if ("`dataflow'" != "") {
                local df_upper = upper("`dataflow'")
                gen cat_upper = upper(category)
                replace found = 0 if cat_upper != "`df_upper'"
                drop cat_upper
            }
            
            * Keep only matches
            keep if found == 1
            sort code
            
            * Limit results
            local n_matches = _N
            if (`n_matches' > `limit') {
                keep in 1/`limit'
                local n_matches = `limit'
            }
            
            * Extract results
            forvalues i = 1/`n_matches' {
                local ind_code = code[`i']
                local ind_name = name[`i']
                local ind_cat = category[`i']
                
                local matches "`matches' `ind_code'"
                local match_names `"`match_names' "`ind_name'""'
                local match_dataflows "`match_dataflows' `ind_cat'"
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
    if ("`dataflow'" != "") {
        noi di as text "Search Results for: " as result "`keyword'" as text " in " as result "`dataflow'"
    }
    else {
        noi di as text "Search Results for: " as result "`keyword'"
    }
    noi di as text "{hline 70}"
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
        noi di as text "  - Use {bf:unicefdata, categories} to see available dataflows"
        noi di as text "  - Use {bf:unicefdata, search(keyword)} without dataflow filter"
    }
    else {
        noi di as text _col(2) "{ul:Indicator}" _col(20) "{ul:Dataflow}" _col(35) "{ul:Name}"
        noi di ""
        
        forvalues i = 1/`n_matches' {
            local ind : word `i' of `matches'
            local df : word `i' of `match_dataflows'
            local nm : word `i' of `match_names'
            
            * Truncate name if too long
            if (length("`nm'") > 35) {
                local nm = substr("`nm'", 1, 32) + "..."
            }
            
            noi di as result _col(2) "`ind'" as text _col(20) "`df'" _col(35) "`nm'"
        }
        
        if (`n_matches' >= `limit') {
            noi di ""
            noi di as text "  (Showing first `limit' matches. Use limit() option for more.)"
        }
    }
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Found: " as result `n_matches' as text " indicator(s)"
    noi di as text "{hline 70}"
    
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

*******************************************************************************
* _unicef_indicator_info.ado
*! v 1.3.0   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* Display detailed info about a specific UNICEF indicator using YAML metadata
* Uses yaml.ado for robust YAML parsing
* Uses Stata frames (v16+) for better isolation when available
*******************************************************************************

program define _unicef_indicator_info, rclass
    version 14.0
    
    syntax , Indicator(string) [VERBOSE METApath(string)]
    
    * Check if frames are available (Stata 16+)
    local use_frames = (c(stata_version) >= 16)
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata directory (YAML files in src/_/ alongside this ado)
        *-----------------------------------------------------------------------
        
        if ("`metapath'" == "") {
            * Find the helper program location (src/_/)
            capture findfile _unicef_indicator_info.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                * Extract directory containing this ado file
                local ado_dir = subinstr("`ado_path'", "\", "/", .)
                local ado_dir = subinstr("`ado_dir'", "_unicef_indicator_info.ado", "", .)
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
        * Read YAML file and get indicator info (frames for Stata 16+)
        *-----------------------------------------------------------------------
        
        local indicator_upper = upper("`indicator'")
        local found = 0
        local ind_name ""
        local ind_category ""
        local ind_sdg ""
        local ind_unit ""
        local ind_desc ""
        local ind_source ""
        local ind_urn ""
        
        if (`use_frames') {
            * Stata 16+ - use frames for better isolation
            * Note: yaml.ado prefixes frame names with "yaml_"
            local yaml_frame_base "_unicef_yaml_temp"
            local yaml_frame "yaml_`yaml_frame_base'"
            capture frame drop `yaml_frame'
            
            * Read YAML into a frame (yaml.ado will prefix with "yaml_")
            yaml read using "`yaml_file'", frame(`yaml_frame_base')
            
            * Use the actual frame name (with yaml_ prefix)
            frame `yaml_frame' {
                * Try to get indicator metadata
                capture yaml get indicators:`indicator_upper' frame(`yaml_frame_base')
                local found = (_rc == 0 & "`r(found)'" == "1")
                
                if (`found') {
                    local ind_name "`r(name)'"
                    local ind_category "`r(category)'"
                    local ind_desc "`r(description)'"
                    local ind_urn "`r(urn)'"
                }
            }
            
            * Clean up frame (use the actual prefixed name)
            capture frame drop `yaml_frame'
        }
        else {
            * Stata 14/15 - use preserve/restore
            preserve
            
            yaml read using "`yaml_file'", replace
            
            * Try to get indicator metadata
            capture yaml get indicators:`indicator_upper'
            local found = (_rc == 0 & "`r(found)'" == "1")
            
            if (`found') {
                local ind_name "`r(name)'"
                local ind_category "`r(category)'"
                local ind_desc "`r(description)'"
                local ind_urn "`r(urn)'"
            }
            
            restore
        }
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Indicator Information: " as result "`indicator_upper'"
    noi di as text "{hline 70}"
    noi di ""
    
    if (!`found') {
        noi di as err "  Indicator '`indicator_upper'' not found in metadata."
        noi di as text "  Use 'unicefdata, search(keyword)' to search for indicators."
        noi di ""
        exit 111
    }
    
    noi di as text _col(2) "Code:        " as result "`indicator_upper'"
    noi di as text _col(2) "Name:        " as result "`ind_name'"
    noi di as text _col(2) "Category:    " as result "`ind_category'"
    
    if ("`ind_desc'" != "" & "`ind_desc'" != ".") {
        noi di ""
        noi di as text _col(2) "Description:"
        noi di as result _col(4) "`ind_desc'"
    }
    
    if ("`ind_urn'" != "" & "`ind_urn'" != ".") {
        noi di ""
        noi di as text _col(2) "URN:         " as result "`ind_urn'"
    }
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Usage: " as result "unicefdata, indicator(`indicator_upper') geo(AFG BGD) year(2020/2022)"
    noi di as text "{hline 70}"
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return local indicator "`indicator_upper'"
    return local name "`ind_name'"
    return local category "`ind_category'"
    return local description "`ind_desc'"
    return local urn "`ind_urn'"
    
end

*******************************************************************************
* _unicef_indicator_info.ado
*! v 1.5.0   18Dec2025               by Joao Pedro Azevedo (UNICEF)
* Display detailed info about a specific UNICEF indicator using YAML metadata
* Uses yaml.ado for robust YAML parsing
* Uses Stata frames (v16+) for better isolation when available
*
* v1.5.0: Added supported disaggregations display from dataflow schema
* v1.4.0: MAJOR REWRITE - Direct dataset query instead of yaml get calls
*         - Much faster and more robust
*         - Avoids frame context/return value issues
*******************************************************************************

program define _unicef_indicator_info, rclass
    version 14.0
    
    syntax , Indicator(string) [VERBOSE METApath(string) BRIEF]
    
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
        * Read YAML and get indicator info using direct dataset operations
        *-----------------------------------------------------------------------
        
        local indicator_upper = upper("`indicator'")
        local found = 0
        local ind_name ""
        local ind_category ""
        local ind_desc ""
        local ind_urn ""
        
        if (`use_frames') {
            *-------------------------------------------------------------------
            * Stata 16+ - use frames for better isolation
            *-------------------------------------------------------------------
            local yaml_frame_base "_unicef_info_temp"
            local yaml_frame "yaml_`yaml_frame_base'"
            capture frame drop `yaml_frame'
            
            * Read YAML into a frame (yaml.ado stores as key/value dataset)
            yaml read using "`yaml_file'", frame(`yaml_frame_base')
            
            * Work directly with the dataset in the frame
            frame `yaml_frame' {
                * yaml.ado creates keys like: indicators_CME_MRY0T4_code, indicators_CME_MRY0T4_name
                * Filter to rows for this specific indicator
                keep if regexm(key, "^indicators_`indicator_upper'_(code|name|category|description|urn)$")
                
                local found = (_N > 0)
                
                if (`found') {
                    * Extract each attribute value
                    forvalues i = 1/`=_N' {
                        local k = key[`i']
                        local v = value[`i']
                        
                        if (regexm("`k'", "_name$")) {
                            local ind_name "`v'"
                        }
                        else if (regexm("`k'", "_category$")) {
                            local ind_category "`v'"
                        }
                        else if (regexm("`k'", "_description$")) {
                            local ind_desc "`v'"
                        }
                        else if (regexm("`k'", "_urn$")) {
                            local ind_urn "`v'"
                        }
                    }
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
            
            * Filter to rows for this specific indicator
            keep if regexm(key, "^indicators_`indicator_upper'_(code|name|category|description|urn)$")
            
            local found = (_N > 0)
            
            if (`found') {
                * Extract each attribute value
                forvalues i = 1/`=_N' {
                    local k = key[`i']
                    local v = value[`i']
                    
                    if (regexm("`k'", "_name$")) {
                        local ind_name "`v'"
                    }
                    else if (regexm("`k'", "_category$")) {
                        local ind_category "`v'"
                    }
                    else if (regexm("`k'", "_description$")) {
                        local ind_desc "`v'"
                    }
                    else if (regexm("`k'", "_urn$")) {
                        local ind_urn "`v'"
                    }
                }
            }
            
            restore
        }
        
        *-----------------------------------------------------------------------
        * Get supported disaggregations from dataflow schema
        *-----------------------------------------------------------------------
        
        local supported_dims ""
        local has_sex = 0
        local has_age = 0
        local has_wealth = 0
        local has_residence = 0
        local has_maternal_edu = 0
        
        if ("`ind_category'" != "" & "`ind_category'" != ".") {
            * Try to find dataflow schema file
            local schema_file "`metapath'../metadata/current/dataflows/`ind_category'.yaml"
            capture confirm file "`schema_file'"
            if (_rc != 0) {
                * Try alternative path
                local schema_file "`metapath'../../metadata/current/dataflows/`ind_category'.yaml"
                capture confirm file "`schema_file'"
            }
            
            if (_rc == 0) {
                * Read schema to get dimensions
                if (`use_frames') {
                    local schema_frame "yaml_schema_temp"
                    capture frame drop `schema_frame'
                    capture yaml read using "`schema_file'", frame(schema_temp)
                    
                    if (_rc == 0) {
                        frame yaml_schema_temp {
                            * Look for dimension entries
                            gen is_dim = regexm(key, "^dimensions_[0-9]+_id$")
                            levelsof value if is_dim == 1, local(dims) clean
                            
                            foreach d of local dims {
                                if ("`d'" == "SEX") {
                                    local has_sex = 1
                                    local supported_dims "`supported_dims' sex"
                                }
                                else if ("`d'" == "AGE") {
                                    local has_age = 1
                                    local supported_dims "`supported_dims' age"
                                }
                                else if ("`d'" == "WEALTH_QUINTILE") {
                                    local has_wealth = 1
                                    local supported_dims "`supported_dims' wealth"
                                }
                                else if ("`d'" == "RESIDENCE") {
                                    local has_residence = 1
                                    local supported_dims "`supported_dims' residence"
                                }
                                else if ("`d'" == "MATERNAL_EDU_LVL") {
                                    local has_maternal_edu = 1
                                    local supported_dims "`supported_dims' maternal_edu"
                                }
                            }
                        }
                        capture frame drop yaml_schema_temp
                    }
                }
                else {
                    * Stata 14/15: use preserve/restore
                    preserve
                    capture yaml read using "`schema_file'", replace
                    if (_rc == 0) {
                        gen is_dim = regexm(key, "^dimensions_[0-9]+_id$")
                        levelsof value if is_dim == 1, local(dims) clean
                        
                        foreach d of local dims {
                            if ("`d'" == "SEX") {
                                local has_sex = 1
                                local supported_dims "`supported_dims' sex"
                            }
                            else if ("`d'" == "AGE") {
                                local has_age = 1
                                local supported_dims "`supported_dims' age"
                            }
                            else if ("`d'" == "WEALTH_QUINTILE") {
                                local has_wealth = 1
                                local supported_dims "`supported_dims' wealth"
                            }
                            else if ("`d'" == "RESIDENCE") {
                                local has_residence = 1
                                local supported_dims "`supported_dims' residence"
                            }
                            else if ("`d'" == "MATERNAL_EDU_LVL") {
                                local has_maternal_edu = 1
                                local supported_dims "`supported_dims' maternal_edu"
                            }
                        }
                    }
                    restore
                }
            }
        }
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    if ("`brief'" == "") {
        noi di ""
        noi di as text "{hline 70}"
        noi di as text "Indicator Information: " as result "`indicator_upper'"
        noi di as text "{hline 70}"
        noi di ""
    }
    
    if (!`found') {
        noi di as err "  Indicator '`indicator_upper'' not found in metadata."
        noi di as text "  Use 'unicefdata, search(keyword)' to search for indicators."
        noi di ""
        exit 111
    }
    
    noi di as text _col(2) "Code:        " as result "`indicator_upper'"
    noi di as text _col(2) "Name:        " as result "`ind_name'"
    noi di as text _col(2) "Category:    " as result "`ind_category'"
    
    if ("`ind_desc'" != "" & "`ind_desc'" != "." & "`brief'" == "") {
        noi di ""
        noi di as text _col(2) "Description:"
        noi di as result _col(4) "`ind_desc'"
    }
    
    if ("`ind_urn'" != "" & "`ind_urn'" != "." & "`brief'" == "") {
        noi di ""
        noi di as text _col(2) "URN:         " as result "`ind_urn'"
    }
    
    * Display supported disaggregations
    noi di ""
    noi di as text _col(2) "Supported Disaggregations:"
    if ("`supported_dims'" != "") {
        noi di as text _col(4) "sex:          " as result cond(`has_sex', "Yes (SEX)", "No")
        noi di as text _col(4) "age:          " as result cond(`has_age', "Yes (AGE)", "No")
        noi di as text _col(4) "wealth:       " as result cond(`has_wealth', "Yes (WEALTH_QUINTILE)", "No")
        noi di as text _col(4) "residence:    " as result cond(`has_residence', "Yes (RESIDENCE)", "No")
        noi di as text _col(4) "maternal_edu: " as result cond(`has_maternal_edu', "Yes (MATERNAL_EDU_LVL)", "No")
    }
    else {
        noi di as text _col(4) "(Could not determine - run 'unicefdata, sync' to update metadata)"
    }
    
    if ("`brief'" == "") {
        noi di ""
        noi di as text "{hline 70}"
        noi di as text "Usage: " as result "unicefdata, indicator(`indicator_upper') countries(AFG BGD) year(2020:2022)"
        noi di as text "{hline 70}"
    }
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return local indicator "`indicator_upper'"
    return local name "`ind_name'"
    return local category "`ind_category'"
    return local description "`ind_desc'"
    return local urn "`ind_urn'"
    return local has_sex "`has_sex'"
    return local has_age "`has_age'"
    return local has_wealth "`has_wealth'"
    return local has_residence "`has_residence'"
    return local has_maternal_edu "`has_maternal_edu'"
    return local supported_dims "`supported_dims'"
    
end

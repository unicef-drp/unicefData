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
        local ind_dataflow ""
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
                * Filter to rows for this specific indicator (include dataflow field)
                keep if regexm(key, "^indicators_`indicator_upper'_(code|name|category|dataflow|description|urn)$")
                
                local found = (_N > 0)
                
                if ("`verbose'" != "") {
                    noi di as text "Found " as result `found' as text " metadata fields for " as result "`indicator_upper'"
                }
                
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
                        else if (regexm("`k'", "_dataflow$")) {
                            * Prefer dataflow over category if available
                            if ("`ind_category'" == "" | "`ind_category'" == ".") {
                                local ind_category "`v'"
                            }
                            local ind_dataflow "`v'"
                        }
                        else if (regexm("`k'", "_description$")) {
                            local ind_desc "`v'"
                        }
                        else if (regexm("`k'", "_urn$")) {
                            local ind_urn "`v'"
                        }
                    }
                    
                    if ("`verbose'" != "") {
                        noi di as text "  Category: " as result "`ind_category'"
                        noi di as text "  Dataflow: " as result "`ind_dataflow'"
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
            
            * Filter to rows for this specific indicator (include dataflow field)
            keep if regexm(key, "^indicators_`indicator_upper'_(code|name|category|dataflow|description|urn)$")
            
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
                    else if (regexm("`k'", "_dataflow$")) {
                        * Prefer dataflow over category if available
                        if ("`ind_category'" == "" | "`ind_category'" == ".") {
                            local ind_category "`v'"
                        }
                        local ind_dataflow "`v'"
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
        
        * Debug: show what we got from indicator metadata
        if ("`verbose'" != "") {
            noi di ""
            noi di as text "Debug: ind_category = [" as result "`ind_category'" as text "]"
            noi di as text "Debug: ind_dataflow = [" as result "`ind_dataflow'" as text "]"
            noi di as text "Debug: metapath = [" as result "`metapath'" as text "]"
        }
        
        local supported_dims ""
        local has_sex = 0
        local has_age = 0
        local has_wealth = 0
        local has_residence = 0
        local has_maternal_edu = 0
        
        * Determine which dataflow to use for schema lookup
        * Priority: ind_dataflow (explicit) > ind_category (derived from indicator code)
        local dataflow_name ""
        if ("`ind_dataflow'" != "" & "`ind_dataflow'" != ".") {
            local dataflow_name "`ind_dataflow'"
        }
        else if ("`ind_category'" != "" & "`ind_category'" != ".") {
            local dataflow_name "`ind_category'"
        }
        
        if ("`dataflow_name'" != "") {
            * Try to find dataflow schema file (sysdir: _dataflows/{DATAFLOW}.yaml)
            * The schema defines dimensions available for ALL indicators in this dataflow
            local schema_file "`metapath'_dataflows/`dataflow_name'.yaml"
            if ("`verbose'" != "") {
                noi di as text "Looking for dataflow schema: " as result "`dataflow_name'.yaml"
                noi di as text "  Path: " as result "`schema_file'"
            }
            capture confirm file "`schema_file'"
            if (_rc != 0) {
                if ("`verbose'" != "") {
                    noi di as text "  Not found, trying repo path..."
                }
                * Try repo path (development)
                local schema_file "`metapath'../metadata/current/dataflows/`dataflow_name'.yaml"
                capture confirm file "`schema_file'"
            }
            if (_rc != 0) {
                if ("`verbose'" != "") {
                    noi di as text "  Not found, trying alternative repo path..."
                }
                * Try alternative repo path
                local schema_file "`metapath'../../metadata/current/dataflows/`dataflow_name'.yaml"
                capture confirm file "`schema_file'"
            }
            if (_rc != 0) {
                if ("`verbose'" != "") {
                    noi di as text "  Schema file not found for dataflow: " as result "`dataflow_name'"
                }
            }
            
            if (_rc == 0) {
                * Read schema to get dimensions
                if ("`verbose'" != "") {
                    noi di as text "  Found schema at: " as result "`schema_file'"
                }
                
                * Direct file reading approach - more reliable than yaml.ado for nested lists
                * The YAML files have a simple format: "- id: DIMENSION_NAME" lines under dimensions:
                tempname fh
                local dims ""
                local in_dimensions = 0
                
                file open `fh' using "`schema_file'", read text
                file read `fh' line
                while r(eof) == 0 {
                    local trimmed_line = strtrim(`"`line'"')
                    
                    * Check if we're entering dimensions section
                    if ("`trimmed_line'" == "dimensions:") {
                        local in_dimensions = 1
                        if ("`verbose'" != "") {
                            noi di as text "    Entering dimensions section"
                        }
                    }
                    * Check if we're leaving dimensions section (new top-level key without leading dash/space)
                    else if (`in_dimensions' == 1) {
                        * Top-level keys start at column 1 and end with colon
                        local first_char = substr(`"`line'"', 1, 1)
                        if ("`first_char'" != " " & "`first_char'" != "-" & "`first_char'" != "" & regexm(`"`line'"', "^[a-z_]+:")) {
                            local in_dimensions = 0
                            if ("`verbose'" != "") {
                                noi di as text "    Leaving dimensions section at: `trimmed_line'"
                            }
                        }
                        * Extract dimension id: lines like "- id: REF_AREA"
                        else if (regexm("`trimmed_line'", "^- id: *([A-Z_0-9]+)")) {
                            local dim_id = regexs(1)
                            local dims "`dims' `dim_id'"
                            if ("`verbose'" != "") {
                                noi di as text "    Found dimension: " as result "`dim_id'"
                            }
                        }
                    }
                    file read `fh' line
                }
                file close `fh'
                local dims = strtrim("`dims'")
                
                if ("`verbose'" != "") {
                    noi di as text "  All dimensions: " as result "`dims'"
                }
                
                * Map dimensions to supported disaggregations
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
                    else if ("`d'" == "MATERNAL_EDU_LVL" | "`d'" == "MOTHER_EDUCATION") {
                        local has_maternal_edu = 1
                        local supported_dims "`supported_dims' maternal_edu"
                    }
                }
            }
        }
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results (unless brief option specified)
    *---------------------------------------------------------------------------
    
    if ("`brief'" == "") {
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
        if ("`ind_dataflow'" != "" & "`ind_dataflow'" != "`ind_category'") {
            noi di as text _col(2) "Dataflow:    " as result "`ind_dataflow'"
        }
        
        if ("`ind_desc'" != "" & "`ind_desc'" != ".") {
            noi di ""
            noi di as text _col(2) "Description:"
            noi di as result _col(4) "`ind_desc'"
        }
        
        if ("`ind_urn'" != "" & "`ind_urn'" != ".") {
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
        
        noi di ""
        noi di as text "{hline 70}"
        noi di as text "Usage: " as result "unicefdata, indicator(`indicator_upper') countries(AFG BGD) year(2020:2022)"
        noi di as text "{hline 70}"
    }
    else {
        * Brief mode - just check if found (for error handling in caller)
        if (!`found') {
            exit 111
        }
    }
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return local indicator "`indicator_upper'"
    return local name "`ind_name'"
    return local category "`ind_category'"
    return local dataflow "`ind_dataflow'"
    return local description "`ind_desc'"
    return local urn "`ind_urn'"
    return local has_sex "`has_sex'"
    return local has_age "`has_age'"
    return local has_wealth "`has_wealth'"
    return local has_residence "`has_residence'"
    return local has_maternal_edu "`has_maternal_edu'"
    return local supported_dims "`supported_dims'"
    
end

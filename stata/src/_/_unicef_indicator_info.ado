*******************************************************************************
* _unicef_indicator_info.ado
*! v 1.7.0   17Jan2026               by Joao Pedro Azevedo (UNICEF)
* Display detailed info about a specific UNICEF indicator using YAML metadata
*
* v1.6.0: MAJOR PERF FIX - Direct file reading with early termination
*         - Searches for specific indicator, stops when found
*         - No longer loads entire 5000+ key YAML into memory
*         - ~100x faster for single indicator lookups
* v1.5.0: Added supported disaggregations display from dataflow schema
* v1.4.0: MAJOR REWRITE - Direct dataset query instead of yaml get calls
*******************************************************************************

program define _unicef_indicator_info, rclass
    version 14.0
    
    syntax , Indicator(string) [VERBOSE METApath(string) BRIEF]
    
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
            noi di as text "Run {stata unicefdata_sync} to download metadata."
            exit 601
        }
        
        if ("`verbose'" != "") {
            noi di as text "Reading indicators from: " as result "`yaml_file'"
        }
        
        *-----------------------------------------------------------------------
        * FAST: Direct file search for specific indicator (no full YAML parse)
        * Searches for "  INDICATOR_CODE:" section, extracts fields, stops early
        *-----------------------------------------------------------------------
        
        * STATA MACRO ASSIGNMENT BEST PRACTICE
        * - Use: local varname value              (direct assignment)
        * - NOT:  local varname = value           (expression evaluation - slower!)
        * - Use = ONLY for expressions: local x = `y' + 1
        * WHY? The = operator causes Stata to parse RHS as math/functions,
        * leading to unexpected string behavior and slower execution.
        * Keep simple assignments as direct syntax for clarity and speed.
        
        local indicator_upper = upper("`indicator'")
        local found 0
        local ind_name ""
        local ind_category ""
        local ind_parent ""
        local ind_dataflow ""
        local ind_desc ""
        local ind_urn ""
        
        * =====================================================================
        * CALL YAML PARSER: Extract indicator metadata from YAML file
        * =====================================================================
        * The __unicef_parse_indicator_yaml program encapsulates all the
        * complex parsing logic: file handling, state machine, field extraction,
        * and disaggregation collection. It returns 8 locals via r() macros.
        
        __unicef_parse_indicator_yaml, yamlfile("`yaml_file'") ///
            indicator("`indicator_upper'") `verbose'
        
        * Capture returned values
        local ind_name `r(ind_name)'
        local ind_category `r(ind_category)'
        local ind_parent `r(ind_parent)'
        local ind_dataflow `r(ind_dataflow)'
        local ind_desc `r(ind_desc)'
        local ind_urn `r(ind_urn)'
        local disagg_raw `r(disagg_raw)'
        local disagg_totals `r(disagg_totals)'
        local found `r(found)'
        
        *-----------------------------------------------------------------------
        * Process disaggregations from the combined read above
        *-----------------------------------------------------------------------
        
        local supported_dims ""
        local has_sex 0
        local has_age 0
        local has_wealth 0
        local has_residence 0
        local has_maternal_edu 0
        
        if ("`verbose'" != "") {
            noi di as text "Extracting disaggregations from enriched metadata"
            noi di as text "  Raw disaggregations: `disagg_raw'"
            noi di as text "  With totals: `disagg_totals'"
        }
        
        * Parse the disaggregations and map to display names
        if ("`disagg_raw'" != "") {
            * Clean up array format if needed: [DIM1,DIM2] -> DIM1, DIM2 -> DIM1 DIM2
            local disagg_raw = subinstr("`disagg_raw'", "[", "", .)
            local disagg_raw = subinstr("`disagg_raw'", "]", "", .)
            local disagg_raw = subinstr("`disagg_raw'", ",", " ", .)
            local disagg_raw = strtrim("`disagg_raw'")
            
            * Do the same for disagg_with_totals
            local disagg_totals = subinstr("`disagg_totals'", "[", "", .)
            local disagg_totals = subinstr("`disagg_totals'", "]", "", .)
            local disagg_totals = subinstr("`disagg_totals'", ",", " ", .)
            local disagg_totals = strtrim("`disagg_totals'")
            
            foreach d of local disagg_raw {
                if ("`d'" == "SEX") {
                    local has_sex 1
                }
                else if ("`d'" == "AGE") {
                    local has_age 1
                }
                else if ("`d'" == "WEALTH_QUINTILE") {
                    local has_wealth 1
                }
                else if ("`d'" == "RESIDENCE") {
                    local has_residence 1
                }
                else if ("`d'" == "MATERNAL_EDU_LVL" | "`d'" == "MOTHER_EDUCATION") {
                    local has_maternal_edu 1
                }
            }
            local supported_dims = "`disagg_raw'"
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
            noi di as text "  Use {stata unicefdata, search(`indicator_upper')} to search for similar indicators."
            noi di as text "  Or try {stata unicefdata, categories} to browse available dataflows."
            noi di ""
            exit 111
        }
        
        noi di as text _col(2) "Code:        " as result "`indicator_upper'"
        noi di as text _col(2) "Name:        " as result "`ind_name'"
        
        * Show category (may be empty for some indicators, fallback to parent)
        if ("`ind_category'" != "") {
            noi di as text _col(2) "Category:    " as result "`ind_category'"
        }
        else if ("`ind_parent'" != "") {
            noi di as text _col(2) "Category:    " as result "`ind_parent'"
        }
        else {
            noi di as text _col(2) "Category:    " as result "(not classified)"
        }
        
        * Show dataflow(s)
        if ("`ind_dataflow'" != "") {
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
        
        * Display supported disaggregations with allowed values
        noi di ""
        noi di as text _col(2) "Supported Disaggregations:"
        
        if ("`disagg_raw'" != "") {
            * Parse each dimension and check if it has totals
            foreach d of local disagg_raw {
                * Skip REF_AREA (country codes - too many to display)
                if ("`d'" == "REF_AREA") {
                    if (regexm("`disagg_totals'", "`d'")) {
                        noi di as text _col(4) "`d' (country/region)  " as result "(with totals)"
                    }
                    else {
                        noi di as text _col(4) "`d' (country/region)"
                    }
                }
                else {
                    * Map dimension codes to their allowed values
                    local dim_values ""
                    if ("`d'" == "SEX") {
                        local dim_values "Male, Female"
                    }
                    else if ("`d'" == "RESIDENCE") {
                        local dim_values "Urban, Rural"
                    }
                    else if ("`d'" == "WEALTH_QUINTILE") {
                        local dim_values "Quintile 1, Quintile 2, Quintile 3, Quintile 4, Quintile 5"
                    }
                    else if ("`d'" == "AGE") {
                        local dim_values "Age groups (0-4, 5-9, 10-17, 18+, etc.)"
                    }
                    else if ("`d'" == "MATERNAL_EDU_LVL") {
                        local dim_values "No education, Primary, Secondary, Higher"
                    }
                    else if ("`d'" == "EDUCATION_LEVEL") {
                        local dim_values "ISCED levels 0-8"
                    }
                    else if ("`d'" == "DISABILITY_STATUS") {
                        local dim_values "With disability, Without disability"
                    }
                    else if ("`d'" == "ETHNIC_GROUP") {
                        local dim_values "Country-specific ethnic classifications"
                    }
                    else {
                        local dim_values "(values vary by dataflow)"
                    }
                    
                    if (regexm("`disagg_totals'", "`d'")) {
                        noi di as text _col(4) "`d'  " as result "(with totals)"
                        noi di as text _col(6) as text "Options: `dim_values'"
                    }
                    else {
                        noi di as text _col(4) "`d'"
                        noi di as text _col(6) as text "Options: `dim_values'"
                    }
                }
            }
        }
        else {
            noi di as text _col(4) "(Not available for this indicator)"
        }
        noi di ""
        noi di as text "{hline 70}"
        noi di as text "Usage: {stata unicefdata, indicator(`indicator_upper') countries(AFG BGD) clear}"
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
    
    * Extract primary (first) dataflow for API calls
    * Dataflow is comma-separated: "EDUCATION, GLOBAL_DATAFLOW"
    * Extract just the first one before the comma
    local comma_pos = strpos("`ind_dataflow'", ",")
    if (`comma_pos' > 0) {
        local primary_dataflow = strtrim(substr("`ind_dataflow'", 1, `comma_pos' - 1))
    }
    else {
        local primary_dataflow = "`ind_dataflow'"
    }
    
    return local indicator "`indicator_upper'"
    return local name "`ind_name'"
    return local category "`ind_category'"
    return local dataflow "`ind_dataflow'"
    return local primary_dataflow "`primary_dataflow'"
    return local description "`ind_desc'"
    return local urn "`ind_urn'"
    return local has_sex "`has_sex'"
    return local has_age "`has_age'"
    return local has_wealth "`has_wealth'"
    return local has_residence "`has_residence'"
    return local has_maternal_edu "`has_maternal_edu'"
    return local supported_dims "`supported_dims'"
    
end
*! v 1.7.0   17Jan2026               by Joao Pedro Azevedo (UNICEF)
* v1.7.0: ENHANCED - Uses enriched indicators metadata with disaggregations
*         - Disaggregations now read directly from indicator metadata
*         - Shows which disaggregations support totals (_T suffix)
*         - No longer depends on dataflow schema files
*         - More reliable and faster disaggregation lookup
* v1.6.0: MAJOR PERF FIX - Direct file reading with early termination
*         - Searches for specific indicator, stops when found
*         - No longer loads entire 5000+ key YAML into memory
*         - ~100x faster for single indicator lookups
* v1.5.0: Added supported disaggregations display from dataflow schema
* v1.4.0: MAJOR REWRITE - Direct dataset query instead of yaml get calls
*******************************************************************************

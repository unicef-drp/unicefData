*******************************************************************************
* _unicef_indicator_info.ado
*! v 1.0.0   09Dec2025               by Joao Pedro Azevedo (UNICEF)
* Display detailed information about a specific UNICEF indicator
*******************************************************************************

program define _unicef_indicator_info, rclass
    version 14.0
    
    syntax , INDICATOR(string) [VERBOSE METApath(string)]
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata directory
        *-----------------------------------------------------------------------
        
        if ("`metapath'" == "") {
            findfile unicefdata.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                local ado_dir = subinstr("`ado_path'", "src/u/unicefdata.ado", "", .)
                local ado_dir = subinstr("`ado_dir'", "src\u\unicefdata.ado", "", .)
                local metapath "`ado_dir'metadata/vintages/"
            }
            
            if ("`metapath'" == "") | (!fileexists("`metapath'indicators.yaml")) {
                local metapath "`c(sysdir_plus)'u/metadata/vintages/"
            }
        }
        
        local yaml_file "`metapath'indicators.yaml"
        
        *-----------------------------------------------------------------------
        * Check YAML file exists
        *-----------------------------------------------------------------------
        
        capture confirm file "`yaml_file'"
        if (_rc != 0) {
            noi di as err "Indicators metadata not found at: `yaml_file'"
            noi di as err "Run 'unicefdata_sync' to download metadata."
            exit 601
        }
        
        * Uppercase the indicator for matching
        local indicator = upper("`indicator'")
        
        *-----------------------------------------------------------------------
        * Read YAML file and find indicator
        *-----------------------------------------------------------------------
        
        preserve
        
        yaml read using "`yaml_file'", replace
        
        * Check if indicator exists
        count if parent == "indicators_`indicator'"
        if (r(N) == 0) {
            restore
            noi di as err "Indicator '`indicator'' not found in metadata"
            noi di as text "Use 'unicefdata, search(<keyword>)' to find indicators."
            exit 198
        }
        
        * Extract metadata for this indicator
        keep if parent == "indicators_`indicator'"
        
        * Initialize locals for each field
        local ind_name ""
        local ind_dataflow ""
        local ind_sdg ""
        local ind_unit ""
        local ind_desc ""
        
        * Extract values
        count if strpos(key, "_name") > 0
        if (r(N) > 0) {
            levelsof value if strpos(key, "_name") > 0, local(ind_name) clean
        }
        
        count if strpos(key, "_dataflow") > 0
        if (r(N) > 0) {
            levelsof value if strpos(key, "_dataflow") > 0, local(ind_dataflow) clean
        }
        
        count if strpos(key, "_sdg_target") > 0
        if (r(N) > 0) {
            levelsof value if strpos(key, "_sdg_target") > 0, local(ind_sdg) clean
        }
        
        count if strpos(key, "_unit") > 0
        if (r(N) > 0) {
            levelsof value if strpos(key, "_unit") > 0, local(ind_unit) clean
        }
        
        count if strpos(key, "_description") > 0
        if (r(N) > 0) {
            levelsof value if strpos(key, "_description") > 0, local(ind_desc) clean
        }
        
        restore
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Indicator Information: " as result "`indicator'"
    noi di as text "{hline 70}"
    noi di ""
    
    noi di as text _col(2) "Code:         " as result "`indicator'"
    
    if ("`ind_name'" != "") {
        noi di as text _col(2) "Name:         " as result "`ind_name'"
    }
    
    if ("`ind_dataflow'" != "") {
        noi di as text _col(2) "Dataflow:     " as result "`ind_dataflow'"
    }
    
    if ("`ind_sdg'" != "") {
        noi di as text _col(2) "SDG Target:   " as result "`ind_sdg'"
    }
    
    if ("`ind_unit'" != "") {
        noi di as text _col(2) "Unit:         " as result "`ind_unit'"
    }
    
    if ("`ind_desc'" != "") {
        noi di ""
        noi di as text _col(2) "Description:"
        noi di as result _col(4) "`ind_desc'"
    }
    
    noi di ""
    noi di as text "{hline 70}"
    noi di ""
    noi di as text "Usage: " as result `"unicefdata, indicator(`indicator') countries(<iso3>)"'
    noi di as text "   or: " as result `"unicefdata, indicator(`indicator') countries(BRA USA CHN) start_year(2010)"'
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return local indicator "`indicator'"
    return local name "`ind_name'"
    return local dataflow "`ind_dataflow'"
    return local sdg_target "`ind_sdg'"
    return local unit "`ind_unit'"
    return local description "`ind_desc'"
    return local yaml_file "`yaml_file'"
    
end

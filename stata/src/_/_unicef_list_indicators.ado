*******************************************************************************
* _unicef_list_indicators.ado
*! v 1.0.0   09Dec2025               by Joao Pedro Azevedo (UNICEF)
* List indicators in a specific UNICEF SDMX dataflow
*******************************************************************************

program define _unicef_list_indicators, rclass
    version 14.0
    
    syntax , DATAFLOW(string) [LIMIT(integer 50) VERBOSE METApath(string)]
    
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
        
        * Uppercase the dataflow for matching
        local dataflow = upper("`dataflow'")
        
        if ("`verbose'" != "") {
            noi di as text "Listing indicators for dataflow: " as result "`dataflow'"
        }
        
        *-----------------------------------------------------------------------
        * Read YAML file and filter by dataflow
        *-----------------------------------------------------------------------
        
        preserve
        
        yaml read using "`yaml_file'", replace
        
        * Get dataflow entries
        keep if substr(parent, 1, 11) == "indicators_" | parent == "indicators"
        keep if strpos(key, "_dataflow") > 0
        gen indicator = subinstr(parent, "indicators_", "", 1)
        rename value df_value
        
        * Filter to matching dataflow
        keep if upper(df_value) == "`dataflow'"
        
        tempfile df_data
        save `df_data'
        local n_indicators = _N
        
        if (`n_indicators' == 0) {
            restore
            noi di as err "No indicators found for dataflow '`dataflow''"
            noi di as text "Use 'unicefdata, flows' to see available dataflows."
            exit 198
        }
        
        * Get names for these indicators
        yaml read using "`yaml_file'", replace
        keep if substr(parent, 1, 11) == "indicators_" | parent == "indicators"
        keep if strpos(key, "_name") > 0
        gen indicator = subinstr(parent, "indicators_", "", 1)
        rename value name
        keep indicator name
        
        * Merge with dataflow filter
        merge 1:1 indicator using `df_data', keep(3) nogen
        
        * Sort
        sort indicator
        
        * Limit
        local n_total = _N
        if (_N > `limit') {
            keep in 1/`limit'
        }
        local n_shown = _N
        
        restore
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Indicators in dataflow: " as result "`dataflow'"
    noi di as text "{hline 70}"
    noi di ""
    
    * Re-do for display
    preserve
    quietly {
        yaml read using "`yaml_file'", replace
        keep if substr(parent, 1, 11) == "indicators_" | parent == "indicators"
        keep if strpos(key, "_dataflow") > 0
        gen indicator = subinstr(parent, "indicators_", "", 1)
        rename value df_value
        keep if upper(df_value) == "`dataflow'"
        
        tempfile df_data
        save `df_data'
        
        yaml read using "`yaml_file'", replace
        keep if substr(parent, 1, 11) == "indicators_" | parent == "indicators"
        keep if strpos(key, "_name") > 0
        gen indicator = subinstr(parent, "indicators_", "", 1)
        rename value name
        keep indicator name
        
        merge 1:1 indicator using `df_data', keep(3) nogen
        sort indicator
        
        if (_N > `limit') {
            keep in 1/`limit'
        }
    }
    
    noi di as text _col(2) "{ul:Indicator Code}" _col(30) "{ul:Name}"
    noi di ""
    
    local n_shown = _N
    forvalues i = 1/`n_shown' {
        local ind = indicator[`i']
        local nm = name[`i']
        
        * Truncate name if too long
        if (length("`nm'") > 40) {
            local nm = substr("`nm'", 1, 37) + "..."
        }
        
        noi di as result _col(2) "`ind'" as text _col(30) "`nm'"
    }
    
    restore
    
    noi di ""
    noi di as text "{hline 70}"
    if (`n_total' > `limit') {
        noi di as text "Showing " as result `n_shown' as text " of " as result `n_total' as text " indicators. Use " as result "limit(N)" as text " to see more."
    }
    else {
        noi di as text "Total: " as result `n_total' as text " indicator(s) in " as result "`dataflow'"
    }
    noi di as text "{hline 70}"
    noi di ""
    noi di as text "Usage: " as result "unicefdata, indicator(<code>) countries(<iso3>)"
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar n_indicators = `n_total'
    return scalar n_shown = `n_shown'
    return local dataflow "`dataflow'"
    return local yaml_file "`yaml_file'"
    
end

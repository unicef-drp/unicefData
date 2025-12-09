*******************************************************************************
* _unicef_search_indicators.ado
*! v 1.0.0   09Dec2025               by Joao Pedro Azevedo (UNICEF)
* Search UNICEF indicators by keyword
*******************************************************************************

program define _unicef_search_indicators, rclass
    version 14.0
    
    syntax , KEYword(string) [LIMIT(integer 20) VERBOSE METApath(string)]
    
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
        
        if ("`verbose'" != "") {
            noi di as text "Searching indicators in: " as result "`yaml_file'"
        }
        
        *-----------------------------------------------------------------------
        * Read YAML file using yaml.ado
        *-----------------------------------------------------------------------
        
        preserve
        
        yaml read using "`yaml_file'", replace
        
        * Keep only indicator entries (parent starts with "indicators_")
        keep if substr(parent, 1, 11) == "indicators_" | parent == "indicators"
        
        * Extract indicator code from parent
        gen indicator = subinstr(parent, "indicators_", "", 1)
        
        * Get the name entries
        keep if strpos(key, "_name") > 0
        rename value name
        
        * Also need dataflow - merge back
        tempfile names_data
        save `names_data'
        
        * Re-read for dataflow
        yaml read using "`yaml_file'", replace
        keep if substr(parent, 1, 11) == "indicators_" | parent == "indicators"
        keep if strpos(key, "_dataflow") > 0
        gen indicator = subinstr(parent, "indicators_", "", 1)
        rename value dataflow
        keep indicator dataflow
        
        * Merge
        merge 1:1 indicator using `names_data', keep(3) nogen
        
        * Keep essential columns
        keep indicator name dataflow
        
        *-----------------------------------------------------------------------
        * Search by keyword (case-insensitive)
        *-----------------------------------------------------------------------
        
        local keyword_lower = lower("`keyword'")
        
        * Search in both indicator code and name
        gen _match = (strpos(lower(indicator), "`keyword_lower'") > 0) | ///
                     (strpos(lower(name), "`keyword_lower'") > 0)
        
        keep if _match == 1
        drop _match
        
        * Sort by indicator
        sort indicator
        
        * Limit results
        local n_found = _N
        if (`n_found' > `limit') {
            keep in 1/`limit'
        }
        
        local n_shown = _N
        
        restore
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 78}"
    noi di as text `"Indicators matching "`keyword'""'
    noi di as text "{hline 78}"
    noi di ""
    
    if (`n_found' == 0) {
        noi di as text "No indicators found matching '" as result "`keyword'" as text "'"
        noi di ""
        noi di as text "Try a different search term or use 'unicefdata, flows' to see available dataflows."
        return scalar n_found = 0
        exit
    }
    
    * Re-do the search for display
    preserve
    quietly {
        yaml read using "`yaml_file'", replace
        
        keep if substr(parent, 1, 11) == "indicators_" | parent == "indicators"
        gen indicator = subinstr(parent, "indicators_", "", 1)
        keep if strpos(key, "_name") > 0
        rename value name
        
        tempfile names_data
        save `names_data'
        
        yaml read using "`yaml_file'", replace
        keep if substr(parent, 1, 11) == "indicators_" | parent == "indicators"
        keep if strpos(key, "_dataflow") > 0
        gen indicator = subinstr(parent, "indicators_", "", 1)
        rename value dataflow
        keep indicator dataflow
        
        merge 1:1 indicator using `names_data', keep(3) nogen
        keep indicator name dataflow
        
        local keyword_lower = lower("`keyword'")
        gen _match = (strpos(lower(indicator), "`keyword_lower'") > 0) | ///
                     (strpos(lower(name), "`keyword_lower'") > 0)
        keep if _match == 1
        drop _match
        sort indicator
        
        if (_N > `limit') {
            keep in 1/`limit'
        }
    }
    
    noi di as text _col(2) "{ul:Indicator}" _col(28) "{ul:Name}" _col(60) "{ul:Dataflow}"
    noi di ""
    
    local n_shown = _N
    forvalues i = 1/`n_shown' {
        local ind = indicator[`i']
        local nm = name[`i']
        local df = dataflow[`i']
        
        * Truncate name if too long
        if (length("`nm'") > 30) {
            local nm = substr("`nm'", 1, 27) + "..."
        }
        
        noi di as result _col(2) "`ind'" as text _col(28) "`nm'" as result _col(60) "`df'"
    }
    
    restore
    
    noi di ""
    noi di as text "{hline 78}"
    if (`n_found' > `limit') {
        noi di as text "Showing " as result `n_shown' as text " of " as result `n_found' as text " matches. Use " as result "limit(N)" as text " to see more."
    }
    else {
        noi di as text "Found " as result `n_found' as text " matching indicator(s)"
    }
    noi di as text "{hline 78}"
    noi di ""
    noi di as text "Usage: " as result "unicefdata, indicator(<code>) countries(<iso3>)"
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar n_found = `n_found'
    return scalar n_shown = `n_shown'
    return local keyword "`keyword'"
    return local yaml_file "`yaml_file'"
    
end

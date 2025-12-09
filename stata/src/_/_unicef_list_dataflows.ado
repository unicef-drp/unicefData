*******************************************************************************
* _unicef_list_dataflows.ado
*! v 1.0.0   09Dec2025               by Joao Pedro Azevedo (UNICEF)
* List available UNICEF SDMX dataflows from YAML metadata
*******************************************************************************

program define _unicef_list_dataflows, rclass
    version 14.0
    
    syntax [, DETail VERBOSE METApath(string)]
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata directory
        *-----------------------------------------------------------------------
        
        if ("`metapath'" == "") {
            * Find the package installation path
            findfile unicefdata.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                * Extract directory (go up from src/u/ to find metadata/)
                local ado_dir = subinstr("`ado_path'", "src/u/unicefdata.ado", "", .)
                local ado_dir = subinstr("`ado_dir'", "src\u\unicefdata.ado", "", .)
                local metapath "`ado_dir'metadata/vintages/"
            }
            
            * Fallback to PLUS directory
            if ("`metapath'" == "") | (!fileexists("`metapath'dataflows.yaml")) {
                local metapath "`c(sysdir_plus)'u/metadata/vintages/"
            }
        }
        
        local yaml_file "`metapath'dataflows.yaml"
        
        *-----------------------------------------------------------------------
        * Check YAML file exists
        *-----------------------------------------------------------------------
        
        capture confirm file "`yaml_file'"
        if (_rc != 0) {
            noi di as err "Dataflows metadata not found at: `yaml_file'"
            noi di as err "Run 'unicefdata_sync' to download metadata."
            exit 601
        }
        
        if ("`verbose'" != "") {
            noi di as text "Reading dataflows from: " as result "`yaml_file'"
        }
        
        *-----------------------------------------------------------------------
        * Read YAML file using yaml.ado
        *-----------------------------------------------------------------------
        
        preserve
        
        * Use yaml read command (loads into current dataset)
        yaml read using "`yaml_file'", replace
        
        * Filter to dataflow entries only (parent = "dataflows")
        keep if parent == "dataflows"
        
        * Count dataflows
        local n_flows = _N
        
        *-----------------------------------------------------------------------
        * Extract dataflow IDs and names
        *-----------------------------------------------------------------------
        
        * The key format is "dataflows_CME" -> extract ID
        gen dataflow_id = subinstr(key, "dataflows_", "", 1)
        replace dataflow_id = subinstr(dataflow_id, "_name", "", 1)
        replace dataflow_id = subinstr(dataflow_id, "_description", "", 1)
        
        * Keep only rows with "name" type info (not parent markers)
        keep if type != "parent" & strpos(key, "_name") > 0
        
        * Clean up key to get just the ID
        replace dataflow_id = subinstr(key, "dataflows_", "", 1)
        replace dataflow_id = subinstr(dataflow_id, "_name", "", 1)
        
        * Rename value to name
        rename value name
        
        * Keep essential columns
        keep dataflow_id name
        
        * Sort
        sort dataflow_id
        
        * Get count
        local n_flows = _N
        
        restore
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Available UNICEF SDMX Dataflows"
    noi di as text "{hline 70}"
    noi di ""
    
    * Re-read and display
    preserve
    quietly {
        yaml read using "`yaml_file'", replace
        keep if parent == "dataflows" & type != "parent" & strpos(key, "_name") > 0
        
        gen dataflow_id = subinstr(key, "dataflows_", "", 1)
        replace dataflow_id = subinstr(dataflow_id, "_name", "", 1)
        rename value name
        keep dataflow_id name
        sort dataflow_id
        
        local n_flows = _N
    }
    
    if ("`detail'" != "") {
        noi di as text _col(2) "{ul:Dataflow ID}" _col(25) "{ul:Name}"
        noi di ""
        
        forvalues i = 1/`n_flows' {
            local id = dataflow_id[`i']
            local nm = name[`i']
            * Truncate name if too long
            if (length("`nm'") > 45) {
                local nm = substr("`nm'", 1, 42) + "..."
            }
            noi di as result _col(2) "`id'" as text _col(25) "`nm'"
        }
    }
    else {
        * Compact display - 3 columns
        noi di as text _col(2) "Dataflow IDs:"
        noi di ""
        
        local col = 2
        forvalues i = 1/`n_flows' {
            local id = dataflow_id[`i']
            if (`col' > 60) {
                noi di ""
                local col = 2
            }
            noi di as result _col(`col') "`id'" _continue
            local col = `col' + 22
        }
        noi di ""
    }
    
    restore
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Total: " as result `n_flows' as text " dataflows available"
    noi di as text "{hline 70}"
    noi di ""
    noi di as text "Usage: " as result "unicefdata, indicator(<code>) dataflow(<ID>)"
    noi di as text "   or: " as result "unicefdata, indicators(<ID>)" as text " to list indicators in a dataflow"
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar n_dataflows = `n_flows'
    return local yaml_file "`yaml_file'"
    
end

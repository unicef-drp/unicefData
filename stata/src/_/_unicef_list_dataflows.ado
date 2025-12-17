*******************************************************************************
* _unicef_list_dataflows.ado
*! v 1.3.0   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* List available UNICEF SDMX dataflows from YAML metadata
* Uses yaml.ado for robust YAML parsing
* Uses Stata frames (v16+) for better isolation when available
*******************************************************************************

program define _unicef_list_dataflows, rclass
    version 14.0
    
    syntax [, DETail VERBOSE METApath(string)]
    
    * Check if frames are available (Stata 16+)
    local use_frames = (c(stata_version) >= 16)
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata directory (YAML files in src/_/ alongside this ado)
        *-----------------------------------------------------------------------
        
        if ("`metapath'" == "") {
            * Find the helper program location (src/_/)
            capture findfile _unicef_list_dataflows.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                * Extract directory containing this ado file
                local ado_dir = subinstr("`ado_path'", "\", "/", .)
                local ado_dir = subinstr("`ado_dir'", "_unicef_list_dataflows.ado", "", .)
                local metapath "`ado_dir'"
            }
            
            * Fallback to PLUS directory _/
            if ("`metapath'" == "") | (!fileexists("`metapath'_unicefdata_dataflows.yaml")) {
                local metapath "`c(sysdir_plus)'_/"
            }
        }
        
        local yaml_file "`metapath'_unicefdata_dataflows.yaml"
        
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
        * Read YAML file using yaml.ado (frames for Stata 16+)
        *-----------------------------------------------------------------------
        
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
                * Get immediate children under 'dataflows' parent
                yaml list dataflows, keys children frame(`yaml_frame_base')
                local dataflow_ids "`r(keys)'"
                
                * Count dataflows
                local n_flows : word count `dataflow_ids'
                
                * Now build results dataset
                clear
                gen str50 dataflow_id = ""
                gen str100 name = ""
                
                local obs = 0
                foreach id of local dataflow_ids {
                    local ++obs
                    set obs `obs'
                    replace dataflow_id = "`id'" in `obs'
                    
                    * Get name attribute for this dataflow
                    capture yaml get dataflows:`id', attributes(name) quiet frame(`yaml_frame_base')
                    if (_rc == 0 & "`r(name)'" != "") {
                        replace name = "`r(name)'" in `obs'
                    }
                    else {
                        replace name = "`id'" in `obs'
                    }
                }
                
                * Sort
                sort dataflow_id
            }
            
            * Copy results to tempfile for display
            tempfile flowdata
            frame `yaml_frame': save `flowdata'
            
            * Clean up frame
            capture frame drop `yaml_frame'
        }
        else {
            * Stata 14/15 - use preserve/restore
            preserve
            
            * Use yaml read command (loads into current dataset)
            yaml read using "`yaml_file'", replace
            
            * Get immediate children under 'dataflows' parent
            yaml list dataflows, keys children
            local dataflow_ids "`r(keys)'"
            
            * Count dataflows
            local n_flows : word count `dataflow_ids'
            
            * Now build results dataset
            clear
            gen str50 dataflow_id = ""
            gen str100 name = ""
            
            local obs = 0
            foreach id of local dataflow_ids {
                local ++obs
                set obs `obs'
                replace dataflow_id = "`id'" in `obs'
                
                * Get name attribute for this dataflow
                capture yaml get dataflows:`id', attributes(name) quiet
                if (_rc == 0 & "`r(name)'" != "") {
                    replace name = "`r(name)'" in `obs'
                }
                else {
                    replace name = "`id'" in `obs'
                }
            }
            
            * Sort
            sort dataflow_id
            
            * Store data for display
            tempfile flowdata
            save `flowdata'
            
            restore
        }
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 70}"
    noi di as text "Available UNICEF SDMX Dataflows"
    noi di as text "{hline 70}"
    noi di ""
    
    * Re-load for display
    preserve
    quietly use `flowdata', clear
    local n_flows = _N
    
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
    return local dataflow_ids "`dataflow_ids'"
    return local yaml_file "`yaml_file'"
    
end

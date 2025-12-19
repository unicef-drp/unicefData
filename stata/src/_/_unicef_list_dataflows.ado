*******************************************************************************
* _unicef_list_dataflows.ado
*! v 1.4.0   19Dec2025               by Joao Pedro Azevedo (UNICEF)
* List available UNICEF SDMX dataflows from YAML metadata
* Uses yaml.ado for robust YAML parsing
* Uses Stata frames (v16+) for better isolation when available
*
* v1.4.0: MAJOR REWRITE - Direct dataset query instead of yaml get loop
*         - Much faster: single dataset operations vs N individual lookups
*         - More robust: avoids frame context/return value issues
*         - Consistent with _unicef_search_indicators.ado pattern
* v1.3.0: Initial version using yaml list + yaml get loop
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
        * Read YAML and extract dataflows using direct dataset operations
        * This is MUCH faster than calling yaml get for each dataflow
        *-----------------------------------------------------------------------
        
        local dataflow_ids ""
        local n_flows = 0
        
        if (`use_frames') {
            *-------------------------------------------------------------------
            * Stata 16+ - use frames for better isolation
            *-------------------------------------------------------------------
            local yaml_frame_base "_unicef_df_temp"
            local yaml_frame "yaml_`yaml_frame_base'"
            capture frame drop `yaml_frame'
            
            * Read YAML into a frame (yaml.ado stores as key/value dataset)
            yaml read using "`yaml_file'", frame(`yaml_frame_base')
            
            * Work directly with the dataset in the frame
            frame `yaml_frame' {
                * yaml.ado creates keys like: dataflows_CME_code, dataflows_CME_name, etc.
                * Keep only code and name rows under dataflows
                keep if regexm(key, "^dataflows_[A-Za-z0-9_]+_(code|name)$")
                
                * Extract dataflow ID and attribute type from key
                * Key format: dataflows_<DATAFLOW_ID>_<attribute>
                gen attribute = ""
                replace attribute = "code" if regexm(key, "_code$")
                replace attribute = "name" if regexm(key, "_name$")
                
                * Extract dataflow ID (between "dataflows_" and "_code/_name")
                gen df_id = regexs(1) if regexm(key, "^dataflows_(.+)_(code|name)$")
                
                * Reshape to wide: one row per dataflow with code and name columns
                keep df_id attribute value
                reshape wide value, i(df_id) j(attribute) string
                
                * Rename for clarity
                capture rename valuecode dataflow_id
                capture rename valuename name
                
                * Handle missing values - use df_id as fallback
                capture replace dataflow_id = df_id if missing(dataflow_id) | dataflow_id == ""
                capture replace name = dataflow_id if missing(name) | name == ""
                
                * Sort by dataflow_id for consistent output
                sort dataflow_id
                
                * Count dataflows and build ID list
                local n_flows = _N
                forvalues i = 1/`n_flows' {
                    local id = dataflow_id[`i']
                    local dataflow_ids "`dataflow_ids' `id'"
                }
                
                * Keep only final columns
                keep dataflow_id name
                order dataflow_id name
            }
            
            * Copy results to tempfile for display
            tempfile flowdata
            frame `yaml_frame': save `flowdata'
            
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
            
            * Keep only code and name rows under dataflows
            keep if regexm(key, "^dataflows_[A-Za-z0-9_]+_(code|name)$")
            
            * Extract attribute type from key
            gen attribute = ""
            replace attribute = "code" if regexm(key, "_code$")
            replace attribute = "name" if regexm(key, "_name$")
            
            * Extract dataflow ID
            gen df_id = regexs(1) if regexm(key, "^dataflows_(.+)_(code|name)$")
            
            * Reshape to wide
            keep df_id attribute value
            reshape wide value, i(df_id) j(attribute) string
            
            * Rename for clarity
            capture rename valuecode dataflow_id
            capture rename valuename name
            
            * Handle missing values
            capture replace dataflow_id = df_id if missing(dataflow_id) | dataflow_id == ""
            capture replace name = dataflow_id if missing(name) | name == ""
            
            * Sort
            sort dataflow_id
            
            * Count dataflows and build ID list
            local n_flows = _N
            forvalues i = 1/`n_flows' {
                local id = dataflow_id[`i']
                local dataflow_ids "`dataflow_ids' `id'"
            }
            
            * Keep only final columns
            keep dataflow_id name
            order dataflow_id name
            
            * Store data for display
            tempfile flowdata
            save `flowdata'
            
            restore
        }
        
        local dataflow_ids = strtrim("`dataflow_ids'")
        
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

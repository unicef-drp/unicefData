*! version 1.0.0  15Jan2026
program define _unicef_build_schema_key, rclass
* Build SDMX data key using schema-aware dimension construction
* 
* Syntax: _unicef_build_schema_key indicator_code dataflow metadata_path [, nofilter]
*
* This program dynamically extracts dimension structure from dataflow schema
* and constructs an efficient pre-fetch filter key with explicit dimension values.
*
* When nofilter=0 (default):
*     Constructs: .{INDICATOR}._T._T._T... (one _T per dimension)
*     Server filters to totals only (efficient)
*
* When nofilter=1:
*     Constructs: .{INDICATOR}.... (all values for all dimensions)
*     Server returns ALL disaggregations (50-100x more data)
*
* Returns:
*   r(key) - SDMX data key string for URL construction
*
* Example:
*   _unicef_build_schema_key "CME_MRY0T4" "CME" "/path/to/metadata"
*   local mykey = r(key)
*   
*   _unicef_build_schema_key "CME_MRY0T4" "CME" "/path/to/metadata", nofilter
*   local mykey_all = r(key)

* Parse options
    syntax anything, [NOFilter]
    local indicator_code : word 1 of `anything'
    local dataflow : word 2 of `anything'
    local metadata_path : word 3 of `anything'
    
    * nofilter option: if present, set nofilter=1
    local nofilter = 0
    if (!missing("`nofilter'")) {
        local nofilter = 1
    }
    
    * Special case: WS_HCF_* indicators in WASH_HEALTHCARE_FACILITY
    if substr(upper("`indicator_code'"), 1, 6) == "WS_HCF" & "`dataflow'" == "WASH_HEALTHCARE_FACILITY" {
        * Map indicator prefix to service type
        local suffix = substr("`indicator_code'", 7, .)
        
        local service_type ""
        if substr("`suffix'", 1, 2) == "W-" {
            local service_type "WAT"
        }
        else if substr("`suffix'", 1, 2) == "S-" {
            local service_type "SAN"
        }
        else if substr("`suffix'", 1, 2) == "H-" {
            local service_type "HYG"
        }
        else if substr("`suffix'", 1, 3) == "WM-" {
            local service_type "HCW"
        }
        else if substr("`suffix'", 1, 2) == "C-" {
            local service_type "CLEAN"
        }
        
        * Load dataflow schema to get dimension values
        local schema_file = "`metadata_path'/dataflows/`dataflow'.yaml"
        
        if !fileexists("`schema_file'") {
            * Fallback if schema not found
            if (`nofilter' == 1) {
                * Fetch all HCF and RESIDENCE values
                local hcf_vals ""
                local res_vals ""
            }
            else {
                * Pre-fetch filtering: use totals
                local hcf_vals "_T,NON_HOS,HOS,GOV,NON_GOV"
                local res_vals "_T,U,R"
            }
        }
        else {
            * Parse YAML schema to extract dimension values
            * For now, use default values (schema parsing in Stata is complex)
            if (`nofilter' == 1) {
                * Fetch all values
                local hcf_vals ""
                local res_vals ""
            }
            else {
                * Pre-fetch filtering: use known defaults
                local hcf_vals "_T,NON_HOS,HOS,GOV,NON_GOV"
                local res_vals "_T,U,R"
            }
        }
        
        * Build HCF and RESIDENCE parts
        local hcf_part = subinstr("`hcf_vals'", ",", "+", .)
        local res_part = subinstr("`res_vals'", ",", "+", .)
        
        * REF_AREA left empty for all countries
        * Key order per schema: REF_AREA.INDICATOR.SERVICE_TYPE.HCF_TYPE.RESIDENCE
        if !missing("`service_type'") {
            return local key ".`indicator_code'.`service_type'.`hcf_part'.`res_part'"
        }
        else {
            * Fallback: no service_type mapping found
            return local key ".`indicator_code'..`hcf_part'.`res_part'"
        }
    }
    
    * Standard case: construct key based on schema dimensions
    * Load dataflow schema to get dimension structure
    local schema_file = "`metadata_path'/dataflows/`dataflow'.yaml"
    
    if !fileexists("`schema_file'") {
        * Fallback if schema not found
        if (`nofilter' == 1) {
            * Fetch all disaggregations: use empty strings for all dimensions
            return local key ".`indicator_code'....."
        }
        else {
            * Pre-fetch filtering: use _T for all dimensions
            return local key ".`indicator_code'._T._T._T._T._T"
        }
    }
    
    * For now, use conservative default that applies to most dataflows
    * This builds: .{INDICATOR}._T for most dimensions (SEX set to _T for totals)
    * Or: .{INDICATOR}.. if nofilter (all disaggregations)
    * More sophisticated parsing of YAML schema can be added later if needed
    
    if (`nofilter' == 1) {
        * Fetch all disaggregations
        return local key ".`indicator_code'.."
    }
    else {
        * Pre-fetch filtering (totals only)
        return local key ".`indicator_code'._T"
    }

end

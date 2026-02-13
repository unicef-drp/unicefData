*! version 2.0.1  13Feb2026
program define _unicef_build_schema_key, rclass
* Build SDMX data key using schema-aware dimension construction
* 
* Syntax: _unicef_build_schema_key indicator_code dataflow metadata_path [, nofilter verbose]
*
* This program dynamically extracts dimension structure from dataflow schema
* and constructs an efficient pre-fetch filter key respecting actual dimension order.
*
* Key insight: Dimension order varies by dataflow:
*   - CME: INDICATOR.SEX.AGE.WEALTH.RESIDENCE
*   - WASH_HOUSEHOLDS: REF_AREA.INDICATOR.SERVICE_TYPE.WEALTH.RESIDENCE
*
* When nofilter=0 (default):
*     Uses _T for all filterable dimensions (efficient)
*
* When nofilter=1:
*     Constructs: .{INDICATOR}.... (all disaggregations, with trailing dots for known dimension count)
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

  version 11
  syntax anything, [NOFilter VERbose BULK SEX(string) AGE(string) WEALTH(string) RESIDENCE(string) MATERNAL_EDU(string) FILTERDISAGG]
  
  local indicator_code : word 1 of `anything'
  local dataflow : word 2 of `anything'
  local metadata_path : word 3 of `anything'
  
  local nofilter = cond(!missing("`nofilter'"), 1, 0)
  local bulk = cond(!missing("`bulk'"), 1, 0)
  local filter_disagg = cond(!missing("`filterdisagg'"), 1, 0)  // Skip indicator dimension if true
  
  * Handle bulk download: use 'all' as indicator code
  if (`bulk' == 1 | lower("`indicator_code'") == "all") {
    local indicator_code "all"
    if "`verbose'" != "" {
      display "  (schema_key) Bulk download mode: using 'all' for indicator dimension"
    }
  }
  
  if "`verbose'" != "" {
    display "  (schema_key) Building key for `indicator_code' in `dataflow'"
  }
  
  // Extract dimension structure using helper
  capture {
    __unicef_get_indicator_filters, dataflow("`dataflow'") `verbose'
    if _rc == 0 {
      local num_dimensions = r(num_dimensions)
      local ref_area_pos = r(ref_area_position)
      local indicator_pos = r(indicator_position)
      
      // CRITICAL: Capture individual dimension names (dimension_1, dimension_2, etc)
      // This is needed in the loop below to identify which dimensions to include in the key
      forvalues i = 1/`num_dimensions' {
        local dimension_`i' = r(dimension_`i')
      }
      
      if "`verbose'" != "" {
        display "    Dimensions: `num_dimensions' (REF_AREA at `ref_area_pos', INDICATOR at `indicator_pos')"
        forvalues i = 1/`num_dimensions' {
          display "      Position `i': `dimension_`i''"
        }
      }
    }
  }
  
  if _rc != 0 {
    if "`verbose'" != "" {
      display "    Schema lookup failed; using fallback"
    }
    // Fallback: conservative assumption
    // Bulk mode: return "all" as-is (SDMX REST standard: /all means entire dataflow)
    if (lower("`indicator_code'") == "all") {
      return local key "all"
    }
    else if (`nofilter' == 1) {
      return local key ".`indicator_code'"
    }
    else {
      return local key ".`indicator_code'._T._T._T._T._T"
    }
    exit
  }
  
  // Build key respecting dimension order
  // Strategy: Create position-aware filter vector
  
  // Bulk mode with successful schema: still return "all" — get_sdmx handles the URL
  if (lower("`indicator_code'") == "all") {
    if "`verbose'" != "" {
      display "    Bulk mode: returning 'all' key"
    }
    return local key "all"
  }

  if (`nofilter' == 1) {
    // No filter: pad with dots based on dimension count
    // Output: .INDICATOR. . . . . (one dot per non-fixed dimension)
    local key ".`indicator_code'"
    
    // Count non-fixed dimensions to pad appropriately
    local non_fixed_count = `num_dimensions' - 3  // Subtract REF_AREA, INDICATOR, TIME_PERIOD
    if `non_fixed_count' > 0 {
      local dotpad ""
      forvalues i = 1/`non_fixed_count' {
        local dotpad "`dotpad'."
      }
      local key "`key'`dotpad'"
    }
    
    if "`verbose'" != "" {
      display "    NoFilter mode: `key'"
    }
    return local key "`key'"
  }
  else {
    // User filters mode: build the key following actual schema dimension order
    // Map known disaggregation dimensions to the provided filter values
    
    // Build key starting with indicator position
    if (`filter_disagg' == 0) {
      // Include indicator in the key
      local key ".`indicator_code'"
    }
    else {
      // Filter only disaggregation dimensions (skip indicator)
      // Start with empty to only add disagg filters
      local key ""
    }
    
    // Loop over schema dimensions in order and append filter values
    // Skip fixed dimensions: REF_AREA, INDICATOR, TIME_PERIOD, UNIT_MEASURE
    forvalues i = 1/`num_dimensions' {
      local dim_id = upper("`dimension_`i''")
      
      // When filter_disagg=1, skip INDICATOR dimension entirely
      if (`filter_disagg' == 1 & "`dim_id'" == "INDICATOR") {
        continue
      }
      
      if inlist("`dim_id'", "REF_AREA", "INDICATOR", "TIME_PERIOD", "UNIT_MEASURE") {
        continue
      }
      
      // Select the appropriate filter value based on the dimension id
      local f_val ""
      if ("`dim_id'" == "SEX") {
        local f_val "`sex'"
      }
      else if ("`dim_id'" == "AGE") {
        local f_val "`age'"
      }
      else if ("`dim_id'" == "WEALTH_QUINTILE") {
        local f_val "`wealth'"
      }
      else if ("`dim_id'" == "RESIDENCE") {
        local f_val "`residence'"
      }
      else if (substr("`dim_id'",1,7) == "MATERNAL") {
        local f_val "`maternal_edu'"
      }
      else {
        // Unknown dimension: leave empty to request all
        local f_val ""
      }
      
      // Append to key, preserving positional structure
      if ("`f_val'" == "") {
        local key "`key'."
      }
      else {
        local key "`key'.`f_val'"
      }
    }
    
    if "`verbose'" != "" {
      display "    User filters mode: `key'"
      display "      sex=`sex', age=`age', wealth=`wealth', residence=`residence', maternal_edu=`maternal_edu'"
    }
    return local key "`key'"
  }

end

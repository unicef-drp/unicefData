*******************************************************************************
* _unicef_fetch_with_fallback.ado
*! v 1.0.0   09Dec2025               by Joao Pedro Azevedo (UNICEF)
* Fetch data with automatic dataflow fallback on 404 errors
* Tries alternative dataflows when primary dataflow returns no data
*******************************************************************************

program define _unicef_fetch_with_fallback, rclass
    version 14.0
    
    syntax , Indicator(string) ///
             [DATAFLOW(string) ///
              Base_url(string) ///
              VERSION(string) ///
              Start_year(string) ///
              End_year(string) ///
              PAGE_size(integer 100000) ///
              MAX_retries(integer 3) ///
              VERBOSE]
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Set defaults
        *-----------------------------------------------------------------------
        
        if ("`base_url'" == "") {
            local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
        }
        
        if ("`version'" == "") {
            local version "1.0"
        }
        
        *-----------------------------------------------------------------------
        * Build list of dataflows to try
        *-----------------------------------------------------------------------
        
        local dataflows_to_try ""
        
        * If a specific dataflow was requested, try it first
        if ("`dataflow'" != "") {
            local dataflows_to_try "`dataflow'"
        }
        
        * Extract indicator prefix for fallback detection
        local prefix = word(subinstr("`indicator'", "_", " ", 1), 1)
        
        * Define fallback dataflows based on prefix
        if ("`prefix'" == "CME") {
            local fallbacks "CME GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "NT") {
            local fallbacks "NUTRITION NUTRITION_DIETS GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "IM") {
            local fallbacks "IMMUNISATION GLOBAL_DATAFLOW"
        }
        else if inlist("`prefix'", "ED", "EDUNF") {
            local fallbacks "EDUCATION EDUANALYTICS GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "WS") {
            local fallbacks "WASH_HOUSEHOLDS WASH_SCHOOLS WASH_HEALTHCARE GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "HVA") {
            local fallbacks "HIV_AIDS GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "MNCH") {
            local fallbacks "MNCH GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "PT") {
            local fallbacks "PT CHILD_PROTECTION GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "ECD") {
            local fallbacks "ECD GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "PV") {
            local fallbacks "CHLD_PVTY CHILD_POVERTY GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "SDG") {
            local fallbacks "CHILD_RELATED_SDG SDG GLOBAL_DATAFLOW"
        }
        else {
            * Unknown prefix - try GLOBAL_DATAFLOW directly
            local fallbacks "GLOBAL_DATAFLOW"
        }
        
        * Merge with requested dataflow (avoiding duplicates)
        foreach df of local fallbacks {
            if (strpos("`dataflows_to_try'", "`df'") == 0) {
                local dataflows_to_try "`dataflows_to_try' `df'"
            }
        }
        
        *-----------------------------------------------------------------------
        * Try each dataflow in sequence
        *-----------------------------------------------------------------------
        
        local success 0
        local tried_dataflows ""
        local successful_dataflow ""
        
        tempfile tempdata
        
        foreach df of local dataflows_to_try {
            if (`success' == 1) continue
            
            local tried_dataflows "`tried_dataflows' `df'"
            
            * Build API URL for this dataflow
            local indicator_key = ".`indicator'."
            local rel_path "data/UNICEF,`df',`version'/`indicator_key'"
            
            * Query parameters
            local query_params "format=csv&labels=both"
            
            if ("`start_year'" != "" & "`start_year'" != "0") {
                local query_params "`query_params'&startPeriod=`start_year'"
            }
            
            if ("`end_year'" != "" & "`end_year'" != "0") {
                local query_params "`query_params'&endPeriod=`end_year'"
            }
            
            local query_params "`query_params'&startIndex=0&count=`page_size'"
            
            * Full URL
            local full_url "`base_url'/`rel_path'?`query_params'"
            
            if ("`verbose'" != "") {
                noi di as text "Trying dataflow: " as result "`df'"
                noi di as text "URL: " as result "`full_url'"
            }
            
            * Try to download
            local attempt_success 0
            forvalues attempt = 1/`max_retries' {
                capture copy "`full_url'" "`tempdata'", replace public
                if (_rc == 0) {
                    * Check if file has content (not a 404 or empty response)
                    capture import delimited using "`tempdata'", clear varnames(1) encoding("utf-8")
                    if (_rc == 0 & _N > 0) {
                        local attempt_success 1
                        local success 1
                        local successful_dataflow "`df'"
                        continue, break
                    }
                    else {
                        * Empty data - try next dataflow
                        if ("`verbose'" != "") {
                            noi di as text "  No data in `df' (empty response)"
                        }
                        continue, break
                    }
                }
                if ("`verbose'" != "") {
                    noi di as text "  Attempt `attempt' failed. Retrying..."
                }
                sleep 1000
            }
            
            if (`attempt_success' == 0) {
                if ("`verbose'" != "") {
                    noi di as text "  Dataflow `df' failed or returned no data"
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Return results
        *-----------------------------------------------------------------------
        
        if (`success' == 1) {
            if ("`verbose'" != "") {
                noi di as text "Successfully fetched from dataflow: " as result "`successful_dataflow'"
            }
            
            return local success "1"
            return local dataflow "`successful_dataflow'"
            return local tried_dataflows "`tried_dataflows'"
            return local obs_count = _N
            return local url "`full_url'"
        }
        else {
            noi di as err "Could not fetch data from any dataflow."
            noi di as err "Tried: `tried_dataflows'"
            
            return local success "0"
            return local dataflow ""
            return local tried_dataflows "`tried_dataflows'"
            return local obs_count = 0
        }
        
    }

end


*******************************************************************************
* Version history
*******************************************************************************
* v 1.0.0   09Dec2025   by Joao Pedro Azevedo
*   Initial release
*   - Automatic dataflow fallback on 404 errors
*   - Prefix-based fallback definitions
*   - Multiple retry support
*   - Verbose logging of attempts
*******************************************************************************

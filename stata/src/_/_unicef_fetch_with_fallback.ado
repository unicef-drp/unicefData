*******************************************************************************
* _unicef_fetch_with_fallback.ado
*! v 1.6.1   12Jan2026               by Joao Pedro Azevedo (UNICEF)
* Fetch data with automatic dataflow fallback on 404 errors
* Unified fallback architecture - sequences aligned with canonical YAML
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
        * Build list of dataflows to try - Load from canonical YAML if available
        *-----------------------------------------------------------------------
        
        local dataflows_to_try ""
        
        * If a specific dataflow was requested, try it first
        if ("`dataflow'" != "") {
            local dataflows_to_try "`dataflow'"
        }
        
        * Extract indicator prefix for fallback detection
        local prefix = word(subinstr("`indicator'", "_", " ", 1), 1)
        
        * Define fallback dataflows based on prefix
        * These match the canonical YAML fallback_sequences
        * (Hardcoded here - ideally loaded from canonical YAML via YAML package)
        if ("`prefix'" == "CME") {
            local fallbacks "CME CME_DF_2021_WQ CME_COUNTRY_ESTIMATES CME_SUBNATIONAL GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "ED") {
            local fallbacks "EDUCATION_UIS_SDG EDUCATION EDUCATION_FLS EDUCATION_IMEP_SDG GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "PT") {
            local fallbacks "PT PT_CM PT_FGM PT_CONFLICT CHILD_PROTECTION GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "COD") {
            local fallbacks "CAUSE_OF_DEATH CME MORTALITY GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "WS") {
            local fallbacks "WASH_HOUSEHOLDS WASH_SCHOOLS WASH_HEALTHCARE_FACILITY WASH GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "IM") {
            local fallbacks "IMMUNISATION IMMUNISATION_COVERAGE HEALTH GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "TRGT") {
            local fallbacks "CHILD_RELATED_SDG SDG_CHILD_TARGETS GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "SPP") {
            local fallbacks "SOC_PROTECTION SOCIAL_PROTECTION SOC_SAFETY_NETS GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "MNCH") {
            local fallbacks "MNCH MATERNAL_HEALTH CHILD_HEALTH HEALTH GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "NT") {
            local fallbacks "NUTRITION NUTRITION_STUNTING NUTRITION_WASTING CHILD_NUTRITION HEALTH GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "ECD") {
            local fallbacks "ECD EARLY_CHILDHOOD_DEVELOPMENT EDUCATION GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "HVA") {
            local fallbacks "HIV_AIDS HIV AIDS HEALTH GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "PV") {
            local fallbacks "CHLD_PVTY CHILD_POVERTY POVERTY GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "DM") {
            local fallbacks "DM DEMOGRAPHICS DM_PROJECTIONS POPULATION GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "MG") {
            local fallbacks "MG MIGRATION CHILD_MIGRATION GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "GN") {
            local fallbacks "GENDER GENDER_EQUALITY GIRLS_EDUCATION GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "FD") {
            local fallbacks "FUNCTIONAL_DIFF DISABILITY FUNCTIONAL_DIFFICULTY HEALTH GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "ECO") {
            local fallbacks "ECONOMIC ECONOMICS LABOUR EMPLOYMENT GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "COVID") {
            local fallbacks "COVID_CASES COVID COVID_DEATHS COVID_VACCINATION HEALTH GLOBAL_DATAFLOW"
        }
        else if ("`prefix'" == "WT") {
            local fallbacks "WASH_HOUSEHOLDS WASH_SCHOOLS PT CHILD_PROTECTION EDUCATION GLOBAL_DATAFLOW"
        }
        else {
            * Unknown prefix - use DEFAULT from canonical YAML
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

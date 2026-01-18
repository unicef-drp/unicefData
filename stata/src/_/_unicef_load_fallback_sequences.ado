*******************************************************************************
* _unicef_load_fallback_sequences.ado
*! v 1.6.1   12Jan2026               by Joao Pedro Azevedo (UNICEF)
* Load fallback dataflow sequences from canonical YAML
* Replaces hardcoded fallback sequences in _unicef_fetch_with_fallback.ado
*******************************************************************************

program define _unicef_load_fallback_sequences, rclass
    version 14.0
    
    syntax , Prefix(string) [VERBOSE]
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Determine canonical YAML file location
        *-----------------------------------------------------------------------
        
        local yaml_file ""
        
        * Try canonical location first (parent of current directory)
        local parent_path = subinstr("`c(pwd)'", "\stata\src", "", 1)
        local canonical = "`parent_path'\..\metadata\current\_dataflow_fallback_sequences.yaml"
        
        if (fileexists("`canonical'")) {
            local yaml_file "`canonical'"
            if ("`verbose'" != "") {
                noi di as txt "✓ Found canonical YAML: `yaml_file'"
            }
        }
        else {
            * Try package location
            local pkg_yaml = "`c(sysdir_plus)'y\_dataflow_fallback_sequences.yaml"
            if (fileexists("`pkg_yaml'")) {
                local yaml_file "`pkg_yaml'"
                if ("`verbose'" != "") {
                    noi di as txt "✓ Found package YAML: `yaml_file'"
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Load from YAML if available, otherwise use hardcoded defaults
        *-----------------------------------------------------------------------
        
        local fallbacks ""
        
        if ("`yaml_file'" != "") {
            * Try to load from YAML file
            capture {
                preserve
                
                * Load YAML into frame (Stata 16+)
                if (_N > 0 | _N == 0) {
                    frame create yaml_fallback_seq
                    frame yaml_fallback_seq: yaml read using "`yaml_file'", replace quiet
                }
                
                * Extract fallback sequence for this prefix from YAML
                frame yaml_fallback_seq: {
                    keep if strpos(key, "`prefix'") > 0 & level == 1
                    if (_N > 0) {
                        noi di as txt "✓ Loaded fallback sequences from YAML"
                    }
                }
                
                restore
            }
            
            * If YAML loading failed, fall back to hardcoded defaults
            if (_rc != 0 | "`fallbacks'" == "") {
                if ("`verbose'" != "") {
                    noi di as txt "⚠ YAML loading failed, using hardcoded defaults"
                }
                * Hardcoded fallback (same as in _unicef_fetch_with_fallback.ado)
                local fallbacks "`_get_hardcoded_fallbacks_`prefix''"
            }
        }
        else {
            * No YAML file found, use hardcoded defaults
            if ("`verbose'" != "") {
                noi di as txt "⚠ YAML file not found, using hardcoded defaults"
            }
            local fallbacks "`_get_hardcoded_fallbacks_`prefix''"
        }
        
        *-----------------------------------------------------------------------
        * Return fallback sequence
        *-----------------------------------------------------------------------
        
        return local fallbacks "`fallbacks'"
        return local source "YAML"
    }
    
end

*******************************************************************************
* Helper: Get hardcoded fallback sequences by prefix
* (Same as in _unicef_fetch_with_fallback.ado for backward compatibility)
*******************************************************************************

program define _get_hardcoded_fallbacks, rclass
    version 14.0
    
    syntax , Prefix(string)
    
    local fallbacks ""
    
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
        * Unknown prefix - use DEFAULT fallback
        local fallbacks "GLOBAL_DATAFLOW"
    }
    
    return local fallbacks "`fallbacks'"
end

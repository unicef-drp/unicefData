*******************************************************************************
*! __unicef_parse_ind_yaml_v2 v1.0.2  21Feb2026
*! Parse UNICEF indicators metadata YAML using yaml.ado bulk collapse (faster)
*! Drop-in replacement for __unicef_parse_indicators_yaml.ado
*! 
*! Uses yaml v1.9.0 indicators preset for ~60% faster parsing
*! Produces identical output variables for compatibility with cache loader
*******************************************************************************

program define __unicef_parse_ind_yaml_v2
    version 14.0
    args yaml_path

    * Check yaml.ado is installed with required version (once per session)
    if "$UNICEF_yaml_checked" != "1" {
        _unicefdata_check_yaml, minversion(1.9.0)
        global UNICEF_yaml_checked 1
    }

    quietly {
        * Use yaml v1.9.0 bulk+collapse with UNICEF-specific colfields
        * (indicators preset has wrong default colfields for UNICEF YAML)
        yaml read using "`yaml_path'", bulk collapse replace colfields(code;name;description;urn;parent;tier;tier_reason;dataflows;disaggregations;disaggregations_with_totals)
        
        * yaml produces 'ind_code' from YAML keys - this is what we want
        * Drop redundant code column (ind_code already has the code)
        capture drop code
        
        * Rename fields to match __unicef_parse_indicators_yaml output format
        * _yaml_collapse already concatenates list items with semicolons into
        * single columns (e.g. dataflows = "CME;GLOBAL_DATAFLOW"), so we
        * just rename — no need to find/merge dataflows_1, dataflows_2, etc.

        * Rename core fields with field_ prefix
        rename name field_name
        rename description field_desc

        * Handle optional fields that may not exist
        capture rename urn field_urn
        if (_rc != 0) gen str1 field_urn = ""

        capture rename parent field_parent
        if (_rc != 0) gen str1 field_parent = ""

        capture rename tier field_tier
        if (_rc != 0) gen str1 field_tier = ""

        capture rename tier_reason field_tier_reason
        if (_rc != 0) gen str1 field_tier_reason = ""

        * Rename array fields (already semicolon-separated by _yaml_collapse)
        capture rename dataflows field_dataflows
        if (_rc != 0) gen str1 field_dataflows = ""

        capture rename disaggregations field_disagg
        if (_rc != 0) gen str1 field_disagg = ""

        capture rename disaggregations_with_totals field_disagg_totals
        if (_rc != 0) gen str1 field_disagg_totals = ""
        
        * Drop empty indicator rows (if any)
        drop if ind_code == ""
        
        * Add parser version for cache invalidation
        gen str10 _parser_version = "1.0.2"
        
        * Keep only necessary columns
        keep ind_code field_name field_desc field_urn field_parent ///
             field_dataflows field_tier field_tier_reason ///
             field_disagg field_disagg_totals _parser_version
    }
end


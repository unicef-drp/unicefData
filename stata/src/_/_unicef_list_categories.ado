*******************************************************************************
* _unicef_list_categories.ado
*! v 1.3.2   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* List all available indicator categories with counts
* Uses yaml.ado for robust YAML parsing
* Uses Stata frames (v16+) for better isolation when available
* v1.3.2: Use full indicator catalog (733 indicators) with category field
* v1.3.1: Fixed frame naming (use explicit yaml_ prefix for clarity)
* 
* Aligned with Python list_categories() and R list_categories()
*******************************************************************************

program define _unicef_list_categories, rclass
    version 14.0
    
    syntax [, VERBOSE METApath(string)]
    
    * Check if frames are available (Stata 16+)
    local use_frames = (c(stata_version) >= 16)
    
    quietly {
    
        *-----------------------------------------------------------------------
        * Locate metadata directory (YAML files in src/_/ alongside this ado)
        *-----------------------------------------------------------------------
        
        if ("`metapath'" == "") {
            * Find the helper program location (src/_/)
            capture findfile _unicef_list_categories.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                * Extract directory containing this ado file
                local ado_dir = subinstr("`ado_path'", "\", "/", .)
                local ado_dir = subinstr("`ado_dir'", "_unicef_list_categories.ado", "", .)
                local metapath "`ado_dir'"
            }
            
            * Fallback to PLUS directory _/
            if ("`metapath'" == "") | (!fileexists("`metapath'_unicefdata_indicators_metadata.yaml")) {
                local metapath "`c(sysdir_plus)'_/"
            }
        }
        
        * Use full indicator catalog (733 indicators with category field)
        local yaml_file "`metapath'_unicefdata_indicators_metadata.yaml"
        
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
            noi di as text "Reading categories from: " as result "`yaml_file'"
        }
        
        *-----------------------------------------------------------------------
        * Read YAML file and count categories
        *-----------------------------------------------------------------------
        
        * Initialize category tracking
        * We'll use locals to track categories and their counts
        * Format: cat_<name> = count
        local categories ""
        local total_indicators = 0
        
        if (`use_frames') {
            * Stata 16+ - use frames for better isolation
            * Note: yaml.ado prefixes frame names with "yaml_"
            local yaml_frame_base "unicef_cat"
            local yaml_frame "yaml_`yaml_frame_base'"
            capture frame drop `yaml_frame'
            
            * Read YAML into a frame (yaml.ado will prefix with "yaml_")
            yaml read using "`yaml_file'", frame(`yaml_frame_base')
            
            * Use the actual frame name (with yaml_ prefix)
            frame `yaml_frame' {
                * Get all indicator codes under 'indicators' parent
                yaml list indicators, keys children frame(`yaml_frame_base')
                local all_indicators "`r(keys)'"
                
                foreach ind of local all_indicators {
                    local ++total_indicators
                    
                    * Get category for this indicator (from full catalog)
                    capture yaml get indicators:`ind', attributes(category) quiet frame(`yaml_frame_base')
                    if (_rc == 0 & "`r(category)'" != "") {
                        local cat_name = "`r(category)'"
                    }
                    else {
                        local cat_name = "UNKNOWN"
                    }
                    
                    * Update category count
                    local cat_clean = subinstr("`cat_name'", " ", "_", .)
                    local cat_clean = subinstr("`cat_clean'", "-", "_", .)
                    
                    if (strpos("`categories'", "`cat_clean'") == 0) {
                        * New category
                        local categories "`categories' `cat_clean'"
                        local count_`cat_clean' = 1
                    }
                    else {
                        * Existing category - increment
                        local count_`cat_clean' = `count_`cat_clean'' + 1
                    }
                }
            }
            
            * Clean up frame
            capture frame drop `yaml_frame'
        }
        else {
            * Stata 14/15 - use preserve/restore
            preserve
            
            yaml read using "`yaml_file'", replace
            
            * Get all indicator codes under 'indicators' parent
            yaml list indicators, keys children
            local all_indicators "`r(keys)'"
            
            foreach ind of local all_indicators {
                local ++total_indicators
                
                * Get category for this indicator (from full catalog)
                capture yaml get indicators:`ind', attributes(category) quiet
                if (_rc == 0 & "`r(category)'" != "") {
                    local cat_name = "`r(category)'"
                }
                else {
                    local cat_name = "UNKNOWN"
                }
                
                * Update category count
                local cat_clean = subinstr("`cat_name'", " ", "_", .)
                local cat_clean = subinstr("`cat_clean'", "-", "_", .)
                
                if (strpos("`categories'", "`cat_clean'") == 0) {
                    * New category
                    local categories "`categories' `cat_clean'"
                    local count_`cat_clean' = 1
                }
                else {
                    * Existing category - increment
                    local count_`cat_clean' = `count_`cat_clean'' + 1
                }
            }
            
            restore
        }
        
        local categories = strtrim("`categories'")
        local n_categories : word count `categories'
        
        *-----------------------------------------------------------------------
        * Sort categories by count (descending)
        *-----------------------------------------------------------------------
        
        * Create temporary dataset to sort
        preserve
        clear
        local n_cat : word count `categories'
        set obs `n_cat'
        gen str50 category = ""
        gen int count = .
        
        local i = 1
        foreach cat of local categories {
            replace category = "`cat'" in `i'
            replace count = `count_`cat'' in `i'
            local ++i
        }
        
        gsort -count category
        
        * Store sorted order
        local sorted_categories ""
        local sorted_counts ""
        forvalues i = 1/`n_cat' {
            local cat_val = category[`i']
            local count_val = count[`i']
            local sorted_categories "`sorted_categories' `cat_val'"
            local sorted_counts "`sorted_counts' `count_val'"
        }
        
        restore
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 50}"
    noi di as text "  Available Indicator Categories"
    noi di as text "{hline 50}"
    noi di ""
    noi di as text _col(3) "{ul:Category}" _col(35) "{ul:Count}"
    noi di as text "{hline 50}"
    
    local i = 1
    foreach cat of local sorted_categories {
        local count_val : word `i' of `sorted_counts'
        noi di as result _col(3) "`cat'" as text _col(35) %6.0f `count_val'
        local ++i
    }
    
    noi di as text "{hline 50}"
    noi di as text _col(3) "{bf:TOTAL}" _col(35) as result %6.0f `total_indicators'
    noi di as text "{hline 50}"
    noi di ""
    noi di as text "  Use {bf:unicefdata, search(keyword) dataflow(CATEGORY)}"
    noi di as text "  to search indicators within a specific category."
    noi di ""
    noi di as text "  Use {bf:unicefdata, indicators(CATEGORY)} to list all"
    noi di as text "  indicators in a specific category."
    noi di ""
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar n_categories = `n_categories'
    return scalar n_indicators = `total_indicators'
    return local categories "`sorted_categories'"
    
    * Also return counts for each category
    foreach cat of local sorted_categories {
        return scalar count_`cat' = `count_`cat''
    }
    
end

*******************************************************************************
* Version history
*******************************************************************************
* v 1.3.2   17Dec2025   by Joao Pedro Azevedo
*   - Use full indicator catalog (unicef_indicators_metadata.yaml, 733 indicators)
*   - Read 'category' field instead of 'dataflow' for category grouping
*
* v 1.3.1   17Dec2025   by Joao Pedro Azevedo
*   - Fixed frame naming (use explicit yaml_ prefix for clarity)
*
* v 1.3.0   17Dec2025   by Joao Pedro Azevedo
*   Initial implementation
*   - Lists all indicator categories (dataflows) with counts
*   - Aligned with Python list_categories() and R list_categories()
*   - Uses frames for Stata 16+ for better isolation
*   - Returns r(categories) list and r(n_categories), r(n_indicators) scalars
*******************************************************************************
*******************************************************************************

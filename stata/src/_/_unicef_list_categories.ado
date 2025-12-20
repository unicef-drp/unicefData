*******************************************************************************
* _unicef_list_categories.ado
*! v 1.4.0   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* List all available indicator categories with counts
* Uses yaml.ado for robust YAML parsing
* Uses Stata frames (v16+) for better isolation when available
*
* v1.4.0: MAJOR REWRITE - Direct dataset query instead of 733 yaml get calls
*         - Much faster: single dataset filter vs 733 individual lookups
*         - More robust: avoids frame context/return value issues
*         - Idiomatic Stata: leverage dataset operations
* v1.3.3: Remove redundant frame() option when already inside frame block
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
        * Read YAML and extract categories using direct dataset operations
        * This is MUCH faster than calling yaml get 733 times
        *-----------------------------------------------------------------------
        
        if (`use_frames') {
            *-------------------------------------------------------------------
            * Stata 16+ - use frames for better isolation
            *-------------------------------------------------------------------
            local yaml_frame_base "unicef_cat"
            local yaml_frame "yaml_`yaml_frame_base'"
            capture frame drop `yaml_frame'
            
            * Read YAML into a frame (yaml.ado stores as key/value dataset)
            yaml read using "`yaml_file'", frame(`yaml_frame_base')
            
            * Work directly with the dataset in the frame
            frame `yaml_frame' {
                * yaml.ado creates dataset with columns: key, value, level, parent, type
                * Keys look like: indicators_HVA_EPI_LHIV_category (yaml.ado uses _ as separator)
                * We want all rows where key ends with _category under indicators
                
                * Keep only category rows (one per indicator)
                * Exclude description entries (keys containing _description_)
                keep if regexm(key, "^indicators_[A-Za-z0-9_]+_category$")
                drop if regexm(key, "_description_")
                
                * Count total indicators
                local total_indicators = _N
                
                * Handle missing/empty categories
                replace value = "UNKNOWN" if value == "" | missing(value)
                
                * Clean category names (replace spaces and hyphens with underscores)
                replace value = subinstr(value, " ", "_", .)
                replace value = subinstr(value, "-", "_", .)
                
                * Get unique categories and their counts
                * Use collapse to count occurrences of each category
                rename value category
                gen count = 1
                collapse (sum) count, by(category)
                
                * Sort by count descending, then category name
                gsort -count category
                
                * Extract results into locals
                local n_categories = _N
                local sorted_categories ""
                local sorted_counts ""
                
                forvalues i = 1/`n_categories' {
                    local cat_val = category[`i']
                    local count_val = count[`i']
                    local sorted_categories "`sorted_categories' `cat_val'"
                    local sorted_counts "`sorted_counts' `count_val'"
                    * Store individual count for return values
                    local count_`cat_val' = `count_val'
                }
            }
            
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
            
            * Keep only category rows (one per indicator)
            * yaml.ado uses underscores as key separator
            * Exclude description entries (keys containing _description_)
            keep if regexm(key, "^indicators_[A-Za-z0-9_]+_category$")
            drop if regexm(key, "_description_")
            
            * Count total indicators
            local total_indicators = _N
            
            * Handle missing/empty categories
            replace value = "UNKNOWN" if value == "" | missing(value)
            
            * Clean category names
            replace value = subinstr(value, " ", "_", .)
            replace value = subinstr(value, "-", "_", .)
            
            * Get unique categories and their counts
            rename value category
            gen count = 1
            collapse (sum) count, by(category)
            
            * Sort by count descending, then category name
            gsort -count category
            
            * Extract results into locals
            local n_categories = _N
            local sorted_categories ""
            local sorted_counts ""
            
            forvalues i = 1/`n_categories' {
                local cat_val = category[`i']
                local count_val = count[`i']
                local sorted_categories "`sorted_categories' `cat_val'"
                local sorted_counts "`sorted_counts' `count_val'"
                * Store individual count for return values
                local count_`cat_val' = `count_val'
            }
            
            restore
        }
        
        local sorted_categories = strtrim("`sorted_categories'")
        local sorted_counts = strtrim("`sorted_counts'")
        
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Display results
    *---------------------------------------------------------------------------
    
    noi di ""
    noi di as text "{hline 50}"
    noi di as text "  Available Indicator Categories (click to search)"
    noi di as text "{hline 50}"
    noi di ""
    noi di as text _col(3) "{ul:Category}" _col(35) "{ul:Count}"
    noi di as text "{hline 50}"
    
    local i = 1
    foreach cat of local sorted_categories {
        local count_val : word `i' of `sorted_counts'
        noi di as text _col(3) "{stata unicefdata, search(`cat') limit(100):`cat'}" as text _col(35) %6.0f `count_val'
        local ++i
    }
    
    noi di as text "{hline 50}"
    noi di as text _col(3) "{bf:TOTAL}" _col(35) as result %6.0f `total_indicators'
    noi di as text "{hline 50}"
    
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
* v 1.4.0   17Dec2025   by Joao Pedro Azevedo
*   - MAJOR REWRITE: Direct dataset query instead of 733 yaml get calls
*   - Performance: Single regexm filter + collapse vs 733 individual lookups
*   - Robustness: Avoids frame context/return value propagation issues
*   - Idiomatic: Leverages Stata's dataset manipulation strengths
*
* v 1.3.3   17Dec2025   by Joao Pedro Azevedo
*   - Remove redundant frame() option when already inside frame block
*
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

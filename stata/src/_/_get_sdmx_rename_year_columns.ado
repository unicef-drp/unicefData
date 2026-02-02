*! version 2.0.0  30Jan2026
*! Added non-year variable tracking and optional reordering
*! Added AUTO detection mode to intelligently choose between ROW and LABEL sources
program define _get_sdmx_rename_year_columns, rclass
    version 11
    syntax , csvfile(string) [ROW LABEL AUTO REORDER]
    
    // Purpose: Rename columns based on first row values or variable labels
    // Used after importing data where column headers are stored as data or labels
    //
    // Options:
    //   auto    - (default) Auto-detect best source by counting year-like patterns
    //             Compares first row values vs labels, uses source with more years
    //   row     - Force rename columns using first row values
    //             Used when insheet creates v1, v2, v3... and puts headers 
    //             in first data row (csv-ts format or similar)
    //   label   - Force rename columns using variable labels
    //             Used when variable labels contain the desired column names
    //   reorder - Reorder variables so non-year columns come before year columns
    //
    // AUTO Detection Logic:
    //   1. Count columns where first row value looks like a year (1900-2100)
    //   2. Count columns where variable label looks like a year (1900-2100)
    //   3. Choose source with higher year count
    //   4. Tie-breaker: prefer LABEL (more stable, no data row dropped)
    //
    // Returns:
    //   r(renamed_count)  - Number of columns renamed
    //   r(method)         - Detection method used (ROW, LABEL, LABEL_FALLBACK)
    //   r(non_year_vars)  - Space-separated list of non-year variables (context/dimensions)
    //   r(year_vars)      - Space-separated list of year variables (yr####)
    //   r(non_year_count) - Count of non-year variables
    //   r(year_count)     - Count of year variables
    //
    // Note: AUTO is default if no option specified
    // Values are cleaned to be valid Stata variable names
    
    // Count options specified
    local opt_count = 0
    if "`row'" != "" local opt_count = `opt_count' + 1
    if "`label'" != "" local opt_count = `opt_count' + 1
    if "`auto'" != "" local opt_count = `opt_count' + 1
    
    // Validate: only one option allowed
    if `opt_count' > 1 {
        display as error "options auto, row, and label are mutually exclusive"
        error 198
    }
    
    // Default to AUTO if no option specified
    if `opt_count' == 0 {
        local auto "auto"
    }
    
    quietly ds
    local allvars `r(varlist)'
    local renamed_count = 0
    local chosen_method ""
    
    // =========================================================================
    // AUTO DETECTION: Determine best source for column names
    // =========================================================================
    if "`auto'" != "" {
        local row_year_count = 0
        local label_year_count = 0
        
        foreach varname of local allvars {
            // --- Check first row value for year pattern ---
            capture local firstval = `varname'[1]
            if _rc == 0 {
                // Convert numeric to string
                local valtype : type `varname'
                if substr("`valtype'", 1, 3) != "str" {
                    capture local firstval = string(`varname'[1], "%10.0g")
                    if _rc != 0 | "`firstval'" == "." {
                        local firstval ""
                    }
                }
                
                // Check if looks like a year (4-digit number 1900-2100)
                local firstval = trim("`firstval'")
                if length("`firstval'") == 4 {
                    local is_numeric = 1
                    forvalues i = 1/4 {
                        local char = substr("`firstval'", `i', 1)
                        if !inrange("`char'", "0", "9") {
                            local is_numeric = 0
                        }
                    }
                    if `is_numeric' == 1 {
                        local yearnum = real("`firstval'")
                        if `yearnum' >= 1900 & `yearnum' <= 2100 {
                            local row_year_count = `row_year_count' + 1
                        }
                    }
                }
            }
            
            // --- Check variable label for year pattern ---
            local varlabel : variable label `varname'
            local varlabel = trim("`varlabel'")
            if length("`varlabel'") == 4 {
                local is_numeric = 1
                forvalues i = 1/4 {
                    local char = substr("`varlabel'", `i', 1)
                    if !inrange("`char'", "0", "9") {
                        local is_numeric = 0
                    }
                }
                if `is_numeric' == 1 {
                    local yearnum = real("`varlabel'")
                    if `yearnum' >= 1900 & `yearnum' <= 2100 {
                        local label_year_count = `label_year_count' + 1
                    }
                }
            }
        }
        
        // Decision: choose source with more year patterns
        // Tie-breaker: prefer LABEL (more stable, no row dropped)
        if `label_year_count' >= `row_year_count' & `label_year_count' > 0 {
            local label "label"
            local chosen_method "LABEL"
        }
        else if `row_year_count' > 0 {
            local row "row"
            local chosen_method "ROW"
        }
        else {
            // No year patterns found - fallback to LABEL as safer option
            local label "label"
            local chosen_method "LABEL_FALLBACK"
        }
    }
    
    // =========================================================================
    // METHOD 1: ROW - Use first row values as column names
    // =========================================================================
    if "`row'" != "" {
        foreach varname of local allvars {
            // Get the value in row 1 for this variable
            // Handle both string and numeric variables
            capture local firstval = `varname'[1]
            if _rc != 0 {
                continue
            }
            
            // Convert numeric to string if needed
            local valtype : type `varname'
            if substr("`valtype'", 1, 3) != "str" {
                // Numeric variable - convert to string
                capture local firstval = string(`varname'[1], "%10.0g")
                if _rc != 0 | "`firstval'" == "." {
                    continue
                }
            }
            else {
                // String variable - get value directly
                local firstval = `varname'[1]
            }
            
            // Skip if empty
            if trim("`firstval'") == "" {
                continue
            }
            
            // Clean value to create valid Stata variable name
            local newname = trim("`firstval'")
            
            // Replace spaces and special chars with underscores
            local newname = subinstr("`newname'", " ", "_", .)
            local newname = subinstr("`newname'", "-", "_", .)
            local newname = subinstr("`newname'", ".", "_", .)
            local newname = subinstr("`newname'", ",", "_", .)
            local newname = subinstr("`newname'", "(", "_", .)
            local newname = subinstr("`newname'", ")", "_", .)
            local newname = subinstr("`newname'", "/", "_", .)
            local newname = subinstr("`newname'", "&", "_", .)
            local newname = subinstr("`newname'", "%", "pct", .)
            local newname = subinstr("`newname'", "#", "n", .)
            local newname = subinstr("`newname'", "'", "", .)
            local newname = subinstr("`newname'", `"""', "", .)
            
            // Remove multiple consecutive underscores
            while strpos("`newname'", "__") > 0 {
                local newname = subinstr("`newname'", "__", "_", .)
            }
            
            // Remove leading/trailing underscores
            while substr("`newname'", 1, 1) == "_" & length("`newname'") > 1 {
                local newname = substr("`newname'", 2, .)
            }
            while substr("`newname'", -1, 1) == "_" & length("`newname'") > 1 {
                local newname = substr("`newname'", 1, length("`newname'")-1)
            }
            
            // If starts with digit, prefix with "yr" (for year columns like 2019 -> yr2019)
            local firstchar = substr("`newname'", 1, 1)
            if inrange("`firstchar'", "0", "9") {
                local newname = "yr`newname'"
            }
            
            // Truncate to 32 characters (Stata limit)
            if length("`newname'") > 32 {
                local newname = substr("`newname'", 1, 32)
            }
            
            // Skip if empty after cleaning or same as original
            if "`newname'" == "" | "`newname'" == "`varname'" {
                continue
            }
            
            // Rename the variable
            capture rename `varname' `newname'
            if _rc == 0 {
                label variable `newname' "`firstval'"
                local renamed_count = `renamed_count' + 1
            }
        }
        
        // If we renamed columns, first row is header data - drop it
        if `renamed_count' > 0 {
            quietly drop in 1
        }
    }
    
    // =========================================================================
    // METHOD 2: LABEL - Use variable labels as column names
    // =========================================================================
    else if "`label'" != "" {
        foreach varname of local allvars {
            // Get the variable label
            local varlabel : variable label `varname'
            
            // Skip if no label
            if trim("`varlabel'") == "" {
                continue
            }
            
            // Clean label to create valid Stata variable name
            local newname = trim("`varlabel'")
            
            // Replace spaces and special chars with underscores
            local newname = subinstr("`newname'", " ", "_", .)
            local newname = subinstr("`newname'", "-", "_", .)
            local newname = subinstr("`newname'", ".", "_", .)
            local newname = subinstr("`newname'", ",", "_", .)
            local newname = subinstr("`newname'", "(", "_", .)
            local newname = subinstr("`newname'", ")", "_", .)
            local newname = subinstr("`newname'", "/", "_", .)
            local newname = subinstr("`newname'", "&", "_", .)
            local newname = subinstr("`newname'", "%", "pct", .)
            local newname = subinstr("`newname'", "#", "n", .)
            local newname = subinstr("`newname'", "'", "", .)
            local newname = subinstr("`newname'", `"""', "", .)
            
            // Remove multiple consecutive underscores
            while strpos("`newname'", "__") > 0 {
                local newname = subinstr("`newname'", "__", "_", .)
            }
            
            // Remove leading/trailing underscores
            while substr("`newname'", 1, 1) == "_" & length("`newname'") > 1 {
                local newname = substr("`newname'", 2, .)
            }
            while substr("`newname'", -1, 1) == "_" & length("`newname'") > 1 {
                local newname = substr("`newname'", 1, length("`newname'")-1)
            }
            
            // If starts with digit, prefix with "yr"
            local firstchar = substr("`newname'", 1, 1)
            if inrange("`firstchar'", "0", "9") {
                local newname = "yr`newname'"
            }
            
            // Truncate to 32 characters (Stata limit)
            if length("`newname'") > 32 {
                local newname = substr("`newname'", 1, 32)
            }
            
            // Skip if empty after cleaning or same as original
            if "`newname'" == "" | "`newname'" == "`varname'" {
                continue
            }
            
            // Rename the variable
            capture rename `varname' `newname'
            if _rc == 0 {
                label variable `newname' "`varlabel'"
                local renamed_count = `renamed_count' + 1
            }
        }
        // Note: LABEL method does NOT drop first row (labels don't add data rows)
    }
    
    // =========================================================================
    // COLLECT NON-YEAR AND YEAR VARIABLES
    // =========================================================================
    // After renaming, categorize variables into non-year (context) and year columns
    quietly ds
    local allvars_final `r(varlist)'
    local non_year_vars ""
    local year_vars ""
    
    foreach varname of local allvars_final {
        // Check if variable name matches yr#### pattern (year column)
        local is_year_var = 0
        if substr("`varname'", 1, 2) == "yr" & length("`varname'") == 6 {
            // Check remaining 4 chars are digits
            local yearpart = substr("`varname'", 3, 4)
            local is_numeric = 1
            forvalues i = 1/4 {
                local char = substr("`yearpart'", `i', 1)
                if !inrange("`char'", "0", "9") {
                    local is_numeric = 0
                }
            }
            if `is_numeric' == 1 {
                local yearnum = real("`yearpart'")
                if `yearnum' >= 1900 & `yearnum' <= 2100 {
                    local is_year_var = 1
                }
            }
        }
        
        if `is_year_var' == 1 {
            local year_vars "`year_vars' `varname'"
        }
        else {
            local non_year_vars "`non_year_vars' `varname'"
        }
    }
    
    // Trim leading spaces
    local non_year_vars = trim("`non_year_vars'")
    local year_vars = trim("`year_vars'")
    
    // Count variables
    local non_year_count : word count `non_year_vars'
    local year_count : word count `year_vars'
    
    // =========================================================================
    // OPTIONAL: REORDER VARIABLES (non-year first, then year columns)
    // =========================================================================
    if "`reorder'" != "" & "`non_year_vars'" != "" & "`year_vars'" != "" {
        order `non_year_vars' `year_vars'
    }
    
    // Return results
    return local renamed_count `renamed_count'
    return local method "`chosen_method'"
    return local non_year_vars "`non_year_vars'"
    return local year_vars "`year_vars'"
    return local non_year_count `non_year_count'
    return local year_count `year_count'
end

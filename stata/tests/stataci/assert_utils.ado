*! assert_utils.ado
*! Enhanced assertion utilities for unicefdata testing
*! Based on stataci framework with additional data validation assertions
*! Author: Joao Pedro Azevedo
*! Date: December 2025

* ============================================================================
* NUMERIC ASSERTIONS
* ============================================================================

capture program drop assert_equal_num
program define assert_equal_num
    version 14.0
    syntax anything(name=a) anything(name=b) [, MSG(string)]
    
    tempname A B
    scalar `A' = `a'
    scalar `B' = `b'
    
    if (`A' != `B') {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Expected: `b' = " `B'
        di as error "  Got:      `a' = " `A'
        exit 9
    }
end

capture program drop assert_approx
program define assert_approx
    version 14.0
    syntax anything(name=a) anything(name=b) [, Tolerance(real 1e-6) MSG(string)]
    
    tempname A B diff
    scalar `A' = `a'
    scalar `B' = `b'
    scalar `diff' = abs(`A' - `B')
    
    if (`diff' > `tolerance') {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Values differ by " `diff' " (tolerance: `tolerance')"
        di as error "  Expected: ~`b'"
        di as error "  Got:      `a'"
        exit 9
    }
end

capture program drop assert_greater
program define assert_greater
    version 14.0
    syntax anything(name=a) anything(name=b) [, MSG(string)]
    
    tempname A B
    scalar `A' = `a'
    scalar `B' = `b'
    
    if (`A' <= `B') {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Expected `a' > `b'"
        di as error "  Got: " `A' " <= " `B'
        exit 9
    }
end

capture program drop assert_inrange
program define assert_inrange
    version 14.0
    args val lower upper
    
    if (`val' < `lower' | `val' > `upper') {
        di as error "Assertion failed: Value not in range"
        di as error "  Value `val' not in [`lower', `upper']"
        exit 9
    }
end

* ============================================================================
* STRING ASSERTIONS
* ============================================================================

capture program drop assert_equal_str
program define assert_equal_str
    version 14.0
    syntax anything(name=a) anything(name=b) [, MSG(string)]
    
    local A "`a'"
    local B "`b'"
    
    if ("`A'" != "`B'") {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Expected: '`B''"
        di as error "  Got:      '`A''"
        exit 9
    }
end

capture program drop assert_contains
program define assert_contains
    version 14.0
    syntax anything(name=haystack) anything(name=needle) [, MSG(string)]
    
    local pos = strpos("`haystack'", "`needle'")
    
    if (`pos' == 0) {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  String '`haystack'' does not contain '`needle''"
        exit 9
    }
end

* ============================================================================
* FILE ASSERTIONS
* ============================================================================

capture program drop assert_file_exists
program define assert_file_exists
    version 14.0
    args path
    
    * Remove any surrounding quotes
    local p = subinstr(`"`path'"', `"""', "", .)
    
    if !fileexists("`p'") {
        di as error "Assertion failed: File not found"
        di as error "  File not found: `p'"
        exit 9
    }
end

capture program drop assert_dir_exists
program define assert_dir_exists
    version 14.0
    args path
    
    * Remove any surrounding quotes
    local p = subinstr(`"`path'"', `"""', "", .)
    
    capture confirm file "`p'/."
    if _rc {
        di as error "Assertion failed: Directory not found"
        di as error "  Directory not found: `p'"
        exit 9
    }
end

* ============================================================================
* RETURN CODE ASSERTIONS
* ============================================================================

capture program drop assert_rc_zero
program define assert_rc_zero
    version 14.0
    syntax [, MSG(string)]
    
    if (_rc != 0) {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Return code = `=_rc' (expected 0)"
        exit 9
    }
end

capture program drop assert_error
program define assert_error
    version 14.0
    syntax anything(name=expected_rc) [, MSG(string)]
    
    if (_rc != `expected_rc') {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Expected error code: `expected_rc'"
        di as error "  Got error code: `=_rc'"
        exit 9
    }
end

* ============================================================================
* DATA ASSERTIONS (unicefdata-specific)
* ============================================================================

capture program drop assert_nobs
program define assert_nobs
    version 14.0
    syntax anything(name=expected) [, MIN MAX MSG(string)]
    
    local N = _N
    
    * Check minimum
    if "`min'" != "" {
        if (`N' < `expected') {
            if "`msg'" != "" {
                di as error "Assertion failed: `msg'"
            }
            di as error "  Expected at least `expected' observations"
            di as error "  Got: `N'"
            exit 9
        }
    }
    * Check maximum
    else if "`max'" != "" {
        if (`N' > `expected') {
            if "`msg'" != "" {
                di as error "Assertion failed: `msg'"
            }
            di as error "  Expected at most `expected' observations"
            di as error "  Got: `N'"
            exit 9
        }
    }
    * Check exact
    else {
        if (`N' != `expected') {
            if "`msg'" != "" {
                di as error "Assertion failed: `msg'"
            }
            di as error "  Expected exactly `expected' observations"
            di as error "  Got: `N'"
            exit 9
        }
    }
end

capture program drop assert_nobs_min
program define assert_nobs_min
    version 14.0
    syntax anything(name=minobs) [, MSG(string)]
    
    if (_N < `minobs') {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Expected at least `minobs' observations"
        di as error "  Got: " _N
        exit 9
    }
end

capture program drop assert_varexists
program define assert_varexists
    version 14.0
    syntax varlist [, MSG(string)]
    
    foreach v of varlist `varlist' {
        capture confirm variable `v'
        if _rc {
            if "`msg'" != "" {
                di as error "Assertion failed: `msg'"
            }
            di as error "  Variable '`v'' not found"
            exit 9
        }
    }
end

capture program drop assert_vartype
program define assert_vartype
    version 14.0
    syntax varname, TYPE(string) [MSG(string)]
    
    local actual_type : type `varlist'
    
    * Handle type aliases
    local expected = lower("`type'")
    if inlist("`expected'", "string", "str") {
        if substr("`actual_type'", 1, 3) != "str" {
            if "`msg'" != "" {
                di as error "Assertion failed: `msg'"
            }
            di as error "  Variable '`varlist'' expected type: string"
            di as error "  Got: `actual_type'"
            exit 9
        }
    }
    else if inlist("`expected'", "numeric", "num") {
        if inlist(substr("`actual_type'", 1, 3), "str") {
            if "`msg'" != "" {
                di as error "Assertion failed: `msg'"
            }
            di as error "  Variable '`varlist'' expected type: numeric"
            di as error "  Got: `actual_type'"
            exit 9
        }
    }
    else {
        if "`actual_type'" != "`type'" {
            if "`msg'" != "" {
                di as error "Assertion failed: `msg'"
            }
            di as error "  Variable '`varlist'' expected type: `type'"
            di as error "  Got: `actual_type'"
            exit 9
        }
    }
end

capture program drop assert_nomissing
program define assert_nomissing
    version 14.0
    syntax varlist [, MSG(string)]
    
    foreach v of varlist `varlist' {
        quietly count if missing(`v')
        if r(N) > 0 {
            if "`msg'" != "" {
                di as error "Assertion failed: `msg'"
            }
            di as error "  Variable '`v'' has " r(N) " missing values"
            exit 9
        }
    }
end

capture program drop assert_unique
program define assert_unique
    version 14.0
    syntax varlist [, MSG(string)]
    
    tempvar dup
    quietly duplicates tag `varlist', gen(`dup')
    quietly count if `dup' > 0
    
    if r(N) > 0 {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Variables `varlist' not unique"
        di as error "  Found " r(N) " duplicate rows"
        exit 9
    }
end

capture program drop assert_values_in
program define assert_values_in
    version 14.0
    syntax varname, VALUES(string) [MSG(string)]
    
    * Parse allowed values
    local allowed "`values'"
    
    * Check each observation
    tempvar valid
    gen `valid' = 0
    
    foreach val of local allowed {
        replace `valid' = 1 if `varlist' == "`val'"
    }
    
    quietly count if `valid' == 0 & !missing(`varlist')
    if r(N) > 0 {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Variable '`varlist'' contains invalid values"
        di as error "  Allowed: `allowed'"
        quietly levelsof `varlist' if `valid' == 0, local(bad_vals)
        di as error "  Found: `bad_vals'"
        exit 9
    }
end

capture program drop assert_sorted
program define assert_sorted
    version 14.0
    syntax varlist [, MSG(string)]
    
    tempvar sortorder
    gen `sortorder' = _n
    
    sort `varlist'
    
    tempvar newsort
    gen `newsort' = _n
    
    quietly count if `sortorder' != `newsort'
    if r(N) > 0 {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Data not sorted by: `varlist'"
        exit 9
    }
end

* ============================================================================
* DATAFRAME COMPARISON (for cross-platform validation)
* ============================================================================

capture program drop assert_df_equal
program define assert_df_equal
    version 14.0
    syntax using/, [TOLerance(real 1e-6) MSG(string)]
    
    * Compare current dataset with reference file
    preserve
    
    * Load reference
    tempfile current
    quietly save `current'
    
    use `using', clear
    local ref_n = _N
    local ref_vars : r(varlist)
    
    use `current', clear
    
    * Check observation count
    if (_N != `ref_n') {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  Observation count mismatch"
        di as error "  Expected: `ref_n'"
        di as error "  Got: " _N
        restore
        exit 9
    }
    
    * Use cf for detailed comparison
    capture cf _all using `using'
    if _rc {
        if "`msg'" != "" {
            di as error "Assertion failed: `msg'"
        }
        di as error "  DataFrames differ - see cf output above"
        restore
        exit 9
    }
    
    restore
end

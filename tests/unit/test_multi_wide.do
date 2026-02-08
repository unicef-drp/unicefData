* Test multi-indicator wide format fix
* Tests: geo_type presence, no alias_id, variable ordering

clear all
set more off
discard

* Use tempfile for logging to avoid dirtying the repo
tempfile logfile
log using "`logfile'", replace text

di as text "=========================================="
di as text "Testing multi-indicator wide format"
di as text "=========================================="

* Test with 2 indicators
unicefdata, indicator(CME_MRY0T4 CME_MRM0) clear wide

di _n(2) as text "Variable list after wide format:"
ds

di _n(2) as text "First 5 observations:"
list in 1/5, table abbrev(20)

* Check for key variables
di _n(2) as text "Checking key variables:"

* Check geo_type exists
capture confirm variable geo_type
if (_rc == 0) {
    di as result "✓ geo_type exists"
}
else {
    di as error "✗ geo_type MISSING"
    log close
    exit 9
}

* Check alias_id does NOT exist
capture confirm variable alias_id
if (_rc != 0) {
    di as result "✓ alias_id correctly removed"
}
else {
    di as error "✗ alias_id still present (should be removed)"
    log close
    exit 9
}

* Check first variable is NOT a year column
ds
local first_var : word 1 of `r(varlist)'
if (substr("`first_var'", 1, 2) == "yr") {
    di as error "✗ First variable is year column (`first_var') - reordering failed"
    log close
    exit 9
}
else {
    di as result "✓ First variable is context column (`first_var')"
}

* Check iso3 and indicator come before year columns
local yr_found = 0
local context_after_yr = 0
foreach v of varlist _all {
    if (substr("`v'", 1, 2) == "yr") {
        local yr_found = 1
    }
    else if (`yr_found' == 1) {
        * Non-year variable found after year variables
        local context_after_yr = 1
    }
}

if (`context_after_yr' == 0) {
    di as result "✓ All context variables come before year columns"
}
else {
    di as error "✗ Some context variables appear after year columns"
    log close
    exit 9
}

di _n(2) as text "=========================================="
di as text "Test complete"
di as text "=========================================="

log close

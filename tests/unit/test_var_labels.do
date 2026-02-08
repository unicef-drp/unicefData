* Test variable names and labels

clear all
set more off
capture program drop unicefdata

unicefdata, indicator(CME_MRY0T4) countries(BRA) clear wide

di ""
di "=== Variable names and labels ==="
foreach v of varlist * {
    local lab : variable label `v'
    di "`v': `lab'"
}

di ""
di "=== Check for uppercase variable names ==="
local n_upper = 0
foreach v of varlist * {
    if "`v'" != lower("`v'") {
        di as error "UPPERCASE: `v'"
        local n_upper = `n_upper' + 1
    }
}

di ""
di "=== Check for missing labels ==="
local n_nolabel = 0
foreach v of varlist * {
    local lab : variable label `v'
    if "`lab'" == "" {
        di as error "NO LABEL: `v'"
        local n_nolabel = `n_nolabel' + 1
    }
}

* Exit with error if any issues found
if (`n_upper' > 0 | `n_nolabel' > 0) {
    di as error "FAILURE: Found `n_upper' uppercase variables and `n_nolabel' variables without labels"
    exit 9
}
else {
    di as result "SUCCESS: All variables are lowercase and have labels"
}

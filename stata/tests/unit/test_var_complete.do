* Comprehensive test of variable names and labels

clear all
set more off
capture program drop unicefdata

unicefdata, indicator(CME_MRY0T4) countries(BRA) clear wide

di ""
di "=== First 10 variables with labels ==="
local i = 1
foreach v of varlist * {
    if `i' <= 10 {
        local lab : variable label `v'
        di "`v': " as result "`lab'"
    }
    local i = `i' + 1
}

di ""
di "=== Check all variables are lowercase ==="
local n_upper = 0
foreach v of varlist * {
    if "`v'" != lower("`v'") {
        di as error "UPPERCASE: `v'"
        local n_upper = `n_upper' + 1
    }
}
di as result "Uppercase variables found: `n_upper'"

di ""
di "=== Check all variables have labels ==="
local n_nolabel = 0
foreach v of varlist * {
    local lab : variable label `v'
    if "`lab'" == "" {
        di as error "NO LABEL: `v'"
        local n_nolabel = `n_nolabel' + 1
    }
}
di as result "Variables without labels: `n_nolabel'"

di ""
di "=== Summary ==="
if (`n_upper' == 0 & `n_nolabel' == 0) {
    di as result "√ All variables are lowercase and have labels"
}
else {
    di as error "✗ Issues found: `n_upper' uppercase, `n_nolabel' without labels"
    exit 9
}

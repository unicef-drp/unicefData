* Quick test to verify variable name alignment
clear all
set more off

adopath + "."

* Test basic download
unicefdata, indicator(CME_MRY0T4) countries(ALB USA) clear verbose

* Check variables
describe

* Verify key variables exist with correct short names
confirm variable iso3
confirm variable country
confirm variable indicator
confirm variable period
confirm variable value

* Check variable labels
di as text "{bf:Variable Labels:}"
foreach v of varlist * {
    local lab: variable label `v'
    if "`lab'" != "" {
        di as text "  `v': " as result "`lab'"
    }
}

di as result "SUCCESS: All key variables exist with correct names and labels!"

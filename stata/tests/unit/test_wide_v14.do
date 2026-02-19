clear all
set more off
discard
unicefdata, indicator(CME_MRY0T4) clear wide

di ""
di "=== First 2 observations ==="
list in 1/2

di ""
di "=== Year variables (yr*) ==="
capture ds yr*
if _rc == 0 {
    ds yr*
    di ""
    di "SUCCESS: Year columns renamed!"
} 
else {
    di as error "FAILURE: No yr* variables found"
    exit 9
}

di ""
di "=== Total observations ==="
count

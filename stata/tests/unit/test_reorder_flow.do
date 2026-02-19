* Test full flow with v2.2.0 helper and v1.3.3 get_sdmx
* Variables should be reordered: context vars first, then year vars

clear all
set more off
capture program drop _get_sdmx_rename_year_columns
capture program drop get_sdmx
capture program drop unicefdata

di ""
di "=== Testing wide format with automatic reordering ==="

unicefdata, indicator(CME_MRY0T4) countries(BRA) clear wide verbose

di ""
di "=== Variable order after unicefdata (should have context vars first) ==="
des

di ""
di "=== First 15 variables (should be context/dimension vars) ==="
ds
local allvars `r(varlist)'
forvalues i = 1/15 {
    local v : word `i' of `allvars'
    if "`v'" != "" {
        di "`i'. `v'"
    }
}

di ""
di "=== List first row to verify structure ==="
ds yr*
local yrvars `r(varlist)'
list iso3 country indicator sex `yrvars' in 1

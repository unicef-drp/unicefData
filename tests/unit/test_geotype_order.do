* Test geo_type ordering - should appear before yr#### variables

clear all
set more off
capture program drop _get_sdmx_rename_year_columns
capture program drop get_sdmx
capture program drop unicefdata

unicefdata, indicator(CME_MRY0T4) countries(BRA) clear wide

di ""
di "=== Variable order (geo_type should be before yr#### vars) ==="
ds

di ""
di "=== First 10 variables ==="
local allvars `r(varlist)'
forvalues i = 1/10 {
    local v : word `i' of `allvars'
    di "`i'. `v'"
}

di ""
di "=== Find geo_type position ==="
local pos = 0
local i = 1
foreach v of local allvars {
    if "`v'" == "geo_type" {
        local pos = `i'
    }
    local i = `i' + 1
}
di "geo_type is at position: `pos'"

* Assert that geo_type was found
assert `pos' > 0

di ""
di "=== Find first yr#### variable and compare positions ==="
unab yearvars : yr*
local firstyr : word 1 of `yearvars'
di "First year variable: `firstyr'"

local pos_year = 0
local i = 1
foreach v of local allvars {
    if "`v'" == "`firstyr'" {
        local pos_year = `i'
    }
    local i = `i' + 1
}
di "First year variable is at position: `pos_year'"

* Assert that the first yr#### variable exists and comes after geo_type
assert `pos_year' > 0
assert `pos' < `pos_year'

di ""
di "=== Describe key identifier vars and year vars ==="
* Use capture in case no year variables exist (edge case)
capture describe iso3 country indicator sex wealth_quintile data_source unit geo_type yr*
if _rc {
    di as text "Note: Some variables may not exist in this dataset"
    describe iso3 country indicator sex geo_type
}

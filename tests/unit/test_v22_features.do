* Test v2.2.0: Non-year variable tracking and reordering

clear all
set more off
capture program drop _get_sdmx_rename_year_columns
capture program drop get_sdmx
capture program drop unicefdata

di ""
di "=== Test 1: Download data and check return values ==="

unicefdata, indicator(CME_MRY0T4) countries(BRA) clear wide

di ""
di "=== Current variable order (describe) ==="
des, short

di ""
di "=== Test 2: Now test the helper directly with REORDER option ==="

* Save current data
tempfile testdata
save `testdata', replace

* Export to CSV
tempfile csvtemp
local csvfile "`csvtemp'.csv"
export delimited using "`csvfile'", replace

* Clear and reimport
clear
import delimited using "`csvfile'", varnames(1)

di ""
di "=== Before helper (reimported data) ==="
des, short

di ""
di "=== Calling helper with REORDER option ==="
_get_sdmx_rename_year_columns, csvfile("`csvfile'") reorder

di ""
di "=== Return values ==="
return list

* Assert that year_count is positive
assert r(year_count) > 0

di ""
di "=== Non-year variables ==="
di r(non_year_vars)

* Assert that non_year_vars is not empty
assert "`r(non_year_vars)'" != ""

di ""
di "=== Year variables (first 10) ==="
local yearvars = r(year_vars)

* Assert that first year variable starts with "yr"
local firstyr : word 1 of `yearvars'
assert substr("`firstyr'", 1, 2) == "yr"

forvalues i = 1/10 {
    local v : word `i' of `yearvars'
    if "`v'" != "" {
        di "`v'"
    }
}

di ""
di "=== After REORDER (describe) ==="
des, short

* Verify that non-year vars come before year vars in variable order
ds
local allvars `r(varlist)'
local first_var : word 1 of `allvars'
assert substr("`first_var'", 1, 2) != "yr"

di ""
di "=== SUCCESS: v2.2.0 features working ==="

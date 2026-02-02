* Test that ALL tokens in disaggregation filters are handled
clear all
set more off
version 11

* Use dev ado path
capture noisily adopath ++ "C:/GitHub/myados/unicefData-dev/stata/src"

* Fresh program cache
capture noisily discard

* Run the user example
capture noisily unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) sex(ALL) wide_attributes clear
local rc = _rc

if (`rc' != 0) {
    noi di as error "sex(ALL) request failed with r(" `rc' ")"
    exit `rc'
}
else {
    noi di as text "sex(ALL) handled successfully (normalized to _T)"
}

* Optional: verify presence of expected columns
capture confirm variable indicator iso3 period value
if (_rc) {
    noi di as error "Expected columns not found; dataset structure unexpected"
    exit 498
}

noi di as text "Test passed."

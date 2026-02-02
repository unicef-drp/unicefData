* Test wide format with v2.1.0 helper (AUTO detection)
* Tests that csv-ts format correctly uses LABEL source for years

clear all
set more off

* FORCE fresh program cache
discard

* Set adopath to source directory for testing
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src\_"
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src\g"
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src\u"

* Discard again after adopath changes
discard

* Check which version of helper is being found
which _get_sdmx_rename_year_columns

di ""
di "=== Testing wide format with v2.1.0 AUTO detection ==="
di ""

* Run the wide format request
unicefdata, indicator(CME_MRM0) clear wide verbose

* Check results
di ""
di "=== Checking variable names ==="
describe

* Verify year columns exist
capture confirm variable yr2020
if _rc == 0 {
    di as result "✓ SUCCESS: yr2020 exists - LABEL detection worked!"
}
else {
    di as error "✗ FAILED: yr2020 not found - still using old logic"
    describe, short
}

* Check for old-style v## columns
capture confirm variable v20
if _rc == 0 {
    di as error "✗ FAILED: v20 still exists - rename failed"
}
else {
    di as result "✓ SUCCESS: No v## columns found"
}

* List one observation to verify
list in 1, abbreviate(12)

di ""
di "Test complete."

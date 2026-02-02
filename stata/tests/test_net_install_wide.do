* Test that net install installs the correct v2.1.0 helper
* This verifies the package distribution is correct

clear all
set more off
discard

* Remove source directories from adopath to test net install only
capture adopath - "C:\GitHub\myados\unicefData-dev\stata\src"
capture adopath - "C:\GitHub\myados\unicefData-dev\stata\src\_"
capture adopath - "C:\GitHub\myados\unicefData-dev\stata\src\g"
capture adopath - "C:\GitHub\myados\unicefData-dev\stata\src\u"

* Force reinstall from package
net install unicefdata, from("C:\GitHub\myados\unicefData-dev\stata") replace force
discard

* Show which version is loaded
di ""
di "=== Checking installed helper version ==="
which _get_sdmx_rename_year_columns

di ""
di "=== Testing wide format ==="
unicefdata, indicator(CME_MRM0) clear wide 

* Check results
describe

* Verify year columns exist
capture confirm variable yr2020
if _rc == 0 {
    di ""
    di as result "✓ SUCCESS: yr2020 exists - v2.1.0 AUTO detection working!"
}
else {
    di ""
    di as error "✗ FAILED: yr2020 not found - wrong version installed"
    capture confirm variable v20
    if _rc == 0 {
        di as error "  Found v## columns - old version behavior"
    }
}

di ""
di "Test complete."

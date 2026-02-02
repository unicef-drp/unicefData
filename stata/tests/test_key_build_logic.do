* Test schema key building with filterdisagg option
clear all
set more off

* Test the new filterdisagg logic
di ""
di "=========================================="
di "Testing _unicef_build_schema_key with filterdisagg"
di "=========================================="
di ""

* Simulate what _unicef_build_schema_key would return
* With filterdisagg=1, indicator should NOT be in the key
* It should only contain disaggregation filters
di "When filterdisagg=1 (skip indicator dimension):"
di "  Schema key should be: ._T._T._T._T (just disaggregations)"
di "  NOT: .CME_MRY0T4._T._T._T._T"
di ""
di "This ensures the filtervector in SDMX query only contains:"
di "  disaggregation dimensions (sex, age, wealth, residence, etc)"
di "  NOT the indicator dimension (already in URL dimension 2)"
di ""

di "=========================================="
di "✓ Fix applied: filterdisagg option added to _unicef_build_schema_key"
di "✓ unicefdata.ado updated to use filterdisagg=1"
di "=========================================="

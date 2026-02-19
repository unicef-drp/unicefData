*! Test tier field extraction from YAML parser
*! Version 1.0.0  17Jan2026

clear all
set more off

* Define master YAML file location
local yamlfile "C:\Users\jpazevedo\ado\plus\_\_unicefdata_indicators_metadata.yaml"

noi di _n(2) "{hline 80}"
noi di "TIER EXTRACTION TEST - Testing __unicef_parse_indicator_yaml.ado"
noi di "{hline 80}"

* Test 1: TIER 1 indicator (should have data)
noi di _n "TEST 1: TIER 1 Indicator (NT_ANT_HAZ_NE2)"
noi di "{hline 80}"
__unicef_parse_indicator_yaml, yamlfile("`yamlfile'") indicator(NT_ANT_HAZ_NE2)
noi di "  Code: " r(ind_name)
noi di "  Category: " r(ind_category)
noi di "  Dataflow: " r(ind_dataflow)
noi di "  TIER: " r(tier)
noi di "  TIER Reason: " r(tier_reason)
noi di "  TIER Subcategory: " r(tier_subcategory)
noi di "  Found: " r(found)

* Validation
assert r(tier) == "1"
assert r(tier_reason) == "verified_and_downloadable"
noi di _n "[OK] TIER 1 extraction successful"

* Test 2: TIER 2 indicator (orphan, no data)
noi di _n(2) "TEST 2: TIER 2 Indicator (ED_LN_R_L1)"
noi di "{hline 80}"
__unicef_parse_indicator_yaml, yamlfile("`yamlfile'") indicator(ED_LN_R_L1)
noi di "  Code: " r(ind_name)
noi di "  Category: " r(ind_category)
noi di "  Dataflow: " r(ind_dataflow)
noi di "  TIER: " r(tier)
noi di "  TIER Reason: " r(tier_reason)
noi di "  TIER Subcategory: " r(tier_subcategory)
noi di "  Found: " r(found)

* Validation
assert r(tier) == "2"
assert r(tier_reason) == "officially_defined_no_data"
assert r(tier_subcategory) == "2A_future_planned"
noi di _n "[OK] TIER 2 extraction successful"

* Test 3: TIER 3 indicator (legacy, undocumented)
noi di _n(2) "TEST 3: TIER 3 Indicator (C010101)"
noi di "{hline 80}"
__unicef_parse_indicator_yaml, yamlfile("`yamlfile'") indicator(C010101)
noi di "  Code: " r(ind_name)
noi di "  Category: " r(ind_category)
noi di "  Dataflow: " r(ind_dataflow)
noi di "  TIER: " r(tier)
noi di "  TIER Reason: " r(tier_reason)
noi di "  TIER Subcategory: " r(tier_subcategory)
noi di "  Found: " r(found)

* Validation
assert r(tier) == "3"
assert r(tier_reason) == "legacy_undocumented"
assert r(tier_subcategory) == "3A_deprecated_numeric"
noi di _n "[OK] TIER 3 extraction successful"

noi di _n(2) "{hline 80}"
noi di "ALL TESTS PASSED - Tier extraction working correctly"
noi di "{hline 80}" _n

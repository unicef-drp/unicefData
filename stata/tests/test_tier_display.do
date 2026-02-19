*! Test tier display in _unicef_indicator_info
*! Version 1.0.0  17Jan2026

clear all
set more off

noi di _n(2) "{hline 80}"
noi di "TIER DISPLAY TEST - Testing _unicef_indicator_info with tier warnings"
noi di "{hline 80}"

* Test 1: TIER 1 indicator (no warning)
noi di _n(2) "{bf:TEST 1: TIER 1 Indicator (NT_ANT_HAZ_NE2)}"
noi di "{hline 80}"
_unicef_indicator_info, indicator(NT_ANT_HAZ_NE2)
assert r(tier) == "1"
noi di _n "[OK] TIER 1 displayed correctly (no warning)"

* Test 2: TIER 2 indicator (should show warning)
noi di _n(2) "{bf:TEST 2: TIER 2 Indicator (ED_LN_R_L1)}"
noi di "{hline 80}"
_unicef_indicator_info, indicator(ED_LN_R_L1)
assert r(tier) == "2"
assert r(tier_subcategory) == "2A_future_planned"
noi di _n "[OK] TIER 2 warning displayed correctly"

* Test 3: TIER 3 indicator (should show warning)
noi di _n(2) "{bf:TEST 3: TIER 3 Indicator (C010101)}"
noi di "{hline 80}"
_unicef_indicator_info, indicator(C010101)
assert r(tier) == "3"
assert r(tier_subcategory) == "3A_deprecated_numeric"
noi di _n "[OK] TIER 3 warning displayed correctly"

noi di _n(2) "{hline 80}"
noi di "ALL TESTS PASSED - Tier display and warnings working correctly"
noi di "{hline 80}" _n

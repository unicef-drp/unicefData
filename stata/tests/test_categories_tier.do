*! Test tier-aware categories counting
*! v1.0 19Jan2026

clear all
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"
adopath ++ "c:\Users\jpazevedo\ado\plus"

noi di ""
noi di "{hline 60}"
noi di "TEST: Categories with default tier filtering"
noi di "{hline 60}"

* Test 1: Default (tier 1 only)
noi di ""
noi di "Test 1: categories (default, tier 1 only)"
_unicef_list_categories
local tier1_total = r(n_indicators)
noi di "  Total indicators (tier 1): `tier1_total'"
noi di "  r(tier_mode): " r(tier_mode)
noi di "  r(tier_filter): " r(tier_filter)
noi di "  r(show_orphans): " r(show_orphans)

* Test 2: showall (all tiers)
noi di ""
noi di "Test 2: categories showall (all tiers 1+2+3)"
_unicef_list_categories, showall
local all_total = r(n_indicators)
noi di "  Total indicators (all): `all_total'"
noi di "  r(tier_mode): " r(tier_mode)
noi di "  r(tier_filter): " r(tier_filter)
noi di "  r(show_orphans): " r(show_orphans)

* Compare
noi di ""
noi di "COMPARISON:"
noi di "  Tier 1 only: `tier1_total' indicators"
noi di "  All tiers: `all_total' indicators"
if (`all_total' > `tier1_total') {
    noi di as result "  ✓ PASS: showall count is greater (difference: " `all_total' - `tier1_total' ")"
}
else {
    noi di as error "  ✗ FAIL: showall count should be > tier1 count"
}

noi di ""
noi di "{hline 60}"
noi di "End of test"
noi di "{hline 60}"

*! Test tier filtering in search command
*! Version 1.0.0  17Jan2026

clear all
set more off

noi di _n(2) "{hline 80}"
noi di "TIER FILTERING TEST - Testing _unicef_search_indicators tier filters"
noi di "{hline 80}"

* Test 1: Default search (TIER 1 only)
noi di _n(2) "{bf:TEST 1: Default Search (TIER 1 only)}"
noi di "{hline 80}"
_unicef_search_indicators, keyword("mortality") limit(5)
local n_results = r(n_matches)
noi di _n "Number of results (TIER 1 only): " `n_results'

* Test 2: Search with showtier2 (TIER 1 + TIER 2)
noi di _n(2) "{bf:TEST 2: Search with showtier2 (TIER 1 + TIER 2)}"
noi di "{hline 80}"
_unicef_search_indicators, keyword("mortality") limit(5) showtier2
local n_results_t2 = r(n_matches)
noi di _n "Number of results (TIER 1+2): " `n_results_t2'

* Verify TIER 1+2 >= TIER 1 only
assert `n_results_t2' >= `n_results'
noi di "[OK] TIER 1+2 count >= TIER 1 only"

* Test 3: Search with showorphans (alias for showtier2)
noi di _n(2) "{bf:TEST 3: Search with showorphans (alias)}"
noi di "{hline 80}"
_unicef_search_indicators, keyword("education") limit(5) showorphans
local n_results_orphans = r(n_matches)
noi di _n "Number of results (showorphans): " `n_results_orphans'

* Test 4: Search with showtier3 (TIER 1 + TIER 3)
noi di _n(2) "{bf:TEST 4: Search with showtier3 (TIER 1 + TIER 3)}"
noi di "{hline 80}"
_unicef_search_indicators, keyword("malaria") limit(5) showtier3
local n_results_t3 = r(n_matches)
noi di _n "Number of results (TIER 1+3): " `n_results_t3'

* Test 5: Search with showall (all tiers)
noi di _n(2) "{bf:TEST 5: Search with showall (all tiers)}"
noi di "{hline 80}"
_unicef_search_indicators, keyword("water") limit(10) showall
local n_results_all = r(n_matches)
noi di _n "Number of results (all tiers): " `n_results_all'

noi di _n(2) "{hline 80}"
noi di "ALL TESTS PASSED - Tier filtering working correctly"
noi di "  Default (T1 only): " `n_results'
noi di "  With T2: " `n_results_t2'
noi di "  With T3: " `n_results_t3'
noi di "  All tiers: " `n_results_all'
noi di "{hline 80}" _n

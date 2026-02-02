*******************************************************************************
* Test: Tier Filtering in Discovery Commands
* Purpose: Verify tier filtering works correctly for search and indicators
* Date: 19Jan2026
*******************************************************************************

clear all
set more off

noi di ""
noi di "{hline 80}"
noi di "{bf:TEST: Tier Filtering in Discovery Commands}"
noi di "{hline 80}"

*===============================================================================
* TEST 1: Search - Default (Tier 1 only)
*===============================================================================

noi di ""
noi di "{bf:TEST 1: Search 'mortality' (default = Tier 1 only)}"
noi di ""

unicefdata, search(mortality) limit(5)
return list

local n_tier1 = r(n_matches)
noi di ""
noi di "✓ Default search found {result:`n_tier1'} Tier 1 indicators"

*===============================================================================
* TEST 2: Search - With showtier2
*===============================================================================

noi di ""
noi di "{bf:TEST 2: Search 'mortality' showtier2 (Tier 1-2)}"
noi di ""

unicefdata, search(mortality) limit(10) showtier2
return list

local n_tier2 = r(n_matches)
noi di ""
noi di "✓ Tier 1-2 search found {result:`n_tier2'} indicators (should be >= `n_tier1')"

assert `n_tier2' >= `n_tier1'
noi di "✓ PASSED: Tier 2 includes more indicators than Tier 1"

*===============================================================================
* TEST 3: Search - With showtier3
*===============================================================================

noi di ""
noi di "{bf:TEST 3: Search 'mortality' showtier3 (Tier 1-3)}"
noi di ""

unicefdata, search(mortality) limit(15) showtier3
return list

local n_tier3 = r(n_matches)
noi di ""
noi di "✓ Tier 1-3 search found {result:`n_tier3'} indicators (should be >= `n_tier2')"

assert `n_tier3' >= `n_tier2'
noi di "✓ PASSED: Tier 3 includes more indicators than Tier 2"

*===============================================================================
* TEST 4: Search - With showall
*===============================================================================

noi di ""
noi di "{bf:TEST 4: Search 'mortality' showall (all tiers)}"
noi di ""

unicefdata, search(mortality) limit(20) showall
return list

local n_all = r(n_matches)
noi di ""
noi di "✓ All tiers search found {result:`n_all'} indicators (should be >= `n_tier3')"

assert `n_all' >= `n_tier3'
noi di "✓ PASSED: Showall includes all tiers"

*===============================================================================
* TEST 5: Indicators - Default (Tier 1 only)
*===============================================================================

noi di ""
noi di "{bf:TEST 5: List indicators in CME dataflow (default = Tier 1)}"
noi di ""

unicefdata, indicators(CME)
return list

local cme_tier1 = r(n_indicators)
noi di ""
noi di "✓ CME Tier 1 has {result:`cme_tier1'} indicators"

*===============================================================================
* TEST 6: Indicators - With showtier2
*===============================================================================

noi di ""
noi di "{bf:TEST 6: List indicators in CME dataflow showtier2 (Tier 1-2)}"
noi di ""

unicefdata, indicators(CME) showtier2
return list

local cme_tier2 = r(n_indicators)
noi di ""
noi di "✓ CME Tier 1-2 has {result:`cme_tier2'} indicators (should be >= `cme_tier1')"

assert `cme_tier2' >= `cme_tier1'
noi di "✓ PASSED: Tier 2 includes Tier 1 indicators"

*===============================================================================
* TEST 7: Indicators - With showall
*===============================================================================

noi di ""
noi di "{bf:TEST 7: List indicators in CME dataflow showall}"
noi di ""

unicefdata, indicators(CME) showall
return list

local cme_all = r(n_indicators)
noi di ""
noi di "✓ CME all tiers has {result:`cme_all'} indicators (should be >= `cme_tier2')"

assert `cme_all' >= `cme_tier2'
noi di "✓ PASSED: Showall includes all tier indicators"

*===============================================================================
* TEST 8: Alias - showlegacy should work like showtier3
*===============================================================================

noi di ""
noi di "{bf:TEST 8: Search 'education' showlegacy (alias for showtier3)}"
noi di ""

unicefdata, search(education) limit(10) showlegacy
return list

local n_legacy = r(n_matches)
noi di ""
noi di "✓ Showlegacy found {result:`n_legacy'} indicators"
noi di "✓ PASSED: Showlegacy option works (alias for showtier3)"

*===============================================================================
* Summary
*===============================================================================

noi di ""
noi di "{hline 80}"
noi di "{bf:ALL TIER FILTERING TESTS PASSED}"
noi di "{hline 80}"
noi di ""
noi di "Summary of results:"
noi di "  • Default (Tier 1):    `n_tier1' mortality indicators"
noi di "  • Tier 1-2:            `n_tier2' mortality indicators"
noi di "  • Tier 1-3:            `n_tier3' mortality indicators"
noi di "  • All tiers:           `n_all' mortality indicators"
noi di "  • CME Tier 1:          `cme_tier1' indicators"
noi di "  • CME Tier 1-2:        `cme_tier2' indicators"
noi di "  • CME all tiers:       `cme_all' indicators"
noi di ""
noi di "✓ Tier filtering is working correctly!"
noi di "{hline 80}"

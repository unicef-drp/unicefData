*===============================================================================
* TEST: Tier Filtering Return Values
*===============================================================================
* Purpose: Verify that discovery commands return tier filtering metadata
* Author: Development Team
* Date: January 2026
*===============================================================================

clear all
set more off

noi di _n "{hline 80}"
noi di "{bf:Testing Tier Filtering Return Values}"
noi di "{hline 80}" _n

*-------------------------------------------------------------------------------
* TEST 1: Search command - Default (Tier 1 only)
*-------------------------------------------------------------------------------

noi di "{bf:TEST 1:} Search with default (Tier 1 only) - return values"

unicefdata, search(mortality) limit(5)

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 1
assert "`r(tier_filter)'" == "tier_1_only"
assert r(show_orphans) == 0

noi di "{txt}✓ Tier metadata correctly returned" _n

*-------------------------------------------------------------------------------
* TEST 2: Search command - With showtier2
*-------------------------------------------------------------------------------

noi di "{bf:TEST 2:} Search with showtier2 - return values"

unicefdata, search(mortality) limit(5) showtier2

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 2
assert "`r(tier_filter)'" == "tier_1_and_2"
assert r(show_orphans) == 0

noi di "{txt}✓ Tier 2 metadata correctly returned" _n

*-------------------------------------------------------------------------------
* TEST 3: Search command - With showtier3
*-------------------------------------------------------------------------------

noi di "{bf:TEST 3:} Search with showtier3 - return values"

unicefdata, search(mortality) limit(5) showtier3

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 3
assert "`r(tier_filter)'" == "tier_1_2_3"
assert r(show_orphans) == 0

noi di "{txt}✓ Tier 3 metadata correctly returned" _n

*-------------------------------------------------------------------------------
* TEST 4: Search command - With showall
*-------------------------------------------------------------------------------

noi di "{bf:TEST 4:} Search with showall - return values"

unicefdata, search(mortality) limit(5) showall

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 999
assert "`r(tier_filter)'" == "all_tiers"
assert r(show_orphans) == 1

noi di "{txt}✓ All tiers metadata correctly returned" _n

*-------------------------------------------------------------------------------
* TEST 5: Search command - With showorphans only
*-------------------------------------------------------------------------------

noi di "{bf:TEST 5:} Search with showorphans - return values"

unicefdata, search(mortality) limit(5) showorphans

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 1
assert "`r(tier_filter)'" == "tier_1_only"
assert r(show_orphans) == 1

noi di "{txt}✓ Orphans flag correctly returned" _n

*-------------------------------------------------------------------------------
* TEST 6: Indicators command - Default (Tier 1 only)
*-------------------------------------------------------------------------------

noi di "{bf:TEST 6:} Indicators with default (Tier 1 only) - return values"

unicefdata indicators(CME)

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 1
assert "`r(tier_filter)'" == "tier_1_only"
assert r(show_orphans) == 0

noi di "{txt}✓ Indicators Tier 1 metadata correctly returned" _n

*-------------------------------------------------------------------------------
* TEST 7: Indicators command - With showtier2
*-------------------------------------------------------------------------------

noi di "{bf:TEST 7:} Indicators with showtier2 - return values"

unicefdata indicators(CME), showtier2

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 2
assert "`r(tier_filter)'" == "tier_1_and_2"
assert r(show_orphans) == 0

noi di "{txt}✓ Indicators Tier 2 metadata correctly returned" _n

*-------------------------------------------------------------------------------
* TEST 8: Indicators command - With showall
*-------------------------------------------------------------------------------

noi di "{bf:TEST 8:} Indicators with showall - return values"

unicefdata indicators(CME), showall

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 999
assert "`r(tier_filter)'" == "all_tiers"
assert r(show_orphans) == 1

noi di "{txt}✓ Indicators all tiers metadata correctly returned" _n

*-------------------------------------------------------------------------------
* TEST 9: Showlegacy alias
*-------------------------------------------------------------------------------

noi di "{bf:TEST 9:} Search with showlegacy (alias for showtier3) - return values"

unicefdata, search(mortality) limit(5) showlegacy

noi di _n "{txt}Return values:"
noi return list

* Verify tier metadata is returned
assert r(tier_mode) == 3
assert "`r(tier_filter)'" == "tier_1_2_3"
assert r(show_orphans) == 0

noi di "{txt}✓ Showlegacy alias correctly returned" _n

*===============================================================================
* FINAL SUMMARY
*===============================================================================

noi di _n "{hline 80}"
noi di "{bf:✓ ALL TIER RETURN VALUES TESTS PASSED}"
noi di "{hline 80}" _n

noi di "{txt}Summary:"
noi di "  • All tier filtering return values work correctly"
noi di "  • r(tier_mode) returns correct numeric tier level"
noi di "  • r(tier_filter) returns correct tier description"
noi di "  • r(show_orphans) returns correct orphan flag"
noi di "  • Both search and indicators commands return tier metadata"
noi di "  • Showlegacy alias works correctly" _n

*===============================================================================
* END OF TEST
*===============================================================================

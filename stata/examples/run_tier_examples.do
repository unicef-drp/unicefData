*! version 1.8.0  17Jan2026
* Title: Tiered discovery examples for unicefdata
* Author: João Pedro Azevedo (World Bank | UNICEF)
* Contact: https://jpazvd.github.io
* License: MIT

capture log close _all
log using "../../output/logs/run_tier_examples.log", replace text

set more off
set linesize 80

* Ensure fresh program state
quietly discard

* Example 1: Default search (Tier 1 only)
noi di "Example 1: Default Tier 1 search"
unicefdata, search(stunting) limit(10)

* Example 2: Include Tier 2
noi di "Example 2: Include Tier 2 (officially defined, no data)"
unicefdata, search(stunting) limit(10) showtier2

* Example 3: Include Tier 3 (legacy/undocumented)
noi di "Example 3: Include Tier 3 (legacy)"
unicefdata, search(stunting) limit(10) showtier3

* Example 4: Include all tiers (1–3)
noi di "Example 4: Include all tiers"
unicefdata, search(stunting) limit(20) showall

* Example 5: Show orphan indicators (taxonomy maintenance)
noi di "Example 5: Show orphan indicators"
unicefdata, search(child) limit(20) showorphans

log close

* Optional: save a brief marker of successful run
file open fh using "../../output/logs/run_tier_examples.done", write replace
file write fh "OK" _n
file close fh

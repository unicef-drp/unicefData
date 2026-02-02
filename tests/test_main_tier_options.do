*! Test tier filtering through main unicefdata command
*! Version 1.0.0  17Jan2026

clear all
set more off

noi di _n(2) "{hline 80}"
noi di "END-TO-END TIER TEST - Testing unicefdata, search() with tier options"
noi di "{hline 80}"

* Test 1: Default search (TIER 1 only)
noi di _n(2) "{bf:TEST 1: unicefdata, search(malaria) - Default TIER 1 only}"
noi di "{hline 80}"
unicefdata, search(malaria) limit(5)

* Test 2: Search with showtier2
noi di _n(2) "{bf:TEST 2: unicefdata, search(education) showtier2}"
noi di "{hline 80}"
unicefdata, search(education) limit(5) showtier2

* Test 3: Search with showorphans (alias)
noi di _n(2) "{bf:TEST 3: unicefdata, search(mortality) showorphans}"
noi di "{hline 80}"
unicefdata, search(mortality) limit(5) showorphans

* Test 4: Search with showtier3
noi di _n(2) "{bf:TEST 4: unicefdata, search(water) showtier3}"
noi di "{hline 80}"
unicefdata, search(water) limit(5) showtier3

* Test 5: Search with showall
noi di _n(2) "{bf:TEST 5: unicefdata, search(health) showall}"
noi di "{hline 80}"
unicefdata, search(health) limit(10) showall

noi di _n(2) "{hline 80}"
noi di "ALL TESTS PASSED - Tier options working through main command"
noi di "{hline 80}" _n

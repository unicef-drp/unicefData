# Regression Test Baselines (REGR-01)

## Purpose

Baseline snapshots for detecting silent regressions in UNICEF API responses.

## Files

| File | Indicator | Countries | Year | Last Updated | Status |
|------|-----------|-----------|------|--------------|--------|
| `snap_mortality_baseline.csv` | CME_MRY0T4 | USA, BRA | 2020 | 2026-01-19 | Initial baseline |
| `snap_vaccination_baseline.csv` | IM_DTP3 | IND, ETH | 2020 | 2026-01-19 | Initial baseline |
| `snap_multi_baseline.csv` | CME_MRY0T4, IM_DTP3 | USA | 2020 | 2026-01-19 | Initial baseline |

## When to Update

**DO UPDATE** when:
- UNICEF announces official data revisions
- API schema changes require package updates
- Indicators are deprecated and replaced

**DO NOT UPDATE** when:
- Random test failures (investigate regression instead)
- Temporary API downtime  
- Personal preference for different test data

## How to Update

```bash
cd C:\GitHub\myados\unicefData-dev\stata\qa
stata /e do fixtures/regenerate_baselines.do

# Review changes
git diff fixtures/

# If changes are intentional, commit with reason
git add fixtures/*.csv
git commit -m "chore: update REGR-01 baselines (reason: API revision 2026-01)"
```

## Baseline Values (for reference)

### Mortality (CME_MRY0T4) - Under-5 mortality rate
- **USA 2020:** 6.97 Deaths per 1000 live births
- **BRA 2020:** 14.63 Deaths per 1000 live births

*Source: UNICEF Child Mortality Estimates (CME)*

### Vaccination (IM_DTP3) - DTP3 immunization coverage
- **IND 2020:** 91.00% 
- **ETH 2020:** 87.00%

*Source: UNICEF Immunization Coverage Estimates*

### Multi-indicator (USA 2020)
- **CME_MRY0T4:** 6.97 Deaths per 1000 live births
- **IM_DTP3:** 96.00%

*Tests the `wide_indicators` option for reshaping multiple indicators*

## Notes

### Why These Indicators?

**CME_MRY0T4 (Under-5 Mortality Rate)**
- Referenced in 5+ other tests (MULTI-01, PERF-01)
- Stable historical data (2020 is finalized, not provisional)
- High-value indicator for UNICEF mission

**IM_DTP3 (DTP3 Vaccination Coverage)**
- Used in MULTI-01 for wide_indicators testing
- Well-established immunization indicator
- Complements mortality indicator

### Why Year 2020?

- Recent enough to be relevant
- Old enough to be stable (no longer provisional)
- Pre-COVID disruptions stabilized by 2020

### Why These Countries?

- **USA:** Major developed country, stable reporting
- **BRA:** Major developing country, Latin America representation
- **IND:** Largest developing country population
- **ETH:** Sub-Saharan Africa representation

These countries are unlikely to be removed from UNICEF databases.

## Tolerance

Regression test allows **±0.01 tolerance** for floating-point comparison:
- Strict enough to catch real data changes
- Loose enough to handle rounding differences

## Maintenance

- **Weekly:** Automated CI runs REGR-01 (detects unintended changes)
- **Before releases:** Manual review of REGR-01 status
- **Annually:** Review if baselines need refresh (check UNICEF changelog)

## Troubleshooting

### Test Fails After Baseline Update

**Symptom:** REGR-01 fails immediately after updating baselines

**Causes:**
1. Baseline CSV format error (check column names match)
2. Missing/extra rows in baseline
3. Decimal precision mismatch

**Fix:**
```stata
* Compare current download vs baseline manually
unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) clear
list indicator iso3 year value unit

* Check baseline file
import delimited "qa/fixtures/snap_mortality_baseline.csv", clear
list
```

### API Returns Different Values

**Symptom:** REGR-01 reports "X rows differ"

**Investigation:**
1. Check if UNICEF announced data revision
   - https://data.unicef.org/resources/data-releases/
2. Compare actual vs baseline values
   - Small difference (<1%): likely rounding/precision
   - Large difference (>10%): likely data revision
3. Verify with secondary source (WHO, World Bank)

**Resolution:**
- If revision confirmed: Update baselines via `regenerate_baselines.do`
- If bug suspected: Debug API response, check transformations
- If transient: Retry test

## Version History

| Date | Version | Changes | Reason |
|------|---------|---------|--------|
| 2026-01-19 | 1.0 | Initial baselines created | REGR-01 implementation |

---

**Maintainer:** João Pedro Azevedo  
**Last Review:** 19 Jan 2026

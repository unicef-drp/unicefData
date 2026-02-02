# unicefData Quality Assurance (QA) Test Suite

**Status:** ✅ **100% Coverage - All 38 Tests Passing**
**Last Updated:** February 1, 2026
**Branch:** develop
**Version:** 2.0.4

---

## Quick Reference

| Metric | Value |
|--------|-------|
| **Tests** | 38/38 passing |
| **Coverage** | 100% |
| **Duration** | ~10 minutes |
| **Test Families** | 9 (ENV, DL, DIS, FILT, META, EDGE, REGR, SYNC, XPLAT) |
| **Regression Baselines** | 2 (mortality, vaccination) |
| **Stata Version** | 14+ (tested on Stata 17 MP) |

---

## Running Tests

### Full Test Suite
```stata
cd C:\GitHub\myados\unicefData-dev\stata\qa
do run_tests.do
```

### Test Output
- **Console:** Real-time pass/fail status
- **Log file:** `run_tests.log` (detailed execution trace)
- **History:** `test_history.txt` (cumulative test run summary)

---

## Test Family Architecture

The QA suite follows a **progressive validation strategy**, building from simple to complex:

```
ENV (Foundation)    → Verify basic environment
   ↓
DL (Core)          → Test basic data retrieval  
   ↓
DIS (Demographics) → Validate subpopulation filtering
   ↓
FILT (Subsetting)  → Test data limiting/targeting
   ↓
META (Discovery)   → Validate search and metadata
   ↓
EDGE (Resilience)  → Handle edge cases
   ↓
REGR (Stability)   → Monitor API consistency
```

### Why 7 Families?

Each family addresses a distinct **failure mode**:

| Family | Failure Mode | Example Impact |
|--------|--------------|----------------|
| **ENV** | Installation/setup issues | User can't run command |
| **DL** | API connectivity/parsing | Primary use case broken |
| **DIS** | Disaggregation logic errors | Wrong population subsets |
| **FILT** | Filter implementation bugs | Too much/too little data |
| **META** | Metadata cache corruption | Can't discover indicators |
| **EDGE** | Unhandled edge cases | Crashes on unusual inputs |
| **REGR** | Silent API data changes | Analyses use stale values |

---

## Test Categories (30 Tests)

### 1. 🔧 Environment Tests (ENV-01 to ENV-03)
**Purpose:** Verify testing environment is properly configured

| Test | Validates |
|------|-----------|
| **ENV-01** | `unicefdata` command is installed and callable |
| **ENV-02** | Help documentation is available via `help unicefdata` |
| **ENV-03** | Package version matches expected format (X.Y.Z) |

**Why These Matter:** Ensures test failures are due to code issues, not setup problems.

---

### 2. 📥 Download Tests (DL-01 to DL-10)
**Purpose:** Validate core data retrieval from UNICEF SDMX API

| Test | Validates |
|------|-----------|
| **DL-01** | Basic indicator download (CME_MRY0T4) |
| **DL-02** | `countries()` option filters properly |
| **DL-03** | `year()` option restricts periods |
| **DL-04** | Response contains expected variables (iso3, period, value, unit) |
| **DL-05** | Multi-indicator download works |
| **DL-06** | Wide format reshaping (wide_indicators) |
| **DL-07** | `latest` option returns most recent value |
| **DL-08** | Results contain expected observation counts |
| **DL-09** | `clear` option replaces data in memory |
| **DL-10** | Invalid inputs produce appropriate errors |

**Why These Matter:** Ensures primary use case (fetching data) works across parameter combinations.

---

### 3. 🔍 Disaggregation Tests (DIS-01 to DIS-09)
**Purpose:** Verify filtering by demographic and socioeconomic dimensions

| Test | Validates |
|------|-----------|
| **DIS-01** | Sex filter (_T, M, F) |
| **DIS-02** | Wealth quintile filter (Q1-Q5, _T) |
| **DIS-03** | Residence filter (U, R, _T) |
| **DIS-04** | Age group filter (e.g., Y0T4, Y5T9) |
| **DIS-05** | Maternal education filter (ISCED levels) |
| **DIS-06** | Combined disaggregations (sex + wealth) |
| **DIS-07** | Default behavior returns totals only |
| **DIS-08** | Response includes disaggregation variables |
| **DIS-09** | Warning displayed when filters applied |

**Why These Matter:** Critical for equity analysis and targeting interventions by subpopulations.

---

### 4. 🎯 Filter Tests (FILT-01 to FILT-04)
**Purpose:** Validate data subsetting and limiting options

| Test | Validates |
|------|-----------|
| **FILT-01** | `maxobs()` option limits result size |
| **FILT-02** | Year range filtering (e.g., 2015:2023) |
| **FILT-03** | Multiple countries specification |
| **FILT-04** | Combined filters (year + country + disagg) |

**Why These Matter:** Ensures users can retrieve targeted subsets efficiently.

---

### 5. 📊 Metadata Tests (META-01 to META-02)
**Purpose:** Validate metadata retrieval and documentation queries

| Test | Validates |
|------|-----------|
| **META-01** | Metadata-only queries (info, search, categories) |
| **META-02** | Local YAML metadata cache files are valid |

**Why These Matter:** Ensures discovery features work for finding indicators.

---

### 6. ⚠️ Edge Case Tests (EDGE-01 to EDGE-02)
**Purpose:** Validate handling of unusual or problematic scenarios

| Test | Validates |
|------|-----------|
| **EDGE-01** | Graceful handling of queries with no data |
| **EDGE-02** | Network timeout resilience without crashes |

**Why These Matter:** Ensures graceful degradation under adverse conditions.

---

### 7. 🔄 Regression Tests (REGR-01)
**Purpose:** Detect silent regressions in UNICEF API responses

| Test | Validates |
|------|-----------|
| **REGR-01** | Current API data matches historical baselines (±0.01 tolerance) |

**Baselines Tested:**

1. **Mortality Snapshot** (`fixtures/snap_mortality_baseline.csv`)
   - Indicator: CME_MRY0T4 (Under-5 mortality rate)
   - Countries: USA, BRA
   - Year: 2020
   - Values: USA: 6.4687848, BRA: 14.871896 deaths per 1000 live births

2. **Vaccination Snapshot** (`fixtures/snap_vaccination_baseline.csv`)
   - Indicator: IM_DTP3 (DTP3 vaccination coverage)
   - Countries: IND, ETH
   - Year: 2020
   - Values: IND: 85%, ETH: 62%

**Why This Matters:** Provides early warning when UNICEF updates data or changes API behavior.

**Known Limitation:** Multi-indicator wide format not supported (different dataflows can't be combined with `wide_indicators`).

---

## Baseline Maintenance

### When to Update Baselines

- ✅ After UNICEF announces official data revisions
- ✅ After coordinated API schema changes
- ❌ NEVER automatically - baselines are stable reference points

### How to Regenerate Baselines

```stata
cd C:\GitHub\myados\unicefData-dev\stata\qa
do fixtures/regenerate_baselines.do
```

### Verification Workflow

1. Review differences: `git diff qa/fixtures/`
2. Confirm changes are expected (UNICEF API update)
3. Document reason in commit message
4. Commit updated baselines

**Design Documentation:** See `internal/qa-design/REGR-01_PROPOSAL.md` for implementation details.

---

## Coverage Matrix

| User Workflow | Tests Validating It | Families |
|---------------|---------------------|----------|
| "Find mortality indicators" | META-01, DIS-01 | META, DIS |
| "Get under-5 mortality for Brazil" | DL-01, DL-02, DL-03 | DL |
| "Show urban vs rural stunting" | DIS-03, DIS-06 | DIS |
| "Give me latest vaccination data" | DL-07 | DL |
| "What if API changes silently?" | REGR-01 | REGR |

---

## Test Maintenance

### Adding New Tests

1. Choose appropriate category (ENV/DL/DIS/FILT/META/EDGE/REGR)
2. Assign next available test ID
3. Add test implementation to `run_tests.do`
4. Document in this README
5. Update test count in summary

### Test Naming Convention

- **Format:** `CATEGORY-##` (e.g., `DL-05`, `EDGE-01`)
- **Categories:** ENV, DL, DIS, FILT, META, EDGE, REGR
- **IDs:** Sequential within category, zero-padded

---

## Files

| File | Purpose |
|------|---------|
| `run_tests.do` | Main test suite runner |
| `run_tests.log` | Latest test run (detailed trace) |
| `test_history.txt` | Cumulative test run log |
| `fixtures/snap_mortality_baseline.csv` | Mortality regression baseline |
| `fixtures/snap_vaccination_baseline.csv` | Vaccination regression baseline |
| `fixtures/regenerate_baselines.do` | Baseline regeneration script |
| `fixtures/README.md` | Fixture documentation |
| `COMPLETION_SUMMARY.md` | Project completion summary |

---

## Dependencies

- **Stata:** Version 14+ (tested on Stata 17 MP)
- **Internet:** Required for API downloads
- **unicefdata:** Latest version from `stata/src/u/unicefdata.ado`
- **yaml:** YAML metadata parsing package

---

## Troubleshooting

### REGR-01 Failures

1. Check if UNICEF API has been updated
2. Review baseline values in `fixtures/*.csv`
3. If API legitimately changed, regenerate baselines
4. Document reason for baseline update in commit message

### Network Failures

- Check internet connectivity
- Verify UNICEF SDMX API is accessible: https://sdmx.data.unicef.org
- Review EDGE-02 (timeout resilience) test

### Schema Failures

- Check if API response format changed
- Review DL-04 (schema validation) test
- May require package update

### Test Hangs

- Check for infinite loops in test code
- Kill hung Stata process: `Stop-Process -Name "StataMP-64" -Force`
- Review `run_tests.log` for last executed line

---

## Version History

| Version | Date | Tests | Status | Notes |
|---------|------|-------|--------|-------|
| 2.0.0 | Jan 24, 2026 | 38/38 | ✅ 100% | SYNC-02 enrichment fix, all tests passing |
| 1.10.0 | Jan 19, 2026 | 30/30 | ✅ 100% | REGR-01 complete, full cleanup |
| 1.9.0 | Jan 18, 2026 | 29/30 | ⚠️ 97% | META-02 fixed |
| 1.8.0 | Jan 2026 | 28/30 | ⚠️ 93% | Initial test suite |

---

## Contact

For questions about the test suite, see the main [unicefData README](../../README.md) or [Stata README](../README.md).

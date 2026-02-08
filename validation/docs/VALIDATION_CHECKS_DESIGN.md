# Validation Checks Design Document

**Purpose**: Define automated checks to assess data quality and cross-platform consistency  
**Based on**: Analysis of `SUMMARY_190814.md` and consistency assessment findings  
**Date**: January 20, 2026

---

## Overview

The validation framework currently captures raw data but lacks **automated quality checks**. This document proposes a tiered system of checks with **pass/fail thresholds** and **actionable alerts**.

---

## 1. Data Availability Checks

### Check 1.1: Platform Coverage
**What it checks**: Whether each indicator is accessible from all platforms (Python, R, Stata)

```python
def check_platform_coverage(results):
    """
    Alert if indicator missing from any platform
    
    Thresholds:
    - ✅ PASS: All 3 platforms return data
    - ⚠️ WARN: 2/3 platforms return data
    - 🔴 FAIL: Only 1 platform returns data
    """
    for indicator in results:
        platforms_present = sum([
            indicator.python_status == 'success',
            indicator.r_status == 'success', 
            indicator.stata_status == 'success'
        ])
        
        if platforms_present == 3:
            status = "PASS"
        elif platforms_present == 2:
            status = "WARN - Missing from 1 platform"
        else:
            status = "FAIL - Only 1 platform has data"
```

**Example from current run:**
- `CME_MRM0`: ✅ PASS (all 3 platforms)
- `COD_ALCOHOL_USE_DISORDERS`: ⚠️ WARN (Python missing - not_found)
- `ED_LN_R_L2`: 🔴 FAIL (only 0 platforms - failed everywhere)

**Action on FAIL**: Flag for immediate investigation (invalid indicator?)

### Check 1.2: API Response Rate
**What it checks**: Overall success rate across all tests

```python
def check_api_response_rate(results):
    """
    Calculate % of tests that returned data
    
    Thresholds:
    - ✅ PASS: ≥95% success rate
    - ⚠️ WARN: 85-95% success rate
    - 🔴 FAIL: <85% success rate
    """
    total_tests = len(results) * 3  # 3 platforms
    success_count = count_status(results, 'success') + count_status(results, 'cached')
    rate = (success_count / total_tests) * 100
```

**Example from current run:**
- Total tests: 54
- Successes: 46 (cached + success = 28 + 18)
- Rate: 85.2% → ⚠️ WARN (below 95%)

---

## 2. Cross-Platform Consistency Checks

### Check 2.1: Row Count Consistency
**What it checks**: Whether Python, R, and Stata return same number of rows

```python
def check_row_consistency(indicator_data):
    """
    Compare row counts across platforms
    
    Thresholds:
    - ✅ PASS: All platforms have identical row counts
    - ⚠️ WARN: Row counts differ by <10%
    - 🔴 FAIL: Row counts differ by ≥10%
    
    Special cases:
    - If only 2 platforms available, compare those 2
    - If variance >100%, flag as CRITICAL
    """
    python_rows = indicator_data.python.row_count
    r_rows = indicator_data.r.row_count
    stata_rows = indicator_data.stata.row_count
    
    max_diff = max([python_rows, r_rows, stata_rows]) / min([...])
    
    if max_diff == 1.0:
        return "PASS"
    elif max_diff < 1.10:
        return "WARN - <10% difference"
    elif max_diff < 2.0:
        return "FAIL - 10-100% difference"
    else:
        return "CRITICAL - >100% difference"
```

**Examples from current run:**
- `CME_MRM0`: ✅ PASS (11,875 rows all platforms)
- `DM_POP_CHILD_PROP`: 🔴 FAIL (Python 23,606 vs R 31,524 = 33% diff)
- `ECD_CHLD_U5_LFT-ALN`: 🔴 CRITICAL (Python 117 vs R 564 = 382% diff!)
- `MNCH_PNCMOM`: 🔴 CRITICAL (Python 287 vs R 1,866 = 550% diff!)

**Action on CRITICAL**: Immediately flag for data quality investigation

### Check 2.2: Column Count Consistency
**What it checks**: Whether platforms return same columns

```python
def check_column_consistency(indicator_data):
    """
    Compare column counts and names
    
    Thresholds:
    - ✅ PASS: All platforms have identical column counts
    - ⚠️ WARN: Column counts differ but core 20 columns present
    - 🔴 FAIL: Core columns missing
    
    Core columns (must be present):
    indicator, iso3, country, period, value, unit, sex, age, 
    data_source, geo_type, obs_status, lower_bound, upper_bound
    """
    python_cols = set(indicator_data.python.columns)
    r_cols = set(indicator_data.r.columns)
    stata_cols = set(indicator_data.stata.columns)
    
    core_columns = {
        'indicator', 'iso3', 'country', 'period', 'value', 
        'unit', 'sex', 'age', 'data_source', 'geo_type'
    }
    
    # Check if all platforms have core columns
    for platform_cols in [python_cols, r_cols, stata_cols]:
        if not core_columns.issubset(platform_cols):
            return "FAIL - Missing core columns"
    
    # If counts match exactly
    if len(python_cols) == len(r_cols) == len(stata_cols):
        return "PASS"
    else:
        return "WARN - Column counts differ (acceptable if core present)"
```

**Examples from current run:**
- `CME_MRM0`: ⚠️ WARN (Python 32, R 23 - but both have core columns)
- `DM_POP_CHILD_PROP`: ⚠️ WARN (Python 32, R 37 - R has extra labels)
- `ECD_CHLD_U5_LFT-ALN`: ⚠️ WARN (Python 32, R 57 - R has extensive metadata)

**Pattern identified**: R consistently adds 4-25 extra columns (semantic labels, SOWC flags, metadata)

**Action on FAIL**: Flag missing core columns as blocker

### Check 2.3: Column Name Normalization
**What it checks**: Whether column naming is consistent (case, underscores)

```python
def check_column_naming(indicator_data):
    """
    Verify column naming follows standard convention
    
    Expected: lowercase with underscores (snake_case)
    Examples: indicator_name, iso3, obs_status
    
    Alert on:
    - Mixed case (e.g., "Current age" vs "current_age")
    - Duplicate semantics (e.g., both "age" and "Age")
    - Spaces in column names
    """
    issues = []
    
    for col in all_columns:
        if ' ' in col and col not in ALLOWED_LABELS:
            issues.append(f"Space in column name: {col}")
        
        if col.lower() != col and col.upper() != col:
            issues.append(f"Mixed case: {col}")
    
    return "WARN" if issues else "PASS"
```

**Examples from current run:**
- R columns: `"Current age"`, `"Mother's Education Level"`, `"Time interval at which..."` ← Spaces!
- R columns: `age` + `Age`, `residence` + `Residence` ← Duplicates!
- Python columns: All lowercase with underscores ✅

**Finding**: R violates naming convention (spaces, mixed case, semantic duplicates)

---

## 3. Data Quality Checks

### Check 3.1: Null Value Rate
**What it checks**: Percentage of null/missing values in critical columns

```python
def check_null_rate(data):
    """
    Calculate % of null values in key columns
    
    Thresholds:
    - ✅ PASS: <5% null in value column
    - ⚠️ WARN: 5-20% null in value column
    - 🔴 FAIL: >20% null in value column
    
    Critical columns: value, period, iso3
    """
    for col in ['value', 'period', 'iso3']:
        null_pct = (data[col].isnull().sum() / len(data)) * 100
        
        if null_pct < 5:
            status = "PASS"
        elif null_pct < 20:
            status = "WARN"
        else:
            status = "FAIL"
```

**Data needed**: CSV analysis (not in current SUMMARY)

**Action**: Add null rate to SUMMARY report

### Check 3.2: Value Range Validation
**What it checks**: Whether values are within expected ranges (e.g., percentages 0-100)

```python
def check_value_range(data, indicator_metadata):
    """
    Verify values fall within expected ranges
    
    Examples:
    - Percentage indicators: 0-100
    - Rates per 1000: 0-1000
    - Index scores: Depend on indicator definition
    
    Thresholds:
    - ✅ PASS: All values in range
    - ⚠️ WARN: <1% values out of range
    - 🔴 FAIL: ≥1% values out of range
    """
    unit = indicator_metadata.unit
    
    if unit == 'Percentage':
        out_of_range = data[(data['value'] < 0) | (data['value'] > 100)]
    elif unit == 'Per 1000 live births':
        out_of_range = data[(data['value'] < 0) | (data['value'] > 1000)]
    
    out_of_range_pct = (len(out_of_range) / len(data)) * 100
```

**Data needed**: Unit metadata + value analysis (partially in SUMMARY)

**Action**: Add range validation using indicator metadata

### Check 3.3: Temporal Coverage
**What it checks**: Whether data spans expected time periods

```python
def check_temporal_coverage(data):
    """
    Verify time series has reasonable coverage
    
    Thresholds:
    - ✅ PASS: Data spans ≥10 years
    - ⚠️ WARN: Data spans 5-10 years
    - 🔴 FAIL: Data spans <5 years
    
    Additional check:
    - Flag gaps >5 years in time series
    """
    years = sorted(data['period'].unique())
    span = max(years) - min(years)
    
    # Check for gaps
    gaps = []
    for i in range(len(years) - 1):
        gap = years[i+1] - years[i]
        if gap > 5:
            gaps.append(f"{years[i]} → {years[i+1]} ({gap} year gap)")
```

**Data needed**: Period column analysis (not in current SUMMARY)

**Action**: Add temporal analysis to SUMMARY

---

## 4. Performance Checks

### Check 4.1: Execution Time
**What it checks**: Whether tests complete within reasonable time

```python
def check_execution_time(results):
    """
    Monitor query performance
    
    Thresholds (per indicator):
    - ✅ PASS: <5 seconds average
    - ⚠️ WARN: 5-10 seconds average
    - 🔴 FAIL: >10 seconds average
    
    Platform-specific thresholds:
    - Python: <2s (fastest)
    - R: <8s (slowest, includes data processing)
    - Stata: <5s (middle)
    """
    for indicator in results:
        avg_time = indicator.average_time
        
        if avg_time < 5:
            status = "PASS"
        elif avg_time < 10:
            status = "WARN - Slow query"
        else:
            status = "FAIL - Timeout risk"
```

**Examples from current run:**
- `CME_MRM0`: ✅ PASS (0.03s avg)
- `ED_LN_R_L2`: 🔴 FAIL (9.44s avg - and it failed!)
- `WS_HCF_WM-N`: ⚠️ WARN (4.18s avg)

**Finding**: Slow queries often correlate with failures (ED_LN_R_L2, NT_ANT_BAZ_NE2)

**Action**: Flag indicators >8s for investigation

### Check 4.2: Cache Hit Rate
**What it checks**: Effectiveness of caching mechanism

```python
def check_cache_effectiveness(results):
    """
    Calculate % of tests served from cache
    
    Thresholds:
    - ✅ PASS: >80% cache hit rate (for repeat runs)
    - ⚠️ WARN: 50-80% cache hit rate
    - 🔴 FAIL: <50% cache hit rate
    
    Note: First run should have 0% cache hits
    Subsequent runs should have high cache hits
    """
    total_tests = len(results)
    cached = count_status(results, 'cached')
    cache_rate = (cached / total_tests) * 100
```

**Example from current run:**
- Cached: 28/54 (51.9%) → ⚠️ WARN

**Expected**: For repeat run with same seed, should be ~95% cached

---

## 5. Regression Checks

### Check 5.1: Row Count Regression
**What it checks**: Whether row counts changed since last validation

```python
def check_row_count_regression(current, baseline):
    """
    Compare row counts to baseline (previous run)
    
    Thresholds:
    - ✅ PASS: Row count unchanged (±1 row tolerance)
    - ⚠️ WARN: Row count changed <5%
    - 🔴 FAIL: Row count changed ≥5%
    - 🚨 CRITICAL: Row count changed >50%
    
    Track over time:
    - Store baseline in validation/baselines/seed42_baseline.json
    - Compare each run to baseline
    - Alert on significant deviations
    """
    for indicator in current:
        baseline_rows = baseline.get(indicator.name, {}).get('rows')
        current_rows = indicator.row_count
        
        if baseline_rows is None:
            status = "NEW - No baseline"
        else:
            diff_pct = abs(current_rows - baseline_rows) / baseline_rows * 100
            
            if diff_pct < 0.1:
                status = "PASS"
            elif diff_pct < 5:
                status = "WARN - Minor change"
            elif diff_pct < 50:
                status = "FAIL - Significant change"
            else:
                status = "CRITICAL - Data changed drastically"
```

**Use case**: Detect API changes or data quality issues

**Example scenarios:**
- API returns new data → Row count increases (expected)
- API filtering changes → Row count decreases (investigate)
- Data correction → Row count changes (acceptable if documented)

### Check 5.2: Column Schema Regression
**What it checks**: Whether column names changed since baseline

```python
def check_schema_regression(current, baseline):
    """
    Detect schema changes (new/removed columns)
    
    Alert on:
    - Columns added (could be new metadata - WARN)
    - Columns removed (breaking change - FAIL)
    - Columns renamed (breaking change - FAIL)
    """
    baseline_cols = set(baseline.columns)
    current_cols = set(current.columns)
    
    added = current_cols - baseline_cols
    removed = baseline_cols - current_cols
    
    if removed:
        return f"FAIL - Columns removed: {removed}"
    elif added:
        return f"WARN - Columns added: {added}"
    else:
        return "PASS"
```

---

## 6. Proposed Check Summary Table

Add this to the end of each SUMMARY report:

```markdown
## Validation Quality Checks

### Data Availability
| Check | Status | Details |
|-------|--------|---------|
| Platform coverage | ⚠️ WARN | 2 indicators missing from platforms |
| API response rate | ⚠️ WARN | 85.2% success (target: 95%) |

### Cross-Platform Consistency
| Check | Status | Details |
|-------|--------|---------|
| Row count consistency | 🔴 FAIL | 4 indicators with >10% row differences |
| Row count CRITICAL | 🚨 ALERT | 2 indicators with >100% differences (MNCH_PNCMOM, ECD_CHLD_U5_LFT-ALN) |
| Column count consistency | ⚠️ WARN | All indicators differ (acceptable - R adds metadata) |
| Core columns present | ✅ PASS | All platforms have 10 core columns |

### Data Quality
| Check | Status | Details |
|-------|--------|---------|
| Null value rate | ℹ️ NOT CHECKED | Add to next version |
| Value range validation | ℹ️ NOT CHECKED | Add to next version |
| Temporal coverage | ℹ️ NOT CHECKED | Add to next version |

### Performance
| Check | Status | Details |
|-------|--------|---------|
| Execution time | ⚠️ WARN | 2 indicators >8s (both failed) |
| Cache hit rate | ⚠️ WARN | 51.9% (acceptable for mixed fresh/cached run) |

### Regression (vs baseline)
| Check | Status | Details |
|-------|--------|---------|
| Row count regression | ℹ️ NO BASELINE | First run - establish baseline |
| Schema regression | ℹ️ NO BASELINE | First run - establish baseline |

### Overall Quality Score
**Score**: 52/100 (🔴 NEEDS IMPROVEMENT)

**Breakdown**:
- Data availability: 7/10 (2 points lost for missing platforms)
- Consistency: 2/10 (8 points lost for row mismatches)
- Data quality: 0/10 (not checked yet)
- Performance: 7/10 (slow queries on failures)
- Regression: 0/10 (no baseline)

**Release Recommendation**: ❌ DO NOT RELEASE
- Must resolve row count mismatches
- Must investigate MNCH_PNCMOM 550% difference
- Must fix ED_LN_R_L2 and NT_ANT_BAZ_NE2 failures
```

---

## 7. Implementation Plan

### Phase 1: Core Checks (Week 1)
- [x] Platform coverage check
- [x] Row count consistency check
- [x] Column count consistency check
- [ ] Add checks to SUMMARY report generation

### Phase 2: Quality Checks (Week 2)
- [ ] Null value rate analysis
- [ ] Value range validation
- [ ] Temporal coverage check

### Phase 3: Regression System (Week 3)
- [ ] Baseline storage (JSON format)
- [ ] Row count regression detection
- [ ] Schema regression detection
- [ ] Automated alerts

### Phase 4: Integration (Week 4)
- [ ] Add to CI/CD pipeline
- [ ] Email alerts on FAIL/CRITICAL
- [ ] Dashboard visualization

---

## 8. File Locations

**Baseline storage**:
```
validation/
├── baselines/
│   ├── seed42_baseline.json          # Row counts for seed 42 sample
│   ├── seed42_schema_baseline.json   # Column schemas
│   └── last_validated.json           # Timestamp + metadata
```

**Check implementation**:
```
validation/
├── checks/
│   ├── __init__.py
│   ├── availability.py     # Platform coverage, API response
│   ├── consistency.py      # Row/column consistency
│   ├── quality.py          # Null rates, ranges, temporal
│   ├── performance.py      # Execution time, cache
│   └── regression.py       # Baseline comparison
```

**Integration**:
```python
# In test_all_indicators_comprehensive.py

from checks import (
    check_platform_coverage,
    check_row_consistency,
    check_execution_time
)

# After test execution
check_results = {
    'availability': check_platform_coverage(results),
    'consistency': check_row_consistency(results),
    'performance': check_execution_time(results)
}

# Add to SUMMARY report
generate_summary(results, check_results)
```

---

## 9. Alerting Logic

### Critical Alerts (Immediate)
- Row count >100% difference between platforms
- Core columns missing
- >20% API failures

### High Priority Alerts (Same day)
- Row count 10-100% difference
- Execution time >10s
- Cache hit rate <50% (on repeat runs)

### Medium Priority Alerts (Next business day)
- Row count <10% difference
- Column count differences (if not documented)
- Execution time 5-10s

### Info Alerts (Weekly digest)
- New indicators added
- Schema changes (new columns)
- Cache statistics

---

## Questions for Discussion

1. **Acceptable variance**: What % row difference is acceptable between platforms?
   - Current proposal: <10% WARN, ≥10% FAIL
   - Alternative: <5% WARN, ≥5% FAIL (stricter)

2. **Column consistency**: Should we require exact column match?
   - Current: Allow differences if core 10 columns present
   - Alternative: Require exact match (force R to standardize)

3. **Baseline update frequency**: How often to update baseline?
   - Proposal: Manual update after each release
   - Alternative: Auto-update if all checks pass

4. **Pass threshold for release**: What overall score is acceptable?
   - Current proposal: 80/100
   - Must have: 0 CRITICAL alerts, <3 FAIL alerts

---

**Next Steps**:
1. Review this design with team
2. Implement Phase 1 checks
3. Run validation with checks enabled
4. Establish baseline for seed=42
5. Document check thresholds in project docs

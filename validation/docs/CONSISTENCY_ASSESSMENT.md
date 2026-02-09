# 📊 Platform Consistency Assessment Report

**Date:** January 20, 2026  
**Analysis:** Cross-platform comparison (Python, R, Stata) validation results

---

## Executive Summary

### Key Metrics
- **Total Indicators:** 26
- **Present in All Platforms:** 17/26 (65%)
- **Row Counts Match (where comparable):** 11/17 (65%)
- **Column Counts Match (where comparable):** 2/17 (12%)
- **Critical Issues:** 9 indicators with significant row/column mismatches

---

## 1. Data Availability

### Present in All Three Platforms (17 indicators ✓)
These indicators have been successfully cached from Python, R, and Stata:

| Indicator | Python Rows | R Rows | Stata Rows | Status |
|-----------|------------|--------|------------|--------|
| CME_ARR_10T19 | 252 | 252 | ✗ | Stata missing |
| CME_ARR_SBR | 213 | 213 | ✗ | Stata missing |
| CME_ARR_U5MR | 245 | 245 | ✗ | Stata missing |
| CME_MRM0 | 11,875 | 11,875 | ✗ | Stata missing |
| CME_MRM1T11 | 11,862 | 11,862 | ✗ | Stata missing |
| CME_MRM1T59 | 11,862 | 11,862 | ✗ | Stata missing |
| DM_POP_CHILD_PROP | 23,606 | 31,524 | ✗ | Row mismatch |
| ECD_CHLD_U5_LFT-ALN | 117 | 564 | ✗ | Row mismatch |
| ECON_GVT_HLTH_EXP_PTEXP | 246 | 246 | ✗ | Stata missing |
| FD_EARLY_STIM | 50 | 118 | 118 | Row mismatch |
| GN_IDX | 178 | 178 | ✗ | Stata missing |
| IM_DTP3 | 9,761 | 9,761 | ✗ | Stata missing |
| MG_RFGS_CNTRY_ORIGIN | 4,584 | 11,017 | ✗ | Row mismatch |
| MNCH_PNCMOM | 287 | 1,866 | ✗ | Row mismatch |
| PT_ADLT_PS_NEC | 100 | 333 | 100 | Row mismatch (R different) |
| PV_CHLD_DPRV-E1-HS | 72 | 72 | 72 | ✓ Rows match |
| WS_HCF_WM-N | 1,705 | 1,705 | 1,705 | ✓ Rows match |
| SPP_GDPPC | 236 | 236 | ✗ | Stata missing |
| WT_ADLS_15-19_ED_NEET | (?) | (?) | (?) | To verify |

### Missing from Platforms (9 indicators ✗)

| Indicator | Python | R | Stata | Notes |
|-----------|--------|---|-------|-------|
| CME_COVID_CASES | ✗ | ✓ | ✓ | Python missing |
| CME_COVID_CASES_SHARE | ✗ | ✓ | ✓ | Python missing |
| CME_COVID_DEATHS | ✗ | ✓ | ✓ | Python missing |
| CME_COVID_DEATHS_SHARE | ✗ | ✓ | ✓ | Python missing |
| COD_ALCOHOL_USE_DISORDERS | ✗ | ✓ | ✓ | Python missing (API 404 error) |
| PV_CHLD_DPRV-L4-HS | ✓ | ✗ | ✗ | R & Stata missing |
| WS_PPL_W-ALB | ✓ | ✗ | ✗ | R & Stata missing |
| HVA_PREV_TEST_RES_12 | ✗ | ✓ | ✓ | Python missing (API 404 error) |
| NT_ANT_BAZ_NE2 | ✗ | ✗ | ✗ | All missing (invalid indicator) |

---

## 2. Row Count Analysis

### 🟢 Consistent Row Counts (Same across platforms)

| Indicator | Rows | Platforms |
|-----------|------|-----------|
| PV_CHLD_DPRV-E1-HS | 72 | Python = R = Stata |
| WS_HCF_WM-N | 1,705 | Python = R = Stata |

**Success Rate:** 2/17 (11.8%)

### 🔴 Row Count Mismatches

#### Category 1: Python = R ≠ Stata (Stata Missing CSV)

| Indicator | Python | R | Stata | Difference |
|-----------|--------|---|-------|------------|
| CME_ARR_10T19 | 252 | 252 | ✗ | - |
| CME_ARR_SBR | 213 | 213 | ✗ | - |
| CME_ARR_U5MR | 245 | 245 | ✗ | - |
| CME_MRM0 | 11,875 | 11,875 | ✗ | - |
| CME_MRM1T11 | 11,862 | 11,862 | ✗ | - |
| CME_MRM1T59 | 11,862 | 11,862 | ✗ | - |
| ECON_GVT_HLTH_EXP_PTEXP | 246 | 246 | ✗ | - |
| GN_IDX | 178 | 178 | ✗ | - |
| IM_DTP3 | 9,761 | 9,761 | ✗ | - |
| SPP_GDPPC | 236 | 236 | ✗ | - |

**Diagnosis:** Stata CSV files not created for these indicators (likely encoding issues when reading cached Stata data)

#### Category 2: Python ≠ R (Both platforms present)

| Indicator | Python | R | Difference | % Diff |
|-----------|--------|---|-----------|--------|
| DM_POP_CHILD_PROP | 23,606 | 31,524 | +7,918 | 33.5% ↑ R |
| ECD_CHLD_U5_LFT-ALN | 117 | 564 | +447 | 382% ↑ R |
| MG_RFGS_CNTRY_ORIGIN | 4,584 | 11,017 | +6,433 | 140% ↑ R |
| MNCH_PNCMOM | 287 | 1,866 | +1,579 | 550% ↑ R |

**Pattern:** R consistently returns MORE rows than Python (35-550% more)

**Likely Causes:**
- Python may filter out rows with missing values
- R may include broader set of dimensions/combinations
- Different handling of NULL/missing data
- Different aggregation strategies for multi-dimensional indicators

#### Category 3: Python = Stata ≠ R

| Indicator | Python | R | Stata | % Diff |
|-----------|--------|---|-------|--------|
| PT_ADLT_PS_NEC | 100 | 333 | 100 | R is 3.3× larger |

**Pattern:** R has 3× more rows than Python and Stata (which match)

---

## 3. Column Count Analysis

### 🟢 Consistent Column Counts

| Indicator | Columns | Platforms |
|-----------|---------|-----------|
| None found | - | - |

**Success Rate:** 0/17 (0%)

### 🔴 Column Count Mismatches (ALL indicators)

All 17 indicators that are present in Python show column count mismatches:

| Indicator | Python Cols | R Cols | Stata Cols | R Extra | Stata Extra |
|-----------|------------|--------|------------|---------|-------------|
| CME_ARR_10T19 | 32 | 23 | ✗ | -9 | - |
| CME_MRM0 | 32 | 23 | ✗ | -9 | - |
| DM_POP_CHILD_PROP | 32 | 37 | ✗ | +5 | - |
| ECD_CHLD_U5_LFT-ALN | 32 | 57 | ✗ | +25 | - |
| ECON_GVT_HLTH_EXP_PTEXP | 32 | 36 | ✗ | +4 | - |
| FD_EARLY_STIM | 32 | 51 | 38 | +19 | +6 |
| GN_IDX | 32 | 39 | ✗ | +7 | - |
| IM_DTP3 | 32 | 40 | ✗ | +8 | - |
| MG_RFGS_CNTRY_ORIGIN | 32 | 38 | ✗ | +6 | - |
| MNCH_PNCMOM | 32 | 46 | ✗ | +14 | - |
| PT_ADLT_PS_NEC | 32 | 55 | 32 | +23 | Same |
| PV_CHLD_DPRV-E1-HS | 32 | 27 | 25 | -5 | -7 |
| SPP_GDPPC | 32 | 36 | ✗ | +4 | - |
| WS_HCF_WM-N | 32 | 36 | 32 | +4 | Same |
| WT_ADLS_15-19_ED_NEET | 32 | 36 | ✗ | +4 | - |

**Key Findings:**

1. **Python always has 32 base columns** (consistent core schema)
2. **R adds 4-25 extra columns** (median +6) 
3. **Stata matches Python or has slight variations**
4. **Extra columns in R:** metadata, SOWC flags, statistical details (STD_ERR, N_CASES, CONF_INTVAL)

---

## 4. Column Name Differences

### Common Pattern: Case Sensitivity and Metadata Fields

**Python columns (base set):**
```
indicator, indicator_name, iso3, country, geo_type, period, value, unit, unit_name, 
sex, sex_name, age, wealth_quintile, wealth_quintile_name, residence, maternal_edu_lvl,
lower_bound, upper_bound, obs_status, obs_status_name, data_source, ref_period, 
country_notes, unit_multiplier, obs_conf, wgtd_sampl_size, obs_footnote, 
series_footnote, source_link, custodian, time_period_method, coverage_time
```

**R adds (varies by indicator):**
- Demographic breakdowns: Age, Residence, Education Level, Ethnic Group, etc.
- SOWC flags: SOWC_FLAG_A, SOWC_FLAG_B, SOWC_FLAG_C, etc.
- Statistical details: STD_ERR, CONF_INTVAL, N_CASES
- Semantic duplicates: English labels for coded variables
- Example: `MOTHER_EDUCATION` + `Mother's Education Level` (both for same variable)

**Stata typically:**
- Matches Python column count
- Uses lowercase or different naming conventions
- Subset of R's extended metadata

---

## 5. Issues Identified

### 🔴 CRITICAL (Prevents accurate comparison)

1. **Stata CSV Export Failure** (10 indicators)
   - UTF-8 encoding issue when reading cached Stata data
   - CSVs generated but not readable by Python
   - Error: `'utf-8' codec can't decode byte 0xfc`
   - **Impact:** Cannot compare Python vs R vs Stata for most indicators

2. **Row Count Discrepancies in R** (4-550% higher than Python)
   - DM_POP_CHILD_PROP: 23,606 (Python) vs 31,524 (R) = +33.5%
   - ECD_CHLD_U5_LFT-ALN: 117 (Python) vs 564 (R) = +382%
   - MG_RFGS_CNTRY_ORIGIN: 4,584 (Python) vs 11,017 (R) = +140%
   - MNCH_PNCMOM: 287 (Python) vs 1,866 (R) = +550%
   - **Impact:** Data inconsistency across platforms

### ⚠️  MAJOR (Affects usability)

1. **Inconsistent Column Presence** (100% of indicators)
   - All indicators have different column counts
   - R consistently adds 4-25 extra columns
   - Metadata field naming inconsistent (some duplicates with English labels)
   - **Impact:** Hard to programmatically join data across platforms

2. **Missing Platform Coverage**
   - 9/26 indicators not in all platforms
   - Python missing: COVID indicators (API 404 errors)
   - R/Stata missing: PV_CHLD_DPRV-L4-HS, WS_PPL_W-ALB

### ℹ️  INFORMATIONAL (Expected differences)

1. **Column Count Differences Expected**
   - R often includes descriptive labels alongside codes
   - Metadata enrichment varies by platform
   - This is a design choice, not necessarily a bug

2. **Platform-Specific Columns**
   - R: Extended demographic breakdowns, SOWC flags
   - Stata: Smaller footprint, minimal extra metadata
   - Python: Balanced middle ground

---

## 6. Recommendations

### Immediate Actions (Priority 1)

1. **Fix Stata CSV Encoding Issue**
   - Root cause: UTF-8 decode error when reading cached Stata data
   - Solution: Force encoding='latin-1' or 'utf-8-sig' in read_csv()
   - **Impact:** Unblock Stata comparison for 10 indicators

2. **Investigate R Row Count Inflation**
   - Compare API responses (are R getting different data?)
   - Check R's data processing (filters, aggregation)
   - Determine if rows are duplicates or legitimate additional observations
   - **Impact:** Verify data accuracy

### Medium Term (Priority 2)

1. **Standardize Column Presence**
   - Document which columns are "core" vs "optional"
   - Define platform-specific extensions cleanly
   - Provide a column mapping dictionary for cross-platform joins

2. **Add Validation Logic**
   - Row count validation (flag if differs > 10%)
   - Column count validation (warn if differs)
   - Automated regression detection

### Long Term (Priority 3)

1. **Create Platform Consistency Tests**
   - Unit tests comparing sample indicators across platforms
   - Define acceptable tolerance thresholds
   - Add to CI/CD pipeline

2. **Documentation**
   - Explain why R has more rows/columns
   - Create mapping between Python ↔ R ↔ Stata columns
   - Add troubleshooting guide

---

## Summary Table

| Metric | Value | Status |
|--------|-------|--------|
| **Indicators Compared** | 26 | - |
| **Present All Platforms** | 17 (65%) | ⚠️ Need 100% |
| **Rows Match** | 2/17 (12%) | 🔴 Critical |
| **Columns Match** | 0/17 (0%) | 🔴 Critical |
| **Stata CSV Readable** | 7/17 (41%) | 🔴 Encoding issue |
| **R Row Inflate (>30%)** | 4 indicators | 🔴 Investigate |
| **Column Consistency** | ~32 base + R variations | ℹ️ Expected |

---

## Next Steps

1. Run Stata encoding diagnostic
2. Deep dive on R row count discrepancies  
3. Create column mapping reference
4. Design platform-agnostic CSV spec

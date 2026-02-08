# CONSISTENCY ASSESSMENT: EXECUTIVE SUMMARY

**Date:** January 20, 2026  
**Analysis:** Cross-platform CSV consistency (Python, R, Stata)  
**Test Run:** seed=42, stratified sampling, 18 indicators  
**Status:** 🔴 **CRITICAL ISSUES IDENTIFIED**

---

## ⚠️ KEY FINDINGS

### 1. Row Count Inconsistencies (CRITICAL)

**4 indicators show significant row count differences between Python and R:**

| Indicator | Python | R | Difference | Severity |
|-----------|--------|---|-----------|----------|
| **MNCH_PNCMOM** | 287 | 1,866 | **+550%** | 🔴 CRITICAL |
| **ECD_CHLD_U5_LFT-ALN** | 117 | 564 | **+382%** | 🔴 CRITICAL |
| **MG_RFGS_CNTRY_ORIGIN** | 4,584 | 11,017 | **+140%** | 🔴 CRITICAL |
| **DM_POP_CHILD_PROP** | 23,606 | 31,524 | **+33%** | 🟠 HIGH |

**Impact:** Users on different platforms will get **DIFFERENT RESULTS** for the same query (e.g., different totals, different row counts).

**Root Cause:** Unknown - requires investigation into:
- API response differences (are both correct?)
- Data filtering logic (Python filters more aggressively?)
- Aggregation strategy (Python aggregates, R disaggregates?)

---

### 2. Column Count Inconsistencies (MAJOR)

**ALL 17 indicators present in Python show column count mismatches:**

- **Python:** Always 32 base columns (consistent)
- **R:** 23-57 columns (includes extra labels and metadata)
- **Stata:** 25-38 columns (variable)

**Example - DM_POP_CHILD_PROP:**
- Python: 32 columns (codes: `wealth_quintile`, `residence`, `age`)
- R: 36 columns (codes + labels: `wealth_quintile` + `WEALTH_QUINTILE_NAME`, `residence` + `Residence`, `age` + `Current age`)

**Impact:** 
- ✅ Can join on common columns
- ❌ Column names inconsistent across platforms
- ❌ R includes semantic duplicates (both code and label)
- ❌ Hard to write platform-agnostic analysis code

---

### 3. Stata Coverage Issue (MAJOR)

**Stata CSV exports failing for 10+ indicators:**

- CSV files generated but unable to read
- **Error:** UTF-8 encoding issue (`'utf-8' codec can't decode byte 0xfc`)
- Likely cause: Stata outputs Latin-1/CP1252, Python expects UTF-8
- **Impact:** Cannot compare Python ↔ R ↔ Stata for most CME indicators

---

## ✅ WHAT WORKS

| Metric | Status | Details |
|--------|--------|---------|
| **2 indicators with matching rows** | ✅ | PV_CHLD_DPRV-E1-HS (72 rows), WS_HCF_WM-N (1,705 rows) |
| **Data present in all platforms** | ✅ | 2/17 indicators (all 3 platforms match) |
| **Python column consistency** | ✅ | Python always returns 32 base columns |
| **Seed-based reproducibility** | ✅ | seed=42 produces same sample every time |
| **Caching system** | ✅ | 92.6% test pass rate with caching |

---

## 🔴 RECOMMENDED ACTIONS (PRIORITY ORDER)

### Phase 1: Diagnosis (This Week)

**1.1 Investigate R row inflation**
- **Question:** Why does R have 33-550% more rows than Python?
- **Approach:** 
  - Compare Python vs R API responses for DM_POP_CHILD_PROP
  - Check if 7,918 extra rows are: (a) duplicates, (b) additional dimensions, or (c) different data
  - Trace filtering logic in Python (`unicef_api/indicator.py`) and R (`R/unicefData.R`)
- **Expected outcome:** Identify root cause, determine if bug or design choice
- **Effort:** 2-4 hours
- **Blockers:** This affects data accuracy and must be resolved before release

**1.2 Fix Stata CSV encoding**
- **Issue:** Cannot read Stata CSV files (UTF-8 decode error)
- **Approach:** 
  - Identify encoding used by Stata
  - Update Python CSV reader to handle encoding automatically
  - Test with sample Stata CSV
- **Expected outcome:** Can successfully read all Stata CSV files
- **Effort:** 30-60 min
- **Dependency:** Unblocks Stata comparison

**1.3 Compare data values** (where rows overlap)
- **Question:** For indicators where both platforms have same row count, do the DATA VALUES match?
- **Approach:** Load PV_CHLD_DPRV-E1-HS and WS_HCF_WM-N CSVs, compare all values
- **Expected outcome:** Verify data integrity for matching row counts
- **Effort:** 1 hour

### Phase 2: Documentation (Next 2 Weeks)

**2.1 Document platform differences**
- Add section to API docs: "Cross-Platform Differences"
- Explain: column differences, row count variations, why they occur
- Provide guidance: "Use Python for summary stats, R for detailed breakdowns"

**2.2 Create column mapping**
- Build lookup table: Python column name → R column name → Stata column name
- Identify "core required" vs "platform-specific optional" columns
- Version the mapping (for future compatibility)

**2.3 Add validation tests**
- Row count regression test (fail if >5% change)
- Column presence validation
- Data value spot checks

### Phase 3: Standardization (v2.0)

**3.1 Implement canonical CSV format**
- Define UNICEF indicator CSV spec (rows, columns, data types)
- All platforms produce identical output
- Semantic duplicates (labels) in separate optional columns

**3.2 Add filtering options**
- `--aggregate`: Return summary only (fewer rows)
- `--disaggregate`: Return all dimension combinations (more rows)
- Consistent behavior across all platforms

---

## ❓ QUESTIONS FOR DISCUSSION

1. **Data Accuracy:** Is R's data correct (31,524 rows) or Python's (23,606 rows) for DM_POP_CHILD_PROP?
   - Should we query UNICEF API documentation?
   - Should we ask WHO reference implementation?

2. **Design Choice:** Should all platforms return:
   - Option A: Identical output (same rows, same columns, same values)
   - Option B: Platform-optimized output (current approach - different but compatible)
   - Option C: Platform-agnostic spec + optional platform-specific columns

3. **Release Decision:** Can we release with these inconsistencies?
   - What's the minimum acceptable consistency level?
   - Should we add disclaimer: "Data may differ across platforms for same indicator"?

---

## 📊 DATA SUMMARY

### Indicators Analyzed
- **Total:** 26 unique indicators across all platforms
- **Python & R:** 17 indicators
- **Python only:** 2 indicators (PV_CHLD_DPRV-L4-HS, WS_PPL_W-ALB)
- **R & Stata only:** 9 indicators (COVID variants + others)

### Row Count Status
- **Match (all platforms):** 2/17 (12%)
- **Python = Stata ≠ R:** 1/17 (6%)
- **Python = R ≠ Stata:** 7/17 (41%) - *Stata CSV unreadable*
- **Python ≠ R:** 4/17 (23%) - *CRITICAL MISMATCHES*

### Column Count Status
- **Match:** 0/17 (0%)
- **Differ:** 17/17 (100%)
  - Python: 32 columns (base)
  - R: +4 to +25 columns (average +6)
  - Stata: -7 to +6 columns (variable)

### Data Quality Score
- **Consistency:** 12% (only 2/17 indicators fully consistent)
- **Coverage:** 65% (17/26 indicators in all 3 platforms)
- **Usability:** 41% (7/17 readable and comparable)
- **Overall Rating:** 🔴 **NEEDS WORK** (minimum 80% for release)

---

## 📁 GENERATED REPORTS

All reports saved to `validation/`:

1. **CONSISTENCY_ASSESSMENT.md** - Comprehensive analysis with detailed tables
2. **ROW_MISMATCH_ANALYSIS.md** - Deep dive on DM_POP_CHILD_PROP (33% difference)
3. **platform_consistency_summary.csv** - All 26 indicators with metrics
4. **This file** - Executive summary and action items

---

## ✅ NEXT STEP

**Immediate action:** Schedule investigation of R row inflation for DM_POP_CHILD_PROP and MNCH_PNCMOM. These 550%+ differences must be understood before proceeding with release.

**Timeline:** 
- Phase 1 (Diagnosis): Complete by end of week
- Phase 2 (Documentation): Complete before release
- Phase 3 (Standardization): Plan for v2.0

---

**Generated:** January 20, 2026  
**Analysis By:** Copilot Validation Framework  
**Test Configuration:** seed=42, stratified sampling, 18 indicators, all 3 languages  
**Test Results:** 54 tests (18 × 3), 92.6% pass rate, 2 failures, 4 not found

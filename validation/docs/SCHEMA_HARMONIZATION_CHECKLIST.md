# Cross-Platform Schema Harmonization - Implementation Checklist

**Branch:** `feat/cross-platform-dataset-schema`  
**Created:** 2026-01-14  
**Owner:** You  

---

## Overview

Harmonize Python, R, and Stata dataset outputs to produce identical column names and ordering.

**Current Status:**
- Python & R: ✅ Already identical (16+ columns, consistent naming)
- Stata: ⚠️ Different schema (20 columns, different naming and ordering)

---

## Phase 1: Schema Design & Review

- [ ] Review CROSS_PLATFORM_SCHEMA_ANALYSIS.md
- [ ] Approve canonical column order and naming
- [ ] Resolve questions on optional columns (bounds, source, notes)
- [ ] Document any indicator-specific exceptions

---

## Phase 2: Python Implementation

### 2.1 Rename Dimensions
- [ ] Change `wealth_quintile` → `wealth` everywhere in Python code
- [ ] Change `wealth_quintile_name` → `wealth_name` everywhere
- [ ] Verify all callsites updated

**Files:**
- `R/unicefdata.R` (main function)
- `R/unicefdata_api.py` (API wrapper)
- `python/unicefdata.py` (wrapper)

### 2.2 Reorder Columns
- [ ] Implement column reordering to canonical schema
- [ ] Add missing columns (if applicable):
  - `source` 
  - `notes`
  - `refper` (if available from API)
  - `lb`, `ub` (confidence bounds if available)

**Files:**
- `R/unicefdata.R` (post-processing)

### 2.3 Testing
- [ ] Run 5 indicators with --seed 51 to verify output
- [ ] Compare columns with Stata output
- [ ] Verify backward compatibility (if needed)

---

## Phase 3: R Implementation

### 3.1 Update to Match Python Changes
- [ ] Rename dimensions to match Python (`wealth_quintile` → `wealth`)
- [ ] Reorder columns to canonical schema
- [ ] Add source/notes if available from API

**Files:**
- `R/unicefdata.R` (main R package function)

### 3.2 Testing
- [ ] Run 5 indicators to verify output matches Python
- [ ] Check column counts and names match exactly

---

## Phase 4: Stata Implementation

### 4.1 Major Schema Changes
- [ ] Add missing dimensions to Stata output:
  - [ ] `age` column
  - [ ] `residence` column
  - [ ] `maternal_edu_lvl` column
- [ ] Rename `wealth` → `wealth_quintile` (for consistency with Python/R)
- [ ] Rename `wealth_name` → `wealth_quintile_name`

**Files:**
- `stata/src/u/unicefdata.ado` (main command)
- `stata/src/_/_download_data.ado` (data processing)
- `stata/src/_/_standardize_columns.ado` (column handling, if exists)

### 4.2 Reorder Columns
- [ ] Implement canonical column order in Stata
- [ ] Test export delimited to verify CSV order

### 4.3 Bounds & Metadata
- [ ] Verify `lb`, `ub` columns present (confidence bounds)
- [ ] Verify `source`, `notes` columns present
- [ ] Check `refper`, `status` fields are handled correctly

### 4.4 Testing
- [ ] Run 5 indicators to verify output
- [ ] Compare exact column order with Python/R using script

---

## Phase 5: Validation Suite Updates

### 5.1 ConsistencyChecker Enhancements
- [ ] Update to verify **column order** matches, not just count
- [ ] Add detailed column mismatch reporting (which columns differ, by platform)
- [ ] Add warnings if columns are reordered but otherwise identical

**Files:**
- `validation/scripts/test_all_indicators_comprehensive.py` (ConsistencyChecker class)

### 5.2 Test Script
- [ ] Create standalone schema-verification script
- [ ] Script loads 3 cached CSVs (python/r/stata versions) and compares:
  - Column count
  - Column names (exact match, case-sensitive)
  - Column order
  - Data type consistency (if applicable)

**File to Create:**
- `validation/scripts/verify_schema_consistency.py`

---

## Phase 6: Full Validation Run

- [ ] Run validation suite with 60 indicators and all three languages
  ```bash
  python validation/scripts/test_all_indicators_comprehensive.py \
    --limit 60 --seed 51 --random-stratified --valid-only
  ```
- [ ] Review SUMMARY report for 100% consistency
- [ ] Audit any remaining mismatches as indicator-specific issues

---

## Phase 7: Documentation & Release

- [ ] Update README with canonical schema documentation
- [ ] Update user guides to reference unified schema
- [ ] Create migration guide if backward-breaking changes
- [ ] Document version bump (e.g., 1.5.3 → 2.0.0 if major schema change)
- [ ] Commit with message: `feat: harmonize cross-platform dataset schemas`
- [ ] Tag release (if applicable)

---

## Known Issues & Exceptions

### Indicator-Specific
- [ ] Document any indicators where schema legitimately differs
- [ ] Example: Some indicators may not have age breakdowns (OK if missing in all platforms)

### Platform-Specific
- [ ] Stata may legitimately include extra metadata (source, notes) — OK as long as same columns present in Python/R

---

## Success Criteria

✅ **ALL of the following must be true:**

1. All cached CSV files (Python, R, Stata) for the same indicator have:
   - Same number of columns
   - Same column names (case-sensitive match)
   - Same column order
   
2. Validation suite reports 100% consistency for all tested indicators

3. No blocking errors in ConsistencyChecker output

4. Documentation updated with new unified schema

---

## Timeline Estimate

- Phase 1 (Design): 1 day
- Phase 2 (Python): 2-3 days (mostly refactoring)
- Phase 3 (R): 1-2 days (minor, mostly renaming)
- Phase 4 (Stata): 3-5 days (most complex; new columns to extract)
- Phase 5 (Validation): 1 day
- Phase 6 (Full run): 2-3 days (running full suite)
- Phase 7 (Docs): 1 day

**Total: 11-17 days**

---

## Notes

- Coordinate with Stata data extraction to ensure new columns (age, residence, maternal_edu_lvl) are available from API
- Test incrementally with small indicator samples before running full suite
- Use branch `feat/cross-platform-dataset-schema` to isolate changes

---

*Last updated: 2026-01-14*

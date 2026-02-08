# unicefdata v1.10.0 Release Notes

**Release Date:** January 18, 2026  
**Author:** João Pedro Azevedo (UNICEF)

---

## Summary

This release consolidates significant improvements to the `info()` option, streamlines the post-data-fetch display, adds SDMX dimension code visibility, and removes technical fields from user-facing disaggregation lists.

---

## What Changed and Why

### 1. Unified Information Display Architecture

**Problem:** There were two different information displays:
- After data fetch: Showed Yes/No for disaggregations (outdated format)
- `info()` option: Showed detailed metadata with dimension values

**Solution:** 
- **Post-fetch display** is now streamlined to show essentials only (indicator, dataflow, name, description, observation count)
- **`info()` option** provides the comprehensive metadata view
- A clickable tip now directs users to `info()` for full details

**Files Changed:**
- `unicefdata.ado` - Lines 2114-2156 replaced with streamlined display

**New Post-Fetch Output:**
```
----------------------------------------------------------------------
 Indicator: ED_ANAR_L2  |  Dataflow: EDUCATION
----------------------------------------------------------------------
 Name:         Adjusted net attendance rate for adolescents...
 Description:  Percentage of children of lower secondary...
 Observations: 16
----------------------------------------------------------------------
 Tip: Use unicefdata, info(ED_ANAR_L2) for full metadata, API query, and
   disaggregation codes
----------------------------------------------------------------------
```

### 2. SDMX Dimension Codes Now Visible

**Problem:** Users couldn't see the actual SDMX codes (M, F, Q1, Q2, etc.) needed for API queries.

**Solution:** `info()` now displays both human-readable values AND SDMX codes:

```
 Supported Disaggregations:
   SEX  (with totals)
     Values: Male, Female
     Codes:  M, F, _T (total)
   WEALTH_QUINTILE  (with totals)
     Values: Quintile 1-5
     Codes:  Q1, Q2, Q3, Q4, Q5, _T (total)
```

**Files Changed:**
- `_unicef_indicator_info.ado` v1.10.0 - Added `dim_codes` mapping for each dimension type

### 3. UNIT_MEASURE Excluded from Disaggregations

**Problem:** UNIT_MEASURE appeared in disaggregation lists for EDUCATION indicators, but it's a technical field (percentage vs rate vs count), not a demographic filter like sex or wealth.

**Root Cause:** In some dataflows (like EDUCATION), UNIT_MEASURE is defined as a dimension rather than an attribute. The filter engine was including all dimensions.

**Solution:** `__unicef_get_indicator_filters.ado` now explicitly excludes UNIT_MEASURE:
```stata
if !inlist("`dim_id'", "REF_AREA", "INDICATOR", "TIME_PERIOD", "UNIT_MEASURE") {
    local ++num_filter_dimensions
    ...
}
```

**Files Changed:**
- `__unicef_get_indicator_filters.ado` v0.5.0

### 4. "(with totals)" Display Fixed

**Problem:** When using the `__unicef_get_indicator_filters` subroutine, the "(with totals)" suffix wasn't appearing next to disaggregation names.

**Root Cause:** The `disagg_totals` local wasn't being set when dimensions came from the subroutine.

**Solution:** Set `disagg_totals` to match `disagg_raw` since UNICEF's standard schema supports totals (`_T`) for all filter dimensions.

**Files Changed:**
- `_unicef_indicator_info.ado` v1.9.1 → v1.10.0

---

## Version History (This Session)

| Version | Component | Change |
|---------|-----------|--------|
| v1.10.0 | `_unicef_indicator_info.ado` | Show SDMX codes for each disaggregation dimension |
| v1.9.1 | `_unicef_indicator_info.ado` | Fixed "(with totals)" display when using dataflow schema subroutine |
| v1.9.0 | `_unicef_indicator_info.ado` | Refactored to use `__unicef_get_indicator_filters` subroutine; Added API query URL display |
| v0.5.0 | `__unicef_get_indicator_filters.ado` | Exclude UNIT_MEASURE from filter-eligible dimensions |
| v1.9.1 | `unicefdata.ado` | Streamlined post-fetch display with tip to use `info()` |

---

## Technical Details

### Dimension Code Mappings

| Dimension | Human Values | SDMX Codes |
|-----------|--------------|------------|
| SEX | Male, Female | M, F, _T |
| RESIDENCE | Urban, Rural | U, R, _T |
| WEALTH_QUINTILE | Quintile 1-5 | Q1, Q2, Q3, Q4, Q5, _T |
| AGE | Age groups | Y0T4, Y5T9, Y10T14, Y15T17, Y18T24, _T |
| EDUCATION_LEVEL | ISCED levels | L0_2, L1, L2, L3, _T |
| MATERNAL_EDU_LVL | Education levels | L0_2, L1, L2T8, _T |

### Excluded Dimensions

These dimensions are excluded from "Supported Disaggregations" because they're either:
- **Automatic** (REF_AREA, INDICATOR, TIME_PERIOD) - handled by other options
- **Technical** (UNIT_MEASURE) - not a user-facing demographic filter

---

## Testing

All changes verified with:
```stata
. unicefdata, info(ED_ANAR_L2)   // EDUCATION dataflow - confirms UNIT_MEASURE excluded
. unicefdata, info(CME_MRY0T4)   // CME dataflow - confirms codes displayed
. unicefdata, indicator(ED_ANAR_L2) countries(AFG BGD) clear  // Streamlined display
```

---

## Files Modified

| File | Version | Location |
|------|---------|----------|
| `unicefdata.ado` | v1.9.1 | `stata/src/u/` |
| `_unicef_indicator_info.ado` | v1.10.0 | `stata/src/_/` |
| `__unicef_get_indicator_filters.ado` | v0.5.0 | `stata/src/_/` |
| `UNICEF_Open_Data_API_Comprehensive_Guide.md` | updated | `doc/` |

---

## Sync Status

All files synced to:
- ✅ `unicefData-dev/stata/src/` (development)
- ✅ `unicefData/stata/src/` (public repo)
- ✅ `C:\Users\jpazevedo\ado\plus\` (installed)

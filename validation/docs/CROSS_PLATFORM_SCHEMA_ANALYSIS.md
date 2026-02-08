# Cross-Platform Dataset Schema Analysis

**Date:** January 14, 2026  
**Status:** IN PROGRESS - Harmonization Project

## Problem Statement

Python, R, and Stata wrappers currently generate datasets with different column names and orderings. **The schema differences are DATAFLOW-DEPENDENT:** each platform uses a different mapping from raw SDMX API columns to standardized outputs, leading to inconsistent column presence and naming.

---

## Canonical Schema Definition (From Source Code)

Both **R and Stata have EXPLICIT schema definitions** in their implementation:

### R Definition (unicef_core.R:454-490)

```r
rename_map <- c(
  "indicator" = "INDICATOR", 
  "indicator_name" = "Indicator",
  "iso3" = "REF_AREA", 
  "country" = "Geographic area",
  "unit" = "UNIT_MEASURE", 
  "unit_name" = "Unit of measure",
  "sex" = "SEX", 
  "sex_name" = "Sex",
  "age" = "AGE", 
  "wealth_quintile" = "WEALTH_QUINTILE",
  "wealth_quintile_name" = "Wealth Quintile", 
  "residence" = "RESIDENCE",
  "maternal_edu_lvl" = "MATERNAL_EDU_LVL", 
  "lower_bound" = "LOWER_BOUND",
  "upper_bound" = "UPPER_BOUND", 
  "obs_status" = "OBS_STATUS",
  "obs_status_name" = "Observation Status", 
  "data_source" = "DATA_SOURCE",
  "ref_period" = "REF_PERIOD", 
  "country_notes" = "COUNTRY_NOTES"
)

standard_cols <- c("indicator", "indicator_name", "iso3", "country", "geo_type", "period", "value",
                   "unit", "unit_name", "sex", "sex_name", "age",
                   "wealth_quintile", "wealth_quintile_name", "residence",
                   "maternal_edu_lvl", "lower_bound", "upper_bound",
                   "obs_status", "obs_status_name", "data_source",
                   "ref_period", "country_notes")
```

**KEY:** R **ALWAYS** includes `wealth_quintile` (not `wealth`) and 22 total columns.

### Stata Definition (unicefdata.ado:780-790)

```stata
local renames ""
local renames "`renames' wealth_quintile:wealth WEALTH_QUINTILE:wealth"
local renames "`renames' lower_bound:lb LOWER_BOUND:lb"
local renames "`renames' upper_bound:ub UPPER_BOUND:ub"
local renames "`renames' obs_status:status OBS_STATUS:status"
local renames "`renames' data_source:source DATA_SOURCE:source"
local renames "`renames' ref_period:refper REF_PERIOD:refper"
local renames "`renames' country_notes:notes COUNTRY_NOTES:notes"
local renames "`renames' maternal_edu_lvl:matedu MATERNAL_EDU_LVL:matedu"
```

**KEY:** Stata **RENAMES** columns to shorter names: `wealth_quintile` → `wealth`, `maternal_edu_lvl` → `matedu`, etc.

### Python Definition (Need to find - likely in unicefdata_api.py or similar)

Python likely has similar mappings but may not be following the same schema as R/Stata.

---

## Root Cause Analysis

| Issue | Root Cause | Platform Affected |
|-------|-----------|------------------|
| `wealth_quintile` vs `wealth` | R keeps full name; Stata shortens it | R vs Stata |
| Missing age/residence/maternal_edu in Stata export | CSV export may drop these columns during serialization | Stata |
| Extra columns in Stata (lb, ub, etc.) | Stata renames them; Python/R may not include in export | Stata vs Python/R |
| Column order differs | R/Python: metadata→country→data→dims; Stata: country→metadata→dims→data | All |

---

## The Real Problem: Export Layer Inconsistency

**The schema is DEFINED in code** (R and Stata have explicit mappings), but:

1. **R** produces the defined schema correctly in memory but **exports ALL columns** to CSV
2. **Stata** produces the defined schema correctly in memory but **renames short** and **may drop certain columns** during export
3. **Python** likely has a different mapping altogether

**This is not a data difference—it's an EXPORT/SERIALIZATION difference.**

---

## Implementation Plan - Revised (Dataflow-Aware)

Now that we understand the **schema is defined in code**, the issue is **EXPORT layer inconsistency**, not data fetching.

### Phase 1: Unify Export Schema (Priority: Highest)

**Goal:** All platforms export using the SAME schema with SAME column names and order.

**Decision Point:** Which schema to adopt?
- **Option A:** Adopt R's `wealth_quintile` (longer names, more explicit)
- **Option B:** Adopt Stata's `wealth` (shorter, but diverges from R code)
- **Recommendation:** **Option A** (R's schema) because it's already codified in R source and cleaner names

**Tasks:**
1. **R Export:** Keep current schema—already matches intended output ✅
2. **Stata Export:** Update to use `wealth_quintile`, `maternal_edu_lvl`, etc. (map short names back to long)
3. **Python Export:** Verify matches R schema; fix if divergent

### Phase 2: Fix Stata Export Layer

**Problem:** Stata shortens column names during export.

**Solution:** In `unicefdata.ado`, after data is fetched, before CSV export:
- Create aliases/labels that preserve the full SDMX names
- OR: Rename `wealth` → `wealth_quintile` before export
- Ensure `age`, `residence`, `maternal_edu_lvl` columns are retained in export

**File to Modify:** `stata/src/u/unicefdata.ado` (around line 900+, export section)

### Phase 3: Verify Python Compliance

**File to Check:** `R/unicefdata_api.py` (or equivalent Python wrapper)

- Does Python use the same rename_map as R?
- Does Python include all 22 columns or subset?
- Does Python export column names in correct order?

### Phase 4: Test & Validate

Run 60-indicator validation with all three languages and verify:
- Same column count
- Same column names (case-sensitive)
- Same column order
- All platforms handle missing values consistently

---

---

*Created: 2026-01-14 by cross-platform harmonization project*

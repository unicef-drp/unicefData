# Cross-Platform Schema Recommendation

**Date:** January 14, 2026  
**Branch:** `feat/cross-platform-dataset-schema`

---

## Executive Summary

Based on comparative analysis of:
- **wbopendata** (World Bank API wrapper) — mature, production schema
- **R unicefData** — explicitly defined 22-column schema with rename maps
- **Stata unicefData** — renames to short names, drops columns during export
- **Python unicefData** — (needs verification)

**Recommendation: Adopt a HYBRID schema inspired by wbopendata + R unicefData**

---

## Key Insights from wbopendata

wbopendata uses a **simple, flat, country-centric design:**

```
countrycode, countryname, indicatorcode, indicatorname, year, value, [other fields]
```

**Advantages:**
- ✅ **Simple structure**: 5 core columns that work across ALL indicators
- ✅ **Scalable**: Handles 29,000+ indicators without schema explosion
- ✅ **User-friendly**: Non-technical users understand immediately
- ✅ **Proven in production**: wbopendata has been stable for 15+ years
- ✅ **Multi-language**: Metadata available in EN/ES/FR

**Differences from current unicefData:**
- wbopendata uses `indicatorcode` + `indicatorname` (simpler naming)
- unicefData uses `indicator` + `indicator_name` (shortened codes)
- wbopendata keeps only essential columns; unicefData includes all available dimensions

---

## Recommended Schema for unicefData

**Adopt R's 22-column schema BUT with wbopendata-style naming principles:**

### Standard Columns (Always Present)

```
iso3                    # Country code (3-letter ISO)
country                 # Country name (full)
indicator               # Indicator code (e.g., CME_MRY0T4)
indicator_name          # Indicator name (descriptive)
period                  # Year or time period
value                   # Main observation value
unit                    # Unit code (e.g., "per 1000 live births")
unit_name               # Unit description
```

### Dimension Columns (Present if Available for Indicator)

```
sex                     # Sex code (M/F/T)
sex_name                # Sex label
age                     # Age group code
wealth_quintile         # Wealth quintile code (Q1-Q5 or Total)
wealth_quintile_name    # Wealth quintile label
residence               # Residence type (Urban/Rural)
maternal_edu_lvl        # Maternal education level
```

### Metadata Columns (Present if Available from API)

```
source                  # Data source attribution
notes                   # Country-specific notes
ref_period              # Reference period (if different from observation year)
lower_bound             # Lower confidence bound (if available)
upper_bound             # Upper confidence bound (if available)
obs_status              # Observation status code
obs_status_name         # Observation status label
geo_type                # Geographic type (National/Regional/etc.)
```

### Column Order (Canonical)

```
iso3, country, indicator, indicator_name, period, 
value, unit, unit_name, 
sex, sex_name, age, 
wealth_quintile, wealth_quintile_name, residence, maternal_edu_lvl, 
source, notes, ref_period, lower_bound, upper_bound, 
obs_status, obs_status_name, geo_type
```

---

## Rationale

### Why NOT wbopendata's Full Schema?

| Aspect | wbopendata | unicefData Goal |
|--------|-----------|-----------------|
| **Sources** | 1 (World Bank) | 50+ (UNICEF + partners) |
| **Country attributes** | 17 fields per country | 0 fields (keep lean) |
| **Dimensions** | Indicator-specific | Explicit: sex, age, wealth, residence, maternal_edu |
| **Bounds** | Not standard | Essential (confidence intervals) |

**Conclusion:** wbopendata's simplicity works for WB's single API; unicefData needs richer dimension support.

### Why NOT Stata's Short Names?

Stata currently shortens to:
- `wealth` (instead of `wealth_quintile`)
- `matedu` (instead of `maternal_edu_lvl`)
- `lb`/`ub` (instead of `lower_bound`/`upper_bound`)

**Problems:**
- ❌ Deviates from R code (which uses long names)
- ❌ CSV exports lose clarity (`matedu` ambiguous)
- ❌ Inconsistent with metadata documentation
- ✅ BUT: Stata's short names ARE convenient in Stata itself

**Solution:** Use long names in CSV; Stata can alias them at import.

### Why Adopt R's 22-Column Schema?

1. **Already defined in code** — no ambiguity
2. **Tested and working** — R exports all 22 columns successfully
3. **Comprehensive** — covers all UNICEF dimensions
4. **User-friendly** — clear, descriptive names
5. **Metadata-rich** — includes bounds, status, source

---

## Implementation Strategy

### Phase 1: Adopt R Schema (Days 1-2)

- ✅ R: Keep as-is (already correct)
- 🔄 Python: Verify matches R schema, fix if divergent
- 🔄 Stata: Update CSV export to use full names

### Phase 2: Stata Export Layer Fix (Days 3-5)

**Before CSV export, add rename/alias pass:**

```stata
* Map short names back to long names for export
rename wealth wealth_quintile
rename wealth_name wealth_quintile_name
rename matedu maternal_edu_lvl
rename lb lower_bound
rename ub upper_bound
rename refper ref_period
rename status obs_status
rename status_name obs_status_name
rename source data_source
rename notes country_notes

* Then export as CSV
export delimited using "cache/stata/indicator.csv", replace
```

### Phase 3: Validation & Testing (Days 6-7)

Run 60-indicator validation with all three languages:
- Verify same column count (22)
- Verify same column names
- Verify same column order
- Check null handling consistency

---

## Why This Schema Makes Sense

**Comparison Table:**

| Feature | wbopendata | Current unicefData | Proposed |
|---------|-----------|-----------------|---------|
| **Simple core** | ✅ 5 cols | ❌ No | ✅ 8 cols |
| **Dimensions** | ❌ Limited | ✅ Rich | ✅ Rich |
| **Bounds/Status** | ❌ None | ✅ Yes | ✅ Yes |
| **Production-proven** | ✅ 15 years | ⚠️ Beta | ✅ Inherits R stability |
| **Backward-compatible** | N/A | ⚠️ Breaking | ⚠️ Breaking (but intentional) |

---

## Expected Outcome

**Before:**
```
Python:  indicator, indicator_name, iso3, country, ..., wealth_quintile, ... (16+ cols)
R:       indicator, indicator_name, iso3, country, ..., wealth_quintile, ... (22 cols)
Stata:   iso3, country, indicator, ..., wealth, ... (20 cols, different names/order)
```

**After:**
```
Python:  iso3, country, indicator, indicator_name, period, value, ..., wealth_quintile, ... (22 cols)
R:       iso3, country, indicator, indicator_name, period, value, ..., wealth_quintile, ... (22 cols)
Stata:   iso3, country, indicator, indicator_name, period, value, ..., wealth_quintile, ... (22 cols)
```

✅ **Perfect consistency across all three platforms**

---

## Version & Versioning

- **Current:** v1.5.2 (pre-unification)
- **After Schema Harmonization:** v2.0.0 (major change to schema)
- **Rationale:** Breaking change to CSV schema warrants major version bump

### Release Notes

```
v2.0.0 (2026-01-20)
===================
BREAKING CHANGE: Cross-platform dataset schema unified

- All platforms (Python, R, Stata) now produce identical column names, order, and count
- CSV output schema now: iso3, country, indicator, indicator_name, period, value, 
  unit, unit_name, + 14 optional dimension/metadata columns
- Stata short names (wealth, matedu, lb, ub) now exported as full names 
  (wealth_quintile, maternal_edu_lvl, lower_bound, upper_bound)
- All 22 columns present in all exports for consistency
- Backward-compatible in R/Python (no code changes needed)
- Stata users: No code changes needed; CSV structure improved

Migration: No action needed for users. Updated CSV schema matches R/Python exactly.
```

---

## Contingency: If wbopendata Schema Fits Better

If during implementation we discover unicefData truly needs wbopendata-style simplicity, fall back to:

```
iso3, country, indicator, indicator_name, period, value, 
+ dimension columns only (sex, sex_name, age, wealth_quintile, wealth_quintile_name, etc.)
- drop bounds, status, source, notes initially
```

But **recommendation stands**: Keep all 22 columns for metadata richness.

---

## Next Steps

1. ✅ Present this recommendation to stakeholder
2. ⏳ Get approval on 22-column schema
3. ⏳ Begin Phase 1 (Python verification)
4. ⏳ Proceed to Phase 2 (Stata export layer)
5. ⏳ Execute Phase 3 (validation run)

---

*Recommendation prepared: 2026-01-14*  
*Branch: feat/cross-platform-dataset-schema*

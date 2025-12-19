# Stata `unicefdata` Improvement Plan

## Cross-Language Feature Parity Analysis

This document outlines the improvements needed to align the Stata `unicefdata.ado` command with the Python (`unicef_api`) and R (`unicefData`) implementations.

**Analysis Date:** December 9, 2025  
**Current Stata Version:** 1.2.1  
**Python Version:** 0.3.0  
**R Version:** N/A (source files)

---

## Executive Summary

The Stata `unicefdata` command has **solid core functionality** (data retrieval, filtering, format conversion) but lacks several features available in Python and R:

| Priority | Feature Gap | Impact |
|----------|-------------|--------|
| **HIGH** | No indicator search/discovery | Users can't find indicators |
| **HIGH** | No dataflow listing | Users can't explore available data |
| **HIGH** | No `wide_indicators` format | Can't compare multiple indicators |
| **MEDIUM** | No metadata enrichment | Missing region, income_group columns |
| **MEDIUM** | No dataflow fallback on 404 | Some indicators fail unnecessarily |
| **MEDIUM** | No in-memory caching | Repeated queries hit API each time |
| **LOW** | No vintage comparison | Can't track data changes over time |

---

## Detailed Feature Comparison

### 1. Core Data Retrieval ✅ ALIGNED

All three implementations share:
- Same base function: `unicefdata()` / `unicefData()`
- Same parameter names: `indicator`, `countries`, `start_year`, `end_year`
- Same SDMX API endpoint
- Same output column names: `iso3`, `indicator`, `period`, `value`

| Feature | Python | R | Stata |
|---------|--------|---|-------|
| Single indicator | ✅ | ✅ | ✅ |
| Multiple indicators | ✅ via list | ✅ via vector | ⚠️ Limited |
| Country filter | ✅ | ✅ | ✅ |
| Year range | ✅ | ✅ | ✅ |
| Pagination | ✅ | ✅ | ✅ |
| Retries | ✅ | ✅ | ✅ |

**Stata gap:** Multiple indicators work but can only be from the same dataflow.

---

### 2. Discovery Functions ❌ MISSING IN STATA

Python provides rich discovery:
```python
from unicef_api import list_dataflows, list_indicators, search_indicators

# List all available dataflows
flows = list_dataflows()

# List all indicators in a dataflow
indicators = list_indicators(dataflow="NUTRITION")

# Search indicators by keyword
results = search_indicators("mortality under 5")
```

R is also missing these functions (needs to be added).

**Stata needs:**
- `unicefdata, search(keyword)` - Find indicators by keyword
- `unicefdata, flows` - List available dataflows
- `unicefdata, indicators(dataflow)` - List indicators in a dataflow
- `unicefdata, info(indicator)` - Get indicator metadata

---

### 3. Disaggregation Filters ✅ ALIGNED

All three implementations support the same disaggregation filters:

| Filter | Python | R | Stata |
|--------|--------|---|-------|
| `sex` | ✅ | ✅ | ✅ |
| `age` | ⚠️ Missing | ✅ | ✅ |
| `wealth` | ⚠️ Missing | ✅ | ✅ |
| `residence` | ⚠️ Missing | ✅ | ✅ |
| `maternal_edu` | ⚠️ Missing | ✅ | ✅ |

**Note:** Python is actually behind here! Stata and R have full disaggregation support.

---

### 4. Output Formats ⚠️ PARTIALLY ALIGNED

| Format | Python | R | Stata |
|--------|--------|---|-------|
| `long` (default) | ✅ | ✅ | ✅ |
| `wide` (years as columns) | ✅ | ✅ | ✅ |
| `wide_indicators` (indicators as columns) | ✅ | ⚠️ Partial | ❌ Missing |
| `wide_sex` | ❌ | ✅ | ❌ |
| `wide_age` | ❌ | ✅ | ❌ |

**Stata needs:**
- Add `wide_indicators` option for comparing multiple indicators
- Add `wide_sex` and `wide_age` for disaggregation pivots

---

### 5. Post-Processing Options ⚠️ PARTIALLY ALIGNED

| Option | Python | R | Stata |
|--------|--------|---|-------|
| `latest` (most recent value) | ✅ | ✅ | ✅ |
| `mrv(n)` (n most recent) | ✅ | ✅ | ✅ |
| `dropna` | ✅ | ✅ | ✅ |
| `simplify` | ✅ | ✅ | ✅ |
| `raw` | ✅ | ✅ | ✅ |

**Status:** Fully aligned! 🎉

---

### 6. Metadata Enrichment ❌ MISSING IN STATA

Python's `add_metadata` parameter:
```python
df = unicefData(
    indicator="CME_MRY0T4",
    add_metadata=["region", "income_group", "continent"]
)
# Result includes: iso3, country, region, income_group, continent, ...
```

| Metadata | Python | R | Stata |
|----------|--------|---|-------|
| `region` | ✅ | ✅ | ❌ |
| `income_group` | ✅ | ✅ | ❌ |
| `continent` | ✅ | ✅ | ❌ |
| `indicator_name` | ✅ | ✅ | ✅ |
| `geo_type` | ❌ | ✅ | ❌ |

**Stata needs:**
- Add `addmeta` option to include region, income_group
- Load metadata from YAML or embedded lookup table

---

### 7. Error Handling ⚠️ PARTIALLY ALIGNED

| Feature | Python | R | Stata |
|---------|--------|---|-------|
| Basic error messages | ✅ | ✅ | ✅ |
| Dataflow 404 fallback | ✅ | ❌ | ❌ |
| Detailed SDMX error parsing | ✅ | ⚠️ | ⚠️ |
| Indicator validation | ✅ | ⚠️ | ⚠️ |

**Stata needs:**
- When auto-detected dataflow returns 404, try alternative dataflows
- Parse SDMX error responses for better messages

---

### 8. Caching ⚠️ PARTIAL IN STATA

| Caching | Python | R | Stata |
|---------|--------|---|-------|
| YAML metadata cache | ✅ | ✅ | ✅ |
| In-memory cache | ✅ | ✅ (memoise) | ❌ |
| Cache data results | ⚠️ | ⚠️ | ❌ |

**Stata needs:**
- Consider `tempfile` caching for repeated queries in same session
- Or document that users should save results to disk

---

### 9. Vintage/Version Control ❌ MISSING IN STATA

Python provides:
```python
from unicef_api import list_vintages, compare_vintages

# List all metadata versions
vintages = list_vintages()

# Compare changes between versions
changes = compare_vintages("2024-01-15", "2024-06-30")
```

**Stata needs:** Not critical, but could add `unicefdata, vintage` subcommand.

---

## Implementation Roadmap

### Phase 1: Critical Missing Features (HIGH Priority)

#### 1.1 Discovery Subcommands

Add new subcommands to enable indicator discovery:

```stata
* List available dataflows
unicefdata, flows

* Search indicators by keyword
unicefdata, search("mortality")
unicefdata, search("nutrition")

* List indicators in a dataflow
unicefdata, indicators(NUTRITION)
unicefdata, indicators(CME)

* Get indicator info
unicefdata, info(CME_MRY0T4)
```

**Implementation:**
1. Create `_unicef_list_dataflows.ado` helper
2. Create `_unicef_search_indicators.ado` helper
3. Parse YAML metadata for searches
4. Add new syntax parsing in `unicefdata.ado`

#### 1.2 Wide Indicators Format

Add `wide_indicators` option for comparing multiple indicators:

```stata
* Current (fails or produces odd results)
unicefdata, indicator(CME_MRY0T4 NT_ANT_HAZ_NE2_MOD) wide

* New: wide with indicators as columns
unicefdata, indicator(CME_MRY0T4 NT_ANT_HAZ_NE2_MOD) wide_indicators
```

**Implementation:**
```stata
* In unicefdata.ado, after data retrieval
if ("`wide_indicators'" != "") {
    keep iso3 country period indicator value
    reshape wide value, i(iso3 country period) j(indicator) string
    rename value* *
}
```

---

### Phase 2: Enhanced Functionality (MEDIUM Priority)

#### 2.1 Metadata Enrichment

Add `addmeta()` option:

```stata
unicefdata, indicator(CME_MRY0T4) addmeta(region income_group)
```

**Implementation:**
1. Create `metadata/country_regions.dta` lookup table
2. Merge after data retrieval:
```stata
if ("`addmeta'" != "") {
    merge m:1 iso3 using "`metadata_path'country_regions.dta", keepusing(region income_group) nogen keep(1 3)
}
```

#### 2.2 Dataflow Fallback

When auto-detected dataflow returns 404, try alternatives:

```stata
* In _unicef_detect_dataflow_yaml, add fallback logic
local alternatives "GLOBAL_DATAFLOW"
if (substr("`indicator'", 1, 2) == "ED") {
    local alternatives "EDUCATION_UIS_SDG EDUCATION GLOBAL_DATAFLOW"
}
foreach df of local alternatives {
    capture copy "`url'" "`tempfile'"
    if (_rc == 0) {
        local dataflow "`df'"
        continue, break
    }
}
```

#### 2.3 Geo Type Column

Add `geo_type` classification (country vs aggregate):

```stata
* After data retrieval
gen geo_type = ""
* Mark known aggregates
replace geo_type = "aggregate" if inlist(iso3, "UNICEF", "WB", "WORLD")
replace geo_type = "country" if geo_type == ""
label variable geo_type "Geographic type (country/aggregate)"
```

---

### Phase 3: Nice-to-Have Features (LOW Priority)

#### 3.1 Additional Wide Formats

```stata
unicefdata, indicator(CME_MRY0T4) wide_sex    // Sex as columns
unicefdata, indicator(CME_MRY0T4) wide_age    // Age groups as columns
```

#### 3.2 Session Caching

Cache API results within a Stata session:

```stata
* Create global macro with cached file path
global unicef_cache_CME_MRY0T4 = "`tempfile'"

* On subsequent calls, check cache first
if ("$unicef_cache_`indicator'" != "") {
    use "$unicef_cache_`indicator'", clear
}
```

#### 3.3 Vintage Commands

```stata
unicefdata, vintage list              // List available vintages
unicefdata, vintage compare(v1 v2)    // Compare two vintages
```

---

## Detailed Implementation Guide

### File Changes Required

1. **`unicefdata.ado`** - Main command
   - Add `flows`, `search`, `indicators`, `info` subcommands
   - Add `wide_indicators` option
   - Add `addmeta()` option
   - Add geo_type classification

2. **New helper files:**
   - `_unicef_list_dataflows.ado` - Parse dataflows from YAML
   - `_unicef_search_indicators.ado` - Search indicators
   - `_unicef_get_indicator_info.ado` - Get indicator metadata
   - `_unicef_dataflow_fallback.ado` - Handle 404 with alternatives

3. **Metadata files:**
   - `metadata/country_regions.dta` - ISO3 to region/income mapping
   - Update `metadata/dataflows.yaml` with full dataflow list

### Syntax Changes

**Current syntax:**
```stata
unicefdata, indicator(string) [dataflow(string) countries(string) ...]
```

**Proposed extended syntax:**
```stata
unicefdata [subcommand], [options]

* Data retrieval (default)
unicefdata, indicator(string) [options]

* Discovery subcommands
unicefdata, flows                      // List dataflows
unicefdata, search(string)             // Search indicators
unicefdata, indicators(dataflow)       // List indicators in dataflow
unicefdata, info(indicator)            // Get indicator info
```

### Testing Plan

1. **Unit tests** for each new subcommand
2. **Integration tests** comparing output with Python/R
3. **Validation** using `validation/validate_cross_language.py`

---

## Priority Matrix

| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| `search()` subcommand | Medium | High | **P1** |
| `flows` subcommand | Low | High | **P1** |
| `indicators()` subcommand | Medium | High | **P1** |
| `wide_indicators` option | Low | Medium | **P2** |
| `addmeta()` option | Medium | Medium | **P2** |
| Dataflow fallback | Medium | Medium | **P2** |
| `geo_type` column | Low | Low | **P3** |
| Additional wide formats | Medium | Low | **P3** |
| Session caching | High | Low | **P3** |

---

## Next Steps

1. **Immediate (Week 1):**
   - Implement `flows` subcommand (simplest)
   - Implement `search()` subcommand using YAML

2. **Short-term (Week 2-3):**
   - Implement `indicators()` and `info()` subcommands
   - Implement `wide_indicators` option
   - Add dataflow fallback logic

3. **Medium-term (Week 4+):**
   - Add `addmeta()` with region/income lookup
   - Add `geo_type` classification
   - Create comprehensive test suite

---

## Appendix: Code Snippets

### A. List Dataflows Implementation

```stata
*******************************************************************************
* unicefdata_flows.ado - List available UNICEF dataflows
*******************************************************************************
program define unicefdata_flows, rclass
    version 14.0
    
    syntax [, VERBOSE]
    
    * Find metadata path
    findfile dataflows.yaml, path("`c(sysdir_plus)'u/metadata/")
    local yaml_file "`r(fn)'"
    
    * Read YAML and display
    tempfile df_list
    
    * Use Python bridge or mata to parse YAML
    python: import yaml
    python: with open("`yaml_file'") as f: data = yaml.safe_load(f)
    python: print(f"Found {len(data['dataflows'])} dataflows")
    
    * Display results
    noi di as text "{hline 70}"
    noi di as text "Available UNICEF Dataflows"
    noi di as text "{hline 70}"
    noi di as text "ID" _col(25) "Name"
    noi di as text "{hline 70}"
    
    * Loop through dataflows...
    
end
```

### B. Search Indicators Implementation

```stata
*******************************************************************************
* _unicef_search_indicators.ado - Search indicators by keyword
*******************************************************************************
program define _unicef_search_indicators, rclass
    version 14.0
    
    syntax , KEYword(string) [LIMIT(integer 20)]
    
    * Load indicators from YAML
    findfile indicators.yaml, path("`c(sysdir_plus)'u/metadata/")
    local yaml_file "`r(fn)'"
    
    * Search logic
    preserve
    clear
    
    * Parse YAML into dataset
    * (Implementation depends on yaml.ado availability)
    
    * Filter by keyword (case-insensitive)
    local keyword_lower = lower("`keyword'")
    keep if strpos(lower(name), "`keyword_lower'") > 0 | ///
            strpos(lower(indicator), "`keyword_lower'") > 0
    
    * Display results
    if (_N == 0) {
        noi di as text "No indicators found matching '`keyword'"
    }
    else {
        noi di as text "{hline 70}"
        noi di as text "Indicators matching '`keyword'"
        noi di as text "{hline 70}"
        list indicator name dataflow in 1/`limit', noobs
    }
    
    restore
end
```

### C. Wide Indicators Implementation

```stata
* Add to unicefdata.ado after data retrieval
if ("`wide_indicators'" != "") {
    * Ensure we have required variables
    capture confirm variable iso3 period indicator value
    if (_rc != 0) {
        noi di as err "Cannot reshape: missing required variables"
        exit 198
    }
    
    * Keep essential columns for reshape
    keep iso3 country period indicator value
    
    * Reshape: indicators become columns
    reshape wide value, i(iso3 country period) j(indicator) string
    
    * Clean up column names (remove "value" prefix)
    foreach v of varlist value* {
        local newname = subinstr("`v'", "value", "", 1)
        rename `v' `newname'
    }
    
    sort iso3 period
    
    if ("`verbose'" != "") {
        noi di as text "Reshaped to wide_indicators format."
    }
}
```

---

*Document generated by cross-language validation analysis*

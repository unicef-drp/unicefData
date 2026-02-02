# Legacy Wide Option Implementation (DEPRECATED)

**Date Deprecated:** January 2026  
**Replacement:** Use `get_sdmx` command with `wide` option instead  
**Archive Location:** `stata/src/_/_archive/deprecated_2026/`  
**Original Location:** `stata/src/u/unicefdata.ado` (lines 2185-2440, removed in v1.10.1)

---

## Overview

The `wide` option in `unicefdata` command used **Stata-side data reshaping** (the `reshape` command) to convert long format SDMX data to wide format with years as columns. This implementation has been **deprecated in favor of the API-native csv-ts format**.

## Why Deprecation?

| Aspect | Old Approach (reshape) | New Approach (csv-ts API) |
|--------|------------------------|--------------------------|
| **Performance** | Slower (reshape overhead) | Faster (API-native format) |
| **Efficiency** | Requires round-trip to Stata memory | Direct API response |
| **Scalability** | Limited by Stata's memory/reshape limits | Handled by API infrastructure |
| **Reliability** | Subject to reshape edge cases (duplicates, etc.) | Consistent API response format |

## Implementation Details (Archived)

### Algorithm

The deprecated `wide` option (lines 2370-2440 in old unicefdata.ado) implemented:

1. **Build alias_id** (iso3 + indicator + disaggregation variables)
   - Example: `BRA_CME_MRY0T4_T_0_0_URBAN`

2. **Preserve metadata**
   - Save country, sex, age, wealth, residence, maternal education columns
   - Merge back after reshape

3. **Reshape to wide**
   - Input: Long format (iso3, period, value)
   - Command: `reshape wide value, i(alias_id) j(period)`
   - Output: `alias_id` row with columns `value2019`, `value2020`, etc.

4. **Rename columns to yr#### format**
   - Loop over `ds value*` and rename each to `yr####`
   - Example: `value2020` → `yr2020`

5. **Merge back metadata**
   - Restore country, indicator, sex, age, wealth, residence columns
   - Full data context restored

### Code Snapshot

The original implementation (lines 2370-2440) is preserved below for reference:

```stata
else if ("`wide'" != "") {
    * Reshape to wide format (years as columns with yr prefix)
    * Result: iso3, country, indicator, sex, wealth, age, residence, etc., and columns like yr2019, yr2020, yr2021
    capture confirm variable iso3
    capture confirm variable period
    capture confirm variable indicator
    capture confirm variable value
    if (_rc == 0) {
        * Build alias_id from iso3, indicator, and any non-missing disaggregations
        capture confirm variable alias_id
        if (_rc != 0) {
            gen str200 alias_id = iso3 + "_" + indicator
            foreach v in sex age wealth residence matedu {
                capture confirm variable `v'
                if (_rc == 0) {
                    replace alias_id = alias_id + "_" + `v' if length(`v') > 0
                }
            }
        }

        * Preserve identifier metadata to merge back after reshape
        preserve
        local meta_vars "alias_id iso3 country indicator"
        foreach v in sex age wealth residence matedu {
            capture confirm variable `v'
            if (_rc == 0) local meta_vars "`meta_vars' `v'"
        }
        keep `meta_vars'
        duplicates drop alias_id, force
        tempfile alias_meta
        save `alias_meta', replace
        restore

        * Ensure period is numeric for reshape j()
        capture confirm numeric variable period
        if (_rc != 0) {
            cap destring period, replace
        }

        * Keep only alias_id, period and value for pivot
        local __wide_ready 1
        capture keep alias_id period value
        if (_rc != 0) {
            noi di as text "Note: Required variables missing for wide reshape; leaving data in long format."
            local __wide_ready 0
        }

        if "`__wide_ready'" == "1" {
            * Ensure uniqueness on alias_id × period
            capture duplicates drop alias_id period, force
            sort alias_id period
            by alias_id period: gen byte __first_key = _n==1
            keep if __first_key
            drop __first_key
        }

        if "`__wide_ready'" == "1" {
            * Reshape: years become columns (period is numeric)
            capture reshape wide value, i(alias_id) j(period)
            if (_rc == 0) {
                * Rename value* variables to have yr prefix
                quietly ds value*
                foreach var in `r(varlist)' {
                    local year = subinstr("`var'", "value", "", 1)
                    rename `var' yr`year'
                }
                * Merge back metadata
                capture merge 1:1 alias_id using `alias_meta'
                if (_rc == 0) {
                    drop _merge
                    sort iso3 indicator
                }
                else {
                    noi di as text "Note: Metadata merge failed; proceeding without merged identifiers."
                }
            }
            else {
                noi di as text "Note: Could not reshape to wide format (years as columns)."
            }
        }
    }
}
```

## Example Usage (Deprecated)

```stata
// OLD USAGE (unicefdata with wide option)
unicefdata, indicator(CME_MRY0T4) countries(BRA MEX) wide

// Result:
// iso3  country  indicator  yr2015  yr2016  yr2017  yr2018  yr2019  yr2020
// BRA   Brazil   CME_MRY0T4  7.2     6.8     6.3     5.9     5.4     5.0
// MEX   Mexico   CME_MRY0T4  5.1     4.9     4.7     4.5     4.3     4.1
```

## New Usage (Recommended)

```stata
// NEW USAGE (get_sdmx with wide option)
get_sdmx, indicator(CME_MRY0T4) countries(BRA MEX) wide

// Result:
// iso3  indicator  yr2015  yr2016  yr2017  yr2018  yr2019  yr2020
// BRA   CME_MRY0T4  7.2     6.8     6.3     5.9     5.4     5.0
// MEX   CME_MRY0T4  5.1     4.9     4.7     4.5     4.3     4.1
```

## Advantages of New csv-ts Format

1. **Performance:**
   - API handles pivoting (no Stata reshape overhead)
   - Data arrives already in wide format
   - No preserve/restore cycle needed

2. **Simplicity:**
   - get_sdmx passes `format=csv-ts` to API
   - Only one reshape command (in API, not Stata)
   - Fewer edge cases and error handling

3. **Consistency:**
   - API-native format across all client languages (Python, R, Stata)
   - Guaranteed column consistency
   - No duplicate handling edge cases

4. **Scalability:**
   - API infrastructure handles memory-intensive reshapes
   - No Stata memory constraints
   - Works seamlessly for large requests

## Migration Guide

### For Existing Code

Replace this:
```stata
unicefdata, indicator(CME_MRY0T4 MMR ARTSM0T14 GHE_HE0 UIS_1_ALCA_GPI) ///
    countries(BRA MEX ARG COL ECU) wide

// Or with wide_indicators
unicefdata, indicator(CME_MRY0T4 MMR ARTSM0T14) ///
    countries(BRA MEX) wide_indicators
```

With this:
```stata
get_sdmx, indicator(CME_MRY0T4 MMR ARTSM0T14 GHE_HE0 UIS_1_ALCA_GPI) ///
    countries(BRA MEX ARG COL ECU) wide

// For indicator-column format, use wide with attributes:
get_sdmx, indicator(CME_MRY0T4 MMR ARTSM0T14) ///
    countries(BRA MEX) wide
```

### Behavior Differences

| Feature | Old unicefdata wide | New get_sdmx wide |
|---------|---------------------|-------------------|
| **Row structure** | iso3, country, indicator, disaggregation vars | iso3, indicator, disaggregation vars |
| **Column naming** | yr2015, yr2016 (same) | yr2015, yr2016 (same) |
| **Metadata** | country names included in rows | not included (use addmeta option) |
| **Missing values** | Sparse format (empty cells) | Sparse format (same) |
| **Performance** | 2-5 seconds | <1 second |
| **API format** | csv (long) + Stata reshape | csv-ts (wide, native) |

## Related Files

- **Deprecation Notice:** Added to unicefdata.ado line 2000-2015 (warning message)
- **Archive Parent:** `stata/src/_/_archive/deprecated_2026/README.md`
- **New Implementation:** `stata/src/g/get_sdmx.ado` (lines 217-225, 735-740, 855-875)

## Questions?

See the API primer documentation or contact the package maintainer.

---

*Last Updated: January 2026*  
*Version: 1.0 (Archive of unicefdata.ado v1.10.0 wide option)*


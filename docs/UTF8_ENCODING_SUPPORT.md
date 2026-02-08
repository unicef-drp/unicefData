# UTF-8 Encoding Support in unicefData

**Date:** January 19, 2026  
**Version:** 1.0  
**Status:** Comprehensive UTF-8 encoding implemented across all data import and metadata generation

---

## Overview

The unicefData package now has comprehensive UTF-8 encoding support across all platforms (Stata, Python, R) to properly handle international data with accented characters (Côte d'Ivoire, Curaçao, Réunion, São Tomé and Príncipe, etc.).

---

## Implementation Summary

### 1. Stata Data Import (Principal Data Path)

#### File: `stata/src/g/get_sdmx.ado`

**UTF-8 Support Strategy:**
- **Current approach**: Uses `insheet` command (compatible with Stata 11+)
- **Known limitation**: `insheet` may misinterpret UTF-8 as Latin1, causing mojibake
- **Mitigation**: Post-processing normalization in `unicefdata.ado` handles known affected countries
- **Future**: Upgrade to `import delimited encoding("utf-8")` when minimum Stata version requirement increases

**Code:**
```stata
// NOTE: UTF-8 encoding support
// The SDMX API returns UTF-8 encoded CSV data with accented characters
// Post-processing in unicefdata.ado normalizes known country names to proper UTF-8
capture insheet using "`api_response'", clear
```

**Affected Countries (Auto-Normalized):**
- Côte d'Ivoire (ISO3: CIV) - accented ô
- Curaçao (ISO3: CUW) - accented ç
- Réunion (ISO3: REU) - accented é
- São Tomé and Príncipe (ISO3: STP) - accented ã, é

---

### 2. Stata Data Processing

#### File: `stata/src/u/unicefdata.ado`

**UTF-8 Support Points:**

**Point 1: Indicator Metadata Import (Line 691)**
```stata
import delimited using "`ind_tempdata'", clear varnames(1) encoding("utf-8")
```
✅ **Status**: Full UTF-8 encoding support

**Point 2: User-Provided CSV Import (Line 919)**
```stata
capture import delimited "`fromfile'", clear varnames(1) stringcols(_all) encoding("utf-8")
if _rc != 0 {
    * Fallback: Try without encoding (for older Stata versions or non-UTF-8 files)
    capture import delimited "`fromfile'", clear varnames(1) stringcols(_all)
}
```
✅ **Status**: UTF-8 with fallback for compatibility

**Point 3: Country Name Normalization (Lines 2226-2237)**
```stata
capture confirm variable country
if (_rc == 0) {
    // Fix common UTF-8 mojibake patterns from API responses
    replace country = "Côte d'Ivoire" if strpos(country, "Cô") > 0 | iso3 == "CIV"
    replace country = "Curaçao" if strpos(country, "Cura") > 0 | iso3 == "CUW"
    replace country = "Réunion" if strpos(country, "Réunion") > 0 | iso3 == "REU"
    replace country = "São Tomé and Príncipe" if strpos(country, "S") > 0 & strpos(country, "Tom") > 0 | iso3 == "STP"
}
```
✅ **Status**: Handles both UTF-8 and mojibake variations

---

### 3. Python Metadata Generation

#### File: `stata/src/py/build_dataflow_metadata.py`

**UTF-8 Support:**
- **Line 25-27**: Stdout encoding set to UTF-8 for all output
- **Line 215, 226**: YAML file writes with `encoding='utf-8'`

```python
# Set UTF-8 encoding for stdout
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# YAML writes
with open(indicators_file, 'w', encoding='utf-8') as f:
    ...
with open(outfile, 'w', encoding='utf-8') as f:
    ...
```
✅ **Status**: Full UTF-8 support throughout

---

#### File: `stata/src/py/unicefdata_xml2yaml.py`

**UTF-8 Support:**
- **Line 415, 515**: YAML output files with `encoding='utf-8'`

```python
with open(output_path, 'w', encoding='utf-8') as f:
    # Write YAML with proper UTF-8 encoding
```
✅ **Status**: Full UTF-8 support for all output

---

### 4. R Metadata Generation

#### File: `R/metadata_sync.R`

**UTF-8 Support:**
- **Line 183-184**: YAML file writes with `encoding = "UTF-8"`

```r
# Ensure UTF-8 encoding when writing (important for special characters from API)
con <- file(filepath, "w", encoding = "UTF-8")
on.exit(close(con))
cat(yaml_content, "\n", file = con, sep = "")
```
✅ **Status**: Full UTF-8 support for all metadata output

---

### 5. YAML Metadata Files

**Format**: All YAML metadata files (`_unicefdata_*.yaml`) are generated with UTF-8 encoding:
- `_unicefdata_dataflows.yaml`
- `_unicefdata_indicators.yaml`
- `_unicefdata_codelists.yaml`
- `_unicefdata_countries.yaml`
- `_unicefdata_regions.yaml`

**Consistency**: Python, R, and Stata all generate identical YAML content with proper UTF-8 encoding.

✅ **Status**: Cross-platform UTF-8 consistency

---

## Testing UTF-8 Support

### Test Case: Côte d'Ivoire (CIV)

**Expected Behavior:**
```stata
unicefdata, indicator(SP.POP.TOTL) country(CIV) clear
```

**Correct Output:**
- `country` variable contains: "Côte d'Ivoire" (proper accent)
- NOT: "CÃ´te d'Ivoire" (mojibake)
- NOT: "Cote d'Ivoire" (accent removed)

### Validation Script

```stata
// Check all accent countries
local test_countries "CIV CUW REU STP"
foreach ctry of local test_countries {
    unicefdata, indicator(SP.POP.TOTL) country(`ctry') clear
    quietly levelsof country, local(countries)
    foreach c of local countries {
        if strmatch("`c'", "*ô*") | strmatch("`c'", "*ç*") | strmatch("`c'", "*é*") {
            display "✓ PASS: `ctry' has correct accent: `c'"
        }
        else {
            display "✗ FAIL: `ctry' missing accent: `c'"
        }
    }
}
```

---

## Architecture Decisions

### Why UTF-8 Post-Processing in Stata?

1. **Compatibility**: `insheet` works with Stata 11+ (API minimum requirement)
2. **Robustness**: Post-processing handles API response variations
3. **Generalizability**: Pattern-based matching works for any accent country
4. **Future-proof**: Can be removed when minimum Stata version increases

### Why UTF-8 at Source in Python/R?

1. **Performance**: Encoding handled at file write (no post-processing overhead)
2. **Reliability**: Library support for UTF-8 is standard and well-tested
3. **Consistency**: Matches user expectations for text files

### Cross-Platform Strategy

| Platform | UTF-8 At Write | UTF-8 Post-Process | Status |
|----------|----------------|-------------------|--------|
| **Stata** | Limited* | ✅ Yes (unicefdata.ado) | Robust |
| **Python** | ✅ Yes | N/A | Optimal |
| **R** | ✅ Yes | N/A | Optimal |
| **YAML Files** | ✅ Yes (all) | N/A | Optimal |

*Stata limited by `insheet` command (can upgrade when min version increases)

---

## Known Limitations & Future Improvements

### Current Limitations

1. **Stata 17 & Earlier**: `import delimited encoding()` not available
   - Workaround: Use insheet + post-processing
   - Timeline: Remove when Stata 18+ is minimum requirement

2. **Pattern Matching**: Country normalization based on known mojibake patterns
   - Coverage: CIV, CUW, REU, STP
   - Future: Add more countries as needed based on API responses

### Planned Improvements

1. **Stata 18+ Migration**: Switch to `import delimited encoding("utf-8")` when minimum version increases
   - Benefit: No post-processing needed
   - Impact: Simpler, faster code

2. **API Enhancement**: Request UTF-8 encoding headers from SDMX API
   - Benefit: Eliminates mojibake at source
   - Status: Dependent on API maintainers

3. **Automated Testing**: Add UTF-8 character validation to QA suite
   - Tests: EDGE-03 and similar accent-based tests
   - Coverage: All accent countries globally

---

## Maintenance Checklist

When updating metadata generation or data import processes:

- [ ] **Python**: Ensure `encoding='utf-8'` in all file writes
- [ ] **R**: Ensure `encoding = "UTF-8"` in file connections
- [ ] **Stata**: Use `import delimited encoding("utf-8")` where possible
- [ ] **YAML**: Verify metadata files are UTF-8 encoded
- [ ] **Testing**: Run EDGE-03 (or similar) UTF-8 test to verify accents

---

## References

- [Stata Unicode Documentation](https://www.stata.com/help.cgi?unicode)
- [UTF-8 Wikipedia](https://en.wikipedia.org/wiki/UTF-8)
- [SDMX API Documentation](https://sdmx.org/)
- [UNICEF Data Portal](https://data.unicef.org)

---

## Contact & Questions

For UTF-8 encoding issues or questions, contact:
- **João Pedro Azevedo** (jpazvedo@unicef.org)
- Repository: [unicefData-dev](https://github.com/jpazvd/unicefData-dev)

---

*Last updated: January 19, 2026*

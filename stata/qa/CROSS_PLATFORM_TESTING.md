# Cross-Platform Consistency Testing (XPLAT Tests)

**Category 6: XPLAT-01 through XPLAT-05**  
**Priority: CRITICAL for multi-platform reproducibility**  
**Last Updated: January 6, 2026**

---

## Overview

The unicefData package is available in three platforms:
- **Python** (`unicef_api` library)
- **R** (`unicefData` package)
- **Stata** (`unicefdata` command)

Cross-platform consistency tests (XPLAT) ensure that all three implementations:
1. Use the same metadata sources
2. Return identically structured data
3. Apply the same variable naming conventions
4. Format numeric values consistently
5. Support reproducible cross-platform workflows

---

## Why Cross-Platform Testing Matters

### User Impact
- **Reproducibility**: Code examples work across platforms
- **Collaboration**: Teams using different tools get same results
- **Training**: Documentation applies to all platforms
- **Validation**: Results can be verified across implementations

### Technical Impact
- **Data Integrity**: Inconsistencies reveal API parsing bugs
- **Metadata Sync**: Catches divergence in metadata updates
- **API Changes**: Detects when SDMX API format changes
- **Regression Detection**: Identifies when updates break compatibility

---

## Test Suite

### XPLAT-01: Metadata YAML File Consistency

**Purpose**: Verify that all three platforms generate compatible metadata YAML files.

**Files Compared**:
```
Python:  C:\GitHub\myados\unicefData\python\metadata\current\_unicefdata_countries.yaml
R:       C:\GitHub\myados\unicefData\R\metadata\current\_unicefdata_countries.yaml
Stata:   C:\GitHub\myados\unicefData\stata\src\_\_unicefdata_countries.yaml
```

**What's Tested**:
- All three YAML files exist
- Country counts match across platforms
- Dataflow counts match across platforms
- Sample countries (USA, BRA, IND, GBR) present in all
- YAML structure is parseable by yaml.ado

**Expected Country Count**: ~453 countries

**Debug Steps if Fails**:
1. Check file existence in each directory
2. Parse country count from each YAML:
   - Python/R: `_metadata.total_countries`
   - Stata: `metadata.countrie_count` (note typo)
3. If counts differ, check sync timestamps
4. Re-sync metadata for divergent platform

**Re-sync Commands**:
```bash
# Python
cd C:\GitHub\myados\unicefData\python
python sync_metadata.py

# R
cd C:\GitHub\myados\unicefData\R
Rscript sync_metadata.R

# Stata
do C:\GitHub\myados\unicefData\stata\src\_\_unicefdata_sync_dataflow_index.do
```

---

### XPLAT-02: Variable Naming Consistency

**Purpose**: Verify all platforms use the same variable names for downloaded data.

**Convention**: All lowercase, human-readable names (not SDMX uppercase)

**Required Variables** (all platforms):
| Variable | Description | Type |
|----------|-------------|------|
| `iso3` | ISO 3166-1 alpha-3 country code | string |
| `country` | Country name | string |
| `period` | Year (integer) | numeric |
| `indicator` | Indicator code | string |
| `value` | Measurement value | numeric |

**Disaggregation Variables** (when applicable):
| Variable | SDMX Dimension | Values |
|----------|----------------|--------|
| `sex` | SEX | F, M, _T |
| `wealth` | WEALTH_QUINTILE | Q1-Q5, B20, B40, B60, B80, R20-R80, _T |
| `residence` | RESIDENCE | U (urban), R (rural), _T (total) |

**Forbidden Variable Names** (SDMX uppercase):
- ❌ `REF_AREA` (use `iso3`)
- ❌ `TIME_PERIOD` (use `period`)
- ❌ `OBS_VALUE` (use `value`)
- ❌ `INDICATOR` (use `indicator`)
- ❌ `SEX` (use `sex`)

**Test Method**:
1. Download same indicator in Stata: `CME_MRY0T4`
2. Check for expected variables: `iso3`, `country`, `period`, `indicator`, `value`
3. Verify SDMX names NOT present
4. Compare with Python/R column names (manual verification)

**Debug Steps if Fails**:
1. Download same data in each platform:
   ```python
   # Python
   from unicef_api import unicef_api
   df = unicef_api.get_data("CME_MRY0T4", countries=["USA"], years=[2020])
   print(df.columns)
   ```
   ```r
   # R
   library(unicefData)
   df <- get_unicef("CME_MRY0T4", countries="USA", years=2020)
   names(df)
   ```
   ```stata
   * Stata
   unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) clear
   describe
   ```
2. Compare column/variable names directly
3. If differ, check variable mapping in each codebase:
   - Python: `unicef_api/client.py` (REF_AREA -> iso3 mapping)
   - R: `R/get_unicef.R` (variable renaming)
   - Stata: `src/_api_read.ado` (variable assignment)

---

### XPLAT-03: Numerical Formatting Consistency

**Purpose**: Verify numeric values formatted identically across platforms.

**What's Tested**:
- `value`: Numeric type (not string)
- `period`: Numeric integer type
- Missing values: Properly represented (not as strings or zeros)
- Value ranges: Reasonable (e.g., mortality 0-1000 per 1000 live births)

**Numeric Type Requirements**:
| Platform | value | period |
|----------|-------|--------|
| Python | float64 | int64 |
| R | numeric | integer |
| Stata | float/double | byte/int/long |

**Missing Value Representations**:
| Platform | Representation |
|----------|----------------|
| Python | `NaN` (not `None`, `'NULL'`, `''`) |
| R | `NA` (not `NULL`, `'NA'`) |
| Stata | `.` (not `0`, `-999`, `''`) |

**Test Method**:
1. Download: `CME_MRY0T4`, countries(USA BRA), year(2018:2020)
2. Verify `value` is numeric (not string)
3. Verify `period` is numeric integer
4. Check period values are integers (no 2020.5, 2020.25)
5. Check value ranges (0-1000 for mortality rates)

**Debug Steps if Fails**:
1. Check data types in each platform
2. Compare precision (decimal places)
3. Inspect missing value handling
4. Check for string corruption ("NULL", "NA", "")

---

### XPLAT-04: Country Code Consistency

**Purpose**: Verify all platforms use identical ISO 3166-1 alpha-3 country codes.

**Standard**: ISO 3166-1 alpha-3 (3-character codes: USA, BRA, IND)

**Test Countries** (sample verification):
| Code | Name | Present in All? |
|------|------|-----------------|
| USA | United States of America | ✓ |
| BRA | Brazil | ✓ |
| IND | India | ✓ |
| GBR | United Kingdom | ✓ |
| DEU | Germany | ✓ |

**Test Method**:
1. Check each test country exists in all three YAML files
2. Verify code format: exactly 3 uppercase characters
3. Compare country names (should be identical or close variants)

**Debug Steps if Fails**:
1. Query country from each YAML file:
   ```stata
   yaml query countries.USA using "path/to/_unicefdata_countries.yaml"
   ```
2. Compare country names (spelling may vary slightly)
3. If codes differ:
   - Check if using alpha-2 (US) instead of alpha-3 (USA)
   - Review country code extraction in API client
4. If names differ significantly:
   - Check SDMX source field (name vs description)
   - Review YAML sync scripts

**SDMX Source**:
```
https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_COUNTRY/latest
```

---

### XPLAT-05: Data Structure Alignment

**Purpose**: Verify all platforms return data in the same structure for identical queries.

**What's Tested**:
- Row counts: Same N for same query
- Column presence: All expected variables present
- Disaggregation variables: Present when applicable
- No extra/missing columns

**Test Query**:
```
Indicator: CME_MRY0T4 (Under-5 mortality)
Countries: USA, BRA
Year: 2020
```

**Expected Structure**:
- **Rows**: 6-12 observations (2 countries × 3 sex values × 1-2 years)
- **Core Columns**: iso3, country, period, indicator, value
- **Disaggregation**: sex (F, M, _T)

**Test Method**:
1. Download identical query in Stata
2. Count rows (_N)
3. Verify core variables present
4. Check disaggregation variables (sex, wealth if applicable)

**Debug Steps if Fails**:
1. Download identical query in each platform
2. Compare row counts:
   ```python
   # Python
   print(f"Rows: {len(df)}")
   ```
   ```r
   # R
   cat(sprintf("Rows: %d\n", nrow(df)))
   ```
   ```stata
   * Stata
   di "Rows: " _N
   ```
3. If row counts differ:
   - Check API URL construction
   - Check filter application logic
   - Check duplicate removal
4. If columns differ:
   - Review variable naming mapping
   - Check disaggregation variable handling

---

## Running Cross-Platform Tests

### Run All Cross-Platform Tests
```stata
do run_tests.do XPLAT
```

### Run Individual Tests
```stata
do run_tests.do XPLAT-01       # Metadata YAML consistency
do run_tests.do XPLAT-02       # Variable naming
do run_tests.do XPLAT-03       # Numerical formatting
do run_tests.do XPLAT-04       # Country codes
do run_tests.do XPLAT-05       # Data structure
```

### Run with Verbose Debugging
```stata
do run_tests.do XPLAT-01 verbose
```

---

## Interpreting Test Results

### All Tests Pass ✓
- Cross-platform consistency maintained
- Safe to update documentation
- Users can rely on cross-platform examples

### XPLAT-01 Fails (Metadata)
- **Action**: Re-sync metadata for all platforms
- **Impact**: Country/indicator lookups may differ
- **Priority**: HIGH

### XPLAT-02 Fails (Variable Names)
- **Action**: Review variable mapping in each codebase
- **Impact**: Code examples break across platforms
- **Priority**: CRITICAL

### XPLAT-03 Fails (Numeric Types)
- **Action**: Check type assignment in API clients
- **Impact**: Statistical results may differ
- **Priority**: CRITICAL

### XPLAT-04 Fails (Country Codes)
- **Action**: Standardize on ISO 3166-1 alpha-3
- **Impact**: Country filtering breaks
- **Priority**: HIGH

### XPLAT-05 Fails (Data Structure)
- **Action**: Review API request construction
- **Impact**: Reproducibility fails
- **Priority**: CRITICAL

---

## Maintenance

### When to Re-run
- After metadata sync in any platform
- Before major releases
- After SDMX API format changes
- When cross-platform issues reported

### Expected Changes
- Country count increases (new countries added to SDMX)
- Dataflow count increases (new indicators)
- Sync timestamps differ (platforms synced at different times)

### Acceptable Differences
- Sync timestamps (`_metadata.synced_at`)
- Platform identifiers (`_metadata.platform`)
- Minor country name spelling variants
- Column order (structure matters, order doesn't)

### Unacceptable Differences
- Different country counts (indicates missing sync)
- Different variable names (breaks reproducibility)
- Different numeric types (causes statistical errors)
- Missing core variables (breaks basic usage)

---

## Contact

For cross-platform consistency issues:
1. File GitHub issue in unicefData repo
2. Tag issue with `cross-platform` and `reproducibility`
3. Include test output from all three platforms

**Maintainers**:
- Python: [Python maintainer email]
- R: [R maintainer email]
- Stata: João Pedro Azevedo (jpazevedo@unicef.org)

---

*Last Updated: January 6, 2026*  
*Version: 1.5.1*

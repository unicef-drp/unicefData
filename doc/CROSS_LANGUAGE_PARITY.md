# unicefData Cross-Language Feature Parity

**Generated:** December 18, 2025  
**Version:** Python 0.3.0 | R 0.2.3 | Stata 1.4.0

This document provides a comprehensive comparison of features across Python, R, and Stata implementations of the unicefData package.

---

## Table of Contents

1. [Default Extraction Behavior](#default-extraction-behavior)
2. [Main Function Parameters](#main-function-parameters)
3. [Output Format Options](#output-format-options)
4. [Post-Processing Options](#post-processing-options)
5. [Discovery Commands](#discovery-commands)
6. [API/Technical Options](#apitechnical-options)
7. [Metadata/Vintage Features](#metadatavintage-features)
8. [Warning Messages](#warning-messages)
9. [Feature Gaps Summary](#feature-gaps-summary)
10. [Recommendations](#recommendations)

---

## Default Extraction Behavior

When you call `unicefData()` with just an indicator, each language applies the following defaults:

### Default Parameter Values

| Parameter | Python Default | R Default | Stata Default | Behavior |
|-----------|---------------|-----------|---------------|----------|
| **countries** | `None` | `NULL` | (empty) | **All countries** - fetches global data |
| **year** | `None` | `NULL` | (empty) | **All years** - no time filtering |
| **sex** | `"_T"` | `"_T"` | `"_T"` | **Total** - sex aggregate only |
| **age** | N/A | `NULL` | (empty) | **All/Total** - no age filtering |
| **wealth** | N/A | `NULL` | (empty) | **All/Total** - no wealth filtering |
| **residence** | N/A | `NULL` | (empty) | **All/Total** - no residence filtering |
| **maternal_edu** | N/A | `NULL` | (empty) | **All/Total** - no maternal education filtering |
| **dataflow** | `None` | `NULL` | (empty) | **Auto-detected** from indicator code |
| **format** | `"long"` | `"long"` | `long` | **Long format** - one row per observation |
| **tidy** | `True` | `TRUE` | N/A | **Cleaned output** - standardized column names |
| **country_names** | `True` | `TRUE` | ✅ automatic | **Includes country names** |
| **raw** | `False` | `FALSE` | (not set) | **Processed output** - not raw SDMX |
| **latest** | `False` | `FALSE` | (not set) | **All observations** - not just latest |
| **dropna** | `False` | `FALSE` | (not set) | **Keeps NA values** |
| **simplify** | `False` | `FALSE` | (not set) | **All columns** - includes metadata |
| **max_retries** | `3` | `3` | `3` | **3 retry attempts** on failure |
| **page_size** | N/A | `100000` | `100000` | **100K rows** per API request |
| **version** | N/A | `NULL` (auto) | `"1.0"` | **SDMX v1.0** |

### Minimal Example (Default Behavior)

```python
# Python - fetches ALL countries, ALL years, sex=Total
from unicef_api import unicefData
df = unicefData(indicator="CME_MRY0T4")
# Returns: ~5000+ rows (all countries × all years × sex=_T)
```

```r
# R - fetches ALL countries, ALL years, sex=Total
df <- unicefData(indicator = "CME_MRY0T4")
# Returns: ~5000+ rows (all countries × all years × sex=_T)
```

```stata
* Stata - fetches ALL countries, ALL years, sex=Total
unicefdata, indicator(CME_MRY0T4) clear
* Returns: ~5000+ obs (all countries × all years × sex=_T)
```

### Key Differences in Defaults

| Aspect | Python | R | Stata |
|--------|--------|---|-------|
| **Disaggregation filters** | Only `sex` | Full set (`age`, `wealth`, `residence`, `maternal_edu`) | Full set |
| **NULL/empty handling** | Returns all data | Returns all data | Returns all data |
| **Fallback on 404** | ✅ Enabled by default | ❌ Not implemented | ✅ Enabled by default |
| **Verbose output** | ❌ Minimal | ❌ Minimal | ❌ Off (use `verbose` to enable) |
| **Cache/memoization** | ❌ Off | ❌ Off (`cache=FALSE`) | ❌ Not available |
| **Disaggregation validation** | ❌ Not available | ❌ Not available | ✅ Warns if filter not supported |

### What "Total" (`_T`) Means for Sex Filter

All languages default to `sex="_T"` which means:
- Returns only the **sex aggregate** (total of male + female)
- Does **NOT** return male-only or female-only breakdowns
- To get all sex disaggregations, use `sex="ALL"` (R) or omit the filter and post-process

### Checking Supported Disaggregations (Stata)

**Not all indicators support all disaggregations.** For example:
- `CME` (Child Mortality) dataflow supports: `sex`, `wealth`
- `NUTRITION` dataflow supports: `sex`, `age`, `wealth`, `residence`, `maternal_edu`

In Stata, use `unicefdata, info(<indicator>)` to see what disaggregations are available:

```stata
* Check what disaggregations CME_MRY0T4 supports
unicefdata, info(CME_MRY0T4)

* Output includes:
*   Supported Disaggregations:
*     sex:          Yes (SEX)
*     age:          No
*     wealth:       Yes (WEALTH_QUINTILE)
*     residence:    No
*     maternal_edu: No
```

**Stata will now warn you** if you specify a disaggregation filter that the indicator doesn't support:

```stata
* This will show a warning because CME doesn't have AGE dimension
unicefdata, indicator(CME_MRY0T4) age(Y0T4) clear

* Warning: The following disaggregation(s) are NOT supported by CME_MRY0T4:
*          age
*   This indicator's dataflow (CME) does not include these dimensions.
*   Your filter(s) will be ignored. Use 'unicefdata, info(CME_MRY0T4)' for details.
```

### Important Notes

1. **Large result sets**: With defaults, queries can return thousands of rows. Consider adding `countries` or `year` filters for faster results.

2. **Auto-detection**: All languages auto-detect the dataflow from the indicator prefix (e.g., `CME_MRY0T4` → dataflow `CME`).

3. **Consistent output**: Default output format is **long** with standardized column names (`iso3`, `country`, `indicator`, `period`, `value`).

4. **Disaggregation availability varies by indicator**: Always check `unicefdata, info(<indicator>)` before applying filters.

---

## Main Function Parameters

| Parameter | Python | R | Stata | Notes |
|-----------|:------:|:-:|:-----:|-------|
| **indicator** | ✅ | ✅ | ✅ | Indicator code(s) - auto-detects dataflow |
| **dataflow** | ✅ | ✅ | ✅ | SDMX dataflow ID (optional, auto-detected) |
| **countries** | ✅ | ✅ | ✅ | ISO3 country codes |
| **year** | ✅ | ✅ | ✅ | Single, range (`2015:2023`), or list (`2015,2018,2020`) |
| **sex** | ✅ | ✅ | ✅ | Sex disaggregation (`_T`, `F`, `M`) |
| **age** | ❌ | ✅ | ✅ | Age group filter (⚠️ not all indicators support) |
| **wealth** | ❌ | ✅ | ✅ | Wealth quintile filter (⚠️ not all indicators support) |
| **residence** | ❌ | ✅ | ✅ | Urban/Rural filter (⚠️ not all indicators support) |
| **maternal_edu** | ❌ | ✅ | ✅ | Maternal education filter (⚠️ not all indicators support) |

### Year Parameter Format (All Languages)

All three languages support the unified `year` parameter:

```python
# Python
df = unicefData(indicator="CME_MRY0T4", year=2020)          # Single year
df = unicefData(indicator="CME_MRY0T4", year="2015:2023")   # Range
df = unicefData(indicator="CME_MRY0T4", year="2015,2018,2020")  # List
```

```r
# R
df <- unicefData(indicator="CME_MRY0T4", year=2020)
df <- unicefData(indicator="CME_MRY0T4", year="2015:2023")
df <- unicefData(indicator="CME_MRY0T4", year="2015,2018,2020")
```

```stata
* Stata
unicefdata, indicator(CME_MRY0T4) year(2020) clear
unicefdata, indicator(CME_MRY0T4) year(2015:2023) clear
unicefdata, indicator(CME_MRY0T4) year(2015,2018,2020) clear
```

---

## Output Format Options

| Format | Python | R | Stata | Notes |
|--------|:------:|:-:|:-----:|-------|
| **long** (default) | ✅ | ✅ | ✅ | One row per observation |
| **wide** | ✅ | ✅ | ✅ | Years as columns |
| **wide_indicators** | ✅ | ✅ | ✅ | Indicators as columns |
| **wide_sex** | ❌ | ✅ | ❌ | Sex disaggregations as columns |
| **wide_age** | ❌ | ✅ | ❌ | Age groups as columns |
| **wide_wealth** | ❌ | ✅ | ❌ | Wealth quintiles as columns |
| **wide_residence** | ❌ | ✅ | ❌ | Residence types as columns |
| **wide_maternal_edu** | ❌ | ✅ | ❌ | Maternal education as columns |

### Notes on Wide Formats

- **wide_indicators** requires multiple indicators to be useful
- **wide** with multiple indicators may produce complex output (warning issued)
- R supports full pivot on any disaggregation dimension

---

## Post-Processing Options

| Option | Python | R | Stata | Notes |
|--------|:------:|:-:|:-----:|-------|
| **latest** | ✅ | ✅ | ✅ | Most recent value per country (cross-sectional) |
| **mrv(n)** | ✅ | ✅ | ✅ | N most recent values per country |
| **circa** | ✅ | ✅ | ✅ | Find closest available year when exact not available |
| **dropna** | ✅ | ✅ | ✅ | Drop rows with missing values |
| **simplify** | ✅ | ✅ | ✅ | Keep only essential columns |
| **raw** | ✅ | ✅ | ✅ | Return raw SDMX output without cleaning |
| **add_metadata** | ✅ | ✅ | ✅ | Add `region`, `income_group`, `continent` columns |
| **ignore_duplicates** | ✅ | ✅ | ❌ | Handle exact duplicate rows gracefully |

### Metadata Options

All languages support adding these metadata columns:
- `region` - UNICEF/World Bank region classification
- `income_group` - World Bank income classification
- `continent` - Continent name

R additionally supports:
- `indicator_name` - Full indicator description
- `indicator_category` - Indicator category (CME, NUTRITION, etc.)

---

## Discovery Commands

| Command | Python | R | Stata | Example |
|---------|:------:|:-:|:-----:|---------|
| **list_dataflows** | ✅ `list_dataflows()` | ✅ `list_unicef_flows()` | ✅ `unicefdata, flows` | List all 69 dataflows |
| **search_indicators** | ✅ `search_indicators()` | ✅ `search_indicators()` | ✅ `unicefdata, search()` | Keyword search in 733+ indicators |
| **list_categories** | ✅ `list_categories()` | ✅ `list_categories()` | ✅ `unicefdata, categories` | List categories with counts |
| **list_indicators** | ✅ `list_indicators()` | ✅ `list_indicators()` | ✅ `unicefdata, indicators()` | Indicators in a dataflow |
| **get_indicator_info** | ✅ `get_indicator_info()` | ✅ `get_indicator_info()` | ✅ `unicefdata, info()` | Detailed indicator metadata |

### Discovery Examples

```python
# Python
from unicef_api import search_indicators, list_categories
search_indicators("mortality")
list_categories()
```

```r
# R
search_indicators("mortality")
list_categories()
```

```stata
* Stata
unicefdata, search(mortality)
unicefdata, categories
unicefdata, indicators(CME)
unicefdata, info(CME_MRY0T4)
```

---

## API/Technical Options

| Option | Python | R | Stata | Notes |
|--------|:------:|:-:|:-----:|-------|
| **max_retries** | ✅ | ✅ | ✅ | Retry attempts on network failure |
| **page_size** | ❌ | ✅ | ✅ | Rows per API request (default: 100,000) |
| **version** | ❌ | ✅ | ✅ | SDMX version |
| **tidy** | ✅ | ✅ | N/A | Return cleaned output (Python/R only) |
| **country_names** | ✅ | ✅ | ✅ | Add country name column |
| **cache** | ❌ | ✅ | ❌ | Memoize results for repeated calls |
| **fallback/nofallback** | ✅ | ❌ | ✅ | Dataflow fallback on 404 errors |
| **validate** | ❌ | ❌ | ✅ | Validate inputs against codelists |
| **verbose** | ❌ | ❌ | ✅ | Show detailed progress output |
| **clear** | N/A | N/A | ✅ | Stata-specific: replace data in memory |

### Dataflow Fallback

Python and Stata support automatic fallback to alternative dataflows when the auto-detected one returns 404:

```python
# Python - automatic fallback enabled by default
# Tries alternatives: EDUCATION → EDUCATION_UIS_SDG → GLOBAL_DATAFLOW
```

```stata
* Stata
unicefdata, indicator(ED_CR_L1) fallback clear    // Try alternatives on 404
unicefdata, indicator(ED_CR_L1) nofallback clear  // Disable fallback
```

---

## Metadata/Vintage Features

| Feature | Python | R | Stata | Notes |
|---------|:------:|:-:|:-----:|-------|
| **sync_metadata** | ✅ | ✅ | ✅ | Download/refresh API metadata |
| **list_vintages** | ✅ | ✅ | ❌ | List available metadata snapshots |
| **compare_vintages** | ✅ | ✅ | ❌ | Compare two metadata versions |
| **ensure_metadata** | ✅ | ✅ | ❌ | Auto-sync if metadata is stale |

### Sync Commands

```python
# Python
from unicef_api import sync_metadata, list_vintages
sync_metadata()
list_vintages()
```

```r
# R
sync_metadata()
list_vintages()
compare_vintages("2025-12-01", "2025-12-15")
```

```stata
* Stata
unicefdata, sync              // Sync all metadata
unicefdata, sync(indicators)  // Sync indicators only
```

---

## Warning Messages

### Standardized Warning Messages Across Languages

#### 1. Wide Format with Multiple Indicators

| Language | Warning Message |
|----------|-----------------|
| **Python** | `Warning: 'wide' format with multiple indicators may produce complex output.`<br>`Consider using 'wide_indicators' format instead.` |
| **R** | `Warning: 'wide' format with multiple indicators may produce complex output.`<br>`Consider using 'wide_indicators' format instead.` |
| **Stata** | *(Not implemented - uses wide_indicators automatically)* |

#### 2. Wide Indicators with Single Indicator

| Language | Warning Message |
|----------|-----------------|
| **Python** | `Warning: 'wide_indicators' format is designed for multiple indicators.` |
| **R** | `Warning: 'wide_indicators' format is designed for multiple indicators.` |
| **Stata** | *(Returns data in long format)* |

#### 3. Metadata Sync Failures

| Language | Warning Message |
|----------|-----------------|
| **Python** | `Warning: Metadata sync failed ({e}). Proceeding without cached metadata.` |
| **R** | *(Uses `warning()` function)* `Failed to load cache: {message}` |
| **Stata** | `Warning: Large XML files may hit Stata macro limits (~730+ indicators)` |

#### 4. Parameter Validation (Stata-specific)

| Warning | Condition |
|---------|-----------|
| `Warning: sex value 'X' may not be valid. Expected: _T, F, M` | Invalid sex parameter |
| `Warning: wealth value 'X' may not be valid. Expected: _T, Q1-Q5` | Invalid wealth parameter |
| `Warning: residence value 'X' may not be valid. Expected: _T, U, R` | Invalid residence parameter |
| `Warning: No data remaining after applying disaggregation filters for wide_indicators.` | Filters too restrictive |

#### 5. Duplicate Rows (Python/R only)

| Language | Warning/Error Message |
|----------|----------------------|
| **Python** | Error (default): `Found N exact duplicate rows (all values identical). Set ignore_duplicates=True to automatically remove duplicates.`<br>Warning (if ignore_duplicates=True): `Removed N exact duplicate rows.` |
| **R** | Similar behavior with `ignore_duplicates` parameter |
| **Stata** | *(Not implemented)* |

#### 6. Fetch Failures

| Language | Warning Message |
|----------|-----------------|
| **Python** | `All dataflow attempts failed for 'INDICATOR'. Tried: [dataflow1, dataflow2, ...]` |
| **R** | `Error in purrr::map: {message}` |
| **Stata** | `Warning: Could not fetch INDICATOR (skipped)` |

---

## Feature Gaps Summary

### Python Missing (vs R)

1. **Filter parameters**: `age`, `wealth`, `residence`, `maternal_edu`
2. **Wide formats**: `wide_sex`, `wide_age`, `wide_wealth`, `wide_residence`, `wide_maternal_edu`
3. **API options**: `page_size`, `version`
4. **Caching**: `cache` option for memoization

### Stata Missing (vs R)

1. **Wide formats**: `wide_sex`, `wide_age`, `wide_wealth`, `wide_residence`, `wide_maternal_edu`
2. **Duplicate handling**: `ignore_duplicates` option
3. **Vintage features**: `list_vintages`, `compare_vintages`
4. **Session caching**: Cache downloaded data across calls

### R Missing (vs Python/Stata)

1. **Dataflow fallback**: `fallback`/`nofallback` options for 404 handling
2. **Verbose output**: `verbose` option for detailed progress

---

## Recommendations

### Priority 1 (High Impact)

| Task | Target | Rationale |
|------|--------|-----------|
| Add `age`, `wealth`, `residence`, `maternal_edu` to Python | Python | Parity with R/Stata for disaggregation filters |
| Add `fallback` option to R | R | Parity with Python/Stata for robust data fetching |

### Priority 2 (Medium Impact)

| Task | Target | Rationale |
|------|--------|-----------|
| Add `wide_sex/age/wealth` formats to Python | Python | Full pivot support like R |
| Add `wide_sex/age/wealth` formats to Stata | Stata | Full pivot support like R |
| Add vintage commands to Stata | Stata | Metadata version tracking |

### Priority 3 (Nice to Have)

| Task | Target | Rationale |
|------|--------|-----------|
| Add `ignore_duplicates` to Stata | Stata | Handle duplicate rows gracefully |
| Add `cache` option to Python | Python | Memoization for repeated calls |
| Add `verbose` option to Python/R | Python, R | Detailed progress output |
| Standardize warning messages | All | Consistent user experience |

---

## Appendix: Function Signatures

### Python

```python
def unicefData(
    indicator: Union[str, List[str]],
    countries: Optional[List[str]] = None,
    year: Union[int, str, List[int], Tuple[int, int], None] = None,
    dataflow: Optional[str] = None,
    sex: str = "_T",
    tidy: bool = True,
    country_names: bool = True,
    max_retries: int = 3,
    format: str = "long",
    latest: bool = False,
    circa: bool = False,
    add_metadata: Optional[List[str]] = None,
    dropna: bool = False,
    simplify: bool = False,
    mrv: Optional[int] = None,
    raw: bool = False,
    ignore_duplicates: bool = False,
) -> pd.DataFrame
```

### R

```r
unicefData <- function(
    indicator     = NULL,
    dataflow      = NULL,
    countries     = NULL,
    year          = NULL,
    sex           = "_T",
    age           = NULL,
    wealth        = NULL,
    residence     = NULL,
    maternal_edu  = NULL,
    tidy          = TRUE,
    country_names = TRUE,
    max_retries   = 3,
    cache         = FALSE,
    page_size     = 100000,
    detail        = c("data", "structure"),
    version       = NULL,
    format        = c("long", "wide", "wide_indicators", "wide_sex", 
                      "wide_age", "wide_wealth", "wide_residence", "wide_maternal_edu"),
    latest        = FALSE,
    circa         = FALSE,
    add_metadata  = NULL,
    dropna        = FALSE,
    simplify      = FALSE,
    mrv           = NULL,
    raw           = FALSE,
    ignore_duplicates = FALSE
)
```

### Stata

```stata
unicefdata, indicator(string) [dataflow(string)] [countries(string)]
            [year(string)] [sex(string)] [age(string)] [wealth(string)]
            [residence(string)] [maternal_edu(string)]
            [long] [wide] [wide_indicators]
            [latest] [mrv(integer)] [circa] [dropna] [simplify] [raw]
            [addmeta(string)] [version(string)] [page_size(integer)]
            [max_retries(integer)] [clear] [verbose] [validate]
            [fallback] [nofallback]
```

---

*Document maintained by unicefData development team.*

# UNICEF Data Package - Cross-Language Feature Parity Comparison

**Generated:** December 9, 2025  
**Version:** Python 0.3.0 | R 1.0.0 | Stata 1.2.1

This document provides a comprehensive comparison of the `unicefData` package implementations across Python, R, and Stata.

---

## Executive Summary

| Feature Area | Python | R | Stata |
|--------------|--------|---|-------|
| **Core Data Retrieval** | ✅ Full | ✅ Full | ✅ Full |
| **Filtering** | ✅ Full | ✅ Full | ✅ Full |
| **Output Formats** | ✅ Full | ✅ Full | ⚠️ Partial |
| **Metadata Sync** | ✅ Full | ✅ Full | ✅ Full |
| **Discovery Functions** | ✅ Full | ✅ Full | ❌ None |
| **Caching** | ✅ Full | ✅ Full | ⚠️ Partial |
| **Post-Production** | ✅ Full | ✅ Full | ⚠️ Partial |

---

## 1. Primary Data Retrieval Function

### Function Signature Comparison

#### Python: `unicefData()`

```python
unicefData(
    indicator: Union[str, List[str]],      # Indicator code(s)
    countries: Optional[List[str]] = None,  # ISO3 codes
    start_year: Optional[int] = None,
    end_year: Optional[int] = None,
    dataflow: Optional[str] = None,        # Auto-detected if None
    sex: str = "_T",                        # _T, F, M
    tidy: bool = True,
    country_names: bool = True,
    max_retries: int = 3,
    # Post-production options:
    format: str = "long",                   # long, wide, wide_indicators
    latest: bool = False,
    add_metadata: Optional[List[str]] = None,  # region, income_group, continent
    dropna: bool = False,
    simplify: bool = False,
    mrv: Optional[int] = None,
    raw: bool = False,
    ignore_duplicates: bool = False,
) -> pd.DataFrame
```

#### R: `unicefData()`

```r
unicefData(
    indicator = NULL,                # Character vector of indicator codes
    dataflow = NULL,                 # SDMX dataflow ID
    countries = NULL,                # ISO3 country codes
    start_year = NULL,
    end_year = NULL,
    sex = "_T",                      # _T, F, M, ALL
    age = NULL,                      # Age group filter
    wealth = NULL,                   # Wealth quintile filter
    residence = NULL,                # URBAN, RURAL
    maternal_edu = NULL,             # Maternal education filter
    tidy = TRUE,
    country_names = TRUE,
    max_retries = 3,
    cache = FALSE,                   # Memoize results
    page_size = 100000,
    detail = c("data", "structure"),
    version = NULL,
    # Post-production options:
    format = c("long", "wide", "wide_indicators", "wide_sex", 
               "wide_age", "wide_wealth", "wide_residence", "wide_maternal_edu"),
    latest = FALSE,
    add_metadata = NULL,             # region, income_group, continent, indicator_name
    dropna = FALSE,
    simplify = FALSE,
    mrv = NULL,
    raw = FALSE,
    ignore_duplicates = FALSE,
    # Legacy parameters (deprecated):
    flow = NULL, key = NULL, start_period = NULL, end_period = NULL, retry = NULL
)
```

#### Stata: `unicefdata`

```stata
unicefdata [, 
    INDICATOR(string)           // Indicator code(s)
    DATAFLOW(string)            // SDMX dataflow ID
    COUNTries(string)           // ISO3 country codes
    START_year(integer 0)       // Start year
    END_year(integer 0)         // End year
    SEX(string)                 // _T, F, M, ALL
    AGE(string)                 // Age group filter
    WEALTH(string)              // Wealth quintile filter
    RESIDENCE(string)           // URBAN, RURAL
    MATERNAL_edu(string)        // Maternal education filter
    LONG                        // Long format (default)
    WIDE                        // Wide format
    LATEST                      // Most recent value only
    MRV(integer 0)              // N most recent values
    DROPNA                      // Drop missing values
    SIMPLIFY                    // Essential columns only
    RAW                         // Raw SDMX output
    VERSION(string)             // SDMX version
    PAGE_size(integer 100000)   // Rows per request
    MAX_retries(integer 3)      // Retry attempts
    CLEAR                       // Replace data in memory
    VERBOSE                     // Show progress
    VALIDATE                    // Validate inputs against codelists
]
```

---

## 2. Feature Comparison Matrix

### 2.1 Core Data Retrieval

| Feature | Python | R | Stata | Notes |
|---------|--------|---|-------|-------|
| Single indicator | ✅ | ✅ | ✅ | All support single indicator codes |
| Multiple indicators | ✅ List | ✅ Vector | ⚠️ Manual | Stata requires multiple calls or manual concatenation |
| Auto-detect dataflow | ✅ | ✅ | ✅ | All infer dataflow from indicator prefix |
| Explicit dataflow | ✅ | ✅ | ✅ | All support explicit dataflow specification |
| Dataflow fallback | ✅ | ⚠️ | ❌ | Python tries alternative dataflows on 404 |

### 2.2 Filtering Options

| Filter | Python | R | Stata | Notes |
|--------|--------|---|-------|-------|
| Country (ISO3) | ✅ | ✅ | ✅ | All support ISO3 filtering |
| Year range (start/end) | ✅ | ✅ | ✅ | Consistent across all |
| Sex | ✅ `_T/F/M` | ✅ `_T/F/M/ALL` | ✅ `_T/F/M/ALL` | R/Stata have `ALL` option |
| Age group | ❌ | ✅ | ✅ | Python filters in post-processing |
| Wealth quintile | ❌ | ✅ | ✅ | Python filters in post-processing |
| Residence | ❌ | ✅ | ✅ | Python filters in post-processing |
| Maternal education | ❌ | ✅ | ✅ | Python filters in post-processing |
| Default to totals | ✅ `_T` | ✅ Auto | ✅ `_T` | R auto-filters to totals by default |

### 2.3 Output Formats

| Format | Python | R | Stata | Notes |
|--------|--------|---|-------|-------|
| Long (default) | ✅ | ✅ | ✅ | Standard tidy format |
| Wide (years as columns) | ✅ | ✅ | ✅ | Pivot by time period |
| Wide by indicators | ✅ | ✅ | ❌ | Indicators as columns |
| Wide by sex | ❌ | ✅ | ❌ | R-specific |
| Wide by age | ❌ | ✅ | ❌ | R-specific |
| Wide by wealth | ❌ | ✅ | ❌ | R-specific |
| Wide by residence | ❌ | ✅ | ❌ | R-specific |
| Wide by maternal edu | ❌ | ✅ | ❌ | R-specific |
| Raw SDMX output | ✅ | ✅ | ✅ | Unprocessed API response |

### 2.4 Post-Production Processing

| Feature | Python | R | Stata | Notes |
|---------|--------|---|-------|-------|
| Latest value only | ✅ | ✅ | ✅ | Most recent non-missing per country |
| MRV (N most recent) | ✅ | ✅ | ✅ | Keep N latest values per country |
| Drop NA values | ✅ | ✅ | ✅ | Remove missing observations |
| Simplify columns | ✅ | ✅ | ✅ | Keep essential columns only |
| Add region metadata | ✅ | ✅ | ❌ | Add UNICEF/WB region |
| Add income group | ✅ | ✅ | ❌ | Add WB income classification |
| Add continent | ✅ | ✅ | ❌ | Add continent name |
| Add indicator name | ✅ | ✅ | ⚠️ | Auto-added if in YAML |
| Duplicate detection | ✅ | ✅ | ❌ | Error on exact duplicates |

### 2.5 Column Naming Convention

| Column | Python | R | Stata | Standard |
|--------|--------|---|-------|----------|
| Country code | `iso3` | `iso3` | `iso3` | ✅ Aligned |
| Country name | `country` | `country` | `country` | ✅ Aligned |
| Indicator | `indicator` | `indicator` | `indicator` | ✅ Aligned |
| Time period | `period` | `period` | `period` | ✅ Aligned |
| Value | `value` | `value` | `value` | ✅ Aligned |
| Sex | `sex` | `sex` | `sex` | ✅ Aligned |
| Age | `age` | `age` | `age` | ✅ Aligned |
| Wealth | `wealth_quintile` | `wealth_quintile` | `wealth` | ⚠️ Stata shorter |
| Lower bound | `lower_bound` | `lower_bound` | `lb` | ⚠️ Stata shorter |
| Upper bound | `upper_bound` | `upper_bound` | `ub` | ⚠️ Stata shorter |

---

## 3. Discovery Functions

### 3.1 List Dataflows

| Function | Python | R | Stata |
|----------|--------|---|-------|
| **Name** | `list_dataflows()` | `list_unicef_flows()` / `list_sdmx_flows()` | N/A |
| **Returns** | DataFrame | Tibble | N/A |
| **Columns** | id, name, agency, version | id, agency, version, name | N/A |
| **Caching** | No | Yes (memoise) | N/A |

### 3.2 Search Indicators

| Function | Python | R | Stata |
|----------|--------|---|-------|
| **Name** | `search_indicators()` | N/A | N/A |
| **Parameters** | `query`, `category`, `limit`, `show_description` | N/A | N/A |
| **Output** | Formatted print to console | N/A | N/A |

### 3.3 List Categories

| Function | Python | R | Stata |
|----------|--------|---|-------|
| **Name** | `list_categories()` | N/A | N/A |
| **Returns** | Printed list of categories | N/A | N/A |

### 3.4 Get Indicator Info

| Function | Python | R | Stata |
|----------|--------|---|-------|
| **Name** | `get_indicator_info()` | `get_indicator_info()` | N/A |
| **Returns** | Dict with name, category, description | List with same | N/A |

### 3.5 Get Dataflow for Indicator

| Function | Python | R | Stata |
|----------|--------|---|-------|
| **Name** | `get_dataflow_for_indicator()` | `detect_dataflow()` | `_unicef_detect_dataflow_yaml` |
| **Approach** | YAML metadata + prefix fallback | Prefix mapping + overrides | YAML + prefix fallback |

---

## 4. Metadata Synchronization

### 4.1 Sync Functions

| Feature | Python | R | Stata |
|---------|--------|---|-------|
| **Main Function** | `MetadataSync.sync_all()` / `sync_metadata()` | `sync_metadata()` | `unicefdata_sync` |
| **Dataflows** | ✅ `_unicefdata_dataflows.yaml` | ✅ `_unicefdata_dataflows.yaml` | ✅ `_unicefdata_dataflows.yaml` |
| **Indicators** | ✅ `_unicefdata_indicators.yaml` | ✅ `_unicefdata_indicators.yaml` | ✅ `_unicefdata_indicators.yaml` |
| **Codelists** | ✅ `_unicefdata_codelists.yaml` | ✅ `_unicefdata_codelists.yaml` | ✅ `_unicefdata_codelists.yaml` |
| **Countries** | ✅ `_unicefdata_countries.yaml` | ✅ `_unicefdata_countries.yaml` | ✅ `_unicefdata_countries.yaml` |
| **Regions** | ✅ `_unicefdata_regions.yaml` | ✅ `_unicefdata_regions.yaml` | ✅ `_unicefdata_regions.yaml` |
| **Dataflow Schemas** | ✅ Per-dataflow YAML | ✅ Per-dataflow YAML | ❌ |
| **Sync History** | ✅ | ✅ | ✅ |
| **Watermarks** | ✅ platform, version, synced_at | ✅ platform, version, synced_at | ✅ platform, version, synced_at |

### 4.2 Vintage Control

| Feature | Python | R | Stata |
|---------|--------|---|-------|
| **Vintage snapshots** | ✅ | ✅ | ⚠️ Manual |
| **Compare vintages** | ✅ `compare_vintages()` | ✅ `compare_vintages()` | ❌ |
| **List vintages** | ✅ `list_vintages()` | ✅ `list_vintages()` | ❌ |
| **Load specific vintage** | ✅ | ✅ | ❌ |

---

## 5. Caching & Performance

| Feature | Python | R | Stata |
|---------|--------|---|-------|
| **In-memory cache** | ✅ Module-level | ✅ `memoise` | ❌ |
| **Disk cache** | ✅ YAML files | ✅ YAML + memoise filesystem | ✅ YAML files |
| **Pagination** | ✅ Automatic | ✅ Automatic | ✅ `page_size` option |
| **Retry logic** | ✅ Exponential backoff | ✅ `httr::RETRY` | ✅ Simple retry loop |
| **Connection pooling** | ✅ requests.Session | ⚠️ Per-request | ❌ |

---

## 6. Error Handling

| Error Type | Python | R | Stata |
|------------|--------|---|-------|
| Invalid country codes | ✅ ValueError | ⚠️ Warning | ⚠️ Silent filter |
| Invalid indicator | ✅ SDMXNotFoundError | ✅ httr::stop_for_status | ✅ Error message |
| Network failure | ✅ SDMXError hierarchy | ✅ httr exceptions | ✅ Basic error |
| Bad request (400) | ✅ SDMXBadRequestError | ✅ httr::stop_for_status | ⚠️ Generic error |
| Not found (404) | ✅ SDMXNotFoundError | ✅ httr::stop_for_status | ✅ Helpful message |
| Server error (500) | ✅ SDMXServerError | ✅ httr::stop_for_status | ⚠️ Generic error |
| Duplicate detection | ✅ ValueError (optional) | ✅ Error (optional) | ❌ |

---

## 7. Input Validation

| Validation | Python | R | Stata |
|------------|--------|---|-------|
| Country code format | ✅ `validate_country_codes()` | ⚠️ Basic | ✅ `validate` option |
| Year range logic | ✅ `validate_year_range()` | ✅ Basic checks | ⚠️ Minimal |
| Indicator format | ✅ `validate_indicator_code()` | ⚠️ None | ❌ |
| Codelist validation | ⚠️ Schema-based | ✅ Schema-based | ✅ YAML-based |

---

## 8. SDMX Client Architecture

| Component | Python | R | Stata |
|-----------|--------|---|-------|
| **Client class** | ✅ `UNICEFSDMXClient` | ❌ Functional | ❌ Single program |
| **Fetch method** | `fetch_indicator()` | `unicefData_raw()` | Direct `copy` |
| **Schema validation** | ✅ `MetadataManager` | ✅ `validate_unicef_schema()` | ⚠️ Basic |
| **URL builder** | ✅ Internal | ✅ Internal | ✅ Internal |

---

## 9. Key Differences Summary

### Python Advantages
- Comprehensive error hierarchy (`SDMXError` subclasses)
- Dataflow fallback on 404 errors (tries alternatives automatically)
- Search functions (`search_indicators()`, `list_categories()`)
- Connection pooling with `requests.Session`
- Type hints and detailed docstrings

### R Advantages
- Additional wide formats (`wide_sex`, `wide_age`, `wide_wealth`, etc.)
- Built-in memoisation with `memoise` package
- SDMX structure endpoint support (`detail="structure"`)
- More granular disaggregation filters (age, wealth, residence, maternal_edu)
- Legacy parameter support for backward compatibility

### Stata Advantages
- Native integration with Stata's data environment
- `validate` option for codelist validation
- Direct variable labeling
- Return macros (`r(indicator)`, `r(dataflow)`, etc.)
- Works in restricted environments without external dependencies

### Stata Limitations
- No discovery functions (search, list categories)
- No vintage comparison
- Limited output format options (no wide_indicators, wide_sex, etc.)
- No metadata enrichment (region, income_group, continent)
- No in-memory caching
- Less granular error handling

---

## 10. Recommended Improvements

### For Stata
1. Add `search` subcommand for indicator discovery
2. Add `add_metadata` option for region/income_group
3. Implement `wide_indicators` format
4. Add vintage comparison support
5. Improve error messages with SDMX-specific codes

### For R
1. Add `search_indicators()` function (currently missing)
2. Add dataflow fallback mechanism like Python
3. Consider exposing `UNICEFSDMXClient`-like class

### For Python
1. Add disaggregation parameters (age, wealth, residence, maternal_edu)
2. Add additional wide formats (wide_sex, wide_age, etc.)
3. Consider adding `cache=True` parameter like R
4. Add SDMX structure endpoint support

---

## 11. Cross-Language Compatibility Notes

### YAML Metadata Alignment
All three languages use the same YAML file naming convention:
- `_unicefdata_dataflows.yaml`
- `_unicefdata_indicators.yaml`
- `_unicefdata_codelists.yaml`
- `_unicefdata_countries.yaml`
- `_unicefdata_regions.yaml`
- `_unicefdata_sync_history.yaml`

All include platform watermarks for triangulation:
```yaml
_metadata:
  platform: python|r|stata
  version: "2.0.0"
  synced_at: "2025-12-09T10:30:00Z"
  source: "https://sdmx.data.unicef.org/..."
```

### Output Column Alignment
Core columns are aligned across all platforms:
- `iso3`, `country`, `indicator`, `period`, `value`
- Stata uses shorter names for some columns (`lb`/`ub` vs `lower_bound`/`upper_bound`)

### Time Period Handling
All platforms convert monthly periods (YYYY-MM) to decimal years:
- `2020-06` → `2020.5` (year + month/12)
- This ensures consistent time-series analysis across platforms

---

## Appendix A: Full Parameter Reference

### Python `unicefData()` Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `indicator` | `str` or `List[str]` | Required | Indicator code(s) |
| `countries` | `List[str]` | `None` | ISO3 country codes |
| `start_year` | `int` | `None` | Start year |
| `end_year` | `int` | `None` | End year |
| `dataflow` | `str` | Auto-detect | SDMX dataflow ID |
| `sex` | `str` | `"_T"` | Sex filter |
| `tidy` | `bool` | `True` | Clean output |
| `country_names` | `bool` | `True` | Add country names |
| `max_retries` | `int` | `3` | Retry attempts |
| `format` | `str` | `"long"` | Output format |
| `latest` | `bool` | `False` | Latest value only |
| `add_metadata` | `List[str]` | `None` | Metadata columns |
| `dropna` | `bool` | `False` | Drop missing |
| `simplify` | `bool` | `False` | Essential columns |
| `mrv` | `int` | `None` | N most recent |
| `raw` | `bool` | `False` | Raw output |
| `ignore_duplicates` | `bool` | `False` | Allow duplicates |

### R `unicefData()` Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `indicator` | `character` | `NULL` | Indicator code(s) |
| `dataflow` | `character` | `NULL` | SDMX dataflow ID |
| `countries` | `character` | `NULL` | ISO3 country codes |
| `start_year` | `numeric` | `NULL` | Start year |
| `end_year` | `numeric` | `NULL` | End year |
| `sex` | `character` | `"_T"` | Sex filter |
| `age` | `character` | `NULL` | Age filter |
| `wealth` | `character` | `NULL` | Wealth filter |
| `residence` | `character` | `NULL` | Residence filter |
| `maternal_edu` | `character` | `NULL` | Maternal edu filter |
| `tidy` | `logical` | `TRUE` | Clean output |
| `country_names` | `logical` | `TRUE` | Add country names |
| `max_retries` | `integer` | `3` | Retry attempts |
| `cache` | `logical` | `FALSE` | Memoize results |
| `page_size` | `integer` | `100000` | Rows per page |
| `detail` | `character` | `"data"` | data or structure |
| `version` | `character` | `NULL` | SDMX version |
| `format` | `character` | `"long"` | Output format |
| `latest` | `logical` | `FALSE` | Latest value only |
| `add_metadata` | `character` | `NULL` | Metadata columns |
| `dropna` | `logical` | `FALSE` | Drop missing |
| `simplify` | `logical` | `FALSE` | Essential columns |
| `mrv` | `integer` | `NULL` | N most recent |
| `raw` | `logical` | `FALSE` | Raw output |
| `ignore_duplicates` | `logical` | `FALSE` | Allow duplicates |

### Stata `unicefdata` Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `indicator()` | string | Required* | Indicator code(s) |
| `dataflow()` | string | Auto-detect | SDMX dataflow ID |
| `countries()` | string | All | ISO3 country codes |
| `start_year()` | integer | None | Start year |
| `end_year()` | integer | None | End year |
| `sex()` | string | `_T` | Sex filter |
| `age()` | string | All | Age filter |
| `wealth()` | string | All | Wealth filter |
| `residence()` | string | All | Residence filter |
| `maternal_edu()` | string | All | Maternal edu filter |
| `long` | flag | Default | Long format |
| `wide` | flag | Off | Wide format |
| `latest` | flag | Off | Latest value only |
| `mrv()` | integer | None | N most recent |
| `dropna` | flag | Off | Drop missing |
| `simplify` | flag | Off | Essential columns |
| `raw` | flag | Off | Raw output |
| `version()` | string | `1.0` | SDMX version |
| `page_size()` | integer | `100000` | Rows per page |
| `max_retries()` | integer | `3` | Retry attempts |
| `clear` | flag | Off | Clear data in memory |
| `verbose` | flag | Off | Show progress |
| `validate` | flag | Off | Validate inputs |

*Either `indicator()` or `dataflow()` is required.

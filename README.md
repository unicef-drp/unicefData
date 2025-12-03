# unicefData

[![R-CMD-check](https://github.com/unicef-drp/unicefData/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions)
[![Python Tests](https://github.com/unicef-drp/unicefData/actions/workflows/python-tests.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Bilingual R and Python library for downloading UNICEF child welfare indicators via SDMX API**

The **unicefData** package provides lightweight, consistent interfaces to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) in both **R** and **Python**. Inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank), you can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.

---

## Quick Start

Both R and Python use the **same functions** with identical parameter names.

### Python

```python
from unicef_api import get_unicef, search_indicators, list_categories

# Don't know the indicator code? Search for it!
search_indicators("mortality")
list_categories()

# Fetch under-5 mortality for specific countries
# Dataflow is auto-detected from the indicator code!
df = get_unicef(
    indicator="CME_MRY0T4",
    countries=["ALB", "USA", "BRA"],
    start_year=2015,
    end_year=2023
)

print(df.head())
```

### R

```r
source("R/unicef_api/get_unicef.R")

# Don't know the indicator code? Search for it!
search_indicators("mortality")
list_categories()

# Fetch under-5 mortality for specific countries
# Dataflow is auto-detected from the indicator code!
df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA", "BRA"),
  start_year = 2015,
  end_year = 2023
)

print(head(df))
```

> **Note:** You don't need to specify `dataflow`! The package automatically detects it from the indicator code on first use, fetching the complete indicator codelist (733 indicators) from the UNICEF SDMX API.

---

## Installation

### R Package

```r
# Install from GitHub
devtools::install_github("unicef-drp/unicefData")
library(unicefData)
```

### Python Package

```bash
git clone https://github.com/unicef-drp/unicefData.git
cd unicefData/python
pip install -e .
```

---

## Finding Indicators

Use `search_indicators()` and `list_categories()` to discover available indicators.

### Search by Keyword

```python
# Python
from unicef_api import search_indicators

search_indicators("mortality")      # Find mortality-related indicators
search_indicators("stunting")       # Find nutrition indicators
search_indicators("immunization")   # Find vaccine coverage indicators
```

```r
# R
source("R/unicef_api/get_unicef.R")

search_indicators("mortality")
search_indicators("stunting")
search_indicators("immunization")
```

**Output:**
```
====================================================================================================
  UNICEF Indicators matching 'mortality'
====================================================================================================

  Found 24 indicator(s) (showing first 10)
----------------------------------------------------------------------------------------------------
  CODE             CATEGORY    NAME                                 DESCRIPTION
----------------------------------------------------------------------------------------------------
  CME_MRM0         CME         Neonatal mortality rate              Probability of dying during..
  CME_MRY0         CME         Infant mortality rate                Probability of dying between..
  CME_MRY0T4       CME         Under-five mortality rate            Probability of dying between..
  ...
----------------------------------------------------------------------------------------------------
```

### List Categories

```python
# Python
from unicef_api import list_categories
list_categories()
```

```r
# R
list_categories()
```

**Output:**
```
==================================================
  Available Indicator Categories
==================================================

  CATEGORY                       COUNT
--------------------------------------------------
  GLOBAL_DATAFLOW                  226
  NUTRITION                        112
  WASH_HOUSEHOLDS                   57
  EDUCATION                         54
  PT                                50
  CME                               39
  HIV_AIDS                          38
  MNCH                              38
  ...
--------------------------------------------------
  TOTAL                            733
```

### Search by Category

```python
# Python
search_indicators(category="CME")           # All child mortality indicators
search_indicators(category="NUTRITION")     # All nutrition indicators
search_indicators("rate", category="CME")   # Mortality rates only
```

```r
# R
search_indicators(category = "CME")
search_indicators(category = "NUTRITION")
search_indicators("rate", category = "CME")
```

---

## Post-Production Features

The `get_unicef()` function includes powerful post-production options for data transformation and enrichment.

### 📅 Time Period Handling

**Important**: The UNICEF SDMX API returns TIME_PERIOD values in various formats. This library automatically converts them to decimal years for consistent time-series analysis:

| Original Format | Decimal Year | Calculation |
|----------------|--------------|-------------|
| `2020` | `2020.0` | Integer year |
| `2020-01` | `2020.0833` | 2020 + 1/12 (January) |
| `2020-06` | `2020.5000` | 2020 + 6/12 (June) |
| `2020-11` | `2020.9167` | 2020 + 11/12 (November) |

**Formula**: `decimal_year = year + month/12`

This conversion:
- **Preserves temporal precision** for sub-annual survey data
- **Maintains a consistent numeric format** for all observations  
- **Enables proper sorting** and time-series analysis
- **Works identically** in both Python and R packages

```python
# Python: Data with monthly periods will have decimal years
df = get_unicef(indicator="NT_ANT_HAZ_NE2", countries=["BGD"])
print(df[["iso3", "period", "value"]].head())
#   iso3       period  value
# 0  BGD  2011.583333   40.0  # July 2011 (2011 + 7/12)
# 1  BGD  2011.750000   41.3  # September 2011 (2011 + 9/12)
```

```r
# R: Same decimal conversion
df <- get_unicef(indicator = "NT_ANT_HAZ_NE2", countries = "BGD")
head(df[, c("iso3", "period", "value")])
#   iso3       period  value
# 1  BGD  2011.583333   40.0
# 2  BGD  2011.750000   41.3
```

### Output Formats

```python
# Python: Long format (default) - one row per observation
df = get_unicef(indicator="CME_MRY0T4", format="long")

# Wide format - years as columns
df = get_unicef(indicator="CME_MRY0T4", format="wide")
# Result: iso3 | country | y2015 | y2016 | y2017 | ...

# Wide indicators format - indicators as columns (for multiple indicators)
df = get_unicef(
    indicator=["CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"],
    format="wide_indicators"
)
# Result: iso3 | country | period | CME_MRY0T4 | NT_ANT_HAZ_NE2_MOD
```

```r
# R: Same options
df <- get_unicef(indicator = "CME_MRY0T4", format = "wide")
df <- get_unicef(
  indicator = c("CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"),
  format = "wide_indicators"
)
```

### Latest Value Per Country

Get only the most recent non-missing observation per country (useful for cross-sectional analysis):

```python
# Python
df = get_unicef(indicator="CME_MRY0T4", latest=True)
# Each country has one row with its most recent value
# Note: The year may differ by country based on data availability
```

```r
# R
df <- get_unicef(indicator = "CME_MRY0T4", latest = TRUE)
```

### Most Recent Values (MRV)

Keep the N most recent years per country:

```python
# Python: Keep last 3 years per country
df = get_unicef(indicator="CME_MRY0T4", mrv=3)
```

```r
# R
df <- get_unicef(indicator = "CME_MRY0T4", mrv = 3)
```

### Add Country/Indicator Metadata

Enrich data with region, income group, and other metadata:

```python
# Python
df = get_unicef(
    indicator="CME_MRY0T4",
    add_metadata=["region", "income_group", "continent"]
)
# Result includes: iso3 | country | region | income_group | continent | ...
```

```r
# R
df <- get_unicef(
  indicator = "CME_MRY0T4",
  add_metadata = c("region", "income_group", "continent")
)
```

**Available metadata options:**

| Metadata | Description |
|----------|-------------|
| `region` | UNICEF/World Bank region (e.g., "Sub-Saharan Africa") |
| `income_group` | World Bank income classification (e.g., "Low income") |
| `continent` | Continent name (e.g., "Africa") |
| `indicator_name` | Full indicator name |
| `indicator_category` | Indicator category (CME, NUTRITION, etc.) |

### Combining Options

Post-production options can be combined for powerful data transformations:

```python
# Python: Cross-sectional analysis with metadata
df = get_unicef(
    indicator=["CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"],
    format="wide_indicators",
    latest=True,
    add_metadata=["region", "income_group"],
    dropna=True
)
# Result: One row per country with latest mortality and stunting values,
#         plus region and income group for analysis
```

```r
# R: Same approach
df <- get_unicef(
  indicator = c("CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"),
  format = "wide_indicators",
  latest = TRUE,
  add_metadata = c("region", "income_group"),
  dropna = TRUE
)
```

---

## Automatic Dataflow Detection

The package automatically downloads the complete UNICEF indicator codelist (733 indicators across 15 categories) on first use and caches it locally. This enables:

1. **No need to specify dataflow** - Just provide the indicator code
2. **Accurate mapping** - Each indicator maps to its correct dataflow
3. **Offline support** - Cache is saved to language-specific metadata directories
4. **Auto-refresh** - Cache is refreshed every 30 days

### Cache Locations

| Language | Cache Path |
|----------|------------|
| Python | `python/metadata/current/unicef_indicators_metadata.yaml` |
| R | `R/metadata/current/unicef_indicators_metadata.yaml` |

### Manual cache refresh

```python
# Python
from unicef_api import refresh_indicator_cache, get_cache_info

n = refresh_indicator_cache()  # Force refresh from API
info = get_cache_info()        # Check cache status
```

```r
# R
n <- refresh_indicator_cache()
info <- get_cache_info()
```

---

## Unified API Reference

### get_unicef() Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `indicator` | string/vector | required | Indicator code(s), e.g., `CME_MRY0T4` |
| `dataflow` | string | **auto-detect** | SDMX dataflow ID (optional - auto-detected from indicator) |
| `countries` | vector/list | NULL (all) | ISO3 country codes, e.g., `["ALB", "USA"]` |
| `start_year` | integer | NULL (all) | First year of data |
| `end_year` | integer | NULL (all) | Last year of data |
| `sex` | string | `_T` | Sex filter: `_T` (total), `F`, `M`, or NULL (all) |
| `tidy` | boolean | TRUE | Return cleaned data with standardized columns |
| `country_names` | boolean | TRUE | Add country name column |
| `max_retries` | integer | 3 | Number of retry attempts on failure |

#### Post-Production Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `format` | string | `"long"` | Output format: `"long"`, `"wide"`, or `"wide_indicators"` |
| `latest` | boolean | FALSE | Keep only latest non-missing value per country (year may vary) |
| `mrv` | integer | NULL | Keep only the N most recent values per country |
| `add_metadata` | vector/list | NULL | Metadata to add: `"region"`, `"income_group"`, `"continent"`, `"indicator_name"`, `"indicator_category"` |
| `dropna` | boolean | FALSE | Remove rows with missing values |
| `simplify` | boolean | FALSE | Keep only essential columns |

### search_indicators() Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | string | NULL | Search term (matches code, name, description) |
| `category` | string | NULL | Filter by category (e.g., `CME`, `NUTRITION`) |
| `limit` | integer | 50 | Max results to display (0 = unlimited) |
| `show_description` | boolean | TRUE | Include description column |

### list_categories()

No parameters. Displays all available categories with indicator counts.

---

## Available Categories

| Category | Count | Description |
|----------|-------|-------------|
| `GLOBAL_DATAFLOW` | 226 | General indicators |
| `NUTRITION` | 112 | Nutrition (stunting, wasting, etc.) |
| `WASH_HOUSEHOLDS` | 57 | Water and Sanitation |
| `EDUCATION` | 54 | Education indicators |
| `PT` | 50 | Child Protection |
| `CME` | 39 | Child Mortality Estimates |
| `HIV_AIDS` | 38 | HIV/AIDS indicators |
| `MNCH` | 38 | Maternal and Child Health |
| `DM` | 26 | Demographics |
| `MIGRATION` | 26 | Migration |
| `IMMUNISATION` | 18 | Immunization coverage |
| `GENDER` | 16 | Gender indicators |
| `ECON` | 13 | Economic indicators |
| `FUNCTIONAL_DIFF` | 12 | Functional difficulties |
| `ECD` | 8 | Early Childhood Development |

Use `list_categories()` for the complete list.

---

## Features

| Feature | R | Python |
|---------|---|--------|
| Unified `get_unicef()` API | ✅ | ✅ |
| **`search_indicators()`** | ✅ | ✅ |
| **`list_categories()`** | ✅ | ✅ |
| Auto dataflow detection | ✅ | ✅ |
| Filter by country, year, sex | ✅ | ✅ |
| Automatic retries | ✅ | ✅ |
| 733 indicators supported | ✅ | ✅ |
| **Post-production: `format`** | ✅ | ✅ |
| **Post-production: `latest`** | ✅ | ✅ |
| **Post-production: `mrv`** | ✅ | ✅ |
| **Post-production: `add_metadata`** | ✅ | ✅ |
| Metadata versioning | ✅ | ✅ |
| Disk-based caching | ✅ | No |

---

## Backward Compatibility (R)

Legacy parameter names still work:

| Legacy | New |
|--------|-----|
| `flow` | `dataflow` |
| `key` | `indicator` |
| `start_period` | `start_year` |
| `end_period` | `end_year` |
| `retry` | `max_retries` |

---

## Examples

See the examples directories:

- **R**: `R/examples/00_quick_start.R`
- **Python**: `python/examples/00_quick_start.py`

---

## Links

- UNICEF Data Portal: <https://data.unicef.org/>
- SDMX API Docs: <https://data.unicef.org/sdmx-api-documentation/>
- GitHub: <https://github.com/unicef-drp/unicefData>

---

## License

MIT License

# unicefData

[![R-CMD-check](https://github.com/unicef-drp/unicefData/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions) 
[![Python Tests](https://github.com/unicef-drp/unicefData/actions/workflows/python-tests.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions) 
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Stata 14+](https://img.shields.io/badge/Stata-14+-1a5276.svg)](https://www.stata.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Trilingual R, Python, and Stata library for downloading UNICEF child welfare indicators via SDMX API**

The **unicefData** package provides lightweight, consistent interfaces to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) in **R**, **Python**, and **Stata**. Inspired by `get_ilostat()` (ILO), `wb_data()` (World Bank), and `wbopendata` (World Bank for Stata), you can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.

---

## Quick Start

All three languages use **the same functions** with nearly identical parameter names.

### Python

```python
from unicef_api import unicefData, search_indicators, list_categories

# Don't know the indicator code? Search for it!
search_indicators("mortality")
list_categories()

# Fetch under-5 mortality for specific countries
# Dataflow is auto-detected from the indicator code!
df = unicefData(
    indicator="CME_MRY0T4",
    countries=["ALB", "USA", "BRA"],
    year="2015:2023"  # Range, or single year, or list [2015, 2018, 2020]
)

print(df.head())
```

### R

```r
library(unicefData)

# Don't know the indicator code? Search for it!
search_indicators("mortality")
list_categories()

# Fetch under-5 mortality for specific countries
# Dataflow is auto-detected from the indicator code!
df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA", "BRA"),
  year = "2015:2023"  # Range, or single year, or c(2015, 2018, 2020)
)

print(head(df))
```

### Stata

```stata
* Don't know the indicator code? Search for it!
unicefdata, categories        // List all categories
unicefdata, search(mortality)  // Search by keyword
unicefdata, dataflow(CME)     // Show dataflow schema (dimensions, attributes)

* Fetch under-5 mortality for specific countries
unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) ///
    year(2015:2023) clear

* View the data
list iso3 country indicator period value in 1/10

* For help and full syntax:
help unicefdata
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

### Stata Package

```stata
* Option 1: Install using the github package (recommended)
* First install github package (one-time): net install github, from("https://haghish.github.io/github/")
github install unicef-drp/unicefData, package(stata)

* Option 2: Install from local clone
* Clone repo first: git clone https://github.com/unicef-drp/unicefData.git
cd "path/to/unicefData/stata"
do install_local.do

* Option 3: Manual installation
* Copy files from stata/src/u/, stata/src/_/, stata/src/y/, stata/src/py/
* to your PLUS ado directory (find path with: sysdir)
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
source("R/unicefData.R")

search_indicators("mortality")
search_indicators("stunting")
search_indicators("immunization")
```

**Output (current, 2025-12-19):**
```
----------------------------------------------------------------------
Search Results for: mortality
----------------------------------------------------------------------

 Indicator         Dataflow       Name

 CME               CME            Child mortality
 CME_ARR_10T19     N/A            Annual Rate of Reduction in Mort...
 CME_MRM0          CME            Neonatal mortality rate
 CME_MRM1T11       N/A            Mortality rate age 1-11 months
 CME_MRM1T59       N/A            Mortality rate 1-59 months
 CME_MRY0          CME            Infant mortality rate
 CME_MRY0T4        CME            Under-five mortality rate
 CME_MRY10T14      CME            Mortality rate age 10-14
 CME_MRY10T19      CME            Mortality rate age 10-19
 CME_MRY15T19      CME            Mortality rate age 15-19

  (Showing first 10 matches. Use limit() option for more.)

----------------------------------------------------------------------
Found: 10 indicator(s)
----------------------------------------------------------------------
```
Note: Results may vary by API updates and sync date.

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

**Output (current, 2025-12-20):**
```
==================================================
  Available Indicator Categories
==================================================

  CATEGORY                       COUNT
--------------------------------------------------
  NUTRITION                        112
  CAUSE_OF_DEATH                    83
  CHILD_RELATED_SDG                 77
  WASH_HOUSEHOLDS                   57
  PT                                43
  CHLD_PVTY                         43
  CME                               39
  EDUCATION                         38
  HIV_AIDS                          38
  MNCH                              38
  DM                                26
  MIGRATION                         26
  IMMUNISATION                      18
  EDUCATION_UIS_SDG                 16
  GENDER                            16
  ECON                              13
  FUNCTIONAL_DIFF                   12
  SOC_PROTECTION                    10
  ECD                                8
  PT_CM                              8
  GLOBAL_DATAFLOW                    6
  PT_FGM                             6
--------------------------------------------------
  TOTAL                            733

  Use search_indicators(category='CATEGORY_NAME') to see indicators
```
Note: Counts may vary by sync date. Use `list_categories()` for current totals.

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

The `unicefData()` function includes powerful post-production options for data transformation and enrichment.

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
df = unicefData(indicator="NT_ANT_HAZ_NE2", countries=["BGD"])
print(df[["iso3", "period", "value"]].head())
#   iso3       period  value
# 0  BGD  2011.583333   40.0  # July 2011 (2011 + 7/12)
# 1  BGD  2011.750000   41.3  # September 2011 (2011 + 9/12)
```

```r
# R: Same decimal conversion
df <- unicefData(indicator = "NT_ANT_HAZ_NE2", countries = "BGD")
head(df[, c("iso3", "period", "value")])
#   iso3       period  value
# 1  BGD  2011.583333   40.0
# 2  BGD  2011.750000   41.3
```

### Output Formats

```python
# Python: Long format (default) - one row per observation
df = unicefData(indicator="CME_MRY0T4", format="long")

# Wide format - years as columns
df = unicefData(indicator="CME_MRY0T4", format="wide")
# Result: iso3 | country | y2015 | y2016 | y2017 | ...

# Wide indicators format - indicators as columns (for multiple indicators)
df = unicefData(
    indicator=["CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"],
    format="wide_indicators"
)
# Result: iso3 | country | period | CME_MRY0T4 | NT_ANT_HAZ_NE2_MOD
```

```r
# R: Same options
df <- unicefData(indicator = "CME_MRY0T4", format = "wide")
df <- unicefData(
  indicator = c("CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"),
  format = "wide_indicators"
)
```

### Latest Value Per Country

Get only the most recent non-missing observation per country (useful for cross-sectional analysis):

```python
# Python
df = unicefData(indicator="CME_MRY0T4", latest=True)
# Each country has one row with its most recent value
# Note: The year may differ by country based on data availability
```

```r
# R
df <- unicefData(indicator = "CME_MRY0T4", latest = TRUE)
```

### Most Recent Values (MRV)

Keep the N most recent years per country:

```python
# Python: Keep last 3 years per country
df = unicefData(indicator="CME_MRY0T4", mrv=3)
```

```r
# R
df <- unicefData(indicator = "CME_MRY0T4", mrv = 3)
```

### Circa (Nearest Year Matching)

When exact years aren't available, `circa=True` finds the closest data point:

```python
# Python: Get data closest to 2015 for each country
df = unicefData(indicator="NT_ANT_HAZ_NE2", year=2015, circa=True)
# Country A might get 2014 data, Country B might get 2016 if 2015 unavailable
```

```r
# R
df <- unicefData(indicator = "NT_ANT_HAZ_NE2", year = 2015, circa = TRUE)
```

```stata
* Stata
unicefdata, indicator(NT_ANT_HAZ_NE2) year(2015) circa clear
```

This is useful when working with survey-based indicators where timing varies by country.

### Add Country/Indicator Metadata

Enrich data with region, income group, and other metadata:

```python
# Python
df = unicefData(
    indicator="CME_MRY0T4",
    add_metadata=["region", "income_group", "continent"]
)
# Result includes: iso3 | country | region | income_group | continent | ...
```

```r
# R
df <- unicefData(
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
df = unicefData(
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
df <- unicefData(
  indicator = c("CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"),
  format = "wide_indicators",
  latest = TRUE,
  add_metadata = c("region", "income_group"),
  dropna = TRUE
)
```

---

## Automatic Dataflow Detection

The package automatically downloads the complete UNICEF indicator codelist (700+ indicators across multiple categories) on first use and caches it locally. This enables:

1. **No need to specify dataflow** - Just provide the indicator code
2. **Accurate mapping** - Each indicator maps to its correct dataflow
3. **Offline support** - Cache is saved to language-specific metadata directories
4. **Auto-refresh** - Cache is refreshed every 30 days

### Cache Locations

| Language | Cache Path |
|----------|------------|
| Python | `~/.unicef_data/python/metadata/current/unicef_indicators_metadata.yaml` (env overrides: `UNICEF_DATA_HOME_PY`, `UNICEF_DATA_HOME`); dev: `python/metadata/current/` |
| R | `tools::R_user_dir("unicefdata", "cache")/metadata/current/unicef_indicators_metadata.yaml` (fallback: `~/.unicef_data/r/metadata/current/...`; env overrides: `UNICEF_DATA_HOME_R`, `UNICEF_DATA_HOME`); dev: `R/metadata/current/` |
| Stata | Installed under `PLUS` (`plus/_` for YAML helpers); dev: `stata/metadata/current/` |

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

### unicefData() Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `indicator` | string/vector | required | Indicator code(s), e.g., `CME_MRY0T4` |
| `dataflow` | string | **auto-detect** | SDMX dataflow ID (optional - auto-detected from indicator) |
| `countries` | vector/list | NULL (all) | ISO3 country codes, e.g., `["ALB", "USA"]` |
| `year` | int/string/list | NULL (all) | Year(s): single (`2020`), range (`"2015:2023"`), or list (`[2015, 2018]`) |
| `circa` | boolean | FALSE | Find closest available year when exact year unavailable |
| `sex` | string | `_T` | Sex filter: `_T` (total), `F`, `M`, or `ALL` (all disaggregations) |
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
| `NUTRITION` | 112 | Nutrition (stunting, wasting, etc.) |
| `CAUSE_OF_DEATH` | 83 | Causes of death |
| `CHILD_RELATED_SDG` | 77 | SDG targets and goals |
| `WASH_HOUSEHOLDS` | 57 | Water and Sanitation |
| `PT` | 43 | Child Protection |
| `CHLD_PVTY` | 43 | Child Poverty |
| `CME` | 39 | Child Mortality Estimates |
| `EDUCATION` | 38 | Education indicators |
| `HIV_AIDS` | 38 | HIV/AIDS indicators |
| `MNCH` | 38 | Maternal and Child Health |
| `DM` | 26 | Demographics |
| `MIGRATION` | 26 | Migration |
| `IMMUNISATION` | 18 | Immunization coverage |
| `EDUCATION_UIS_SDG` | 16 | UNESCO Education SDG indicators |
| `GENDER` | 16 | Gender indicators |
| `ECON` | 13 | Economic indicators |
| `FUNCTIONAL_DIFF` | 12 | Functional difficulties |
| `SOC_PROTECTION` | 10 | Social protection programs |
| `ECD` | 8 | Early Childhood Development |
| `PT_CM` | 8 | Child Marriage |
| `GLOBAL_DATAFLOW` | 6 | General/uncategorized indicators |
| `PT_FGM` | 6 | Female Genital Mutilation |

Use `list_categories()` for the complete list.

---

## Dataflow Disaggregation Support

Different dataflows support different disaggregation dimensions. Use the `unicefdata, info(INDICATOR)` command in Stata (or equivalent in R/Python) to check which disaggregations are available for a specific indicator.

### Key Disaggregation Dimensions

| Dimension | Description | API Parameter |
|-----------|-------------|---------------|
| **SEX** | Gender disaggregation | `sex=` |
| **AGE** | Age group disaggregation | `age=` |
| **WEALTH_QUINTILE** | Wealth quintile disaggregation | `wealth=` |
| **RESIDENCE** | Urban/rural disaggregation | `residence=` |
| **MATERNAL_EDU_LVL** | Mother's education level | `maternal_edu=` |

### Disaggregation Availability by Dataflow

The following table shows which disaggregation dimensions are available for each dataflow (as of 2025-12-20):

| Dataflow | SEX | AGE | WEALTH | RESIDENCE | MATERNAL_EDU |
|----------|:---:|:---:|:------:|:---------:|:------------:|
| **CAUSE_OF_DEATH** | ✓ | ✓ | - | - | - |
| **CCRI** | - | - | - | - | - |
| **CHILD_RELATED_SDG** | ✓ | ✓ | ✓ | ✓ | - |
| **CHLD_PVTY** | ✓ | - | - | ✓ | - |
| **CME** | ✓ | - | ✓ | - | - |
| **CME_CAUSE_OF_DEATH** | ✓ | - | - | - | - |
| **CME_COUNTRY_PROFILES_DATA** | - | - | - | - | - |
| **CME_DF_2021_WQ** | ✓ | - | ✓ | - | - |
| **CME_SUBNATIONAL** | ✓ | - | ✓ | - | - |
| **COVID** | ✓ | ✓ | ✓ | ✓ | - |
| **COVID_CASES** | ✓ | ✓ | - | - | - |
| **DM** | ✓ | ✓ | - | ✓ | - |
| **DM_PROJECTIONS** | ✓ | ✓ | - | ✓ | - |
| **ECD** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **ECONOMIC** | - | - | - | - | - |
| **EDUCATION** | ✓ | - | ✓ | ✓ | - |
| **EDUCATION_FLS** | ✓ | - | - | - | - |
| **EDUCATION_UIS_SDG** | ✓ | - | ✓ | ✓ | - |
| **FUNCTIONAL_DIFF** | ✓ | ✓ | ✓ | ✓ | - |
| **GENDER** | ✓ | ✓ | - | ✓ | - |
| **GLOBAL_DATAFLOW** | ✓ | ✓ | - | - | - |
| **HIV_AIDS** | ✓ | ✓ | ✓ | ✓ | - |
| **IMMUNISATION** | - | ✓ | - | - | - |
| **MG** (Migration) | - | ✓ | - | - | - |
| **MNCH** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **NUTRITION** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **PT** (Child Protection) | ✓ | ✓ | ✓ | ✓ | - |
| **PT_CM** (Child Marriage) | ✓ | ✓ | ✓ | ✓ | - |
| **PT_CONFLICT** | ✓ | ✓ | - | - | - |
| **PT_FGM** | - | ✓ | ✓ | ✓ | - |
| **SDG_PROG_ASSESSMENT** | - | - | - | - | - |
| **SOC_PROTECTION** | ✓ | - | ✓ | ✓ | - |
| **WASH_HEALTHCARE_FACILITY** | - | - | - | ✓ | - |
| **WASH_HOUSEHOLDS** | - | - | ✓ | ✓ | - |
| **WASH_HOUSEHOLD_MH** | ✓ | ✓ | - | ✓ | - |
| **WASH_HOUSEHOLD_SUBNAT** | - | - | ✓ | ✓ | - |
| **WASH_SCHOOLS** | - | - | - | ✓ | - |

**Notes:**
- ✓ = Dimension available for disaggregation
- `-` = Dimension not available
- **CME_SUBNAT_*** dataflows (country-specific subnational): All support SEX and WEALTH_QUINTILE
- **MATERNAL_EDU** includes both `MATERNAL_EDU_LVL` and `MOTHER_EDUCATION` dimension names
- Availability does not guarantee data exists for all values; use API to check actual data coverage

### Checking Indicator Disaggregations

```stata
* Stata: Check what disaggregations are supported
unicefdata, info(CME_MRY0T4)

* Output shows:
*  Supported Disaggregations:
*    sex:          Yes (SEX)
*    age:          No
*    wealth:       Yes (WEALTH_QUINTILE)
*    residence:    No
*    maternal_edu: No
```

```python
# Python: Get indicator info
from unicef_api import indicator_info
indicator_info("CME_MRY0T4")
```

```r
# R: Get indicator info
indicator_info("CME_MRY0T4")
```

---

## Metadata Synchronization

The unicefData package maintains synchronized YAML metadata files across all three platforms (Python, R, Stata). These files contain dataflow definitions, indicator catalogs, country codes, and codelist mappings.

### Python

```python
import sys
sys.path.insert(0, 'python')

from unicef_api.metadata import MetadataSync
from unicef_api.schema_sync import sync_dataflow_schemas
from unicef_api.indicator_registry import refresh_indicator_cache

# Sync core metadata files
ms = MetadataSync()
ms.sync_all(verbose=True)

# Generate dataflow schemas (dataflows/*.yaml)
sync_dataflow_schemas(output_dir='python/metadata/current')

# Generate full indicator catalog (counts vary)
refresh_indicator_cache()
```

**Generated files:** `python/metadata/current/`
- `_unicefdata_dataflows.yaml` - dataflow catalog
- `_unicefdata_indicators.yaml` - common SDG indicators (subset)
- `_unicefdata_codelists.yaml` - dimension codelists
- `_unicefdata_countries.yaml` - country codes
- `_unicefdata_regions.yaml` - regional codes
- `unicef_indicators_metadata.yaml` - full indicator catalog
- `dataflow_index.yaml` - Dataflow schema index
- `dataflows/*.yaml` - individual dataflow schemas
Counts vary by API updates and sync date.

### R

```r
# Set working directory to R folder
setwd("R")

# Load and run metadata sync
source("metadata_sync.R")
sync_all_metadata(verbose = TRUE)

# Generate full indicator catalog
source("indicator_registry.R")
refresh_indicator_cache()

# Generate dataflow schemas (requires schema_sync.R)
source("schema_sync.R")
sync_dataflow_schemas()
```

**Generated files:** `R/metadata/current/`
- Same file structure as Python

### Stata

```stata
* Standard sync (uses Python for large XML files when available)
unicefdata_sync, verbose

* Pure Stata sync (with suffix for separate files)
unicefdata_sync, suffix("_stataonly") verbose

* View help for all options
help unicefdata_sync
```

**Generated files:** `stata/metadata/current/`
- Same file structure as Python/R
- `*_stataonly.yaml` files when using suffix option

#### ⚠️ Stata Limitations

The pure Stata XML parser has limitations with large XML files due to Stata's macro length restrictions (error 920). This affects:
- `dataflow_index.yaml` - May have empty dataflows list
- `dataflows/*.yaml` - Individual schema files may not be generated

**Recommended:** Use the standard `unicefdata_sync, verbose` command (without suffix) which uses Python assistance for complete metadata extraction. Or use Python directly:

```stata
python:
from unicef_api.schema_sync import sync_dataflow_schemas
sync_dataflow_schemas(output_dir='stata/metadata/current')
end
```

### Metadata Consistency

All platforms should generate matching metadata with:
- Same record counts across Python, R, and Stata
- Standardized `_metadata` headers with platform, version, timestamp
- Shared indicator definitions from `config/common_indicators.yaml`

Use the status script to verify consistency:

```bash
python tests/report_metadata_status.py --detailed
```

---

## Features

| Feature | R | Python | Stata |
|---------|---|--------|-------|
| Unified `unicefData()` / `unicefdata` API | ✅ | ✅ | ✅ |
| **`search_indicators()`** | ✅ | ✅ | ✅ |
| **`list_categories()`** | ✅ | ✅ | ✅ |
| **Dataflow schema display** | ✅ | ✅ | ✅ |
| Auto dataflow detection | ✅ | ✅ | ✅ |
| Filter by country, year, sex | ✅ | ✅ | ✅ |
| Unified `year` parameter | ✅ | ✅ | ✅ |
| **`circa` nearest year matching** | ✅ | ✅ | ✅ |
| Automatic retries | ✅ | ✅ | ✅ |
| 700+ indicators supported | ✅ | ✅ | ✅ |
| **Post-production: `format`** | ✅ | ✅ | ✅ |
| **Post-production: `latest`** | ✅ | ✅ | ✅ |
| **Post-production: `mrv`** | ✅ | ✅ | ✅ |
| **Post-production: `add_metadata`** | ✅ | ✅ | 🔜 |
| Metadata versioning | ✅ | ✅ | ✅ |
| Disk-based caching | ✅ | No | ✅ |
| YAML metadata sync | ✅ | ✅ | ✅ |

---

## Backward Compatibility (R)

Legacy parameter names still work:

| Legacy | New |
|--------|-----|
| `flow` | `dataflow` |
| `key` | `indicator` |
| `start_year` | `year` (use `"2015:2023"` for range) |
| `end_year` | `year` (use `"2015:2023"` for range) |
| `start_period` | `year` |
| `end_period` | `year` |
| `retry` | `max_retries` |

---

## Examples

See the examples directories:

- **R**: `R/examples/00_quick_start.R`
- **Python**: `python/examples/00_quick_start.py`
- **Stata**: `stata/examples/` and `help unicefdata`

---

## Project Structure

```
unicefData/
├── config/                 # Shared configuration
│   └── common_indicators.yaml  # 25 SDG indicators (Python/R/Stata source)
├── R/                      # R package source
│   ├── metadata/current/   # R metadata files
│   └── *.R                 # R source files
├── python/                 # Python package source
│   ├── metadata/current/   # Python metadata files
│   └── unicef_api/         # Python package
├── stata/                  # Stata package source
│   ├── src/u/              # Main ado files (unicefdata.ado, etc.)
│   ├── src/_/              # Internal subroutines
│   ├── metadata/current/   # Stata metadata files
│   └── examples/           # Stata examples
├── tests/                  # Cross-platform test utilities
│   ├── orchestrator_metadata.py     # Master sync orchestrator
│   ├── sync_metadata_python.py      # Python metadata sync
│   ├── sync_metadata_r.R            # R metadata sync
│   ├── sync_metadata_stata.do       # Stata metadata sync
│   ├── report_metadata_status.py    # Metadata consistency checker
│   └── README.md                    # Test documentation
└── README.md
```

---

## Links

- UNICEF Data Portal: <https://data.unicef.org/>
- SDMX API Docs: <https://data.unicef.org/sdmx-api-documentation/>
- GitHub: <https://github.com/unicef-drp/unicefData>

---

## License

MIT License

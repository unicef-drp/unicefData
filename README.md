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
unicefdata, flows             // List all dataflows
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

#### Tiered Discovery (Stata)

Discovery commands include tier filters to control which indicators appear:

- Default: Tier 1 only (verified and downloadable)
- `showtier2`: include Tier 2 (officially defined, no data) — warning shown
- `showtier3` / `showlegacy`: include Tier 3 (legacy/undocumented) — warning shown
- `showall`: include Tiers 1–3
- `showorphans`: include orphan indicators (taxonomy maintenance)

Examples:

```stata
unicefdata, search(stunting) limit(10)          // Tier 1
unicefdata, search(stunting) limit(10) showtier2
unicefdata, search(stunting) limit(10) showtier3
unicefdata, search(stunting) limit(20) showall
```

#### Tier Classification System

The package uses a 4-tier system to classify indicator availability and reliability:

```
┌─────────────────────────────────────────────────────────────────┐
│                    TIER CLASSIFICATION                          │
└─────────────────────────────────────────────────────────────────┘

Tier 1 (480 indicators) - ✅ VERIFIED AND DOWNLOADABLE
├─ Has valid dataflow mapping (e.g., CME, NT, MNCH)
├─ Data available via SDMX API
├─ Fully tested and validated
└─ Example: CME_MRY0T4 (Under-5 mortality)

Tier 2 (0 indicators) - ⚠️  LIMITED/DEPRECATED
├─ Has dataflow but marked as limited access
├─ May have restricted availability
└─ Use with caution

Tier 3 (0 indicators) - ⚠️  NO DATA AVAILABLE
├─ Has 'nodata' or empty dataflow mapping
├─ Metadata exists but no data in API
└─ Indicator definition only

Tier 4 (258 indicators) - ❌ NO DATAFLOW MAPPING
├─ No dataflow information available
├─ Cannot be downloaded via API
├─ Orphan indicators (taxonomy maintenance)
└─ Example: CME (parent category, not downloadable)

┌─────────────────────────────────────────────────────────────────┐
│              DOWNLOAD TROUBLESHOOTING BY TIER                   │
└─────────────────────────────────────────────────────────────────┘

Error: "Could not fetch data from any dataflow"
│
├─ Check indicator tier:
│   └─ unicefdata, search(YourIndicatorCode)
│
├─ If Tier 1: Network/API issue
│   ├─ Check internet connection
│   ├─ Verify firewall settings
│   ├─ Try: set timeout1 30
│   └─ Check: https://sdmx.data.unicef.org/
│
├─ If Tier 3/4: Indicator not downloadable
│   ├─ Search for related Tier 1 indicators
│   ├─ Example: Search child indicators of category
│   └─ unicefdata, search(RelatedTerm) limit(20)
│
└─ Alternative: Manually specify dataflow
    └─ unicefdata, indicator(CODE) dataflow(DATAFLOW_NAME)

```

> **Note:** You don't need to specify `dataflow`! The package automatically detects it from the indicator code on first use, fetching the complete indicator codelist (733 indicators) from the UNICEF SDMX API.

---

## 🆕 What's New in v2.0.4 (Stata)

**Bug Fix Release** - February 1, 2026

* **False warning fix**: Resolved issue where valid disaggregation filters showed "NOT supported" warnings
  - Fixed metadata_path reset logic (line 707 of unicefdata.ado)
  - Changed from unconditional reset to conditional fallback
  - Eliminates false warnings while maintaining error detection
  - Validated: 32/32 cross-platform indicators (100% consistency)

* **Examples documentation refresh**: Updated unicefdata_examples.ado to match v2.0.4 API
  - Improved syntax clarity
  - Better disaggregation handling examples
  - Aligned with latest metadata system

* **Cross-platform alignment**: Python (sdmx_client.py) and R (unicefData.R, unicef_core.R) updated for consistency
  - All three platforms now use corrected metadata_path handling logic
  - Python tests: 28/28 passing (1 optional)
  - R tests: 8/8 passing (100%)

## 🆕 What's New in v2.0.0 (Stata)

**Major Quality Milestone** - All QA tests passing (38/38, 100% success rate)

* **SYNC-02 Enrichment Fix**: Resolved critical path extraction bug
  - Fixed directory path extraction logic in metadata enrichment pipeline
  - Phase 2-3 enrichment now working: tier classification + disaggregations
  - Previously: 37/38 tests passing (SYNC-02 failed)
  - Now: 38/38 tests passing in 10m 17s

* **Enhanced Reliability**: Metadata synchronization pipeline fully operational
  - All enrichment phases complete successfully
  - Improved YAML file path resolution
  - Better error handling and diagnostics

## 🆕 What's New in v1.10.0 (Stata)

**Released**: January 19, 2026

### Added (Stata)
- **Regression snapshot testing (REGR-01)**: Baseline comparison system to detect silent API data regressions using historical snapshots with ±0.01 tolerance
- **Country name generation**: Automatically generates `country` variable from `iso3` codes using country lookup table
- **Enhanced UTF-8 support**: Full Unicode character preservation across XML→YAML→Stata pipeline
- **Enhanced info() display**: Shows SDMX dimension codes alongside human-readable values with clickable API Query URLs
- **Debug options**: Added `debug`, `trace`, and `verbose` options for troubleshooting
- **Improved error handling**: Better error messages and fallback behavior for missing data

### Fixed (Stata)
- YAML metadata parsing now uses `yaml get` (compatible with all yaml package versions)
- wide_indicators reshape now correctly creates indicator columns
- Unicode accents preserved in country names (e.g., "Côte d'Ivoire")
- Case-insensitive CSV variable renaming (handles Stata's automatic lowercase conversion)

### Quality Metrics (Stata)
- **Test coverage**: ✅ **30/30 tests passing (100% coverage)**
- **Test suite**: 6 categories (ENV, DL, DIS, FILT, META, EDGE, REGR) with comprehensive QA documentation
- **Regression baselines**: 2 validated snapshots (mortality, vaccination) for API stability monitoring
- **Platforms**: Tested on Windows, macOS, Linux
- **Stata versions**: Compatible with Stata 14+

## What's New in v1.9.0 (Stata)

**Released**: January 17, 2026

### Added (Stata)
- Tiered discovery options in `unicefdata`: default Tier 1; opt-in `showtier2`, `showtier3`, `showall`, `showorphans`
- Warning messages when non-default tiers are included to indicate provenance and risk
- Examples do-file for tiers: `doc/examples/run_tier_examples.do`

---

## 🆕 What's New in v1.5.2

**Released**: January 6, 2026

### Fixed
- **404 fallback behavior**: Invalid indicators now return empty results (not errors) across all platforms with automatic fallback to GLOBAL_DATAFLOW
- **Quick-start examples**: Updated from deprecated `start_year`/`end_year` to unified `year` parameter
- **User-Agent (Python)**: Resolved circular import preventing dynamic version detection

### Added
- **Dynamic User-Agent strings**: All platforms now send descriptive UA with version, runtime, and OS for better API tracking
  - R: `unicefData-R/1.5.2 (R/4.x.x; Windows)`
  - Python: `unicefData-Python/1.5.2 (Python/3.11.5; Windows)`
  - Stata: `unicefData-StataSync/1.5.2 (Python/3.11.5; Windows)`
- **Comprehensive test coverage**: 24 new tests across R and Python validating PR #14 features
  - R: 14 tests (5 for 404 fallback, 7 for list_dataflows wrapper)
  - Python: 10 tests (4 for 404 fallback, 6 for list_dataflows wrapper)
- **Quick verification scripts**: Added rapid validation tools for testing changes

### Improved
- **list_dataflows() wrapper**: Consistent schema with documented columns across all platforms
- **Error handling**: More informative messages when indicators not found
- **Test alignment**: R and Python now have matching test coverage for identical behaviors

See [NEWS.md](NEWS.md) (R/Stata) and [python/CHANGELOG.md](python/CHANGELOG.md) (Python) for full changelogs.

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

### Quick Start (Automated)

**Stata (Recommended):**
```stata
* Full metadata refresh (all files, all languages)
unicefdata_refresh_all, verbose

* Check metadata age
unicefdata_sync, verbose

* Force manual sync (without staleness warning)
unicefdata_sync, force verbose
```

**PowerShell (Cross-language sync):**
```powershell
# Sync Stata metadata to Python/R
.\scripts\sync_metadata_cross_language.ps1
```

**Python:**
```python
from tests import orchestrator_metadata
orchestrator_metadata.sync_all()
```

**R:**
```r
source("tests/sync_metadata_r.R")
```

---

### Metadata Refresh Workflow

The package uses a **4-step metadata refresh workflow** to ensure consistency:

1. **Base metadata** — Sync core structures (dataflows, codelists, countries, regions)
2. **Dataflow dimension values** — Query SDMX `/data/` endpoint to extract actual values for each dimension
3. **Indicator enrichment** — Fetch complete indicator codelist with dataflow mappings
4. **Dimension enrichment** — Add available dimension values to indicator metadata

**Command:**
```stata
unicefdata_refresh_all, verbose
```

**What it does:**
- Runs `unicefdata_sync` for base metadata
- Calls Python script `build_dataflow_metadata.py` to query API for dimension values
- Re-syncs indicator metadata with dataflow mappings
- Calls Python script `enrich_indicators_metadata.py` to add dimension values
- Updates sync history with timestamps and checksums

**Output:**
```
┌─────────────────────────────────────────────┐
│ unicefData Metadata Refresh Summary         │
└─────────────────────────────────────────────┘

  ✓ Step 1: Base metadata synced
  ✓ Step 2: Dataflow dimension values extracted
  ✓ Step 3: Indicator metadata enriched
  ⚠ Step 4: Dimension enrichment skipped (Python script not found)

Metadata files updated:
  - _unicefdata_dataflows.yaml
  - _unicefdata_dataflow_metadata.yaml
  - _unicefdata_indicators_metadata.yaml
  - _unicefdata_countries.yaml
  - _unicefdata_regions.yaml
  - _unicefdata_sync_history.yaml

All metadata synced successfully.
```

---

### Staleness Detection

The package **automatically warns** if metadata is >30 days old:

```stata
. unicefdata, indicator(CME_MRY0T4) clear

⚠ WARNING: Metadata is 45 days old (last sync: 2025-11-15)

  Metadata may be outdated. Consider refreshing:

  {stata unicefdata_refresh_all, verbose}  (full refresh - recommended)
  {stata unicefdata_sync, force verbose}   (selective refresh)

  To suppress this warning, use: unicefdata_sync, force
```

**Note:** Staleness check only runs when:
- User does NOT specify `force` option
- Sync history file exists
- `verbose` option shows age even if <30 days

---

### Automated Refresh (GitHub Actions)

Metadata is automatically refreshed **every Monday at 2 AM UTC** via GitHub Actions workflow. See [`.github/workflows/metadata-sync.yml`](.github/workflows/metadata-sync.yml) for implementation.

The workflow:
- Runs Python scripts to query SDMX API for latest dimension values
- Updates metadata files if changes detected
- Auto-commits with `[skip ci]` to prevent loops
- Creates GitHub issue if refresh fails

**Manual trigger:** Go to Actions tab → "Weekly Metadata Refresh" → Run workflow

---

### Cross-Language Metadata Sync

To ensure Python, R, and Stata use **identical metadata**, run:

```powershell
# Copies metadata from Stata (canonical) to Python/R
.\scripts\sync_metadata_cross_language.ps1

# Dry run (preview changes)
.\scripts\sync_metadata_cross_language.ps1 -DryRun
```

**What it syncs:**
- `_unicefdata_dataflow_metadata.yaml` (dimension values)
- `_unicefdata_indicators_metadata.yaml` (indicator→dataflow mappings)
- `_unicefdata_dataflows.yaml` (dataflow schemas)
- `_unicefdata_countries.yaml`, `_unicefdata_regions.yaml`
- `_unicefdata_sync_history.yaml` (sync timestamps)

**Output:**
```
  ≡ SAME: _unicefdata_dataflows.yaml → Python (hash: 7f3a2b9c4d1e6...)
  ↻ UPDATE: _unicefdata_dataflow_metadata.yaml → Python
    Source: a1b2c3d4e5f6...
    Target: 9z8y7x6w5v4u...
  + NEW: _unicefdata_indicators_metadata.yaml → R

  Files synced:  3
  Files skipped: 2
  Errors:        0

✓ Cross-language metadata sync complete
```

---

### Metadata Consistency Check

To verify all three languages have matching metadata:

```bash
python tests/report_metadata_status.py
```

This reports:
- File existence across languages
- SHA256 checksums (detects drift)
- Timestamp discrepancies
- Missing files

---

### Language-Specific Sync (Advanced)

**Python:**
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

# Generate full indicator catalog
refresh_indicator_cache()
```

**R:**
```r
setwd("R")
source("metadata_sync.R")
sync_all_metadata(verbose = TRUE)

source("indicator_registry.R")
refresh_indicator_cache()

source("schema_sync.R")
sync_dataflow_schemas()
```

**Stata:**
```stata
* Standard sync (uses Python for large XML when available)
unicefdata_sync, verbose

* Pure Stata sync (with suffix for separate files)
unicefdata_sync, suffix("_stataonly") verbose
```

**Generated files:** All languages produce identical YAML files in their respective `metadata/current/` directories
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

## Testing & Validation

The **unicefData** package includes a comprehensive cross-platform validation framework to ensure data consistency and API compatibility across all three languages (Python, R, Stata).

### Quick Validation Run

```bash
cd validation
python run_validation.py --limit 10 --seed 42 --languages python r stata
```

**Parameters:**
- `--limit`: Number of indicators to test (default: 10)
- `--seed`: Random seed for reproducibility (default: 42)
- `--languages`: Which platforms to test: python, r, stata (default: python)
- `--valid-only`: Test only Tier 1 indicators (default: true)
- `--verbose`: Enable verbose output (flag)

### Validation Results

Results are cached for speed and stored in:
- **Logs**: `logs/YYYYMMDD/indicator_validation_HHMMSS/`
- **Cache**: `cache/{language}/*.csv` with metadata tracking
- **Results**: `results/YYYYMMDD/` with per-language summaries

### Validation Features

✓ **Cross-Platform Consistency**: Tests same indicators across Python, R, and Stata  
✓ **Smart Caching**: Uses cached data for ~3000x speedup  
✓ **Automatic Metadata Loading**: Dataflow detection, region codes, indicators  
✓ **Error Detection**: Identifies platform-specific issues (e.g., 404s, timeouts)  
✓ **Reproducibility**: Fixed seed ensures consistent indicator selection  

### Troubleshooting Validation Issues

- **"No cached indicators found"** → First run; cache will build automatically
- **"Codelists file not found"** → Non-critical; metadata manager provides defaults
- **Platform inconsistencies** → Check logs in `logs/` for per-platform errors

For detailed information, see:
- [VALIDATION_QUICK_START.md](VALIDATION_QUICK_START.md) — Command reference
- [ROOT_CAUSE_ANALYSIS.md](ROOT_CAUSE_ANALYSIS.md) — Architecture and fixes
- [VALIDATION_SUMMARY_*.md](VALIDATION_SUMMARY_20260120.md) — Recent runs

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
├── validation/             # Cross-platform validation framework
│   ├── run_validation.py   # Entry point for validation runs
│   ├── scripts/            # Orchestration and test engine
│   ├── cache/              # Test data cache (per-language)
│   ├── logs/               # Detailed test logs
│   ├── results/            # Validation results and summaries
│   └── README.md           # Validation documentation
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

## Author

**Joao Pedro Azevedo** ([@jpazvd](https://github.com/jpazvd))  
Chief Statistician, UNICEF Data and Analytics Section

---

## Contributing

Contributions are welcome! Whether it's bug reports, feature requests, or code contributions, we appreciate your help in improving this package.

### How to Contribute

1. **Report bugs** — Open an [issue](https://github.com/unicef-drp/unicefData/issues) with a clear description
2. **Request features** — Suggest new indicators, filters, or functionality
3. **Submit code** — Fork the repo, create a branch, and open a pull request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/unicef-drp/unicefData.git
cd unicefData

# For Python development
cd python && pip install -e .

# For R development
# Open unicefData.Rproj in RStudio

# For Stata development
cd stata && do install_local.do
```

Please ensure your contributions pass the existing tests before submitting a PR.

---

## Release & Versioning

This project follows Semantic Versioning (MAJOR.MINOR.PATCH) and uses Conventional Commits to automate version bumps and releases. For the full policy, test gating, and tagging flow, see the workspace guide:

- Release & Versioning: ../.unicef/RELEASE_GUIDE.md


---

## Links

- UNICEF Data Portal: <https://data.unicef.org/>
- SDMX API Docs: <https://data.unicef.org/sdmx-api-documentation/>
- GitHub: <https://github.com/unicef-drp/unicefData>

---

## License

MIT License

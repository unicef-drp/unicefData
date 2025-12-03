# UNICEF API - R Library

[![R 4.0+](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**R component of the bilingual unicefData library for downloading UNICEF SDG indicators via SDMX API**

This is the R implementation of the **unicefData** package. For the Python implementation, see the [python directory](../python/README.md).

## 🌐 Bilingual Package

The **unicefData** repository provides consistent APIs in both R and Python:

| Feature | R | Python |
|---------|---|--------|
| Unified API | `get_unicef()` | `get_unicef()` |
| **Search indicators** | `search_indicators()` | `search_indicators()` |
| **List categories** | `list_categories()` | `list_categories()` |
| **Auto dataflow detection** | ✅ | ✅ |
| List dataflows | `list_dataflows()` | `list_dataflows()` |
| 733 indicators | ✅ | ✅ |
| Automatic retries | ✅ | ✅ |
| Country name lookup | ✅ | ✅ |

## 🚀 Features

- **Easy-to-use API**: Simple R interface for UNICEF SDMX data
- **Auto dataflow detection**: No need to know which dataflow an indicator is in
- **Search capability**: Find indicators using `search_indicators()` and `list_categories()`
- **Comprehensive coverage**: Access 733 indicators across 15 categories
- **Automatic data cleaning**: Standardized Tibbles ready for analysis
- **Decimal year conversion**: Monthly periods (YYYY-MM) converted to decimal years for time-series analysis
- **Error handling**: Comprehensive error messages and automatic retries
- **Flexible filtering**: Filter by country, year, sex, age, wealth, residence, maternal education
- **Multiple dataflows**: Support for specialized dataflows (CME, NUTRITION, EDUCATION, etc.)
- **Wide Formats**: Pivot data by year, indicator, sex, wealth, etc.

## 📅 Time Period Handling

**Important**: The UNICEF SDMX API returns TIME_PERIOD values in various formats. This library automatically converts them to decimal years for consistent time-series analysis:

| Original Format | Decimal Year | Calculation |
|----------------|--------------|-------------|
| `2020` | `2020.0` | Integer year |
| `2020-01` | `2020.0833` | 2020 + 1/12 (January) |
| `2020-06` | `2020.5000` | 2020 + 6/12 (June) |
| `2020-11` | `2020.9167` | 2020 + 11/12 (November) |

**Formula**: `decimal_year = year + month/12`

This conversion:
- Preserves temporal precision for sub-annual survey data
- Maintains a consistent numeric format for all observations
- Enables proper sorting and time-series analysis
- Works identically in both Python and R packages

## 📦 Installation

You can source the scripts directly from this repository:

```r
source("R/unicef_api/get_unicef.R")
```

Dependencies:
- `dplyr`
- `httr`
- `readr`
- `magrittr`
- `countrycode`
- `tidyr`
- `memoise`
- `xml2`
- `yaml`

## 🎯 Quick Start

### Basic Usage

```r
source("R/unicef_api/get_unicef.R")

# Fetch under-5 mortality for specific countries
# Dataflow is auto-detected from indicator code!
df <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA", "BRA"),
  start_year = 2015,
  end_year = 2023
)

print(head(df))
```

### Wide Formats

Pivot your data easily:

```r
# Wide by Wealth Quintile
df_wealth <- get_unicef(
  indicator = "CME_MRY0T4",
  countries = c("COL", "PER"),
  format = "wide_wealth"
)

# Wide by Sex
df_sex <- get_unicef(
  indicator = "HIV_AIDS_INDICATOR",
  format = "wide_sex"
)
```

### Search Indicators

```r
# Search for mortality indicators
search_indicators("mortality")

# List all available categories
list_categories()
```

## 📂 Directory Structure

- `unicef_api/`: Core R scripts and API implementation
- `examples/`: Usage examples and tutorials
- `metadata/`: Cached metadata and schemas

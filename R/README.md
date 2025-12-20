# UNICEF API - R Library

[![R 4.0+](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**R component of the trilingual unicefData library for downloading UNICEF SDG indicators via SDMX API**

This is the R implementation of the **unicefData** package. For other implementations, see the links below.

> 📦 **Other languages:** [Python](../python/README.md) | [Stata](../stata/README.md) | [Main README](../README.md)

## 🌐 Trilingual Package

The **unicefData** repository provides consistent APIs in R, Python, and Stata:

| Feature | R | Python | Stata |
|---------|---|--------|-------|
| Unified API | `unicefData()` | `unicefData()` | `unicefdata` |
| **Search indicators** | `search_indicators()` | `search_indicators()` | `unicefdata, search()` |
| **List categories** | `list_categories()` | `list_categories()` | `unicefdata, categories` |
| **Auto dataflow detection** | ✅ | ✅ | ✅ |
| **Dataflow schema** | `dataflow_schema()` | `dataflow_schema()` | `unicefdata, dataflow()` |
| List dataflows | `list_dataflows()` | `list_dataflows()` | `unicefdata, flows` |
| 733 indicators | ✅ | ✅ | ✅ |
| Automatic retries | ✅ | ✅ | ✅ |
| Country name lookup | ✅ | ✅ | ✅ |

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
- **Batch downloads**: Fetch multiple indicators efficiently

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
source("R/unicefData.R")
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
source("R/unicef_api/unicefData.R")

# Fetch under-5 mortality for specific countries
# Dataflow is auto-detected from indicator code!
df <- unicefData(
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
df_wealth <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("COL", "PER"),
  format = "wide_wealth"
)

# Wide by Sex
df_sex <- unicefData(
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

### Dataflow Schema

View the dimensions and attributes available for a dataflow:

```r
# Get schema for Child Mortality dataflow
schema <- dataflow_schema("CME")
print(schema)

# Access components
schema$dimensions  # REF_AREA, INDICATOR, SEX, WEALTH_QUINTILE
schema$attributes  # DATA_SOURCE, COUNTRY_NOTES, REF_PERIOD, ...
```

## 📂 Directory Structure

- `examples/`: Usage examples and tutorials
- `metadata/`: Cached metadata and schemas

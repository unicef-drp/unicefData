# UNICEF API - Python Library

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Python component of the trilingual unicefData library for downloading UNICEF SDG indicators via SDMX API**

This is the Python implementation of the **unicefData** package. For other implementations, see the links below.

> 📦 **Other languages:** [R](../R/README.md) | [Stata](../stata/README.md) | [Main README](../README.md)

## 🌐 Trilingual Package

The **unicefData** repository provides consistent APIs in R, Python, and Stata:

| Feature | R | Python | Stata |
|---------|---|--------|-------|
| Unified API | `get_unicef()` | `get_unicef()` | `unicefdata` |
| **Search indicators** | `search_indicators()` | `search_indicators()` | `unicefdata, search()` |
| **List categories** | `list_categories()` | `list_categories()` | `unicefdata, categories` |
| **Auto dataflow detection** | ✅ | ✅ | ✅ |
| **Dataflow schema** | `dataflow_schema()` | `dataflow_schema()` | `unicefdata, dataflow()` |
| List dataflows | `list_dataflows()` | `list_dataflows()` | `unicefdata, flows` |
| 733 indicators | ✅ | ✅ | ✅ |
| Automatic retries | ✅ | ✅ | ✅ |
| Country name lookup | ✅ | ✅ | ✅ |

## 🚀 Features

- **Easy-to-use API**: Simple Python interface for UNICEF SDMX data
- **Auto dataflow detection**: No need to know which dataflow an indicator is in
- **Search capability**: Find indicators using `search_indicators()` and `list_categories()`
- **Comprehensive coverage**: Access 733 indicators across 15 categories
- **Automatic data cleaning**: Standardized DataFrames ready for analysis
- **Decimal year conversion**: Monthly periods (YYYY-MM) converted to decimal years for time-series analysis
- **Error handling**: Comprehensive error messages and automatic retries
- **Flexible filtering**: Filter by country, year, sex disaggregation
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

```bash
cd python
pip install -e .
```

Or install dependencies directly:

```bash
pip install -r requirements.txt
```

## 🎯 Quick Start

### Find Indicators

Don't know the indicator code? Search for it!

```python
from unicef_api import search_indicators, list_categories

# Search for mortality indicators
search_indicators("mortality")

# Search for nutrition indicators
search_indicators("stunting")

# List all available categories (15 categories, 733 indicators)
list_categories()

# Search within a category
search_indicators(category="CME")  # All child mortality indicators
search_indicators("rate", category="CME")  # Only rates
```

### Dataflow Schema

View the dimensions and attributes available for a dataflow:

```python
from unicef_api import dataflow_schema, print_dataflow_schema

# Get schema for Child Mortality dataflow
schema = dataflow_schema("CME")
print_dataflow_schema(schema)

# Access components
schema['dimensions']  # ['REF_AREA', 'INDICATOR', 'SEX', 'WEALTH_QUINTILE']
schema['attributes']  # ['DATA_SOURCE', 'COUNTRY_NOTES', 'REF_PERIOD', ...]
```

### Basic Usage

```python
from unicef_api import get_unicef

# Fetch under-5 mortality for specific countries
# Dataflow is auto-detected from indicator code!
df = get_unicef(
    indicator='CME_MRY0T4',
    countries=['ALB', 'USA', 'BRA'],
    start_year=2015,
    end_year=2023
)

print(df.head())
```

### Post-Production Options

```python
# Get latest value per country (cross-sectional analysis)
df = get_unicef(
    indicator='CME_MRY0T4',
    latest=True  # Each country has one row with most recent value
)

# Wide format - years as columns
df = get_unicef(
    indicator='CME_MRY0T4',
    format='wide'  # Result: iso3 | country | y2015 | y2016 | ...
)

# Multiple indicators with automatic merge
df = get_unicef(
    indicator=['CME_MRY0T4', 'NT_ANT_HAZ_NE2_MOD'],
    format='wide_indicators',  # Result: iso3 | period | CME_MRY0T4 | NT_ANT_HAZ_NE2_MOD
    latest=True
)

# Add country metadata (region, income group)
df = get_unicef(
    indicator='CME_MRY0T4',
    add_metadata=['region', 'income_group', 'continent'],
    latest=True
)

# Keep only last 3 years per country
df = get_unicef(indicator='CME_MRY0T4', mrv=3)

# Drop missing values and simplify columns
df = get_unicef(
    indicator='CME_MRY0T4',
    dropna=True,
    simplify=True
)
```

### Using UNICEFSDMXClient (Advanced)

```python
from unicef_api import UNICEFSDMXClient

# Initialize client
client = UNICEFSDMXClient()

# Fetch under-5 mortality for specific countries
df = client.fetch_indicator(
    'CME_MRY0T4',
    countries=['ALB', 'USA', 'BRA'],
    start_year=2015,
    end_year=2023
)

print(df.head())
```

### Fetch Multiple Indicators

```python
# Fetch multiple indicators at once
indicators = ['CME_MRY0T4', 'NT_ANT_HAZ_NE2_MOD', 'IM_DTP3']

df = client.fetch_multiple_indicators(
    indicators,
    countries=['ALB', 'USA'],
    start_year=2015,
    combine=True  # Combine into single DataFrame
)
```

### Fetch All Countries

```python
# Fetch all available countries (no country filter)
df = client.fetch_indicator('CME_MRY0T4', start_year=2020)

print(f"Downloaded data for {df['country_code'].nunique()} countries")
```

### Using Specific Dataflows

```python
# Use specialized dataflow for better performance
df = client.fetch_indicator(
    'NT_ANT_HAZ_NE2_MOD',
    dataflow='NUTRITION',
    countries=['IND', 'BGD', 'PAK']
)
```

## 📊 Common Indicators

### Child Mortality (SDG 3.2)
- `CME_MRM0` - Neonatal mortality rate
- `CME_MRY0T4` - Under-5 mortality rate

### Nutrition (SDG 2.2)
- `NT_ANT_HAZ_NE2_MOD` - Stunting prevalence
- `NT_ANT_WHZ_NE2` - Wasting prevalence
- `NT_ANT_WHZ_PO2_MOD` - Overweight prevalence

### Education (SDG 4.1)
- `ED_CR_L1_UIS_MOD` - Primary completion rate
- `ED_CR_L2_UIS_MOD` - Lower secondary completion rate
- `ED_READ_L2` - Reading proficiency
- `ED_MAT_L2` - Mathematics proficiency

### Immunization (SDG 3.b)
- `IM_DTP3` - DTP3 immunization coverage
- `IM_MCV1` - Measles immunization coverage

### WASH (SDG 6.1, 6.2)
- `WS_PPL_W-SM` - Safely managed drinking water
- `WS_PPL_S-SM` - Safely managed sanitation
- `WS_PPL_H-B` - Basic handwashing facilities

### Child Protection (SDG 5.3, 16.2, 16.9)
- `PT_CHLD_Y0T4_REG` - Birth registration
- `PT_F_20-24_MRD_U18_TND` - Child marriage
- `PT_F_15-49_FGM` - Female genital mutilation
- `PT_CHLD_1-14_PS-PSY-V_CGVR` - Violent discipline

See `unicef_api/config.py` for complete list of indicators.

## 🛠️ Advanced Usage

### Data Cleaning and Transformation

```python
from unicef_api.utils import clean_dataframe, pivot_wide, calculate_growth_rate

# Clean data
df_clean = clean_dataframe(
    df,
    remove_nulls=True,
    remove_duplicates=True,
    sort_by=['country_code', 'year']
)

# Pivot to wide format
df_wide = pivot_wide(df, index_cols=['country_code', 'year'])

# Calculate year-over-year growth
df_growth = calculate_growth_rate(df, periods=1)
```

### Indicator Discovery

```python
from unicef_api.config import (
    list_indicators_by_sdg,
    list_indicators_by_dataflow,
    get_indicator_metadata
)

# Find indicators for SDG target 3.2.1
indicators = list_indicators_by_sdg('3.2.1')
print(indicators)  # ['CME_MRY0T4']

# Find all nutrition indicators
nutrition_indicators = list_indicators_by_dataflow('NUTRITION')

# Get indicator metadata
meta = get_indicator_metadata('CME_MRY0T4')
print(meta['name'])  # 'Under-5 mortality rate'
print(meta['sdg'])   # '3.2.1'
```

### Error Handling

```python
from unicef_api import (
    UNICEFSDMXClient,
    SDMXNotFoundError,
    SDMXBadRequestError
)

client = UNICEFSDMXClient()

try:
    df = client.fetch_indicator('INVALID_CODE')
except SDMXNotFoundError as e:
    print(f"Indicator not found: {e}")
except SDMXBadRequestError as e:
    print(f"Invalid request: {e}")
```

## 📚 API Reference

### UNICEFSDMXClient

Main client for fetching UNICEF data.

#### Methods

##### `fetch_indicator()`

Fetch data for a single indicator.

**Parameters:**
- `indicator_code` (str): UNICEF indicator code (e.g., 'CME_MRY0T4')
- `countries` (List[str], optional): ISO3 country codes (e.g., ['ALB', 'USA'])
- `start_year` (int, optional): Starting year (e.g., 2015)
- `end_year` (int, optional): Ending year (e.g., 2023)
- `dataflow` (str, optional): SDMX dataflow name (auto-detected if None)
- `sex_disaggregation` (str, optional): Sex filter ('_T', 'F', 'M'). Default: '_T'
- `max_retries` (int, optional): Number of retry attempts. Default: 3
- `return_raw` (bool, optional): Return raw data without cleaning. Default: False

**Returns:** `pd.DataFrame` with indicator data

##### `fetch_multiple_indicators()`

Fetch multiple indicators at once.

**Parameters:**
- `indicator_codes` (List[str]): List of indicator codes
- `countries` (List[str], optional): ISO3 country codes
- `start_year` (int, optional): Starting year
- `end_year` (int, optional): Ending year
- `dataflow` (str, optional): SDMX dataflow name
- `combine` (bool, optional): Combine into single DataFrame. Default: True

**Returns:** `pd.DataFrame` (if combine=True) or `dict` (if combine=False)

## 🔧 Configuration

### Available Dataflows

- `GLOBAL_DATAFLOW` - Global dataflow (default, contains most indicators)
- `CME` - Child Mortality Estimates
- `NUTRITION` - Nutrition indicators
- `EDUCATION_UIS_SDG` - Education indicators
- `IMMUNISATION` - Immunization coverage
- `HIV_AIDS` - HIV/AIDS indicators
- `WASH_HOUSEHOLDS` - Water, Sanitation, and Hygiene
- `MNCH` - Maternal, Newborn and Child Health
- `PT` - Child Protection
- `PT_CM` - Child Marriage
- `PT_FGM` - Female Genital Mutilation
- `ECD` - Early Childhood Development
- `CHLD_PVTY` - Child Poverty

See `unicef_api/config.py` for complete configuration.

## 📖 Examples

See `examples/` folder for complete examples:

- `01_basic_usage.py` - Basic data download
- `02_multiple_indicators.py` - Batch downloads
- `03_data_analysis.py` - Data cleaning and analysis
- `04_sdg_indicators.py` - Working with SDG indicators

## 🐛 Troubleshooting

### Connection Errors

If you encounter connection errors, the library will automatically retry with exponential backoff. You can increase retry attempts:

```python
df = client.fetch_indicator('CME_MRY0T4', max_retries=5)
```

### Invalid Indicator Codes

Use `get_indicator_metadata()` to verify indicator codes:

```python
from unicef_api.config import COMMON_INDICATORS
print(list(COMMON_INDICATORS.keys())[:10])
```

### Country Code Validation

Ensure country codes are valid ISO 3166-1 alpha-3 codes:

```python
from unicef_api.utils import validate_country_codes

try:
    validate_country_codes(['USA', 'BRA', 'ALB'])
except ValueError as e:
    print(f"Validation error: {e}")
```

## 📝 Data Sources

All data is sourced from:
- **UNICEF SDMX API**: https://sdmx.data.unicef.org/
- **UNICEF Data Warehouse**: https://data.unicef.org/

API Documentation: https://data.unicef.org/sdmx-api-documentation/

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👤 Author

**Joao Pedro Azevedo**  
Senior Advisor, Data and Analytics  
UNICEF  
Email: jazevedo@unicef.org

## 🙏 Acknowledgments

This library was developed as part of UNICEF's SDG reporting efforts, based on code from:
- `unicef-sdg-llm-benchmark` repository
- `PROD-SDG-REP-2025` production pipeline
- `oda_baselines_repo` SDMX tools

## 📚 Related Projects

- **unicefData (R package)**: R interface for UNICEF data
- **PROD-SDG-REP-2025**: Production pipeline for UNICEF SDG reports
- **unicef-sdg-llm-benchmark**: LLM benchmarking for SDG indicators

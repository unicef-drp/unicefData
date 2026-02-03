# unicefData - Python Package

[![Python Tests](https://github.com/unicef-drp/unicefData/actions/workflows/python-tests.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Python component of the trilingual unicefData library for downloading UNICEF SDG indicators via SDMX API**

This is the Python implementation of the **unicefData** package. For other implementations, see the links below.

> **Other languages:** [R](../R/README.md) | [Stata](../stata/README.md) | [Main README](../README.md)

---

## Installation

```bash
# Clone repository
git clone https://github.com/unicef-drp/unicefData.git
cd unicefData/python

# Install in development mode
pip install -e .

# Or install dependencies directly
pip install -r requirements.txt
```

---

## Quick Start

### Search for Indicators

```python
from unicef_api import search_indicators, list_categories

# Search by keyword
search_indicators("mortality")
search_indicators("stunting")

# List all categories
list_categories()

# Search within a category
search_indicators(category="CME")
search_indicators("rate", category="CME")
```

### Download Data

```python
from unicef_api import unicefData

# Fetch under-5 mortality (dataflow auto-detected)
df = unicefData(
    indicator="CME_MRY0T4",
    countries=["ALB", "USA", "BRA"],
    year="2015:2023"  # Range, single year, or list
)

print(df.head())
```

### View Dataflow Schema

```python
from unicef_api import dataflow_schema, print_dataflow_schema

schema = dataflow_schema("CME")
print_dataflow_schema(schema)
```

---

## Post-Production Options

### Output Formats

```python
# Long format (default)
df = unicefData(indicator="CME_MRY0T4", format="long")

# Wide format - years as columns
df = unicefData(indicator="CME_MRY0T4", format="wide")

# Wide indicators - indicators as columns
df = unicefData(
    indicator=["CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"],
    format="wide_indicators"
)
```

### Latest Value Per Country

```python
df = unicefData(indicator="CME_MRY0T4", latest=True)
```

### Most Recent Values (MRV)

```python
df = unicefData(indicator="CME_MRY0T4", mrv=3)
```

### Circa (Nearest Year)

```python
df = unicefData(indicator="NT_ANT_HAZ_NE2", year=2015, circa=True)
```

### Add Metadata

```python
df = unicefData(
    indicator="CME_MRY0T4",
    add_metadata=["region", "income_group", "continent"]
)
```

### Combining Options

```python
df = unicefData(
    indicator=["CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"],
    format="wide_indicators",
    latest=True,
    add_metadata=["region", "income_group"],
    dropna=True
)
```

---

## API Reference

### unicefData()

Main function for fetching UNICEF indicator data.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `indicator` | str/list | required | Indicator code(s) |
| `dataflow` | str | auto-detect | SDMX dataflow ID |
| `countries` | list | None (all) | ISO3 country codes |
| `year` | int/str/list | None (all) | Year(s) |
| `circa` | bool | False | Find closest year |
| `sex` | str | `"_T"` | Sex filter |
| `max_retries` | int | 3 | Retry attempts |

#### Post-Production Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `format` | str | `"long"` | `"long"`, `"wide"`, `"wide_indicators"` |
| `latest` | bool | False | Keep only latest per country |
| `mrv` | int | None | Keep N most recent values |
| `add_metadata` | list | None | Metadata to add |
| `dropna` | bool | False | Remove missing values |
| `simplify` | bool | False | Keep only essential columns |

### UNICEFSDMXClient (Advanced)

```python
from unicef_api import UNICEFSDMXClient

client = UNICEFSDMXClient()

# Fetch single indicator
df = client.fetch_indicator(
    "CME_MRY0T4",
    countries=["ALB", "USA"],
    start_year=2015,
    end_year=2023
)

# Fetch multiple indicators
df = client.fetch_multiple_indicators(
    ["CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"],
    countries=["ALB", "USA"],
    combine=True
)
```

### Other Functions

| Function | Description |
|----------|-------------|
| `search_indicators(query, category, limit)` | Search indicators |
| `list_categories()` | List all categories |
| `list_dataflows()` | List available dataflows |
| `dataflow_schema(dataflow)` | Get dataflow schema |
| `refresh_indicator_cache()` | Force cache refresh |
| `get_cache_info()` | Get cache status |

---

## Time Period Handling

Monthly periods are converted to decimal years:

| Original | Decimal | Calculation |
|----------|---------|-------------|
| `2020` | `2020.0` | Integer year |
| `2020-01` | `2020.0833` | 2020 + 1/12 |
| `2020-06` | `2020.5000` | 2020 + 6/12 |

---

## Common Indicators

### Child Mortality (SDG 3.2)
- `CME_MRM0` - Neonatal mortality rate
- `CME_MRY0T4` - Under-5 mortality rate

### Nutrition (SDG 2.2)
- `NT_ANT_HAZ_NE2_MOD` - Stunting prevalence
- `NT_ANT_WHZ_NE2` - Wasting prevalence

### Immunization (SDG 3.b)
- `IM_DTP3` - DTP3 coverage
- `IM_MCV1` - Measles coverage

### WASH (SDG 6)
- `WS_PPL_W-SM` - Safely managed water
- `WS_PPL_S-SM` - Safely managed sanitation

### Child Protection
- `PT_CHLD_Y0T4_REG` - Birth registration
- `PT_F_20-24_MRD_U18_TND` - Child marriage

---

## Cache Locations

| Environment | Path |
|-------------|------|
| Standard | `~/.unicef_data/python/metadata/current/` |
| Override | Set `UNICEF_DATA_HOME_PY` or `UNICEF_DATA_HOME` |
| Development | `python/metadata/current/` |

---

## Error Handling

```python
from unicef_api import SDMXNotFoundError, SDMXBadRequestError

try:
    df = unicefData(indicator="INVALID_CODE")
except SDMXNotFoundError as e:
    print(f"Indicator not found: {e}")
except SDMXBadRequestError as e:
    print(f"Invalid request: {e}")
```

---

## Troubleshooting

### Connection Errors

```python
# Increase retry attempts
df = unicefData(indicator="CME_MRY0T4", max_retries=5)
```

### Invalid Indicator

```python
# Search for valid indicators
search_indicators("mortality")

# Check indicator metadata
from unicef_api.config import get_indicator_metadata
meta = get_indicator_metadata("CME_MRY0T4")
```

### Stale Cache

```python
from unicef_api import refresh_indicator_cache
refresh_indicator_cache()
```

---

## Examples

See `examples/` folder:

- `00_quick_start.py` - Basic usage
- `01_basic_usage.py` - Data download
- `02_multiple_indicators.py` - Batch downloads
- `03_data_analysis.py` - Data cleaning
- `04_sdg_indicators.py` - SDG queries

---

## Version History

### v2.0.0 (2026-01-31)
- Fixed SYNC-02 enrichment bug
- All 28 tests passing
- Cross-platform alignment

### v1.5.2 (2026-01-07)
- Fixed 404 fallback behavior
- Added dynamic User-Agent strings
- Added 10 new integration tests

See [CHANGELOG.md](CHANGELOG.md) for complete changelog.

---

## Dependencies

- pandas
- requests
- pyyaml
- countrycode (optional)

---

## License

MIT License - See [LICENSE](../LICENSE)

## Author

**Joao Pedro Azevedo**
Chief Statistician, UNICEF Data and Analytics Section
Email: jazevedo@unicef.org

## Contributing

See [Contributing Guide](../README.md#contributing) in the main README.

# unicefData - Python Package

[![PyPI version](https://badge.fury.io/py/unicefdata.svg)](https://pypi.org/project/unicefdata/)
[![Python Tests](https://github.com/unicef-drp/unicefData/actions/workflows/python-tests.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![Downloads](https://static.pepy.tech/badge/unicefdata)](https://pepy.tech/project/unicefdata)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Python component of the trilingual unicefData library for downloading UNICEF SDG indicators via SDMX API**

This is the Python implementation of the **unicefData** package. For other implementations, see the links below.

> **Other languages:** [R](../R/README.md) | [Stata](../stata/README.md) | [Main README](../README.md)

---

## Installation

```bash
pip install unicefdata
```

For development:

```bash
git clone https://github.com/unicef-drp/unicefData.git
cd unicefData/python
pip install -e ".[dev]"
```

### Verify Installation

```python
import unicefdata
print(unicefdata.__version__)  # Should print: 2.1.0
```

---

## What's New in 2.1.0

- 🧪 **Cross-language test suite**: 14 shared fixture tests validating structural consistency across Python, R, and Stata
- 📚 **YAML schema documentation**: Comprehensive format reference for all 7 YAML file types
- 🗑️ **Enhanced cache management**: 5-layer cache clearing with optional reload, 30-day staleness threshold
- 🔍 **Improved 404 errors**: All not-found errors now include tried dataflows in error messages
- ✅ **Version alignment**: All sub-modules now match package version, dynamic User-Agent strings
- 🧹 **Removed hardcoded paths**: All path resolution is now dynamic

See [CHANGELOG.md](CHANGELOG.md) for complete details.

---

## Quick Start

### Search for Indicators

```python
from unicefdata import search_indicators, list_categories

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
from unicefdata import unicefData

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
from unicefdata import dataflow_schema, print_dataflow_schema

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
from unicefdata import UNICEFSDMXClient

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
| `clear_cache()` | Clear all 5 cache layers |

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

## Error Handling

```python
from unicefdata import SDMXNotFoundError, SDMXBadRequestError, SDMXTimeoutError

try:
    df = unicefData(indicator="INVALID_CODE")
except SDMXNotFoundError as e:
    print(f"Indicator not found: {e}")
except SDMXBadRequestError as e:
    print(f"Invalid request: {e}")
except SDMXTimeoutError as e:
    print(f"Request timed out: {e}")
```

### Configurable Timeout

```python
from unicefdata import UNICEFSDMXClient

# Set custom timeout (default: 60s)
client = UNICEFSDMXClient(timeout=120)
```

---

## Troubleshooting

### Connection Errors

```python
# Increase retry attempts
df = unicefData(indicator="CME_MRY0T4", max_retries=5)
```

### Stale Cache

```python
from unicefdata import clear_cache
clear_cache()  # Clears all 5 cache layers
```

---

## Examples

See `examples/` folder:

- `00_quick_start.py` - Basic usage
- `01_indicator_discovery.py` - Finding indicators
- `02_sdg_indicators.py` - SDG queries
- `03_data_formats.py` - Output formats
- `04_metadata_options.py` - Metadata enrichment
- `05_advanced_features.py` - Advanced options

---

## Version History

See [CHANGELOG.md](CHANGELOG.md) for complete changelog.

---

## Dependencies

- pandas
- requests
- pyyaml

---

## Acknowledgments

This package was developed at the UNICEF Data and Analytics Section. The author gratefully acknowledges the collaboration of **Lucas Rodrigues**, **Yang Liu**, and **Karen Avanesian**, whose technical contributions and feedback were instrumental in the development of this Python package.

Special thanks to **Yves Jaques**, **Alberto Sibileau**, and **Daniele Olivotti** for designing and maintaining the UNICEF SDMX data warehouse infrastructure that makes this package possible.

The author also acknowledges the **UNICEF database managers** and technical teams who ensure data quality, as well as the country office staff and National Statistical Offices whose data collection efforts make this work possible.

Development of this package was supported by UNICEF institutional funding for data infrastructure and statistical capacity building. The author also acknowledges UNICEF colleagues who provided testing and feedback during development, as well as the broader open-source Python community.

Development was assisted by AI coding tools (GitHub Copilot, Claude). All code has been reviewed, tested, and validated by the package maintainers.

## Disclaimer

**This package is provided for research and analytical purposes.**

The `unicefData` package provides programmatic access to UNICEF's public data warehouse. While the author is affiliated with UNICEF, **this package is not an official UNICEF product and the statements in this documentation are the views of the author and do not necessarily reflect the policies or views of UNICEF**.

Data accessed through this package comes from the [UNICEF Data Warehouse](https://sdmx.data.unicef.org/). Users should verify critical data points against official UNICEF publications at [data.unicef.org](https://data.unicef.org/).

This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or UNICEF be liable for any claim, damages or other liability arising from the use of this software.

The designations employed and the presentation of material in this package do not imply the expression of any opinion whatsoever on the part of UNICEF concerning the legal status of any country, territory, city or area or of its authorities, or concerning the delimitation of its frontiers or boundaries.

## Data Citation and Provenance

**Important Note on Data Vintages**

Official statistics are subject to revisions as new information becomes available and estimation methodologies improve. UNICEF indicators are regularly updated based on new surveys, censuses, and improved modeling techniques. Historical values may be revised retroactively to reflect better information or methodological improvements.

**For reproducible research and proper data attribution, users should:**

1. **Document the indicator code** - Specify the exact SDMX indicator code(s) used (e.g., `CME_MRY0T4`)
2. **Record the download date** - Note when data was accessed (e.g., "Data downloaded: 2026-02-09")
3. **Cite the data source** - Reference both the package and the UNICEF Data Warehouse
4. **Archive your dataset** - Save a copy of the exact data used in your analysis

**Example citation for data used in research:**

> Under-5 mortality data (indicator: CME_MRY0T4) accessed from UNICEF Data Warehouse via unicefData Python package (v2.1.0) on 2026-02-09. Data available at: https://sdmx.data.unicef.org/

This practice ensures that others can verify your results and understand any differences that may arise from data updates. For official UNICEF statistics in publications, always cross-reference with the current version at [data.unicef.org](https://data.unicef.org/).

## Citation

If you use this package, please cite:

> Azevedo, Joao Pedro (2026). "unicefdata: Unified access to UNICEF indicators across R, Python, and Stata." Mimeo, UNICEF Chief Statistician Office.

---

## Development

Development assisted by AI coding tools (GitHub Copilot, Claude). All code reviewed and validated by maintainers.

---

## Author

**Joao Pedro Azevedo** ([@jpazvd](https://github.com/jpazvd))
Chief Statistician, UNICEF Data and Analytics Section
Email: jpazevedo@unicef.org
Website: [jpazvd.github.io](https://jpazvd.github.io/)

---

## License

MIT License - See [LICENSE](../LICENSE)

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

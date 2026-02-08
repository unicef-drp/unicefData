# unicefData Python Library - Installation and Usage Guide

## Installation

### Option 1: Install from PyPI (Recommended)

```bash
pip install unicefdata
```

### Option 2: Install in Development Mode

```bash
# Navigate to the python directory
cd python/

# Install in editable mode with all dependencies
pip install -e ".[dev]"
```

## Quick Start

### Basic Example

```python
from unicefdata import unicefData

# Fetch under-5 mortality for Brazil, India, Nigeria
df = unicefData(
    'CME_MRY0T4',
    countries=['BRA', 'IND', 'NGA'],
    start_year=2015,
    end_year=2023
)

print(df.head())
df.to_csv('mortality_data.csv', index=False)
```

### Run Examples

```bash
# Navigate to examples directory
cd python/examples

# Run basic usage example
python 00_quick_start.py

# Run indicator discovery example
python 01_indicator_discovery.py

# Run SDG indicators example
python 02_sdg_indicators.py

# Run data formats example
python 03_data_formats.py
```

## Package Structure

```
python/
├── unicefdata/                 # Main package (pip install unicefdata)
│   ├── __init__.py             # Package exports, version
│   ├── unicefdata.py           # Main API: unicefData(), parse_year(), clear_cache()
│   ├── sdmx_client.py          # UNICEFSDMXClient class, HTTP, 404 handling
│   ├── sdmx.py                 # Low-level SDMX helpers
│   ├── flows.py                # list_dataflows(), dataflow_schema()
│   ├── indicator_registry.py   # Indicator-to-dataflow mapping
│   ├── metadata.py             # MetadataSync class
│   ├── metadata_manager.py     # MetadataManager class
│   ├── schema_sync.py          # Schema synchronization
│   ├── schema_cache.py         # Schema caching utilities
│   ├── utils.py                # Validation, cleaning, reference data
│   ├── config.py               # Configuration settings
│   ├── config_loader.py        # Load config from files
│   ├── yaml_formatter.py       # YAML formatting utilities
│   ├── run_sync.py             # CLI for metadata sync
│   └── metadata/               # Bundled YAML metadata (~700KB)
│       └── current/
│           ├── _unicefdata_indicators_metadata.yaml
│           ├── _dataflow_fallback_sequences.yaml
│           ├── _unicefdata_regions.yaml
│           ├── _unicefdata_dataflows.yaml
│           ├── _unicefdata_countries.yaml
│           ├── _unicefdata_codelists.yaml
│           └── dataflows/*.yaml
│
├── examples/                   # Usage examples
│   ├── 00_quick_start.py
│   ├── 01_indicator_discovery.py
│   ├── 02_sdg_indicators.py
│   └── ...
│
├── tests/                      # Unit and integration tests
│   ├── test_unicef_api.py
│   ├── test_metadata_manager.py
│   └── ...
│
├── pyproject.toml              # Package build configuration
├── LICENSE                     # MIT License
├── README.md                   # Full documentation
└── CHANGELOG.md                # Version history
```

## Key Features

### 1. Download Single Indicator

```python
from unicefdata import unicefData

df = unicefData(
    'CME_MRY0T4',           # Indicator code
    countries=['ALB'],       # Country filter (optional)
    start_year=2015,         # Start year (optional)
    end_year=2023            # End year (optional)
)
```

### 2. Download Multiple Indicators

```python
from unicefdata import unicefData

indicators = ['CME_MRY0T4', 'NT_ANT_HAZ_NE2_MOD', 'IM_DTP3']

# Fetch each indicator
for ind in indicators:
    df = unicefData(ind, countries=['BRA', 'IND'], start_year=2015)
    print(f"{ind}: {len(df)} rows")
```

### 3. Search for Indicators

```python
from unicefdata import search_indicators

# Search by keyword
results = search_indicators('mortality')
print(results)
```

### 4. List Available Dataflows

```python
from unicefdata import list_dataflows

flows = list_dataflows()
print(flows)
```

### 5. Clear Cache

```python
from unicefdata import clear_cache

# Clear all 5 cache layers with optional reload
clear_cache(reload=True)
```

## Available Indicators

### Key SDG Indicators

| Indicator Code | Name | SDG Target |
|---------------|------|------------|
| `CME_MRY0T4` | Under-5 mortality rate | 3.2.1 |
| `CME_MRM0` | Neonatal mortality rate | 3.2.2 |
| `NT_ANT_HAZ_NE2_MOD` | Stunting prevalence | 2.2.1 |
| `NT_ANT_WHZ_NE2` | Wasting prevalence | 2.2.2 |
| `ED_CR_L1_UIS_MOD` | Primary completion rate | 4.1.1 |
| `ED_CR_L2_UIS_MOD` | Lower secondary completion | 4.1.1 |
| `IM_DTP3` | DTP3 immunization coverage | 3.b.1 |
| `WS_PPL_W-SM` | Safely managed drinking water | 6.1.1 |
| `WS_PPL_S-SM` | Safely managed sanitation | 6.2.1 |
| `PT_CHLD_Y0T4_REG` | Birth registration | 16.9.1 |

Use `search_indicators()` to find more indicators by keyword.

## Testing

```bash
# Run unit tests
cd python/
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=unicefdata

# Integration tests (requires API connection)
python tests/run_tests.py
```

## Troubleshooting

### Import Error

```python
# If you get "ModuleNotFoundError: No module named 'unicefdata'"
# Install the package:
pip install unicefdata

# Or for development:
pip install -e ".[dev]"
```

### API Connection Error

```python
from unicefdata import UNICEFSDMXClient

# Configure timeout (default: 60s)
client = UNICEFSDMXClient(timeout=120)

# The library automatically retries failed requests with exponential backoff
df = client.fetch_indicator('CME_MRY0T4', max_retries=5)
```

### Stale Cache

```python
from unicefdata import clear_cache

# Clear all caches and reload metadata
clear_cache(reload=True)
```

## Integration with Existing Workflows

### Replace R API calls with Python

**R code:**
```r
df <- unicefData("CME_MRY0T4", countries = c("ALB", "USA"))
```

**Python equivalent:**
```python
from unicefdata import unicefData

df = unicefData('CME_MRY0T4', countries=['ALB', 'USA'])
df.to_csv('mortality_data.csv', index=False)
```

### Batch Download Script

```python
from unicefdata import unicefData

indicators = {
    'mortality': ['CME_MRM0', 'CME_MRY0T4'],
    'nutrition': ['NT_ANT_HAZ_NE2_MOD', 'NT_ANT_WHZ_NE2'],
    'education': ['ED_CR_L1_UIS_MOD', 'ED_CR_L2_UIS_MOD'],
}

for category, indicator_list in indicators.items():
    for ind in indicator_list:
        df = unicefData(ind, start_year=2015)
        df.to_csv(f'api_{category}_{ind}.csv', index=False)
        print(f"Downloaded {ind}: {len(df)} observations")
```

## Additional Resources

- **UNICEF Data Portal**: https://data.unicef.org/
- **SDMX API Documentation**: https://data.unicef.org/sdmx-api-documentation/
- **PyPI Package**: https://pypi.org/project/unicefdata/
- **GitHub Repository**: https://github.com/unicef-drp/unicefData

## Author

**Joao Pedro Azevedo**
Chief Statistician, UNICEF Data and Analytics Section

## License

MIT License

---

**Next Steps:**

1. Install the package: `pip install unicefdata`
2. Run examples: `python examples/00_quick_start.py`
3. Search indicators: `search_indicators('mortality')`
4. Integrate with your workflows

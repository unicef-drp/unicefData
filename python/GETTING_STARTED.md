# UNICEF API Python Library - Installation and Usage Guide

## 📦 Installation

### Option 1: Install in Development Mode (Recommended)

```powershell
# Navigate to the python directory
cd D:\jazevedo\GitHub\unicefData\python

# Install in editable mode with dependencies
pip install -e .
```

### Option 2: Install from Requirements

```powershell
# Install core dependencies only
pip install -r requirements.txt

# Install development dependencies (for testing)
pip install -r requirements-dev.txt
```

## 🚀 Quick Start

### Basic Example

```python
from unicef_api import UNICEFSDMXClient

# Initialize client
client = UNICEFSDMXClient()

# Fetch under-5 mortality for Brazil, India, Nigeria
df = client.fetch_indicator(
    'CME_MRY0T4',
    countries=['BRA', 'IND', 'NGA'],
    start_year=2015,
    end_year=2023
)

print(df.head())
df.to_csv('mortality_data.csv', index=False)
```

### Run Examples

```powershell
# Navigate to examples directory
cd D:\jazevedo\GitHub\unicefData\python\examples

# Run basic usage example
python 01_basic_usage.py

# Run multiple indicators example
python 02_multiple_indicators.py

# Run SDG indicators example
python 03_sdg_indicators.py

# Run data analysis example
python 04_data_analysis.py
```

## 📂 Package Structure

```
D:\jazevedo\GitHub\unicefData\python\
├── unicef_api/              # Main package
│   ├── __init__.py          # Package initialization and exports
│   ├── sdmx_client.py       # SDMX API client (main class)
│   ├── config.py            # Dataflow and indicator configurations
│   └── utils.py             # Utility functions
│
├── examples/                # Usage examples
│   ├── 01_basic_usage.py
│   ├── 02_multiple_indicators.py
│   ├── 03_sdg_indicators.py
│   └── 04_data_analysis.py
│
├── tests/                   # Unit tests
│   └── test_unicef_api.py
│
├── setup.py                 # Package installation config
├── requirements.txt         # Core dependencies
├── requirements-dev.txt     # Development dependencies
├── README.md                # Full documentation
└── .gitignore              # Git ignore rules
```

## 🎯 Key Features

### 1. Download Single Indicator

```python
client = UNICEFSDMXClient()

df = client.fetch_indicator(
    'CME_MRY0T4',           # Indicator code
    countries=['ALB'],       # Country filter (optional)
    start_year=2015,         # Start year (optional)
    end_year=2023            # End year (optional)
)
```

### 2. Download Multiple Indicators

```python
indicators = ['CME_MRY0T4', 'NT_ANT_HAZ_NE2_MOD', 'IM_DTP3']

# Combined into single DataFrame
df = client.fetch_multiple_indicators(
    indicators,
    countries=['BRA', 'IND'],
    start_year=2015,
    combine=True
)

# Or as separate DataFrames
df_dict = client.fetch_multiple_indicators(
    indicators,
    combine=False
)
```

### 3. Work with SDG Indicators

```python
from unicef_api.config import (
    list_indicators_by_sdg,
    get_indicator_metadata
)

# Find indicators for SDG target 3.2.1
indicators = list_indicators_by_sdg('3.2.1')

# Get indicator metadata
meta = get_indicator_metadata('CME_MRY0T4')
print(meta['name'])  # 'Under-5 mortality rate'
```

### 4. Data Utilities

```python
from unicef_api.utils import (
    clean_dataframe,
    pivot_wide,
    calculate_growth_rate,
    merge_with_country_names
)

# Clean data
df = clean_dataframe(df, remove_nulls=True, sort_by=['country_code', 'year'])

# Add country names
df = merge_with_country_names(df)

# Pivot to wide format
df_wide = pivot_wide(df, index_cols=['country_code', 'year'])

# Calculate growth rates
df = calculate_growth_rate(df, periods=1)
```

## 🔍 Available Indicators

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

See `unicef_api/config.py` for complete list.

## 🧪 Testing

```powershell
# Install development dependencies
pip install -r requirements-dev.txt

# Run tests
cd D:\jazevedo\GitHub\unicefData\python
pytest tests/ -v

# Run tests with coverage
pytest tests/ --cov=unicef_api --cov-report=html
```

## 🐛 Troubleshooting

### Import Error

```python
# If you get "ModuleNotFoundError: No module named 'unicef_api'"
# Make sure you installed the package:
pip install -e .
```

### API Connection Error

```python
# The library automatically retries failed requests
# You can increase retry attempts:
df = client.fetch_indicator('CME_MRY0T4', max_retries=5)
```

### Invalid Indicator Code

```python
# Use config to verify indicator codes:
from unicef_api.config import COMMON_INDICATORS
print(list(COMMON_INDICATORS.keys()))
```

## 📊 Integration with Existing Workflows

### Integration with PROD-SDG-REP-2025

Replace R API calls with Python:

**R code:**
```r
unf_dw_mort <- read_csv(sdg_mortality)
```

**Python equivalent:**
```python
from unicef_api import UNICEFSDMXClient

client = UNICEFSDMXClient()
df_mortality = client.fetch_indicator('CME_MRY0T4')
df_mortality.to_csv('api_unf_mort.csv', index=False)
```

### Batch Download Script

```python
# Create a batch download script
from unicef_api import UNICEFSDMXClient

client = UNICEFSDMXClient()

indicators = {
    'mortality': ['CME_MRM0', 'CME_MRY0T4'],
    'nutrition': ['NT_ANT_HAZ_NE2_MOD', 'NT_ANT_WHZ_NE2'],
    'education': ['ED_CR_L1_UIS_MOD', 'ED_CR_L2_UIS_MOD'],
}

for category, indicator_list in indicators.items():
    df = client.fetch_multiple_indicators(
        indicator_list,
        start_year=2015,
        combine=True
    )
    df.to_csv(f'api_{category}.csv', index=False)
    print(f"✓ Downloaded {category}: {len(df)} observations")
```

## 📚 Additional Resources

- **UNICEF Data Portal**: https://data.unicef.org/
- **SDMX API Documentation**: https://data.unicef.org/sdmx-api-documentation/
- **Full README**: `D:\jazevedo\GitHub\unicefData\python\README.md`
- **Examples**: `D:\jazevedo\GitHub\unicefData\python\examples\`

## 👤 Author

**Joao Pedro Azevedo**  
Chief Statistician, UNICEF Data and Analytics Section

## 📄 License

MIT License

---

**Next Steps:**

1. Install the package: `pip install -e .`
2. Run examples: `python examples/01_basic_usage.py`
3. Integrate with your workflows
4. Customize for your specific needs

For questions or issues, please refer to the full documentation in `README.md`.

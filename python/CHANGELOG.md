# Changelog

All notable changes to the unicef-api Python library will be documented in this file.

## [0.1.0] - 2025-12-01

### Added

- Initial release of unicef-api Python library
- Core `UNICEFSDMXClient` class for fetching UNICEF indicators
- Support for 40+ SDG-related child welfare indicators
- Multiple dataflow support (GLOBAL_DATAFLOW, CME, NUTRITION, EDUCATION, etc.)
- Comprehensive error handling with custom exceptions
- Automatic retry logic with exponential backoff
- Data cleaning and standardization utilities
- Country code validation
- Year range validation
- Configuration module with indicator metadata
- Helper functions for:
  - Pivoting data from long to wide format
  - Calculating growth rates
  - Merging with country names
  - Data cleaning and deduplication
- Batch download support (`fetch_multiple_indicators`)
- SDG indicator discovery functions
- Complete documentation and README
- Four comprehensive usage examples
- Unit tests with pytest
- Package installation via setup.py
- Requirements management (core and dev dependencies)

### Features

#### Core Client
- `UNICEFSDMXClient()` - Main API client
- `fetch_indicator()` - Download single indicator
- `fetch_multiple_indicators()` - Batch download
- Support for country filtering
- Support for year range filtering
- Sex disaggregation filtering
- Raw data option (no cleaning)

#### Configuration
- `COMMON_INDICATORS` - 40+ pre-configured indicators with metadata
- `UNICEF_DATAFLOWS` - All available dataflow configurations
- `get_dataflow_for_indicator()` - Auto-detect dataflow
- `get_indicator_metadata()` - Retrieve indicator details
- `list_indicators_by_sdg()` - Find indicators by SDG target
- `list_indicators_by_dataflow()` - List indicators by dataflow
- `get_all_sdg_targets()` - List all covered SDG targets

#### Utilities
- `validate_country_codes()` - ISO3 country code validation
- `validate_year_range()` - Year range validation
- `validate_indicator_code()` - Indicator code validation
- `clean_dataframe()` - Data cleaning and standardization
- `merge_with_country_names()` - Add country names
- `pivot_wide()` - Convert long to wide format
- `calculate_growth_rate()` - Calculate period-over-period growth
- `load_country_codes()` - Load valid country codes

#### Examples
- `01_basic_usage.py` - Basic data download
- `02_multiple_indicators.py` - Batch downloads
- `03_sdg_indicators.py` - Working with SDG indicators
- `04_data_analysis.py` - Data cleaning and transformation

### Technical Details

- Python 3.8+ support
- Dependencies: requests, pandas
- Comprehensive docstrings
- Type hints where applicable
- Logging support
- Session management for connection pooling
- CSV format for optimal performance
- Automatic data type conversion
- Duplicate removal
- Null value handling

### Known Limitations

- Some dataflows may not support country filtering in URL (filtered post-fetch)
- Country names mapping is partial (comprehensive mapping requires external file)
- No caching support yet (planned for future release)
- No async support yet (planned for future release)

### Acknowledgments

Based on code from:
- `unicef-sdg-llm-benchmark` repository (sdmx_client.py)
- `PROD-SDG-REP-2025` production pipeline (0121_get_data_api.R)
- `oda_baselines_repo` SDMX tools (fetch_sdmx_structure_yaml.py)

## [Unreleased]

### Planned Features

- Caching support for offline work
- Async/parallel downloads for large batches
- Progress bars for long downloads
- Excel export support
- Comprehensive country name database
- Data visualization helpers
- More granular age/sex disaggregation options
- Support for SDMX XML and JSON formats
- Custom dataflow support
- Rate limiting configuration
- Proxy support

---

**Version Format**: [Major.Minor.Patch]
- **Major**: Breaking changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, backward compatible

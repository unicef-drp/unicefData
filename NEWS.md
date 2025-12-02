# unicefData Changelog

## 0.2.0 (2025-01-06)

### R Package Bug Fixes
* **Fixed SDMX URL construction** in `get_sdmx()` - corrected indicator key format 
  from `.INDICATOR.` to `.INDICATOR..` (two trailing dots) to match UNICEF API requirements
* **Fixed countrycode integration** - replaced deprecated `countrycode::countrycode_df` 
  with `countrycode::countrycode()` function
* Added comprehensive test script (`R/examples/test_api.R`) validating all major dataflows
* Verified compatibility with 68 UNICEF SDMX dataflows

### Python Package (NEW)
* Added complete Python implementation (`python/unicef_api/`)
  - `UNICEFSDMXClient` class for fetching SDMX data
  - 40+ pre-configured SDG indicators in `config.py`
  - Comprehensive error handling with 7 exception types
  - Automatic retry with exponential backoff
  - Data cleaning and transformation utilities
* Added 4 Python examples:
  - `01_basic_usage.py` - Simple indicator fetching
  - `02_multiple_indicators.py` - Batch download
  - `03_sdg_indicators.py` - SDG-focused queries
  - `04_data_analysis.py` - Data transformation workflows
* Added unit tests with pytest

### R Package Improvements
* Reorganized R examples into `R/examples/`:
  - `01_batch_fetch_sdg.R` - Batch-fetch SDG indicators
  - `02_sdmx_client_demo.R` - SDMX client demonstration
  - `test_api.R` - API test suite
* Improved documentation

### Repository
* Updated README to document bilingual R/Python support
* Updated DESCRIPTION with correct dependencies (added tibble, xml2, memoise, countrycode, tools)
* Updated NAMESPACE with all exported functions
* Updated .Rbuildignore for Python folder exclusion
* Added MIT LICENSE file
* Added comprehensive `.gitignore`
* Cleaned up old log files and temporary directories

---

## 0.1.0 (2025-07-04)

### R Package (Initial Release)
* `list_sdmx_flows()` - List available SDMX dataflows
* `list_sdmx_codelist()` - Browse dimension codelists
* `get_sdmx()` - Generalized SDMX data fetching with:
  - Automatic paging for large datasets
  - Retry logic for transient failures
  - Disk-based caching via `memoise`
  - Tidy output with country name joins
  - Support for CSV, SDMX-XML, and SDMX-JSON formats
* Utility functions:
  - `safe_read_csv()` / `safe_write_csv()` for robust I/O
  - `process_block()` for structured logging

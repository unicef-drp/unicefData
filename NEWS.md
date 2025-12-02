# unicefdata Changelog

## 0.2.0 (2025-12-01)

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

### R Package
* Reorganized R examples into `R/examples/`:
  - `01_batch_fetch_sdg.R` - Batch-fetch SDG indicators
  - `02_sdmx_client_demo.R` - SDMX client demonstration
* Improved documentation

### Repository
* Updated README to document bilingual R/Python support
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

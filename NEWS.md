# unicefData Changelog

## 0.2.3 (2025-12-08)

### Bug Fixes
* **R**: Renamed `sync_indicators()` to `build_indicator_catalog()` in `R/metadata.R` to resolve function name conflict with `R/metadata_sync.R`
  - The `sync_indicators()` function in `metadata_sync.R` (saves YAML files) is unchanged
  - `build_indicator_catalog()` builds in-memory indicator catalog for runtime use

## 0.2.2 (2025-12-02)

### Vintage Control (NEW)
* **R**: Added vintage control functions to `R/metadata.R`:
  - `list_vintages()` - List all available metadata snapshots
  - `load_vintage(vintage)` - Load metadata from a specific vintage date
  - `compare_vintages(v1, v2)` - Compare two vintages to detect additions/removals/changes
  - `get_vintage_path(vintage)` - Get path to vintage directory
  - `ensure_metadata(max_age_days)` - Auto-sync if metadata is stale
  
* **Python**: Added vintage control to `unicef_api/metadata.py`:
  - `list_vintages()` - List all available metadata snapshots
  - `load_vintage(vintage)` - Load metadata from a specific vintage
  - `compare_vintages(v1, v2)` - Compare vintages for API changes
  - `ensure_metadata(max_age_days)` - Auto-sync with staleness check
  - `MetadataSync.sync_all(create_vintage=True)` - Creates versioned snapshot

* **Vintage Directory Structure**:
  ```
  metadata/
    dataflows.yaml       # Current metadata
    codelists.yaml
    indicators.yaml
    sync_summary.yaml
    sync_history.yaml    # History of all syncs
    vintages/
      2025-12-02/        # Historical snapshot
        dataflows.yaml
        codelists.yaml
        indicators.yaml
        summary.yaml
  ```

### Auto-sync on First Use
* Metadata is automatically synced when first accessed
* Default staleness threshold: 30 days (configurable via `max_age_days`)
* Use `force=True` to refresh even if metadata is fresh

---

## 0.2.1 (2025-12-02)

### Metadata Sync & Validation (NEW)
* **R**: Added `R/metadata.R` with:
  - `sync_metadata()` - Download and cache API metadata as YAML files
  - `sync_dataflows()`, `sync_codelists()`, `build_indicator_catalog()` - Sync specific metadata types
  - `validate_data()` - Validate DataFrames against cached metadata
  - `load_dataflows()`, `load_indicators()`, `load_codelists()` - Load cached metadata
  - `create_data_version()` - Create version records for data tracking
  
* **Python**: Added `unicef_api/metadata.py` with:
  - `sync_metadata()` - Download and cache API metadata as YAML files
  - `MetadataSync` class for full control over sync operations
  - `validate_indicator_data()` - Validate DataFrames against cached metadata
  - Data versioning with SHA-256 hashes for triangulation

* **Generated YAML Files** in `metadata/`:
  - `dataflows.yaml` - 69 UNICEF dataflows with names and versions
  - `indicators.yaml` - 25+ SDG indicators with dataflow mappings
  - `codelists.yaml` - Country codes, sex, age groups, etc.
  - `sync_summary.yaml` - Last sync timestamp and statistics

### Dependencies
* Python: Added `pyyaml>=6.0` requirement
* R: Uses existing `yaml` package

---

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

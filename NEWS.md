# unicefData Changelog

## 2.2.0 (2026-02-15)

### Cross-Platform Testing Infrastructure

* **328+ automated tests** across 11 test families (unit, integration, deterministic, sync-pipeline, discovery, error-conditions, transformations, cross-language, API-mock, regression, smoke)
* **Deterministic fixture system**: Single `tests/fixtures.zip` source with automated extraction via git hooks and `unpack_fixtures.py`
* **Full CI matrix**: R (devel/release/oldrel × Ubuntu/macOS/Windows), Python 3.9-3.11, YAML schema validation
* **19 CI checks** all passing

### R Package

* Added 5 new testthat test files: transformations, deterministic, discovery, sync-pipeline, error-conditions
* Added `helper-fixtures.R` with `testthat::test_path()` for R CMD check compatibility
* Fixed category resolution fallback in `list_categories()` - eliminates "UNKNOWN" entries
* Added input validation for `unicefData()` with helpful `search_indicators()` hint

### Python Package

* Fixed missing sex filter in full-dataflow path (`get_sdmx(flow="CME", sex="_T")`)
* Fixed `None` indicator converting to literal `"None"` string
* Added retry logic with exponential backoff for full-dataflow fetches  
* Added `detail` parameter validation
* Validated indicator input and filter empty/None values

### CI/CD

* Added fixture extraction step to all 3 test workflows
* Relaxed R-CMD-check from `error-on: "warning"` to `error-on: "error"`
* Excluded legacy debug scripts from pytest collection
* Fixed lint issues in `unpack_fixtures.py`

### Documentation

* Added cross-platform testing framework paper
* Added test audit with 11-family typology
* Added versioning policy document
* Documented git hooks and SHA-256 fixture stamps
* Added roxygen2 documentation and vignettes

## 2.1.0 (2026-02-07)

### Cache Management

* **R**: Added `clear_unicef_cache()` - clears 6 cache layers with optional reload
* **Python**: Added `clear_cache()` - clears 5 cache layers with optional reload
* **Stata**: Added `clearcache` subcommand - drops cached frames
* All three languages verified at 30-day staleness threshold

### Error Handling Improvements

* **Python**: Added `SDMXTimeoutError` exception; configurable timeout via constructor
* **R**: Fixed `apply_circa()` NA handling - no longer drops countries with all-NA values

### Portability Fixes

* **R**: Replaced hardcoded paths with `system.file()` resolution
* **Stata**: Implemented 3-tier path resolution (PLUS -> findfile/adopath -> cwd)
* All 404 errors now include tried dataflows context across all 3 languages

### Docs & Help

* Created YAML_SCHEMA.md documenting all 7 YAML file formats
* Documented `noerror`, `fromfile()`/`tofile()`, and `clearcache` in Stata help
* Documented Python prerequisites in `unicefdata_sync.sthlp`

### Testing Infrastructure

* Added 3 new API response fixture CSVs (nutrition, sex disaggregation, multi-indicator)
* Created expected output fixtures for cross-language comparison
* Cross-language validation tests: Python (14/14), R (13/13), Stata (12/12)

## 2.0.0 (2026-01-31)

### Major Fixes
* **SYNC-02 enrichment bug**: Fixed critical path extraction bug preventing Phase 2-3 enrichment
  - Root cause: Incorrect directory path extraction from YAML file paths
  - Solution: Implemented forvalues loop to find rightmost slash properly
  - Impact: All 38 QA tests now passing (100% success rate, was 37/38)
  - Enrichment now includes tier classification and disaggregation metadata

### Documentation
* **Version headers aligned**: Updated version to 2.0.0 across all platforms (R, Python, Stata)
* **Roxygen2 regenerated**: Fixed `.yaml_scalar()` function and regenerated all `man/*.Rd` files
* **Workspace cleanup**: Consolidated archive folders and removed duplicates

### Testing & Quality Assurance
* **Full QA test suite**: All 38 tests passing (10m 17s duration)
  - ENV tests: ✅ (environment validation)
  - DL tests: ✅ (download functionality)
  - TRANS tests: ✅ (data transformation)
  - META tests: ✅ (metadata operations)
  - SYNC tests: ✅ (synchronization including enrichment)
  - MULTI tests: ✅ (multi-indicator operations)
* **Full test suite verified**: R (26 passed), Python (28 passed), Stata QA (38/38 passed)

### Breaking Changes
* Version bump to 2.0.0 reflects major reliability improvements in metadata pipeline

## 1.6.0 (2026-01-12)

### Stata Dataflow Enhancements
* **PT subdataflows**: Extended PT fallback to include PT_CM (child marriage) and PT_FGM (female genital mutilation)
  - Enables indicators like PT_CM_EMPLOY_12M (168 rows)
  - Fallback sequence: PT → PT_CM → PT_FGM → CHILD_PROTECTION → GLOBAL_DATAFLOW

* **New prefix-to-dataflow mappings**: Added automatic detection for 4 new indicator prefixes:
  - `COD` → `CAUSE_OF_DEATH` dataflow (18 indicators with data)
  - `TRGT` → `CHILD_RELATED_SDG` dataflow
  - `SPP` → `SOC_PROTECTION` dataflow (236 rows for SPP_GDPPC)
  - `WT` → `PT` dataflow (92 rows for WT_ADLS_10-17_LBR_ECON)

### Bug Fixes
* **Fallback import bug**: Fixed duplicate import skip logic when fallback mechanism provides data
  - Prevents r(601) "file not found" errors on re-import attempts
  - Properly initializes `fallback_used` flag throughout indicator fetch

### Testing & Validation
* **Cross-platform parity**: Stata now matches Python performance on all tested indicators
  - COD indicators: 18 rows ✅ (Python: 18, R: fail)
  - PT_CM_EMPLOY_12M: 168 rows ✅ (Python: 168, R: fail)
  - SPP_GDPPC: 236 rows ✅ (Python: 236, R: 236)
  - WT_ADLS_10-17_LBR_ECON: 92 rows ✅ (Python: 92, R: 92)
* Seed-42 validation: 19 new Stata successes (0→19, no regressions)

### Breaking Changes
None — all changes backward-compatible with existing code

---

## 1.5.2 (2026-01-07)

### Fixed
* **404 fallback in R**: Invalid indicators now return empty data frame with informative message instead of throwing error (parity with Python behavior)
* **Quick-start example**: Fixed deprecated `start_year`/`end_year` parameters → now uses unified `year` parameter syntax

### Added
* **Dynamic User-Agent**: All platforms now send descriptive UA strings with version, runtime, and repo URL
  - R: `unicefData-R/<version> (R/<r_ver>; <OS>) (+https://github.com/unicef-drp/unicefData)`
  - Python: `unicefData-Python/<version> (Python/<py_ver>; <system>) (+github...)`
  - Stata: `unicefData-StataSync/<version> (Python/<py_ver>; <platform>) (+github...)`
* **Test coverage for PR #14**: 24 new tests validating 404 fallback and wrapper behavior
  - R: 14 tests (5 for 404 fallback, 7 for list_dataflows, 1 skip)
  - Python: 10 tests (4 for 404 fallback, 6 for list_dataflows)
* **Quick verification script**: Added `R/examples/07_quick_verification.R` for rapid PR validation

### Refactored
* **list_dataflows() wrapper**: Now consistently wraps `list_sdmx_flows()` with unified output schema (id, agency, version, name)
* **Stata helper version**: `stata_schema_sync.py` now dynamically imports version from `unicef_api` package with fallback

### Documentation
* **Test coverage summary**: Added `PR14_TEST_COVERAGE_SUMMARY.md` documenting all PR #14 validation
* **Examples aligned**: All R/Python/Stata examples now use consistent `year` parameter syntax

## 1.5.0 (2025-12-19)

### Cross-Platform Release
* **Defaults**: Disaggregation filters now default to totals (`_T`) for sex, age, wealth, residence, and maternal education across Stata, R, and Python.
* **Metadata caches**: Added per-language cache roots with environment overrides (`UNICEF_DATA_HOME_PY`, `UNICEF_DATA_HOME_R`) to keep Python and R YAML stores separate and install-friendly.
* **Documentation**: Refreshed README examples (categories and mortality search) and help text to reflect current API outputs and default behavior.
* **Version alignment**: Bumped package versions to 1.5.0 across R, Python, and Stata for the unified release.

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

# Changelog

All notable changes to the unicefdata Python library will be documented in this file.

## [2.1.0] - 2026-02-08

### Added

- **Cross-language test suite**: 14 shared fixture tests validating structural consistency across Python, R, and Stata
- **YAML schema documentation**: Comprehensive format reference for all 7 YAML file types

### Changed

- **`clear_cache()`**: Verified 5-layer cache clearing with optional reload
- **30-day staleness threshold**: Aligned with R and Stata cache management
- **404 error context**: All not-found errors now include tried dataflows in error messages
- **Hardcoded paths**: Fully removed; all path resolution is dynamic

### Fixed

- **Version alignment**: `metadata.py` sub-module version now matches package version
- **User-Agent string**: Dynamically uses current package version

### Tested

- 44/44 unit tests passing, 1 skipped (requires API connection)
- Cross-language fixture tests: 14/14 passing

## [2.0.0] - 2026-02-07

### Changed

- **Package renamed**: `unicef-api` / `unicef_api` is now `unicefdata`
  - Install: `pip install unicefdata`
  - Import: `from unicefdata import unicefData`
  - Main module: `unicefdata.py` (was `core.py`), aligning with R (`unicefData.R`) and Stata (`unicefdata.ado`)
- **Packaging modernized**: `setup.py` + `MANIFEST.in` replaced by `pyproject.toml`
- **Metadata bundled**: YAML metadata files shipped inside the package (~700KB)
- **`unicef_sdmx`** merged into main `unicefdata` package
- **Python floor**: Raised to `>=3.9` (3.8 is EOL)
- **LICENSE**: Full MIT license text added

### Added

- **`clear_cache()`**: Clears all 5 cache layers with optional reload
- **`SDMXTimeoutError`**: Typed exception for timeouts; configurable via `UNICEFSDMXClient(timeout=120)`
- **Cross-language test suite**: 14 shared fixture tests validating structural consistency across Python, R, and Stata
- **PyPI publication**: Available at https://test.pypi.org/project/unicefdata/

### Fixed

- **Hardcoded paths**: Removed; 404 errors now include tried dataflows in error messages

### Tested

- 44/44 unit tests passing, 1 skipped (requires API connection)

## [1.5.2] - 2026-01-07

### Added

- **Dynamic User-Agent**: All HTTP requests now include descriptive UA string
  - Format: `unicefData-Python/<version> (Python/<py_ver>; <system>) (+https://github.com/unicef-drp/unicefData)`
  - Applied consistently across `sdmx_client.py` and `schema_sync.py`
- **Comprehensive test suite for PR #14**: 10 new integration tests
  - 4 tests for 404 fallback behavior (`test_404_fallback.py`)
  - 6 tests for `list_dataflows()` wrapper schema validation (`test_list_dataflows.py`)

### Fixed

- **404 fallback behavior**: Invalid indicators now return empty DataFrame instead of raising exceptions (consistent error handling)
- **list_dataflows() parameter**: Fixed documentation to use `max_retries` (not `retry` or `cache`)

### Changed

- **Test alignment**: Python and R test suites now have matching coverage for 404 fallback and wrapper validation
- **Version management**: Version string now dynamically read from `__init__.py` in User-Agent builder

## [1.5.0] - 2025-12-19

### Changed

- Bumped package version to 1.5.0 for the unified multi-language release.
- Separated metadata cache roots by language with the `UNICEF_DATA_HOME_PY` override to keep Python YAML files out of R/Stata caches.

### Fixed

- Documentation refreshed to reflect current discovery outputs and default `_T` disaggregation behavior.

## [0.1.0] - 2025-12-01

### Added

- Initial release of the Python library
- Core `UNICEFSDMXClient` class for fetching UNICEF indicators
- Support for 40+ SDG-related child welfare indicators
- Multiple dataflow support (GLOBAL_DATAFLOW, CME, NUTRITION, EDUCATION, etc.)
- Comprehensive error handling with custom exceptions
- Automatic retry logic with exponential backoff
- Data cleaning and standardization utilities
- Country code validation, year range validation
- Batch download support (`fetch_multiple_indicators`)
- SDG indicator discovery functions
- Complete documentation, examples, and unit tests

---

**Version Format**: [Major.Minor.Patch]

- **Major**: Breaking changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, backward compatible

# Changelog

All notable changes to the unicefdata Python library will be documented in this file.

## [2.4.2] - 2026-04-20

### Fixed

- Added `Accept-Language: en` header to the shared `requests.Session` in
  `UNICEFSDMXClient.__init__()` — prevents occasional non-English indicator names
  returned by the UNICEF SDMX API when no locale is specified (fixes #45)
- Updated repository metadata sync tooling (`stata/src/py/build_dataflow_metadata.py`)
  to send `Accept-Language: en` and `User-Agent` headers via
  `urllib.request.Request` — ensures weekly metadata refresh jobs receive
  English descriptions consistently

## [2.4.1] - 2026-03-27

### Changed

- **`diagnose` parameter**: New opt-in `diagnose=True` parameter. Default behavior restored to server-side year filtering (faster). Query status codes only populated when `diagnose=True`.
- Version alignment patch: v2.4.0 was tagged before R/Stata were ready.

## [2.4.0] - 2026-03-25

### Added

- **Query status codes**: When `unicefData()` returns an empty DataFrame, `df.attrs` now contains structured metadata explaining why:
  - `query_status`: One of `ok`, `indicator_not_found`, `country_not_found`, `year_not_found`, `year_beyond_range`
  - `available_years`: List of years with data (when `year_not_found` or `year_beyond_range`)
  - `nearest_year`: Closest available year to the requested year
  - `available_countries`: Countries with data (when `country_not_found`)
  - `message`: Human-readable explanation
- **Cross-language spec**: `docs/QUERY_STATUS_CODES.md` defines the same codes for Python, R, and Stata

### Changed

- **Fetch without year filter**: Primary dataflow queries no longer pass `startPeriod`/`endPeriod` to the SDMX API. Year filtering is applied client-side. This avoids the SDMX API 404 quirk on survey-based dataflows (NUTRITION, MNCH, EDUCATION) where valid country+indicator combinations return 404 when a specific year has no data.
- **Smarter fallback logic**: Fallback dataflows are only tried on real 404s (dataflow doesn't exist), not on empty results (dataflow exists but data is sparse for this country/year). Previously, querying `MNCH_CSEC` for a year without data would try 4 non-existent fallback dataflows.

### Fixed

- **MNCH_CSEC, MNCH_BIRTH18**: Now return `year_not_found` with `available_years` instead of `SDMXNotFoundError` after exhausting fallbacks
- **NT_ANT_HAZ_NE2, NT_ANT_WAZ_NE2, NT_ANT_WHZ_NE2**: Same fix for nutrition indicators
- **ED_CR_L1**: Same fix for education indicators

## [2.3.2] - 2026-03-22

### Changed

- **Version aligned to repo release v2.3.2**: Minor bump from 2.2.x to 2.3.x per the Minimum Bump Rule (patches reserved for critical fixes only). Consolidates the v2.2.1 and v2.2.2 bug fixes into a proper minor release.

### Added

- **Version validation CI**: New `versioning-check.yml` workflow validates version bumps and cross-platform consistency on every PR. Backed by `scripts/check_versions.py` (trilingual) and `scripts/update_component_versions.py`.

## [2.2.2] - 2026-03-20

### Fixed

- **`UNICEFSDMXClient.fetch_indicator()` dataflow resolution**: When no `dataflow` is specified, the client now auto-detects the correct dataflow from indicators metadata then prefix-based fallback sequences, matching the behaviour of `unicefData()`. Previously it always defaulted to `GLOBAL_DATAFLOW` regardless of the indicator.

## [2.2.1] - 2026-03-20

### Fixed

- **Bundled metadata path**: `_load_fallback_sequences()` now correctly resolves `metadata/current/_dataflow_fallback_sequences.yaml` (was missing `current/` subdirectory)
- **Indicators metadata path**: `_load_indicators_metadata()` now searches the installed package location (`unicefdata/metadata/current/_unicefdata_indicators_metadata.yaml`) as first priority, eliminating startup warning
- **Codelists filename**: `MetadataManager._load_codelists()` now looks for `_unicefdata_codelists.yaml` (was `codelists.yaml`)
- **Category lookup**: `list_categories()` and `search_indicators(category=...)` now fall back to `_infer_category()` when the `category` field is absent from cached indicator data — fixes all categories showing as `UNKNOWN`

### Tested

- All startup warnings resolved with installed package
- `list_categories()` now returns 19 populated categories (792 indicators)
- `search_indicators(category="CME")` returns 39 indicators as expected

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

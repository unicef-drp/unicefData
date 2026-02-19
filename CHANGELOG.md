# unicefData Multi-Language Changelog

**Overall changelog for the unicefData trilingual project (R, Python, Stata).**

See language-specific detailed changelogs:
- **R Package**: [r/NEWS.md](r/NEWS.md) — R-specific changes, CRAN submissions
- **Python Package**: [python/CHANGELOG.md](python/CHANGELOG.md) — Python API updates
- **Stata Package**: [stata/CHANGELOG.md](stata/CHANGELOG.md) — Stata programming changes

---

## [2.3.0] - 2026-02-19

### Multi-Language Updates

- **Repository Reorganized**: Clean separation of language-specific packages
  - `r/` — R package (CRAN-ready)
  - `python/` — Python package (PyPI)
  - `stata/` — Stata package (SSC)
  - `paper/` — Academic documentation
- **R CRAN Compliance**: Cache directory moved to `tempdir()` (Benjamin Altmann review)
- **Paper Enhanced**: Added reproducibility and AI motivation section
- **All CI/CD**: Tests passing across platforms (R, Python, Stata)

### R (v2.3.0) - CRAN Ready

- ✅ Cache directory compliance (CRAN Policy 1.1.3.1)
- ✅ All reviewer feedback addressed (Uwe Ligges, Benjamin Altmann)
- ✅ 0 errors | 0 warnings | 2 notes
- See [r/NEWS.md](r/NEWS.md) for details

### Python (v2.1.0)

- Cross-language test suite verified (14/14 tests)
- Cache management at 30-day staleness threshold
- See [python/CHANGELOG.md](python/CHANGELOG.md) for details

### Stata (v2.3.0)

- Discovery Caching: Frame-based session caching (Stata 16+). YAML metadata parsed once, subsequent `search()` calls near-instantaneous
- **`__unicef_parse_indicators_yaml`**: Bulk YAML parser reads full indicators metadata into one-row-per-indicator dataset
- **`_unicef_load_indicators_cache`**: Frame cache manager with parser-version-based invalidation
- **`nocache` option**: Forces re-parsing of the YAML metadata file
- **`clear` option for search**: Clears data in memory before displaying search results
- **EDUCATION_LG dataflow**: New dataflow definition added

### Changed

- `clearcache` now also drops the `_unicef_indicators` frame cache
- `unicefdata_sync` automatically invalidates cached frame after metadata refresh
- `_unicef_search_indicators` v2.0.0: dataset-based search on cached metadata (Stata 16+); unchanged line-by-line parsing for Stata 14-15

### Removed

- Archived vestigial `_query_indicators.ado` and `_query_metadata.ado` (inherited from wbopendata, zero live callers) to `_archive/vestigial_wbopendata/`

### Tested

- Stata: 63/63 tests passing (100%) across 16 families

## [2.2.1] - 2026-02-18 (Stata)

### Fixed

- **Multi-indicator fallback overwrite**: Primary HTTP import no longer clobbers valid fallback data (added `ind_success_via_fallback` guard)
- **Search tier-filter bypass**: First match block in `_unicef_search_indicators` now applies tier/orphan filtering (was missing, allowing unfiltered indicators to leak)
- **`latest`/`mrv` filter**: All required variables (`iso3`, `period`, `value`) checked individually instead of only last `_rc`
- **São Tomé country match**: Broad `strpos` replaced with `iso3 == "STP"`
- **Label loop count**: Dynamically computed word count replaces hardcoded value (44)

### Removed

- Corrupt `_unicef_fetch_with_fallback.ado` (3-byte file, no callers) and references from all pkg manifests
- Dead `_get_sdmx_fetch` and `_get_sdmx_parse_structure` programs from get_sdmx.ado (-74 lines)
- Non-existent file references from pkg manifests (`_dataflow_indicators_list.txt`, `_unicefdata_countries.dta`)

### Changed

- `version` declaration updated from 11 to 14 (matching Requires: Stata 14.0+)

### Tested

- Stata: 63/63 tests passing (100%) across 16 families

## [2.2.0] - 2026-02-17 (Stata)

### Added

- **Input validation**: `wide_indicators` with single indicator now raises error 198 (previously warning)
- **Input validation**: `attributes()` without `wide_attributes`/`wide_indicators` now raises error 198 (previously silently ignored)
- **Input validation**: `circa` without `year()` now raises error 198 (previously silently ignored)
- **Dataset metadata**: `_dta[]` char records version, timestamp, syntax, indicator, dataflow
- **Variable metadata**: Variable-level chars on value and indicator columns
- **`nochar` option**: Suppress char metadata writes
- **4 new test families**: DATA (1), MULTI (2), PERF (1), REGR (1)
- **5 new DET tests**: multi-country, time series, vaccination, nofilter, long series fixtures

### Fixed

- **Compound quoting**: All `strpos()` and `lower()` calls on `0` macro use compound quotes for `fromfile()` paths
- **Block comment bug**: `/*.csv` in comment parsed as block comment, swallowing DET test section
- **Windows backslash paths**: `c(pwd)` causing escape char errors in DET fixtures
- **XPLAT-01/04**: Cross-platform metadata paths corrected (Root/R/Stata instead of Python/R/Stata)
- **EXT-05**: Replaced unavailable CCRI dataflow with ECD; accepts graceful API error

### Tested

- Stata: 63/63 tests passing (100%) across 16 families

## [2.1.0] - 2026-02-07 (All Platforms)

### Added

- **Cache management APIs**: `clear_unicef_cache()` (R, 6 layers), `clear_cache()` (Python, 5 layers), `clearcache` subcommand (Stata, drops cached frames)
- **Python `SDMXTimeoutError`**: Typed exception for timeouts; configurable via `UNICEFSDMXClient(timeout=120)`
- **Cross-language test suite**: 39 shared fixture tests (Python 14, R 13, Stata 12) using shared CSV fixtures
- **YAML_SCHEMA.md**: Documents all 7 YAML file types used across the package

### Fixed

- **R `apply_circa()`**: Countries with all-NA values no longer silently dropped
- **R hardcoded paths**: Replaced with `system.file()` resolution in `indicator_registry.R`
- **Stata hardcoded paths**: 3-tier resolution (PLUS -> findfile/adopath -> cwd)
- **404 error context**: All 3 languages now include tried dataflows in error messages

### Changed

- Python timeout: raises `SDMXTimeoutError` instead of returning empty DataFrame
- Staleness threshold verified at 30 days across all 3 languages

### Tested

- Python: 32/32 tests passing
- R: 26/26 tests passing
- Stata: 7/7 QA + 12/12 cross-language tests passing

## [2.0.4] - 2026-02-01 (Stata)

### Fixed
- **False warning bug**: Resolved issue where valid disaggregation filters showed "NOT supported" warnings
  - Fixed metadata_path reset logic (line 707 of unicefdata.ado)
  - Changed from unconditional reset to conditional fallback
  - Preserves metadata_path when available, only resets if missing
  - Eliminates false warnings while maintaining error detection for truly unsupported filters
  - Validated: 32/32 cross-platform indicators with 100% consistency

### Changed
- **Examples documentation**: Refreshed unicefdata_examples.ado to match v2.0.4 API
  - Updated syntax documentation clarity
  - Improved disaggregation handling examples
  - Aligned with latest metadata system

### Updated (Cross-Platform)
- **Python**: sdmx_client.py aligned with fixed Stata behavior
- **R**: unicefData.R and unicef_core.R wrappers consistent with corrected logic

### Tested
- Python: 28/28 tests passing, 1 optional skipped
- R: 8/8 tests passing
- Stata: 32/32 cross-platform validation (100%)

## [2.0.0] - 2026-01-31 (All Platforms)

### Changed
- **Version alignment**: All platforms (R, Python, Stata) now at version 2.0.0
- **Documentation regenerated**: Roxygen2 man/*.Rd files updated with new internal helper docs
- **Workspace cleanup**: Consolidated internal/_archive/ folder, removed 326+ duplicate/stale files

### Fixed
- **R metadata.R**: Fixed incomplete `.yaml_scalar()` function that was breaking roxygen2 documentation generation

### Added
- New man/*.Rd files for internal helper functions:
  - `dot-create_vintage.Rd`, `dot-fetch_one_flow.Rd`, `dot-fetch_xml.Rd`
  - `dot-get_fallback_sequences.Rd`, `dot-is_http_404.Rd`
  - `dot-load_yaml.Rd`, `dot-load_yaml_from_path.Rd`, `dot-update_sync_history.Rd`
  - `get_fallback_dataflows.Rd`

## [1.10.0] - 2026-01-18 (Stata)

### Added
- **NEW**: `fromfile(filename)` option for offline/CI testing - loads data from CSV instead of calling API
- **NEW**: `tofile(filename)` option to save raw API response to CSV for creating test fixtures
- Enables deterministic, fast CI testing without network dependency
- Supports GitHub Actions and other CI workflows with pre-generated fixture files

### Example Usage
```stata
* Create test fixture (one-time, with network)
unicefdata, indicator(CME_MRY0T4) countries(AFG) tofile("fixtures/cme_afg.csv") clear

* Run tests using fixture (fast, no network)
unicefdata, indicator(CME_MRY0T4) fromfile("fixtures/cme_afg.csv") clear
```

## [1.9.3] - 2026-01-18 (Stata)

### Fixed
- **Critical bugfix**: `nofilter` option now correctly suppresses filter_option, allowing fetch of ALL disaggregations (sex M/F/_T, wealth Q1-Q5/_T)

## [1.9.2] - 2026-01-18 (Stata)

### Fixed
- **Critical bugfix**: `filter_option` now properly defined and passed to `get_sdmx` (was undefined, causing API-level filtering to fail silently)
- **Critical bugfix**: `countries()` option now passed to `get_sdmx` for API-level country filtering (previously only filtered post-download)
- **Critical bugfix**: Multi-value filters (e.g., `sex(M F)`) now converted to SDMX OR syntax (`M+F`) for correct API queries

### Changed
- Filter system now works at API level: queries like `countries(AFG BGD) sex(M F)` reduce downloads from 33,000+ to ~280 observations
- Default behavior returns totals only (`_T`); use `nofilter` to fetch all disaggregations

## [1.9.0] - 2026-01-17 (Stata)

### Added
- Tiered discovery options in `unicefdata` (Stata): default Tier 1; opt-in `showtier2`, `showtier3`, `showall`, `showorphans`
- Warning messages for non-default tiers indicating provenance and risk
- Examples do-file `doc/examples/run_tier_examples.do`
- Tier preservation check script `validation/scripts/check_tier_preservation.py`

### Changed
- Help docs updated with "Tier Filters" section; version banner set to 1.9.0
- Ado header bumped to 1.9.0 with NEW notes

### Notes
- Sync workflow should preserve tier metadata fields. Use `run_sync_enriched.do` to enrich and verify preservation.

## [1.8.0] - 2026-01-16 (Stata)
- Subnational access option and dataflow guards

## [1.5.2] - 2026-01-06 (All)
- Various improvements and tests across R/Python/Stata

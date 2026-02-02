# Changelog

All notable changes to this project will be documented in this file.

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

# unicefData (R Package) Changelog

## 2.3.0 (2026-02-19)

### CRAN Compliance

* Moved cache directory from `.unicef_cache/` to `tempdir()` for CRAN policy compliance
* All cached files now written to session-specific temporary directory
* Cache automatically cleaned up at R session end
* Updated DESCRIPTION file per CRAN reviewer feedback (Benjamin Altmann)
* Fixed LICENSE file format
* Added CRAN submission comments in `cran-comments.md`

### Testing

* All R CMD check tests passing (0 errors | 0 warnings | 2 notes)
* Tested on R-hub builder (Windows/Linux/macOS)
* 328+ automated tests across 11 test families

## 2.2.0 (2026-02-17)

### Testing Infrastructure

* Added 5 new testthat test files:
  - `test-transformations.R`
  - `test-deterministic.R`
  - `test-discovery.R`
  - `test-sync-pipeline.R`
  - `test-error-conditions.R`
* Added `helper-fixtures.R` with `testthat::test_path()` for R CMD check compatibility
* Deterministic fixture system with automated extraction via git hooks
* Full CI matrix: R (devel/release/oldrel × Ubuntu/macOS/Windows)

### Bug Fixes

* Fixed category resolution fallback in `list_categories()` - eliminates "UNKNOWN" entries
* Added input validation for `unicefData()` with helpful `search_indicators()` hint

### Documentation

* Added roxygen2 documentation for all exported functions
* Added vignettes for common workflows
* Replaced hardcoded paths with `system.file()` resolution for portability

## 2.1.0 (2026-02-07)

### Cache Management

* Added `clear_unicef_cache()` - clears 6 cache layers with optional reload
* All cache functions verified at 30-day staleness threshold
* Cache directory configurable via options

### Error Handling Improvements

* Fixed `apply_circa()` NA handling - no longer drops countries with all-NA values
* All 404 errors now include tried dataflows context
* Improved error messages with actionable suggestions

### Testing Infrastructure

* Added 3 new API response fixture CSVs (nutrition, sex disaggregation, multi-indicator)
* Created expected output fixtures for cross-language comparison
* Cross-language validation tests: R (13/13 passing)

## 2.0.0 (2026-01-31)

### Major Fixes

* Fixed critical path extraction bug in metadata sync
* All enrichment phases now working correctly
* Tier classification and disaggregation metadata properly loaded

### Documentation

* Roxygen2 regenerated for all functions
* Fixed `.yaml_scalar()` function documentation
* Updated all `man/*.Rd` files

### Testing & Quality Assurance

* Full test suite verified: R (26 tests passing)
* All R CMD check tests passing

### Breaking Changes

* Version bump to 2.0.0 reflects major reliability improvements

## 1.6.0 (2026-01-12)

### Enhancements

* Extended dataflow fallback logic for better indicator coverage
* Improved automatic dataflow detection
* Added support for new indicator prefixes

### Bug Fixes

* Fixed edge cases in indicator search
* Improved metadata caching reliability

## 1.5.0 (2025-12-15)

### New Features

* Added vintage parameter for historical data access
* Improved metadata synchronization
* Enhanced error messages for API failures

### Bug Fixes

* Fixed 404 handling for missing indicators
* Corrected URL construction for SDMX queries

## 1.4.0 (2025-11-20)

### New Features

* Added support for disaggregation filters (sex, age, residence)
* Improved data transformation pipeline
* Enhanced metadata validation

### Bug Fixes

* Fixed encoding issues in indicator labels
* Corrected time period parsing

## 1.3.0 (2025-10-10)

### New Features

* Initial R package release with core UNICEF SDMX API client
* Support for 700+ UNICEF indicators
* Metadata search and discovery functions
* Data download and transformation
* YAML-based configuration

### Documentation

* Comprehensive README with usage examples
* Vignettes for common workflows
* Full roxygen2 API documentation

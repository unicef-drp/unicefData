# unicefData (R Package) Changelog

## 2.4.1 (2026-04-20)

### Bug Fixes

* Added `Accept-Language: en` header to all SDMX API requests via `httr::RETRY`
  in `fetch_sdmx_text()` — prevents occasional non-English indicator names
  returned by the UNICEF SDMX API when no locale is specified (fixes #45)

## 2.4.0 (2026-03-26)

### New Features

* **`diagnose` parameter**: New `diagnose = TRUE` option for `unicefData()` that
  classifies empty results via tibble attributes:
  - `attr(df, "query_status")`: One of `ok`, `indicator_not_found`, `country_not_found`,
    `year_not_found`, `year_beyond_range`
  - `attr(df, "available_years")`: Years with data for this country+indicator
  - `attr(df, "nearest_year")`: Closest available year to the requested year
  - `attr(df, "message")`: Human-readable explanation
* When `diagnose = FALSE` (default), behavior is unchanged — year filters are
  sent to the API server-side for performance.

### Bug Fixes

* Added missing `verbose` parameter to `get_sdmx()` (was referenced but never
  declared; masked by `globalVariables()`)
* Bumped minimum R version from 3.5.0 to 4.0.0 (`tools::R_user_dir()` requires R >= 4.0)
* Fixed `.metadata_config` environment parent (now uses `emptyenv()` consistently)
* Removed redundant `%||%` redefinitions in `flows.R` (already imported from rlang)
* Excluded `R/README.md` from package build to avoid R CMD check NOTE
* Switched all `\donttest{}` examples to `\dontrun{}` for deterministic CI

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

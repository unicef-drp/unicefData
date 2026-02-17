# R testthat Test Suite

Unit and integration tests for the `unicefData` R package using the
[testthat](https://testthat.r-lib.org/) framework.

**Last Updated**: 2026-02-17

## Quick Start

```r
# From the package root directory
devtools::test()

# Run a specific test file
testthat::test_file("tests/testthat/test-deterministic.R")
```

## Test Files

| File | Tests | API? | Fixtures | Description |
|------|-------|------|----------|-------------|
| `test-deterministic.R` | 13 | No | 12 CSVs (`deterministic/`) | Frozen data validation (Gould Phase 6) |
| `test-transformations.R` | 12 | No | 6 CSVs (`deterministic/`) | Data cleaning and transformation pipeline |
| `test-error-conditions.R` | 12 | No | 8 CSVs (`deterministic/`) | Parameter validation and data quality |
| `test-sync-pipeline.R` | 12 | No | XML (`xml/`, `api_responses/`), YAML (`yaml/`) | SDMX XML to YAML metadata sync |
| `test-discovery.R` | 18 | No | 2 YAMLs (`yaml/`) | Indicator discovery from metadata |
| `test-build_indicator_catalog.R` | 3 | No | None | Package loading and namespace |
| `test-404-fallback.R` | 3 | Yes | None | HTTP 404 fallback (skipped in CI) |
| `test-list-dataflows.R` | 6 | Yes | None | Dataflow listing (skipped on CRAN) |
| `test-unicefData.R` | 2 | Yes | None | Core data retrieval function |
| `test-available_indicators.R` | 2 | Partial | None | Indicator listing |

**Total**: ~83 tests. ~70 run offline using fixtures; ~13 require live API access.

## Test Categories

### Offline Tests (Run in CI)

These tests use frozen fixture files and never call the live API.
They run in all environments: CI, CRAN, and local.

- **Deterministic tests** (`test-deterministic.R`) — Core test suite validating
  pinned CSV data: value pinning, multi-country, time series trends, sex
  disaggregation, regression baselines. References Gould (2001) Phase 6.

- **Transformation tests** (`test-transformations.R`) — Tests internal functions
  `clean_unicef_data()` and `filter_unicef_data()`: SDMX column renaming,
  numeric conversion, sex filtering, geo_type assignment, edge cases.

- **Error condition tests** (`test-error-conditions.R`) — Parameter validation
  (`parse_year()`), duplicate detection on key dimensions, data type assertions
  (numeric OBS_VALUE, integer TIME_PERIOD, 3-char ISO3 REF_AREA).

- **Sync pipeline tests** (`test-sync-pipeline.R`) — Tests XML parsing functions
  that convert SDMX codelists to YAML metadata. Validates dataflow, indicator,
  country, and region parsing. Cross-checks XML and YAML fixture consistency.

- **Discovery tests** (`test-discovery.R`) — Tests indicator lookup, search, and
  filtering from YAML metadata. Uses portable helper functions that replicate
  package logic (can run without the package installed).

- **Package loading tests** (`test-build_indicator_catalog.R`) — Verifies package
  namespace integrity and exported functions.

### Live API Tests (Skipped in CI)

These tests call the UNICEF SDMX API and are protected with `skip_on_cran()`
and/or `skip_on_ci()`. They only run in interactive local sessions.

- **404 fallback tests** (`test-404-fallback.R`) — Invalid indicators return
  empty data frames; valid indicators work after a 404 fallback.

- **Dataflow listing tests** (`test-list-dataflows.R`) — Output schema, known
  dataflows present, no duplicates. Uses `tryCatch` for graceful API failures.

- **Core function tests** (`test-unicefData.R`) — Valid indicator returns data
  frame with expected columns; network errors handled gracefully.

## Fixture Infrastructure

Fixtures are loaded via `helper-fixtures.R` (auto-sourced by testthat).

### Path Resolution

`helper-fixtures.R` provides these functions:

| Function | Resolves to |
|----------|-------------|
| `get_fixtures_dir()` | `tests/fixtures/deterministic/` |
| `get_api_fixtures_dir()` | `tests/fixtures/api_responses/` |
| `get_xml_fixtures_dir()` | `tests/fixtures/xml/` |
| `get_yaml_fixtures_dir()` | `tests/fixtures/yaml/` |

Each function tries multiple candidate paths to work correctly during both
interactive use and `R CMD check`.

### Helper Functions

- `read_fixture(filename)` — Reads a CSV from `fixtures/deterministic/`
- `skip_if_no_fixtures(dir)` — Skips test if fixture directory is missing

### Fixture Directories

All fixture files are tracked directly in git (no ZIP extraction needed):

```text
tests/fixtures/
├── api_responses/   # Mock SDMX CSV/XML responses (7 files)
├── deterministic/   # Pinned test CSVs (12 files + manifest.json)
├── expected/        # Cross-language validation outputs (4 files)
├── xml/             # Subset XML codelists (3 files)
├── xml_full/        # Full codelists + enrichment (18 files)
└── yaml/            # Metadata fixtures (4 files)
```

## Mocking Approach

R tests do **not** use HTTP mocking libraries (`httptest`, `webmockr`).
Instead, offline tests read frozen fixture files directly via `read.csv()`.
This is the same approach used by Stata tests.

For Python HTTP mocking details, see `internal/mock_design/`.

## CI Workflows

- **R CMD check** (`.github/workflows/check.yaml`) — Runs `devtools::check()`
  which executes all testthat tests. Live API tests are skipped via `skip_on_ci()`.

- **R Scripted Tests** (`.github/workflows/r-scripted-tests.yaml`) — Runs
  additional R test scripts from `R/tests/`.

## Related Documentation

- `tests/testthat/helper-fixtures.R` — Fixture path resolution and helpers
- `tests/fixtures/api_responses/README.md` — API response fixture documentation
- `tests/fixtures/expected/README.md` — Expected output fixture documentation
- `R/tests/README.md` — R scripted test documentation (integration tests)
- `internal/mock_design/` — Python mock API design documentation
- `internal/TEST_STRATEGY.md` — Cross-language test strategy overview

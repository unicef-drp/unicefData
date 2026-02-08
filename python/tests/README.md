# Python Test Suite

This directory contains tests for the Python `unicefdata` library.

> **See also:** [validation/README.md](../../validation/README.md) for the complete testing infrastructure documentation.

## Quick Start

```bash
cd python/
pytest tests/ -v
```

## Test Scripts

| Script | Description | Framework |
|--------|-------------|-----------|
| `test_unicef_api.py` | Core API and client unit tests | pytest |
| `test_metadata_manager.py` | Metadata management tests | pytest |
| `test_cross_language_output.py` | Cross-language fixture validation | pytest |
| `test_pipeline_mocked.py` | Full pipeline with mocked HTTP | pytest |
| `run_tests.py` | Comprehensive integration tests | standalone |
| `test_dimensions.py` | SDMX dimension parsing tests | standalone |

## Unit Tests (pytest)

### `test_unicef_api.py`

Unit tests for `UNICEFSDMXClient` and utility functions:
- Client initialization
- Indicator fetching (with API connection)
- Dataflow detection
- Country code validation
- Year range validation

```bash
pytest tests/test_unicef_api.py -v
```

### `test_metadata_manager.py`

Tests for the `MetadataManager` class:
- Schema retrieval
- Column mapping
- DataFrame standardization
- DataFrame validation

```bash
pytest tests/test_metadata_manager.py -v
```

## Integration Tests

### `run_tests.py`

Comprehensive test suite that validates all major functionality:
- Listing dataflows
- Fetching data for specific domains (Mortality, Stunting, Immunization)
- Handling multiple indicators
- Metadata synchronization

```bash
python tests/run_tests.py
```

**Output files:**
- `output/test_dataflows.csv`
- `output/test_mortality.csv`
- `output/test_stunting.csv`
- `output/test_immunization.csv`
- `output/test_multiple_indicators.csv`

### `test_dimensions.py`

Standalone script to test SDMX dimension extraction from dataflow XML responses.

```bash
python tests/test_dimensions.py
```

## Output Directory

All test artifacts are saved in `output/` (gitignored):
- `metadata_sync_test/` - Metadata cache from sync tests
- `*.csv` - Various output files from `run_tests.py`

## Running All Tests

```bash
# Unit tests only
pytest tests/ -v

# With coverage
pytest tests/ -v --cov=unicefdata

# Integration tests (requires API connection)
python tests/run_tests.py
```

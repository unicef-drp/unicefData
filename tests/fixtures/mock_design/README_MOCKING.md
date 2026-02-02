# Test Mocking Strategy

**Date**: 2026-01-25
**Policy**: No tests should retrieve data from the live UNICEF data warehouse.

## Current Status

### ✅ Fully Mocked (Run in CI)
- **test_list_dataflows.py** - All 6 tests use mocked SDMX XML responses
  - Uses `responses` library to mock HTTP calls
  - Uses `mock_sdmx_api` fixture from conftest.py
  - Tests run fast (~1s total) without API access

### ⚠️ Integration Tests (Skipped in CI)
- **test_404_fallback.py** - 4 tests marked as `@pytest.mark.integration`
  - Requires complex mocking of full SDMX data fetch pipeline
  - Currently skipped in CI to avoid 403 errors
  - Can be run manually for validation

### ✅ Other Tests
- **test_metadata_manager.py** - Uses local files only
- **test_unicef_api.py** - Uses local metadata
- **test_dimensions.py** - Unit tests, no API calls

## Running Tests

### CI/CD (GitHub Actions)
```bash
cd python
pytest tests/  # Runs all non-integration tests
```

Integration tests are automatically skipped (marked with `@pytest.mark.integration`).

### Local Development (All Tests)
```bash
cd python
pytest tests/ -m "integration"  # Run ONLY integration tests (requires API access)
pytest tests/                     # Run ALL tests including integration
```

### Local Development (Skip Integration)
```bash
cd python
pytest tests/ -m "not integration"  # Skip integration tests
```

## Mock Fixtures

All fixtures are defined in `conftest.py`:

- `mock_dataflows_xml` - SDMX XML response for dataflow list
- `mock_sdmx_api` - Setup function for mocking API endpoints
- `mock_indicator_response_empty` - Empty result for invalid indicators
- `mock_indicator_response_valid` - Valid data response

## Adding New Tests

### For Tests That Need API Data

1. Create fixture in `conftest.py` with sample response
2. Use `@responses.activate` decorator
3. Call fixture to setup mocks
4. Write test as normal

Example:
```python
import responses

@responses.activate
def test_something(mock_sdmx_api):
    mock_sdmx_api()  # Setup mocks
    result = list_dataflows()
    assert len(result) > 0
```

### For Integration Tests (Manual Only)

1. Mark with `@pytest.mark.integration`
2. Document in test docstring that it requires API access
3. These will be skipped in CI

Example:
```python
@pytest.mark.integration
def test_live_api():
    """Requires live API access - manual testing only"""
    result = unicefData(indicator="CME_MRY0T4", countries=["ALB"])
    assert len(result) > 0
```

## Dependencies

The `responses` library is required for HTTP mocking:
```bash
pip install responses
```

This is installed automatically in GitHub Actions (see `.github/workflows/python-tests.yaml`).

## Benefits

- ✅ Fast tests (no network I/O)
- ✅ Reliable (no API downtime)
- ✅ No rate limiting issues
- ✅ Works in CI/CD without API keys
- ✅ Deterministic results

## Future Work

To fully mock `test_404_fallback.py`:
1. Create SDMX data response fixtures (JSON/XML)
2. Mock SDMXClient methods
3. Remove `@pytest.mark.integration` markers
4. Add to CI test suite

---

**Last Updated**: 2026-01-25
**Related Files**: conftest.py, pytest.ini, python-tests.yaml

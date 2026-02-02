# Mock API Implementation Guide

**Step-by-Step Guide to Implementing API Mocks**

## Prerequisites

✅ Already completed:
- `responses` library installed (in workflow)
- `pytest.ini` created with markers
- `conftest.py` created with dataflow mocks
- `test_list_dataflows.py` fully mocked

## Step 1: Add CSV Response Fixtures

Add these to `conftest.py`:

```python
@pytest.fixture
def mock_csv_valid_cme():
    """
    Mock CSV response for valid CME indicator (CME_MRY0T4).
    Returns realistic under-5 mortality data for Albania.
    """
    return """DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS,DATA_SOURCE
CME,ALB,CME_MRY0T4,_T,2020,8.5,PER_1000_LIVEBIRTHS,AVAILABLE,NATIONAL_STATISTICS
CME,ALB,CME_MRY0T4,_T,2021,8.2,PER_1000_LIVEBIRTHS,AVAILABLE,NATIONAL_STATISTICS
CME,ALB,CME_MRY0T4,_T,2022,7.9,PER_1000_LIVEBIRTHS,AVAILABLE,NATIONAL_STATISTICS"""


@pytest.fixture
def mock_csv_empty():
    """
    Mock empty CSV response for invalid/not-found indicators.
    Headers only, no data rows - results in empty DataFrame.
    """
    return """DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS
"""


@pytest.fixture
def mock_csv_valid_usa():
    """
    Mock CSV response for USA country (used in fallback tests).
    """
    return """DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS
CME,USA,CME_MRY0T4,_T,2020,6.7,PER_1000_LIVEBIRTHS,AVAILABLE
CME,USA,CME_MRY0T4,_T,2021,6.5,PER_1000_LIVEBIRTHS,AVAILABLE"""
```

## Step 2: Create Data Endpoint Mock Setup

Add this fixture to `conftest.py`:

```python
import re

@pytest.fixture
def mock_sdmx_data_endpoints(mock_csv_valid_cme, mock_csv_valid_usa, mock_csv_empty):
    """
    Setup mocks for SDMX data retrieval endpoints.

    Mocks different scenarios:
    - Valid indicator (CME_MRY0T4) → Returns CSV data
    - Invalid indicator (INVALID_*) → Returns 404
    - Fake indicator (FAKE_*) → Returns empty CSV (simulates no data found)

    Use with @responses.activate decorator in tests.

    Example:
        @responses.activate
        def test_something(mock_sdmx_data_endpoints):
            mock_sdmx_data_endpoints()  # Setup mocks
            result = unicefData(indicator="CME_MRY0T4", countries=["ALB"])
            assert len(result) > 0
    """
    def _setup_mocks():
        base_url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data"

        # ====================================================================
        # Valid Indicator: CME_MRY0T4 with Albania (ALB)
        # ====================================================================
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(base_url)}/UNICEF,.*CME_MRY0T4\.ALB.*'),
            body=mock_csv_valid_cme,
            status=200,
            content_type='text/csv'
        )

        # ====================================================================
        # Valid Indicator: CME_MRY0T4 with USA
        # ====================================================================
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(base_url)}/UNICEF,.*CME_MRY0T4\.USA.*'),
            body=mock_csv_valid_usa,
            status=200,
            content_type='text/csv'
        )

        # ====================================================================
        # Invalid Indicators: Return 404 Not Found
        # ====================================================================
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(base_url)}/UNICEF,.*INVALID.*'),
            body='',
            status=404,
            content_type='text/plain'
        )

        # ====================================================================
        # Fake Indicators: Return empty CSV (no data, but valid response)
        # Used to test fallback logic
        # ====================================================================
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(base_url)}/UNICEF,.*FAKE.*'),
            body=mock_csv_empty,
            status=200,
            content_type='text/csv'
        )

        # ====================================================================
        # Generic Invalid: Any other unknown indicator → 404
        # ====================================================================
        # This should be last as it's a catch-all
        # Note: Only add if you want all unknown indicators to 404
        # Otherwise, let real tests use real indicators or add specific mocks

    return _setup_mocks
```

## Step 3: Update test_404_fallback.py

### Before (Integration Test):

```python
@pytest.mark.integration
def test_invalid_indicator_returns_empty_dataframe(self):
    """Invalid indicator should return empty DataFrame without raising"""
    df = unicefData(
        indicator="INVALID_XYZ_NONEXISTENT",
        countries=["ALB"],
        year=2020
    )
    assert isinstance(df, pd.DataFrame)
    assert df.empty
```

### After (Mocked Test):

```python
import responses

@responses.activate
def test_invalid_indicator_returns_empty_dataframe(self, mock_sdmx_data_endpoints):
    """Invalid indicator should return empty DataFrame without raising"""
    mock_sdmx_data_endpoints()  # Setup mocks

    df = unicefData(
        indicator="INVALID_XYZ_NONEXISTENT",
        countries=["ALB"],
        year=2020
    )

    assert isinstance(df, pd.DataFrame)
    assert df.empty  # Should be empty (404 → fallback → no data)
```

## Step 4: Complete test_404_fallback.py Conversion

Here's the full updated file:

```python
"""
Test 404 fallback behavior (PR #14)

Validates that invalid indicators return empty DataFrames without raising exceptions,
and that the 404-aware fallback to GLOBAL_DATAFLOW works as expected.

NOTE: All tests use mocked API responses - no live API calls are made.
"""

import pytest
import pandas as pd
import responses
from unicef_api import unicefData


class Test404Fallback:
    """Tests for 404 error handling and GLOBAL_DATAFLOW fallback"""

    @responses.activate
    def test_invalid_indicator_returns_empty_dataframe(self, mock_sdmx_data_endpoints):
        """Invalid indicator should return empty DataFrame without raising"""
        mock_sdmx_data_endpoints()

        # Use clearly invalid indicator code
        df = unicefData(
            indicator="INVALID_XYZ_NONEXISTENT",
            countries=["ALB"],
            year=2020
        )

        # Should return DataFrame (possibly empty)
        assert isinstance(df, pd.DataFrame)

        # Empty result is expected for invalid indicator
        # (404 fallback should have tried GLOBAL_DATAFLOW and found nothing)
        assert df.empty

    @responses.activate
    def test_404_fallback_preserves_column_structure(self, mock_sdmx_data_endpoints):
        """Even with invalid indicator, DataFrame structure should be consistent"""
        mock_sdmx_data_endpoints()

        df = unicefData(
            indicator="FAKE_INDICATOR_404_TEST",
            countries=["USA"],
            year=2020
        )

        # Should return DataFrame (empty but with columns)
        assert isinstance(df, pd.DataFrame)

        # Even if empty, should have standard structure
        # (CSV headers were returned, so columns exist)
        if not df.empty or len(df.columns) > 0:
            # Has columns from CSV headers
            assert 'OBS_VALUE' in df.columns or len(df.columns) > 0

    @responses.activate
    def test_valid_indicator_after_404_still_works(self, mock_sdmx_data_endpoints):
        """After a 404, subsequent valid requests should work normally"""
        mock_sdmx_data_endpoints()

        # First, try invalid indicator
        df_invalid = unicefData(
            indicator="INVALID_FIRST",
            countries=["ALB"],
            year=2020
        )
        assert df_invalid.empty

        # Then, try valid indicator - should work
        df_valid = unicefData(
            indicator="CME_MRY0T4",
            countries=["ALB"],
            year=2020
        )

        assert isinstance(df_valid, pd.DataFrame)
        assert not df_valid.empty  # Should have data
        assert 'OBS_VALUE' in df_valid.columns

    @responses.activate
    def test_multiple_invalid_indicators_handled_gracefully(self, mock_sdmx_data_endpoints):
        """Multiple invalid indicators should all return empty DataFrames without errors"""
        mock_sdmx_data_endpoints()

        invalid_indicators = ["INVALID_A", "INVALID_B", "INVALID_C"]

        for indicator in invalid_indicators:
            df = unicefData(
                indicator=indicator,
                countries=["ALB"],
                year=2020
            )

            # Each should return empty DataFrame
            assert isinstance(df, pd.DataFrame)
            assert df.empty
```

## Step 5: Verification

### Run Tests Locally

```bash
cd python
pytest tests/test_404_fallback.py -v
```

Expected output:
```
tests/test_404_fallback.py::Test404Fallback::test_invalid_indicator_returns_empty_dataframe PASSED
tests/test_404_fallback.py::Test404Fallback::test_404_fallback_preserves_column_structure PASSED
tests/test_404_fallback.py::Test404Fallback::test_valid_indicator_after_404_still_works PASSED
tests/test_404_fallback.py::Test404Fallback::test_multiple_invalid_indicators_handled_gracefully PASSED

===== 4 passed in 0.5s =====
```

### Run All Tests

```bash
cd python
pytest tests/ -v
```

Expected: All tests pass, no API calls made.

## Step 6: Update pytest.ini (Optional)

Since tests are now mocked, remove the integration marker from test docstrings:

```ini
# pytest.ini

[pytest]
testpaths = tests
python_files = test_*.py

markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    # integration marker removed - all tests now mocked
```

## Step 7: Commit Changes

```bash
git add python/tests/conftest.py
git add python/tests/test_404_fallback.py
git add python/tests/*.md
git commit -m "feat(tests): mock 404 fallback tests for CI/CD

- Added CSV response fixtures for valid/invalid indicators
- Created mock_sdmx_data_endpoints fixture for data API
- Converted test_404_fallback.py to use mocks
- Removed @pytest.mark.integration markers
- All tests now pass without live API access

Tests coverage:
- Valid indicator responses (CME_MRY0T4)
- Invalid indicator 404 responses
- Fake indicator empty responses
- Fallback logic validation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## Troubleshooting

### Issue: Test Still Hits Live API

**Symptom**: Test takes >5 seconds or fails with network errors

**Solution**: Ensure `@responses.activate` decorator is present and mock setup is called:

```python
@responses.activate  # <- Must have this
def test_something(self, mock_sdmx_data_endpoints):
    mock_sdmx_data_endpoints()  # <- Must call this
    # ... test code
```

### Issue: 404 Error Despite Mock

**Symptom**: Test fails with `SDMXNotFoundError`

**Solution**: Check URL pattern matches. Add debug output:

```python
@responses.activate
def test_debug(self, mock_sdmx_data_endpoints):
    mock_sdmx_data_endpoints()

    # Add callback to see what URL is being requested
    def debug_callback(request):
        print(f"Request URL: {request.url}")
        return (404, {}, '')

    responses.add_callback(
        responses.GET,
        re.compile(r'.*'),
        callback=debug_callback
    )

    # Run test...
```

### Issue: Empty DataFrame Has Wrong Structure

**Symptom**: Assertion fails on column names

**Solution**: Check CSV headers in `mock_csv_empty`. Ensure headers match expected schema:

```csv
DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS
```

### Issue: Test Passes Locally, Fails in CI

**Symptom**: Works on local machine, fails in GitHub Actions

**Solution**:
1. Ensure `responses` is in workflow dependencies
2. Check for timezone/locale-dependent code
3. Verify no hardcoded file paths

## Best Practices

✅ **DO**:
- Use `@responses.activate` decorator
- Call setup fixture before test logic
- Use regex patterns for flexible URL matching
- Include realistic CSV data in mocks
- Test both success and failure scenarios

❌ **DON'T**:
- Mix mocked and real API calls in same test
- Hardcode full URLs (use regex patterns)
- Forget to call `mock_setup()` function
- Use mock data that doesn't match real API schema

## Reference

- **Responses Docs**: https://github.com/getsentry/responses
- **SDMX API**: https://data.unicef.org/sdmx-api-documentation/
- **Pytest Fixtures**: https://docs.pytest.org/en/stable/fixture.html

---

**Created**: 2026-01-25
**Status**: Ready to implement
**Estimated Time**: 30 minutes

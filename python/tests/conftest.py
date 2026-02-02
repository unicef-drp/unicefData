"""
Pytest configuration and shared fixtures for mocking API responses.

Fixtures read response data from tests/fixtures/api_responses/ directory,
which is shared across all language implementations (Python, Stata, R).
"""

import pytest
import responses
import json
from pathlib import Path

# Path to shared fixture files
FIXTURES_DIR = Path(__file__).parent.parent.parent / "tests" / "fixtures" / "api_responses"


@pytest.fixture
def mock_dataflows_xml():
    """
    Mock SDMX XML response for list_dataflows().
    Returns valid SDMX 2.1 structure matching UNICEF endpoint format.

    Source: tests/fixtures/api_responses/dataflows.xml
    """
    return (FIXTURES_DIR / "dataflows.xml").read_text(encoding='utf-8')


@pytest.fixture
def mock_indicator_response_empty():
    """
    Mock empty SDMX response for invalid indicators (404/empty result).
    """
    return {
        "data": [],
        "structure": {
            "dimensions": []
        }
    }


@pytest.fixture
def mock_indicator_response_valid():
    """
    Mock valid SDMX data response for a working indicator.
    Simplified structure matching UNICEF SDMX format.
    """
    return {
        "data": [
            {
                "indicator": "CME_MRY0T4",
                "country": "ALB",
                "year": 2020,
                "value": 8.5,
                "sex": "Total"
            }
        ],
        "structure": {
            "dimensions": ["REF_AREA", "TIME_PERIOD", "SEX"],
            "attributes": ["OBS_STATUS", "UNIT_MEASURE"]
        }
    }


@pytest.fixture
def mock_csv_valid_cme():
    """
    Mock CSV response for valid CME indicator (CME_MRY0T4).
    Returns realistic under-5 mortality data for Albania.

    Source: tests/fixtures/api_responses/cme_albania_valid.csv
    """
    return (FIXTURES_DIR / "cme_albania_valid.csv").read_text(encoding='utf-8')


@pytest.fixture
def mock_csv_valid_usa():
    """
    Mock CSV response for USA country (used in fallback tests).

    Source: tests/fixtures/api_responses/cme_usa_valid.csv
    """
    return (FIXTURES_DIR / "cme_usa_valid.csv").read_text(encoding='utf-8')


@pytest.fixture
def mock_csv_empty():
    """
    Mock empty CSV response for invalid/not-found indicators.
    Headers only, no data rows - results in empty DataFrame.

    Source: tests/fixtures/api_responses/empty_response.csv
    """
    return (FIXTURES_DIR / "empty_response.csv").read_text(encoding='utf-8')


@pytest.fixture
def mock_sdmx_api(mock_dataflows_xml):
    """
    Pytest fixture to mock SDMX API endpoints (dataflow list).
    Use with @responses.activate decorator in tests.

    Example:
        @responses.activate
        def test_something(mock_sdmx_api):
            mock_sdmx_api()  # Setup mocks
            result = list_dataflows()
            assert len(result) > 0
    """
    def _setup_mocks():
        # Mock dataflow list endpoint
        responses.add(
            responses.GET,
            "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF",
            body=mock_dataflows_xml,
            status=200,
            content_type='application/xml'
        )

    return _setup_mocks


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
        import re

        base_url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data"

        # Valid Indicator: CME_MRY0T4 (matches any country or no country filter)
        # Matches patterns like: /CME_MRY0T4.ALB or .CME_MRY0T4.? or .CME_MRY0T4.
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(base_url)}/UNICEF,.*CME_MRY0T4[\.].+'),
            body=mock_csv_valid_cme,
            status=200,
            content_type='text/csv'
        )

        # Invalid Indicators: Return 404 Not Found
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(base_url)}/UNICEF,.*INVALID.*'),
            body='',
            status=404,
            content_type='text/plain'
        )

        # Fake Indicators: Return empty CSV (no data, but valid response)
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(base_url)}/UNICEF,.*FAKE.*'),
            body=mock_csv_empty,
            status=200,
            content_type='text/csv'
        )

    return _setup_mocks

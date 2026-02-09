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


@pytest.fixture
def mock_csv_nutrition():
    """
    Mock CSV response for NUTRITION indicator (NT_ANT_HAZ_NE2).
    Multi-country stunting data for India, Ethiopia, Bangladesh.

    Source: tests/fixtures/api_responses/nutrition_multi_country.csv
    """
    return (FIXTURES_DIR / "nutrition_multi_country.csv").read_text(encoding='utf-8')


@pytest.fixture
def mock_csv_disaggregated_sex():
    """
    Mock CSV response for CME with sex disaggregation (M/F/_T).
    Brazil data with 3 sex values across 2 years.

    Source: tests/fixtures/api_responses/cme_disaggregated_sex.csv
    """
    return (FIXTURES_DIR / "cme_disaggregated_sex.csv").read_text(encoding='utf-8')


@pytest.fixture
def mock_csv_vaccination():
    """
    Mock CSV response for multiple vaccination indicators (IM_DTP3, IM_MCV1).
    Ghana and Kenya data.

    Source: tests/fixtures/api_responses/vaccination_multi_indicator.csv
    """
    return (FIXTURES_DIR / "vaccination_multi_indicator.csv").read_text(encoding='utf-8')


@pytest.fixture
def mock_pipeline_endpoints(
    mock_csv_valid_cme,
    mock_csv_nutrition,
    mock_csv_disaggregated_sex,
    mock_csv_vaccination,
    mock_csv_empty,
):
    """
    Setup mocks for full pipeline tests across multiple indicator types.

    Mocked scenarios:
    - CME_MRY0T4 → cme_albania_valid.csv (Albania, _T sex only)
    - CME_MRY0T4 with sex disaggregation → cme_disaggregated_sex.csv (Brazil, M/F/_T)
    - NT_ANT_HAZ_NE2 → nutrition_multi_country.csv (IND/ETH/BGD, with AGE)
    - IM_DTP3 / IM_MCV1 → vaccination_multi_indicator.csv (GHA/KEN)
    - Any unmatched → 404

    Use with @responses.activate decorator in tests.
    """
    def _setup_mocks(sex_fixture="albania"):
        import re

        base_url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"

        # Structure/schema endpoint — return empty XML to avoid schema errors
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(base_url)}/datastructure/.*'),
            body='<?xml version="1.0"?><Structure/>',
            status=200,
            content_type='application/xml'
        )

        data_url = f"{base_url}/data"

        # Nutrition indicator
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(data_url)}/UNICEF,.*NT_ANT_HAZ.*'),
            body=mock_csv_nutrition,
            status=200,
            content_type='text/csv'
        )

        # Vaccination indicators
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(data_url)}/UNICEF,.*IM_(DTP3|MCV1).*'),
            body=mock_csv_vaccination,
            status=200,
            content_type='text/csv'
        )

        # CME indicator — choose fixture based on test needs
        cme_body = mock_csv_disaggregated_sex if sex_fixture == "brazil" else mock_csv_valid_cme
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(data_url)}/UNICEF,.*CME_MRY0T4.*'),
            body=cme_body,
            status=200,
            content_type='text/csv'
        )

        # Catch-all: any unmatched data request → 404
        responses.add(
            responses.GET,
            re.compile(rf'{re.escape(data_url)}/UNICEF,.*'),
            body='',
            status=404,
            content_type='text/plain'
        )

    return _setup_mocks

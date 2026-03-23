"""
Tests for UNICEFSDMXClient.fetch_indicator() dataflow auto-detection.

Three cases (Copilot review comment on sdmx_client.py line 636):
  1. Indicator present in metadata  → dataflow from metadata
  2. Indicator absent from metadata → prefix-based fallback sequence
  3. WS_HCF_H-L special-case       → WASH_HEALTHCARE_FACILITY override

Each test mocks session.get so no network calls are made, then inspects
_last_url to confirm the correct dataflow appears in the request URL.
"""

import pytest
import pandas as pd
from unittest.mock import MagicMock, patch
from unicefdata import UNICEFSDMXClient

# Minimal CSV response that the client can parse without error
_EMPTY_CSV = (
    "REF_AREA,INDICATOR,SEX,WEALTH_QUINTILE,TIME_PERIOD,OBS_VALUE,"
    "UNIT_MEASURE,LOWER_BOUND,UPPER_BOUND,OBS_STATUS,DATA_SOURCE,"
    "COUNTRY_NOTES,REF_PERIOD\n"
)


def _make_response(csv_body: str = _EMPTY_CSV, status: int = 200):
    """Build a minimal requests.Response mock."""
    mock_resp = MagicMock()
    mock_resp.status_code = status
    mock_resp.text = csv_body
    mock_resp.content = csv_body.encode()
    mock_resp.raise_for_status = MagicMock()
    return mock_resp


class TestFetchIndicatorDataflowResolution:
    """Verify fetch_indicator() selects the correct dataflow."""

    def _client_with_mock_session(self):
        client = UNICEFSDMXClient()
        client.session = MagicMock()
        client.session.get.return_value = _make_response()
        return client

    def test_metadata_lookup_cme(self):
        """CME_MRY0T4 is in metadata → dataflow resolved to 'CME'."""
        client = self._client_with_mock_session()

        # Confirm metadata has CME_MRY0T4 mapped to CME
        assert "CME_MRY0T4" in client._indicators_metadata

        try:
            client.fetch_indicator("CME_MRY0T4", countries=["ALB"], start_year=2020, end_year=2020)
        except Exception:
            pass  # Empty CSV may cause downstream parse errors; URL is already set

        assert hasattr(client, "_last_url"), "fetch_indicator() must set _last_url"
        assert ",CME," in client._last_url, (
            f"Expected dataflow 'CME' in URL, got: {client._last_url}"
        )

    def test_prefix_fallback_unknown_indicator(self):
        """An indicator absent from metadata uses prefix-based fallback sequence."""
        client = self._client_with_mock_session()

        # Confirm the indicator is NOT in metadata
        unknown = "UNKNOWN_FAKE_XYZ"
        assert unknown not in client._indicators_metadata

        try:
            client.fetch_indicator(unknown, countries=["ALB"], start_year=2020, end_year=2020)
        except Exception:
            pass

        assert hasattr(client, "_last_url"), "fetch_indicator() must set _last_url"
        # Prefix 'UNKNOWN' has no specific sequence → falls back to DEFAULT or GLOBAL_DATAFLOW
        # Either way, a dataflow must appear in the URL (not empty)
        assert "/data/UNICEF," in client._last_url, (
            f"Expected UNICEF dataflow segment in URL, got: {client._last_url}"
        )

    def test_special_case_wash_hcf(self):
        """WS_HCF_H-L triggers the special-case override to WASH_HEALTHCARE_FACILITY."""
        client = self._client_with_mock_session()

        try:
            client.fetch_indicator("WS_HCF_H-L", countries=["ALB"], start_year=2020, end_year=2020)
        except Exception:
            pass

        assert hasattr(client, "_last_url"), "fetch_indicator() must set _last_url"
        assert ",WASH_HEALTHCARE_FACILITY," in client._last_url, (
            f"Expected dataflow 'WASH_HEALTHCARE_FACILITY' in URL, got: {client._last_url}"
        )

    def test_explicit_dataflow_bypasses_autodetect(self):
        """Explicit dataflow= argument always wins over auto-detection."""
        client = self._client_with_mock_session()

        try:
            client.fetch_indicator(
                "CME_MRY0T4",
                countries=["ALB"],
                start_year=2020,
                end_year=2020,
                dataflow="GLOBAL_DATAFLOW",
            )
        except Exception:
            pass

        assert hasattr(client, "_last_url"), "fetch_indicator() must set _last_url"
        assert ",GLOBAL_DATAFLOW," in client._last_url, (
            f"Expected explicit dataflow 'GLOBAL_DATAFLOW' in URL, got: {client._last_url}"
        )

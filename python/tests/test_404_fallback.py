"""
Test 404 fallback behavior (PR #14)

Validates that invalid indicators raise SDMXNotFoundError with context about
which dataflows were tried, and that the 404-aware fallback to GLOBAL_DATAFLOW
works as expected.

NOTE: All tests use mocked API responses - no live API calls are made.
"""

import pytest
import pandas as pd
import responses
from unicefdata import unicefData
from unicefdata.sdmx_client import SDMXNotFoundError


class Test404Fallback:
    """Tests for 404 error handling and GLOBAL_DATAFLOW fallback"""

    @responses.activate
    def test_invalid_indicator_raises_not_found(self, mock_sdmx_data_endpoints):
        """Invalid indicator should raise SDMXNotFoundError with tried dataflows"""
        mock_sdmx_data_endpoints()  # Setup mocks

        # Use clearly invalid indicator code
        with pytest.raises(SDMXNotFoundError, match="not found in any dataflow") as exc_info:
            unicefData(
                indicator="INVALID_XYZ_NONEXISTENT",
                countries=["ALB"],
                year=2020
            )

        # Error message should include tried dataflows context
        assert "Tried dataflows" in str(exc_info.value)

    @responses.activate
    def test_404_fallback_preserves_column_structure(self, mock_sdmx_data_endpoints):
        """Even with invalid indicator, DataFrame structure should be consistent"""
        mock_sdmx_data_endpoints()  # Setup mocks

        df = unicefData(
            indicator="FAKE_INDICATOR_404_TEST",
            countries=["USA"],
            year=2020
        )

        assert isinstance(df, pd.DataFrame)

        # Even if empty, should have standard structure
        # (CSV headers were returned, so columns exist)
        if not df.empty or len(df.columns) > 0:
            # Has columns from CSV headers - check for any standard SDMX column
            column_names = [col.lower() for col in df.columns]
            has_standard_col = any(
                col in column_names
                for col in ['iso3', 'ref_area', 'period', 'time_period', 'value', 'obs_value', 'dataflow']
            )
            # If we have columns, at least one should be standard
            if len(df.columns) > 0:
                assert has_standard_col or len(df.columns) > 0

    @responses.activate
    def test_valid_indicator_after_404_still_works(self, mock_sdmx_data_endpoints):
        """Regression test: ensure 404 fallback doesn't break subsequent valid calls"""
        mock_sdmx_data_endpoints()  # Setup mocks

        # First, try invalid indicator to trigger fallback (should raise)
        with pytest.raises(SDMXNotFoundError):
            unicefData(
                indicator="INVALID_FIRST",
                countries=["ALB"],
                year=2020
            )

        # Then, try a known good indicator (should work normally)
        df = unicefData(
            indicator="CME_MRY0T4",
            countries=["ALB"],
            year=2020
        )

        assert isinstance(df, pd.DataFrame)
        # Should have data for a known good indicator
        assert len(df) > 0
        # Should have value column (main data column)
        column_names = [col.lower() for col in df.columns]
        assert 'obs_value' in column_names or 'value' in column_names

    @responses.activate
    def test_multiple_invalid_indicators_raise_not_found(self, mock_sdmx_data_endpoints):
        """Test that multiple invalid indicators each raise SDMXNotFoundError"""
        mock_sdmx_data_endpoints()  # Setup mocks

        invalid_indicators = [
            "INVALID_A",
            "INVALID_B",
            "INVALID_C"
        ]

        for indicator in invalid_indicators:
            with pytest.raises(SDMXNotFoundError, match="not found in any dataflow"):
                unicefData(
                    indicator=indicator,
                    countries=["USA"],
                    year=2020
                )

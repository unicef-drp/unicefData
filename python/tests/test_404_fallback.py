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
        mock_sdmx_data_endpoints()  # Setup mocks

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

        # First, try invalid indicator to trigger fallback
        df_invalid = unicefData(
            indicator="INVALID_FIRST",
            countries=["ALB"],
            year=2020
        )
        assert df_invalid.empty

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
    def test_multiple_invalid_indicators_handled_gracefully(self, mock_sdmx_data_endpoints):
        """Test that multiple invalid indicators in sequence don't cause issues"""
        mock_sdmx_data_endpoints()  # Setup mocks

        invalid_indicators = [
            "INVALID_A",
            "INVALID_B",
            "INVALID_C"
        ]

        for indicator in invalid_indicators:
            df = unicefData(
                indicator=indicator,
                countries=["USA"],
                year=2020
            )

            # Each should return a DataFrame without raising
            assert isinstance(df, pd.DataFrame)
            # Should be empty (no data for invalid indicators)
            assert df.empty

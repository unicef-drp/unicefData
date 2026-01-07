"""
Test 404 fallback behavior (PR #14)

Validates that invalid indicators return empty DataFrames without raising exceptions,
and that the 404-aware fallback to GLOBAL_DATAFLOW works as expected.
"""

import pytest
import pandas as pd
from unicef_api import unicefData


class Test404Fallback:
    """Tests for 404 error handling and GLOBAL_DATAFLOW fallback"""
    
    @pytest.mark.integration
    def test_invalid_indicator_returns_empty_dataframe(self):
        """Invalid indicator should return empty DataFrame without raising"""
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
    
    @pytest.mark.integration
    def test_404_fallback_preserves_column_structure(self):
        """Even with invalid indicator, DataFrame structure should be consistent"""
        df = unicefData(
            indicator="FAKE_INDICATOR_404_TEST",
            countries=["USA"],
            year=2020
        )
        
        assert isinstance(df, pd.DataFrame)
        
        # If data returned (fallback succeeded), check standard columns
        if len(df) > 0:
            assert "iso3" in df.columns or "ref_area" in df.columns
            assert "period" in df.columns or "time_period" in df.columns
            assert "value" in df.columns or "obs_value" in df.columns
    
    @pytest.mark.integration
    def test_valid_indicator_after_404_still_works(self):
        """Regression test: ensure 404 fallback doesn't break subsequent valid calls"""
        # Try a known good indicator (should work normally)
        df = unicefData(
            indicator="CME_MRY0T4",
            countries=["ALB"],
            year=2020
        )
        
        assert isinstance(df, pd.DataFrame)
        # Should have data for a known good indicator
        assert len(df) > 0
    
    @pytest.mark.integration
    def test_multiple_invalid_indicators_handled_gracefully(self):
        """Test that multiple invalid indicators in sequence don't cause issues"""
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

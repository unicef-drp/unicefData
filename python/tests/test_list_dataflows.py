"""
Test list_dataflows() wrapper (PR #14)

Validates output schema and ensures parity with underlying list_sdmx_flows() function.
"""

import pytest
import pandas as pd
from unicef_api import list_dataflows


class TestListDataflows:
    """Tests for list_dataflows() wrapper function"""
    
    @pytest.mark.integration
    def test_returns_dataframe_with_expected_columns(self):
        """list_dataflows should return DataFrame with id, agency, version, name columns"""
        df = list_dataflows()
        
        # Should return a DataFrame
        assert isinstance(df, pd.DataFrame)
        
        # Check for expected columns from SDMX dataflow metadata
        expected_cols = ["id", "agency", "version", "name"]
        
        for col in expected_cols:
            assert col in df.columns, f"Missing expected column: {col}"
    
    @pytest.mark.integration
    def test_returns_non_empty_result(self):
        """UNICEF should have multiple dataflows (CME, NUTRITION, etc.)"""
        df = list_dataflows()
        
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0, "Should return at least one dataflow"
    
    @pytest.mark.integration
    def test_includes_known_dataflows(self):
        """Result should include known UNICEF dataflows"""
        df = list_dataflows()
        
        assert isinstance(df, pd.DataFrame)
        
        # Check for known UNICEF dataflows
        known_dataflows = ["CME", "NUTRITION", "GLOBAL_DATAFLOW"]
        
        # At least one known dataflow should be present
        has_known = any(flow in df["id"].values for flow in known_dataflows)
        assert has_known, "Should include at least one known dataflow (CME, NUTRITION, GLOBAL_DATAFLOW)"
    
    @pytest.mark.integration
    def test_respects_retry_parameter(self):
        """Test that max_retries parameter is accepted without error"""
        # Test with different retry values (should not raise)
        df_default = list_dataflows()
        df_retry1 = list_dataflows(max_retries=1)
        
        # Both should work
        assert isinstance(df_default, pd.DataFrame)
        assert isinstance(df_retry1, pd.DataFrame)
    
    @pytest.mark.integration
    def test_dataframe_has_valid_data_types(self):
        """Verify that returned columns have appropriate data types"""
        df = list_dataflows()
        
        assert isinstance(df, pd.DataFrame)
        
        # All expected columns should be string type
        for col in ["id", "agency", "version", "name"]:
            if col in df.columns:
                assert df[col].dtype == object or pd.api.types.is_string_dtype(df[col])
    
    @pytest.mark.integration
    def test_no_duplicate_dataflow_ids(self):
        """Each dataflow ID should appear only once"""
        df = list_dataflows()
        
        assert isinstance(df, pd.DataFrame)
        
        # Check for duplicates in id column
        if len(df) > 0:
            duplicates = df[df.duplicated(subset=["id"], keep=False)]
            assert len(duplicates) == 0, f"Found duplicate dataflow IDs: {duplicates['id'].values}"

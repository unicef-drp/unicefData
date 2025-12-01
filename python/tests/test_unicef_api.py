"""
Unit tests for UNICEF API
"""

import pytest
import pandas as pd
from unicef_api import UNICEFSDMXClient
from unicef_api.config import get_dataflow_for_indicator, get_indicator_metadata
from unicef_api.utils import validate_country_codes, validate_year_range


class TestSDMXClient:
    """Tests for UNICEFSDMXClient"""
    
    def test_client_initialization(self):
        """Test client can be initialized"""
        client = UNICEFSDMXClient()
        assert client.base_url == "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
        assert client.agency == "UNICEF"
        assert client.default_dataflow == "GLOBAL_DATAFLOW"
    
    @pytest.mark.skip(reason="Requires API connection")
    def test_fetch_indicator(self):
        """Test fetching a single indicator"""
        client = UNICEFSDMXClient()
        df = client.fetch_indicator(
            'CME_MRY0T4',
            countries=['ALB'],
            start_year=2020,
            end_year=2020
        )
        
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0
        assert 'country_code' in df.columns
        assert 'year' in df.columns
        assert 'value' in df.columns


class TestConfig:
    """Tests for configuration module"""
    
    def test_get_dataflow_for_indicator(self):
        """Test dataflow detection"""
        assert get_dataflow_for_indicator('CME_MRY0T4') == 'CME'
        assert get_dataflow_for_indicator('NT_ANT_HAZ_NE2_MOD') == 'NUTRITION'
        assert get_dataflow_for_indicator('ED_CR_L1_UIS_MOD') == 'EDUCATION_UIS_SDG'
    
    def test_get_indicator_metadata(self):
        """Test metadata retrieval"""
        meta = get_indicator_metadata('CME_MRY0T4')
        assert meta is not None
        assert meta['name'] == 'Under-5 mortality rate'
        assert meta['sdg'] == '3.2.1'


class TestUtils:
    """Tests for utility functions"""
    
    def test_validate_country_codes_valid(self):
        """Test validation of valid country codes"""
        codes = ['USA', 'BRA', 'ALB']
        result = validate_country_codes(codes)
        assert result == codes
    
    def test_validate_country_codes_invalid(self):
        """Test validation of invalid country codes"""
        with pytest.raises(ValueError):
            validate_country_codes(['US'])  # Too short
        
        with pytest.raises(ValueError):
            validate_country_codes(['usa'])  # Not uppercase
    
    def test_validate_year_range_valid(self):
        """Test validation of valid year range"""
        start, end = validate_year_range(2015, 2023)
        assert start == 2015
        assert end == 2023
    
    def test_validate_year_range_invalid(self):
        """Test validation of invalid year range"""
        with pytest.raises(ValueError):
            validate_year_range(2023, 2015)  # Start > End


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

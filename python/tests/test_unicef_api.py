"""
Unit tests for UNICEF API
"""

import pytest
import pandas as pd
from unicefdata import UNICEFSDMXClient
from unicefdata.utils import validate_country_codes, validate_year_range


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


class TestMetadata:
    """Tests for metadata access via client"""
    
    def test_metadata_loaded(self):
        """Test metadata is loaded at initialization"""
        client = UNICEFSDMXClient()
        assert hasattr(client, '_indicators_metadata')
        assert len(client._indicators_metadata) > 0
    
    def test_get_dataflow_for_indicator(self):
        """Test dataflow detection via metadata"""
        client = UNICEFSDMXClient()
        # Note: 'dataflows' field can be string or list
        # Check that expected dataflow is present
        cme_dataflows = client._indicators_metadata['CME_MRY0T4']['dataflows']
        if isinstance(cme_dataflows, list):
            assert 'CME' in cme_dataflows
        else:
            assert cme_dataflows == 'CME'

        nut_dataflows = client._indicators_metadata['NT_ANT_HAZ_NE2_MOD']['dataflows']
        if isinstance(nut_dataflows, list):
            assert 'NUTRITION' in nut_dataflows or 'GLOBAL_DATAFLOW' in nut_dataflows
        else:
            assert nut_dataflows in ['NUTRITION', 'GLOBAL_DATAFLOW']

        ed_dataflows = client._indicators_metadata['ED_CR_L1_UIS_MOD']['dataflows']
        if isinstance(ed_dataflows, list):
            assert 'EDUCATION_UIS_SDG' in ed_dataflows or 'GLOBAL_DATAFLOW' in ed_dataflows
        else:
            assert ed_dataflows in ['EDUCATION_UIS_SDG', 'GLOBAL_DATAFLOW']

    def test_get_indicator_metadata(self):
        """Test metadata retrieval via client"""
        client = UNICEFSDMXClient()
        meta = client._indicators_metadata.get('CME_MRY0T4')
        assert meta is not None
        assert 'dataflows' in meta
        # dataflows can be string or list, check CME is present
        if isinstance(meta['dataflows'], list):
            assert 'CME' in meta['dataflows']
        else:
            assert meta['dataflows'] == 'CME'


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

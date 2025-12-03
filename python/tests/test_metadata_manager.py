import unittest
import pandas as pd
import os
from unicef_api.metadata_manager import MetadataManager

class TestMetadataManager(unittest.TestCase):
    def setUp(self):
        self.manager = MetadataManager()
        
    def test_get_schema(self):
        # Assuming CME.yaml exists from previous steps
        schema = self.manager.get_schema('CME')
        self.assertIsNotNone(schema)
        self.assertEqual(schema['id'], 'CME')
        
    def test_get_column_mapping(self):
        mapping = self.manager.get_column_mapping('CME')
        self.assertIn('REF_AREA', mapping)
        self.assertEqual(mapping['REF_AREA'], 'iso3')
        self.assertIn('TIME_PERIOD', mapping)
        self.assertEqual(mapping['TIME_PERIOD'], 'period')
        
    def test_validate_dataframe(self):
        # Create a dummy dataframe matching CME schema
        data = {
            'REF_AREA': ['AFG'],
            'INDICATOR': ['CME_MRY0T4'],
            'SEX': ['_T'],
            'WEALTH_QUINTILE': ['_T'],
            'TIME_PERIOD': [2020],
            'OBS_VALUE': [50.5]
        }
        df = pd.DataFrame(data)
        self.assertTrue(self.manager.validate_dataframe(df, 'CME'))
        
        # Missing dimension
        df_bad = df.drop(columns=['SEX'])
        self.assertFalse(self.manager.validate_dataframe(df_bad, 'CME'))
        
    def test_standardize_dataframe(self):
        data = {
            'REF_AREA': ['AFG'],
            'INDICATOR': ['CME_MRY0T4'],
            'SEX': ['_T'],
            'WEALTH_QUINTILE': ['_T'],
            'TIME_PERIOD': [2020],
            'OBS_VALUE': [50.5]
        }
        df = pd.DataFrame(data)
        df_std = self.manager.standardize_dataframe(df, 'CME')
        
        self.assertIn('iso3', df_std.columns)
        self.assertIn('period', df_std.columns)
        self.assertNotIn('REF_AREA', df_std.columns)

if __name__ == '__main__':
    unittest.main()

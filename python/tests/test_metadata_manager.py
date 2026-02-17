import unittest
import pandas as pd
import os
from pathlib import Path
from unicefdata.metadata_manager import MetadataManager

# Resolve fixture directory (works from both python/ and repo root)
_THIS_DIR = Path(__file__).resolve().parent          # python/tests/
_REPO_ROOT = _THIS_DIR.parent.parent                 # repo root
_METADATA_FIXTURES = _REPO_ROOT / "tests" / "fixtures" / "python_metadata"


class TestMetadataManager(unittest.TestCase):
    def setUp(self):
        self.manager = MetadataManager(metadata_dir=str(_METADATA_FIXTURES))

    def test_get_schema(self):
        schema = self.manager.get_schema('CME')
        self.assertIsNotNone(schema)
        self.assertIn('dimensions', schema)
        self.assertIn('time_dimension', schema)

    def test_get_column_mapping(self):
        mapping = self.manager.get_column_mapping('CME')
        self.assertIn('REF_AREA', mapping)
        self.assertEqual(mapping['REF_AREA'], 'iso3')
        self.assertIn('TIME_PERIOD', mapping)
        self.assertEqual(mapping['TIME_PERIOD'], 'period')

    def test_validate_dataframe(self):
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

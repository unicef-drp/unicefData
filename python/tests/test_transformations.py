"""
Transformation & Pipeline Tests (TRANS, META, EDGE, DISC families)

Tests post-production transformations (wide format, latest, mrv, add_metadata)
and edge cases using deterministic fixtures. No network access required.

These tests exercise Python's _clean_dataframe, _apply_latest, _apply_mrv,
_apply_format, and related pipeline functions on fixture data.
"""

import pytest
import yaml
import pandas as pd
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
FIXTURES = REPO_ROOT / "tests" / "fixtures" / "deterministic"
METADATA_FIXTURES = REPO_ROOT / "tests" / "fixtures" / "python_metadata"


def load_fixture(name: str) -> pd.DataFrame:
    return pd.read_csv(FIXTURES / name)


# ===========================================================================
# Pipeline: _clean_dataframe column renaming
# ===========================================================================

class TestCleanDataframe:
    """Test that _clean_dataframe renames SDMX columns correctly."""

    def test_column_renaming(self):
        """SDMX columns should be renamed to standard names."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter=None, dropna=False
        )

        assert "iso3" in cleaned.columns, "REF_AREA should become iso3"
        assert "period" in cleaned.columns, "TIME_PERIOD should become period"
        assert "value" in cleaned.columns, "OBS_VALUE should become value"
        assert "indicator" in cleaned.columns, "INDICATOR should become indicator"

    def test_period_numeric(self):
        """Period column should be numeric after cleaning."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2015_2023.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter=None, dropna=False
        )

        assert pd.api.types.is_numeric_dtype(cleaned["period"])

    def test_value_numeric(self):
        """Value column should be numeric after cleaning."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter=None, dropna=False
        )

        assert pd.api.types.is_numeric_dtype(cleaned["value"])

    def test_country_filter(self):
        """Country filter should keep only specified countries."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_BRA_2020.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4",
            countries=["USA"], sex_filter=None, dropna=False
        )

        assert set(cleaned["iso3"].unique()) == {"USA"}

    def test_sex_filter_total(self):
        """Sex filter _T should keep only total rows."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter="_T", dropna=False
        )

        assert (cleaned["sex"] == "_T").all()

    def test_sex_filter_male(self):
        """Sex filter M should keep only male rows."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter="M", dropna=False
        )

        assert (cleaned["sex"] == "M").all()

    def test_geo_type_assigned(self):
        """geo_type should be 0 for country codes."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter=None, dropna=False
        )

        if "geo_type" in cleaned.columns:
            assert (cleaned["geo_type"] == 0).all(), "USA should have geo_type=0"


# ===========================================================================
# TRANS-02: Latest and MRV filters
# ===========================================================================

class TestLatestMRV:
    """Test _apply_latest and _apply_mrv on fixture data."""

    def _make_cleaned_ts(self):
        """Create a cleaned time-series DataFrame for testing."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2015_2023.csv")
        return client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter="_T", dropna=False
        )

    def test_apply_latest(self):
        """_apply_latest keeps only the most recent year."""
        from unicefdata.unicefdata import _apply_latest
        df = self._make_cleaned_ts()
        result = _apply_latest(df)
        assert len(result) == 1, "Latest should return 1 row for single country+indicator"
        assert result["period"].iloc[0] == 2023

    def test_apply_mrv_3(self):
        """_apply_mrv(3) keeps only 3 most recent years."""
        from unicefdata.unicefdata import _apply_mrv
        df = self._make_cleaned_ts()
        result = _apply_mrv(df, 3)
        assert len(result) == 3
        assert set(result["period"]) == {2021, 2022, 2023}


# ===========================================================================
# TRANS-01: Wide format
# ===========================================================================

class TestWideFormat:
    """Test _apply_format for wide transformations."""

    def test_wide_years_as_columns(self):
        """format='wide' should pivot years into columns."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        from unicefdata.unicefdata import _apply_format
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2015_2023.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter="_T", dropna=False
        )
        wide = _apply_format(cleaned, "wide", ["CME_MRY0T4"])

        # Should have year columns (2015, 2016, ... 2023)
        col_names = [str(c) for c in wide.columns]
        assert any("2015" in c for c in col_names), "Should have 2015 column"
        assert any("2023" in c for c in col_names), "Should have 2023 column"
        # Should have 1 row (USA only, single indicator)
        assert len(wide) == 1

    def test_wide_indicators(self):
        """format='wide_indicators' should pivot indicators into columns."""
        from unicefdata.sdmx_client import UNICEFSDMXClient
        from unicefdata.unicefdata import _apply_format
        client = UNICEFSDMXClient()

        df = load_fixture("CME_multi_USA_2020.csv")
        cleaned = client._clean_dataframe(
            df, indicator_code="CME_MRY0T4", sex_filter="_T", dropna=False
        )
        wide = _apply_format(cleaned, "wide_indicators", cleaned["indicator"].unique().tolist())

        # Should have indicator names as columns
        assert "iso3" in wide.columns


# ===========================================================================
# EDGE-02: Single-observation stability
# ===========================================================================

class TestSingleObservation:
    """Pipeline should work correctly with N=1."""

    def test_single_row_processing(self):
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        # Filter to single row
        single = df[(df["SEX"] == "_T")].copy()
        assert len(single) == 1

        cleaned = client._clean_dataframe(
            single, indicator_code="CME_MRY0T4", sex_filter=None, dropna=False
        )
        assert len(cleaned) == 1
        assert "iso3" in cleaned.columns


# ===========================================================================
# EDGE-03: Special characters in country names
# ===========================================================================

class TestSpecialCharacters:
    """Country names with special characters should be preserved."""

    def test_country_name_with_comma(self):
        """'Deaths per 1,000 live births' contains comma — should parse correctly."""
        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        # The unit_name column contains commas in quotes
        if "Unit of measure" in df.columns:
            unit = df["Unit of measure"].iloc[0]
            assert "1,000" in unit or "1000" in unit


# ===========================================================================
# EXT-06 / EDGE: Zero-observation result
# ===========================================================================

class TestZeroObservation:
    """Empty DataFrames should flow through pipeline without errors."""

    def test_empty_dataframe(self):
        from unicefdata.sdmx_client import UNICEFSDMXClient
        client = UNICEFSDMXClient()

        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        empty = df[df["REF_AREA"] == "NONEXISTENT"].copy()
        assert len(empty) == 0

        cleaned = client._clean_dataframe(
            empty, indicator_code="CME_MRY0T4", sex_filter=None, dropna=False
        )
        assert len(cleaned) == 0
        assert isinstance(cleaned, pd.DataFrame)


# ===========================================================================
# DISC: Discovery functions (offline metadata)
# ===========================================================================

class TestDiscovery:
    """Test indicator search and metadata lookup without network."""

    def test_get_dataflow_for_known_indicator(self):
        """CME_MRY0T4 should resolve to a dataflow (CME or GLOBAL_DATAFLOW)."""
        from unicefdata.indicator_registry import get_dataflow_for_indicator
        result = get_dataflow_for_indicator("CME_MRY0T4")
        assert result is not None, "CME_MRY0T4 should resolve to a dataflow"
        assert isinstance(result, str)

    def test_get_indicator_info(self):
        """get_indicator_info should return metadata dict."""
        import unicefdata.indicator_registry as reg

        # Pre-seed the module cache from fixture so no API call is needed
        if not reg._cache_loaded or not reg._indicator_cache:
            cache_file = METADATA_FIXTURES / "unicef_indicators_metadata.yaml"
            if cache_file.exists():
                with open(cache_file, 'r', encoding='utf-8') as f:
                    data = yaml.safe_load(f)
                reg._indicator_cache = data.get('indicators', {})
                reg._cache_loaded = True

        info = reg.get_indicator_info("CME_MRY0T4")
        assert info is not None
        assert isinstance(info, dict)

    def test_search_indicators_mortality(self):
        """search_indicators('mortality') should execute without error."""
        try:
            from unicefdata import search_indicators
            # Some implementations print to stdout and return None
            result = search_indicators("mortality")
            # Either returns data or prints — both acceptable
        except ImportError:
            pytest.skip("search_indicators not available")


# ===========================================================================
# TIER: Tier metadata (offline)
# ===========================================================================

class TestTierMetadata:
    """Test tier classification in indicator metadata."""

    def test_indicator_has_tier(self):
        """CME_MRY0T4 should have tier metadata."""
        from unicefdata.indicator_registry import get_indicator_info
        info = get_indicator_info("CME_MRY0T4")
        if info and "tier" in info:
            assert info["tier"] in (1, 2, 3, 999)

    def test_tier_one_has_dataflow(self):
        """Tier 1 indicators should have a mapped dataflow."""
        from unicefdata.indicator_registry import get_indicator_info
        info = get_indicator_info("CME_MRY0T4")
        if info and info.get("tier") == 1:
            assert "dataflows" in info or "dataflow" in info

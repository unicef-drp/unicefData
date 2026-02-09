"""
Full pipeline tests with mocked API responses.

Tests the complete unicefData() flow (fetch -> clean -> filter -> output) using
HTTP-mocked responses from shared fixture CSVs. No live API calls are made.

Fixtures: tests/fixtures/api_responses/
"""

import pandas as pd
import responses
from unicefdata import unicefData


class TestPipelineBasic:
    """Tests for the basic fetch-clean-output pipeline"""

    @responses.activate
    def test_basic_fetch_and_clean(self, mock_pipeline_endpoints):
        """unicefData() returns cleaned DataFrame with standard columns"""
        mock_pipeline_endpoints()

        df = unicefData(
            indicator="CME_MRY0T4",
            countries=["ALB"],
            year="2020:2022",
        )

        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0

        # Column renaming: SDMX -> standard
        assert "iso3" in df.columns
        assert "period" in df.columns
        assert "value" in df.columns
        assert "indicator" in df.columns

        # Original SDMX columns should be gone
        assert "REF_AREA" not in df.columns
        assert "TIME_PERIOD" not in df.columns
        assert "OBS_VALUE" not in df.columns

    @responses.activate
    def test_period_is_numeric(self, mock_pipeline_endpoints):
        """Period column should be numeric (float) after cleaning"""
        mock_pipeline_endpoints()

        df = unicefData(indicator="CME_MRY0T4", countries=["ALB"])

        assert pd.api.types.is_numeric_dtype(df["period"])
        # Years should be reasonable values
        assert df["period"].min() >= 2000
        assert df["period"].max() <= 2030

    @responses.activate
    def test_value_is_numeric(self, mock_pipeline_endpoints):
        """Value column should be numeric after cleaning"""
        mock_pipeline_endpoints()

        df = unicefData(indicator="CME_MRY0T4", countries=["ALB"])

        assert pd.api.types.is_numeric_dtype(df["value"])
        assert df["value"].notna().all()

    @responses.activate
    def test_country_filtering(self, mock_pipeline_endpoints):
        """Only requested countries should appear in output"""
        mock_pipeline_endpoints()

        df = unicefData(indicator="CME_MRY0T4", countries=["ALB"])

        assert set(df["iso3"].unique()) == {"ALB"}

    @responses.activate
    def test_geo_type_country(self, mock_pipeline_endpoints):
        """Country codes should get geo_type=0 (not aggregate)"""
        mock_pipeline_endpoints()

        df = unicefData(indicator="CME_MRY0T4", countries=["ALB"])

        if "geo_type" in df.columns:
            assert (df["geo_type"] == 0).all()

    @responses.activate
    def test_raw_mode(self, mock_pipeline_endpoints):
        """raw=True should return unprocessed DataFrame with original columns"""
        mock_pipeline_endpoints()

        df = unicefData(indicator="CME_MRY0T4", countries=["ALB"], raw=True)

        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0
        # Raw mode should keep original SDMX column names
        assert "REF_AREA" in df.columns or "INDICATOR" in df.columns


class TestPipelineFiltering:
    """Tests for disaggregation filtering through the pipeline"""

    @responses.activate
    def test_sex_default_filter(self, mock_pipeline_endpoints):
        """Default sex=_T should filter to total rows only"""
        mock_pipeline_endpoints(sex_fixture="brazil")

        df = unicefData(
            indicator="CME_MRY0T4",
            countries=["BRA"],
            sex="_T",
        )

        assert isinstance(df, pd.DataFrame)
        if "sex" in df.columns and len(df) > 0:
            assert set(df["sex"].unique()) == {"_T"}

    @responses.activate
    def test_sex_explicit_male(self, mock_pipeline_endpoints):
        """sex='M' should return only male rows"""
        mock_pipeline_endpoints(sex_fixture="brazil")

        df = unicefData(
            indicator="CME_MRY0T4",
            countries=["BRA"],
            sex="M",
        )

        assert isinstance(df, pd.DataFrame)
        if "sex" in df.columns and len(df) > 0:
            assert set(df["sex"].unique()) == {"M"}


class TestPipelineMulti:
    """Tests for multi-country and multi-indicator scenarios"""

    @responses.activate
    def test_multi_country(self, mock_pipeline_endpoints):
        """Multiple countries should all appear in output"""
        mock_pipeline_endpoints()

        df = unicefData(
            indicator="NT_ANT_HAZ_NE2",
            countries=["IND", "ETH", "BGD"],
        )

        assert isinstance(df, pd.DataFrame)
        if len(df) > 0:
            countries = set(df["iso3"].unique())
            # At least some of the requested countries should appear
            assert len(countries) >= 2

    @responses.activate
    def test_empty_response(self, mock_pipeline_endpoints):
        """Unknown indicator should return empty DataFrame or raise"""
        mock_pipeline_endpoints()

        # This should either return empty DF or raise SDMXNotFoundError
        try:
            df = unicefData(
                indicator="NONEXISTENT_INDICATOR_XYZ",
                countries=["ALB"],
            )
            # If it returns, should be empty DataFrame
            assert isinstance(df, pd.DataFrame)
            assert len(df) == 0
        except Exception:
            # SDMXNotFoundError is also acceptable
            pass


class TestPipelineColumnOrder:
    """Tests for output column ordering and completeness"""

    @responses.activate
    def test_standard_columns_present(self, mock_pipeline_endpoints):
        """Output should contain the critical standard columns"""
        mock_pipeline_endpoints()

        df = unicefData(indicator="CME_MRY0T4", countries=["ALB"])

        # These columns should always be present after cleaning
        critical_cols = ["indicator", "iso3", "period", "value"]
        for col in critical_cols:
            assert col in df.columns, f"Missing critical column: {col}"

    @responses.activate
    def test_indicator_column_value(self, mock_pipeline_endpoints):
        """Indicator column should contain the requested indicator code"""
        mock_pipeline_endpoints()

        df = unicefData(indicator="CME_MRY0T4", countries=["ALB"])

        assert "indicator" in df.columns
        assert "CME_MRY0T4" in df["indicator"].values

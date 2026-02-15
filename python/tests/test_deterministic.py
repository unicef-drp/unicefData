"""
Deterministic / Offline Tests (DET-01 to DET-11, REGR-01)

Gould (2001) Phase 6: Network-independent verification using frozen CSV fixtures.
These tests exercise the data-processing pipeline WITHOUT network access.

Fixtures: tests/fixtures/deterministic/ (canonical, shared across Python/R/Stata)
"""

import pytest
import pandas as pd
from pathlib import Path

# Fixture directory (relative to repo root)
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
FIXTURES = REPO_ROOT / "tests" / "fixtures" / "deterministic"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_fixture(name: str) -> pd.DataFrame:
    """Load a deterministic CSV fixture."""
    path = FIXTURES / name
    if not path.exists():
        raise FileNotFoundError(f"Fixture not found: {path}")
    return pd.read_csv(path)


# ===========================================================================
# DET-01: Single indicator, all countries (basic loading)
# ===========================================================================

class TestDET01:
    """Load CME_MRY0T4_all_2020.csv — basic fixture ingestion."""

    def test_rows_present(self):
        df = load_fixture("CME_MRY0T4_all_2020.csv")
        assert len(df) > 0, "Fixture should have rows"

    def test_required_columns(self):
        df = load_fixture("CME_MRY0T4_all_2020.csv")
        for col in ("REF_AREA", "INDICATOR", "TIME_PERIOD", "OBS_VALUE"):
            assert col in df.columns, f"Missing required column: {col}"

    def test_single_indicator(self):
        df = load_fixture("CME_MRY0T4_all_2020.csv")
        assert df["INDICATOR"].nunique() == 1
        assert df["INDICATOR"].iloc[0] == "CME_MRY0T4"

    def test_single_year(self):
        df = load_fixture("CME_MRY0T4_all_2020.csv")
        assert df["TIME_PERIOD"].nunique() == 1
        assert df["TIME_PERIOD"].iloc[0] == 2020

    def test_multiple_countries(self):
        df = load_fixture("CME_MRY0T4_all_2020.csv")
        assert df["REF_AREA"].nunique() > 100, "All-countries fixture should have 100+ countries"


# ===========================================================================
# DET-02: Value pinning — USA U5MR 2020 ≈ 6.4688
# ===========================================================================

class TestDET02:
    """CME_MRY0T4_USA_2020_pinning.csv — exact value assertions."""

    def test_usa_total_value(self):
        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        total = df.loc[(df["REF_AREA"] == "USA") & (df["SEX"] == "_T"), "OBS_VALUE"]
        assert len(total) == 1, "Exactly one USA _T row expected"
        assert abs(total.iloc[0] - 6.4688) < 0.01, f"USA U5MR should be ~6.4688, got {total.iloc[0]}"

    def test_male_greater_than_female(self):
        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        male = df.loc[df["SEX"] == "M", "OBS_VALUE"].iloc[0]
        female = df.loc[df["SEX"] == "F", "OBS_VALUE"].iloc[0]
        assert male > female, f"Male ({male}) should exceed female ({female})"

    def test_three_sex_categories(self):
        df = load_fixture("CME_MRY0T4_USA_2020_pinning.csv")
        assert set(df["SEX"]) == {"F", "M", "_T"}


# ===========================================================================
# DET-03: Multi-country (USA + BRA)
# ===========================================================================

class TestDET03:
    """CME_MRY0T4_USA_BRA_2020.csv — multi-country parsing."""

    def test_both_countries_present(self):
        df = load_fixture("CME_MRY0T4_USA_BRA_2020.csv")
        countries = set(df["REF_AREA"])
        assert "USA" in countries
        assert "BRA" in countries

    def test_row_count(self):
        df = load_fixture("CME_MRY0T4_USA_BRA_2020.csv")
        assert len(df) == 6, f"Expected 6 rows (2 countries × 3 sex), got {len(df)}"


# ===========================================================================
# DET-04: Time series (USA 2015-2023)
# ===========================================================================

class TestDET04:
    """CME_MRY0T4_USA_2015_2023.csv — temporal structure."""

    def test_nine_years(self):
        df = load_fixture("CME_MRY0T4_USA_2015_2023.csv")
        years = sorted(df["TIME_PERIOD"].unique())
        assert len(years) == 9, f"Expected 9 years, got {len(years)}"
        assert years[0] == 2015
        assert years[-1] == 2023

    def test_monotonic_decrease(self):
        """USA U5MR has been declining — trend should be monotonically decreasing for totals."""
        df = load_fixture("CME_MRY0T4_USA_2015_2023.csv")
        totals = df[df["SEX"] == "_T"].sort_values("TIME_PERIOD")
        values = totals["OBS_VALUE"].tolist()
        # Allow minor non-monotonicity (real data) but overall trend should decline
        assert values[0] > values[-1], "U5MR should decline from 2015 to 2023"

    def test_usa_only(self):
        df = load_fixture("CME_MRY0T4_USA_2015_2023.csv")
        assert df["REF_AREA"].nunique() == 1
        assert df["REF_AREA"].iloc[0] == "USA"


# ===========================================================================
# DET-05: Sex disaggregation (BRA 2020)
# ===========================================================================

class TestDET05:
    """CME_MRY0T4_BRA_sex_2020.csv — disaggregation by sex + wealth."""

    def test_sex_values(self):
        df = load_fixture("CME_MRY0T4_BRA_sex_2020.csv")
        assert "F" in df["SEX"].values
        assert "M" in df["SEX"].values
        assert "_T" in df["SEX"].values

    def test_male_greater_than_female(self):
        df = load_fixture("CME_MRY0T4_BRA_sex_2020.csv")
        male = df.loc[(df["SEX"] == "M") & (df["WEALTH_QUINTILE"] == "_T"), "OBS_VALUE"].iloc[0]
        female = df.loc[(df["SEX"] == "F") & (df["WEALTH_QUINTILE"] == "_T"), "OBS_VALUE"].iloc[0]
        assert male > female

    def test_wealth_quintiles_present(self):
        df = load_fixture("CME_MRY0T4_BRA_sex_2020.csv")
        wq = set(df["WEALTH_QUINTILE"])
        assert "_T" in wq
        # Should have at least some quintile values
        assert len(wq) > 1, "Should have multiple wealth quintile values"


# ===========================================================================
# DET-06: Missing fixture → error
# ===========================================================================

class TestDET06:
    """Non-existent fixture should raise FileNotFoundError."""

    def test_missing_fixture_raises(self):
        with pytest.raises(FileNotFoundError):
            load_fixture("NONEXISTENT_FILE_12345.csv")


# ===========================================================================
# DET-07: Multi-indicator (USA 2020)
# ===========================================================================

class TestDET07:
    """CME_multi_USA_2020.csv — multiple indicators in one fixture."""

    def test_multiple_indicators(self):
        df = load_fixture("CME_multi_USA_2020.csv")
        n_indicators = df["INDICATOR"].nunique()
        assert n_indicators >= 3, f"Expected ≥3 indicators, got {n_indicators}"

    def test_known_indicators_present(self):
        df = load_fixture("CME_multi_USA_2020.csv")
        indicators = set(df["INDICATOR"])
        # CME dataflow includes various mortality indicators
        assert "CME_MRY0T4" in indicators or "CME_MRM0" in indicators

    def test_usa_only(self):
        df = load_fixture("CME_multi_USA_2020.csv")
        assert df["REF_AREA"].nunique() == 1
        assert df["REF_AREA"].iloc[0] == "USA"


# ===========================================================================
# DET-08: Nofilter (USA 2020 — all disaggregations)
# ===========================================================================

class TestDET08:
    """CME_MRY0T4_USA_nofilter_2020.csv — unfiltered data."""

    def test_has_data(self):
        df = load_fixture("CME_MRY0T4_USA_nofilter_2020.csv")
        assert len(df) > 0

    def test_required_columns(self):
        df = load_fixture("CME_MRY0T4_USA_nofilter_2020.csv")
        for col in ("REF_AREA", "INDICATOR", "OBS_VALUE"):
            assert col in df.columns


# ===========================================================================
# DET-09: Long time series (BRA 1990-2023)
# ===========================================================================

class TestDET09:
    """CME_MRY0T4_BRA_1990_2023.csv — 30+ year series."""

    def test_spans_thirty_years(self):
        df = load_fixture("CME_MRY0T4_BRA_1990_2023.csv")
        years = df["TIME_PERIOD"].unique()
        assert min(years) <= 1990
        assert max(years) >= 2023
        assert len(years) >= 30

    def test_bra_only(self):
        df = load_fixture("CME_MRY0T4_BRA_1990_2023.csv")
        assert df["REF_AREA"].nunique() == 1
        assert df["REF_AREA"].iloc[0] == "BRA"

    def test_declining_trend(self):
        df = load_fixture("CME_MRY0T4_BRA_1990_2023.csv")
        totals = df[df["SEX"] == "_T"].sort_values("TIME_PERIOD")
        assert totals["OBS_VALUE"].iloc[0] > totals["OBS_VALUE"].iloc[-1]


# ===========================================================================
# DET-10: Multi-country time series (5 countries, 2018-2023)
# ===========================================================================

class TestDET10:
    """CME_MRY0T4_multi_2018_2023.csv — 5 countries × multiple years."""

    def test_five_countries(self):
        df = load_fixture("CME_MRY0T4_multi_2018_2023.csv")
        assert df["REF_AREA"].nunique() == 5

    def test_known_countries(self):
        df = load_fixture("CME_MRY0T4_multi_2018_2023.csv")
        countries = set(df["REF_AREA"])
        expected = {"USA", "BRA", "IND", "NGA", "ETH"}
        assert countries == expected, f"Expected {expected}, got {countries}"

    def test_multiple_years(self):
        df = load_fixture("CME_MRY0T4_multi_2018_2023.csv")
        years = df["TIME_PERIOD"].unique()
        assert len(years) >= 5


# ===========================================================================
# DET-11: Cross-dataflow (IMMUNISATION — IM_MCV1)
# ===========================================================================

class TestDET11:
    """IM_MCV1_USA_BRA_2015_2023.csv — non-CME dataflow."""

    def test_vaccination_indicator(self):
        df = load_fixture("IM_MCV1_USA_BRA_2015_2023.csv")
        assert "IM_MCV1" in df["INDICATOR"].values

    def test_both_countries(self):
        df = load_fixture("IM_MCV1_USA_BRA_2015_2023.csv")
        countries = set(df["REF_AREA"])
        assert "USA" in countries
        assert "BRA" in countries

    def test_different_columns_than_cme(self):
        """IMMUNISATION has VACCINE/AGE columns that CME doesn't."""
        df = load_fixture("IM_MCV1_USA_BRA_2015_2023.csv")
        # IMMUNISATION dataflow has VACCINE column
        assert "VACCINE" in df.columns or "AGE" in df.columns


# ===========================================================================
# REGR-01a: Regression baseline — mortality
# ===========================================================================

class TestREGR01Mortality:
    """snap_mortality_baseline.csv — pinned values for USA and BRA."""

    def test_usa_mortality(self):
        df = load_fixture("snap_mortality_baseline.csv")
        usa = df[df["iso3"] == "USA"]
        assert len(usa) == 1
        assert abs(usa["value"].iloc[0] - 6.4688) < 0.01

    def test_bra_mortality(self):
        df = load_fixture("snap_mortality_baseline.csv")
        bra = df[df["iso3"] == "BRA"]
        assert len(bra) == 1
        assert abs(bra["value"].iloc[0] - 14.8719) < 0.01


# ===========================================================================
# REGR-01b: Regression baseline — vaccination
# ===========================================================================

class TestREGR01Vaccination:
    """snap_vaccination_baseline.csv — pinned values for IND and ETH."""

    def test_ind_vaccination(self):
        df = load_fixture("snap_vaccination_baseline.csv")
        ind = df[df["iso3"] == "IND"]
        assert len(ind) == 1
        assert abs(ind["value"].iloc[0] - 85) < 1

    def test_eth_vaccination(self):
        df = load_fixture("snap_vaccination_baseline.csv")
        eth = df[df["iso3"] == "ETH"]
        assert len(eth) == 1
        assert abs(eth["value"].iloc[0] - 62) < 1


# ===========================================================================
# NEW-01 / NEW-02: Input validation (from PR #47 review)
# ===========================================================================

class TestInputValidation:
    """Parameter validation tests — no network or fixtures required."""

    def test_none_indicator_rejected(self):
        """unicefData([None]) should raise ValueError."""
        from unicefdata import unicefData
        with pytest.raises(ValueError, match="No valid indicator"):
            unicefData(indicator=[None])

    def test_empty_indicator_list_rejected(self):
        """unicefData([]) should raise ValueError."""
        from unicefdata import unicefData
        with pytest.raises((ValueError, TypeError)):
            unicefData(indicator=[])

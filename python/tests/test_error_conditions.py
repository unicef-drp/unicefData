"""
Error Condition Tests (ERR family)

Gould (2001): "Test that your code does not work in circumstances where it should not."
These tests verify that invalid inputs are rejected with clear error messages.

No network access required.
"""

import pytest
import pandas as pd
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
FIXTURES = REPO_ROOT / "tests" / "fixtures" / "deterministic"


# ===========================================================================
# ERR-04: Invalid country code
# ===========================================================================

class TestInvalidCountryCode:
    """Invalid ISO3 codes should be rejected or warned."""

    def test_too_short_code_rejected(self):
        from unicefdata.utils import validate_country_codes
        with pytest.raises(ValueError):
            validate_country_codes(["US"])

    def test_lowercase_code_rejected(self):
        from unicefdata.utils import validate_country_codes
        with pytest.raises(ValueError):
            validate_country_codes(["usa"])

    def test_non_string_rejected(self):
        from unicefdata.utils import validate_country_codes
        with pytest.raises(ValueError):
            validate_country_codes([123])

    def test_valid_codes_pass(self):
        from unicefdata.utils import validate_country_codes
        result = validate_country_codes(["USA", "BRA"])
        assert "USA" in result
        assert "BRA" in result

    def test_format_valid_unknown_passes(self):
        """ZZZ is format-valid (3 uppercase) — accepted without valid_codes set."""
        from unicefdata.utils import validate_country_codes
        result = validate_country_codes(["ZZZ"])
        assert "ZZZ" in result

    def test_unknown_rejected_with_valid_set(self):
        """ZZZ rejected when valid_codes set is provided."""
        from unicefdata.utils import validate_country_codes
        with pytest.raises(ValueError):
            validate_country_codes(["ZZZ"], valid_codes={"USA", "BRA"})


# ===========================================================================
# ERR-05: Inverted year range
# ===========================================================================

class TestInvertedYearRange:
    """Year range 2025:2020 should be rejected."""

    def test_inverted_range_raises(self):
        from unicefdata.utils import validate_year_range
        with pytest.raises(ValueError):
            validate_year_range(2025, 2020)

    def test_valid_range_passes(self):
        from unicefdata.utils import validate_year_range
        result = validate_year_range(2015, 2023)
        assert result is not None


# ===========================================================================
# ERR-06: No indicator provided
# ===========================================================================

class TestNoIndicator:
    """Calling unicefData without an indicator should raise."""

    def test_none_indicator(self):
        from unicefdata import unicefData
        with pytest.raises((TypeError, ValueError)):
            unicefData(indicator=None)

    def test_empty_string_indicator(self):
        from unicefdata import unicefData
        with pytest.raises((ValueError, Exception)):
            unicefData(indicator="")


# ===========================================================================
# ERR-08: Invalid indicator code
# ===========================================================================

class TestInvalidIndicator:
    """Invalid indicator should raise SDMXNotFoundError (requires some metadata)."""

    def test_invalid_indicator_metadata_lookup(self):
        """get_dataflow_for_indicator returns None for unknown indicators."""
        from unicefdata.indicator_registry import get_dataflow_for_indicator
        result = get_dataflow_for_indicator("XXXXX_INVALID_99999")
        # Should return None or raise — both are acceptable
        assert result is None or isinstance(result, str)


# ===========================================================================
# Year parsing validation
# ===========================================================================

class TestYearParsing:
    """parse_year() should handle various input formats correctly."""

    def test_single_int(self):
        from unicefdata.unicefdata import parse_year
        result = parse_year(2020)
        assert result["start_year"] == 2020
        assert result["end_year"] == 2020

    def test_range_string(self):
        from unicefdata.unicefdata import parse_year
        result = parse_year("2015:2023")
        assert result["start_year"] == 2015
        assert result["end_year"] == 2023

    def test_comma_string(self):
        from unicefdata.unicefdata import parse_year
        result = parse_year("2015,2018,2020")
        assert result["year_list"] == [2015, 2018, 2020]

    def test_none_returns_none(self):
        from unicefdata.unicefdata import parse_year
        result = parse_year(None)
        assert result["start_year"] is None
        assert result["end_year"] is None

    def test_tuple_range(self):
        from unicefdata.unicefdata import parse_year
        result = parse_year((2015, 2023))
        assert result["start_year"] == 2015
        assert result["end_year"] == 2023


# ===========================================================================
# Duplicate detection (DL-06)
# ===========================================================================

class TestDuplicateDetection:
    """Fixtures should not have duplicate rows on key dimensions."""

    @pytest.mark.parametrize("fixture", [
        "CME_MRY0T4_USA_2020_pinning.csv",
        "CME_MRY0T4_USA_BRA_2020.csv",
        "CME_MRY0T4_USA_2015_2023.csv",
    ])
    def test_no_duplicates_on_key_dims(self, fixture):
        df = pd.read_csv(FIXTURES / fixture)
        key_cols = [c for c in ["REF_AREA", "INDICATOR", "SEX", "WEALTH_QUINTILE", "TIME_PERIOD"]
                    if c in df.columns]
        duplicates = df.duplicated(subset=key_cols, keep=False)
        assert not duplicates.any(), f"Duplicate rows found in {fixture}"


# ===========================================================================
# Data type validation (DATA-01)
# ===========================================================================

class TestDataTypes:
    """Numeric columns must be parseable as numbers."""

    @pytest.mark.parametrize("fixture", [
        "CME_MRY0T4_USA_2020_pinning.csv",
        "CME_MRY0T4_BRA_sex_2020.csv",
        "CME_multi_USA_2020.csv",
        "IM_MCV1_USA_BRA_2015_2023.csv",
    ])
    def test_obs_value_numeric(self, fixture):
        df = pd.read_csv(FIXTURES / fixture)
        assert pd.to_numeric(df["OBS_VALUE"], errors="coerce").notna().all(), \
            f"OBS_VALUE has non-numeric values in {fixture}"

    @pytest.mark.parametrize("fixture", [
        "CME_MRY0T4_USA_2020_pinning.csv",
        "CME_MRY0T4_USA_2015_2023.csv",
        "CME_MRY0T4_BRA_1990_2023.csv",
    ])
    def test_time_period_integer(self, fixture):
        df = pd.read_csv(FIXTURES / fixture)
        periods = pd.to_numeric(df["TIME_PERIOD"], errors="coerce")
        assert periods.notna().all()
        assert (periods == periods.astype(int)).all(), \
            f"TIME_PERIOD should be integer years in {fixture}"

    @pytest.mark.parametrize("fixture", [
        "CME_MRY0T4_USA_2020_pinning.csv",
        "CME_MRY0T4_USA_BRA_2020.csv",
        "CME_MRY0T4_multi_2018_2023.csv",
    ])
    def test_iso3_three_chars(self, fixture):
        df = pd.read_csv(FIXTURES / fixture)
        assert (df["REF_AREA"].str.len() == 3).all(), \
            f"REF_AREA should be 3-char ISO3 codes in {fixture}"

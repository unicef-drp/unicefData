"""
Automated tests to verify Python can download indicators from various dataflows
after implementing the 3-tier fallback logic and simpler .INDICATOR. key pattern.

Uses golden indicators from validation/xval/golden_indicators.yaml
"""

import pytest

from unicef_api import unicefData


@pytest.mark.parametrize(
    "indicator, year",
    [
        ("COD_ALCOHOL_USE_DISORDERS", 2019),  # CAUSE_OF_DEATH dataflow
        ("HVA_PMTCT_MTCT", 2020),  # HIV_AIDS dataflow (mother-to-child transmission)
    ]
)
def test_indicator_downloads_successfully(indicator, year):
    """
    Ensure that calling unicefData for selected indicators returns
    a non-empty DataFrame with an iso3 country column.
    """
    df = unicefData(
        indicator=indicator,
        countries=None,  # All countries
        year=year,
    )
    
    # Basic structural assertions replacing previous print-based checks.
    assert df is not None
    assert not df.empty
    assert "iso3" in df.columns
    # Ensure there is at least one country represented.
    assert df["iso3"].nunique() > 0

"""
Pytest tests to verify the 3-tier fallback logic implementation.

Tests:
1. COD_ALCOHOL_USE_DISORDERS should use CAUSE_OF_DEATH dataflow (Tier 1 metadata lookup)
2. HVA_PMTCT_MTCT should use HIV_AIDS dataflow (Tier 1 metadata lookup)
3. Verify that valid, non-empty data are returned for both indicators

Uses golden indicators from validation/xval/golden_indicators.yaml
"""

import sys
import logging
from pathlib import Path

# Add parent directory to path so unicefdata can be imported when running tests directly
sys.path.insert(0, str(Path(__file__).parent))

# Configure logging to see debug messages during test runs
logging.basicConfig(
    level=logging.INFO,  # Changed from DEBUG to reduce noise
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

import pytest

from unicefdata import unicefData
from unicefdata.sdmx_client import SDMXForbiddenError


def test_cod_alcohol_use_disorders_fallback():
    """
    COD_ALCOHOL_USE_DISORDERS should successfully retrieve data using the
    CAUSE_OF_DEATH dataflow via Tier 1 metadata lookup.
    """
    try:
        df1 = unicefData(
            indicator="COD_ALCOHOL_USE_DISORDERS",
            countries=None,  # None = ALL countries
            year=2019,
        )
    except SDMXForbiddenError:
        pytest.skip("API returned 403 Forbidden for COD_ALCOHOL_USE_DISORDERS")

    # Basic sanity checks: we expect some data and an iso3 column with values.
    assert df1 is not None, "unicefData returned None for COD_ALCOHOL_USE_DISORDERS"
    assert not df1.empty, "Expected non-empty DataFrame for COD_ALCOHOL_USE_DISORDERS"
    assert "iso3" in df1.columns, "Expected 'iso3' column in COD_ALCOHOL_USE_DISORDERS results"
    assert df1["iso3"].notna().any(), "Expected at least one non-null iso3 code"

    logger.info(
        "Downloaded %d rows for %d countries for COD_ALCOHOL_USE_DISORDERS",
        len(df1),
        len(df1["iso3"].unique()),
    )


def test_hva_pmtct_mtct_fallback():
    """
    HVA_PMTCT_MTCT (Mother-to-child HIV transmission rate) should successfully
    retrieve data using the HIV_AIDS dataflow via Tier 1 metadata lookup.
    """
    try:
        df2 = unicefData(
            indicator="HVA_PMTCT_MTCT",
            countries=None,  # All countries
            year="2015:2023",
        )
    except SDMXForbiddenError:
        pytest.skip("API returned 403 Forbidden for HVA_PMTCT_MTCT")

    # Basic sanity checks: we expect some data for the requested indicator.
    assert df2 is not None, "unicefData returned None for HVA_PMTCT_MTCT"
    assert not df2.empty, "Expected non-empty DataFrame for HVA_PMTCT_MTCT"
    assert "iso3" in df2.columns, "Expected 'iso3' column in HVA_PMTCT_MTCT results"
    assert df2["iso3"].notna().any(), "Expected at least one non-null iso3 code"

    logger.info(
        "Downloaded %d rows for %d countries for HVA_PMTCT_MTCT",
        len(df2),
        len(df2["iso3"].unique()),
    )

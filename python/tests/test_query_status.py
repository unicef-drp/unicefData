"""Tests for query status codes on empty results.

Verifies that unicefData() sets df.attrs["query_status"] correctly.
All tests use mocked HTTP responses — no network calls.

See docs/QUERY_STATUS_CODES.md for the full spec.
"""

import re
import pytest
import responses

import unicefdata.unicefdata as _umod
from unicefdata import unicefData
from unicefdata.sdmx_client import SDMXNotFoundError


BASE_URL = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data"
SDMX_ANY = re.compile(r"https://sdmx\.data\.unicef\.org/.*")

MNCH_BRA_CSV = (
    "DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS,DATA_SOURCE\n"
    "MNCH,BRA,MNCH_CSEC,_T,2015,55.5,PCT,AVAILABLE,SURVEY\n"
    "MNCH,BRA,MNCH_CSEC,_T,2016,55.6,PCT,AVAILABLE,SURVEY\n"
    "MNCH,BRA,MNCH_CSEC,_T,2017,55.8,PCT,AVAILABLE,SURVEY\n"
    "MNCH,BRA,MNCH_CSEC,_T,2018,56.1,PCT,AVAILABLE,SURVEY\n"
    "MNCH,BRA,MNCH_CSEC,_T,2019,56.4,PCT,AVAILABLE,SURVEY\n"
)

MNCH_BRA_GAP_CSV = (
    "DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS,DATA_SOURCE\n"
    "MNCH,BRA,MNCH_CSEC,_T,2015,55.5,PCT,AVAILABLE,SURVEY\n"
    "MNCH,BRA,MNCH_CSEC,_T,2019,56.4,PCT,AVAILABLE,SURVEY\n"
)

MNCH_ARG_CSV = (
    "DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS,DATA_SOURCE\n"
    "MNCH,ARG,MNCH_CSEC,_T,2020,32.1,PCT,AVAILABLE,SURVEY\n"
)


class _FakeSync:
    def ensure_synced(self, **kwargs):
        return False


def _reset():
    """Reset module state and disable metadata sync before each test."""
    _umod._client = None
    _umod.MetadataSync = _FakeSync


def _mock(csv_body, url_pattern=None):
    """Register mocked response + catch-all 404."""
    if url_pattern and csv_body:
        responses.add(responses.GET, url_pattern, body=csv_body, status=200, content_type="text/csv")
    responses.add(responses.GET, SDMX_ANY, body="Not Found", status=404)


MNCH_PATTERN = re.compile(rf"{re.escape(BASE_URL)}/UNICEF,MNCH.*MNCH_CSEC.*")


@responses.activate
def test_ok():
    _reset()
    _mock(MNCH_BRA_CSV, MNCH_PATTERN)
    df = unicefData(indicator="MNCH_CSEC", countries=["BRA"], dataflow="MNCH")
    assert len(df) > 0
    assert df.attrs.get("query_status") == "ok"


@responses.activate
def test_year_not_found_gap():
    _reset()
    _mock(MNCH_BRA_GAP_CSV, MNCH_PATTERN)
    df = unicefData(indicator="MNCH_CSEC", countries=["BRA"], year=2017, dataflow="MNCH")
    assert len(df) == 0
    assert df.attrs["query_status"] == "year_not_found"
    assert 2015 in df.attrs["available_years"]
    assert 2019 in df.attrs["available_years"]
    assert df.attrs["nearest_year"] in (2015, 2019)


@responses.activate
def test_year_beyond_range_future():
    _reset()
    _mock(MNCH_BRA_CSV, MNCH_PATTERN)
    df = unicefData(indicator="MNCH_CSEC", countries=["BRA"], year=2025, dataflow="MNCH")
    assert len(df) == 0
    assert df.attrs["query_status"] == "year_beyond_range"
    assert df.attrs["nearest_year"] == 2019
    assert "outside" in df.attrs["message"].lower()


@responses.activate
def test_year_beyond_range_past():
    _reset()
    _mock(MNCH_BRA_CSV, MNCH_PATTERN)
    df = unicefData(indicator="MNCH_CSEC", countries=["BRA"], year=2010, dataflow="MNCH")
    assert len(df) == 0
    assert df.attrs["query_status"] == "year_beyond_range"
    assert df.attrs["nearest_year"] == 2015
    assert df.attrs["available_years"] == [2015, 2016, 2017, 2018, 2019]


@responses.activate
def test_country_not_found():
    _reset()
    # Both fetches return ARG-only data
    responses.add(responses.GET, MNCH_PATTERN, body=MNCH_ARG_CSV, status=200, content_type="text/csv")
    responses.add(responses.GET, MNCH_PATTERN, body=MNCH_ARG_CSV, status=200, content_type="text/csv")
    responses.add(responses.GET, SDMX_ANY, body="Not Found", status=404)

    df = unicefData(indicator="MNCH_CSEC", countries=["BRA"], dataflow="MNCH")
    assert len(df) == 0
    assert df.attrs["query_status"] == "country_not_found"
    assert "ARG" in df.attrs.get("available_countries", [])


@responses.activate
def test_indicator_not_found():
    _reset()
    responses.add(responses.GET, SDMX_ANY, body="Not Found", status=404)
    with pytest.raises(SDMXNotFoundError):
        unicefData(indicator="COMPLETELY_FAKE_XYZ", countries=["BRA"])


@responses.activate
def test_attrs_survive():
    _reset()
    _mock(MNCH_BRA_CSV, MNCH_PATTERN)
    df = unicefData(indicator="MNCH_CSEC", countries=["BRA"], year=2025, dataflow="MNCH")
    for key in ["query_status", "query_indicator", "query_countries", "available_years", "nearest_year", "message"]:
        assert key in df.attrs, f"Missing attr: {key}"
    assert isinstance(df.attrs["available_years"], list)
    assert isinstance(df.attrs["message"], str)
    assert len(df.attrs["message"]) > 0


@responses.activate
def test_year_range_beyond():
    _reset()
    _mock(MNCH_BRA_CSV, MNCH_PATTERN)
    df = unicefData(indicator="MNCH_CSEC", countries=["BRA"], year="2025:2028", dataflow="MNCH")
    assert len(df) == 0
    assert df.attrs["query_status"] == "year_beyond_range"
    assert "2025" in df.attrs["message"]

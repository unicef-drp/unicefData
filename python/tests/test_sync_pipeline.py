"""
Sync Pipeline Tests (XML → YAML)
=================================
Tests that the SDMX XML parsing layer correctly converts raw API responses
into structured Python objects. Uses shared XML fixtures from
tests/fixtures/xml/ and tests/fixtures/api_responses/.

These tests verify Pipeline 1: XML → YAML metadata sync.
All tests run offline using mocked HTTP responses.

Test IDs: SYNC-01 through SYNC-12
"""

import pytest
import responses
import re
from pathlib import Path
from xml.etree import ElementTree as ET

# ---------------------------------------------------------------------------
# Fixture paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[2]
XML_FIXTURES = REPO_ROOT / "tests" / "fixtures" / "xml"
API_FIXTURES = REPO_ROOT / "tests" / "fixtures" / "api_responses"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_xml(name: str) -> str:
    """Load an XML fixture file."""
    path = XML_FIXTURES / name
    if not path.exists():
        path = API_FIXTURES / name
    return path.read_text(encoding="utf-8")


# ===========================================================================
# SYNC-01 to SYNC-04: Dataflow list parsing
# ===========================================================================

class TestDataflowListParsing:
    """Test XML → dataflow list parsing (both flows.py and schema_sync.py)."""

    @responses.activate
    def test_sync01_flows_list_dataflows_returns_dataframe(self):
        """SYNC-01: flows.list_dataflows() parses XML into DataFrame."""
        xml = load_xml("dataflows.xml")
        responses.add(
            responses.GET,
            re.compile(r".*sdmx\.data\.unicef\.org.*dataflow.*"),
            body=xml,
            status=200,
            content_type="application/xml",
        )
        from unicefdata.flows import list_dataflows
        df = list_dataflows(max_retries=1)
        assert len(df) == 4
        assert "id" in df.columns
        assert "name" in df.columns
        assert "CME" in df["id"].values

    @responses.activate
    def test_sync02_schema_sync_get_dataflow_list(self):
        """SYNC-02: schema_sync.get_dataflow_list() parses XML into list of dicts."""
        xml = load_xml("dataflows.xml")
        responses.add(
            responses.GET,
            re.compile(r".*sdmx\.data\.unicef\.org.*dataflow.*"),
            body=xml,
            status=200,
            content_type="application/xml",
        )
        from unicefdata.schema_sync import get_dataflow_list
        result = get_dataflow_list(max_retries=1)
        assert len(result) == 4
        ids = [d["id"] for d in result]
        assert "CME" in ids
        assert "NUTRITION" in ids
        assert "GLOBAL_DATAFLOW" in ids

    @responses.activate
    def test_sync03_dataflow_has_required_fields(self):
        """SYNC-03: Each parsed dataflow has id, name, version, agency."""
        xml = load_xml("dataflows.xml")
        responses.add(
            responses.GET,
            re.compile(r".*sdmx\.data\.unicef\.org.*dataflow.*"),
            body=xml,
            status=200,
            content_type="application/xml",
        )
        from unicefdata.schema_sync import get_dataflow_list
        result = get_dataflow_list(max_retries=1)
        for df in result:
            assert "id" in df
            assert "name" in df
            assert "version" in df
            assert "agency" in df

    @responses.activate
    def test_sync04_dataflow_names_extracted(self):
        """SYNC-04: Dataflow names parsed correctly from common:Name elements."""
        xml = load_xml("dataflows.xml")
        responses.add(
            responses.GET,
            re.compile(r".*sdmx\.data\.unicef\.org.*dataflow.*"),
            body=xml,
            status=200,
            content_type="application/xml",
        )
        from unicefdata.schema_sync import get_dataflow_list
        result = get_dataflow_list(max_retries=1)
        name_map = {d["id"]: d["name"] for d in result}
        assert name_map["CME"] == "Child Mortality Estimates"
        assert name_map["NUTRITION"] == "Nutrition"


# ===========================================================================
# SYNC-05 to SYNC-08: Codelist XML parsing (indicator_registry._parse_codelist_xml)
# ===========================================================================

class TestCodelistParsing:
    """Test XML → indicator dictionary parsing via _parse_codelist_xml."""

    def test_sync05_parse_indicator_codelist(self):
        """SYNC-05: _parse_codelist_xml extracts all 5 test indicators."""
        from unicefdata.indicator_registry import _parse_codelist_xml
        xml = load_xml("codelist_indicators.xml")
        result = _parse_codelist_xml(xml)
        assert len(result) == 5
        assert "CME_MRY0T4" in result
        assert "NT_ANT_HAZ_NE2" in result
        assert "IM_MCV1" in result

    def test_sync06_indicator_has_name_and_description(self):
        """SYNC-06: Parsed indicators have name, description, and code."""
        from unicefdata.indicator_registry import _parse_codelist_xml
        xml = load_xml("codelist_indicators.xml")
        result = _parse_codelist_xml(xml)
        cme = result["CME_MRY0T4"]
        assert cme["name"] == "Under-five mortality rate"
        assert "birth" in cme["description"].lower()
        assert cme["code"] == "CME_MRY0T4"

    def test_sync07_indicator_parent_hierarchy(self):
        """SYNC-07: Parsed indicators have parent field from XML hierarchy."""
        from unicefdata.indicator_registry import _parse_codelist_xml
        xml = load_xml("codelist_indicators.xml")
        result = _parse_codelist_xml(xml)
        assert result["CME_MRY0T4"]["parent"] == "CME"
        assert result["NT_ANT_HAZ_NE2"]["parent"] == "NUTRITION"
        assert result["IM_MCV1"]["parent"] == "IMMUNISATION"

    def test_sync08_parse_country_codelist(self):
        """SYNC-08: Country codelist XML parsed correctly."""
        from unicefdata.indicator_registry import _parse_codelist_xml
        xml = load_xml("codelist_countries.xml")
        result = _parse_codelist_xml(xml)
        assert len(result) == 5
        assert "USA" in result
        assert "BRA" in result
        assert result["USA"]["name"] == "United States of America"

    def test_sync09_parse_region_codelist(self):
        """SYNC-09: Region codelist XML parsed correctly."""
        from unicefdata.indicator_registry import _parse_codelist_xml
        xml = load_xml("codelist_regions.xml")
        result = _parse_codelist_xml(xml)
        assert len(result) == 3
        assert "UNDEV_002" in result
        assert result["UNDEV_002"]["name"] == "Africa"
        assert result["UNDEV_002"]["parent"] == "UNDEV_LD"


# ===========================================================================
# SYNC-10 to SYNC-12: Cross-format consistency
# ===========================================================================

class TestCrossFormatConsistency:
    """Verify XML and YAML fixtures are consistent with each other."""

    def test_sync10_xml_yaml_dataflow_count_match(self):
        """SYNC-10: Number of dataflows in XML matches YAML fixture."""
        import yaml
        yaml_path = REPO_ROOT / "tests" / "fixtures" / "yaml" / "_unicefdata_dataflows.yaml"
        with open(yaml_path, "r", encoding="utf-8") as f:
            yaml_data = yaml.safe_load(f)

        xml = load_xml("dataflows.xml")
        root = ET.fromstring(xml)
        ns = {"s": "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure"}
        xml_count = len(root.findall(".//s:Dataflow", ns))

        assert xml_count == len(yaml_data), (
            f"XML has {xml_count} dataflows, YAML has {len(yaml_data)}"
        )

    def test_sync11_xml_yaml_indicator_count_match(self):
        """SYNC-11: Number of indicators in XML matches YAML fixture."""
        import yaml
        yaml_path = REPO_ROOT / "tests" / "fixtures" / "yaml" / "unicef_indicators_metadata.yaml"
        with open(yaml_path, "r", encoding="utf-8") as f:
            yaml_data = yaml.safe_load(f)

        from unicefdata.indicator_registry import _parse_codelist_xml
        xml = load_xml("codelist_indicators.xml")
        xml_data = _parse_codelist_xml(xml)

        assert len(xml_data) == len(yaml_data), (
            f"XML has {len(xml_data)} indicators, YAML has {len(yaml_data)}"
        )

    def test_sync12_xml_yaml_indicator_names_match(self):
        """SYNC-12: Indicator names from XML match YAML fixture names."""
        import yaml
        yaml_path = REPO_ROOT / "tests" / "fixtures" / "yaml" / "unicef_indicators_metadata.yaml"
        with open(yaml_path, "r", encoding="utf-8") as f:
            yaml_data = yaml.safe_load(f)

        from unicefdata.indicator_registry import _parse_codelist_xml
        xml = load_xml("codelist_indicators.xml")
        xml_data = _parse_codelist_xml(xml)

        for code in yaml_data:
            assert code in xml_data, f"Indicator {code} in YAML but not in XML"
            assert xml_data[code]["name"] == yaml_data[code]["name"], (
                f"Name mismatch for {code}: XML={xml_data[code]['name']}, YAML={yaml_data[code]['name']}"
            )

"""Pytest suite for validating SDMX dataflow dimensions.

Converts the previous script into proper tests and expands coverage via
parameterization across common UNICEF dataflows.

NOTE: These tests make live API calls and are SKIPPED in CI environments.
Run locally to validate dimension structure against the live SDMX endpoint.
"""

import os
import pytest
import requests
import xml.etree.ElementTree as ET

# Skip in CI environment - these are live API tests
IN_CI = os.environ.get("CI", "").lower() == "true" or os.environ.get("GITHUB_ACTIONS", "") != ""
pytestmark = pytest.mark.skipif(IN_CI, reason="Skipping live API tests in CI")

try:
    from unicefdata import list_dataflows
except Exception:  # pragma: no cover
    list_dataflows = None


NS = {
    "str": "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure",
    "mes": "http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message",
}


def _get_flow_version(flow_id: str) -> str:
    """Resolve version for a dataflow via unicefdata if available; default to 1.0."""
    if list_dataflows is None:
        return "1.0"
    try:
        df = list_dataflows()
        match = df[df["id"] == flow_id]
        if len(match) == 0:
            return "1.0"
        return str(match.iloc[0]["version"]) or "1.0"
    except Exception:
        return "1.0"


@pytest.mark.parametrize(
    "flow_id, expected_dims",
    [
        ("CME", {"REF_AREA", "INDICATOR", "TIME_PERIOD"}),
        ("NUTRITION", {"REF_AREA", "INDICATOR", "TIME_PERIOD"}),
        ("IMMUNISATION", {"REF_AREA", "INDICATOR", "TIME_PERIOD"}),
    ],
)
def test_dataflow_dimensions_include_core_fields(flow_id: str, expected_dims: set):
    """Ensure core SDMX dimensions exist in the DSD for key dataflows.

    Skips gracefully on network failures.
    """
    version = _get_flow_version(flow_id)
    url = f"https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/{flow_id}/{version}?references=all"
    try:
        r = requests.get(url, timeout=60)
    except requests.RequestException as exc:  # pragma: no cover
        pytest.skip(f"Network error fetching DSD: {exc}")
    if r.status_code != 200:
        pytest.skip(f"DSD HTTP {r.status_code} for {flow_id}")

    try:
        root = ET.fromstring(r.content)
    except ET.ParseError as exc:  # pragma: no cover
        pytest.skip(f"DSD parse error for {flow_id}: {exc}")
    dims = set()
    # Regular dimensions
    for dim in root.findall(".//str:Dimension", NS):
        dim_id = dim.get("id")
        if dim_id:
            dims.add(dim_id)
    # Time dimension is defined separately in SDMX
    time_dim = root.findall(".//str:TimeDimension", NS)
    if time_dim:
        dims.add("TIME_PERIOD")

    # All expected core dimensions should be present
    missing = expected_dims - dims
    assert not missing, f"Missing dimensions in {flow_id}: {sorted(missing)}"


@pytest.mark.parametrize("flow_id", ["CME", "NUTRITION", "IMMUNISATION"])
def test_dataflow_has_at_least_three_dimensions(flow_id: str):
    """Basic shape test: each dataflow should declare multiple dimensions."""
    version = _get_flow_version(flow_id)
    url = f"https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/{flow_id}/{version}?references=all"
    try:
        r = requests.get(url, timeout=60)
    except requests.RequestException as exc:  # pragma: no cover
        pytest.skip(f"Network error fetching DSD: {exc}")
    if r.status_code != 200:
        pytest.skip(f"DSD HTTP {r.status_code} for {flow_id}")
    try:
        root = ET.fromstring(r.content)
    except ET.ParseError as exc:  # pragma: no cover
        pytest.skip(f"DSD parse error for {flow_id}: {exc}")
    dims = root.findall(".//str:Dimension", NS)
    assert len(dims) >= 3, f"Unexpected low dimension count for {flow_id}: {len(dims)}"

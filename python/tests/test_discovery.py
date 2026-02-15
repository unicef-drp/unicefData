"""
Discovery Pipeline Tests (YAML → output)
=========================================
Tests that the discovery functions correctly read YAML metadata and return
consistent, accurate results. Uses shared YAML fixtures from
tests/fixtures/yaml/.

These tests verify Pipeline 2: YAML metadata → user-facing discovery output.
All tests run offline using pre-loaded test caches.

Test IDs: DISC-01 through DISC-18
"""

import pytest
import yaml
from pathlib import Path
from io import StringIO
from unittest.mock import patch

# ---------------------------------------------------------------------------
# Fixture paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[2]
YAML_FIXTURES = REPO_ROOT / "tests" / "fixtures" / "yaml"


def _load_test_cache() -> dict:
    """Load the test indicator cache from YAML fixture."""
    path = YAML_FIXTURES / "unicef_indicators_metadata.yaml"
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


# ---------------------------------------------------------------------------
# Patch helper: override the indicator registry cache with test data
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True)
def patch_indicator_cache(monkeypatch):
    """Pre-populate indicator_registry cache with test YAML data."""
    import unicefdata.indicator_registry as reg

    test_cache = _load_test_cache()
    monkeypatch.setattr(reg, "_indicator_cache", test_cache)

    # Patch _ensure_cache_loaded to return test data without HTTP
    monkeypatch.setattr(reg, "_ensure_cache_loaded", lambda: test_cache)


# ===========================================================================
# DISC-01 to DISC-05: get_dataflow_for_indicator
# ===========================================================================

class TestGetDataflowForIndicator:
    """Test dataflow resolution from indicator codes."""

    def test_disc01_cme_indicator_resolves_to_cme(self):
        """DISC-01: CME_MRY0T4 resolves to CME dataflow."""
        from unicefdata.indicator_registry import get_dataflow_for_indicator
        result = get_dataflow_for_indicator("CME_MRY0T4")
        assert result == "CME"

    def test_disc02_nutrition_indicator_resolves(self):
        """DISC-02: NT_ANT_HAZ_NE2 resolves to NUTRITION dataflow."""
        from unicefdata.indicator_registry import get_dataflow_for_indicator
        result = get_dataflow_for_indicator("NT_ANT_HAZ_NE2")
        assert result == "NUTRITION"

    def test_disc03_immunisation_indicator_resolves(self):
        """DISC-03: IM_MCV1 resolves to IMMUNISATION dataflow."""
        from unicefdata.indicator_registry import get_dataflow_for_indicator
        result = get_dataflow_for_indicator("IM_MCV1")
        assert result == "IMMUNISATION"

    def test_disc04_unknown_indicator_returns_default(self):
        """DISC-04: Unknown indicator returns GLOBAL_DATAFLOW."""
        from unicefdata.indicator_registry import get_dataflow_for_indicator
        result = get_dataflow_for_indicator("NONEXISTENT_CODE")
        assert result == "GLOBAL_DATAFLOW"

    def test_disc05_known_override_bypasses_cache(self):
        """DISC-05: Known override indicators return corrected dataflow."""
        from unicefdata.indicator_registry import get_dataflow_for_indicator
        result = get_dataflow_for_indicator("PT_F_20-24_MRD_U18_TND")
        assert result == "PT_CM"


# ===========================================================================
# DISC-06 to DISC-09: get_indicator_info
# ===========================================================================

class TestGetIndicatorInfo:
    """Test indicator metadata retrieval."""

    def test_disc06_known_indicator_returns_dict(self):
        """DISC-06: get_indicator_info returns dict for known indicator."""
        from unicefdata.indicator_registry import get_indicator_info
        info = get_indicator_info("CME_MRY0T4")
        assert info is not None
        assert isinstance(info, dict)
        assert info["name"] == "Under-five mortality rate"

    def test_disc07_indicator_has_category(self):
        """DISC-07: Indicator info includes category field."""
        from unicefdata.indicator_registry import get_indicator_info
        info = get_indicator_info("CME_MRY0T4")
        assert info["category"] == "CME"

    def test_disc08_unknown_indicator_returns_none(self):
        """DISC-08: get_indicator_info returns None for unknown indicator."""
        from unicefdata.indicator_registry import get_indicator_info
        info = get_indicator_info("TOTALLY_FAKE_IND")
        assert info is None

    def test_disc09_indicator_info_has_description(self):
        """DISC-09: Indicator info includes description."""
        from unicefdata.indicator_registry import get_indicator_info
        info = get_indicator_info("NT_ANT_HAZ_NE2")
        assert "stunted" in info["description"].lower()


# ===========================================================================
# DISC-10 to DISC-13: list_indicators
# ===========================================================================

class TestListIndicators:
    """Test indicator listing and filtering."""

    def test_disc10_list_all_indicators(self):
        """DISC-10: list_indicators returns all 5 test indicators."""
        from unicefdata.indicator_registry import list_indicators
        result = list_indicators()
        assert len(result) == 5

    def test_disc11_filter_by_dataflow(self):
        """DISC-11: list_indicators(dataflow="CME") returns only CME indicators."""
        from unicefdata.indicator_registry import list_indicators
        result = list_indicators(dataflow="CME")
        assert len(result) == 2
        assert "CME_MRY0T4" in result
        assert "CME_MRY0" in result
        assert "IM_MCV1" not in result

    def test_disc12_filter_by_name(self):
        """DISC-12: list_indicators(name_contains="mortality") returns matches."""
        from unicefdata.indicator_registry import list_indicators
        result = list_indicators(name_contains="mortality")
        assert len(result) == 2
        assert "CME_MRY0T4" in result
        assert "CME_MRY0" in result

    def test_disc13_filter_by_dataflow_and_name(self):
        """DISC-13: Combined filters narrow results correctly."""
        from unicefdata.indicator_registry import list_indicators
        result = list_indicators(dataflow="IMMUNISATION", name_contains="measles")
        assert len(result) == 1
        assert "IM_MCV1" in result


# ===========================================================================
# DISC-14 to DISC-16: search_indicators (stdout)
# ===========================================================================

class TestSearchIndicators:
    """Test search_indicators output (prints to stdout)."""

    def test_disc14_search_produces_output(self, capsys):
        """DISC-14: search_indicators("mortality") prints results to stdout."""
        from unicefdata.indicator_registry import search_indicators
        search_indicators("mortality")
        captured = capsys.readouterr()
        assert "CME_MRY0T4" in captured.out
        assert "mortality" in captured.out.lower()

    def test_disc15_search_by_category(self, capsys):
        """DISC-15: search_indicators(category="IMMUNISATION") shows only IM indicators."""
        from unicefdata.indicator_registry import search_indicators
        search_indicators(category="IMMUNISATION")
        captured = capsys.readouterr()
        assert "IM_MCV1" in captured.out
        assert "IM_DTP3" in captured.out
        # CME indicator should not appear
        assert "CME_MRY0T4" not in captured.out

    def test_disc16_search_no_results(self, capsys):
        """DISC-16: search_indicators("xyznonexistent") prints no-results message."""
        from unicefdata.indicator_registry import search_indicators
        search_indicators("xyznonexistent")
        captured = capsys.readouterr()
        # Should print something (even if "no results found")
        assert len(captured.out) > 0


# ===========================================================================
# DISC-17 to DISC-18: Prefix-based inference
# ===========================================================================

class TestPrefixInference:
    """Test _infer_category prefix-based dataflow detection."""

    def test_disc17_prefix_inference_cme(self):
        """DISC-17: CME prefix infers CME category."""
        from unicefdata.indicator_registry import _infer_category
        assert _infer_category("CME_SOME_NEW_IND") == "CME"

    def test_disc18_prefix_inference_nutrition(self):
        """DISC-18: NT prefix infers NUTRITION category."""
        from unicefdata.indicator_registry import _infer_category
        result = _infer_category("NT_SOME_NEW_IND")
        assert result == "NUTRITION"

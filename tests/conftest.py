"""
Pytest configuration for cross-language fixture tests.

This conftest.py provides:
1. Test fixture existence validation (skip tests gracefully if missing)
2. Shared fixture loading utilities
3. CI-friendly error handling
"""

import pytest
from pathlib import Path

# ---------------------------------------------------------------------------
# Exclude legacy debug/validation scripts that aren't proper pytest tests
# ---------------------------------------------------------------------------
collect_ignore = [
    "test_python_integration.py",  # Debug script with broken imports
    "test_quick_python.py",        # Debug script with module-level execution
    "test_direct_metadata.py",     # Debug script, not pytest format
    "test_hardcoded_removal_validation.py",  # Validation script, not pytest format
]

# Paths to shared fixtures
REPO_ROOT = Path(__file__).parent.parent
FIXTURES_DIR = REPO_ROOT / "tests" / "fixtures"
API_RESPONSES_DIR = FIXTURES_DIR / "api_responses"
EXPECTED_DIR = FIXTURES_DIR / "expected"


def pytest_configure(config):
    """Register custom markers."""
    config.addinivalue_line(
        "markers", "requires_fixtures: marks tests that require fixture files"
    )


def _check_fixtures_available():
    """Check if required fixture directories exist."""
    return API_RESPONSES_DIR.exists() and EXPECTED_DIR.exists()


@pytest.fixture(scope="session", autouse=True)
def validate_fixtures_exist():
    """
    Session-scoped fixture that validates fixture availability on test start.
    
    Skips all fixture-dependent tests if fixtures are missing.
    """
    if not _check_fixtures_available():
        pytest.skip(
            f"Fixture directories not available. "
            f"Expected: {API_RESPONSES_DIR} and {EXPECTED_DIR}"
        )


@pytest.fixture
def fixtures_dir():
    """Return path to fixtures/api_responses directory."""
    if not API_RESPONSES_DIR.exists():
        pytest.skip(f"API responses fixtures not found: {API_RESPONSES_DIR}")
    return API_RESPONSES_DIR


@pytest.fixture
def expected_dir():
    """Return path to fixtures/expected directory."""
    if not EXPECTED_DIR.exists():
        pytest.skip(f"Expected outputs fixtures not found: {EXPECTED_DIR}")
    return EXPECTED_DIR


@pytest.fixture
def required_fixture_files():
    """
    Validate required fixture files exist.
    
    Returns dict with paths to all required fixtures.
    """
    required = {
        "cme_albania": API_RESPONSES_DIR / "cme_albania_valid.csv",
        "cme_usa": API_RESPONSES_DIR / "cme_usa_valid.csv",
        "empty": API_RESPONSES_DIR / "empty_response.csv",
        "nutrition": API_RESPONSES_DIR / "nutrition_multi_country.csv",
        "disaggregated": API_RESPONSES_DIR / "cme_disaggregated_sex.csv",
        "vaccination": API_RESPONSES_DIR / "vaccination_multi_indicator.csv",
        "expected_columns": EXPECTED_DIR / "expected_columns.csv",
        "expected_cme": EXPECTED_DIR / "expected_cme_albania_output.csv",
        "expected_nutrition": EXPECTED_DIR / "expected_nutrition_multi_output.csv",
        "expected_errors": EXPECTED_DIR / "expected_error_messages.csv",
    }
    
    missing = [name for name, path in required.items() if not path.exists()]
    if missing:
        pytest.skip(f"Missing fixture files: {', '.join(missing)}")
    
    return required

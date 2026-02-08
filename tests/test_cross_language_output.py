#!/usr/bin/env python3
"""
Cross-Language Output Validation Tests (Phase 7)

Validates that Python's unicefData() produces output structurally consistent
with the expected output fixtures shared across all three language implementations.

These tests use shared fixtures from tests/fixtures/ and do NOT require network access.
"""

import sys
import csv
from pathlib import Path

# Add python module to path
REPO_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(REPO_ROOT / "python"))

FIXTURES_DIR = REPO_ROOT / "tests" / "fixtures" / "api_responses"
EXPECTED_DIR = REPO_ROOT / "tests" / "fixtures" / "expected"


def load_csv(filepath):
    """Load a CSV file and return list of dicts."""
    with open(filepath, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def load_column_mapping():
    """Load the canonical SDMX -> output column mapping."""
    rows = load_csv(EXPECTED_DIR / "expected_columns.csv")
    return {r["sdmx_column"]: r for r in rows}


# ============================================================================
# Test counters
# ============================================================================
tests_run = 0
tests_passed = 0
tests_failed = 0


def run_test(description, test_fn):
    global tests_run, tests_passed, tests_failed
    tests_run += 1
    try:
        test_fn()
        print(f"  PASS  {description}")
        tests_passed += 1
    except Exception as e:
        print(f"  FAIL  {description}: {e}")
        tests_failed += 1


# ============================================================================
# 7.2.1 - Output Structure Validation
# ============================================================================

def test_fixture_files_exist():
    """All fixture files referenced in expected/ should exist."""
    assert FIXTURES_DIR.exists(), f"Fixtures dir not found: {FIXTURES_DIR}"
    assert EXPECTED_DIR.exists(), f"Expected dir not found: {EXPECTED_DIR}"

    required_fixtures = [
        "cme_albania_valid.csv",
        "cme_usa_valid.csv",
        "empty_response.csv",
        "nutrition_multi_country.csv",
        "cme_disaggregated_sex.csv",
        "vaccination_multi_indicator.csv",
    ]
    for name in required_fixtures:
        assert (FIXTURES_DIR / name).exists(), f"Missing fixture: {name}"

    required_expected = [
        "expected_columns.csv",
        "expected_cme_albania_output.csv",
        "expected_nutrition_multi_output.csv",
        "expected_error_messages.csv",
    ]
    for name in required_expected:
        assert (EXPECTED_DIR / name).exists(), f"Missing expected: {name}"


def test_cme_albania_column_structure():
    """CME Albania CSV has all required SDMX columns."""
    mapping = load_column_mapping()
    data = load_csv(FIXTURES_DIR / "cme_albania_valid.csv")

    assert len(data) == 3, f"Expected 3 rows, got {len(data)}"

    required = [col for col, info in mapping.items() if info["required"] == "yes"]
    actual_cols = set(data[0].keys())
    for col in required:
        assert col in actual_cols, f"Missing required column: {col}"


def test_cme_albania_data_values():
    """CME Albania values match expected output fixture."""
    api_data = load_csv(FIXTURES_DIR / "cme_albania_valid.csv")
    expected = load_csv(EXPECTED_DIR / "expected_cme_albania_output.csv")

    assert len(api_data) == len(expected), (
        f"Row count mismatch: API={len(api_data)}, expected={len(expected)}"
    )

    for i, (api_row, exp_row) in enumerate(zip(api_data, expected)):
        # Verify key values map correctly
        assert api_row["REF_AREA"] == exp_row["iso3"], (
            f"Row {i}: REF_AREA={api_row['REF_AREA']} != iso3={exp_row['iso3']}"
        )
        assert api_row["INDICATOR"] == exp_row["indicator"], (
            f"Row {i}: INDICATOR mismatch"
        )
        assert float(api_row["OBS_VALUE"]) == float(exp_row["value"]), (
            f"Row {i}: OBS_VALUE={api_row['OBS_VALUE']} != value={exp_row['value']}"
        )
        assert int(api_row["TIME_PERIOD"]) == int(exp_row["period"]), (
            f"Row {i}: TIME_PERIOD mismatch"
        )


def test_nutrition_multi_country_structure():
    """Nutrition multi-country CSV has age disaggregation column."""
    data = load_csv(FIXTURES_DIR / "nutrition_multi_country.csv")

    assert len(data) == 6, f"Expected 6 rows, got {len(data)}"

    # Must have AGE column (not in CME data)
    assert "AGE" in data[0].keys(), "Missing AGE column in nutrition data"

    # Check country variety
    countries = set(row["REF_AREA"] for row in data)
    assert countries == {"IND", "ETH", "BGD"}, f"Unexpected countries: {countries}"


def test_nutrition_values_match_expected():
    """Nutrition data values match expected output fixture."""
    api_data = load_csv(FIXTURES_DIR / "nutrition_multi_country.csv")
    expected = load_csv(EXPECTED_DIR / "expected_nutrition_multi_output.csv")

    assert len(api_data) == len(expected), "Row count mismatch"

    for i, (api_row, exp_row) in enumerate(zip(api_data, expected)):
        assert api_row["REF_AREA"] == exp_row["iso3"], f"Row {i}: iso3 mismatch"
        assert float(api_row["OBS_VALUE"]) == float(exp_row["value"]), (
            f"Row {i}: value mismatch"
        )


def test_disaggregated_sex_structure():
    """Sex-disaggregated CSV has M/F/_T values."""
    data = load_csv(FIXTURES_DIR / "cme_disaggregated_sex.csv")

    assert len(data) == 6, f"Expected 6 rows, got {len(data)}"

    sex_values = set(row["SEX"] for row in data)
    assert sex_values == {"_T", "M", "F"}, f"Unexpected sex values: {sex_values}"

    # Male mortality should be higher than female (biological pattern)
    for year in ["2020", "2021"]:
        year_rows = [r for r in data if r["TIME_PERIOD"] == year]
        male = float([r for r in year_rows if r["SEX"] == "M"][0]["OBS_VALUE"])
        female = float([r for r in year_rows if r["SEX"] == "F"][0]["OBS_VALUE"])
        assert male > female, f"Year {year}: Male ({male}) should > Female ({female})"


def test_multi_indicator_structure():
    """Multi-indicator vaccination CSV has two indicators."""
    data = load_csv(FIXTURES_DIR / "vaccination_multi_indicator.csv")

    assert len(data) == 8, f"Expected 8 rows, got {len(data)}"

    indicators = set(row["INDICATOR"] for row in data)
    assert indicators == {"IM_DTP3", "IM_MCV1"}, f"Unexpected indicators: {indicators}"

    countries = set(row["REF_AREA"] for row in data)
    assert countries == {"GHA", "KEN"}, f"Unexpected countries: {countries}"


def test_empty_response_structure():
    """Empty response CSV has headers but no data rows."""
    data = load_csv(FIXTURES_DIR / "empty_response.csv")
    assert len(data) == 0, f"Expected 0 rows, got {len(data)}"


def test_data_types_numeric():
    """OBS_VALUE and TIME_PERIOD should be parseable as numeric."""
    for fixture_name in ["cme_albania_valid.csv", "nutrition_multi_country.csv",
                         "cme_disaggregated_sex.csv", "vaccination_multi_indicator.csv"]:
        data = load_csv(FIXTURES_DIR / fixture_name)
        for i, row in enumerate(data):
            try:
                float(row["OBS_VALUE"])
            except ValueError:
                raise AssertionError(f"{fixture_name} row {i}: OBS_VALUE not numeric")
            try:
                int(row["TIME_PERIOD"])
            except ValueError:
                raise AssertionError(f"{fixture_name} row {i}: TIME_PERIOD not numeric")


def test_column_mapping_completeness():
    """expected_columns.csv covers all SDMX columns seen in fixtures."""
    mapping = load_column_mapping()
    sdmx_cols = set(mapping.keys())

    for fixture_name in ["cme_albania_valid.csv", "nutrition_multi_country.csv",
                         "vaccination_multi_indicator.csv"]:
        data = load_csv(FIXTURES_DIR / fixture_name)
        if data:
            for col in data[0].keys():
                assert col in sdmx_cols, (
                    f"Column '{col}' in {fixture_name} not in expected_columns.csv"
                )


# ============================================================================
# 7.2.2 - Error Message Validation
# ============================================================================

def test_error_message_patterns():
    """Error message fixture has valid structure."""
    errors = load_csv(EXPECTED_DIR / "expected_error_messages.csv")
    assert len(errors) >= 3, f"Expected at least 3 error scenarios, got {len(errors)}"

    python_count = 0
    for row in errors:
        assert row["scenario"], "Missing scenario name"
        assert row["error_type"], "Missing error type"
        assert row["message_pattern"], "Missing message pattern"
        langs = row["languages"].split(";")
        assert len(langs) >= 1, f"Scenario {row['scenario']} has no languages"
        if "python" in langs:
            python_count += 1

    assert python_count >= 2, f"Expected at least 2 Python error scenarios, got {python_count}"


def test_python_error_classes_exist():
    """Python exception classes referenced in error fixtures should exist."""
    from unicefdata.sdmx_client import (
        SDMXError,
        SDMXNotFoundError,
        SDMXTimeoutError,
        SDMXBadRequestError,
    )

    # Verify inheritance
    assert issubclass(SDMXNotFoundError, SDMXError)
    assert issubclass(SDMXTimeoutError, SDMXError)
    assert issubclass(SDMXBadRequestError, SDMXError)


# ============================================================================
# 7.2.3 - Cache Validation
# ============================================================================

def test_clear_cache_exists():
    """Python clear_cache() function should be importable."""
    from unicefdata import clear_cache
    assert callable(clear_cache)


def test_clear_cache_returns_list():
    """clear_cache() should return list of cleared cache names."""
    from unicefdata.unicefdata import clear_cache
    result = clear_cache(reload=False, verbose=False)
    assert isinstance(result, list), f"Expected list, got {type(result)}"
    assert len(result) >= 3, f"Expected at least 3 caches cleared, got {len(result)}"
    assert "fallback_sequences" in result
    assert "indicators_metadata" in result


# ============================================================================
# Main
# ============================================================================

if __name__ == "__main__":
    print("\n" + "=" * 70)
    print("Cross-Language Output Validation Tests (Python)")
    print("=" * 70)

    print("\n--- 7.2.1: Output Structure ---")
    run_test("Fixture files exist", test_fixture_files_exist)
    run_test("CME Albania column structure", test_cme_albania_column_structure)
    run_test("CME Albania data values", test_cme_albania_data_values)
    run_test("Nutrition multi-country structure", test_nutrition_multi_country_structure)
    run_test("Nutrition values match expected", test_nutrition_values_match_expected)
    run_test("Disaggregated sex structure", test_disaggregated_sex_structure)
    run_test("Multi-indicator structure", test_multi_indicator_structure)
    run_test("Empty response structure", test_empty_response_structure)
    run_test("Data types numeric", test_data_types_numeric)
    run_test("Column mapping completeness", test_column_mapping_completeness)

    print("\n--- 7.2.2: Error Validation ---")
    run_test("Error message patterns", test_error_message_patterns)
    run_test("Python error classes exist", test_python_error_classes_exist)

    print("\n--- 7.2.3: Cache Validation ---")
    run_test("clear_cache exists", test_clear_cache_exists)
    run_test("clear_cache returns list", test_clear_cache_returns_list)

    print("\n" + "=" * 70)
    print(f"Results: {tests_passed}/{tests_run} passed, {tests_failed} failed")
    print("=" * 70)

    sys.exit(1 if tests_failed > 0 else 0)

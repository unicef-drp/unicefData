#!/usr/bin/env python3
"""
YAML Metadata Schema Validator
===============================

Validates UNICEF metadata YAML files against expected schemas.

Usage:
    python validate_yaml_schema.py <file_type> <filepath>

File types:
    indicators      - _unicefdata_indicators_metadata.yaml
    dataflow_index  - _dataflow_index.yaml
    dataflows       - _unicefdata_dataflows.yaml
    codelists       - _unicefdata_codelists.yaml
    countries       - _unicefdata_countries.yaml
    regions         - _unicefdata_regions.yaml

Exit codes:
    0 - Validation successful
    1 - Validation failed
    2 - File not found or YAML parse error
"""

import sys
import yaml
from typing import Dict, List, Any, Tuple

def validate_indicator_metadata(filepath: str) -> Tuple[bool, List[str]]:
    """
    Validate _unicefdata_indicators_metadata.yaml schema.

    Checks:
    - Metadata header structure
    - tier_counts field present and valid
    - All indicators have required enrichment fields
    - Field value types and ranges
    """
    errors = []

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        return False, [f"File not found: {filepath}"]
    except yaml.YAMLError as e:
        return False, [f"YAML parse error: {e}"]

    # Validate metadata header
    if 'metadata' not in data:
        errors.append("Missing 'metadata' section")
        return False, errors

    metadata = data['metadata']

    # Required metadata fields
    required_meta = ['version', 'source', 'last_updated', 'indicator_count']
    for field in required_meta:
        if field not in metadata:
            errors.append(f"metadata: Missing required field '{field}'")

    # Check tier_counts (required for enriched metadata)
    if 'tier_counts' not in metadata:
        errors.append("metadata: Missing 'tier_counts' field (enrichment incomplete)")
    else:
        tier_counts = metadata['tier_counts']
        for tier in ['tier_1', 'tier_2', 'tier_3', 'tier_4']:
            if tier not in tier_counts:
                errors.append(f"metadata.tier_counts: Missing '{tier}'")
            elif not isinstance(tier_counts[tier], int):
                errors.append(f"metadata.tier_counts.{tier}: Must be integer, got {type(tier_counts[tier])}")

    # Validate indicators section
    if 'indicators' not in data:
        errors.append("Missing 'indicators' section")
        return False, errors

    indicators = data['indicators']

    # Check indicator count matches metadata
    actual_count = len(indicators)
    expected_count = metadata.get('indicator_count', 0)
    if actual_count != expected_count:
        errors.append(f"Indicator count mismatch: metadata says {expected_count}, found {actual_count}")

    # Validate each indicator
    indicators_without_tier = []
    indicators_without_tier_reason = []
    invalid_tier_values = []
    dataflow_order_issues = []  # Indicators with GLOBAL_DATAFLOW not last
    tier_counts_actual = {'tier_1': 0, 'tier_2': 0, 'tier_3': 0, 'tier_4': 0}

    for code, indicator in indicators.items():
        # Required base fields
        required_fields = ['code', 'name']
        for field in required_fields:
            if field not in indicator:
                errors.append(f"{code}: Missing required field '{field}'")

        # Validate code matches key
        if 'code' in indicator and indicator['code'] != code:
            errors.append(f"{code}: code field '{indicator['code']}' doesn't match key")

        # Validate tier (required in enriched metadata)
        if 'tier' not in indicator:
            indicators_without_tier.append(code)
        else:
            tier_value = indicator['tier']
            if not isinstance(tier_value, int) or tier_value not in [1, 2, 3, 4]:
                invalid_tier_values.append(f"{code} (tier={tier_value})")
            else:
                tier_counts_actual[f'tier_{tier_value}'] += 1

        # Validate tier_reason (required if tier exists)
        if 'tier' in indicator and 'tier_reason' not in indicator:
            indicators_without_tier_reason.append(code)

        # Validate tier_reason is a string
        if 'tier_reason' in indicator and not isinstance(indicator['tier_reason'], str):
            errors.append(f"{code}: tier_reason must be string, got {type(indicator['tier_reason'])}")

        # Validate disaggregations (if present, must be list)
        if 'disaggregations' in indicator:
            if not isinstance(indicator['disaggregations'], list):
                errors.append(f"{code}: disaggregations must be list, got {type(indicator['disaggregations'])}")

        # Validate disaggregations_with_totals (if present, must be list)
        if 'disaggregations_with_totals' in indicator:
            if not isinstance(indicator['disaggregations_with_totals'], list):
                errors.append(f"{code}: disaggregations_with_totals must be list")

        # Validate dataflows ordering: GLOBAL_DATAFLOW must be last
        dataflows = indicator.get('dataflows')
        if isinstance(dataflows, list) and len(dataflows) > 1:
            if 'GLOBAL_DATAFLOW' in dataflows:
                global_idx = dataflows.index('GLOBAL_DATAFLOW')
                if global_idx != len(dataflows) - 1:
                    dataflow_order_issues.append(code)

    # Report indicators missing enrichment
    if indicators_without_tier:
        count = len(indicators_without_tier)
        errors.append(f"{count} indicators missing 'tier' field (enrichment incomplete)")
        if count <= 5:
            errors.append(f"  Examples: {', '.join(indicators_without_tier[:5])}")

    if indicators_without_tier_reason:
        count = len(indicators_without_tier_reason)
        errors.append(f"{count} indicators missing 'tier_reason' field")
        if count <= 5:
            errors.append(f"  Examples: {', '.join(indicators_without_tier_reason[:5])}")

    if invalid_tier_values:
        errors.append(f"Invalid tier values (must be 1-4): {', '.join(invalid_tier_values[:5])}")

    # Report GLOBAL_DATAFLOW ordering violations
    if dataflow_order_issues:
        count = len(dataflow_order_issues)
        errors.append(f"{count} indicators have GLOBAL_DATAFLOW not in last position (should be fallback)")
        if count <= 5:
            errors.append(f"  Examples: {', '.join(dataflow_order_issues[:5])}")

    # Verify tier_counts accuracy
    if 'tier_counts' in metadata and not indicators_without_tier:
        for tier in ['tier_1', 'tier_2', 'tier_3', 'tier_4']:
            expected = metadata['tier_counts'].get(tier, 0)
            actual = tier_counts_actual[tier]
            if expected != actual:
                errors.append(f"tier_counts.{tier}: Expected {expected}, counted {actual}")

    if errors:
        return False, errors

    return True, [f"[OK] Valid schema: {actual_count} indicators with complete enrichment"]


def validate_dataflow_index(filepath: str) -> Tuple[bool, List[str]]:
    """
    Validate _dataflow_index.yaml schema.

    Checks:
    - Metadata header
    - Dataflows section with required fields
    - Field types
    """
    errors = []

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        return False, [f"File not found: {filepath}"]
    except yaml.YAMLError as e:
        return False, [f"YAML parse error: {e}"]

    # Validate metadata
    if 'metadata_version' not in data:
        errors.append("Missing 'metadata_version' field")

    if 'synced_at' not in data:
        errors.append("Missing 'synced_at' field")

    # Validate dataflows section
    if 'dataflows' not in data:
        errors.append("Missing 'dataflows' section")
        return False, errors

    dataflows = data['dataflows']
    if not isinstance(dataflows, list):
        errors.append(f"'dataflows' must be a list, got {type(dataflows)}")
        return False, errors

    # Validate each dataflow entry
    for idx, df_data in enumerate(dataflows):
        if not isinstance(df_data, dict):
            errors.append(f"Dataflow[{idx}]: Must be a dict, got {type(df_data)}")
            continue

        df_id = df_data.get('id', f'index_{idx}')

        # Required fields
        required = ['id', 'name', 'dimensions_count', 'attributes_count']
        for field in required:
            if field not in df_data:
                errors.append(f"{df_id}: Missing required field '{field}'")

        # Validate counts are integers
        if 'dimensions_count' in df_data and not isinstance(df_data['dimensions_count'], int):
            errors.append(f"{df_id}: dimensions_count must be integer")

        if 'attributes_count' in df_data and not isinstance(df_data['attributes_count'], int):
            errors.append(f"{df_id}: attributes_count must be integer")

    if errors:
        return False, errors

    return True, [f"[OK] Valid schema: {len(dataflows)} dataflows"]


def validate_simple_list(filepath: str, expected_sections: List[str], file_type: str) -> Tuple[bool, List[str]]:
    """
    Validate simple list-based YAML files (dataflows, codelists, countries, regions).

    Checks:
    - Expected sections present
    - Proper YAML structure
    """
    errors = []

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        return False, [f"File not found: {filepath}"]
    except yaml.YAMLError as e:
        return False, [f"YAML parse error: {e}"]

    # Check expected sections
    for section in expected_sections:
        if section not in data:
            errors.append(f"Missing '{section}' section")

    # Basic structure validation
    if not isinstance(data, dict):
        errors.append(f"Root must be a dict, got {type(data)}")
        return False, errors

    if errors:
        return False, errors

    item_count = sum(len(v) if isinstance(v, (list, dict)) else 1 for v in data.values())
    return True, [f"[OK] Valid {file_type} schema: {item_count} items"]


VALIDATORS = {
    'indicators': validate_indicator_metadata,
    'dataflow_index': validate_dataflow_index,
    'dataflows': lambda f: validate_simple_list(f, ['metadata', 'dataflows'], 'dataflows'),
    'codelists': lambda f: validate_simple_list(f, ['metadata'], 'codelists'),
    'countries': lambda f: validate_simple_list(f, ['metadata', 'countries'], 'countries'),
    'regions': lambda f: validate_simple_list(f, ['metadata', 'regions'], 'regions'),
}


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)

    file_type = sys.argv[1]
    filepath = sys.argv[2]

    if file_type not in VALIDATORS:
        print(f"Error: Unknown file type '{file_type}'")
        print(f"Valid types: {', '.join(VALIDATORS.keys())}")
        sys.exit(2)

    print(f"Validating {file_type} schema: {filepath}")
    print("=" * 70)

    validator = VALIDATORS[file_type]
    success, messages = validator(filepath)

    for msg in messages:
        print(msg)

    print("=" * 70)

    if success:
        print(f"VALIDATION PASSED")
        sys.exit(0)
    else:
        print(f"VALIDATION FAILED")
        sys.exit(1)


if __name__ == '__main__':
    main()

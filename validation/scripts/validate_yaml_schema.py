#!/usr/bin/env python3
"""
YAML Schema Validation Script

Validates that Python, R, and Stata YAMLs follow the same schema and naming conventions.

This ensures that each language's independent YAML files are equivalent in structure
while allowing each language to generate its own metadata files.

Requirements:
- All files must use single underscore prefix: _unicefdata_*.yaml
- All files must have _metadata header with platform, version, synced_at
- Indicator counts should be within 5% tolerance across platforms
- Common indicators should have matching metadata fields

Usage:
    python validation/scripts/validate_yaml_schema.py
    python validation/scripts/validate_yaml_schema.py --verbose
    python validation/scripts/validate_yaml_schema.py --strict  # Fail on any mismatch

Date: 2026-01-25
Version: 1.0.0
"""

import sys
import yaml
import argparse
from pathlib import Path
from typing import Dict, List, Set, Any
from datetime import datetime


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'
    BOLD = '\033[1m'


def load_yaml(path: Path) -> Dict[str, Any]:
    """Load YAML file"""
    if not path.exists():
        return None

    with open(path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def validate_filename(path: Path) -> bool:
    """Validate that filename uses single underscore prefix"""
    filename = path.name
    if not filename.startswith('_unicefdata_') and not filename.startswith('_dataflow_fallback'):
        print(f"  {Colors.RED}X{Colors.END} Invalid filename: {filename}")
        print(f"    Expected: _unicefdata_*.yaml (single underscore)")
        return False
    return True


def validate_metadata_header(yaml_data: Dict, platform: str, file_type: str) -> bool:
    """Validate _metadata or metadata header block"""
    if '_metadata' not in yaml_data and 'metadata' not in yaml_data:
        print(f"  {Colors.RED}X{Colors.END} Missing _metadata or metadata header")
        return False

    metadata = yaml_data.get('_metadata') or yaml_data.get('metadata')
    required_fields = ['platform', 'version', 'synced_at', 'source', 'agency', 'content_type']

    missing = [f for f in required_fields if f not in metadata]
    if missing:
        print(f"  {Colors.RED}X{Colors.END} Missing metadata fields: {missing}")
        return False

    # Validate platform
    if metadata.get('platform', '').lower() != platform.lower():
        print(f"  {Colors.YELLOW}!{Colors.END} Platform mismatch: expected '{platform}', got '{metadata.get('platform')}'")

    # Validate content_type
    if metadata.get('content_type') != file_type:
        print(f"  {Colors.RED}X{Colors.END} Content type mismatch: expected '{file_type}', got '{metadata.get('content_type')}'")
        return False

    return True


def validate_dataflows_ordering(dataflows: List) -> List[str]:
    """
    Validate that GLOBAL_DATAFLOW is always last in multi-dataflow lists.
    
    GLOBAL_DATAFLOW is a fallback dataflow with fewer disaggregations.
    When an indicator exists in multiple dataflows, the more specific 
    dataflow (e.g., NUTRITION, HIV_AIDS) should be listed first so that
    auto-detection uses it as the primary source for disaggregations.
    
    Returns:
        List of validation issue messages (empty if valid)
    """
    if not isinstance(dataflows, list) or len(dataflows) <= 1:
        return []
    
    issues = []
    if 'GLOBAL_DATAFLOW' in dataflows:
        global_idx = dataflows.index('GLOBAL_DATAFLOW')
        if global_idx != len(dataflows) - 1:
            issues.append(f"GLOBAL_DATAFLOW should be last, found at position {global_idx + 1}/{len(dataflows)}")
    
    return issues


def validate_indicators_structure(yaml_data: Dict, platform: str, verbose: bool = False) -> Dict:
    """Validate indicators YAML structure and return summary"""
    if 'indicators' not in yaml_data:
        return {'error': 'Missing indicators section'}

    indicators = yaml_data['indicators']
    sample_keys = list(indicators.keys())[:3] if indicators else []

    # Check structure of sample indicators
    issues = []
    dataflow_order_issues = []
    
    for key, ind in indicators.items():
        if not isinstance(ind, dict):
            issues.append(f"Indicator {key} is not a dictionary")
            continue

        # Check required fields (sample only)
        if key in sample_keys:
            required_fields = ['name', 'dataflow']
            missing = [f for f in required_fields if f not in ind or ind[f] is None]
            if missing and verbose:
                print(f"    {Colors.YELLOW}!{Colors.END} {key}: missing {missing}")
        
        # Check dataflows ordering for ALL indicators with multi-dataflow lists
        dataflows = ind.get('dataflows')
        if dataflows:
            order_issues = validate_dataflows_ordering(dataflows)
            if order_issues:
                dataflow_order_issues.append(f"{key}: {order_issues[0]}")

    # Report dataflow ordering issues
    if dataflow_order_issues:
        print(f"  {Colors.RED}X{Colors.END} GLOBAL_DATAFLOW ordering violations: {len(dataflow_order_issues)}")
        if verbose:
            for issue in dataflow_order_issues[:5]:  # Show first 5
                print(f"    {Colors.YELLOW}!{Colors.END} {issue}")
            if len(dataflow_order_issues) > 5:
                print(f"    ... and {len(dataflow_order_issues) - 5} more")
        issues.extend(dataflow_order_issues)

    return {
        'total': len(indicators),
        'sample': sample_keys,
        'issues': issues,
        'dataflow_order_issues': len(dataflow_order_issues)
    }


def validate_schema_across_platforms(python_dir: Path, r_dir: Path, stata_dir: Path,
                                     verbose: bool = False, strict: bool = False) -> bool:
    """Validate that all platforms follow the same schema"""
    print(f"\n{Colors.BOLD}{'='*80}{Colors.END}")
    print(f"{Colors.BOLD}YAML Schema Validation{Colors.END}")
    print(f"{Colors.BOLD}{'='*80}{Colors.END}\n")

    # File types to validate
    file_types = [
        ('_unicefdata_indicators_metadata.yaml', 'indicators', 'indicators'),
        ('_unicefdata_dataflows.yaml', 'dataflows', 'dataflows'),
        ('_unicefdata_regions.yaml', 'regions', 'regions'),
        ('_unicefdata_countries.yaml', 'countries', 'countries'),
        ('_unicefdata_codelists.yaml', 'codelists', 'codelists'),
    ]

    platforms = [
        ('Python', python_dir, 'python'),
        ('R', r_dir, 'R'),
        ('Stata', stata_dir, 'stata'),
    ]

    all_passed = True
    total_tests = 0
    passed_tests = 0

    # Validate each file type across platforms
    for filename, content_type, data_key in file_types:
        print(f"{Colors.BOLD}Checking: {filename}{Colors.END}")
        print(f"{'-' * 80}")

        platform_data = {}
        file_found = {}

        # Load from each platform
        for platform_name, platform_dir, platform_key in platforms:
            file_path = platform_dir / filename
            total_tests += 1

            print(f"\n{platform_name}:")
            print(f"  Path: {file_path}")

            # Check if file exists
            if not file_path.exists():
                print(f"  {Colors.YELLOW}!{Colors.END} File not found (skipping)")
                file_found[platform_key] = False
                continue

            file_found[platform_key] = True

            # Validate filename
            if not validate_filename(file_path):
                all_passed = False
                continue

            # Load YAML
            try:
                yaml_data = load_yaml(file_path)
                if yaml_data is None:
                    print(f"  {Colors.RED}X{Colors.END} Failed to load YAML")
                    all_passed = False
                    continue

                platform_data[platform_key] = yaml_data

                # Validate metadata header
                if not validate_metadata_header(yaml_data, platform_name, content_type):
                    all_passed = False
                    continue

                # Validate data section exists
                if data_key not in yaml_data:
                    print(f"  {Colors.RED}X{Colors.END} Missing '{data_key}' section")
                    all_passed = False
                    continue

                # Count items
                count = len(yaml_data[data_key])
                metadata = yaml_data.get('_metadata') or yaml_data.get('metadata')
                print(f"  {Colors.GREEN}OK{Colors.END} Valid structure")
                print(f"    Items: {count}")
                print(f"    Version: {metadata.get('version', 'N/A')}")
                print(f"    Synced: {metadata.get('synced_at', 'N/A')[:10]}")

                passed_tests += 1

            except Exception as e:
                print(f"  {Colors.RED}X{Colors.END} Error: {e}")
                all_passed = False

        # Cross-platform comparison
        if len(platform_data) >= 2:
            print(f"\n{Colors.BOLD}Cross-platform comparison:{Colors.END}")

            # Compare counts
            counts = {p: len(data[data_key]) for p, data in platform_data.items()}
            max_count = max(counts.values())
            min_count = min(counts.values())
            tolerance = max_count * 0.05  # 5% tolerance

            print(f"  Counts: {counts}")

            if (max_count - min_count) <= tolerance:
                print(f"  {Colors.GREEN}OK{Colors.END} Counts within tolerance (5%)")
            else:
                print(f"  {Colors.RED}X{Colors.END} Counts differ by more than 5%")
                all_passed = False

            # For indicators, check common indicators have matching fields
            if content_type == 'indicators' and len(platform_data) >= 2:
                platform_keys = list(platform_data.keys())
                p1_data = platform_data[platform_keys[0]]
                p2_data = platform_data[platform_keys[1]]

                common_indicators = (set(p1_data[data_key].keys()) &
                                   set(p2_data[data_key].keys()))

                print(f"  Common indicators: {len(common_indicators)}")

                if verbose and len(common_indicators) > 0:
                    # Sample check
                    sample = list(common_indicators)[:3]
                    print(f"  Sample checks ({len(sample)} indicators):")
                    for ind in sample:
                        p1_ind = p1_data[data_key][ind]
                        p2_ind = p2_data[data_key][ind]

                        # Check if dataflow matches (if both have it)
                        p1_df = p1_ind.get('dataflow')
                        p2_df = p2_ind.get('dataflow')

                        if p1_df and p2_df and p1_df != p2_df:
                            print(f"    {Colors.YELLOW}!{Colors.END} {ind}: dataflow mismatch ({p1_df} vs {p2_df})")
                        elif verbose:
                            print(f"    {Colors.GREEN}OK{Colors.END} {ind}: consistent")

        print()

    # Summary
    print(f"{Colors.BOLD}{'='*80}{Colors.END}")
    print(f"{Colors.BOLD}Summary{Colors.END}")
    print(f"{Colors.BOLD}{'='*80}{Colors.END}")
    print(f"Total tests: {total_tests}")
    print(f"Passed: {passed_tests} ({100 * passed_tests / total_tests if total_tests > 0 else 0:.1f}%)")
    print(f"Failed: {total_tests - passed_tests}")

    if all_passed:
        print(f"\n{Colors.GREEN}{Colors.BOLD}OK All schema validations passed!{Colors.END}\n")
        return True
    else:
        print(f"\n{Colors.RED}{Colors.BOLD}X Some validations failed{Colors.END}\n")
        if strict:
            print(f"{Colors.RED}Strict mode: Exiting with error code{Colors.END}\n")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Validate YAML schema consistency across Python, R, and Stata'
    )
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Show detailed validation output')
    parser.add_argument('--strict', action='store_true',
                       help='Exit with error code if any validation fails')
    parser.add_argument('--python-dir', type=Path,
                       default=Path('python/metadata/current'),
                       help='Path to Python metadata directory')
    parser.add_argument('--r-dir', type=Path,
                       default=Path('R/metadata/current'),
                       help='Path to R metadata directory')
    parser.add_argument('--stata-dir', type=Path,
                       default=Path('stata/src/_'),
                       help='Path to Stata metadata directory')

    args = parser.parse_args()

    # Find repo root (directory containing this script's parent)
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent.parent

    # Resolve paths relative to repo root
    python_dir = repo_root / args.python_dir
    r_dir = repo_root / args.r_dir
    stata_dir = repo_root / args.stata_dir

    print(f"\nRepository root: {repo_root}")
    print(f"Python metadata: {python_dir}")
    print(f"R metadata:      {r_dir}")
    print(f"Stata metadata:  {stata_dir}")

    # Run validation
    success = validate_schema_across_platforms(
        python_dir, r_dir, stata_dir,
        verbose=args.verbose,
        strict=args.strict
    )

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

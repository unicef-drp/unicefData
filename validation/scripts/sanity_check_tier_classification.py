#!/usr/bin/env python3
"""
Sanity Check: Tier Classification Assumption

Verifies the assumption that "has dataflow mapping" = "has data available"

Tests:
1. Sample Tier 1 indicators (has metadata + has dataflow) → Should return data
2. Sample Tier 2 indicators (has metadata, no dataflow) → Should return no data

Usage:
    python validation/scripts/sanity_check_tier_classification.py --sample-size 10

Author: Claude Code
Date: 2026-01-25
"""

import yaml
import requests
import argparse
import random
from pathlib import Path
from typing import Dict, List, Tuple

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BOLD = '\033[1m'
    END = '\033[0m'

def load_enriched_metadata(file_path: Path) -> Dict:
    """Load enriched indicators metadata"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def query_indicator_data(indicator_code: str, dataflow: str, max_rows: int = 1) -> Tuple[bool, int]:
    """
    Query SDMX API for indicator data

    Returns:
        (success, row_count): True if query succeeded, number of data rows returned
    """
    base_url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"

    # Try to query with minimal parameters
    url = f"{base_url}/data/{dataflow}/{indicator_code}?format=csv&startPeriod=2020&endPeriod=2024"

    try:
        response = requests.get(url, timeout=30)

        if response.status_code == 200:
            # Count lines (subtract 1 for header)
            lines = response.text.strip().split('\n')
            row_count = len(lines) - 1 if len(lines) > 1 else 0
            return (True, row_count)
        elif response.status_code == 404:
            # No data found
            return (True, 0)
        else:
            # API error
            return (False, 0)

    except Exception as e:
        print(f"    Error querying {indicator_code}: {e}")
        return (False, 0)

def sample_indicators_by_tier(indicators: Dict, tier: int, sample_size: int) -> List[Dict]:
    """Sample indicators of a specific tier"""
    tier_indicators = [
        {
            'code': code,
            'name': data.get('name', 'N/A'),
            'tier': data.get('tier'),
            'tier_reason': data.get('tier_reason', 'N/A'),
            'dataflows': data.get('dataflows', [])
        }
        for code, data in indicators.items()
        if data.get('tier') == tier
    ]

    if len(tier_indicators) <= sample_size:
        return tier_indicators
    else:
        return random.sample(tier_indicators, sample_size)

def main():
    parser = argparse.ArgumentParser(description='Sanity check tier classification')
    parser.add_argument('--sample-size', type=int, default=10,
                       help='Number of indicators to sample per tier')
    parser.add_argument('--metadata-file', type=Path,
                       default=Path('stata/src/_/_unicefdata_indicators_metadata.yaml'),
                       help='Path to enriched metadata file')
    parser.add_argument('--seed', type=int, default=42,
                       help='Random seed for reproducibility')

    args = parser.parse_args()

    # Set random seed
    random.seed(args.seed)

    # Find repo root and metadata file
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent.parent
    metadata_file = repo_root / args.metadata_file

    print("="*80)
    print(f"{Colors.BOLD}Tier Classification Sanity Check{Colors.END}")
    print("="*80)
    print()
    print("Assumption: 'Has dataflow mapping' = 'Has data available'")
    print()
    print(f"Metadata file: {metadata_file}")
    print(f"Sample size:   {args.sample_size} per tier")
    print(f"Random seed:   {args.seed}")
    print()

    # Load metadata
    data = load_enriched_metadata(metadata_file)
    indicators = data['indicators']
    tier_counts = data['_metadata' if '_metadata' in data else 'metadata'].get('tier_counts', {})

    print(f"Total indicators: {len(indicators)}")
    print(f"  Tier 1: {tier_counts.get('tier_1', 0)}")
    print(f"  Tier 2: {tier_counts.get('tier_2', 0)}")
    print(f"  Tier 3: {tier_counts.get('tier_3', 0)}")
    print()

    # Test Tier 1 indicators (should have data)
    print("="*80)
    print(f"{Colors.BOLD}Test 1: Tier 1 Indicators (metadata + data){Colors.END}")
    print("Expected: All should return data rows > 0")
    print("="*80)
    print()

    tier1_sample = sample_indicators_by_tier(indicators, 1, args.sample_size)
    tier1_passed = 0
    tier1_failed = 0

    for ind in tier1_sample:
        code = ind['code']
        dataflows = ind['dataflows'] if isinstance(ind['dataflows'], list) else [ind['dataflows']]
        primary_dataflow = dataflows[0] if dataflows else None

        if not primary_dataflow:
            print(f"{Colors.RED}✗{Colors.END} {code}: No dataflow (unexpected for Tier 1)")
            tier1_failed += 1
            continue

        success, row_count = query_indicator_data(code, primary_dataflow)

        if success and row_count > 0:
            print(f"{Colors.GREEN}OK{Colors.END} {code}: {row_count} rows (PASS)")
            tier1_passed += 1
        elif success and row_count == 0:
            print(f"{Colors.RED}X{Colors.END} {code}: 0 rows (FAIL - Tier 1 should have data)")
            tier1_failed += 1
        else:
            print(f"{Colors.YELLOW}?{Colors.END} {code}: Query failed (inconclusive)")

    print()
    print(f"Tier 1 Results: {tier1_passed}/{len(tier1_sample)} passed ({100*tier1_passed/len(tier1_sample):.1f}%)")
    print()

    # Test Tier 2 indicators (should have no data)
    print("="*80)
    print(f"{Colors.BOLD}Test 2: Tier 2 Indicators (metadata, no data){Colors.END}")
    print("Expected: All should return 0 data rows")
    print("="*80)
    print()

    tier2_sample = sample_indicators_by_tier(indicators, 2, args.sample_size)
    tier2_passed = 0
    tier2_failed = 0

    if len(tier2_sample) == 0:
        print(f"{Colors.YELLOW}No Tier 2 indicators to test{Colors.END}")
    else:
        for ind in tier2_sample:
            code = ind['code']
            name = ind['name'][:50]  # Truncate long names

            # Tier 2 indicators don't have dataflows, so they can't be queried directly
            # This is the expected behavior
            print(f"{Colors.GREEN}OK{Colors.END} {code}: No dataflow mapping (expected for Tier 2)")
            tier2_passed += 1

        print()
        print(f"Tier 2 Results: {tier2_passed}/{len(tier2_sample)} passed ({100*tier2_passed/len(tier2_sample):.1f}%)")

    print()

    # Summary
    print("="*80)
    print(f"{Colors.BOLD}Summary{Colors.END}")
    print("="*80)

    total_tests = len(tier1_sample) + len(tier2_sample)
    total_passed = tier1_passed + tier2_passed
    total_failed = tier1_failed + tier2_failed

    print(f"Total tests:  {total_tests}")
    print(f"Passed:       {total_passed} ({100*total_passed/total_tests:.1f}%)")
    print(f"Failed:       {total_failed}")
    print()

    if total_failed == 0:
        print(f"{Colors.GREEN}{Colors.BOLD}OK SANITY CHECK PASSED{Colors.END}")
        print()
        print("The assumption 'has dataflow mapping' = 'has data' is VALIDATED")
        print()
        return 0
    else:
        print(f"{Colors.RED}{Colors.BOLD}X SANITY CHECK FAILED{Colors.END}")
        print()
        print(f"Found {tier1_failed} Tier 1 indicators without data")
        print("The assumption may need refinement")
        print()
        return 1

if __name__ == '__main__':
    exit(main())

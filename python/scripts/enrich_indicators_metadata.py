#!/usr/bin/env python3
"""
Python Indicator Metadata Enrichment Script
===========================================

Enriches indicator metadata with:
- dataflows: List of dataflows containing each indicator
- tier: Classification (1=verified, 4=no dataflow)
- tier_reason: Explanation of tier assignment
- disaggregations: Available disaggregation dimensions
- disaggregations_with_totals: Dimensions that have total values

Based on Stata's enrichment pipeline but adapted for Python.

Usage:
    python enrich_indicators_metadata.py

This will:
1. Load base indicators from Stata (source of truth)
2. Load dataflow mapping from Stata
3. Load dataflow metadata from Python
4. Generate enriched metadata in Python format
5. Save to python/metadata/current/_unicefdata_indicators_metadata.yaml

Author: Claude Code
Date: 2026-01-25
"""

import yaml
import sys
from pathlib import Path
from datetime import datetime

def load_yaml(filepath):
    """Load YAML file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def save_yaml(data, filepath):
    """Save YAML file with nice formatting"""
    with open(filepath, 'w', encoding='utf-8') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

def normalize_dataflows_to_list(value):
    """Normalize dataflows field to list format"""
    if isinstance(value, str):
        return [value]
    elif isinstance(value, list):
        return value
    else:
        return []

def sort_dataflows_global_last(dataflows):
    """
    Sort dataflows alphabetically but always put GLOBAL_DATAFLOW last.

    GLOBAL_DATAFLOW is the generic catch-all dataflow with fewer disaggregation
    dimensions. More specific dataflows (NUTRITION, EDUCATION, etc.) should be
    listed first so auto-detection picks the richer dataflow.
    """
    if isinstance(dataflows, str):
        return dataflows  # Single dataflow, no sorting needed

    other_flows = sorted([df for df in dataflows if df != 'GLOBAL_DATAFLOW'])
    if 'GLOBAL_DATAFLOW' in dataflows:
        other_flows.append('GLOBAL_DATAFLOW')
    return other_flows

def classify_tier(indicator_code, has_metadata, has_data):
    """
    Classify indicator into tier based on metadata and data availability.

    Tier system (revised):
      tier 1: Has metadata + Has data (in codelist + has dataflow mapping)
      tier 2: Has metadata - No data (in codelist, no dataflow mapping)
      tier 3: No metadata + Has data (in dataflows but not in codelist)

    Args:
        indicator_code: Indicator code
        has_metadata: True if indicator exists in CL_UNICEF_INDICATOR codelist
        has_data: True if indicator has dataflow mapping

    Returns:
        tuple: (tier, tier_reason)
    """
    if has_metadata and has_data:
        return (1, "metadata_and_data")
    elif has_metadata and not has_data:
        return (2, "metadata_only_no_data")
    elif not has_metadata and has_data:
        return (3, "data_only_no_metadata")
    else:
        # Edge case: neither metadata nor data (shouldn't happen)
        return (None, "invalid_state")

def main():
    """Main enrichment pipeline"""

    print("="*80)
    print("PYTHON INDICATOR METADATA ENRICHMENT")
    print("="*80)
    print()

    # Determine paths
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent.parent

    # Input files (Stata is source of truth for indicators and dataflow map)
    stata_dir = repo_root / "stata" / "src" / "_"
    python_dir = repo_root / "python" / "metadata" / "current"

    base_indicators_file = stata_dir / "_unicefdata_indicators.yaml"
    dataflow_map_file = stata_dir / "_indicator_dataflow_map.yaml"
    dataflow_metadata_file = stata_dir / "_unicefdata_dataflow_metadata.yaml"
    output_file = python_dir / "_unicefdata_indicators_metadata.yaml"

    print(f"Inputs:")
    print(f"  Base indicators:  {base_indicators_file}")
    print(f"  Dataflow map:     {dataflow_map_file}")
    print(f"  Dataflow dims:    {dataflow_metadata_file}")
    print(f"Output:")
    print(f"  Enriched file:    {output_file}")
    print()

    # =========================================================================
    # Step 1: Load base indicator metadata
    # =========================================================================
    print("[Step 1/5] Loading base indicator metadata...")

    if not base_indicators_file.exists():
        print(f"ERROR: File not found: {base_indicators_file}", file=sys.stderr)
        return False

    base_data = load_yaml(base_indicators_file)

    if 'indicators' not in base_data:
        print("ERROR: No 'indicators' key in base metadata", file=sys.stderr)
        return False

    indicators_dict = base_data['indicators']
    print(f"  Loaded {len(indicators_dict)} indicators")

    # =========================================================================
    # Step 2: Add `dataflows` field from indicator_dataflow_map
    # =========================================================================
    print()
    print("[Step 2/5] Adding dataflows field...")

    if not dataflow_map_file.exists():
        print(f"WARNING: File not found: {dataflow_map_file}", file=sys.stderr)
        indicator_to_dataflow = {}
    else:
        dataflow_map = load_yaml(dataflow_map_file)
        indicator_to_dataflow = dataflow_map.get('indicator_to_dataflow', {})

    dataflows_added = 0
    for indicator_code, indicator_data in indicators_dict.items():
        if indicator_code in indicator_to_dataflow:
            # Sort dataflows with GLOBAL_DATAFLOW always last
            indicator_data['dataflows'] = sort_dataflows_global_last(indicator_to_dataflow[indicator_code])
            dataflows_added += 1

    print(f"  Added dataflows to {dataflows_added} indicators")

    # =========================================================================
    # Step 3: Add `tier` and `tier_reason` fields
    # =========================================================================
    print()
    print("[Step 3/5] Adding tier classification...")

    tier_counts = {1: 0, 2: 0, 3: 0}

    for indicator_code, indicator_data in indicators_dict.items():
        # All indicators from base file have metadata (from CL_UNICEF_INDICATOR)
        has_metadata = True
        # Has data if dataflow mapping exists
        has_data = indicator_code in indicator_to_dataflow and bool(indicator_to_dataflow[indicator_code])

        tier, tier_reason = classify_tier(indicator_code, has_metadata, has_data)

        indicator_data['tier'] = tier
        indicator_data['tier_reason'] = tier_reason
        tier_counts[tier] += 1

    print(f"  Tier 1 (metadata + data):     {tier_counts[1]}")
    print(f"  Tier 2 (metadata, no data):   {tier_counts[2]}")
    print(f"  Tier 3 (data, no metadata):   {tier_counts[3]}")

    # =========================================================================
    # Step 4: Add `disaggregations` and `disaggregations_with_totals` fields
    # =========================================================================
    print()
    print("[Step 4/5] Adding disaggregations...")

    if not dataflow_metadata_file.exists():
        print(f"WARNING: File not found: {dataflow_metadata_file}", file=sys.stderr)
        dataflows_dict = {}
    else:
        dataflows_metadata = load_yaml(dataflow_metadata_file)
        dataflows_dict = dataflows_metadata.get('dataflows', {})

    enriched_count = 0
    skipped_count = 0

    for indicator_code, indicator_data in indicators_dict.items():
        dataflows_value = indicator_data.get('dataflows')

        if not dataflows_value:
            skipped_count += 1
            continue

        # Normalize to list
        dataflows_list = normalize_dataflows_to_list(dataflows_value)

        # Use first dataflow (primary)
        dataflow_id = dataflows_list[0]

        if dataflow_id not in dataflows_dict:
            skipped_count += 1
            continue

        # Get dimensions for this dataflow
        dataflow_data = dataflows_dict[dataflow_id]
        if 'dimensions' not in dataflow_data or dataflow_data['dimensions'] is None:
            skipped_count += 1
            continue

        # Build disaggregations lists
        dimensions = dataflow_data['dimensions']
        all_disaggregations = []
        disaggregations_with_totals = []

        for dim_name in sorted(dimensions.keys()):
            if dim_name == 'INDICATOR':
                continue  # Skip INDICATOR dimension

            dim_values = dimensions[dim_name].get('values', [])
            has_total = '_T' in dim_values

            all_disaggregations.append(dim_name)

            if has_total:
                disaggregations_with_totals.append(dim_name)

        # Add to indicator
        if all_disaggregations:
            indicator_data['disaggregations'] = all_disaggregations
            indicator_data['disaggregations_with_totals'] = disaggregations_with_totals
            enriched_count += 1
        else:
            skipped_count += 1

    print(f"  Enriched: {enriched_count} indicators")
    print(f"  Skipped:  {skipped_count} indicators (no dataflow/dimensions)")

    # =========================================================================
    # Step 5: Create metadata header
    # =========================================================================
    print()
    print("[Step 5/5] Creating metadata header...")

    # Create enriched data structure
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    enriched_data = {
        '_metadata': {
            # Standard metadata fields
            'platform': 'python',
            'version': '2.1.0',
            'synced_at': timestamp,
            'source': 'UNICEF SDMX Codelist CL_UNICEF_INDICATOR',
            'agency': 'UNICEF',
            'content_type': 'indicators',
            # Enrichment-specific fields
            'description': 'Enriched UNICEF indicators metadata with tier classification',
            'total_indicators': len(indicators_dict),
            'indicators_with_dataflows': dataflows_added,
            'orphan_indicators': len(indicators_dict) - dataflows_added,
            'indicators_with_disaggregations': enriched_count,
            'tier_counts': {
                'tier_1': tier_counts[1],
                'tier_2': tier_counts[2],
                'tier_3': tier_counts[3],
            }
        },
        'indicators': indicators_dict
    }

    print(f"  Metadata header created")

    # =========================================================================
    # Save enriched metadata
    # =========================================================================
    print()
    print("Saving enriched metadata...")

    save_yaml(enriched_data, output_file)

    print()
    print("="*80)
    print("ENRICHMENT COMPLETE!")
    print("="*80)
    print(f"  Output: {output_file}")
    print()
    print("Summary:")
    print(f"  Total indicators:          {len(indicators_dict)}")
    print(f"  With dataflows:            {dataflows_added}")
    print(f"  With disaggregations:      {enriched_count}")
    print(f"  Tier 1 (metadata + data):  {tier_counts[1]}")
    print(f"  Tier 2 (metadata, no data):{tier_counts[2]}")
    print(f"  Tier 3 (data, no metadata):{tier_counts[3]}")
    print("="*80)

    return True

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)

#!/usr/bin/env python3
"""
Complete Stata Metadata Enrichment Pipeline
============================================

This script performs COMPLETE enrichment of Stata indicator metadata:

Phase 1: Add `dataflows` field from indicator_dataflow_map.yaml
Phase 2: Add `tier` and `tier_reason` fields by classifying indicators
Phase 3: Add `disaggregations` and `disaggregations_with_totals` fields

Input:
  - Base indicator metadata (from API): code, name, description, urn, parent
  - _indicator_dataflow_map.yaml: indicator → dataflow(s) mapping
  - _unicefdata_dataflow_metadata.yaml: dimension values per dataflow

Output:
  - Complete enriched metadata with ALL fields

Usage:
  python enrich_stata_metadata_complete.py \\
    --base-indicators ../../../python/metadata/current/unicef_indicators_metadata.yaml \\
    --dataflow-map ../_/_indicator_dataflow_map.yaml \\
    --dataflow-metadata ../_/_unicefdata_dataflow_metadata.yaml \\
    --output ../_/_unicefdata_indicators_metadata.yaml

Author: JP Azevedo / Claude Code
Date: 2026-01-24
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

def enrich_complete(base_indicators_file, dataflow_map_file, dataflow_metadata_file, output_file):
    """
    Complete enrichment pipeline.

    Steps:
      1. Load base indicator metadata
      2. Add `dataflows` field from indicator_dataflow_map
      3. Add `tier` and `tier_reason` fields
      4. Add `disaggregations` and `disaggregations_with_totals` fields
      5. Update metadata header with statistics
      6. Save enriched metadata
    """

    print("="*80)
    print("COMPLETE STATA METADATA ENRICHMENT PIPELINE")
    print("="*80)
    print()

    # =========================================================================
    # Step 1: Load base indicator metadata
    # =========================================================================
    print("[Step 1/5] Loading base indicator metadata...")
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

    tier_counts = {1: 0, 2: 0, 3: 0, 4: 0}

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
    print(f"  Tier 4 (no metadata, no data):{tier_counts[4]}")

    # =========================================================================
    # Step 4: Add `disaggregations` and `disaggregations_with_totals` fields
    # =========================================================================
    print()
    print("[Step 4/5] Adding disaggregations...")

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
        if 'dimensions' not in dataflow_data:
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
    # Step 5: Update metadata header
    # =========================================================================
    print()
    print("[Step 5/5] Updating metadata header...")

    # Create new metadata header
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    base_data['metadata'] = {
        # Standard metadata fields (required by validator)
        'platform': 'stata',
        'version': '2.1.0',
        'synced_at': timestamp,
        'source': 'UNICEF SDMX Codelist CL_UNICEF_INDICATOR',
        'agency': 'UNICEF',
        'content_type': 'indicators',
        # Enrichment-specific fields
        'url': 'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0',
        'last_updated': timestamp,
        'description': 'Complete enriched UNICEF indicators metadata (auto-generated)',
        'indicator_count': len(indicators_dict),
        'indicators_with_dataflows': dataflows_added,
        'orphan_indicators': len(indicators_dict) - dataflows_added,
        'dataflow_count': len(set(
            df for ind in indicators_dict.values()
            for df in normalize_dataflows_to_list(ind.get('dataflows'))
            if df and df != 'nodata'
        )),
        'total_indicators': len(indicators_dict),
        'tier_counts': {
            'tier_1': tier_counts[1],
            'tier_2': tier_counts[2],
            'tier_3': tier_counts[3],
            'tier_4': tier_counts[4],
        }
    }

    print(f"  Metadata header updated")

    # =========================================================================
    # Save enriched metadata
    # =========================================================================
    print()
    print("Saving enriched metadata...")
    save_yaml(base_data, output_file)

    print()
    print("="*80)
    print("ENRICHMENT COMPLETE!")
    print("="*80)
    print(f"  Input:  {base_indicators_file}")
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

def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Complete enrichment of Stata indicator metadata',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        '--base-indicators',
        required=True,
        help='Path to base unicef_indicators_metadata.yaml (from API)'
    )

    parser.add_argument(
        '--dataflow-map',
        required=True,
        help='Path to _indicator_dataflow_map.yaml'
    )

    parser.add_argument(
        '--dataflow-metadata',
        required=True,
        help='Path to _unicefdata_dataflow_metadata.yaml'
    )

    parser.add_argument(
        '--output',
        required=True,
        help='Output path for enriched metadata'
    )

    args = parser.parse_args()

    # Verify input files exist
    for file_path in [args.base_indicators, args.dataflow_map, args.dataflow_metadata]:
        if not Path(file_path).exists():
            print(f"Error: File not found: {file_path}", file=sys.stderr)
            sys.exit(1)

    # Run enrichment
    success = enrich_complete(
        args.base_indicators,
        args.dataflow_map,
        args.dataflow_metadata,
        args.output
    )

    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()

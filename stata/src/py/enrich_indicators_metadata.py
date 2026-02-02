#!/usr/bin/env python
"""
Enrich indicators metadata with disaggregation information from dataflow metadata.

Adds two fields to each indicator:
  - disaggregations: [DIM1, DIM2, ...] - all dimensions in the dataflow
  - disaggregations_with_totals: [DIM1, DIM2, ...] - dimensions that include _T value

Author: JP Azevedo
Date: 2026-01-17
"""

import yaml
import sys
from pathlib import Path

def load_yaml(filepath):
    """Load YAML file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def save_yaml(data, filepath):
    """Save YAML file with nice formatting"""
    with open(filepath, 'w', encoding='utf-8') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

def enrich_indicators_metadata(indicators_file, dataflows_file, output_file=None):
    """
    Enrich indicators metadata with disaggregations from dataflows.
    
    Args:
        indicators_file: Path to _unicefdata_indicators_metadata.yaml
        dataflows_file: Path to _unicefdata_dataflow_metadata.yaml
        output_file: Output path (defaults to indicators_file)
    """
    
    if output_file is None:
        output_file = indicators_file
    
    print("Loading metadata files...")
    indicators = load_yaml(indicators_file)
    dataflows = load_yaml(dataflows_file)
    
    if 'indicators' not in indicators:
        print("Error: No 'indicators' key in indicators metadata", file=sys.stderr)
        return False
    
    if '_metadata' not in dataflows or 'dataflows' not in dataflows:
        print("Error: Invalid dataflows metadata structure", file=sys.stderr)
        return False
    
    indicators_dict = indicators['indicators']
    dataflows_dict = dataflows['dataflows']
    
    # Build mapping of indicator -> dataflow -> dimensions
    enriched_count = 0
    skipped_count = 0
    
    print(f"\nEnriching {len(indicators_dict)} indicators...")
    
    for indicator_code, indicator_data in indicators_dict.items():
        # Get the dataflows for this indicator (can be string or list)
        dataflows_value = indicator_data.get('dataflows')

        if not dataflows_value:
            skipped_count += 1
            continue

        # Normalize to list format (handle both scalar and list)
        if isinstance(dataflows_value, str):
            dataflows_list = [dataflows_value]
        elif isinstance(dataflows_value, list):
            dataflows_list = dataflows_value
        else:
            skipped_count += 1
            continue

        # Use the first dataflow (primary one)
        dataflow_id = dataflows_list[0]
        
        if dataflow_id not in dataflows_dict:
            print(f"  WARNING: {indicator_code} - dataflow not found: {dataflow_id}")
            skipped_count += 1
            continue
        
        # Get dimensions for this dataflow
        dataflow_data = dataflows_dict[dataflow_id]
        if 'dimensions' not in dataflow_data:
            print(f"  WARNING: {indicator_code} - no dimensions in dataflow {dataflow_id}")
            skipped_count += 1
            continue
        
        # Build disaggregations list (exclude INDICATOR dimension)
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
        
        # Add disaggregations to indicator (Option 2: two separate fields)
        if all_disaggregations:
            indicator_data['disaggregations'] = all_disaggregations
            indicator_data['disaggregations_with_totals'] = disaggregations_with_totals
            enriched_count += 1
        else:
            skipped_count += 1
    
    # Save enriched metadata
    print(f"\nSaving enriched metadata...")
    save_yaml(indicators, output_file)
    
    print(f"\n{'='*80}")
    print(f"Enrichment complete!")
    print(f"  Enriched: {enriched_count} indicators")
    print(f"  Skipped: {skipped_count} indicators")
    print(f"  Output: {output_file}")
    print(f"{'='*80}\n")
    
    return True

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Enrich indicators metadata with disaggregation information',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        '--indicators',
        required=True,
        help='Path to _unicefdata_indicators_metadata.yaml'
    )
    
    parser.add_argument(
        '--dataflows',
        required=True,
        help='Path to _unicefdata_dataflow_metadata.yaml'
    )
    
    parser.add_argument(
        '--output',
        default=None,
        help='Output path (defaults to --indicators file)'
    )
    
    args = parser.parse_args()
    
    # Verify input files exist
    if not Path(args.indicators).exists():
        print(f"Error: Indicators file not found: {args.indicators}", file=sys.stderr)
        sys.exit(1)
    
    if not Path(args.dataflows).exists():
        print(f"Error: Dataflows file not found: {args.dataflows}", file=sys.stderr)
        sys.exit(1)
    
    # Run enrichment
    success = enrich_indicators_metadata(args.indicators, args.dataflows, args.output)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()

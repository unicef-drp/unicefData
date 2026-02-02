#!/usr/bin/env python3
"""
Build indicator-to-dataflow mapping by querying each UNICEF SDMX dataflow.

This script:
1. Fetches all available dataflows from UNICEF SDMX API
2. For each dataflow, queries data with detail=serieskeysonly to get indicator codes
3. Builds a mapping of indicator -> dataflow(s)
4. Outputs YAML file with the mapping

Author: João Pedro Azevedo
License: MIT
"""

import argparse
import sys
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Dict, List, Set
from collections import defaultdict

try:
    import requests
except ImportError:
    print("Error: 'requests' package required. Install with: pip install requests")
    sys.exit(1)

# SDMX API endpoints
DATAFLOW_URL = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/all/latest"
DATA_URL_TEMPLATE = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,{dataflow},1.0/all?format=sdmx-compact-2.1&detail=serieskeysonly"

# XML Namespaces
NAMESPACES = {
    'message': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message',
    'structure': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
    'common': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common',
    'generic': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/data/generic',
    'compact': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/data/compact',
}


def sort_dataflows_global_last(dataflows: List[str]) -> List[str]:
    """
    Sort dataflows alphabetically but always put GLOBAL_DATAFLOW last.
    
    GLOBAL_DATAFLOW is the generic catch-all dataflow with fewer disaggregation
    dimensions. More specific dataflows (NUTRITION, EDUCATION, etc.) should be
    listed first so auto-detection picks the richer dataflow.
    """
    other_flows = sorted([df for df in dataflows if df != 'GLOBAL_DATAFLOW'])
    if 'GLOBAL_DATAFLOW' in dataflows:
        other_flows.append('GLOBAL_DATAFLOW')
    return other_flows


def fetch_dataflows() -> List[str]:
    """Fetch all available dataflow IDs from UNICEF SDMX API."""
    print(f"Fetching dataflows from: {DATAFLOW_URL}")
    
    response = requests.get(DATAFLOW_URL, headers={'Accept': 'application/xml'}, timeout=60)
    response.raise_for_status()
    
    root = ET.fromstring(response.content)
    
    dataflows = []
    for df in root.findall('.//structure:Dataflow', NAMESPACES):
        df_id = df.get('id')
        if df_id:
            dataflows.append(df_id)
    
    print(f"  Found {len(dataflows)} dataflows")
    return sorted(dataflows)


def fetch_indicators_for_dataflow(dataflow: str) -> Set[str]:
    """Fetch all indicator codes from a dataflow using serieskeysonly."""
    url = DATA_URL_TEMPLATE.format(dataflow=dataflow)
    
    try:
        response = requests.get(url, headers={'Accept': 'application/xml'}, timeout=120)
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        if response.status_code == 404:
            print(f"    [SKIP] Dataflow {dataflow} - no data available")
            return set()
        raise
    except requests.exceptions.Timeout:
        print(f"    [TIMEOUT] Dataflow {dataflow}")
        return set()
    except Exception as e:
        print(f"    [ERROR] Dataflow {dataflow}: {e}")
        return set()
    
    indicators = set()
    
    try:
        root = ET.fromstring(response.content)
        
        # Try compact format first (most common)
        # Look for Series elements with INDICATOR attribute
        for series in root.findall('.//{http://www.sdmx.org/resources/sdmxml/schemas/v2_1/data/compact}Series'):
            indicator = series.get('INDICATOR')
            if indicator:
                indicators.add(indicator)
        
        # Also try without namespace (some responses use default namespace)
        if not indicators:
            for series in root.iter():
                if series.tag.endswith('Series'):
                    indicator = series.get('INDICATOR')
                    if indicator:
                        indicators.add(indicator)
        
        # Try generic format if compact didn't work
        if not indicators:
            for obs_key in root.findall('.//generic:SeriesKey/generic:Value[@id="INDICATOR"]', NAMESPACES):
                indicator = obs_key.get('value')
                if indicator:
                    indicators.add(indicator)
    
    except ET.ParseError as e:
        print(f"    [PARSE ERROR] Dataflow {dataflow}: {e}")
        return set()
    
    return indicators


def build_indicator_dataflow_map(dataflows: List[str], verbose: bool = True) -> Dict[str, List[str]]:
    """Build mapping of indicator code -> list of dataflows containing it."""
    indicator_to_dataflows = defaultdict(list)
    dataflow_to_indicators = {}
    
    for i, dataflow in enumerate(dataflows, 1):
        if verbose:
            print(f"  [{i}/{len(dataflows)}] Querying {dataflow}...", end=" ", flush=True)
        
        indicators = fetch_indicators_for_dataflow(dataflow)
        
        if indicators:
            dataflow_to_indicators[dataflow] = sorted(indicators)
            for indicator in indicators:
                indicator_to_dataflows[indicator].append(dataflow)
            if verbose:
                print(f"{len(indicators)} indicators")
        elif verbose:
            print("0 indicators")
    
    return dict(indicator_to_dataflows), dataflow_to_indicators


def write_yaml(output_path: str, indicator_to_dataflows: Dict[str, List[str]], 
               dataflow_to_indicators: Dict[str, List[str]]):
    """Write the mapping to a YAML file."""
    
    with open(output_path, 'w', encoding='utf-8') as f:
        # Metadata
        f.write('metadata:\n')
        f.write("  version: '1.0'\n")
        f.write('  source: UNICEF SDMX API - Dataflow series keys\n')
        f.write(f"  last_updated: {datetime.now().strftime('%Y-%m-%dT%H:%M:%S')}\n")
        f.write('  description: Mapping of indicator codes to dataflows (auto-generated from API)\n')
        f.write(f'  indicator_count: {len(indicator_to_dataflows)}\n')
        f.write(f'  dataflow_count: {len(dataflow_to_indicators)}\n')
        f.write('\n')
        
        # Indicator to dataflow mapping
        f.write('# Mapping: indicator_code -> dataflow(s)\n')
        f.write('indicator_to_dataflow:\n')
        for indicator in sorted(indicator_to_dataflows.keys()):
            dataflows = indicator_to_dataflows[indicator]
            if len(dataflows) == 1:
                f.write(f'  {indicator}: {dataflows[0]}\n')
            else:
                # Multiple dataflows - list format, GLOBAL_DATAFLOW always last
                f.write(f'  {indicator}:\n')
                for df in sort_dataflows_global_last(dataflows):
                    f.write(f'    - {df}\n')
        
        f.write('\n')
        
        # Dataflow to indicators mapping (for reference)
        f.write('# Reverse mapping: dataflow -> indicator_codes\n')
        f.write('dataflow_to_indicators:\n')
        for dataflow in sorted(dataflow_to_indicators.keys()):
            indicators = dataflow_to_indicators[dataflow]
            f.write(f'  {dataflow}:\n')
            f.write(f'    count: {len(indicators)}\n')
            f.write(f'    indicators:\n')
            for ind in indicators:
                f.write(f'      - {ind}\n')
    
    print(f"\nWritten to: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description='Build indicator-to-dataflow mapping from UNICEF SDMX API'
    )
    parser.add_argument(
        '-o', '--output',
        default='_indicator_dataflow_map.yaml',
        help='Output YAML file path (default: _indicator_dataflow_map.yaml)'
    )
    parser.add_argument(
        '--dataflows',
        nargs='+',
        help='Specific dataflows to query (default: all)'
    )
    parser.add_argument(
        '-q', '--quiet',
        action='store_true',
        help='Suppress progress output'
    )
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("Building Indicator-to-Dataflow Mapping")
    print("=" * 60)
    
    # Get dataflows
    if args.dataflows:
        dataflows = args.dataflows
        print(f"Using {len(dataflows)} specified dataflows")
    else:
        dataflows = fetch_dataflows()
    
    print()
    
    # Build mapping
    print("Querying dataflows for indicators...")
    indicator_to_dataflows, dataflow_to_indicators = build_indicator_dataflow_map(
        dataflows, verbose=not args.quiet
    )
    
    print()
    print(f"Summary:")
    print(f"  - Dataflows with data: {len(dataflow_to_indicators)}")
    print(f"  - Unique indicators: {len(indicator_to_dataflows)}")
    
    # Count indicators in multiple dataflows
    multi_df = sum(1 for dfs in indicator_to_dataflows.values() if len(dfs) > 1)
    if multi_df:
        print(f"  - Indicators in multiple dataflows: {multi_df}")
    
    # Write output
    write_yaml(args.output, indicator_to_dataflows, dataflow_to_indicators)
    
    print("\nDone!")


if __name__ == '__main__':
    main()

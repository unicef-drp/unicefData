#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build consolidated dataflow metadata from UNICEF SDMX API

Queries /data/ endpoint with serieskeysonly for each dataflow to extract
actual dimension values in use, then generates _unicefdata_dataflow_metadata.yaml

Usage:
    python build_dataflow_metadata.py --outdir <path> [--verbose] [--agency UNICEF]
    
Example:
    python build_dataflow_metadata.py --outdir "C:/Users/jpazevedo/ado/plus/_/" --verbose

Author: João Pedro Azevedo (UNICEF)
Date: January 2026
License: MIT
"""

import argparse
import sys
import io
import os
from datetime import datetime, timezone
from collections import defaultdict
import xml.etree.ElementTree as ET
import urllib.request
import urllib.error
import time
import socket

# Set UTF-8 encoding for stdout (safe for GitHub Actions)
try:
    if hasattr(sys.stdout, 'buffer') and sys.stdout.encoding != 'utf-8':
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
except Exception:
    pass  # Continue with default encoding

# Configuration
MAX_RETRIES = 3
RETRY_DELAY = 2.0  # seconds
REQUEST_DELAY = 0.5  # seconds between requests (rate limiting)
MAX_CONSECUTIVE_FAILURES = 5  # Fail fast if too many consecutive errors


def yaml_escape(value):
    """Escape a string for safe inclusion in YAML"""
    if value is None:
        return ''
    s = str(value)
    # If contains problematic characters, use double-quoted style
    if any(c in s for c in ["'", '"', ':', '#', '\n', '\r', '[', ']', '{', '}', '&', '*', '!', '|', '>', '%', '@', '`']):
        # Escape backslashes and double quotes
        s = s.replace('\\', '\\\\').replace('"', '\\"')
        return f'"{s}"'
    # Otherwise use single-quoted style
    return f"'{s}'"


def fetch_url_with_retry(url, timeout=60, max_retries=MAX_RETRIES, verbose=False):
    """Fetch URL with retry logic for transient failures"""
    last_error = None
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(url, timeout=timeout) as response:
                return response.read()
        except urllib.error.HTTPError:
            # Don't retry HTTP errors (4xx, 5xx) - they're typically permanent
            raise
        except (urllib.error.URLError, socket.timeout, ConnectionError) as e:
            last_error = e
            if verbose:
                print(f"    [!] Attempt {attempt + 1}/{max_retries} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(RETRY_DELAY * (attempt + 1))  # Exponential backoff
    raise last_error


def fetch_dataflow_list(agency="UNICEF", verbose=False):
    """Fetch list of all dataflows from SDMX API"""
    url = f"https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/{agency}?references=none&detail=full"
    
    if verbose:
        print(f"Fetching dataflow list from: {url}")
    
    try:
        xml_data = fetch_url_with_retry(url, timeout=30, verbose=verbose)
        
        root = ET.fromstring(xml_data)
        
        # Parse dataflows
        dataflows = []
        ns = {
            'str': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
            'com': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common',
            'xml': 'http://www.w3.org/XML/1998/namespace'
        }
        
        for df in root.findall('.//str:Dataflow', ns):
            df_id = df.get('id')
            df_version = df.get('version', '1.0')
            
            # Try to find English name, fallback to any name
            name_elem = df.find('.//com:Name[@xml:lang="en"]', ns)
            if name_elem is None:
                name_elem = df.find('.//com:Name', ns)
            df_name = name_elem.text if name_elem is not None else df_id
            
            dataflows.append({
                'id': df_id,
                'name': df_name,
                'version': df_version
            })
        
        if verbose:
            print(f"Found {len(dataflows)} dataflows")
        
        return dataflows
    
    except Exception as e:
        print(f"Error fetching dataflow list: {e}", file=sys.stderr)
        return []

def fetch_dataflow_dimensions(dataflow_id, dataflow_version, agency="UNICEF", verbose=False):
    """
    Query /data/ endpoint with serieskeysonly to extract actual dimension values
    
    Returns:
        dict: {dimension_name: [list of unique values]}
    """
    url = f"https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/{agency},{dataflow_id},{dataflow_version}/all?format=sdmx-compact-2.1&detail=serieskeysonly"
    
    if verbose:
        print(f"  Querying: {dataflow_id}...")
    
    try:
        xml_data = fetch_url_with_retry(url, timeout=60, verbose=verbose)
        
        root = ET.fromstring(xml_data)
        
        # Parse series keys to extract dimensions
        dimensions = defaultdict(set)
        
        # Try multiple namespace patterns (SDMX compact can vary)
        ns_patterns = [
            {'ns': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/data/compact'},
            {'generic': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/data/generic'},
            {}  # No namespace
        ]
        
        series_found = False
        for ns in ns_patterns:
            # Look for Series elements
            for series in root.findall('.//Series', ns) if not ns else root.iter('Series'):
                series_found = True
                # Extract all attributes (dimensions)
                for attr_name, attr_value in series.attrib.items():
                    # Skip non-dimension attributes
                    if attr_name in ['DATAFLOW', 'OBS_VALUE', 'TIME_PERIOD']:
                        continue
                    dimensions[attr_name].add(attr_value)
            
            if series_found:
                break
        
        # Convert sets to sorted lists
        result = {dim: sorted(list(values)) for dim, values in dimensions.items()}
        
        if verbose:
            dim_count = len(result)
            total_values = sum(len(v) for v in result.values())
            print(f"    -> {dim_count} dimensions, {total_values} unique values")
        
        return result
    
    except urllib.error.HTTPError as e:
        if verbose:
            print(f"    [!] HTTP {e.code}: {e.reason}")
        return {}
    except Exception as e:
        if verbose:
            print(f"    [!] Error: {e}")
        return {}

def build_consolidated_metadata(outdir, agency="UNICEF", verbose=False):
    """Build consolidated dataflow metadata YAML file"""
    
    # Get timestamp
    synced_at = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    
    # Fetch all dataflows
    if verbose:
        print("=" * 80)
        print("Building Consolidated Dataflow Metadata")
        print("=" * 80)
    
    dataflows = fetch_dataflow_list(agency, verbose)
    
    if not dataflows:
        print("Error: No dataflows found", file=sys.stderr)
        return False
    
    # Query each dataflow for dimensions
    all_metadata = {}
    success_count = 0
    consecutive_failures = 0
    all_indicators = set()  # Collect ALL unique indicators across all dataflows
    
    for i, df in enumerate(dataflows, 1):
        df_id = df['id']
        df_version = df['version']
        df_name = df['name']
        
        if verbose:
            print(f"\n[{i}/{len(dataflows)}] {df_id}")
        
        dimensions = fetch_dataflow_dimensions(df_id, df_version, agency, verbose)
        
        if dimensions:
            consecutive_failures = 0  # Reset on success
            # Collect indicators from this dataflow
            if 'INDICATOR' in dimensions:
                all_indicators.update(dimensions['INDICATOR'])
            
            # Calculate metadata statistics
            indicator_count = len(dimensions.get('INDICATOR', [])) if 'INDICATOR' in dimensions else 0
            
            # Calculate total number of possible series (product of all dimension value counts)
            series_count = 1
            for dim_values in dimensions.values():
                series_count *= len(dim_values)
            
            all_metadata[df_id] = {
                'name': df_name,
                'version': df_version,
                'indicator_count': indicator_count,
                'series_count': series_count,
                'dimensions': dimensions
            }
            success_count += 1
        else:
            consecutive_failures += 1
            if consecutive_failures >= MAX_CONSECUTIVE_FAILURES:
                print(f"Error: {MAX_CONSECUTIVE_FAILURES} consecutive failures - aborting", file=sys.stderr)
                break
        
        # Delay to avoid rate limiting
        time.sleep(REQUEST_DELAY)
    
    # Write YAML file
    outfile = os.path.join(outdir, "_unicefdata_dataflow_metadata.yaml")
    
    # Write indicators list to separate file for inspection
    indicators_file = os.path.join(outdir, "_dataflow_indicators_list.txt")
    
    if verbose:
        print("\n" + "=" * 80)
        print(f"Writing metadata to: {outfile}")
        print(f"Writing indicators list to: {indicators_file}")
        print(f"\nUNIQUE INDICATORS FOUND ACROSS ALL DATAFLOWS: {len(all_indicators)}")
    
    try:
        # Write indicators list (one per line, sorted)
        with open(indicators_file, 'w', encoding='utf-8') as f:
            f.write("# Unique indicators found across all UNICEF SDMX dataflows\n")
            f.write(f"# Total: {len(all_indicators)}\n")
            f.write(f"# Date: {synced_at}\n")
            f.write("# Format: One indicator code per line (sorted)\n\n")
            for indicator in sorted(all_indicators):
                f.write(f"{indicator}\n")
        
        if verbose:
            print(f"✓ Indicators list written to {indicators_file}")
        
        with open(outfile, 'w', encoding='utf-8') as f:
            # Write header
            f.write("_metadata:\n")
            f.write(f"  platform: Stata\n")
            f.write(f"  version: '2.0.0'\n")
            f.write(f"  synced_at: '{synced_at}'\n")
            f.write(f"  source: SDMX API /data/ endpoint (serieskeysonly)\n")
            f.write(f"  agency: {agency}\n")
            f.write(f"  content_type: dataflow_schemas\n")
            f.write(f"  total_dataflows: {len(dataflows)}\n")
            f.write(f"  successful_queries: {success_count}\n")
            f.write(f"  unique_indicators_in_dataflows: {len(all_indicators)}\n")
            f.write("\n")
            f.write("dataflows:\n")
            
            # Write each dataflow
            for df_id in sorted(all_metadata.keys()):
                metadata = all_metadata[df_id]
                f.write(f"  {df_id}:\n")
                f.write(f"    name: {yaml_escape(metadata['name'])}\n")
                f.write(f"    version: '{metadata['version']}'\n")
                f.write(f"    indicator_count: {metadata['indicator_count']}\n")
                f.write(f"    series_count: {metadata['series_count']}\n")
                f.write(f"    dimensions:\n")
                
                # Write dimensions
                for dim_name in sorted(metadata['dimensions'].keys()):
                    values = metadata['dimensions'][dim_name]
                    f.write(f"      {dim_name}:\n")
                    f.write(f"        values: {values}\n")
        
        if verbose:
            print(f"✓ Successfully wrote {success_count}/{len(dataflows)} dataflow schemas")
            print("=" * 80)
        
        # Fail if no dataflows were successfully processed
        if success_count == 0:
            print("Error: No dataflows were successfully processed", file=sys.stderr)
            return False
        
        return True
    
    except Exception as e:
        print(f"Error writing YAML file: {e}", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(
        description='Build consolidated dataflow metadata from UNICEF SDMX API',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        '--outdir',
        required=True,
        help='Output directory for _unicefdata_dataflow_metadata.yaml'
    )
    
    parser.add_argument(
        '--agency',
        default='UNICEF',
        help='SDMX agency code (default: UNICEF)'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Verbose output'
    )
    
    parser.add_argument(
        '--create-outdir',
        action='store_true',
        help='Create output directory if it does not exist'
    )
    
    args = parser.parse_args()
    
    # Ensure output directory exists (create if requested)
    if not os.path.isdir(args.outdir):
        if args.create_outdir:
            try:
                os.makedirs(args.outdir, exist_ok=True)
                if args.verbose:
                    print(f"Created output directory: {args.outdir}")
            except OSError as e:
                print(f"Error creating output directory: {e}", file=sys.stderr)
                sys.exit(1)
        else:
            print(f"Error: Output directory not found: {args.outdir}", file=sys.stderr)
            print("Hint: Use --create-outdir to create it", file=sys.stderr)
            sys.exit(1)
    
    # Build metadata with global exception handler
    try:
        success = build_consolidated_metadata(args.outdir, args.agency, args.verbose)
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\nInterrupted by user", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

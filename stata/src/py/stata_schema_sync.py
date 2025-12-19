#!/usr/bin/env python3
"""
stata_schema_sync.py - Generate dataflow schemas for Stata
===========================================================

Standalone Python script that generates:
1. dataflow_index.yaml - Summary of all dataflows with dimension/attribute counts
2. dataflows/*.yaml - Individual schema files for each dataflow

This script is called from Stata's unicefdata_sync.ado when the XML parsing
exceeds Stata's macro length limits.

Usage:
    python stata_schema_sync.py <output_dir> [--suffix SUFFIX] [--verbose]

Example:
    python stata_schema_sync.py stata/metadata/current --verbose
"""

import os
import sys
import argparse
import requests
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Dict, List, Optional, Any
import time

# Ensure UTF-8 output on Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# SDMX namespaces
SDMX_NS = {
    'str': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
    'mes': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message',
    'com': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common',
}

BASE_URL = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
AGENCY = "UNICEF"


def escape_yaml_string(s: str) -> str:
    """Escape special characters for YAML string values."""
    if not s:
        return ''
    s = s.replace('\\', '\\\\')
    s = s.replace("'", "''")
    s = s.replace('\n', ' ').replace('\r', '')
    return s


def get_dataflow_list(verbose: bool = False) -> List[Dict[str, str]]:
    """Get list of all UNICEF dataflows."""
    url = f"{BASE_URL}/dataflow/{AGENCY}?references=none&detail=full"
    
    if verbose:
        print(f"  Fetching dataflow list from API...")
    
    response = requests.get(url, timeout=60)
    response.raise_for_status()
    
    root = ET.fromstring(response.content)
    dataflows = []
    
    for df in root.findall('.//str:Dataflow', SDMX_NS):
        name_elem = df.find('.//com:Name', SDMX_NS)
        dataflows.append({
            'id': df.get('id'),
            'name': escape_yaml_string(name_elem.text if name_elem is not None else ''),
            'version': df.get('version', '1.0'),
            'agency': df.get('agencyID', AGENCY),
        })
    
    if verbose:
        print(f"  Found {len(dataflows)} dataflows")
    
    return dataflows


def get_dataflow_schema(dataflow_id: str, version: str = '1.0', verbose: bool = False) -> Optional[Dict[str, Any]]:
    """Fetch the Data Structure Definition (DSD) for a dataflow."""
    url = f"{BASE_URL}/dataflow/{AGENCY}/{dataflow_id}/{version}?references=all"
    
    try:
        response = requests.get(url, timeout=120)
        
        if response.status_code == 404:
            return None
            
        response.raise_for_status()
        root = ET.fromstring(response.content)
        
        # Extract dimensions
        dimensions = []
        for dim in root.findall('.//str:Dimension', SDMX_NS):
            dim_id = dim.get('id')
            position = dim.get('position')
            
            if not dim_id:
                continue
            
            # Get codelist reference
            codelist = None
            ref = dim.find('.//str:Enumeration/Ref', SDMX_NS)
            if ref is not None:
                codelist = ref.get('id')
            
            dimensions.append({
                'id': dim_id,
                'position': int(position) if position else len(dimensions) + 1,
                'codelist': codelist
            })
        
        # Sort by position
        dimensions.sort(key=lambda x: x['position'])
        
        # Extract time dimension
        time_dim = root.find('.//str:TimeDimension', SDMX_NS)
        time_dimension = time_dim.get('id', 'TIME_PERIOD') if time_dim is not None else 'TIME_PERIOD'
        
        # Extract primary measure
        primary_measure = 'OBS_VALUE'
        pm_elem = root.find('.//str:PrimaryMeasure', SDMX_NS)
        if pm_elem is not None:
            primary_measure = pm_elem.get('id', 'OBS_VALUE')
        
        # Extract attributes
        attributes = []
        for attr in root.findall('.//str:Attribute', SDMX_NS):
            attr_id = attr.get('id')
            if not attr_id:
                continue
            
            # Get codelist reference
            codelist = None
            ref = attr.find('.//str:Enumeration/Ref', SDMX_NS)
            if ref is not None:
                codelist = ref.get('id')
            
            attributes.append({
                'id': attr_id,
                'codelist': codelist
            })
        
        return {
            'dimensions': dimensions,
            'time_dimension': time_dimension,
            'primary_measure': primary_measure,
            'attributes': attributes,
        }
        
    except requests.exceptions.RequestException as e:
        if verbose:
            print(f"    Error fetching {dataflow_id}: {e}")
        return None


def write_schema_file(output_path: str, dataflow: Dict, schema: Dict, synced_at: str):
    """Write individual dataflow schema file."""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(f"id: {dataflow['id']}\n")
        f.write(f"name: '{dataflow['name']}'\n")
        f.write(f"version: '{dataflow['version']}'\n")
        f.write(f"agency: {dataflow['agency']}\n")
        f.write(f"synced_at: '{synced_at}'\n")
        
        f.write("dimensions:\n")
        for dim in schema['dimensions']:
            f.write(f"- id: {dim['id']}\n")
            f.write(f"  position: {dim['position']}\n")
            if dim.get('codelist'):
                f.write(f"  codelist: {dim['codelist']}\n")
        
        f.write(f"time_dimension: {schema['time_dimension']}\n")
        f.write(f"primary_measure: {schema['primary_measure']}\n")
        
        f.write("attributes:\n")
        for attr in schema['attributes']:
            f.write(f"- id: {attr['id']}\n")
            if attr.get('codelist'):
                f.write(f"  codelist: {attr['codelist']}\n")


def sync_schemas(output_dir: str, suffix: str = '', verbose: bool = False) -> int:
    """
    Main sync function.
    
    Returns:
        Number of successfully synced dataflows.
    """
    synced_at = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
    
    # Create output directories
    dataflows_dir = os.path.join(output_dir, f'dataflows{suffix}')
    os.makedirs(dataflows_dir, exist_ok=True)
    
    # Get dataflow list
    dataflows = get_dataflow_list(verbose=verbose)
    n_dataflows = len(dataflows)
    
    # Open index file
    index_path = os.path.join(output_dir, f'dataflow_index{suffix}.yaml')
    
    success_count = 0
    
    with open(index_path, 'w', encoding='utf-8') as index_f:
        index_f.write("metadata_version: '1.0'\n")
        index_f.write(f"synced_at: '{synced_at}'\n")
        index_f.write("source: SDMX API Data Structure Definitions\n")
        index_f.write(f"agency: {AGENCY}\n")
        index_f.write(f"total_dataflows: {n_dataflows}\n")
        index_f.write("dataflows:\n")
        
        for i, df in enumerate(dataflows, 1):
            df_id = df['id']
            df_version = df['version']
            df_name = df['name']
            
            if verbose:
                print(f"  [{i}/{n_dataflows}] {df_id}...", end='', flush=True)
            
            schema = get_dataflow_schema(df_id, df_version, verbose=verbose)
            
            if schema:
                n_dims = len(schema['dimensions'])
                n_attrs = len(schema['attributes'])
                
                # Write to index
                index_f.write(f"- id: {df_id}\n")
                index_f.write(f"  name: '{df_name}'\n")
                index_f.write(f"  version: '{df_version}'\n")
                index_f.write(f"  dimensions_count: {n_dims}\n")
                index_f.write(f"  attributes_count: {n_attrs}\n")
                
                # Write individual schema file
                schema_path = os.path.join(dataflows_dir, f'{df_id}.yaml')
                write_schema_file(schema_path, df, schema, synced_at)
                
                success_count += 1
                
                if verbose:
                    print(f" OK ({n_dims} dims, {n_attrs} attrs)")
            else:
                # Failed to fetch
                index_f.write(f"- id: {df_id}\n")
                index_f.write(f"  name: '{df_name}'\n")
                index_f.write(f"  version: '{df_version}'\n")
                index_f.write(f"  dimensions_count: null\n")
                index_f.write(f"  attributes_count: null\n")
                index_f.write(f"  error: 'Failed to fetch DSD'\n")
                
                if verbose:
                    print(f" FAILED")
            
            # Small delay to avoid rate limiting
            time.sleep(0.2)
    
    return success_count


def main():
    parser = argparse.ArgumentParser(
        description='Sync UNICEF dataflow schemas to YAML files'
    )
    parser.add_argument('output_dir', help='Output directory for metadata files')
    parser.add_argument('--suffix', default='', help='Suffix for filenames (e.g., _stataonly)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Verify output directory exists
    if not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir, exist_ok=True)
    
    if args.verbose:
        print(f"Syncing dataflow schemas to: {args.output_dir}")
    
    try:
        count = sync_schemas(args.output_dir, args.suffix, args.verbose)
        
        print(f"Success: Synced {count} dataflow schemas")
        print(f"Output: {args.output_dir}")
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

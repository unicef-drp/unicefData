"""
schema_sync.py - Sync dataflow schemas from SDMX API
=====================================================

Fetches the Data Structure Definition (DSD) for each UNICEF dataflow
and saves the dimensions and attributes to metadata/dataflow_schemas.yaml

This provides:
- Documentation of expected columns for each dataflow
- Validation reference for outputs
- Consistency between Python and R packages

Usage:
    from unicef_api.schema_sync import sync_dataflow_schemas
    sync_dataflow_schemas()
"""

import os
import yaml
import requests
import platform
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from typing import Dict, List, Optional, Any
import logging
import time

logger = logging.getLogger(__name__)

def _build_user_agent() -> str:
    """Build User-Agent string inline to avoid circular imports."""
    try:
        from unicef_api import __version__
    except ImportError:
        __version__ = "unknown"
    py_ver = platform.python_version()
    system = platform.system()
    return f"unicefData-Python/{__version__} (Python/{py_ver}; {system}) (+https://github.com/unicef-drp/unicefData)"

# SDMX namespaces
SDMX_NS = {
    'str': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
    'mes': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message',
    'com': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common',
}

# Base paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PACKAGE_DIR = os.path.dirname(SCRIPT_DIR)
# Metadata directory within the python package structure
METADATA_DIR = os.path.join(PACKAGE_DIR, 'metadata', 'current')


def get_dataflow_list(max_retries: int = 3) -> List[Dict[str, str]]:
    """Get list of all UNICEF dataflows."""
    url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF?references=none&detail=full"
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=60, headers={'User-Agent': _build_user_agent()})
            response.raise_for_status()
            
            root = ET.fromstring(response.content)
            dataflows = []
            
            for df in root.findall('.//str:Dataflow', SDMX_NS):
                name_elem = df.find('.//com:Name', SDMX_NS)
                dataflows.append({
                    'id': df.get('id'),
                    'name': name_elem.text if name_elem is not None else '',
                    'version': df.get('version', '1.0'),
                    'agency': df.get('agencyID', 'UNICEF'),
                })
            
            return dataflows
            
        except Exception as e:
            logger.warning(f"Attempt {attempt + 1}/{max_retries} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
            else:
                raise
    
    return []


def get_dataflow_schema(dataflow_id: str, version: str = '1.0', max_retries: int = 3) -> Optional[Dict[str, Any]]:
    """
    Fetch the Data Structure Definition (DSD) for a dataflow.
    
    Returns dict with dimensions, attributes, and time_dimension.
    """
    url = f"https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/{dataflow_id}/{version}?references=all"
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=120, headers={'User-Agent': _build_user_agent()})
            
            if response.status_code == 404:
                logger.warning(f"Dataflow {dataflow_id} not found (404)")
                return None
                
            response.raise_for_status()
            root = ET.fromstring(response.content)
            
            # Extract dimensions (only those with id attribute - filters out internal codelist refs)
            dimensions = []
            for dim in root.findall('.//str:Dimension', SDMX_NS):
                dim_id = dim.get('id')
                position = dim.get('position')
                
                # Skip dimensions without id (these are internal codelist references)
                if not dim_id:
                    continue
                
                # Get codelist reference
                codelist_ref = dim.find('.//str:Enumeration/Ref', SDMX_NS)
                codelist = codelist_ref.get('id') if codelist_ref is not None else None
                
                dimensions.append({
                    'id': dim_id,
                    'position': int(position) if position else None,
                    'codelist': codelist,
                })
            
            # Sort by position
            dimensions.sort(key=lambda x: x['position'] or 999)
            
            # Extract time dimension
            time_dim = root.find('.//str:TimeDimension', SDMX_NS)
            time_dimension = time_dim.get('id') if time_dim is not None else 'TIME_PERIOD'
            
            # Extract attributes
            attributes = []
            for attr in root.findall('.//str:Attribute', SDMX_NS):
                attr_id = attr.get('id')
                
                # Get codelist reference if any
                codelist_ref = attr.find('.//str:Enumeration/Ref', SDMX_NS)
                codelist = codelist_ref.get('id') if codelist_ref is not None else None
                
                attributes.append({
                    'id': attr_id,
                    'codelist': codelist,
                })
            
            # Extract primary measure (OBS_VALUE)
            primary_measure = root.find('.//str:PrimaryMeasure', SDMX_NS)
            obs_value_id = primary_measure.get('id') if primary_measure is not None else 'OBS_VALUE'
            
            return {
                'dimensions': dimensions,
                'time_dimension': time_dimension,
                'primary_measure': obs_value_id,
                'attributes': attributes,
            }
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                return None
            logger.warning(f"Attempt {attempt + 1}/{max_retries} for {dataflow_id} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
            else:
                logger.error(f"Failed to fetch schema for {dataflow_id}: {e}")
                return None
                
        except Exception as e:
            logger.warning(f"Attempt {attempt + 1}/{max_retries} for {dataflow_id} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
            else:
                logger.error(f"Failed to fetch schema for {dataflow_id}: {e}")
                return None
    
    return None


def get_sample_data(
    dataflow_id: str, 
    max_rows: int = 10000, 
    max_retries: int = 3,
    exhaustive_cols: Optional[List[str]] = None
) -> Optional[Dict[str, Dict[str, Any]]]:
    """
    Fetch sample data from a dataflow to extract values.
    
    Args:
        dataflow_id: Dataflow ID (e.g., 'CME')
        max_rows: Maximum rows to fetch for sampling
        max_retries: Number of retries
        exhaustive_cols: List of columns to extract ALL values for (from the sample),
                        instead of just top 10.
    
    Returns:
        Dict mapping column names to value statistics:
        {
            'col_name': {
                'values': ['val1', 'val2'],
                'total_count': 100,
                'is_exhaustive': False
            }
        }
    """
    if exhaustive_cols is None:
        exhaustive_cols = ['INDICATOR', 'SEX', 'AGE', 'WEALTH_QUINTILE', 'RESIDENCE', 'MATERNAL_EDU_LVL', 'UNIT_MEASURE']

    # Use CSV format for easier parsing
    url = f"https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,{dataflow_id},1.0/?format=csv&startPeriod=2020"
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=180, stream=True, headers={'User-Agent': _build_user_agent()})
            
            if response.status_code == 404:
                return None
            
            response.raise_for_status()
            
            # Parse CSV - read only first max_rows lines
            import csv
            from io import StringIO
            from collections import Counter
            
            # Get content and limit rows
            lines = response.text.split('\n')
            if len(lines) > max_rows + 1:  # +1 for header
                lines = lines[:max_rows + 1]
            
            reader = csv.DictReader(StringIO('\n'.join(lines)))
            
            # Count values for each column
            value_counts: Dict[str, Counter] = {}
            
            for row in reader:
                for col, val in row.items():
                    if col not in value_counts:
                        value_counts[col] = Counter()
                    if val and val.strip():  # Skip empty values
                        value_counts[col][val] += 1
            
            # Get values for each column
            result: Dict[str, Dict[str, Any]] = {}
            known_numeric_cols = ['OBS_VALUE', 'LOWER_BOUND', 'UPPER_BOUND', 'WGTD_SAMPL_SIZE', 'STD_ERR', 'TIME_PERIOD']
            
            for col, counter in value_counts.items():
                # Check if we should be exhaustive for this column
                is_exhaustive_col = col in exhaustive_cols
                total_unique = len(counter)
                
                # Determine if numerical
                is_numeric = False
                numeric_vals = []
                
                # 1. Try parsing content (unless it's a known categorical column)
                if not is_exhaustive_col:
                    try:
                        # Filter out common non-numeric placeholders
                        valid_keys = [k for k in counter.keys() if k and k.strip() and k.lower() not in ['nan', 'na', '..']]
                        if valid_keys:
                            # Try to convert all valid keys to float
                            parsed_vals = [float(k) for k in valid_keys]
                            # If successful, and we have values, treat as numeric
                            numeric_vals = parsed_vals
                            is_numeric = True
                    except ValueError:
                        is_numeric = False
                
                # 2. Force known numeric columns (override parsing failures for mixed content)
                if col in known_numeric_cols:
                    is_numeric = True
                    numeric_vals = []
                    for k in counter.keys():
                        try:
                            if k and k.strip() and k.lower() not in ['nan', 'na', '..']:
                                numeric_vals.append(float(k))
                        except ValueError:
                            pass

                if is_numeric and numeric_vals:
                    # Numerical handling: Return range
                    result[col] = {
                        'type': 'numerical',
                        'min': min(numeric_vals),
                        'max': max(numeric_vals),
                        'total_count': total_unique
                    }
                else:
                    # Categorical handling: Return values list
                    if is_exhaustive_col:
                        # Get ALL values found in sample, sorted
                        values = sorted(list(counter.keys()))
                        is_exhaustive = True 
                    else:
                        # Get top 10 most frequent values
                        most_common = counter.most_common(10)
                        values = [val for val, count in most_common]
                        is_exhaustive = total_unique <= 10
                    
                    result[col] = {
                        'type': 'categorical',
                        'values': values,
                        'total_count': total_unique,
                        'is_exhaustive': is_exhaustive
                    }
            
            return result
            
        except Exception as e:
            logger.warning(f"Attempt {attempt + 1}/{max_retries} for sample data {dataflow_id}: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
            else:
                logger.error(f"Failed to fetch sample data for {dataflow_id}: {e}")
                return None
    
    return None


def sync_dataflow_schemas(
    output_dir: Optional[str] = None,
    verbose: bool = True,
    dataflows: Optional[List[str]] = None,
    include_sample_values: bool = True,
) -> Dict[str, Any]:
    """
    Sync dataflow schemas from SDMX API to individual YAML files.
    
    Args:
        output_dir: Directory to save schemas (default: metadata/current)
        verbose: Print progress messages
        dataflows: List of specific dataflow IDs to sync (default: all)
        include_sample_values: Fetch sample data and include top 10 most frequent values per column
    
    Returns:
        Dict with sync results
    
    Output structure:
        metadata/current/
          dataflows/
            CME.yaml
            NUTRITION.yaml
            ...
          dataflow_index.yaml
    """
    if output_dir is None:
        output_dir = METADATA_DIR
    
    # Create dataflows subdirectory
    dataflows_dir = os.path.join(output_dir, 'dataflows')
    os.makedirs(dataflows_dir, exist_ok=True)
    
    # Get list of dataflows
    if verbose:
        print("Fetching dataflow list...")
    
    all_dataflows = get_dataflow_list()
    
    if dataflows:
        # Filter to requested dataflows
        all_dataflows = [df for df in all_dataflows if df['id'] in dataflows]
    
    if verbose:
        print(f"Found {len(all_dataflows)} dataflows to process")
    
    # Fetch schema for each dataflow
    index_entries = []
    success_count = 0
    fail_count = 0
    
    for i, df in enumerate(all_dataflows):
        df_id = df['id']
        df_version = df.get('version', '1.0')
        
        if verbose:
            print(f"  [{i+1}/{len(all_dataflows)}] Fetching schema for {df_id}...", end=' ')
        
        schema = get_dataflow_schema(df_id, df_version)
        
        if schema:
            schema_entry = {
                'id': df_id,
                'name': df['name'],
                'version': df_version,
                'agency': df.get('agency', 'UNICEF'),
                'synced_at': datetime.now(timezone.utc).isoformat(),
                'dimensions': schema['dimensions'],
                'time_dimension': schema['time_dimension'],
                'primary_measure': schema['primary_measure'],
                'attributes': schema['attributes'],
            }
            
            # Fetch sample values if requested
            if include_sample_values:
                if verbose:
                    print("fetching samples...", end=' ')
                sample_data = get_sample_data(df_id)
                if sample_data:
                    # Add sample info to each dimension
                    for dim in schema_entry['dimensions']:
                        dim_id = dim['id']
                        if dim_id in sample_data:
                            info = sample_data[dim_id]
                            if info['type'] == 'numerical':
                                dim['values_min'] = info['min']
                                dim['values_max'] = info['max']
                            else:
                                dim['values'] = info['values']
                                dim['is_exhaustive'] = info['is_exhaustive']
                            dim['total_values_count'] = info['total_count']
                    
                    # Add sample info to each attribute
                    for attr in schema_entry['attributes']:
                        attr_id = attr['id']
                        if attr_id in sample_data:
                            info = sample_data[attr_id]
                            if info['type'] == 'numerical':
                                attr['values_min'] = info['min']
                                attr['values_max'] = info['max']
                            else:
                                attr['values'] = info['values']
                                attr['is_exhaustive'] = info['is_exhaustive']
                            attr['total_values_count'] = info['total_count']
                    
                    # Add sample info to primary measure
                    pm_id = schema_entry['primary_measure']
                    if pm_id in sample_data:
                        schema_entry['primary_measure_summary'] = sample_data[pm_id]
                        
                    # Add sample info to time dimension
                    time_id = schema_entry['time_dimension']
                    if time_id in sample_data:
                        schema_entry['time_dimension_summary'] = sample_data[time_id]
            
            # Save individual dataflow schema
            df_path = os.path.join(dataflows_dir, f'{df_id}.yaml')
            with open(df_path, 'w', encoding='utf-8') as f:
                yaml.dump(schema_entry, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
            
            # Add to index
            index_entries.append({
                'id': df_id,
                'name': df['name'],
                'version': df_version,
                'dimensions_count': len(schema['dimensions']),
                'attributes_count': len(schema['attributes']),
            })
            
            success_count += 1
            if verbose:
                print(f"OK ({len(schema['dimensions'])} dims, {len(schema['attributes'])} attrs)")
        else:
            fail_count += 1
            if verbose:
                print("FAILED")
        
        # Small delay to avoid rate limiting
        time.sleep(0.2)
    
    # Save index file
    index = {
        'metadata_version': '1.0',
        'synced_at': datetime.now(timezone.utc).isoformat(),
        'source': 'SDMX API Data Structure Definitions',
        'agency': 'UNICEF',
        'total_dataflows': len(index_entries),
        'dataflows': index_entries,
    }
    
    index_path = os.path.join(output_dir, 'dataflow_index.yaml')
    with open(index_path, 'w', encoding='utf-8') as f:
        yaml.dump(index, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    
    if verbose:
        print(f"\nSaved {success_count} schemas to {dataflows_dir}/")
        print(f"Index saved to {index_path}")
        if fail_count > 0:
            print(f"  ({fail_count} dataflows failed)")
    
    return {
        'success': success_count,
        'failed': fail_count,
        'output_dir': dataflows_dir,
        'index_path': index_path,
    }


def load_dataflow_schema(dataflow_id: str, metadata_dir: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """
    Load schema for a specific dataflow from the cached YAML file.
    
    Args:
        dataflow_id: Dataflow ID (e.g., 'CME', 'NUTRITION')
        metadata_dir: Directory containing dataflows/ subdirectory
    
    Returns:
        Schema dict or None if not found
    """
    if metadata_dir is None:
        metadata_dir = METADATA_DIR
    
    # Look for individual dataflow file
    schema_path = os.path.join(metadata_dir, 'dataflows', f'{dataflow_id}.yaml')
    
    if not os.path.exists(schema_path):
        return None
    
    with open(schema_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def get_expected_columns(dataflow_id: str, metadata_dir: Optional[str] = None) -> List[str]:
    """
    Get list of expected column names for a dataflow.
    
    Args:
        dataflow_id: Dataflow ID (e.g., 'CME', 'NUTRITION')
        metadata_dir: Directory containing dataflow_schemas.yaml
    
    Returns:
        List of column names (dimensions + time + attributes)
    """
    schema = load_dataflow_schema(dataflow_id, metadata_dir)
    
    if not schema:
        return []
    
    columns = []
    
    # Add dimensions
    for dim in schema.get('dimensions', []):
        columns.append(dim['id'])
    
    # Add time dimension
    time_dim = schema.get('time_dimension', 'TIME_PERIOD')
    if time_dim not in columns:
        columns.append(time_dim)
    
    # Add primary measure
    primary = schema.get('primary_measure', 'OBS_VALUE')
    columns.append(primary)
    
    # Add attributes
    for attr in schema.get('attributes', []):
        columns.append(attr['id'])
    
    return columns


if __name__ == '__main__':
    # Run sync when executed directly
    import sys
    
    # Check for specific dataflows argument
    dataflows = None
    if len(sys.argv) > 1:
        dataflows = sys.argv[1:]
        print(f"Syncing specific dataflows: {dataflows}")
    
    result = sync_dataflow_schemas(dataflows=dataflows)
    print(f"\nDone! {result['success']} schemas synced.")

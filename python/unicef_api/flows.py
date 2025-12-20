import pandas as pd
import requests
import xml.etree.ElementTree as ET
import time

def list_dataflows(max_retries: int = 3) -> pd.DataFrame:
    """
    List all available UNICEF SDMX dataflows.
    
    Returns:
        DataFrame with columns: id, name, agency, version
    
    Example:
        >>> from unicef_api import list_dataflows
        >>> flows = list_dataflows()
        >>> print(flows.head())
    """
    
    url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF?references=none&detail=full"
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=60)
            response.raise_for_status()
            
            # Parse XML response
            root = ET.fromstring(response.content)
            
            # Extract dataflows
            ns = {'s': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure'}
            dataflows = []
            
            for df in root.findall('.//s:Dataflow', ns):
                name_elem = df.find('.//s:Name', ns)
                dataflows.append({
                    'id': df.get('id'),
                    'agency': df.get('agencyID'),
                    'version': df.get('version'),
                    'name': name_elem.text if name_elem is not None else ''
                })
            
            return pd.DataFrame(dataflows)
            
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            time.sleep(1)
    
    return pd.DataFrame()


def dataflow_schema(dataflow: str, metadata_dir: str = None) -> dict:
    """
    Get dataflow schema information (dimensions and attributes).
    
    Reads from local YAML schema files in metadata/current/dataflows/.
    
    Args:
        dataflow: The dataflow ID (e.g., "CME", "EDUCATION").
        metadata_dir: Optional path to metadata directory. Auto-detected if None.
    
    Returns:
        Dictionary with keys: id, name, version, agency, dimensions, attributes,
        time_dimension, primary_measure.
    
    Example:
        >>> from unicef_api import dataflow_schema
        >>> schema = dataflow_schema("CME")
        >>> print(schema['dimensions'])
        ['REF_AREA', 'INDICATOR', 'SEX', 'WEALTH_QUINTILE']
        >>> print(schema['attributes'])
        ['DATA_SOURCE', 'COUNTRY_NOTES', 'REF_PERIOD', ...]
    """
    import yaml
    from pathlib import Path
    import os
    
    df_upper = dataflow.upper()
    
    # Find metadata directory
    if metadata_dir is None:
        metadata_dir = _find_metadata_dir()
    
    metadata_path = Path(metadata_dir)
    schema_path = metadata_path / "dataflows" / f"{df_upper}.yaml"
    
    if not schema_path.exists():
        # Fall back to basic info from _unicefdata_dataflows.yaml
        basic = _get_basic_dataflow_info(df_upper, metadata_path)
        if basic:
            print(f"Note: Detailed schema not available for '{df_upper}'. Showing basic info.")
            return basic
        raise FileNotFoundError(
            f"Dataflow '{df_upper}' not found. Use list_dataflows() to see available dataflows."
        )
    
    # Parse YAML schema
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema = yaml.safe_load(f)
    
    # Extract dimensions (list of id values)
    dimensions = []
    if schema.get('dimensions'):
        dimensions = [d.get('id', '') for d in schema['dimensions']]
    
    # Extract attributes (list of id values)
    attributes = []
    if schema.get('attributes'):
        attributes = [a.get('id', '') for a in schema['attributes']]
    
    return {
        'id': schema.get('id', df_upper),
        'name': schema.get('name', ''),
        'version': schema.get('version', ''),
        'agency': schema.get('agency', 'UNICEF'),
        'dimensions': dimensions,
        'attributes': attributes,
        'time_dimension': schema.get('time_dimension', 'TIME_PERIOD'),
        'primary_measure': schema.get('primary_measure', 'OBS_VALUE'),
    }


def print_dataflow_schema(schema: dict) -> None:
    """
    Pretty-print a dataflow schema.
    
    Args:
        schema: Dictionary from dataflow_schema().
    
    Example:
        >>> schema = dataflow_schema("CME")
        >>> print_dataflow_schema(schema)
    """
    print()
    print("-" * 70)
    print(f"Dataflow Schema: {schema['id']}")
    print("-" * 70)
    print()
    
    if schema.get('name'):
        print(f"Name: {schema['name']}")
    if schema.get('version'):
        print(f"Version: {schema['version']}")
    if schema.get('agency'):
        print(f"Agency: {schema['agency']}")
    print()
    
    dims = schema.get('dimensions', [])
    if dims:
        print(f"Dimensions ({len(dims)}):")
        for d in dims:
            print(f"  {d}")
        print()
    
    attrs = schema.get('attributes', [])
    if attrs:
        print(f"Attributes ({len(attrs)}):")
        for a in attrs:
            print(f"  {a}")
    
    print()
    print("-" * 70)


def _find_metadata_dir() -> str:
    """Find metadata directory. Returns path as string."""
    from pathlib import Path
    import os
    
    # 1. Environment override
    env_home = os.environ.get('UNICEF_DATA_HOME_PYTHON') or os.environ.get('UNICEF_DATA_HOME', '')
    if env_home:
        metadata_dir = Path(env_home) / "metadata" / "current"
        if metadata_dir.exists():
            return str(metadata_dir)
    
    # 2. Relative to module location
    module_dir = Path(__file__).parent
    candidates = [
        module_dir / "metadata" / "current",           # unicef_api/metadata/current
        module_dir.parent / "metadata" / "current",   # python/metadata/current
    ]
    for path in candidates:
        if path.exists():
            return str(path.resolve())
    
    # 3. User home directory
    home_dir = Path.home() / ".unicef_data" / "python" / "metadata" / "current"
    if home_dir.exists():
        return str(home_dir)
    
    raise FileNotFoundError("Could not find metadata directory. Run sync_metadata() first.")


def _get_basic_dataflow_info(dataflow: str, metadata_path) -> dict:
    """Get basic dataflow info from _unicefdata_dataflows.yaml."""
    import yaml
    from pathlib import Path
    
    df_file = Path(metadata_path) / "_unicefdata_dataflows.yaml"
    if not df_file.exists():
        return None
    
    with open(df_file, 'r', encoding='utf-8') as f:
        all_flows = yaml.safe_load(f)
    
    if dataflow in all_flows:
        info = all_flows[dataflow]
        return {
            'id': dataflow,
            'name': info.get('name', ''),
            'version': info.get('version', ''),
            'agency': 'UNICEF',
            'dimensions': [],
            'attributes': [],
        }
    return None

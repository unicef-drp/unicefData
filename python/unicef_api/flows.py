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

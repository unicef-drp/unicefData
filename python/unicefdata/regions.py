"""
Country and Region Grouping Functions
=====================================

Retrieves dynamic country and region grouping data from the Solr index.
"""

import os
import io
import requests
import pandas as pd

def _get_solr_credentials() -> tuple:
    """Helper to retrieve Solr credentials from environment variables, falling back to defaults."""
    user = os.environ.get("UNICEF_SOLR_USER", "DAPMRead")
    passwd = os.environ.get("UNICEF_SOLR_PASS", "solrread!")
    return user, passwd

def get_regions_metadata() -> pd.DataFrame:
    """
    Get all available source_agency, aggregate_type, and aggregate_type_id.
    
    Returns:
        DataFrame with columns: source_agency, aggregate_type, aggregate_type_id
    """
    user, passwd = _get_solr_credentials()
    url = "https://ss529626-pa5e13zk-westeurope-azure.searchstax.com/solr/country_regions_metadata/select"
    params = {
        "q": "*:*",
        "rows": 0,
        "facet": "true",
        "facet.pivot": "source_agency,aggregate_type,aggregate_type_id",
        "wt": "json"
    }
    
    response = requests.get(url, params=params, auth=(user, passwd), timeout=60)
    response.raise_for_status()
    
    data = response.json()
    pivots = data.get("facet_counts", {}).get("facet_pivot", {}).get("source_agency,aggregate_type,aggregate_type_id", [])
    
    records = []
    for agency_node in pivots:
        agency = agency_node.get("value")
        for type_node in agency_node.get("pivot", []):
            agg_type = type_node.get("value")
            for id_node in type_node.get("pivot", []):
                agg_type_id = id_node.get("value")
                records.append({
                    "source_agency": agency,
                    "aggregate_type": agg_type,
                    "aggregate_type_id": agg_type_id
                })
                
    return pd.DataFrame(records)

def get_regions(source_agency: str = None, aggregate_type_id: str = None, is_latest: bool = False) -> pd.DataFrame:
    """
    Get country and region grouping data from the Solr index.
    
    Args:
        source_agency: Optional source agency filter (e.g., 'UNICEF').
        aggregate_type_id: Optional aggregate type ID filter (e.g., 'UNICEF_PROG_REG_GLOBAL').
        is_latest: Optional boolean filter. If True, returns only the latest active data.
        
    Returns:
        DataFrame containing regions and component countries.
    """
    user, passwd = _get_solr_credentials()
    url = "https://ss529626-pa5e13zk-westeurope-azure.searchstax.com/solr/country_regions_metadata/select"
    params = {
        "q": "*:*",
        "rows": 20000,
        "wt": "csv"
    }
    
    fq = []
    if is_latest:
        fq.append("is_latest:true")
    if source_agency:
        fq.append(f"source_agency:{source_agency}")
    if aggregate_type_id:
        fq.append(f"aggregate_type_id:{aggregate_type_id}")
        
    if fq:
        params["fq"] = fq
        
    response = requests.get(url, params=params, auth=(user, passwd), timeout=60)
    response.raise_for_status()
    
    return pd.read_csv(io.StringIO(response.text), dtype={"country_m49": str})

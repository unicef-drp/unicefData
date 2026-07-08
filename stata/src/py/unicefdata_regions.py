import os
import sys
import argparse
import requests
import pandas as pd
import json

def get_credentials():
    user = os.environ.get("UNICEF_SOLR_USER", "DAPMRead")
    passwd = os.environ.get("UNICEF_SOLR_PASS", "solrread!")
    return user, passwd

def run_metadata(output_file):
    user, passwd = get_credentials()
    url = "https://ss529626-pa5e13zk-westeurope-azure.searchstax.com/solr/country_regions_metadata/select"
    params = {
        "q": "*:*",
        "rows": 0,
        "facet": "true",
        "facet.pivot": "source_agency,aggregate_type,aggregate_type_id",
        "wt": "json"
    }
    
    try:
        response = requests.get(url, params=params, auth=(user, passwd), timeout=60)
        response.raise_for_status()
        
        data = response.json()
        pivots = data.get("facet_counts", {}).get("facet_pivots", {}).get("source_agency,aggregate_type,aggregate_type_id", [])
        
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
                    
        df = pd.DataFrame(records)
        df.to_csv(output_file, index=False)
        print(f"Success: Metadata written to {output_file}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

def run_regions(output_file, source_agency, aggregate_type_id, is_latest):
    user, passwd = get_credentials()
    url = "https://ss529626-pa5e13zk-westeurope-azure.searchstax.com/solr/country_regions_metadata/select"
    params = {
        "q": "*:*",
        "rows": 1000000,
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
        
    try:
        response = requests.get(url, params=params, auth=(user, passwd), timeout=60)
        response.raise_for_status()
        
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(response.text)
        print(f"Success: Regions data written to {output_file}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Query Solr country/region groupings for Stata.")
    parser.add_argument("--action", required=True, choices=["metadata", "regions"], help="Action to perform")
    parser.add_argument("--output", required=True, help="Output CSV file path")
    parser.add_argument("--agency", help="Filter by source agency")
    parser.add_argument("--type", help="Filter by aggregate type ID")
    parser.add_argument("--latest", action="store_true", help="Filter by latest active regions only")
    
    args = parser.parse_args()
    
    if args.action == "metadata":
        run_metadata(args.output)
    elif args.action == "regions":
        run_regions(args.output, args.agency, args.type, args.latest)

if __name__ == "__main__":
    main()

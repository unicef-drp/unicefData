from unicef_api.schema_sync import sync_dataflow_schemas
from unicef_api.indicator_registry import refresh_indicator_cache

if __name__ == "__main__":
    print("Starting metadata sync...")
    
    # 1. Sync dataflow schemas (dataflow_index.yaml + dataflows/*.yaml)
    print("\n[1/2] Syncing dataflow schemas with hybrid sampling...")
    sync_dataflow_schemas()
    print("Schema sync complete.")
    
    # 2. Sync indicator registry (unicef_indicators_metadata.yaml)
    print("\n[2/2] Syncing indicator registry from CL_UNICEF_INDICATOR codelist...")
    try:
        count = refresh_indicator_cache()
        print(f"Indicator registry sync complete: {count} indicators cached.")
    except Exception as e:
        print(f"WARNING: Indicator registry sync failed: {e}")
    
    print("\nAll metadata sync complete.")

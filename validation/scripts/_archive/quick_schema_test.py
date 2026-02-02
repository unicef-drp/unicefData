#!/usr/bin/env python3
"""Quick test of schema-aware URL construction - single indicator."""

import os
import sys
import pandas as pd
from typing import Optional

# Add Python src to path
REPO_ROOT = os.path.abspath(os.path.dirname(__file__))
PYTHON_SRC = os.path.join(REPO_ROOT, "..", "..", "python")
if PYTHON_SRC not in sys.path:
    sys.path.insert(0, PYTHON_SRC)

from unicef_api.sdmx_client import UNICEFSDMXClient

def test_single_indicator(indicator: str, year: Optional[int] = None):
    """Test fetching a single indicator with schema-aware URL construction."""
    client = UNICEFSDMXClient()
    
    # Fetch with schema-aware key
    print(f"\nTesting: {indicator} (year={year})")
    print("-" * 60)
    
    # Build the URL key
    if indicator.startswith("WS_HCF_"):
        dataflow = "WASH_HEALTHCARE_FACILITY"
    else:
        # Auto-detect from metadata
        # Use the client's built-in metadata to find the dataflow
        indicator_upper = indicator.upper()
        # Check metadata
        if hasattr(client.metadata_manager, 'indicators_metadata'):
            ind_meta = client.metadata_manager.indicators_metadata.get("indicators", {}).get(indicator_upper, {})
            dataflow = ind_meta.get("dataflow", "GLOBAL_DATAFLOW")
        else:
            dataflow = "GLOBAL_DATAFLOW"
    
    key = client._build_schema_aware_key(indicator, dataflow, "_T")
    print(f"URL Key: {key}")
    
    # Fetch
    try:
        start_year = year if year else None
        end_year = year if year else None
        df = client.fetch_indicator(
            indicator,
            start_year=start_year,
            end_year=end_year,
            dataflow=dataflow
        )
        
        print(f"[OK] Success: {len(df)} rows fetched")
        print(f"  Dataflow: {dataflow}")
        print(f"  URL: {client._last_url}")
        
        return len(df)
        
    except Exception as e:
        print(f"[ERROR] {e}")
        return None

if __name__ == "__main__":
    # Test indicators
    tests = [
        ("ECD_CHLD_U5_BKS-HM", None),
        ("ED_MAT_G23", None),
        ("CME_MRY0T4", 2020),
    ]
    
    print("=" * 60)
    print("SCHEMA-AWARE URL CONSTRUCTION TEST")
    print("=" * 60)
    
    results = {}
    for indicator, year in tests:
        row_count = test_single_indicator(indicator, year)
        if row_count is not None:
            results[indicator] = row_count
    
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    for indicator, count in results.items():
        print(f"{indicator:30} {count:6} rows")

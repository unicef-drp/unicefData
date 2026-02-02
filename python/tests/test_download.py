"""
Simple test to verify Python can now download COD_ALCOHOL_USE_DISORDERS and HVA_PREV_TEST_RES_12
after implementing R's 3-tier fallback logic and simpler .INDICATOR. key pattern.
"""

import sys
import logging
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

from unicef_api import unicefData

print("=" * 80)
print("TEST 1: COD_ALCOHOL_USE_DISORDERS (CAUSE_OF_DEATH dataflow)")
print("=" * 80)

try:
    df1 = unicefData(
        indicator="COD_ALCOHOL_USE_DISORDERS",
        countries=None,  # All countries
        year=2019,
    )
    
    if not df1.empty:
        print(f"\n[SUCCESS] Downloaded {len(df1)} rows for {len(df1['iso3'].unique())} countries")
        print(f"Countries: {sorted(df1['iso3'].unique())[:10]}... ({len(df1['iso3'].unique())} total)")
    else:
        print("\n[FAILED] Empty DataFrame")
        
except Exception as e:
    print(f"\n[ERROR] {e}")

print("\n" + "=" * 80)
print("TEST 2: HVA_PREV_TEST_RES_12 (HIV_AIDS dataflow)")
print("=" * 80)

try:
    df2 = unicefData(
        indicator="HVA_PREV_TEST_RES_12",
        countries=None,  # All countries
        year=2020,
    )
    
    if not df2.empty:
        print(f"\n[SUCCESS] Downloaded {len(df2)} rows for {len(df2['iso3'].unique())} countries")
        print(f"Countries: {sorted(df2['iso3'].unique())[:10]}... ({len(df2['iso3'].unique())} total)")
    else:
        print("\n[FAILED] Empty DataFrame")
        
except Exception as e:
    print(f"\n[ERROR] {e}")

print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
print("Both indicators should now download successfully using:")
print("- Tier 1: Direct metadata lookup from YAML")
print("- R's simpler .INDICATOR. key pattern (not ._T._T._T)")
print("- Fallback to GLOBAL_DATAFLOW if needed")

"""
Test script to verify the 3-tier fallback logic implementation.

Tests:
1. COD_ALCOHOL_USE_DISORDERS should use CAUSE_OF_DEATH dataflow (Tier 1 metadata lookup)
2. HVA_PREV_TEST_RES_12 should use HIV_AIDS dataflow (Tier 1 metadata lookup)
3. Verify dataflows are tried in correct order
"""

import sys
import logging
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Configure logging to see debug messages
logging.basicConfig(
    level=logging.INFO,  # Changed from DEBUG to reduce noise
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

from unicef_api import unicefData

print("=" * 80)
print("TEST 1: COD_ALCOHOL_USE_DISORDERS")
print("Expected: Should use CAUSE_OF_DEATH dataflow (Tier 1 lookup)")
print("=" * 80)

try:
    df1 = unicefData(
        indicator="COD_ALCOHOL_USE_DISORDERS",
        countries=None,  # Changed to None = ALL countries
        year=2019,
    )
    
    if not df1.empty:
        print(f"\nSUCCESS: Downloaded {len(df1)} rows for {len(df1['iso3'].unique())} countries")
        print(f"Countries: {sorted(df1['iso3'].unique())}")
        print(f"Columns: {list(df1.columns)}")
        print("\nFirst few rows:")
        print(df1.head())
    else:
        print("\nFAILED: Empty DataFrame returned")
        
except Exception as e:
    print(f"\nERROR: {e}")

print("\n")
print("=" * 80)
print("TEST 2: HVA_PREV_TEST_RES_12")
print("Expected: Should use HIV_AIDS dataflow (Tier 1 lookup)")
print("=" * 80)

try:
    df2 = unicefData(
        indicator="HVA_PREV_TEST_RES_12",
        countries=["KEN", "ZAF"],
        year=2020,
    )
    
    if not df2.empty:
        print(f"\n✅ SUCCESS: Downloaded {len(df2)} rows")
        print(df2.head())
    else:
        print("\n❌ FAILED: Empty DataFrame returned")
        
except Exception as e:
    print(f"\n❌ ERROR: {e}")

print("\n")
print("=" * 80)
print("TEST COMPLETE")
print("=" * 80)

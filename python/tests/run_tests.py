"""
Comprehensive test suite for unicef_api package
Tests all major functionality and saves results to CSV files
"""

import os
import sys
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from unicef_api import get_unicef, list_dataflows, COMMON_INDICATORS, list_vintages
from unicef_api.metadata import sync_metadata, MetadataSync

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

def test_list_dataflows():
    """Test listing available dataflows via list_dataflows()"""
    log("Testing list_dataflows()...")
    
    # Use the actual list_dataflows function to ensure consistent output
    df = list_dataflows()
    
    log(f"  Found {len(df)} dataflows")
    
    # Save to CSV - columns should be: id, agency, version, name
    df.to_csv(os.path.join(OUTPUT_DIR, 'test_dataflows.csv'), index=False)
    log(f"  Saved to test_dataflows.csv")
    
    return len(df) > 50  # Should have 60+ dataflows

def test_child_mortality():
    """Test fetching child mortality data (CME_MRY0T4)"""
    log("Testing child mortality (CME_MRY0T4)...")
    
    # Use get_unicef() for consistent column names with R
    df = get_unicef(
        indicator='CME_MRY0T4',
        countries=['USA', 'GBR', 'FRA', 'DEU', 'JPN'],
        start_year=2015,
        end_year=2023
    )
    
    log(f"  Retrieved {len(df)} observations")
    if len(df) > 0:
        log(f"  Countries: {df['iso3'].unique().tolist()}")
        log(f"  Years: {sorted(df['period'].unique().tolist())}")
    
    df.to_csv(os.path.join(OUTPUT_DIR, 'test_mortality.csv'), index=False)
    log(f"  Saved to test_mortality.csv")
    
    return len(df) > 0

def test_stunting():
    """Test fetching stunting data (NT_ANT_HAZ_NE2)"""
    log("Testing stunting (NT_ANT_HAZ_NE2)...")
    
    # Use get_unicef() for consistent column names with R
    df = get_unicef(
        indicator='NT_ANT_HAZ_NE2',
        countries=['IND', 'BGD', 'PAK', 'NPL', 'ETH'],
        start_year=2010,
        end_year=2023
    )
    
    log(f"  Retrieved {len(df)} observations")
    
    df.to_csv(os.path.join(OUTPUT_DIR, 'test_stunting.csv'), index=False)
    log(f"  Saved to test_stunting.csv")
    
    return len(df) > 0

def test_immunization():
    """Test fetching immunization data (IM_DTP3)"""
    log("Testing immunization (IM_DTP3)...")
    
    # Use get_unicef() for consistent column names with R
    df = get_unicef(
        indicator='IM_DTP3',
        countries=['NGA', 'COD', 'BRA', 'IDN', 'MEX'],
        start_year=2015,
        end_year=2023
    )
    
    log(f"  Retrieved {len(df)} observations")
    
    df.to_csv(os.path.join(OUTPUT_DIR, 'test_immunization.csv'), index=False)
    log(f"  Saved to test_immunization.csv")
    
    return len(df) > 0

def test_metadata_sync():
    """Test metadata sync functionality"""
    log("Testing metadata sync...")
    
    cache_dir = os.path.join(OUTPUT_DIR, 'metadata_sync_test')
    sync = MetadataSync(cache_dir=cache_dir)
    results = sync.sync_all(verbose=False)
    
    log(f"  Synced: {results.get('dataflows', 0)} dataflows, {results.get('indicators', 0)} indicators")
    
    # Test vintage listing
    vintages = sync.list_vintages()
    log(f"  Vintages available: {vintages}")
    
    return results.get('dataflows', 0) > 50

def test_multiple_indicators():
    """Test fetching multiple indicators at once"""
    log("Testing multiple indicators...")
    
    indicators = ['CME_MRY0T4', 'CME_MRY0']  # Under-5 and infant mortality
    all_data = []
    
    for ind in indicators:
        try:
            # Use get_unicef() for consistent column names with R
            df = get_unicef(
                indicator=ind,
                countries=['BRA', 'IND', 'CHN'],
                start_year=2020,
                end_year=2023
            )
            all_data.append(df)
            log(f"  {ind}: {len(df)} observations")
        except Exception as e:
            log(f"  {ind}: ERROR - {e}")
    
    if all_data:
        import pandas as pd
        combined = pd.concat(all_data, ignore_index=True)
        combined.to_csv(os.path.join(OUTPUT_DIR, 'test_multiple_indicators.csv'), index=False)
        log(f"  Saved {len(combined)} total observations")
        return True
    return False

def run_all_tests():
    """Run all tests and report results"""
    print("=" * 60)
    print("UNICEF API Python Package Test Suite")
    print(f"Started: {datetime.now()}")
    print("=" * 60)
    
    tests = [
        ("List Dataflows", test_list_dataflows),
        ("Child Mortality", test_child_mortality),
        ("Stunting", test_stunting),
        ("Immunization", test_immunization),
        ("Metadata Sync", test_metadata_sync),
        ("Multiple Indicators", test_multiple_indicators),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, "PASS" if passed else "FAIL", None))
        except Exception as e:
            results.append((name, "ERROR", str(e)))
            log(f"  ERROR: {e}")
    
    print("\n" + "=" * 60)
    print("TEST RESULTS")
    print("=" * 60)
    
    for name, status, error in results:
        icon = "✅" if status == "PASS" else "❌"
        print(f"{icon} {name}: {status}")
        if error:
            print(f"   Error: {error}")
    
    passed = sum(1 for _, s, _ in results if s == "PASS")
    total = len(results)
    print(f"\nTotal: {passed}/{total} tests passed")
    print("=" * 60)
    
    return passed == total

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)

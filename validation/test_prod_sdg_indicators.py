"""
Test Script: Replicate PROD-SDG-REP-2025 Indicator Downloads
=============================================================

This script tests the get_unicef() function by downloading all indicators
used in the PROD-SDG-REP-2025 project's 0121_get_data_api.R script.

Original indicators extracted from:
D:\jazevedo\GitHub\others\PROD-SDG-REP-2025\01_data_prep\012_codes\0121_get_data_api.R

Author: Joao Pedro Azevedo
Date: December 2024
"""

import sys
import os
import time
from datetime import datetime

# Add the python package to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'python'))

from unicef_api import get_unicef, search_indicators, list_categories

# =============================================================================
# INDICATOR DEFINITIONS (from 0121_get_data_api.R)
# =============================================================================

PROD_SDG_INDICATORS = {
    # Mortality (CME dataflow)
    "mortality": {
        "indicators": ["CME_MRM0", "CME_MRY0T4"],
        "dataflow": "CME",
        "output_file": "api_unf_mort.csv"
    },
    
    # Nutrition (NUTRITION dataflow)
    "nutrition": {
        "indicators": ["NT_ANT_HAZ_NE2_MOD", "NT_ANT_WHZ_NE2", "NT_ANT_WHZ_PO2_MOD"],
        "dataflow": "NUTRITION",
        "output_file": "api_unf_nutr.csv"
    },
    
    # Wasting (subset of nutrition)
    "wasting": {
        "indicators": ["NT_ANT_WHZ_NE2"],
        "dataflow": "NUTRITION",
        "output_file": "api_unf_nutr_wast.csv"
    },
    
    # Anaemia (commented out in original but included for completeness)
    "anaemia": {
        "indicators": ["NT_ANE_WOM_15_49_MOD"],
        "dataflow": "NUTRITION",
        "output_file": "api_unf_anaem.csv"
    },
    
    # Education (EDUCATION_UIS_SDG dataflow)
    # Note: Must use explicit dataflow - auto-detection finds wrong dataflow
    "education": {
        "indicators": [
            "ED_ANAR_L02",
            "ED_CR_L1_UIS_MOD", "ED_CR_L2_UIS_MOD", "ED_CR_L3_UIS_MOD",
            "ED_MAT_G23", "ED_MAT_L1", "ED_MAT_L2",
            "ED_READ_G23", "ED_READ_L1", "ED_READ_L2",
            "ED_ROFST_L1_UIS_MOD", "ED_ROFST_L2_UIS_MOD", "ED_ROFST_L3_UIS_MOD"
        ],
        "dataflow": "EDUCATION_UIS_SDG",
        "explicit_dataflow": True,  # Must specify this dataflow explicitly
        "output_file": "api_unf_edu.csv"
    },
    
    # Immunization (IMMUNISATION dataflow)
    "immunization": {
        "indicators": ["IM_DTP3", "IM_MCV1"],
        "dataflow": "IMMUNISATION",
        "output_file": "api_unf_immun.csv"
    },
    
    # HIV/AIDS (HIV_AIDS dataflow)
    "hiv": {
        "indicators": ["HVA_EPI_INF_RT"],
        "dataflow": "HIV_AIDS",
        "output_file": "api_unf_hiv.csv"
    },
    
    # WASH (WASH_HOUSEHOLDS dataflow)
    "wash": {
        "indicators": [
            "WS_PPL_H-B",
            "WS_PPL_S-ALB", "WS_PPL_S-OD", "WS_PPL_S-SM",
            "WS_PPL_W-ALB", "WS_PPL_W-SM"
        ],
        "dataflow": "WASH_HOUSEHOLDS",
        "output_file": "api_unf_wash.csv"
    },
    
    # Maternal, Newborn and Child Health (MNCH dataflow)
    "mnch": {
        "indicators": ["MNCH_ABR", "MNCH_INFDEC", "MNCH_MMR", "MNCH_SAB", "MNCH_UHC"],
        "dataflow": "MNCH",
        "output_file": "api_unf_mnch.csv"
    },
    
    # Child Protection (PT dataflow)
    "child_protection": {
        "indicators": [
            "PT_CHLD_1-14_PS-PSY-V_CGVR",
            "PT_CHLD_Y0T4_REG",
            "PT_F_18-29_SX-V_AGE-18",
            "PT_M_18-29_SX-V_AGE-18"
        ],
        "dataflow": "PT",
        "output_file": "api_unf_cp.csv"
    },
    
    # Early Childhood Development (ECD dataflow)
    "ecd": {
        "indicators": ["ECD_CHLD_LMPSL"],
        "dataflow": "ECD",
        "output_file": "api_unf_ecd.csv"
    },
    
    # Child Marriage (PT_CM dataflow)
    # Note: Must use explicit dataflow
    "child_marriage": {
        "indicators": ["PT_F_20-24_MRD_U18_TND"],
        "dataflow": "PT_CM",
        "explicit_dataflow": True,
        "output_file": "api_unf_chmrg.csv"
    },
    
    # Female Genital Mutilation (PT_FGM dataflow)
    # Note: Must use explicit dataflow
    "fgm": {
        "indicators": ["PT_F_15-49_FGM"],
        "dataflow": "PT_FGM",
        "explicit_dataflow": True,
        "output_file": "api_unf_fgm.csv"
    },
    
    # Child Poverty (CHLD_PVTY dataflow)
    "child_poverty": {
        "indicators": ["PV_CHLD_DPRV-S-L1-HS"],
        "dataflow": "CHLD_PVTY",
        "output_file": "api_unf_pov.csv"
    },
    
    # Intimate Partner Violence (PT dataflow)
    # Note: This indicator returns 404 - may be deprecated or have no data
    "ipfm": {
        "indicators": ["PT_F_PS-SX_V_PTNR_12MNTH"],
        "dataflow": "PT",
        "output_file": "api_unf_ipfm.csv",
        "known_issue": "Indicator may be deprecated - returns 404"
    }
}


def test_single_indicator_download(category_name, category_info, verbose=True):
    """Test downloading a single category of indicators."""
    
    indicators = category_info["indicators"]
    expected_dataflow = category_info["dataflow"]
    use_explicit_dataflow = category_info.get("explicit_dataflow", False)
    
    if verbose:
        print(f"\n{'='*60}")
        print(f"Testing: {category_name.upper()}")
        print(f"{'='*60}")
        print(f"Indicators: {indicators}")
        print(f"Expected dataflow: {expected_dataflow}")
        if use_explicit_dataflow:
            print(f"Using explicit dataflow: Yes (auto-detection unreliable)")
    
    start_time = time.time()
    
    try:
        # Use explicit dataflow if specified, otherwise let auto-detect work
        if use_explicit_dataflow:
            df = get_unicef(
                indicator=indicators,
                dataflow=expected_dataflow
            )
        else:
            df = get_unicef(
                indicator=indicators,
                # Don't specify dataflow - let it auto-detect
            )
        
        elapsed = time.time() - start_time
        
        if df.empty:
            print(f"  ⚠️  WARNING: Empty DataFrame returned")
            return {
                "category": category_name,
                "status": "warning",
                "message": "Empty DataFrame",
                "rows": 0,
                "time": elapsed
            }
        
        # Get unique indicators returned
        if 'indicator' in df.columns:
            returned_indicators = df['indicator'].unique().tolist()
        elif 'indicator_code' in df.columns:
            returned_indicators = df['indicator_code'].unique().tolist()
        else:
            returned_indicators = ["unknown"]
        
        # Get unique countries
        if 'iso3' in df.columns:
            n_countries = df['iso3'].nunique()
        elif 'country_code' in df.columns:
            n_countries = df['country_code'].nunique()
        else:
            n_countries = 0
        
        if verbose:
            print(f"  [OK] SUCCESS")
            print(f"     Rows: {len(df):,}")
            print(f"     Countries: {n_countries}")
            print(f"     Indicators returned: {returned_indicators}")
            print(f"     Time: {elapsed:.2f}s")
            print(f"     Columns: {df.columns.tolist()}")
        
        return {
            "category": category_name,
            "status": "success",
            "rows": len(df),
            "countries": n_countries,
            "indicators_requested": indicators,
            "indicators_returned": returned_indicators,
            "time": elapsed,
            "dataframe": df
        }
        
    except Exception as e:
        elapsed = time.time() - start_time
        error_msg = str(e)
        
        if verbose:
            print(f"  [FAIL] FAILED: {error_msg[:100]}")
        
        return {
            "category": category_name,
            "status": "failed",
            "error": error_msg,
            "time": elapsed
        }


def run_all_tests(verbose=True):
    """Run tests for all PROD-SDG indicators."""
    
    print("=" * 70)
    print("PROD-SDG-REP-2025 Indicator Download Test")
    print(f"Testing {len(PROD_SDG_INDICATORS)} indicator categories")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)
    
    results = []
    total_start = time.time()
    
    for category_name, category_info in PROD_SDG_INDICATORS.items():
        result = test_single_indicator_download(category_name, category_info, verbose)
        results.append(result)
        
        # Small delay between API calls to be nice to the server
        time.sleep(0.5)
    
    total_time = time.time() - total_start
    
    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    
    success = [r for r in results if r["status"] == "success"]
    warnings = [r for r in results if r["status"] == "warning"]
    failed = [r for r in results if r["status"] == "failed"]
    
    print(f"\n[OK] Successful: {len(success)}/{len(results)}")
    print(f"[WARN] Warnings:   {len(warnings)}/{len(results)}")
    print(f"[FAIL] Failed:      {len(failed)}/{len(results)}")
    
    if success:
        total_rows = sum(r.get("rows", 0) for r in success)
        print(f"\n[DATA] Total rows downloaded: {total_rows:,}")
    
    print(f"\n[TIME] Total time: {total_time:.1f}s")
    
    if failed:
        print("\n[FAIL] Failed categories:")
        for r in failed:
            print(f"   - {r['category']}: {r.get('error', 'Unknown error')[:80]}")
    
    return results


def test_indicator_discovery():
    """Test that we can find all indicators using search_indicators()."""
    
    print("\n" + "=" * 70)
    print("INDICATOR DISCOVERY TEST")
    print("=" * 70)
    
    # Flatten all indicators
    all_indicators = []
    for category_info in PROD_SDG_INDICATORS.values():
        all_indicators.extend(category_info["indicators"])
    
    print(f"\nTotal unique indicators to find: {len(set(all_indicators))}")
    
    # Test search for key terms
    search_terms = ["mortality", "stunting", "immunization", "education", "poverty"]
    
    for term in search_terms:
        print(f"\n[SEARCH] Searching for '{term}':")
        search_indicators(term, limit=3)


def compare_with_original(category_name, category_info):
    """
    Download data using get_unicef() and compare row counts with 
    what the original URLs would return.
    """
    import requests
    import pandas as pd
    from io import StringIO
    
    # Build original-style URL (simplified)
    dataflow = category_info["dataflow"]
    indicators = "+".join(category_info["indicators"])
    
    # This is a simplified URL - the original has more complexity
    original_url = f"https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,{dataflow},1.0/.{indicators}..?format=csv&labels=both"
    
    print(f"\nComparing {category_name}:")
    print(f"  Original URL: {original_url[:80]}...")
    
    # Download with original URL
    try:
        resp = requests.get(original_url, timeout=60)
        resp.raise_for_status()
        df_original = pd.read_csv(StringIO(resp.text))
        original_rows = len(df_original)
        print(f"  Original rows: {original_rows:,}")
    except Exception as e:
        print(f"  Original failed: {e}")
        original_rows = None
    
    # Download with get_unicef()
    try:
        df_new = get_unicef(indicator=category_info["indicators"])
        new_rows = len(df_new)
        print(f"  get_unicef rows: {new_rows:,}")
    except Exception as e:
        print(f"  get_unicef failed: {e}")
        new_rows = None
    
    if original_rows and new_rows:
        # Note: Counts may differ due to filtering (sex, wealth quintile)
        diff = new_rows - original_rows
        print(f"  Difference: {diff:+,} (expected due to filtering)")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Test PROD-SDG indicator downloads")
    parser.add_argument("--category", "-c", help="Test specific category only")
    parser.add_argument("--discovery", "-d", action="store_true", help="Run indicator discovery test")
    parser.add_argument("--compare", action="store_true", help="Compare with original URLs")
    parser.add_argument("--quiet", "-q", action="store_true", help="Less verbose output")
    
    args = parser.parse_args()
    
    if args.discovery:
        test_indicator_discovery()
    elif args.category:
        if args.category in PROD_SDG_INDICATORS:
            test_single_indicator_download(
                args.category, 
                PROD_SDG_INDICATORS[args.category],
                verbose=not args.quiet
            )
        else:
            print(f"Unknown category: {args.category}")
            print(f"Available: {list(PROD_SDG_INDICATORS.keys())}")
    elif args.compare:
        for cat_name, cat_info in list(PROD_SDG_INDICATORS.items())[:3]:
            compare_with_original(cat_name, cat_info)
    else:
        run_all_tests(verbose=not args.quiet)

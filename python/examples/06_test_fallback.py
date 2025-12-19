"""06_test_fallback.py - Test Dataflow Fallback Mechanism
=========================================================

Tests 5 key indicators demonstrating:
1. Direct dataflow fetch (CME, NUTRITION)
2. Static overrides (EDUCATION, CHILD_MARRIAGE)
3. Dynamic fallback (IPV -> GLOBAL_DATAFLOW)

Matches: R/examples/06_test_fallback.R
"""
import sys
import time
sys.path.insert(0, '..')

from unicef_api import unicefData

print("=" * 70)
print("06_test_fallback.py - Test Dataflow Fallback Mechanism")
print("=" * 70)
print()

# Test cases - same as R test_quick.R
tests = [
    {
        "name": "MORTALITY (CME)",
        "indicator": "CME_MRY0T4",
        "countries": ["AFG", "ALB", "USA"],
        "expected": "Direct fetch from CME"
    },
    {
        "name": "NUTRITION (stunting)",
        "indicator": "NT_ANT_HAZ_NE2_MOD",
        "countries": ["AFG", "ALB", "USA"],
        "expected": "Direct fetch from NUTRITION"
    },
    {
        "name": "EDUCATION (override)",
        "indicator": "ED_CR_L1_UIS_MOD",
        "countries": ["AFG", "ALB", "USA"],
        "expected": "Uses override to EDUCATION_UIS_SDG"
    },
    {
        "name": "CHILD_MARRIAGE (override)",
        "indicator": "PT_F_20-24_MRD_U18_TND",
        "countries": ["AFG", "ALB"],
        "expected": "Uses override to PT_CM"
    },
    {
        "name": "IPV (fallback)",
        "indicator": "PT_F_PS-SX_V_PTNR_12MNTH",
        "countries": ["AFG", "ALB"],
        "expected": "Needs fallback to GLOBAL_DATAFLOW"
    }
]

results = {}
total_start = time.time()

for t in tests:
    print(f"\n--- Testing: {t['name']} ---")
    print(f"Indicator: {t['indicator']}")
    
    start = time.time()
    
    try:
        df = unicefData(
            indicator=t["indicator"],
            countries=t["countries"],
            year="2015:2024"
        )
        
        elapsed = time.time() - start
        
        if len(df) > 0:
            print(f"[OK] {len(df)} rows in {elapsed:.1f}s")
            results[t["name"]] = "OK"
        else:
            print(f"[EMPTY] No data in {elapsed:.1f}s")
            results[t["name"]] = "EMPTY"
            
    except Exception as e:
        elapsed = time.time() - start
        print(f"[FAIL] {str(e)[:60]} ({elapsed:.1f}s)")
        results[t["name"]] = "FAIL"

# Summary
total_time = time.time() - total_start

print()
print("=" * 70)
print("SUMMARY")
print("=" * 70)

for name, status in results.items():
    print(f"[{status:5}] {name}")

success = sum(1 for s in results.values() if s == "OK")
total = len(results)

print(f"\nPython: {success}/{total} passed ({total_time:.1f}s total)")

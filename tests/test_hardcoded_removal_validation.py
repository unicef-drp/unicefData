#!/usr/bin/env python3
"""
Validation Test: Hardcoded Dataflows and Indicators Removal
============================================================

This test verifies that after removing all hardcoded dataflows and 
indicator exceptions, the unicefData package still works correctly 
using the comprehensive YAML metadata.

Tests:
1. Python client initialization
2. Metadata loading (733 indicators)
3. Dataflow resolution
4. Backward compatibility (no broken imports)
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'python'))

from unicef_api.sdmx_client import UNICEFSDMXClient

def test_client_initialization():
    """Test 1: Client can be initialized"""
    print("\n[Test 1] Client Initialization")
    print("-" * 50)
    
    try:
        client = UNICEFSDMXClient()
        print(f"✓ Client initialized successfully")
        print(f"  Base URL: {client.base_url}")
        return True
    except Exception as e:
        print(f"✗ Failed to initialize client: {e}")
        return False


def test_metadata_loading():
    """Test 2: Comprehensive metadata is loaded"""
    print("\n[Test 2] Metadata Loading")
    print("-" * 50)
    
    try:
        client = UNICEFSDMXClient()
        metadata = client._indicators_metadata
        
        expected_count = 733
        actual_count = len(metadata)
        
        if actual_count == expected_count:
            print(f"✓ Loaded {actual_count} indicators (expected {expected_count})")
        else:
            print(f"⚠ Loaded {actual_count} indicators (expected {expected_count})")
        
        # Verify structure
        sample_code = 'CME_MRY0T4'
        if sample_code in metadata:
            sample = metadata[sample_code]
            print(f"✓ Sample indicator ({sample_code}) structure:")
            print(f"    dataflow: {sample.get('dataflow')}")
            print(f"    name: {sample.get('name')}")
            print(f"    category: {sample.get('category')}")
            return True
        else:
            print(f"✗ Sample indicator {sample_code} not found")
            return False
            
    except Exception as e:
        print(f"✗ Metadata loading failed: {e}")
        return False


def test_dataflow_resolution():
    """Test 3: Dataflow resolution works correctly"""
    print("\n[Test 3] Dataflow Resolution")
    print("-" * 50)
    
    try:
        client = UNICEFSDMXClient()
        
        # Test cases from removed COMMON_INDICATORS
        test_cases = [
            ('CME_MRY0T4', 'CME', 'Child mortality'),
            ('NT_ANT_HAZ_NE2_MOD', 'NUTRITION', 'Nutrition'),
            ('ED_CR_L1_UIS_MOD', 'EDUCATION_UIS_SDG', 'Education'),
            ('IM_DTP3', 'IMMUNISATION', 'Immunisation'),
            ('WS_PPL_W-SM', 'WASH_HOUSEHOLDS', 'WASH'),
            ('MNCH_MMR', 'MNCH', 'Maternal health'),
            ('PT_CHLD_Y0T4_REG', 'PT', 'Child protection'),
            ('PT_F_15-49_FGM', 'PT_FGM', 'FGM (pattern match removed)'),
            ('ECD_CHLD_LMPSL', 'ECD', 'Early childhood'),
        ]
        
        all_passed = True
        for code, expected_dataflow, category in test_cases:
            if code in client._indicators_metadata:
                actual_dataflow = client._indicators_metadata[code]['dataflow']
                if actual_dataflow == expected_dataflow:
                    print(f"✓ {code}: {actual_dataflow} ({category})")
                else:
                    print(f"✗ {code}: expected {expected_dataflow}, got {actual_dataflow}")
                    all_passed = False
            else:
                print(f"⚠ {code}: not in metadata")
                all_passed = False
        
        return all_passed
        
    except Exception as e:
        print(f"✗ Dataflow resolution failed: {e}")
        return False


def test_no_hardcoded_imports():
    """Test 4: Verify removed functions don't exist in config"""
    print("\n[Test 4] Hardcoded Functions Removed")
    print("-" * 50)
    
    try:
        import unicef_api.config as config
        
        # These should NOT exist
        removed_items = [
            'UNICEF_DATAFLOWS',
            'COMMON_INDICATORS',
            'get_dataflow_for_indicator',
            'get_indicator_metadata',
            'list_indicators_by_sdg',
            'list_indicators_by_dataflow',
            'get_all_sdg_targets',
            'get_indicators',
            'get_dataflows',
        ]
        
        all_removed = True
        for item in removed_items:
            if hasattr(config, item):
                print(f"✗ {item} still exists in config.py (should be removed)")
                all_removed = False
            else:
                print(f"✓ {item} successfully removed")
        
        return all_removed
        
    except Exception as e:
        print(f"✗ Import check failed: {e}")
        return False


def test_fallback_sequences():
    """Test 5: Fallback sequences still work"""
    print("\n[Test 5] Fallback Dataflow Sequences")
    print("-" * 50)
    
    try:
        client = UNICEFSDMXClient()
        
        # Test fallback resolution
        test_cases = [
            ('CME_MRY0T4', ['GLOBAL_DATAFLOW', 'CME']),
            ('NT_ANT_HAZ_NE2_MOD', ['GLOBAL_DATAFLOW', 'NUTRITION']),
        ]
        
        all_passed = True
        for code, expected_sequence in test_cases:
            actual = client._get_fallback_dataflows(code, 'GLOBAL_DATAFLOW')
            if actual == expected_sequence:
                print(f"✓ {code}: {actual}")
            else:
                print(f"✗ {code}: expected {expected_sequence}, got {actual}")
                all_passed = False
        
        return all_passed
        
    except Exception as e:
        print(f"✗ Fallback sequences test failed: {e}")
        return False


def main():
    """Run all validation tests"""
    print("\n" + "=" * 70)
    print("Hardcoded Removal Validation Test Suite")
    print("=" * 70)
    
    tests = [
        test_client_initialization,
        test_metadata_loading,
        test_dataflow_resolution,
        test_no_hardcoded_imports,
        test_fallback_sequences,
    ]
    
    results = []
    for test_func in tests:
        result = test_func()
        results.append(result)
    
    # Summary
    print("\n" + "=" * 70)
    print("Test Summary")
    print("=" * 70)
    
    passed = sum(results)
    total = len(results)
    
    print(f"\nPassed: {passed}/{total}")
    
    if all(results):
        print("\n✓ ALL TESTS PASSED")
        print("\nConclusion: All hardcoded dataflows and indicators have been")
        print("successfully removed. The package now uses comprehensive YAML")
        print("metadata exclusively across all platforms.")
        return 0
    else:
        print("\n✗ SOME TESTS FAILED")
        print("\nPlease review failed tests above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())

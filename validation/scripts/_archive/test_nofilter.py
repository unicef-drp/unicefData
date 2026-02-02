#!/usr/bin/env python3
"""Test nofilter parameter implementation."""

import sys
sys.path.insert(0, 'python')

from unicef_api import UNICEFSDMXClient

client = UNICEFSDMXClient()

# Test 1: CME with filtering (default)
key_filtered = client._build_schema_aware_key('CME_MRY0T4', 'CME', '_T', nofilter=False)
print(f'CME_MRY0T4 (nofilter=False): {key_filtered}')

# Test 2: CME without filtering
key_all = client._build_schema_aware_key('CME_MRY0T4', 'CME', '_T', nofilter=True)
print(f'CME_MRY0T4 (nofilter=True):  {key_all}')

# Test 3: GLOBAL_DATAFLOW with filtering
key_gd = client._build_schema_aware_key('ECD_CHLD_U5_BKS-HM', 'GLOBAL_DATAFLOW', '_T', nofilter=False)
print(f'ECD_CHLD_U5_BKS-HM (nofilter=False): {key_gd}')

# Test 4: GLOBAL_DATAFLOW without filtering
key_gd_all = client._build_schema_aware_key('ECD_CHLD_U5_BKS-HM', 'GLOBAL_DATAFLOW', '_T', nofilter=True)
print(f'ECD_CHLD_U5_BKS-HM (nofilter=True):  {key_gd_all}')

print("\nExpected patterns:")
print("  CME filtered:       ._T._T (totals only)")
print("  CME unfiltered:     .. (all disaggregations)")
print("  GLOBAL_DATAFLOW f:  ._T (totals only)")
print("  GLOBAL_DATAFLOW uf: .. (all disaggregations)")

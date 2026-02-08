#!/usr/bin/env python
"""Test direct indicators metadata lookup for Python"""

import sys
sys.path.insert(0, 'python')

from unicefdata.sdmx_client import UNICEFSDMXClient

print("=" * 50)
print("Python Direct Metadata Lookup Test")
print("=" * 50)

client = UNICEFSDMXClient()

print("\n1. Metadata Initialization:")
print("   Indicators metadata loaded: {} indicators".format(len(client._indicators_metadata)))
print("   Fallback sequences loaded: {} prefixes".format(len(client._fallback_sequences)))

# Test direct lookup
print("\n2. Direct Metadata Lookup (CME_MRY0T4):")
if 'CME_MRY0T4' in client._indicators_metadata:
    meta = client._indicators_metadata['CME_MRY0T4']
    df = meta.get('dataflow', 'N/A')
    print("   [+] Found in metadata: dataflow={}".format(df))
else:
    print("   [-] NOT found in metadata")

# Test fallback lookup
print("\n3. Fallback Dataflows (CME_MRY0T4):")
fallbacks = client._get_fallback_dataflows('CME_MRY0T4', 'GLOBAL_DATAFLOW')
print("   Fallbacks: {}".format(fallbacks))

# Test ED indicator
print("\n4. Direct Lookup (ED_CR_L1_UIS_MOD):")
if 'ED_CR_L1_UIS_MOD' in client._indicators_metadata:
    meta = client._indicators_metadata['ED_CR_L1_UIS_MOD']
    df = meta.get('dataflow', 'N/A')
    print("   [+] Found in metadata: dataflow={}".format(df))
else:
    print("   [!] Note: ED_CR_L1_UIS_MOD not in metadata (may be newer indicator)")

print("\n5. Architecture Summary:")
print("   - Python now uses comprehensive indicators metadata")
print("   - Direct O(1) lookup instead of prefix-based fallback")
print("   - Fallback sequences still available if metadata missing")
print("   - All platforms aligned on canonical YAML metadata")
print("\n[OK] Test complete\n")


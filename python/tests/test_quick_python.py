#!/usr/bin/env python3
import sys
from pathlib import Path

# Add python module to path
# Since we're in python/tests/, parent (.) is python/
PYTHON_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(PYTHON_DIR))

from unicefdata.sdmx_client import UNICEFSDMXClient

print("\n" + "="*60)
print("Python Integration Test: Direct Metadata Lookup")
print("="*60 + "\n")

client = UNICEFSDMXClient()
print(f"1. Indicators metadata loaded: {len(client._indicators_metadata)} indicators")
print(f"2. CME_MRY0T4 dataflow: {client._indicators_metadata['CME_MRY0T4']['dataflow']}")
print(f"3. ED_CR_L1_UIS_MOD dataflow: {client._indicators_metadata['ED_CR_L1_UIS_MOD']['dataflow']}")

# Test fallback resolution
dataflows = client._get_fallback_dataflows('CME_MRY0T4', 'GLOBAL_DATAFLOW')
print(f"4. Fallback dataflows for CME_MRY0T4: {dataflows}")

print("\n[OK] Test passed - Python using direct metadata lookup\n")

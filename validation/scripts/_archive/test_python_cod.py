#!/usr/bin/env python3
"""
Capture Python unicef_api URLs without verbose monkey-patching.
Just import logging to see debug messages.
"""

import logging
logging.basicConfig(level=logging.DEBUG, format='%(levelname)s: %(message)s')

print("Testing COD_DENGUE...")
from unicef_api import unicefData

try:
    result = unicefData(indicator='COD_DENGUE')
    print(f"Result: {len(result) if result is not None else 0} rows")
except Exception as e:
    print(f"Error: {e}")

print("\nDone.")

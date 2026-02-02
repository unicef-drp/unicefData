#!/usr/bin/env python3
# python_verbose_http_trace.py
# Capture exact HTTP requests/responses with requests verbose logging

import sys
import logging
from pathlib import Path

# Add parent dir to path
sys.path.insert(0, str(Path(__file__).parent.parent))

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Enable verbose logging for requests library
logging.basicConfig(level=logging.DEBUG)
logging.getLogger('requests').setLevel(logging.DEBUG)
logging.getLogger('urllib3').setLevel(logging.DEBUG)

# Also write to file
log_file = Path(__file__).parent / "python_http_trace.log"
file_handler = logging.FileHandler(log_file)
file_handler.setLevel(logging.DEBUG)
logging.getLogger().addHandler(file_handler)

print("\n=== Python: Verbose HTTP Request Capture ===\n")
print(f"Verbose logging to: {log_file}\n")

# Test indicators
indicators = ["COD_DENGUE", "MG_NEW_INTERNAL_DISP"]

print("Testing: COD_DENGUE and MG_NEW_INTERNAL_DISP")
print("Indicators with 404 errors in R\n")

# Import after logging is configured
try:
    from unicefdata_client import get_indicator_data
except ImportError:
    print("WARNING: unicefdata_client not found, attempting direct import")
    import sys
    sys.path.insert(0, '.')
    from unicefdata_client import get_indicator_data

for indicator in indicators:
    print("\n" + "="*70)
    print(f"Indicator: {indicator}")
    print("="*70 + "\n")
    
    print("Making API request with verbose output...\n")
    print("(Watch for REQUEST URL, REQUEST HEADERS, RESPONSE STATUS)\n")
    
    try:
        result = get_indicator_data(
            indicator=indicator,
            countries=["USA"],
            year="2020"
        )
        
        print(f"\n✓ Request succeeded")
        print(f"  Rows returned: {len(result)}")
        print(f"  Columns: {list(result.columns)[:5]}...")
        
    except Exception as e:
        print(f"\n✗ Error encountered")
        print(f"  Error type: {type(e).__name__}")
        print(f"  Error message: {str(e)[:200]}")

print("\n\n=== Verbose Output Complete ===")
print("Key things to look for:")
print("  1. Full URL being requested")
print("  2. Request headers (User-Agent, Accept, etc)")
print("  3. HTTP response status code")
print("  4. Response headers")
print(f"\nDetailed logs saved to: {log_file}\n")

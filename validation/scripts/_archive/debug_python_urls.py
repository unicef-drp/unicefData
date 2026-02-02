#!/usr/bin/env python3
"""
Debug Python API URLs to understand what requests unicef_api makes.
"""

import logging
import sys
from io import StringIO
import requests

# Enable HTTP debugging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(levelname)s: %(message)s'
)

# Monkey-patch requests to log URLs
original_request = requests.Session.request
def logged_request(self, method, url, **kwargs):
    print(f"\n>>> {method} {url}")
    if 'params' in kwargs and kwargs['params']:
        print(f"    Params: {kwargs['params']}")
    if 'headers' in kwargs and kwargs['headers']:
        print(f"    Headers: {kwargs['headers']}")
    response = original_request(self, method, url, **kwargs)
    print(f"    Status: {response.status_code}")
    return response

requests.Session.request = logged_request

# Now import and test
print("=" * 70)
print("PYTHON: Testing URL construction for failing indicators")
print("=" * 70)

from unicef_api import unicefData

# Test the two failing indicators
indicators = [
    'COD_DENGUE',
    'MG_NEW_INTERNAL_DISP'
]

for indicator in indicators:
    print(f"\n\n{'='*70}")
    print(f"Testing: {indicator}")
    print(f"{'='*70}")
    
    try:
        result = unicefData(indicator=indicator)
        print(f"\n✓ Success: {len(result) if result is not None else 0} rows returned")
        if result is not None and len(result) > 0:
            print(f"  Columns: {list(result.columns)[:5]}")
    except Exception as e:
        print(f"\n✗ Failed: {e}")

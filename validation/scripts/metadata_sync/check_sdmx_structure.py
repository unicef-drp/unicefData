#!/usr/bin/env python3
"""Check SDMX API structure: Dimensions vs Attributes"""

import sys
sys.path.insert(0, 'python')

from unicef_api import UNICEFSDMXClient
import json
import requests

client = UNICEFSDMXClient()

# 1. Check our current schema understanding
print("="*70)
print("1. Our CME Schema (from metadata)")
print("="*70)
schema = client.metadata_manager.get_schema('CME')
print(json.dumps(schema, indent=2))

# 2. Fetch actual structure from SDMX API
print("\n" + "="*70)
print("2. SDMX Dataflow Structure (from API)")
print("="*70)
url = 'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/CME?references=all&detail=full'
print(f"Fetching: {url}\n")

try:
    resp = requests.get(url, timeout=30)
    print(f"Status: {resp.status_code}")
    print(f"Content-Type: {resp.headers.get('content-type')}")
    
    # Save response for manual inspection
    with open('cme_dataflow_structure.xml', 'w', encoding='utf-8') as f:
        f.write(resp.text)
    print("✓ Saved to: cme_dataflow_structure.xml")
    
    # Try to parse dimensions and attributes from XML
    from xml.etree import ElementTree as ET
    root = ET.fromstring(resp.text)
    
    # Find DataStructure element
    namespaces = {
        'str': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
        'com': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common'
    }
    
    print("\n" + "-"*70)
    print("DIMENSIONS:")
    print("-"*70)
    dims = root.findall('.//str:Dimension', namespaces)
    for dim in dims:
        dim_id = dim.get('id')
        position = dim.get('position')
        print(f"  {position}: {dim_id}")
    
    print("\n" + "-"*70)
    print("ATTRIBUTES:")
    print("-"*70)
    attrs = root.findall('.//str:Attribute', namespaces)
    for attr in attrs:
        attr_id = attr.get('id')
        usage_status = attr.find('.//str:AttributeRelationship', namespaces)
        print(f"  {attr_id}")
        
except Exception as e:
    print(f"Error: {e}")

# 3. Test actual API calls with different key formats
print("\n" + "="*70)
print("3. Testing Different URL Key Formats")
print("="*70)

test_cases = [
    {
        "desc": "Empty key (all countries, all indicators, all disaggregations)",
        "key": ""
    },
    {
        "desc": "Indicator only: .CME_MRY0T4 (one indicator, all disaggregations)",
        "key": ".CME_MRY0T4"
    },
    {
        "desc": "Filtered (our implementation): .CME_MRY0T4._T._T",
        "key": ".CME_MRY0T4._T._T"
    },
    {
        "desc": "Unfiltered (nofilter=True): .CME_MRY0T4..",
        "key": ".CME_MRY0T4.."
    },
]

for test in test_cases:
    print(f"\n{test['desc']}")
    print(f"  Key: '{test['key']}'")
    
    url = f"https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/{test['key']}?format=csv&labels=id"
    print(f"  URL: {url}")
    
    try:
        resp = requests.get(url, timeout=30)
        if resp.status_code == 200:
            lines = resp.text.strip().split('\n')
            print(f"  ✓ Response: {len(lines)-1} data rows")
            if len(lines) > 1:
                print(f"    Headers: {lines[0][:100]}...")
                print(f"    Sample: {lines[1][:100]}...")
        else:
            print(f"  ✗ Error: {resp.status_code}")
    except Exception as e:
        print(f"  ✗ Exception: {e}")

print("\n" + "="*70)
print("Analysis complete. Check cme_dataflow_structure.xml for details.")
print("="*70)

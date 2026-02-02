#!/usr/bin/env python3
"""Check available WASH dataflows from UNICEF API"""

import requests
import xml.etree.ElementTree as ET

# Query dataflows
url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow"
print(f"Querying: {url}")
r = requests.get(url)
print(f"Status: {r.status_code}")

# Parse XML
root = ET.fromstring(r.content)

# Find all dataflows containing 'WASH'
ns = {
    'mes': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message',
    'str': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure'
}

print("\n=== WASH-related Dataflows ===")
dataflows = root.findall('.//str:Dataflow', ns)
for df in dataflows:
    df_id = df.get('id', '')
    if 'WASH' in df_id.upper():
        print(f"  {df_id}")
        
# Also check what dataflow WS_HCF indicators should use
print("\n=== Testing WS_HCF_H-L indicator ===")

# Try with WASH_HOUSEHOLDS
test_url_1 = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/WASH_HOUSEHOLDS/all.WS_HCF_H-L..?format=csv"
r1 = requests.get(test_url_1)
print(f"WASH_HOUSEHOLDS: status={r1.status_code}, data_rows={len(r1.text.split(chr(10)))-1 if r1.ok else 'N/A'}")

# Try with WASH_HEALTHCARE_FACILITY
test_url_2 = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/WASH_HEALTHCARE_FACILITY/all.WS_HCF_H-L..?format=csv"
r2 = requests.get(test_url_2)
print(f"WASH_HEALTHCARE_FACILITY: status={r2.status_code}, data_rows={len(r2.text.split(chr(10)))-1 if r2.ok else 'N/A'}")

# Try with GLOBAL_DATAFLOW
test_url_3 = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/GLOBAL_DATAFLOW/all.WS_HCF_H-L..?format=csv&startPeriod=2020&lastNObservations=5"
r3 = requests.get(test_url_3)
print(f"GLOBAL_DATAFLOW: status={r3.status_code}, data_rows={len(r3.text.split(chr(10)))-1 if r3.ok else 'N/A'}")

print("\nDone.")

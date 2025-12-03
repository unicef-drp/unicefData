"""Test extracting dimensions from SDMX dataflow"""
import requests
import xml.etree.ElementTree as ET

# Get dataflow with references
url = 'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/CME/1.0?references=all'
r = requests.get(url, timeout=60)

# Parse XML
root = ET.fromstring(r.content)

# Find all dimensions
ns = {
    'str': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
    'mes': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message'
}

dimensions = []
for dim in root.findall('.//str:Dimension', ns):
    dim_id = dim.get('id')
    position = dim.get('position')
    dimensions.append({'id': dim_id, 'position': int(position) if position else None})

# Sort by position
dimensions.sort(key=lambda x: x['position'] or 999)

print('CME Dataflow Dimensions:')
for d in dimensions:
    print(f"  {d['position']}: {d['id']}")

# Also get attributes (OBS_VALUE, etc.)
attributes = []
for attr in root.findall('.//str:Attribute', ns):
    attr_id = attr.get('id')
    attributes.append(attr_id)

print()
print('Attributes:')
for a in attributes:
    print(f'  {a}')

#!/usr/bin/env python3
import yaml

with open('_unicefdata_indicators.yaml') as f:
    data = yaml.safe_load(f)

# Search for COD_DENGUE and MG_NEW_INTERNAL_DISP
indicators = data['indicators']

print("Searching for failing indicators in metadata...\n")

for ind in ['COD_DENGUE', 'MG_NEW_INTERNAL_DISP']:
    if ind in indicators:
        info = indicators[ind]
        print(f'{ind}:')
        print(f'  Dataflow: {info.get("dataflow")}')
        print(f'  Name: {info.get("name")}')
    else:
        print(f'{ind}: NOT FOUND in metadata')

print('\n\nAll dataflows in metadata:')
for df in data['_metadata']['indicators_per_dataflow'].keys():
    print(f'  - {df}')

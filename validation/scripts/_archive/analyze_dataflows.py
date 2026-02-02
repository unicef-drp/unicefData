#!/usr/bin/env python3
"""Analyze dataflow-indicator mappings from YAML metadata"""
import yaml
from pathlib import Path

# Load all dataflow YAML files
df_path = Path('C:/GitHub/myados/unicefData/python/metadata/current/dataflows')
mapping = {}

for yaml_file in sorted(df_path.glob('*.yaml')):
    if yaml_file.name == '_metadata.yaml':
        continue
    
    try:
        with open(yaml_file, 'r') as f:
            data = yaml.safe_load(f)
            if data and 'id' in data:
                dataflow_id = data['id']
                indicators = []
                
                # Extract indicators from dimensions
                if 'dimensions' in data and data['dimensions']:
                    for dim in data['dimensions']:
                        if dim.get('id') == 'INDICATOR' and dim.get('values'):
                            indicators = dim['values'][:10]
                            break
                
                mapping[dataflow_id] = {
                    'name': data.get('name', ''),
                    'count': len(indicators) if indicators else 0,
                    'samples': indicators
                }
    except Exception as e:
        print(f"Error reading {yaml_file}: {e}")

# Print summary
print("\n=== DATAFLOW INDICATOR MAPPING ===\n")
for df in sorted(mapping.keys()):
    info = mapping[df]
    prefix = df.split('_')[0] if '_' in df else df[:3]
    samples = ', '.join(info['samples'][:3]) if info['samples'] else 'None'
    print(f"{df:30} Prefix: {prefix:10} Indicators: {info.get('count', 0):3}  Samples: {samples}")

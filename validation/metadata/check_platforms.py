#!/usr/bin/env python3
import yaml

# Check which metadata file is being used
metadata_files = [
    'unicef_indicators_metadata.yaml',
    '_unicefdata_indicators.yaml'
]

for metadata_file in metadata_files:
    try:
        with open(metadata_file) as f:
            data = yaml.safe_load(f)
        
        print(f"\n{'='*60}")
        print(f"File: {metadata_file}")
        print(f"{'='*60}")
        
        # Check platform
        platform = data.get('_metadata', {}).get('platform', 'UNKNOWN')
        print(f"Platform designation: {platform}")
        
        # Check indicators
        indicators_to_check = ['COD_DENGUE', 'MG_NEW_INTERNAL_DISP']
        
        for ind in indicators_to_check:
            if ind in data.get('indicators', {}):
                info = data['indicators'][ind]
                category = info.get('category', 'N/A')
                print(f"\n{ind}:")
                print(f"  category: {category}")
            else:
                print(f"\n{ind}: NOT FOUND")
    except FileNotFoundError:
        print(f"{metadata_file}: File not found")

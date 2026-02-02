"""Check dataflows for failing indicators"""
import sys
sys.path.insert(0, 'python')

from unicef_api.indicator_registry import get_dataflow_for_indicator, _get_cache_path
import yaml

# Check the actual cache
cache_path = _get_cache_path()
print(f'Cache path: {cache_path}')

with open(cache_path, 'r') as f:
    data = yaml.safe_load(f)

# Look for WS_HCF indicators
print("\nWS_HCF indicators in cache:")
for code, info in data.get('indicators', {}).items():
    if 'WS_HCF' in code:
        print(f"  {code}: dataflow = {info.get('dataflow')}")

# Check all failing indicators
print("\nFailing indicators dataflow mapping:")
failing = ['ED_CR_L1_UIS_MOD', 'PT_CM_EMPLOY_12M', 'PT_M_20-24_MRD_U18', 'WS_HCF_H-L', 'WT_ADLS_15-19_ED_NEET']

for ind in failing:
    if ind in data.get('indicators', {}):
        df = data['indicators'][ind].get('dataflow')
        print(f"  {ind}: {df} (from cache)")
    else:
        # Try prefix-based fallback
        df = get_dataflow_for_indicator(ind)
        print(f"  {ind}: {df} (auto-detected)")

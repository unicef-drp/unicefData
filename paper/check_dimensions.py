#!/usr/bin/env python3
"""Check all available disaggregations for CME_MRY0T4 indicator"""

import sys
sys.path.insert(0, 'C:/GitHub/myados/unicefData/python')

from unicef_api import unicefdata
import pandas as pd

print("Querying CME_MRY0T4 for Bangladesh (all disaggregations)...\n")

# Get raw data with all disaggregations
df = unicefdata(
    indicator='CME_MRY0T4',
    countries=['BGD'],
    raw=True
)

# Filter to Bangladesh
df_bgd = df[df['REF_AREA'] == 'BGD'].copy()

print(f"Total observations: {len(df_bgd)}")
print("\n" + "="*70)
print("AVAILABLE DISAGGREGATION DIMENSIONS")
print("="*70)

# Check each potential dimension column
dimension_cols = ['SEX', 'WEALTH_QUINTILE', 'AGE', 'RESIDENCE', 'MATERNAL_EDU_LVL']

for col in dimension_cols:
    if col in df_bgd.columns:
        unique_vals = df_bgd[col].dropna().unique()
        if len(unique_vals) > 0:
            print(f"\n{col}:")
            print(f"  Values: {sorted(unique_vals)}")
            print(f"  Count: {len(unique_vals)} categories")
            
            # Show distribution
            value_counts = df_bgd[col].value_counts()
            print(f"  Distribution:")
            for val, count in value_counts.items():
                print(f"    {val}: {count} observations")

print("\n" + "="*70)
print("SAMPLE COMBINATIONS")
print("="*70)

# Show some example combinations
sample = df_bgd[['TIME_PERIOD', 'SEX', 'WEALTH_QUINTILE', 'OBS_VALUE']].head(10)
print(sample.to_string(index=False))

# Check if there are any residence or maternal education disaggregations
print("\n" + "="*70)
print("NON-NULL COUNTS FOR ALL DIMENSIONS")
print("="*70)
for col in dimension_cols:
    if col in df_bgd.columns:
        non_null = df_bgd[col].notna().sum()
        print(f"{col:20} {non_null:>6} non-null / {len(df_bgd)} total")

import sys
sys.path.insert(0, r'C:\GitHub\myados\unicefData-dev\python')

from unicef_api import unicefData

print("\n=== Testing IM_DTP3 ===")
df_py = unicefData(indicator='IM_DTP3')
cols_py = list(df_py.columns)
print(f"Python columns for IM_DTP3 ({len(cols_py)}):")
print(cols_py)
print(f"Has vaccine column? {'vaccine' in cols_py}")

print("\n=== Testing FD_EARLY_STIM ===")
df_py2 = unicefData(indicator='FD_EARLY_STIM')
cols_py2 = list(df_py2.columns)
print(f"Python columns for FD_EARLY_STIM ({len(cols_py2)}):")
print(cols_py2)
print(f"Has ethnic_group? {'ethnic_group' in cols_py2}")
print(f"Has education_level? {'education_level' in cols_py2}")
print(f"Has disability_status? {'disability_status' in cols_py2}")
print(f"Has admin_level? {'admin_level' in cols_py2}")

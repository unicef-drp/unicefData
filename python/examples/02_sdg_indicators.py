"""02_sdg_indicators.py - SDG Indicator Examples
==============================================

Demonstrates fetching SDG-related indicators across different domains.
Matches: R/examples/02_sdg_indicators.R

Examples:
  1. Child Mortality (SDG 3.2)
  2. Stunting/Wasting (SDG 2.2)
  3. Education Completion (SDG 4.1)
  4. Child Marriage (SDG 5.3)
  5. WASH indicators (SDG 6)
"""
import sys
import os
sys.path.insert(0, '..')

from unicef_api import unicefData

# Setup data directory - centralized for cross-language validation
DATA_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'validation', 'data', 'python')
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

print("=" * 70)
print("02_sdg_indicators.py - SDG Indicator Examples")
print("=" * 70)

# Common parameters
COUNTRIES = ["AFG", "BGD", "BRA", "ETH", "IND", "NGA", "PAK"]
START_YEAR = 2015

# =============================================================================
# Example 1: Child Mortality (SDG 3.2)
# =============================================================================
print("\n--- Example 1: Child Mortality (SDG 3.2) ---")
print("Under-5 and Neonatal mortality rates\n")

df = unicefData(
    indicator=["CME_MRY0T4", "CME_MRM0"],
    countries=COUNTRIES,
    start_year=START_YEAR
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
print(f"Indicators: {df['indicator'].unique().tolist()}")
df.to_csv(os.path.join(DATA_DIR, '02_ex1_child_mortality.csv'), index=False)

# =============================================================================
# Example 2: Nutrition (SDG 2.2)
# =============================================================================
print("\n--- Example 2: Nutrition (SDG 2.2) ---")
print("Stunting, Wasting, Overweight\n")

df = unicefData(
    indicator=["NT_ANT_HAZ_NE2_MOD", "NT_ANT_WHZ_NE2", "NT_ANT_WHZ_PO2_MOD"],
    countries=COUNTRIES,
    start_year=START_YEAR
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
df.to_csv(os.path.join(DATA_DIR, '02_ex2_nutrition.csv'), index=False)

# =============================================================================
# Example 3: Education Completion (SDG 4.1)
# =============================================================================
print("\n--- Example 3: Education (SDG 4.1) ---")
print("Completion rates - Primary, Lower Secondary, Upper Secondary\n")

df = unicefData(
    indicator=["ED_CR_L1_UIS_MOD", "ED_CR_L2_UIS_MOD", "ED_CR_L3_UIS_MOD"],
    countries=COUNTRIES,
    start_year=START_YEAR,
    dataflow="EDUCATION_UIS_SDG"  # Explicit dataflow for reliability
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
df.to_csv(os.path.join(DATA_DIR, '02_ex3_education.csv'), index=False)

# =============================================================================
# Example 4: Child Marriage (SDG 5.3)
# =============================================================================
print("\n--- Example 4: Child Marriage (SDG 5.3) ---")
print("Women married before age 18\n")

df = unicefData(
    indicator="PT_F_20-24_MRD_U18_TND",
    countries=COUNTRIES,
    start_year=START_YEAR
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
df.to_csv(os.path.join(DATA_DIR, '02_ex4_child_marriage.csv'), index=False)

# =============================================================================
# Example 5: WASH (SDG 6)
# =============================================================================
print("\n--- Example 5: WASH (SDG 6) ---")
print("Safely managed water and sanitation\n")

df = unicefData(
    indicator=["WS_PPL_W-SM", "WS_PPL_S-SM"],
    countries=COUNTRIES,
    start_year=START_YEAR
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
df.to_csv(os.path.join(DATA_DIR, '02_ex5_wash.csv'), index=False)

print("\n" + "=" * 70)
print("SDG Indicators Complete!")
print("=" * 70)

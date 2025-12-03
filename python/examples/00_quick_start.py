"""
00_quick_start.py - Quick Start Guide
======================================

Demonstrates the basic get_unicef() API with 5 simple examples.
Matches: R/examples/00_quick_start.R

Examples:
  1. Single indicator, specific countries
  2. Multiple indicators
  3. Nutrition data
  4. Immunization data  
  5. All countries (large download)
"""
import sys
import os
sys.path.insert(0, '..')

from unicef_api import get_unicef

# Setup data directory
DATA_DIR = os.path.join(os.path.dirname(__file__), 'data')
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

print("=" * 70)
print("00_quick_start.py - UNICEF API Quick Start Guide")
print("=" * 70)

# =============================================================================
# Example 1: Single Indicator - Under-5 Mortality
# =============================================================================
print("\n--- Example 1: Single Indicator (Under-5 Mortality) ---")
print("Indicator: CME_MRY0T4")
print("Countries: Albania, USA, Brazil")
print("Years: 2015-2023\n")

df = get_unicef(
    indicator="CME_MRY0T4",
    countries=["ALB", "USA", "BRA"],
    start_year=2015,
    end_year=2023
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
print(df[["iso3", "country", "period", "value"]].head())
df.to_csv(os.path.join(DATA_DIR, '00_ex1_mortality.csv'), index=False)

# =============================================================================
# Example 2: Multiple Indicators - Mortality Comparison
# =============================================================================
print("\n--- Example 2: Multiple Indicators (Mortality) ---")
print("Indicators: CME_MRM0 (Neonatal), CME_MRY0T4 (Under-5)")
print("Years: 2020-2023\n")

df = get_unicef(
    indicator=["CME_MRM0", "CME_MRY0T4"],
    countries=["ALB", "USA", "BRA"],
    start_year=2020,
    end_year=2023
)

print(f"Result: {len(df)} rows")
print(f"Indicators: {df['indicator'].unique().tolist()}")

# =============================================================================
# Example 3: Nutrition - Stunting Prevalence
# =============================================================================
print("\n--- Example 3: Nutrition (Stunting) ---")
print("Indicator: NT_ANT_HAZ_NE2_MOD")
print("Countries: Afghanistan, India, Nigeria")
print("Years: 2015+\n")

df = get_unicef(
    indicator="NT_ANT_HAZ_NE2_MOD",
    countries=["AFG", "IND", "NGA"],
    start_year=2015
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")

# =============================================================================
# Example 4: Immunization - DTP3 Coverage
# =============================================================================
print("\n--- Example 4: Immunization (DTP3) ---")
print("Indicator: IM_DTP3")
print("Countries: Albania, USA, Brazil")
print("Years: 2015-2023\n")

df = get_unicef(
    indicator="IM_DTP3",
    countries=["ALB", "USA", "BRA"],
    start_year=2015,
    end_year=2023
)

print(f"Result: {len(df)} rows")

# =============================================================================
# Example 5: All Countries (Large Download)
# =============================================================================
print("\n--- Example 5: All Countries ---")
print("Indicator: CME_MRY0T4 (Under-5 mortality)")
print("Countries: ALL")
print("Years: 2020+\n")

df = get_unicef(
    indicator="CME_MRY0T4",
    start_year=2020
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
print(f"Years: {df['period'].min()} - {df['period'].max()}")
df.to_csv(os.path.join(DATA_DIR, '00_ex2_mult_mortality.csv'), index=False)

print("\n" + "=" * 70)
print("Quick Start Complete!")
print("=" * 70)

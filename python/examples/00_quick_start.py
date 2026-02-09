"""
00_quick_start.py - Quick Start Guide
======================================

Demonstrates the basic unicefData() API with 5 simple examples.
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

from unicefdata import unicefData

# Setup data directory - centralized for cross-language validation
DATA_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'validation', 'data', 'python')
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

df = unicefData(
    indicator="CME_MRY0T4",
    countries=["ALB", "USA", "BRA"],
    year="2015:2023"
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

df = unicefData(
    indicator=["CME_MRM0", "CME_MRY0T4"],
    countries=["ALB", "USA", "BRA"],
    year="2020:2023"
)

print(f"Result: {len(df)} rows")
print(f"Indicators: {df['indicator'].unique().tolist()}")
df.to_csv(os.path.join(DATA_DIR, '00_ex2_multi_indicators.csv'), index=False)

# =============================================================================
# Example 3: Nutrition - Stunting Prevalence
# =============================================================================
print("\n--- Example 3: Nutrition (Stunting) ---")
print("Indicator: NT_ANT_HAZ_NE2_MOD")
print("Countries: Afghanistan, India, Nigeria")
print("Years: 2015+\n")

df = unicefData(
    indicator="NT_ANT_HAZ_NE2_MOD",
    countries=["AFG", "IND", "NGA"],
    year="2015:2024"  # All years from 2015
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
df.to_csv(os.path.join(DATA_DIR, '00_ex3_nutrition.csv'), index=False)

# =============================================================================
# Example 4: Immunization - DTP3 Coverage
# =============================================================================
print("\n--- Example 4: Immunization (DTP3) ---")
print("Indicator: IM_DTP3")
print("Countries: Nigeria, Kenya, South Africa")
print("Years: 2015-2023\n")

df = unicefData(
    indicator="IM_DTP3",
    countries=["NGA", "KEN", "ZAF"],
    year="2015:2023"
)

print(f"Result: {len(df)} rows")
df.to_csv(os.path.join(DATA_DIR, '00_ex4_immunization.csv'), index=False)

# =============================================================================
# Example 5: All Countries (Large Download)
# =============================================================================
print("\n--- Example 5: All Countries ---")
print("Indicator: CME_MRY0T4 (Under-5 mortality)")
print("Countries: ALL")
print("Years: 2020+\n")

df = unicefData(
    indicator="CME_MRY0T4",
    year="2020:2024"  # All years from 2020
)

print(f"Result: {len(df)} rows, {df['iso3'].nunique()} countries")
print(f"Years: {df['period'].min()} - {df['period'].max()}")
df.to_csv(os.path.join(DATA_DIR, '00_ex5_all_countries.csv'), index=False)

print("\n" + "=" * 70)
print("Quick Start Complete!")
print("=" * 70)

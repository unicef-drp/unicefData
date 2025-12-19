"""03_data_formats.py - Output Format Options
==========================================

Demonstrates different output formats and data transformations.
Matches: R/examples/03_data_formats.R

Examples:
  1. Long format (default)
  2. Wide format (years as columns)
  3. Wide indicators (indicators as columns)
  4. Latest value per country
  5. Most recent N values (MRV)
"""
import sys
sys.path.insert(0, '..')

from unicef_api import unicefData

print("=" * 70)
print("03_data_formats.py - Output Format Options")
print("=" * 70)

COUNTRIES = ["ALB", "USA", "BRA", "IND", "NGA"]

# =============================================================================
# Example 1: Long Format (Default)
# =============================================================================
print("\n--- Example 1: Long Format (Default) ---")
print("One row per observation\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=COUNTRIES,
    start_year=2020,
    format="long"  # default
)

print(f"Shape: {df.shape}")
print(df[["iso3", "country", "period", "value"]].head(10))

# =============================================================================
# Example 2: Wide Format (Years as Columns)
# =============================================================================
print("\n--- Example 2: Wide Format (Years as Columns) ---")
print("Countries as rows, years as columns\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=COUNTRIES,
    start_year=2020,
    format="wide"
)

print(f"Shape: {df.shape}")
print(df)

# =============================================================================
# Example 3: Wide Indicators (Indicators as Columns)
# =============================================================================
print("\n--- Example 3: Wide Indicators ---")
print("Indicators as columns (for comparison)\n")

df = unicefData(
    indicator=["CME_MRY0T4", "CME_MRM0"],
    countries=COUNTRIES,
    start_year=2020,
    format="wide_indicators"
)

print(f"Shape: {df.shape}")
print(df.head(10))

# =============================================================================
# Example 4: Latest Value Per Country
# =============================================================================
print("\n--- Example 4: Latest Value Per Country ---")
print("Cross-sectional analysis (one value per country)\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=COUNTRIES,
    start_year=2015,
    latest=True
)

print(f"Shape: {df.shape} (one row per country)")
print(df[["iso3", "country", "period", "value"]])

# =============================================================================
# Example 5: Most Recent N Values (MRV)
# =============================================================================
print("\n--- Example 5: Most Recent 3 Values (MRV=3) ---")
print("Keep only 3 most recent years per country\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=["ALB", "USA"],
    start_year=2010,
    mrv=3
)

print(f"Shape: {df.shape} (expect 6 rows: 3 years x 2 countries)")
print(df[["iso3", "period", "value"]])

print("\n" + "=" * 70)
print("Data Formats Complete!")
print("=" * 70)

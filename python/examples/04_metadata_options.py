"""04_metadata_options.py - Add Metadata to Data
==============================================

Demonstrates adding metadata columns to output.
Matches: R/examples/04_metadata_options.R

Examples:
  1. Add region classification
  2. Add income group
  3. Add indicator name
  4. Combine multiple metadata
  5. Simplify output columns
"""
import sys
sys.path.insert(0, '..')

from unicefdata import unicefData

print("=" * 70)
print("04_metadata_options.py - Add Metadata to Data")
print("=" * 70)

COUNTRIES = ["ALB", "USA", "BRA", "IND", "NGA", "ETH", "CHN"]

# =============================================================================
# Example 1: Add Region Classification
# =============================================================================
print("\n--- Example 1: Add Region ---")
print("UNICEF/World Bank regional classification\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=COUNTRIES,
    year=2020,
    latest=True,
    add_metadata=["region"]
)

print(f"Columns: {df.columns.tolist()}")
print(df[["iso3", "country", "region", "value"]])

# =============================================================================
# Example 2: Add Income Group
# =============================================================================
print("\n--- Example 2: Add Income Group ---")
print("World Bank income classification\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=COUNTRIES,
    year=2020,
    latest=True,
    add_metadata=["income_group"]
)

print(df[["iso3", "country", "income_group", "value"]])

# =============================================================================
# Example 3: Add Indicator Name
# =============================================================================
print("\n--- Example 3: Add Indicator Name ---")
print("Full indicator description\n")

df = unicefData(
    indicator=["CME_MRY0T4", "CME_MRM0"],
    countries=["ALB", "USA"],
    year=2020,
    latest=True,
    add_metadata=["indicator_name"]
)

print(df[["iso3", "indicator", "indicator_name", "value"]])

# =============================================================================
# Example 4: Multiple Metadata
# =============================================================================
print("\n--- Example 4: Multiple Metadata ---")
print("Combine region, income group, and indicator name\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=COUNTRIES,
    year=2020,
    latest=True,
    add_metadata=["region", "income_group", "indicator_name"]
)

print(f"Columns: {df.columns.tolist()}")
print(df[["iso3", "region", "income_group", "value"]].head())

# =============================================================================
# Example 5: Simplify Output
# =============================================================================
print("\n--- Example 5: Simplify Output ---")
print("Keep only essential columns\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=COUNTRIES,
    year=2020,
    simplify=True
)

print(f"Simplified columns: {df.columns.tolist()}")
print(df.head())

print("\n" + "=" * 70)
print("Metadata Options Complete!")
print("=" * 70)

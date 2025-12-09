"""05_advanced_features.py - Advanced Features
=============================================

Demonstrates advanced query features.
Matches: R/examples/05_advanced_features.R

Examples:
  1. Disaggregation by sex
  2. Disaggregation by wealth quintile
  3. Time series with specific year range
  4. Multiple countries with latest values
  5. Combining filters
"""
import sys
sys.path.insert(0, "..")

from unicef_api import unicefData

print("=" * 70)
print("05_advanced_features.py - Advanced Features")
print("=" * 70)

# =============================================================================
# Example 1: Disaggregation by Sex
# =============================================================================
print("\n--- Example 1: Disaggregation by Sex ---")
print("Under-5 mortality by sex\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=["ALB", "USA", "BRA"],
    start_year=2020,
    sex=["M", "F"]  # Male and Female
)

print(df[["iso3", "period", "sex", "value"]])

# =============================================================================
# Example 2: Disaggregation by Wealth
# =============================================================================
print("\n--- Example 2: Disaggregation by Wealth ---")
print("Stunting by wealth quintile\n")

# Note: wealth_quintile filter is not yet supported in get_unicef arguments
# We fetch raw data and filter manually
df = unicefData(
    indicator="NT_ANT_HAZ_NE2_MOD",
    countries=["IND", "NGA", "ETH"],
    start_year=2015,
    raw=True  # Get raw data to access disaggregations
)

if not df.empty and "wealth_quintile" in df.columns:
    # Filter for Q1 and Q5
    df = df[df["wealth_quintile"].isin(["Q1", "Q5"])]
    print(df[["iso3", "period", "wealth_quintile", "value"]])
else:
    print("No wealth-disaggregated data available for these countries")

# =============================================================================
# Example 3: Time Series
# =============================================================================
print("\n--- Example 3: Time Series ---")
print("Mortality trends 2000-2023\n")

df = unicefData(
    indicator="CME_MRY0T4",
    countries=["ALB"],
    start_year=2000,
    end_year=2023
)

print(f"Time series: {len(df)} observations")
print(df[["period", "value"]].head(10))

# =============================================================================
# Example 4: Multiple Countries Latest
# =============================================================================
print("\n--- Example 4: Multiple Countries Latest ---")
print("Latest immunization rates for many countries\n")

# Get latest DPT3 coverage for multiple countries
df = unicefData(
    indicator="IM_DTP3",
    countries=["AFG", "ALB", "USA", "BRA", "IND", "CHN", "NGA", "ETH"],
    start_year=2015,
    latest=True
)

print(df[["iso3", "country", "period", "value"]])

# =============================================================================
# Example 5: Combining Filters
# =============================================================================
print("\n--- Example 5: Combining Filters ---")
print("Complex query with multiple filters\n")

df = unicefData(
    indicator=["CME_MRY0T4", "CME_MRM0"],  # Multiple indicators
    countries=["ALB", "USA", "BRA"],        # Multiple countries
    start_year=2020,                         # From 2020
    latest=True,                             # Latest values only
    add_metadata=["indicator_name"]          # Include names
)

print(df[["iso3", "indicator", "indicator_name", "period", "value"]])

print("\n" + "=" * 70)
print("Advanced Features Complete!")
print("=" * 70)


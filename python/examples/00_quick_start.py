"""
Quick Start Guide for unicef_api Python Package
================================================

This demonstrates the unified get_unicef() API that is consistent
with the R package, plus the new search_indicators() and list_categories()
functions for discovering available indicators.
"""

from unicef_api import get_unicef, list_dataflows, search_indicators, list_categories

def main():
    print("=" * 70)
    print("unicef_api Python Package - Quick Start")
    print("=" * 70)
    print()

    # =========================================================================
    # Example 0: Discover Indicators
    # =========================================================================
    print("--- Example 0: Discover Available Indicators ---")
    print()
    
    # List all categories (15 categories, 733 indicators)
    print("Available categories:\n")
    list_categories()
    
    print()
    
    # Search for mortality indicators
    print("Searching for 'mortality' indicators:\n")
    search_indicators("mortality", limit=5)
    
    print()
    
    # Search within a specific category
    print("Searching in NUTRITION category:\n")
    search_indicators(category="NUTRITION", limit=5)

    # =========================================================================
    # Example 1: Basic Usage - Fetch Under-5 Mortality
    # =========================================================================
    print("\n--- Example 1: Basic Usage ---")
    print("Fetching under-5 mortality for Albania, USA, and Brazil (2015-2023)")
    print("Note: Dataflow is auto-detected from indicator code!\n")

    df = get_unicef(
        indicator="CME_MRY0T4",
        countries=["ALB", "USA", "BRA"],
        start_year=2015,
        end_year=2023
    )

    if not df.empty:
        print(f"✅ Downloaded {len(df)} observations")
        print("\nSample data:")
        print(df.head())
    else:
        print("⚠️ No data returned")

    # =========================================================================
    # Example 2: Multiple Indicators
    # =========================================================================
    print("\n--- Example 2: Multiple Indicators ---")
    print("Fetching neonatal + under-5 mortality for 2020-2023\n")

    df = get_unicef(
        indicator=["CME_MRM0", "CME_MRY0T4"],
        start_year=2020,
        end_year=2023
    )

    if not df.empty:
        print(f"✅ Downloaded {len(df)} observations")
        if 'INDICATOR' in df.columns:
            print(f"   Indicators: {df['INDICATOR'].unique().tolist()}")

    # =========================================================================
    # Example 3: List Available Dataflows
    # =========================================================================
    print("\n--- Example 3: List Available Dataflows ---")

    flows = list_dataflows()
    print(f"✅ Found {len(flows)} dataflows\n")
    print("Key dataflows for child indicators:")
    key_flows = ["CME", "NUTRITION", "EDUCATION_UIS_SDG", "IMMUNISATION", "MNCH"]
    print(flows[flows['id'].isin(key_flows)])

    # =========================================================================
    # Example 4: Nutrition Data
    # =========================================================================
    print("\n--- Example 4: Nutrition Data ---")
    print("Fetching stunting prevalence\n")

    df = get_unicef(
        indicator="NT_ANT_HAZ_NE2_MOD",
        start_year=2015
    )

    if not df.empty:
        print(f"✅ Downloaded {len(df)} observations")
        if 'REF_AREA' in df.columns:
            print(f"   Countries: {df['REF_AREA'].nunique()}")

    # =========================================================================
    # Example 5: All Countries, All Years
    # =========================================================================
    print("\n--- Example 5: All Countries (large download) ---")
    print("Fetching all DTP3 immunization data...\n")

    df = get_unicef(indicator="IM_DTP3")

    if not df.empty:
        print(f"✅ Downloaded {len(df)} observations")
        if 'REF_AREA' in df.columns:
            print(f"   Countries: {df['REF_AREA'].nunique()}")
        if 'TIME_PERIOD' in df.columns:
            print(f"   Years: {df['TIME_PERIOD'].min()} - {df['TIME_PERIOD'].max()}")

    print()
    print("=" * 70)
    print("Quick start complete!")
    print("=" * 70)


if __name__ == "__main__":
    main()

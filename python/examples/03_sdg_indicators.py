"""
Example 3: Working with SDG Indicators
=======================================

This example demonstrates how to work with SDG (Sustainable Development Goals)
indicators and organize data by SDG targets.
"""

from unicef_api import UNICEFSDMXClient
from unicef_api.config import (
    get_all_sdg_targets,
    list_indicators_by_sdg,
    get_indicator_metadata,
    COMMON_INDICATORS
)
import pandas as pd


def main():
    print("=" * 70)
    print("UNICEF API - SDG Indicators Example")
    print("=" * 70)
    print()
    
    client = UNICEFSDMXClient()
    
    # Example 1: Discover available SDG targets
    print("1. Discovering available SDG targets...")
    all_targets = get_all_sdg_targets()
    print(f"   ✓ Found {len(all_targets)} SDG targets")
    print(f"   ✓ Targets: {all_targets[:10]}...")  # Show first 10
    print()
    
    # Example 2: Get indicators for a specific SDG target
    print("2. Getting indicators for SDG 3.2 (Child mortality)...")
    sdg_3_2_1_indicators = list_indicators_by_sdg('3.2.1')
    print(f"   ✓ SDG 3.2.1 indicators: {sdg_3_2_1_indicators}")
    
    # Show metadata
    for indicator in sdg_3_2_1_indicators:
        meta = get_indicator_metadata(indicator)
        print(f"     - {indicator}: {meta['name']}")
    print()
    
    # Example 3: Fetch SDG 3.2 indicators (Child mortality)
    print("3. Fetching SDG 3.2 child mortality indicators...")
    countries = ['BRA', 'IND', 'NGA', 'ETH', 'BGD']
    
    mortality_data = []
    for indicator in ['CME_MRM0', 'CME_MRY0T4']:
        df = client.fetch_indicator(
            indicator,
            countries=countries,
            start_year=2015,
            end_year=2023
        )
        mortality_data.append(df)
    
    df_mortality = pd.concat(mortality_data, ignore_index=True)
    print(f"   ✓ Downloaded {len(df_mortality)} observations")
    print()
    
    # Example 4: Fetch SDG 4.1 education indicators
    print("4. Fetching SDG 4.1 education indicators...")
    education_indicators = [
        'ED_CR_L1_UIS_MOD',
        'ED_CR_L2_UIS_MOD',
    ]
    
    df_education = client.fetch_multiple_indicators(
        education_indicators,
        countries=countries,
        start_year=2015,
        dataflow='EDUCATION_UIS_SDG',  # Use specific dataflow
        combine=True
    )
    print(f"   ✓ Downloaded {len(df_education)} observations")
    print()
    
    # Example 5: Fetch SDG 6 WASH indicators
    print("5. Fetching SDG 6 WASH indicators...")
    wash_indicators = [
        'WS_PPL_W-SM',  # SDG 6.1.1
        'WS_PPL_S-SM',  # SDG 6.2.1
    ]
    
    df_wash = client.fetch_multiple_indicators(
        wash_indicators,
        countries=countries,
        start_year=2015,
        combine=True
    )
    print(f"   ✓ Downloaded {len(df_wash)} observations")
    print()
    
    # Example 6: Create SDG dashboard data
    print("6. Creating SDG dashboard dataset...")
    
    # Combine all SDG indicators
    df_sdg = pd.concat([
        df_mortality,
        df_education,
        df_wash
    ], ignore_index=True)
    
    # Add SDG metadata
    df_sdg['sdg_target'] = df_sdg['indicator_code'].apply(
        lambda x: get_indicator_metadata(x)['sdg'] if get_indicator_metadata(x) else None
    )
    
    print(f"   ✓ Total SDG observations: {len(df_sdg)}")
    print(f"   ✓ Unique SDG targets: {df_sdg['sdg_target'].nunique()}")
    print()
    
    # Summary by SDG target
    print("7. Summary by SDG target:")
    sdg_summary = df_sdg.groupby('sdg_target').agg({
        'indicator_code': 'nunique',
        'country_code': 'nunique',
        'value': 'count'
    }).rename(columns={
        'indicator_code': 'n_indicators',
        'country_code': 'n_countries',
        'value': 'n_observations'
    })
    print(sdg_summary)
    print()
    
    # Example 7: Latest values by country and SDG
    print("8. Getting latest values by country and SDG target...")
    latest_values = df_sdg.sort_values('year').groupby(
        ['country_code', 'indicator_code']
    ).last().reset_index()
    
    print(f"   ✓ Latest values: {len(latest_values)} observations")
    print()
    print("   Sample of latest values:")
    print(latest_values[['country_code', 'indicator_code', 'year', 'value']].head(10))
    print()
    
    # Save outputs
    print("9. Saving SDG data...")
    df_sdg.to_csv('sdg_indicators.csv', index=False)
    latest_values.to_csv('sdg_latest_values.csv', index=False)
    print("   ✓ Data saved")
    print()
    
    print("=" * 70)
    print("Example completed successfully!")
    print("=" * 70)


if __name__ == "__main__":
    main()

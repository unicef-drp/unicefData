"""
Example 1: Basic Usage - Downloading UNICEF Indicators
=======================================================

This example demonstrates basic usage of the unicef-api library
to download child welfare indicators from the UNICEF SDMX API.
"""

from unicef_api import UNICEFSDMXClient

def main():
    print("=" * 70)
    print("UNICEF API - Basic Usage Example")
    print("=" * 70)
    print()
    
    # Initialize client
    print("1. Initializing UNICEF SDMX client...")
    client = UNICEFSDMXClient()
    print("   ✓ Client initialized")
    print()
    
    # Example 1: Fetch under-5 mortality for specific countries
    print("2. Fetching under-5 mortality (CME_MRY0T4) for Albania, USA, Brazil...")
    df = client.fetch_indicator(
        'CME_MRY0T4',
        countries=['ALB', 'USA', 'BRA'],
        start_year=2015,
        end_year=2023
    )
    
    print(f"   ✓ Downloaded {len(df)} observations")
    print(f"   ✓ Countries: {df['country_code'].unique().tolist()}")
    print(f"   ✓ Year range: {df['year'].min()} - {df['year'].max()}")
    print()
    print("   First few rows:")
    print(df.head(10))
    print()
    
    # Example 2: Fetch all countries for a single year
    print("3. Fetching stunting prevalence (NT_ANT_HAZ_NE2_MOD) for all countries...")
    df_all = client.fetch_indicator(
        'NT_ANT_HAZ_NE2_MOD',
        start_year=2020,
        end_year=2020
    )
    
    print(f"   ✓ Downloaded data for {df_all['country_code'].nunique()} countries")
    print(f"   ✓ Total observations: {len(df_all)}")
    print()
    
    # Example 3: Fetch immunization data with specific dataflow
    print("4. Fetching DTP3 immunization coverage using IMMUNISATION dataflow...")
    df_immun = client.fetch_indicator(
        'IM_DTP3',
        dataflow='IMMUNISATION',
        countries=['IND', 'BGD', 'PAK'],
        start_year=2018,
        end_year=2023
    )
    
    print(f"   ✓ Downloaded {len(df_immun)} observations")
    print()
    print("   Summary statistics:")
    print(df_immun.groupby('country_code')['value'].describe())
    print()
    
    # Save to CSV
    print("5. Saving data to CSV files...")
    df.to_csv('mortality_data.csv', index=False)
    df_all.to_csv('stunting_data.csv', index=False)
    df_immun.to_csv('immunization_data.csv', index=False)
    print("   ✓ Data saved to CSV files")
    print()
    
    print("=" * 70)
    print("Example completed successfully!")
    print("=" * 70)


if __name__ == "__main__":
    main()

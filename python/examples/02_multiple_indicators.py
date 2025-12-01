"""
Example 2: Fetching Multiple Indicators
========================================

This example demonstrates how to fetch multiple indicators efficiently
and combine them into a single dataset for analysis.
"""

from unicef_api import UNICEFSDMXClient
from unicef_api.config import list_indicators_by_dataflow
import pandas as pd


def main():
    print("=" * 70)
    print("UNICEF API - Multiple Indicators Example")
    print("=" * 70)
    print()
    
    client = UNICEFSDMXClient()
    
    # Define countries of interest
    countries = ['IND', 'BGD', 'PAK', 'NPL', 'LKA']  # South Asian countries
    
    # Example 1: Fetch multiple mortality indicators
    print("1. Fetching multiple mortality indicators...")
    mortality_indicators = ['CME_MRM0', 'CME_MRY0T4']
    
    df_mortality = client.fetch_multiple_indicators(
        mortality_indicators,
        countries=countries,
        start_year=2015,
        end_year=2023,
        combine=True
    )
    
    print(f"   ✓ Downloaded {len(df_mortality)} observations")
    print(f"   ✓ Indicators: {df_mortality['indicator_code'].unique().tolist()}")
    print()
    
    # Example 2: Fetch nutrition indicators
    print("2. Fetching nutrition indicators...")
    nutrition_indicators = [
        'NT_ANT_HAZ_NE2_MOD',  # Stunting
        'NT_ANT_WHZ_NE2',      # Wasting
        'NT_ANT_WHZ_PO2_MOD',  # Overweight
    ]
    
    df_nutrition = client.fetch_multiple_indicators(
        nutrition_indicators,
        countries=countries,
        start_year=2015,
        end_year=2023,
        combine=True
    )
    
    print(f"   ✓ Downloaded {len(df_nutrition)} observations")
    print()
    
    # Example 3: Fetch education indicators
    print("3. Fetching education indicators...")
    education_indicators = [
        'ED_CR_L1_UIS_MOD',  # Primary completion
        'ED_CR_L2_UIS_MOD',  # Lower secondary completion
    ]
    
    df_education = client.fetch_multiple_indicators(
        education_indicators,
        countries=countries,
        start_year=2015,
        end_year=2023,
        dataflow='EDUCATION_UIS_SDG',  # Use specific dataflow
        combine=True
    )
    
    print(f"   ✓ Downloaded {len(df_education)} observations")
    print()
    
    # Example 4: Get separate DataFrames (not combined)
    print("4. Fetching indicators as separate DataFrames...")
    immunization_indicators = ['IM_DTP3', 'IM_MCV1']
    
    df_dict = client.fetch_multiple_indicators(
        immunization_indicators,
        countries=countries,
        start_year=2020,
        combine=False  # Return as dictionary
    )
    
    for indicator, df in df_dict.items():
        print(f"   ✓ {indicator}: {len(df)} observations")
    print()
    
    # Combine all datasets
    print("5. Combining all datasets...")
    all_data = pd.concat([
        df_mortality,
        df_nutrition,
        df_education,
    ], ignore_index=True)
    
    print(f"   ✓ Total observations: {len(all_data)}")
    print(f"   ✓ Unique indicators: {all_data['indicator_code'].nunique()}")
    print(f"   ✓ Countries: {all_data['country_code'].nunique()}")
    print()
    
    # Summary by indicator
    print("6. Summary by indicator:")
    summary = all_data.groupby('indicator_code').agg({
        'country_code': 'nunique',
        'year': ['min', 'max'],
        'value': ['count', 'mean', 'std']
    }).round(2)
    print(summary)
    print()
    
    # Save combined dataset
    print("7. Saving combined dataset...")
    all_data.to_csv('combined_indicators.csv', index=False)
    print("   ✓ Saved to combined_indicators.csv")
    print()
    
    print("=" * 70)
    print("Example completed successfully!")
    print("=" * 70)


if __name__ == "__main__":
    main()

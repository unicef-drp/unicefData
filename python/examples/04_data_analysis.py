"""
Example 4: Data Analysis and Transformation
============================================

This example demonstrates data cleaning, transformation, and analysis
techniques using the utility functions.
"""

from unicef_api import UNICEFSDMXClient
from unicef_api.utils import (
    clean_dataframe,
    pivot_wide,
    calculate_growth_rate,
    merge_with_country_names
)
import pandas as pd


def main():
    print("=" * 70)
    print("UNICEF API - Data Analysis Example")
    print("=" * 70)
    print()
    
    client = UNICEFSDMXClient()
    
    # Fetch sample data
    print("1. Fetching sample data...")
    countries = ['BRA', 'IND', 'NGA', 'ETH', 'BGD', 'PAK', 'IDN', 'MEX']
    
    df = client.fetch_indicator(
        'CME_MRY0T4',  # Under-5 mortality
        countries=countries,
        start_year=2000,
        end_year=2023
    )
    
    print(f"   ✓ Downloaded {len(df)} observations")
    print()
    
    # Example 1: Clean data
    print("2. Cleaning data...")
    df_clean = clean_dataframe(
        df,
        remove_nulls=True,
        remove_duplicates=True,
        sort_by=['country_code', 'year']
    )
    
    print(f"   ✓ Cleaned: {len(df_clean)} observations (removed {len(df) - len(df_clean)})")
    print()
    
    # Example 2: Add country names
    print("3. Adding country names...")
    df_clean = merge_with_country_names(df_clean)
    print(f"   ✓ Added country names")
    print(df_clean[['country_code', 'country_name', 'year', 'value']].head())
    print()
    
    # Example 3: Calculate growth rates
    print("4. Calculating year-over-year change...")
    df_growth = calculate_growth_rate(
        df_clean,
        value_col='value',
        group_cols=['country_code'],
        periods=1
    )
    
    print(f"   ✓ Calculated growth rates")
    print()
    print("   Countries with largest recent decline (improvement):")
    recent_data = df_growth[df_growth['year'] >= 2020].copy()
    top_improvers = recent_data.groupby('country_code')['growth_rate'].mean().sort_values().head(5)
    for country, rate in top_improvers.items():
        print(f"     {country}: {rate:.2f}% annual change")
    print()
    
    # Example 4: Pivot to wide format
    print("5. Pivoting data to wide format...")
    df_wide = pivot_wide(
        df_clean,
        index_cols=['country_code', 'country_name'],
        values_col='value',
        columns_col='year'
    )
    
    print(f"   ✓ Created wide format: {df_wide.shape[0]} rows × {df_wide.shape[1]} columns")
    print()
    print("   Wide format preview:")
    print(df_wide.head())
    print()
    
    # Example 5: Calculate summary statistics
    print("6. Calculating summary statistics by country...")
    stats = df_clean.groupby('country_code')['value'].agg([
        'count', 'mean', 'std', 'min', 'max'
    ]).round(2)
    
    print(stats)
    print()
    
    # Example 6: Trend analysis
    print("7. Analyzing trends (2000 vs 2023)...")
    df_2000 = df_clean[df_clean['year'] == 2000].set_index('country_code')['value']
    df_2023 = df_clean[df_clean['year'] == 2023].set_index('country_code')['value']
    
    trend_comparison = pd.DataFrame({
        '2000': df_2000,
        '2023': df_2023,
        'Change': df_2023 - df_2000,
        'Pct_Change': ((df_2023 - df_2000) / df_2000 * 100).round(2)
    })
    
    print(trend_comparison)
    print()
    
    # Example 7: Regional aggregation
    print("8. Creating country groupings for analysis...")
    
    # Define regions (simplified)
    regions = {
        'BRA': 'Latin America',
        'MEX': 'Latin America',
        'IND': 'South Asia',
        'BGD': 'South Asia',
        'PAK': 'South Asia',
        'NGA': 'Sub-Saharan Africa',
        'ETH': 'Sub-Saharan Africa',
        'IDN': 'East Asia & Pacific',
    }
    
    df_clean['region'] = df_clean['country_code'].map(regions)
    
    regional_avg = df_clean.groupby(['region', 'year'])['value'].mean().reset_index()
    print(f"   ✓ Calculated regional averages")
    print()
    
    # Show latest regional values
    latest_regional = regional_avg[regional_avg['year'] == 2023]
    print("   Latest regional averages (2023):")
    for _, row in latest_regional.iterrows():
        print(f"     {row['region']}: {row['value']:.2f}")
    print()
    
    # Save outputs
    print("9. Saving analysis results...")
    df_clean.to_csv('mortality_analysis.csv', index=False)
    df_wide.to_csv('mortality_wide.csv', index=False)
    df_growth.to_csv('mortality_growth.csv', index=False)
    trend_comparison.to_csv('mortality_trends.csv')
    regional_avg.to_csv('mortality_regional.csv', index=False)
    
    print("   ✓ All analysis results saved")
    print()
    
    print("=" * 70)
    print("Example completed successfully!")
    print("=" * 70)


if __name__ == "__main__":
    main()

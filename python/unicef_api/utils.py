"""
Utility Functions for UNICEF API
=================================

Helper functions for validating inputs, cleaning data, and managing country codes.
"""

import pandas as pd
from typing import List, Optional, Set
import re


def validate_country_codes(
    country_codes: List[str], 
    valid_codes: Optional[Set[str]] = None
) -> List[str]:
    """
    Validate ISO 3166-1 alpha-3 country codes
    
    Args:
        country_codes: List of country codes to validate
        valid_codes: Set of valid country codes (optional)
    
    Returns:
        List of valid country codes
        
    Raises:
        ValueError: If invalid country codes are found
        
    Example:
        >>> validate_country_codes(['USA', 'BRA', 'ALB'])
        ['USA', 'BRA', 'ALB']
        >>> validate_country_codes(['US'])  # Raises ValueError
    """
    invalid_codes = []
    
    for code in country_codes:
        if not isinstance(code, str):
            invalid_codes.append(str(code))
        elif len(code) != 3:
            invalid_codes.append(code)
        elif not code.isupper():
            invalid_codes.append(code)
        elif valid_codes and code not in valid_codes:
            invalid_codes.append(code)
    
    if invalid_codes:
        raise ValueError(
            f"Invalid country codes found: {invalid_codes}. "
            f"Country codes must be 3-letter uppercase ISO 3166-1 alpha-3 codes "
            f"(e.g., 'USA', 'BRA', 'ALB')."
        )
    
    return country_codes


def validate_year_range(
    start_year: Optional[int], 
    end_year: Optional[int]
) -> tuple:
    """
    Validate year range parameters
    
    Args:
        start_year: Starting year (or None)
        end_year: Ending year (or None)
    
    Returns:
        Tuple of (start_year, end_year)
        
    Raises:
        ValueError: If year range is invalid
        
    Example:
        >>> validate_year_range(2015, 2023)
        (2015, 2023)
        >>> validate_year_range(2023, 2015)  # Raises ValueError
    """
    if start_year is not None:
        if not isinstance(start_year, int):
            raise ValueError(f"start_year must be an integer, got {type(start_year)}")
        if start_year < 1900 or start_year > 2100:
            raise ValueError(f"start_year must be between 1900 and 2100, got {start_year}")
    
    if end_year is not None:
        if not isinstance(end_year, int):
            raise ValueError(f"end_year must be an integer, got {type(end_year)}")
        if end_year < 1900 or end_year > 2100:
            raise ValueError(f"end_year must be between 1900 and 2100, got {end_year}")
    
    if start_year is not None and end_year is not None:
        if start_year > end_year:
            raise ValueError(
                f"start_year ({start_year}) cannot be greater than end_year ({end_year})"
            )
    
    return start_year, end_year


def validate_indicator_code(indicator_code: str) -> str:
    """
    Validate UNICEF indicator code format
    
    Args:
        indicator_code: Indicator code to validate
    
    Returns:
        Validated indicator code
        
    Raises:
        ValueError: If indicator code is invalid
        
    Example:
        >>> validate_indicator_code('CME_MRY0T4')
        'CME_MRY0T4'
        >>> validate_indicator_code('')  # Raises ValueError
    """
    if not indicator_code or not isinstance(indicator_code, str):
        raise ValueError(
            f"Indicator code must be a non-empty string, got: {repr(indicator_code)}"
        )
    
    # Basic validation: should contain only alphanumeric characters, underscores, and hyphens
    if not re.match(r'^[A-Z0-9_-]+$', indicator_code.upper()):
        raise ValueError(
            f"Invalid indicator code format: '{indicator_code}'. "
            f"Indicator codes should contain only letters, numbers, underscores, and hyphens."
        )
    
    return indicator_code


def clean_dataframe(
    df: pd.DataFrame,
    remove_nulls: bool = True,
    remove_duplicates: bool = True,
    sort_by: Optional[List[str]] = None,
) -> pd.DataFrame:
    """
    Clean and standardize a DataFrame
    
    Args:
        df: DataFrame to clean
        remove_nulls: Remove rows with null values in key columns
        remove_duplicates: Remove duplicate rows
        sort_by: List of columns to sort by
    
    Returns:
        Cleaned DataFrame
        
    Example:
        >>> df = clean_dataframe(df, sort_by=['country_code', 'year'])
    """
    df_clean = df.copy()
    
    if remove_nulls:
        # Remove rows with null values in critical columns
        critical_cols = ['country_code', 'year', 'value']
        existing_cols = [col for col in critical_cols if col in df_clean.columns]
        if existing_cols:
            df_clean = df_clean.dropna(subset=existing_cols)
    
    if remove_duplicates:
        # Remove duplicate rows
        df_clean = df_clean.drop_duplicates()
    
    if sort_by:
        # Sort by specified columns
        existing_sort_cols = [col for col in sort_by if col in df_clean.columns]
        if existing_sort_cols:
            df_clean = df_clean.sort_values(existing_sort_cols)
    
    # Reset index
    df_clean = df_clean.reset_index(drop=True)
    
    return df_clean


def load_country_codes(file_path: Optional[str] = None) -> Set[str]:
    """
    Load valid ISO 3166-1 alpha-3 country codes
    
    Args:
        file_path: Path to file containing country codes (optional)
    
    Returns:
        Set of valid country codes
        
    Example:
        >>> codes = load_country_codes()
        >>> 'USA' in codes
        True
    """
    # Standard ISO 3166-1 alpha-3 codes (partial list - comprehensive list should be loaded from file)
    # This is a fallback if no file is provided
    standard_codes = {
        'AFG', 'ALB', 'DZA', 'AND', 'AGO', 'ATG', 'ARG', 'ARM', 'AUS', 'AUT',
        'AZE', 'BHS', 'BHR', 'BGD', 'BRB', 'BLR', 'BEL', 'BLZ', 'BEN', 'BTN',
        'BOL', 'BIH', 'BWA', 'BRA', 'BRN', 'BGR', 'BFA', 'BDI', 'KHM', 'CMR',
        'CAN', 'CPV', 'CAF', 'TCD', 'CHL', 'CHN', 'COL', 'COM', 'COG', 'COD',
        'CRI', 'CIV', 'HRV', 'CUB', 'CYP', 'CZE', 'DNK', 'DJI', 'DMA', 'DOM',
        'ECU', 'EGY', 'SLV', 'GNQ', 'ERI', 'EST', 'ETH', 'FJI', 'FIN', 'FRA',
        'GAB', 'GMB', 'GEO', 'DEU', 'GHA', 'GRC', 'GRD', 'GTM', 'GIN', 'GNB',
        'GUY', 'HTI', 'HND', 'HUN', 'ISL', 'IND', 'IDN', 'IRN', 'IRQ', 'IRL',
        'ISR', 'ITA', 'JAM', 'JPN', 'JOR', 'KAZ', 'KEN', 'KIR', 'PRK', 'KOR',
        'KWT', 'KGZ', 'LAO', 'LVA', 'LBN', 'LSO', 'LBR', 'LBY', 'LIE', 'LTU',
        'LUX', 'MKD', 'MDG', 'MWI', 'MYS', 'MDV', 'MLI', 'MLT', 'MHL', 'MRT',
        'MUS', 'MEX', 'FSM', 'MDA', 'MCO', 'MNG', 'MNE', 'MAR', 'MOZ', 'MMR',
        'NAM', 'NRU', 'NPL', 'NLD', 'NZL', 'NIC', 'NER', 'NGA', 'NOR', 'OMN',
        'PAK', 'PLW', 'PAN', 'PNG', 'PRY', 'PER', 'PHL', 'POL', 'PRT', 'QAT',
        'ROU', 'RUS', 'RWA', 'KNA', 'LCA', 'VCT', 'WSM', 'SMR', 'STP', 'SAU',
        'SEN', 'SRB', 'SYC', 'SLE', 'SGP', 'SVK', 'SVN', 'SLB', 'SOM', 'ZAF',
        'SSD', 'ESP', 'LKA', 'SDN', 'SUR', 'SWZ', 'SWE', 'CHE', 'SYR', 'TJK',
        'TZA', 'THA', 'TLS', 'TGO', 'TON', 'TTO', 'TUN', 'TUR', 'TKM', 'TUV',
        'UGA', 'UKR', 'ARE', 'GBR', 'USA', 'URY', 'UZB', 'VUT', 'VEN', 'VNM',
        'YEM', 'ZMB', 'ZWE',
        # UNICEF-specific territories
        'AIA', 'COK', 'MSR', 'NIU', 'PSE', 'TCA', 'TKL', 'VGB',
    }
    
    if file_path:
        try:
            # Load from file if provided
            with open(file_path, 'r') as f:
                loaded_codes = {line.strip() for line in f if line.strip()}
            return loaded_codes
        except FileNotFoundError:
            print(f"Warning: Country codes file not found at {file_path}. Using standard codes.")
            return standard_codes
    
    return standard_codes


def merge_with_country_names(
    df: pd.DataFrame,
    country_col: str = 'country_code',
) -> pd.DataFrame:
    """
    Add country names to DataFrame based on ISO3 codes
    
    Args:
        df: DataFrame with country codes
        country_col: Name of column containing country codes
    
    Returns:
        DataFrame with added 'country_name' column
        
    Example:
        >>> df = merge_with_country_names(df)
    """
    # Basic country name mapping (should ideally be loaded from comprehensive source)
    country_names = {
        'AFG': 'Afghanistan', 'ALB': 'Albania', 'DZA': 'Algeria', 'ARG': 'Argentina',
        'ARM': 'Armenia', 'AUS': 'Australia', 'AUT': 'Austria', 'AZE': 'Azerbaijan',
        'BGD': 'Bangladesh', 'BLR': 'Belarus', 'BEL': 'Belgium', 'BEN': 'Benin',
        'BOL': 'Bolivia', 'BIH': 'Bosnia and Herzegovina', 'BWA': 'Botswana', 
        'BRA': 'Brazil', 'BGR': 'Bulgaria', 'BFA': 'Burkina Faso', 'BDI': 'Burundi',
        'KHM': 'Cambodia', 'CMR': 'Cameroon', 'CAN': 'Canada', 'CAF': 'Central African Republic',
        'TCD': 'Chad', 'CHL': 'Chile', 'CHN': 'China', 'COL': 'Colombia',
        'COD': 'Democratic Republic of the Congo', 'COG': 'Congo', 'CRI': 'Costa Rica',
        'CIV': "Côte d'Ivoire", 'HRV': 'Croatia', 'CUB': 'Cuba', 'CYP': 'Cyprus',
        'CZE': 'Czech Republic', 'DNK': 'Denmark', 'DOM': 'Dominican Republic',
        'ECU': 'Ecuador', 'EGY': 'Egypt', 'SLV': 'El Salvador', 'EST': 'Estonia',
        'ETH': 'Ethiopia', 'FIN': 'Finland', 'FRA': 'France', 'GAB': 'Gabon',
        'GMB': 'Gambia', 'GEO': 'Georgia', 'DEU': 'Germany', 'GHA': 'Ghana',
        'GRC': 'Greece', 'GTM': 'Guatemala', 'GIN': 'Guinea', 'HTI': 'Haiti',
        'HND': 'Honduras', 'HUN': 'Hungary', 'ISL': 'Iceland', 'IND': 'India',
        'IDN': 'Indonesia', 'IRN': 'Iran', 'IRQ': 'Iraq', 'IRL': 'Ireland',
        'ISR': 'Israel', 'ITA': 'Italy', 'JAM': 'Jamaica', 'JPN': 'Japan',
        'JOR': 'Jordan', 'KAZ': 'Kazakhstan', 'KEN': 'Kenya', 'KOR': 'South Korea',
        'KWT': 'Kuwait', 'KGZ': 'Kyrgyzstan', 'LAO': 'Laos', 'LVA': 'Latvia',
        'LBN': 'Lebanon', 'LSO': 'Lesotho', 'LBR': 'Liberia', 'LBY': 'Libya',
        'LTU': 'Lithuania', 'LUX': 'Luxembourg', 'MKD': 'North Macedonia',
        'MDG': 'Madagascar', 'MWI': 'Malawi', 'MYS': 'Malaysia', 'MLI': 'Mali',
        'MLT': 'Malta', 'MRT': 'Mauritania', 'MUS': 'Mauritius', 'MEX': 'Mexico',
        'MDA': 'Moldova', 'MNG': 'Mongolia', 'MNE': 'Montenegro', 'MAR': 'Morocco',
        'MOZ': 'Mozambique', 'MMR': 'Myanmar', 'NAM': 'Namibia', 'NPL': 'Nepal',
        'NLD': 'Netherlands', 'NZL': 'New Zealand', 'NIC': 'Nicaragua', 'NER': 'Niger',
        'NGA': 'Nigeria', 'NOR': 'Norway', 'PAK': 'Pakistan', 'PAN': 'Panama',
        'PNG': 'Papua New Guinea', 'PRY': 'Paraguay', 'PER': 'Peru', 'PHL': 'Philippines',
        'POL': 'Poland', 'PRT': 'Portugal', 'ROU': 'Romania', 'RUS': 'Russia',
        'RWA': 'Rwanda', 'SAU': 'Saudi Arabia', 'SEN': 'Senegal', 'SRB': 'Serbia',
        'SLE': 'Sierra Leone', 'SGP': 'Singapore', 'SVK': 'Slovakia', 'SVN': 'Slovenia',
        'SOM': 'Somalia', 'ZAF': 'South Africa', 'SSD': 'South Sudan', 'ESP': 'Spain',
        'LKA': 'Sri Lanka', 'SDN': 'Sudan', 'SWE': 'Sweden', 'CHE': 'Switzerland',
        'SYR': 'Syria', 'TJK': 'Tajikistan', 'TZA': 'Tanzania', 'THA': 'Thailand',
        'TGO': 'Togo', 'TUN': 'Tunisia', 'TUR': 'Turkey', 'TKM': 'Turkmenistan',
        'UGA': 'Uganda', 'UKR': 'Ukraine', 'ARE': 'United Arab Emirates',
        'GBR': 'United Kingdom', 'USA': 'United States', 'URY': 'Uruguay',
        'UZB': 'Uzbekistan', 'VEN': 'Venezuela', 'VNM': 'Vietnam', 'YEM': 'Yemen',
        'ZMB': 'Zambia', 'ZWE': 'Zimbabwe',
        # UNICEF-specific territories
        'PSE': 'Palestine', 'COK': 'Cook Islands', 'NIU': 'Niue',
    }
    
    if country_col in df.columns:
        df['country_name'] = df[country_col].map(country_names)
    
    return df


def pivot_wide(
    df: pd.DataFrame,
    index_cols: List[str] = ['country_code', 'year'],
    values_col: str = 'value',
    columns_col: str = 'indicator_code',
) -> pd.DataFrame:
    """
    Pivot DataFrame from long to wide format
    
    Args:
        df: DataFrame in long format
        index_cols: Columns to use as index
        values_col: Column containing values to pivot
        columns_col: Column to pivot into column names
    
    Returns:
        DataFrame in wide format
        
    Example:
        >>> wide_df = pivot_wide(df, index_cols=['country_code', 'year'])
    """
    return df.pivot_table(
        index=index_cols,
        columns=columns_col,
        values=values_col,
        aggfunc='first'  # Take first value if duplicates exist
    ).reset_index()


def calculate_growth_rate(
    df: pd.DataFrame,
    value_col: str = 'value',
    group_cols: List[str] = ['country_code', 'indicator_code'],
    periods: int = 1,
) -> pd.DataFrame:
    """
    Calculate period-over-period growth rates
    
    Args:
        df: DataFrame with time series data
        value_col: Column containing values
        group_cols: Columns to group by
        periods: Number of periods for growth calculation
    
    Returns:
        DataFrame with added 'growth_rate' column
        
    Example:
        >>> df = calculate_growth_rate(df, periods=1)  # Year-over-year growth
    """
    df = df.copy()
    df = df.sort_values(group_cols + ['year'])
    
    df['growth_rate'] = df.groupby(group_cols)[value_col].pct_change(periods=periods) * 100
    
    return df

def get_country_regions() -> dict:
    """Get ISO3 to UNICEF region mapping."""
    # Comprehensive mapping based on UNICEF regional classifications
    regions = {
        # East Asia and Pacific
        'AUS': 'East Asia and Pacific', 'BRN': 'East Asia and Pacific', 'KHM': 'East Asia and Pacific',
        'CHN': 'East Asia and Pacific', 'PRK': 'East Asia and Pacific', 'FJI': 'East Asia and Pacific',
        'IDN': 'East Asia and Pacific', 'JPN': 'East Asia and Pacific', 'KIR': 'East Asia and Pacific',
        'LAO': 'East Asia and Pacific', 'MYS': 'East Asia and Pacific', 'MHL': 'East Asia and Pacific',
        'FSM': 'East Asia and Pacific', 'MNG': 'East Asia and Pacific', 'MMR': 'East Asia and Pacific',
        'NRU': 'East Asia and Pacific', 'NZL': 'East Asia and Pacific', 'PLW': 'East Asia and Pacific',
        'PNG': 'East Asia and Pacific', 'PHL': 'East Asia and Pacific', 'WSM': 'East Asia and Pacific',
        'SGP': 'East Asia and Pacific', 'SLB': 'East Asia and Pacific', 'KOR': 'East Asia and Pacific',
        'THA': 'East Asia and Pacific', 'TLS': 'East Asia and Pacific', 'TON': 'East Asia and Pacific',
        'TUV': 'East Asia and Pacific', 'VUT': 'East Asia and Pacific', 'VNM': 'East Asia and Pacific',
        # Europe and Central Asia
        'ALB': 'Europe and Central Asia', 'ARM': 'Europe and Central Asia', 'AUT': 'Europe and Central Asia',
        'AZE': 'Europe and Central Asia', 'BLR': 'Europe and Central Asia', 'BEL': 'Europe and Central Asia',
        'BIH': 'Europe and Central Asia', 'BGR': 'Europe and Central Asia', 'HRV': 'Europe and Central Asia',
        'CYP': 'Europe and Central Asia', 'CZE': 'Europe and Central Asia', 'DNK': 'Europe and Central Asia',
        'EST': 'Europe and Central Asia', 'FIN': 'Europe and Central Asia', 'FRA': 'Europe and Central Asia',
        'GEO': 'Europe and Central Asia', 'DEU': 'Europe and Central Asia', 'GRC': 'Europe and Central Asia',
        'HUN': 'Europe and Central Asia', 'ISL': 'Europe and Central Asia', 'IRL': 'Europe and Central Asia',
        'ITA': 'Europe and Central Asia', 'KAZ': 'Europe and Central Asia', 'KGZ': 'Europe and Central Asia',
        'LVA': 'Europe and Central Asia', 'LTU': 'Europe and Central Asia', 'LUX': 'Europe and Central Asia',
        'MKD': 'Europe and Central Asia', 'MLT': 'Europe and Central Asia', 'MDA': 'Europe and Central Asia',
        'MNE': 'Europe and Central Asia', 'NLD': 'Europe and Central Asia', 'NOR': 'Europe and Central Asia',
        'POL': 'Europe and Central Asia', 'PRT': 'Europe and Central Asia', 'ROU': 'Europe and Central Asia',
        'RUS': 'Europe and Central Asia', 'SRB': 'Europe and Central Asia', 'SVK': 'Europe and Central Asia',
        'SVN': 'Europe and Central Asia', 'ESP': 'Europe and Central Asia', 'SWE': 'Europe and Central Asia',
        'CHE': 'Europe and Central Asia', 'TJK': 'Europe and Central Asia', 'TUR': 'Europe and Central Asia',
        'TKM': 'Europe and Central Asia', 'UKR': 'Europe and Central Asia', 'GBR': 'Europe and Central Asia',
        'UZB': 'Europe and Central Asia',
        # Latin America and Caribbean
        'ATG': 'Latin America and Caribbean', 'ARG': 'Latin America and Caribbean', 'BHS': 'Latin America and Caribbean',
        'BRB': 'Latin America and Caribbean', 'BLZ': 'Latin America and Caribbean', 'BOL': 'Latin America and Caribbean',
        'BRA': 'Latin America and Caribbean', 'CHL': 'Latin America and Caribbean', 'COL': 'Latin America and Caribbean',
        'CRI': 'Latin America and Caribbean', 'CUB': 'Latin America and Caribbean', 'DMA': 'Latin America and Caribbean',
        'DOM': 'Latin America and Caribbean', 'ECU': 'Latin America and Caribbean', 'SLV': 'Latin America and Caribbean',
        'GRD': 'Latin America and Caribbean', 'GTM': 'Latin America and Caribbean', 'GUY': 'Latin America and Caribbean',
        'HTI': 'Latin America and Caribbean', 'HND': 'Latin America and Caribbean', 'JAM': 'Latin America and Caribbean',
        'MEX': 'Latin America and Caribbean', 'NIC': 'Latin America and Caribbean', 'PAN': 'Latin America and Caribbean',
        'PRY': 'Latin America and Caribbean', 'PER': 'Latin America and Caribbean', 'KNA': 'Latin America and Caribbean',
        'LCA': 'Latin America and Caribbean', 'VCT': 'Latin America and Caribbean', 'SUR': 'Latin America and Caribbean',
        'TTO': 'Latin America and Caribbean', 'URY': 'Latin America and Caribbean', 'VEN': 'Latin America and Caribbean',
        # Middle East and North Africa
        'DZA': 'Middle East and North Africa', 'BHR': 'Middle East and North Africa', 'DJI': 'Middle East and North Africa',
        'EGY': 'Middle East and North Africa', 'IRN': 'Middle East and North Africa', 'IRQ': 'Middle East and North Africa',
        'ISR': 'Middle East and North Africa', 'JOR': 'Middle East and North Africa', 'KWT': 'Middle East and North Africa',
        'LBN': 'Middle East and North Africa', 'LBY': 'Middle East and North Africa', 'MAR': 'Middle East and North Africa',
        'OMN': 'Middle East and North Africa', 'QAT': 'Middle East and North Africa', 'SAU': 'Middle East and North Africa',
        'SDN': 'Middle East and North Africa', 'SYR': 'Middle East and North Africa', 'TUN': 'Middle East and North Africa',
        'ARE': 'Middle East and North Africa', 'YEM': 'Middle East and North Africa', 'PSE': 'Middle East and North Africa',
        # North America
        'CAN': 'North America', 'USA': 'North America',
        # South Asia
        'AFG': 'South Asia', 'BGD': 'South Asia', 'BTN': 'South Asia', 'IND': 'South Asia',
        'MDV': 'South Asia', 'NPL': 'South Asia', 'PAK': 'South Asia', 'LKA': 'South Asia',
        # Sub-Saharan Africa
        'AGO': 'Sub-Saharan Africa', 'BEN': 'Sub-Saharan Africa', 'BWA': 'Sub-Saharan Africa',
        'BFA': 'Sub-Saharan Africa', 'BDI': 'Sub-Saharan Africa', 'CPV': 'Sub-Saharan Africa',
        'CMR': 'Sub-Saharan Africa', 'CAF': 'Sub-Saharan Africa', 'TCD': 'Sub-Saharan Africa',
        'COM': 'Sub-Saharan Africa', 'COG': 'Sub-Saharan Africa', 'COD': 'Sub-Saharan Africa',
        'CIV': 'Sub-Saharan Africa', 'GNQ': 'Sub-Saharan Africa', 'ERI': 'Sub-Saharan Africa',
        'SWZ': 'Sub-Saharan Africa', 'ETH': 'Sub-Saharan Africa', 'GAB': 'Sub-Saharan Africa',
        'GMB': 'Sub-Saharan Africa', 'GHA': 'Sub-Saharan Africa', 'GIN': 'Sub-Saharan Africa',
        'GNB': 'Sub-Saharan Africa', 'KEN': 'Sub-Saharan Africa', 'LSO': 'Sub-Saharan Africa',
        'LBR': 'Sub-Saharan Africa', 'MDG': 'Sub-Saharan Africa', 'MWI': 'Sub-Saharan Africa',
        'MLI': 'Sub-Saharan Africa', 'MRT': 'Sub-Saharan Africa', 'MUS': 'Sub-Saharan Africa',
        'MOZ': 'Sub-Saharan Africa', 'NAM': 'Sub-Saharan Africa', 'NER': 'Sub-Saharan Africa',
        'NGA': 'Sub-Saharan Africa', 'RWA': 'Sub-Saharan Africa', 'STP': 'Sub-Saharan Africa',
        'SEN': 'Sub-Saharan Africa', 'SYC': 'Sub-Saharan Africa', 'SLE': 'Sub-Saharan Africa',
        'SOM': 'Sub-Saharan Africa', 'ZAF': 'Sub-Saharan Africa', 'SSD': 'Sub-Saharan Africa',
        'TZA': 'Sub-Saharan Africa', 'TGO': 'Sub-Saharan Africa', 'UGA': 'Sub-Saharan Africa',
        'ZMB': 'Sub-Saharan Africa', 'ZWE': 'Sub-Saharan Africa',
    }
    return regions


def get_income_groups() -> dict:
    """Get ISO3 to World Bank income group mapping."""
    # World Bank income classifications (FY2024)
    income = {
        # High income
        'AUS': 'High income', 'AUT': 'High income', 'BEL': 'High income', 'CAN': 'High income',
        'CHE': 'High income', 'CHL': 'High income', 'CZE': 'High income', 'DEU': 'High income',
        'DNK': 'High income', 'ESP': 'High income', 'EST': 'High income', 'FIN': 'High income',
        'FRA': 'High income', 'GBR': 'High income', 'GRC': 'High income', 'HUN': 'High income',
        'IRL': 'High income', 'ISL': 'High income', 'ISR': 'High income', 'ITA': 'High income',
        'JPN': 'High income', 'KOR': 'High income', 'LTU': 'High income', 'LUX': 'High income',
        'LVA': 'High income', 'NLD': 'High income', 'NOR': 'High income', 'NZL': 'High income',
        'POL': 'High income', 'PRT': 'High income', 'SAU': 'High income', 'SGP': 'High income',
        'SVK': 'High income', 'SVN': 'High income', 'SWE': 'High income', 'USA': 'High income',
        'URY': 'High income', 'ARE': 'High income', 'BHR': 'High income', 'KWT': 'High income',
        'OMN': 'High income', 'QAT': 'High income', 'HRV': 'High income', 'CYP': 'High income',
        'MLT': 'High income', 'BRN': 'High income', 'TWN': 'High income', 'HKG': 'High income',
        'MAC': 'High income', 'PAN': 'High income', 'TTO': 'High income', 'BHS': 'High income',
        'BRB': 'High income', 'ATG': 'High income', 'KNA': 'High income', 'SYC': 'High income',
        'PLW': 'High income', 'NRU': 'High income', 'GUM': 'High income', 'PRI': 'High income',
        # Upper middle income
        'ARG': 'Upper middle income', 'BGR': 'Upper middle income', 'BRA': 'Upper middle income',
        'CHN': 'Upper middle income', 'COL': 'Upper middle income', 'CRI': 'Upper middle income',
        'DOM': 'Upper middle income', 'ECU': 'Upper middle income', 'GAB': 'Upper middle income',
        'GNQ': 'Upper middle income', 'GTM': 'Upper middle income', 'IRN': 'Upper middle income',
        'IRQ': 'Upper middle income', 'JAM': 'Upper middle income', 'JOR': 'Upper middle income',
        'KAZ': 'Upper middle income', 'LBN': 'Upper middle income', 'LBY': 'Upper middle income',
        'MEX': 'Upper middle income', 'MKD': 'Upper middle income', 'MNE': 'Upper middle income',
        'MUS': 'Upper middle income', 'MYS': 'Upper middle income', 'NAM': 'Upper middle income',
        'PER': 'Upper middle income', 'ROU': 'Upper middle income', 'RUS': 'Upper middle income',
        'SRB': 'Upper middle income', 'THA': 'Upper middle income', 'TUR': 'Upper middle income',
        'TKM': 'Upper middle income', 'VEN': 'Upper middle income', 'ZAF': 'Upper middle income',
        'ALB': 'Upper middle income', 'ARM': 'Upper middle income', 'AZE': 'Upper middle income',
        'BIH': 'Upper middle income', 'BWA': 'Upper middle income', 'CUB': 'Upper middle income',
        'DMA': 'Upper middle income', 'FJI': 'Upper middle income', 'GEO': 'Upper middle income',
        'GRD': 'Upper middle income', 'GUY': 'Upper middle income', 'LCA': 'Upper middle income',
        'MDV': 'Upper middle income', 'MHL': 'Upper middle income', 'PRY': 'Upper middle income',
        'SUR': 'Upper middle income', 'TON': 'Upper middle income', 'TUV': 'Upper middle income',
        'VCT': 'Upper middle income', 'XKX': 'Upper middle income',
        # Lower middle income
        'AGO': 'Lower middle income', 'BEN': 'Lower middle income', 'BGD': 'Lower middle income',
        'BLZ': 'Lower middle income', 'BOL': 'Lower middle income', 'BTN': 'Lower middle income',
        'CIV': 'Lower middle income', 'CMR': 'Lower middle income', 'COG': 'Lower middle income',
        'COM': 'Lower middle income', 'CPV': 'Lower middle income', 'DJI': 'Lower middle income',
        'DZA': 'Lower middle income', 'EGY': 'Lower middle income', 'GHA': 'Lower middle income',
        'HND': 'Lower middle income', 'HTI': 'Lower middle income', 'IDN': 'Lower middle income',
        'IND': 'Lower middle income', 'KEN': 'Lower middle income', 'KGZ': 'Lower middle income',
        'KHM': 'Lower middle income', 'KIR': 'Lower middle income', 'LAO': 'Lower middle income',
        'LKA': 'Lower middle income', 'LSO': 'Lower middle income', 'MAR': 'Lower middle income',
        'MDA': 'Lower middle income', 'MMR': 'Lower middle income', 'MNG': 'Lower middle income',
        'MRT': 'Lower middle income', 'NGA': 'Lower middle income', 'NIC': 'Lower middle income',
        'NPL': 'Lower middle income', 'PAK': 'Lower middle income', 'PHL': 'Lower middle income',
        'PNG': 'Lower middle income', 'PSE': 'Lower middle income', 'SEN': 'Lower middle income',
        'SLB': 'Lower middle income', 'SLV': 'Lower middle income', 'STP': 'Lower middle income',
        'SWZ': 'Lower middle income', 'TJK': 'Lower middle income', 'TLS': 'Lower middle income',
        'TUN': 'Lower middle income', 'TZA': 'Lower middle income', 'UKR': 'Lower middle income',
        'UZB': 'Lower middle income', 'VNM': 'Lower middle income', 'VUT': 'Lower middle income',
        'WSM': 'Lower middle income', 'ZMB': 'Lower middle income', 'ZWE': 'Lower middle income',
        # Low income
        'AFG': 'Low income', 'BDI': 'Low income', 'BFA': 'Low income', 'CAF': 'Low income',
        'COD': 'Low income', 'ERI': 'Low income', 'ETH': 'Low income', 'GMB': 'Low income',
        'GIN': 'Low income', 'GNB': 'Low income', 'LBR': 'Low income', 'MDG': 'Low income',
        'MLI': 'Low income', 'MOZ': 'Low income', 'MWI': 'Low income', 'NER': 'Low income',
        'PRK': 'Low income', 'RWA': 'Low income', 'SDN': 'Low income', 'SLE': 'Low income',
        'SOM': 'Low income', 'SSD': 'Low income', 'SYR': 'Low income', 'TCD': 'Low income',
        'TGO': 'Low income', 'UGA': 'Low income', 'YEM': 'Low income',
    }
    return income


def get_continents() -> dict:
    """Get ISO3 to continent mapping."""
    continents = {
        # Africa
        'DZA': 'Africa', 'AGO': 'Africa', 'BEN': 'Africa', 'BWA': 'Africa', 'BFA': 'Africa',
        'BDI': 'Africa', 'CPV': 'Africa', 'CMR': 'Africa', 'CAF': 'Africa', 'TCD': 'Africa',
        'COM': 'Africa', 'COG': 'Africa', 'COD': 'Africa', 'CIV': 'Africa', 'DJI': 'Africa',
        'EGY': 'Africa', 'GNQ': 'Africa', 'ERI': 'Africa', 'SWZ': 'Africa', 'ETH': 'Africa',
        'GAB': 'Africa', 'GMB': 'Africa', 'GHA': 'Africa', 'GIN': 'Africa', 'GNB': 'Africa',
        'KEN': 'Africa', 'LSO': 'Africa', 'LBR': 'Africa', 'LBY': 'Africa', 'MDG': 'Africa',
        'MWI': 'Africa', 'MLI': 'Africa', 'MRT': 'Africa', 'MUS': 'Africa', 'MAR': 'Africa',
        'MOZ': 'Africa', 'NAM': 'Africa', 'NER': 'Africa', 'NGA': 'Africa', 'RWA': 'Africa',
        'STP': 'Africa', 'SEN': 'Africa', 'SYC': 'Africa', 'SLE': 'Africa', 'SOM': 'Africa',
        'ZAF': 'Africa', 'SSD': 'Africa', 'SDN': 'Africa', 'TZA': 'Africa', 'TGO': 'Africa',
        'TUN': 'Africa', 'UGA': 'Africa', 'ZMB': 'Africa', 'ZWE': 'Africa',
        # Asia
        'AFG': 'Asia', 'ARM': 'Asia', 'AZE': 'Asia', 'BHR': 'Asia', 'BGD': 'Asia',
        'BTN': 'Asia', 'BRN': 'Asia', 'KHM': 'Asia', 'CHN': 'Asia', 'CYP': 'Asia',
        'GEO': 'Asia', 'IND': 'Asia', 'IDN': 'Asia', 'IRN': 'Asia', 'IRQ': 'Asia',
        'ISR': 'Asia', 'JPN': 'Asia', 'JOR': 'Asia', 'KAZ': 'Asia', 'KWT': 'Asia',
        'KGZ': 'Asia', 'LAO': 'Asia', 'LBN': 'Asia', 'MYS': 'Asia', 'MDV': 'Asia',
        'MNG': 'Asia', 'MMR': 'Asia', 'NPL': 'Asia', 'PRK': 'Asia', 'OMN': 'Asia',
        'PAK': 'Asia', 'PSE': 'Asia', 'PHL': 'Asia', 'QAT': 'Asia', 'SAU': 'Asia',
        'SGP': 'Asia', 'KOR': 'Asia', 'LKA': 'Asia', 'SYR': 'Asia', 'TJK': 'Asia',
        'THA': 'Asia', 'TLS': 'Asia', 'TUR': 'Asia', 'TKM': 'Asia', 'ARE': 'Asia',
        'UZB': 'Asia', 'VNM': 'Asia', 'YEM': 'Asia',
        # Europe
        'ALB': 'Europe', 'AND': 'Europe', 'AUT': 'Europe', 'BLR': 'Europe', 'BEL': 'Europe',
        'BIH': 'Europe', 'BGR': 'Europe', 'HRV': 'Europe', 'CZE': 'Europe', 'DNK': 'Europe',
        'EST': 'Europe', 'FIN': 'Europe', 'FRA': 'Europe', 'DEU': 'Europe', 'GRC': 'Europe',
        'HUN': 'Europe', 'ISL': 'Europe', 'IRL': 'Europe', 'ITA': 'Europe', 'LVA': 'Europe',
        'LIE': 'Europe', 'LTU': 'Europe', 'LUX': 'Europe', 'MLT': 'Europe', 'MDA': 'Europe',
        'MCO': 'Europe', 'MNE': 'Europe', 'NLD': 'Europe', 'MKD': 'Europe', 'NOR': 'Europe',
        'POL': 'Europe', 'PRT': 'Europe', 'ROU': 'Europe', 'RUS': 'Europe', 'SMR': 'Europe',
        'SRB': 'Europe', 'SVK': 'Europe', 'SVN': 'Europe', 'ESP': 'Europe', 'SWE': 'Europe',
        'CHE': 'Europe', 'UKR': 'Europe', 'GBR': 'Europe', 'VAT': 'Europe',
        # North America
        'ATG': 'North America', 'BHS': 'North America', 'BRB': 'North America', 'BLZ': 'North America',
        'CAN': 'North America', 'CRI': 'North America', 'CUB': 'North America', 'DMA': 'North America',
        'DOM': 'North America', 'SLV': 'North America', 'GRD': 'North America', 'GTM': 'North America',
        'HTI': 'North America', 'HND': 'North America', 'JAM': 'North America', 'MEX': 'North America',
        'NIC': 'North America', 'PAN': 'North America', 'KNA': 'North America', 'LCA': 'North America',
        'VCT': 'North America', 'TTO': 'North America', 'USA': 'North America',
        # South America
        'ARG': 'South America', 'BOL': 'South America', 'BRA': 'South America', 'CHL': 'South America',
        'COL': 'South America', 'ECU': 'South America', 'GUY': 'South America', 'PRY': 'South America',
        'PER': 'South America', 'SUR': 'South America', 'URY': 'South America', 'VEN': 'South America',
        # Oceania
        'AUS': 'Oceania', 'FJI': 'Oceania', 'KIR': 'Oceania', 'MHL': 'Oceania', 'FSM': 'Oceania',
        'NRU': 'Oceania', 'NZL': 'Oceania', 'PLW': 'Oceania', 'PNG': 'Oceania', 'WSM': 'Oceania',
        'SLB': 'Oceania', 'TON': 'Oceania', 'TUV': 'Oceania', 'VUT': 'Oceania',
    }
    return continents

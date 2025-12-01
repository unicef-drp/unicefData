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

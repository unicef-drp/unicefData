"""
Core UNICEF API Functions
=========================

Main functions for retrieving data from the UNICEF SDMX API.

Version: 1.6.1 - Unified fallback architecture (canonical YAML-based)
"""

import logging
from typing import List, Optional, Union, Tuple, Dict
import pandas as pd
import yaml
from pathlib import Path

from unicef_api.sdmx import get_sdmx
from unicef_api.flows import list_dataflows
from unicef_api.utils import (
    validate_country_codes,
    validate_year_range,
    load_country_codes,
    clean_dataframe,
    get_country_regions,
    get_income_groups,
    get_continents,
)
from unicef_api.indicator_registry import (
    get_dataflow_for_indicator,
    get_indicator_info,
)
from unicef_api.sdmx_client import (
    UNICEFSDMXClient,
    SDMXNotFoundError,
)
from unicef_api.metadata import MetadataSync

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

__all__ = ['unicefData', 'unicefdata', 'parse_year']


# =============================================================================
# Year Parameter Parsing
# =============================================================================

def parse_year(year: Union[int, str, List[int], Tuple[int, int], None]) -> dict:
    """
    Parse the flexible year parameter into start_year, end_year, and year_list.
    
    Supported formats:
        - None: All years (no filtering)
        - int: Single year (e.g., 2020)
        - str with colon: Range (e.g., "2015:2023")
        - str with comma: List (e.g., "2015,2018,2020")
        - tuple: Range as (start, end)
        - list: Explicit list of years
    
    Args:
        year: Year specification in any supported format
        
    Returns:
        dict with keys:
            - start_year: int or None
            - end_year: int or None
            - year_list: List[int] or None (for non-contiguous years)
            
    Examples:
        >>> parse_year(2020)
        {'start_year': 2020, 'end_year': 2020, 'year_list': None}
        
        >>> parse_year("2015:2023")
        {'start_year': 2015, 'end_year': 2023, 'year_list': None}
        
        >>> parse_year("2015,2018,2020")
        {'start_year': 2015, 'end_year': 2020, 'year_list': [2015, 2018, 2020]}
        
        >>> parse_year(None)
        {'start_year': None, 'end_year': None, 'year_list': None}
    """
    if year is None:
        return {'start_year': None, 'end_year': None, 'year_list': None}
    
    # Single integer
    if isinstance(year, int):
        return {'start_year': year, 'end_year': year, 'year_list': None}
    
    # Tuple (start, end)
    if isinstance(year, tuple) and len(year) == 2:
        return {'start_year': int(year[0]), 'end_year': int(year[1]), 'year_list': None}
    
    # List of years
    if isinstance(year, list):
        years = [int(y) for y in year]
        return {
            'start_year': min(years),
            'end_year': max(years),
            'year_list': sorted(years)
        }
    
    # String formats
    if isinstance(year, str):
        # Range format: "2015:2023"
        if ':' in year:
            parts = year.split(':')
            if len(parts) == 2:
                start = int(parts[0].strip())
                end = int(parts[1].strip())
                return {'start_year': start, 'end_year': end, 'year_list': None}
        
        # List format: "2015,2018,2020"
        if ',' in year:
            years = [int(y.strip()) for y in year.split(',')]
            return {
                'start_year': min(years),
                'end_year': max(years),
                'year_list': sorted(years)
            }
        
        # Single year as string: "2020"
        return {'start_year': int(year), 'end_year': int(year), 'year_list': None}
    
    raise ValueError(
        f"Invalid year format: {year}. "
        f"Expected int, 'YYYY:YYYY', 'YYYY,YYYY,YYYY', tuple, or list."
    )


def _apply_circa(df: pd.DataFrame, target_years: List[int]) -> pd.DataFrame:
    """
    For each country, find observations closest to the target year(s).
    
    When data for the exact target year isn't available, this finds the
    observation with the period closest to each target year. Different
    countries may have different actual years in the result.
    
    Args:
        df: DataFrame with iso3, period, value columns
        target_years: List of target years to match
        
    Returns:
        DataFrame with one observation per country per target year (approximately)
    """
    if 'period' not in df.columns or 'iso3' not in df.columns:
        return df
    
    if df.empty:
        return df
    
    # Drop NA values before finding closest
    df = df.dropna(subset=['value']) if 'value' in df.columns else df
    
    results = []
    
    # Group by indicator if present
    group_cols = ['iso3']
    if 'indicator' in df.columns:
        group_cols.append('indicator')
    
    for target in target_years:
        # For each country(-indicator), find the observation closest to target
        for _, group in df.groupby(group_cols):
            if group.empty:
                continue
            # Find index of closest period to target
            idx = (group['period'] - target).abs().idxmin()
            closest_row = group.loc[[idx]].copy()
            closest_row['target_year'] = target
            results.append(closest_row)
    
    if not results:
        return df.head(0)  # Empty with same columns
    
    result = pd.concat(results, ignore_index=True)
    
    # Remove duplicates if same observation is closest to multiple targets
    result = result.drop_duplicates(subset=[c for c in result.columns if c != 'target_year'])
    
    return result


# =============================================================================
# Dataflow Fallback Logic - Load from Canonical YAML
# =============================================================================

def _load_fallback_sequences() -> Dict[str, List[str]]:
    """
    Load fallback dataflow sequences from canonical YAML file.
    
    Tries multiple locations:
    1. Canonical metadata directory (parent level)
    2. Package metadata directory (if bundled)
    
    Returns:
        Dict mapping indicator prefix to list of dataflows to try
        
    Example:
        {
            'CME': ['CME', 'CME_DF_2021_WQ', 'GLOBAL_DATAFLOW'],
            'ED': ['EDUCATION_UIS_SDG', 'EDUCATION', 'GLOBAL_DATAFLOW'],
            ...
        }
    """
    fallback_file = None
    
    # Try canonical location first (parent of python/metadata/current/)
    canonical_path = Path(__file__).parent.parent.parent / 'metadata/current/_dataflow_fallback_sequences.yaml'
    if canonical_path.exists():
        fallback_file = canonical_path
    
    # Fallback to package bundled version
    if not fallback_file:
        pkg_path = Path(__file__).parent / 'metadata/_dataflow_fallback_sequences.yaml'
        if pkg_path.exists():
            fallback_file = pkg_path
    
    # Default fallback if no file found
    if not fallback_file:
        logger.warning("Canonical fallback sequences file not found, using defaults")
        return {
            'ED': ['EDUCATION_UIS_SDG', 'EDUCATION', 'GLOBAL_DATAFLOW'],
            'PT': ['PT', 'PT_CM', 'PT_FGM', 'CHILD_PROTECTION', 'GLOBAL_DATAFLOW'],
            'PV': ['CHLD_PVTY', 'GLOBAL_DATAFLOW'],
            'NT': ['NUTRITION', 'GLOBAL_DATAFLOW'],
            'DEFAULT': ['GLOBAL_DATAFLOW'],
        }
    
    try:
        with open(fallback_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
            
        if 'fallback_sequences' in data:
            return data['fallback_sequences']
        
        logger.warning(f"No 'fallback_sequences' key in {fallback_file}, using defaults")
        return {'DEFAULT': ['GLOBAL_DATAFLOW']}
        
    except Exception as e:
        logger.error(f"Error loading fallback sequences from {fallback_file}: {e}")
        return {'DEFAULT': ['GLOBAL_DATAFLOW']}


# Load fallback sequences at module initialization
FALLBACK_SEQUENCES = _load_fallback_sequences()

import logging
_logger = logging.getLogger(__name__)

# Global client instance
_client = None


def _fetch_indicator_with_fallback(
    client: UNICEFSDMXClient,
    indicator_code: str,
    dataflow: str,
    countries: Optional[List[str]] = None,
    start_year: Optional[int] = None,
    end_year: Optional[int] = None,
    sex: str = "_T",
    max_retries: int = 3,
    tidy: bool = True,
) -> pd.DataFrame:
    """
    Fetch indicator data with automatic dataflow fallback on 404 errors.
    
    If the initial dataflow returns a 404 (Not Found), this function will
    automatically try alternative dataflows based on the indicator prefix.
    This handles cases where the UNICEF API metadata reports an indicator
    in one dataflow but the data actually exists in another.
    
    Args:
        client: UNICEFSDMXClient instance
        indicator_code: UNICEF indicator code
        dataflow: Initial dataflow to try
        countries: List of ISO3 country codes
        start_year: Starting year
        end_year: Ending year
        sex: Sex disaggregation
        max_retries: Number of retries per dataflow
        tidy: Whether to return cleaned data
        
    Returns:
        DataFrame with indicator data, or empty DataFrame if all attempts fail
    """
    # Build list of dataflows to try
    dataflows_to_try = [dataflow]
    
    # Get indicator prefix (e.g., 'ED' from 'ED_CR_L1_UIS_MOD')
    prefix = indicator_code.split('_')[0] if '_' in indicator_code else indicator_code[:2]
    
    # Add alternatives for this prefix from canonical YAML
    if prefix in FALLBACK_SEQUENCES:
        for alt in FALLBACK_SEQUENCES[prefix]:
            if alt not in dataflows_to_try:
                dataflows_to_try.append(alt)
    else:
        # Use default fallback for unknown prefixes
        for alt in FALLBACK_SEQUENCES.get('DEFAULT', ['GLOBAL_DATAFLOW']):
            if alt not in dataflows_to_try:
                dataflows_to_try.append(alt)
    
    # Ensure GLOBAL_DATAFLOW is always the last resort (if not already there)
    if 'GLOBAL_DATAFLOW' not in dataflows_to_try:
        dataflows_to_try.append('GLOBAL_DATAFLOW')
    
    last_error = None
    
    for df_attempt in dataflows_to_try:
        try:
            df = client.fetch_indicator(
                indicator_code=indicator_code,
                countries=countries,
                start_year=start_year,
                end_year=end_year,
                dataflow=df_attempt,
                sex_disaggregation=sex,
                max_retries=max_retries,
                return_raw=not tidy,
            )
            
            if not df.empty:
                if df_attempt != dataflow:
                    _logger.info(
                        f"Successfully fetched '{indicator_code}' using fallback "
                        f"dataflow '{df_attempt}' (original '{dataflow}' failed)"
                    )
                return df
                
        except SDMXNotFoundError as e:
            last_error = e
            if df_attempt != dataflows_to_try[-1]:
                _logger.debug(
                    f"Dataflow '{df_attempt}' returned 404 for '{indicator_code}', "
                    f"trying alternatives..."
                )
            continue
            
        except Exception as e:
            # For non-404 errors, don't try alternatives
            _logger.error(f"Error fetching '{indicator_code}': {e}")
            raise
    
    # All dataflows failed
    if last_error:
        _logger.warning(
            f"All dataflow attempts failed for '{indicator_code}'. "
            f"Tried: {dataflows_to_try}"
        )
    
    return pd.DataFrame()


def _fetch_with_fallback(
    indicators: List[str],
    dataflow: str,
    countries: Optional[List[str]] = None,
    start_year: Optional[int] = None,
    end_year: Optional[int] = None,
    sex: str = "_T",
    max_retries: int = 3,
    tidy: bool = True,
) -> pd.DataFrame:
    """
    Fetch multiple indicators using get_sdmx() with fallback logic.
    
    This is an internal helper that combines multiple indicator fetches
    and applies the dataflow fallback mechanism.
    
    Args:
        indicators: List of indicator codes
        dataflow: Primary dataflow to try
        countries: ISO3 country codes to filter
        start_year: Starting year
        end_year: Ending year
        sex: Sex disaggregation
        max_retries: Number of retries per dataflow
        tidy: Whether to return cleaned data
        
    Returns:
        Combined DataFrame with all indicator data
    """
    global _client
    
    # Lazy initialization of client
    if _client is None:
        _client = UNICEFSDMXClient()
    
    dfs = []
    for ind in indicators:
        df = _fetch_indicator_with_fallback(
            client=_client,
            indicator_code=ind,
            dataflow=dataflow,
            countries=countries,
            start_year=start_year,
            end_year=end_year,
            sex=sex,
            max_retries=max_retries,
            tidy=tidy,
        )
        if not df.empty:
            dfs.append(df)
    
    if not dfs:
        return pd.DataFrame()
    
    return pd.concat(dfs, ignore_index=True)


# =============================================================================
# Low-level get_sdmx() function - matching R API
# =============================================================================




# =============================================================================
# Unified unicefData() function - Primary API
# =============================================================================

def unicefData(
    indicator: Union[str, List[str]],
    countries: Optional[List[str]] = None,
    year: Union[int, str, List[int], Tuple[int, int], None] = None,
    dataflow: Optional[str] = None,
    sex: str = "_T",
    tidy: bool = True,
    country_names: bool = True,
    max_retries: int = 3,
    # NEW: Post-production options
    format: str = "long",
    latest: bool = False,
    circa: bool = False,
    add_metadata: Optional[List[str]] = None,
    dropna: bool = False,
    simplify: bool = False,
    mrv: Optional[int] = None,
    raw: bool = False,
    ignore_duplicates: bool = False,
) -> pd.DataFrame:
    """
    Fetch UNICEF indicator data from SDMX API.
    
    This is the primary function for downloading indicator data. It provides
    a simple, consistent interface matching the R package's unicefData().
    
    Args:
        indicator: Indicator code(s). Single string or list of codes.
            Examples: "CME_MRY0T4" (under-5 mortality), "NT_ANT_HAZ_NE2_MOD" (stunting)
        countries: ISO 3166-1 alpha-3 country codes. If None, fetches all countries.
            Examples: ["ALB", "USA", "BRA"]
        year: Year specification. Supports multiple formats:
            - None: All available years (default)
            - int: Single year (e.g., 2020)
            - str range: "2015:2023" for years 2015-2023
            - str list: "2015,2018,2020" for non-contiguous years
            - tuple: (2015, 2023) equivalent to "2015:2023"
            - list: [2015, 2018, 2020] equivalent to "2015,2018,2020"
        dataflow: SDMX dataflow ID. If None, auto-detected from indicator.
            Examples: "CME", "NUTRITION", "EDUCATION_UIS_SDG"
        sex: Sex disaggregation filter.
            "_T" = Total (default), "F" = Female, "M" = Male, None = all
        tidy: If True, returns cleaned DataFrame with standardized columns.
            If False, returns raw API response.
        country_names: If True, adds country name column (requires tidy=True).
        max_retries: Number of retry attempts on network failure.
        raw: If True, return raw SDMX data without column standardization.
            Default is False (clean, standardized output matching R package).
        
        # Post-production options:
        format: Output format. Options:
            - "long" (default): One row per observation
            - "wide": Countries as rows, years as columns (pivoted)
            - "wide_indicators": Years as rows, indicators as columns
        latest: If True, keep only the most recent non-missing value per country.
            The year may differ by country. Useful for cross-sectional analysis.
        circa: If True, for each specified year find the closest available data point.
            When exact years aren't available, returns observations with periods
            closest to the requested year(s). Different countries may have different
            actual years. Only applies when specific years are requested.
            Example: year=2015, circa=True might return 2014 data for Country A
            and 2016 data for Country B if 2015 isn't available.
        add_metadata: List of metadata columns to add. Options:
            - "region": UNICEF/World Bank region
            - "income_group": World Bank income classification
            - "continent": Continent name
            - "indicator_name": Full indicator name
            - "indicator_category": Indicator category (CME, NUTRITION, etc.)
            Example: add_metadata=["region", "income_group"]
        dropna: If True, remove rows with missing values.
        simplify: If True, keep only essential columns (iso3, country, indicator, 
            period, value). Removes metadata columns.
        mrv: Most Recent Value(s). Keep only the N most recent years per country.
            Example: mrv=1 is equivalent to latest=True, mrv=3 keeps last 3 years.
        ignore_duplicates: If False (default), raises an error when exact duplicate
            rows are found (all column values identical). Set to True to allow 
            automatic removal of duplicates.
    
    Returns:
        pandas.DataFrame with columns (varies by options):
            - indicator_code: Indicator code
            - country_code: ISO 3166-1 alpha-3 country code
            - country_name: Country name (if country_names=True)
            - period: Time period as decimal year. Monthly periods (YYYY-MM) are 
                converted to decimal format: 2020-06 becomes 2020.5 (year + month/12).
                This preserves temporal precision for sub-annual survey data.
            - value: Observation value
            - unit: Unit of measure
            - sex: Sex disaggregation
            - age: Age group
            - wealth_quintile: Wealth quintile disaggregation
            - residence: Residence type (Urban/Rural/Total)
            - maternal_edu_lvl: Maternal education level
            - lower_bound: Lower bound (if available)
            - upper_bound: Upper bound (if available)
            - obs_status: Observation status
            - data_source: Data source
            - region: Region (if add_metadata includes "region")
            - income_group: Income group (if add_metadata includes "income_group")
    
    Note:
        TIME PERIOD CONVERSION: The UNICEF API returns periods in formats like 
        "2020" (annual) or "2020-03" (monthly). Monthly periods are automatically 
        converted to decimal years: "2020-01" → 2020.0833, "2020-06" → 2020.5, 
        "2020-11" → 2020.9167. Formula: decimal_year = year + month/12
    
    Raises:
        SDMXNotFoundError: Indicator or country not found
        SDMXBadRequestError: Invalid parameters
        SDMXServerError: API server error
    
    Examples:
        >>> from unicef_api import unicefData
        >>> 
        >>> # Basic usage - under-5 mortality for year range
        >>> df = unicefData(
        ...     indicator="CME_MRY0T4",
        ...     countries=["ALB", "USA", "BRA"],
        ...     year="2015:2023"
        ... )
        >>> 
        >>> # Single year
        >>> df = unicefData(
        ...     indicator="CME_MRY0T4",
        ...     countries=["ALB", "USA"],
        ...     year=2020
        ... )
        >>> 
        >>> # Non-contiguous years
        >>> df = unicefData(
        ...     indicator="CME_MRY0T4",
        ...     year="2015,2018,2020"
        ... )
        >>> 
        >>> # Circa mode - find closest available year
        >>> df = unicefData(
        ...     indicator="CME_MRY0T4",
        ...     year=2015,
        ...     circa=True  # Returns closest to 2015 for each country
        ... )
        >>> 
        >>> # Get latest value per country (cross-sectional)
        >>> df = unicefData(
        ...     indicator="CME_MRY0T4",
        ...     latest=True
        ... )
        >>> 
        >>> # Wide format with region metadata
        >>> df = unicefData(
        ...     indicator="CME_MRY0T4",
        ...     format="wide",
        ...     add_metadata=["region", "income_group"]
        ... )
        >>> 
        >>> # Multiple indicators merged automatically
        >>> df = unicefData(
        ...     indicator=["CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"],
        ...     format="wide_indicators",
        ...     latest=True
        ... )
    
    See Also:
        - get_sdmx(): Low-level function with direct SDMX control
        - list_dataflows(): List available dataflows
        - search_indicators(): Find indicator codes
    """
    # Ensure metadata is synced (one-time check)
    # This ensures dataflows.yaml, codelists.yaml, and indicators.yaml exist
    # Individual dataflow schemas are fetched lazily by MetadataManager
    try:
        sync = MetadataSync()
        if sync.ensure_synced(verbose=False):
            print("Initialized UNICEF metadata cache.")
    except Exception as e:
        print(f"Warning: Metadata sync failed ({e}). Proceeding without cached metadata.")

    # Handle single indicator or list
    indicators = [indicator] if isinstance(indicator, str) else indicator
    
    # Parse the year parameter
    year_spec = parse_year(year)
    start_year = year_spec['start_year']
    end_year = year_spec['end_year']
    year_list = year_spec['year_list']
    
    # Auto-detect dataflow if not provided
    if dataflow is None:
        dataflow = get_dataflow_for_indicator(indicators[0])
        print(f"Auto-detected dataflow '{dataflow}'")
    
    print("")
    
    # Use get_sdmx() for the actual data fetch
    # This provides the low-level SDMX query with fallback logic
    result = _fetch_with_fallback(
        indicators=indicators,
        dataflow=dataflow,
        countries=countries,
        start_year=start_year,
        end_year=end_year,
        sex=sex,
        max_retries=max_retries,
        tidy=not raw,
    )
    
    print("")
    
    # If raw=True, return the data as-is without post-processing
    if raw or result.empty:
        return result
    
    # ==========================================================================
    # POST-PRODUCTION PROCESSING
    # ==========================================================================
    
    # Standardize column names for processing
    # Use short, consistent names: indicator, iso3, country, period
    # These match the R package output for cross-language consistency
    col_mapping = {
        'REF_AREA': 'iso3',
        'country_code': 'iso3',
        'INDICATOR': 'indicator', 
        'indicator_code': 'indicator',
        'TIME_PERIOD': 'period',
        'year': 'period',
        'OBS_VALUE': 'value',
        'country_name': 'country',
    }
    for old, new in col_mapping.items():
        if old in result.columns and new not in result.columns:
            result = result.rename(columns={old: new})
    
    # Ensure period is numeric
    if 'period' in result.columns:
        result['period'] = pd.to_numeric(result['period'], errors='coerce')
    
    # Filter to specific years if year_list provided (non-contiguous years)
    if year_list is not None and 'period' in result.columns:
        # For non-contiguous years, filter to exact matches OR apply circa
        if circa:
            # Apply circa: find closest available year for each target
            result = _apply_circa(result, year_list)
        else:
            # Strict filter to only requested years
            result = result[result['period'].isin(year_list)]
    elif circa and year is not None and 'period' in result.columns:
        # Circa mode with single year or range
        # For ranges, circa finds closest to start and end
        target_years = [start_year] if start_year == end_year else [start_year, end_year]
        result = _apply_circa(result, target_years)
    
    # 0. Detect and remove duplicates
    # Duplicates are rows where ALL column values are identical
    if len(result) > 0:
        n_before = len(result)
        
        # Check for exact duplicates (all columns must match)
        n_duplicates = n_before - result.drop_duplicates(keep='first').shape[0]
        
        if n_duplicates > 0:
            if not ignore_duplicates:
                raise ValueError(
                    f"Found {n_duplicates} exact duplicate rows (all values identical). "
                    f"Set ignore_duplicates=True to automatically remove duplicates."
                )
            else:
                # Remove exact duplicates, keeping first occurrence
                result = result.drop_duplicates(keep='first')
                import warnings
                warnings.warn(
                    f"Removed {n_duplicates} exact duplicate rows (all values identical).",
                    UserWarning
                )
    
    # 1. Add metadata columns
    if add_metadata and 'iso3' in result.columns:
        result = _add_country_metadata(result, add_metadata)
        result = _add_indicator_metadata(result, add_metadata)
    
    # 2. Drop NA values
    if dropna and 'value' in result.columns:
        result = result.dropna(subset=['value'])
    
    # 3. Most Recent Values (MRV)
    if mrv is not None and mrv > 0 and 'iso3' in result.columns and 'period' in result.columns:
        result = _apply_mrv(result, mrv)
    
    # 4. Latest value per country
    if latest and 'iso3' in result.columns and 'period' in result.columns:
        result = _apply_latest(result)
    
    # 5. Format transformation (long/wide)
    if format != "long" and 'iso3' in result.columns:
        result = _apply_format(result, format, indicators)
    
    # 6. Simplify columns
    if simplify:
        result = _simplify_columns(result, format)
    
    return result


def _add_country_metadata(df: pd.DataFrame, metadata_list: List[str]) -> pd.DataFrame:
    """Add country-level metadata columns."""
    try:
        import pycountry
    except ImportError:
        pycountry = None
    
    # Mapping of metadata names to data
    if 'region' in metadata_list:
        # UNICEF regions (simplified mapping)
        region_map = {
            'EAP': 'East Asia and Pacific',
            'ECA': 'Europe and Central Asia', 
            'LAC': 'Latin America and Caribbean',
            'MENA': 'Middle East and North Africa',
            'NA': 'North America',
            'SA': 'South Asia',
            'SSA': 'Sub-Saharan Africa',
            'WE': 'Western Europe',
        }
        # Basic ISO3 to region mapping (can be expanded)
        iso3_to_region = get_country_regions()
        df['region'] = df['iso3'].map(iso3_to_region)
    
    if 'income_group' in metadata_list:
        income_map = get_income_groups()
        df['income_group'] = df['iso3'].map(income_map)
    
    if 'continent' in metadata_list:
        continent_map = get_continents()
        df['continent'] = df['iso3'].map(continent_map)
    
    return df


def _add_indicator_metadata(df: pd.DataFrame, metadata_list: List[str]) -> pd.DataFrame:
    """Add indicator-level metadata columns."""
    if 'indicator' not in df.columns:
        return df
    
    if 'indicator_name' in metadata_list or 'indicator_category' in metadata_list:
        # Get indicator info from registry
        unique_indicators = df['indicator'].unique()
        for ind in unique_indicators:
            info = get_indicator_info(ind)
            if info:
                if 'indicator_name' in metadata_list:
                    df.loc[df['indicator'] == ind, 'indicator_name'] = info.get('name', '')
                if 'indicator_category' in metadata_list:
                    df.loc[df['indicator'] == ind, 'indicator_category'] = info.get('category', '')
    
    return df


def _apply_mrv(df: pd.DataFrame, n: int) -> pd.DataFrame:
    """Keep only the N most recent values per country-indicator combination."""
    if 'indicator' in df.columns:
        # Group by country and indicator
        df = df.sort_values(['iso3', 'indicator', 'period'], ascending=[True, True, False])
        df = df.groupby(['iso3', 'indicator']).head(n).reset_index(drop=True)
    else:
        # Group by country only
        df = df.sort_values(['iso3', 'period'], ascending=[True, False])
        df = df.groupby('iso3').head(n).reset_index(drop=True)
    return df


def _apply_latest(df: pd.DataFrame) -> pd.DataFrame:
    """Keep only the latest non-missing value per country-indicator."""
    if 'value' in df.columns:
        df = df.dropna(subset=['value'])
    
    if 'indicator' in df.columns:
        # Get latest per country-indicator
        idx = df.groupby(['iso3', 'indicator'])['period'].idxmax()
    else:
        # Get latest per country
        idx = df.groupby('iso3')['period'].idxmax()
    
    return df.loc[idx].reset_index(drop=True)


def _apply_format(df: pd.DataFrame, format: str, indicators: List[str]) -> pd.DataFrame:
    """Transform between long and wide formats."""
    if format == "wide":
        # Countries as rows, years as columns
        # Only works well for single indicator
        if 'indicator' in df.columns and df['indicator'].nunique() > 1:
            print("Warning: 'wide' format with multiple indicators may produce complex output.")
            print("         Consider using 'wide_indicators' format instead.")
        
        # Identify columns to keep as index
        index_cols = ['iso3']
        if 'country' in df.columns:
            index_cols.append('country')
        for col in ['region', 'income_group', 'continent']:
            if col in df.columns:
                index_cols.append(col)
        if 'indicator' in df.columns and df['indicator'].nunique() > 1:
            index_cols.append('indicator')
        
        # Pivot
        df = df.pivot_table(
            index=index_cols,
            columns='period',
            values='value',
            aggfunc='first'
        ).reset_index()
        
        # Flatten column names if multi-index
        if isinstance(df.columns, pd.MultiIndex):
            df.columns = [f"{a}_{b}" if b else a for a, b in df.columns]
    
    elif format == "wide_indicators":
        # Years as rows, indicators as columns
        # Useful when comparing multiple indicators
        if 'indicator' not in df.columns or df['indicator'].nunique() == 1:
            print("Warning: 'wide_indicators' format is designed for multiple indicators.")
            return df
        
        # Identify columns to keep as index
        index_cols = ['iso3', 'period']
        if 'country' in df.columns:
            index_cols.insert(1, 'country')
        for col in ['region', 'income_group', 'continent']:
            if col in df.columns:
                index_cols.append(col)
        
        # Pivot
        df = df.pivot_table(
            index=index_cols,
            columns='indicator',
            values='value',
            aggfunc='first'
        ).reset_index()
        
        # Flatten column names
        df.columns.name = None
    
    return df


def _simplify_columns(df: pd.DataFrame, format: str) -> pd.DataFrame:
    """Keep only essential columns."""
    if format == "long":
        essential = ['iso3', 'country', 'indicator', 'period', 'value']
        available = [c for c in essential if c in df.columns]
        # Also keep metadata if added
        for col in ['region', 'income_group', 'continent', 'indicator_name']:
            if col in df.columns:
                available.append(col)
        return df[available]
    else:
        # For wide format, keep all pivoted columns
        return df


# =============================================================================
# Lowercase Alias (for consistency with Stata's case-insensitive commands)
# =============================================================================

# Alias for users accustomed to Stata's case-insensitive unicefdata command
unicefdata = unicefData




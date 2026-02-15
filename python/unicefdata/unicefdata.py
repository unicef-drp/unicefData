"""  
Core UNICEF API Functions
=========================

Main functions for retrieving data from the UNICEF SDMX API.

Version: 2.0.0 (2026-01-31)
Unified fallback architecture with canonical YAML-based metadata.

Cross-platform alignment: R, Python, Stata all use identical:
- Fallback dataflow sequences
- Indicator metadata
- Output column schemas
"""

import logging
from typing import List, Optional, Union, Tuple, Dict
import pandas as pd
import yaml
from pathlib import Path

from unicefdata.sdmx import get_sdmx
from unicefdata.flows import list_dataflows
from unicefdata.utils import (
    validate_country_codes,
    validate_year_range,
    load_country_codes,
    clean_dataframe,
    get_country_regions,
    get_income_groups,
    get_continents,
)
from unicefdata.indicator_registry import (
    get_dataflow_for_indicator,
    get_indicator_info,
)
from unicefdata.sdmx_client import (
    UNICEFSDMXClient,
    SDMXNotFoundError,
)
from unicefdata.metadata import MetadataSync

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


def _load_indicators_metadata() -> Dict[str, dict]:
    """
    Load comprehensive indicators metadata from canonical YAML file.
    
    This provides O(1) direct lookup of the correct dataflow for each indicator,
    matching R's .INDICATORS_METADATA_YAML functionality.
    
    Tries multiple locations (same as R's search order):
    1. metadata/current/_unicefdata_indicators_metadata.yaml
    2. stata/src/__unicefdata_indicators_metadata.yaml (canonical source)
    3. Package bundled version
    
    Returns:
        Dict mapping indicator code -> {dataflow: str, ...metadata}
        
    Example:
        {
            'COD_ALCOHOL_USE_DISORDERS': {
                'code': 'COD_ALCOHOL_USE_DISORDERS',
                'dataflow': 'CAUSE_OF_DEATH',
                'name': 'Alcohol use disorders',
                ...
            },
            ...
        }
    """
    import os
    
    candidates = []
    
    # Get the repository root (parent of python/)
    # python/unicefdata/core.py -> python/ -> repo_root/
    repo_root = Path(__file__).parent.parent.parent

    # Priority 1: R metadata (canonical cross-language location)
    # This ensures Python and R use the same source of truth
    r_meta = repo_root / 'R' / 'metadata' / 'current' / '_unicefdata_indicators_metadata.yaml'
    if r_meta.exists():
        candidates.append(r_meta)

    # Priority 2: Python package bundled metadata
    python_meta = repo_root / 'python' / 'metadata' / 'current' / '_unicefdata_indicators_metadata.yaml'
    if python_meta.exists():
        candidates.append(python_meta)

    # Priority 3: stata/src/_/_unicefdata_indicators_metadata.yaml (canonical source in -dev repo)
    stata_path = repo_root / 'stata' / 'src' / '_' / '_unicefdata_indicators_metadata.yaml'
    if stata_path.exists():
        candidates.append(stata_path)

    # Priority 4: metadata/current/ (if it exists)
    canonical_path = repo_root / 'metadata' / 'current' / '_unicefdata_indicators_metadata.yaml'
    if canonical_path.exists():
        candidates.append(canonical_path)
    
    # Try each candidate
    for candidate in candidates:
        try:
            logger.info(f"Attempting to load indicators metadata from: {candidate}")
            with open(candidate, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
                if data and 'indicators' in data:
                    num_indicators = len(data['indicators'])
                    logger.info(f"✅ Loaded comprehensive indicators metadata: {num_indicators} indicators from {candidate.name}")
                    return data['indicators']
                else:
                    logger.warning(f"⚠️ File exists but has no 'indicators' key: {candidate}")
        except Exception as e:
            logger.warning(f"Error loading {candidate}: {e}. Trying next location...")
    
    # No metadata file found - will fall back to prefix-based logic
    logger.warning("No comprehensive indicators metadata found. Will use prefix-based fallback sequences only.")
    return {}


# Load fallback sequences and indicators metadata at module initialization
FALLBACK_SEQUENCES = _load_fallback_sequences()
INDICATORS_METADATA = _load_indicators_metadata()

import logging
_logger = logging.getLogger(__name__)

# Global client instance
_client = None


def clear_cache(reload: bool = True, verbose: bool = True) -> list:
    """Clear all in-memory caches across the unicefdata package.

    Resets module-level caches for fallback sequences, indicators metadata,
    the global SDMX client instance, indicator registry cache, and config
    cache. After clearing, the next API call will reload all metadata from
    YAML files (or fetch fresh from the API if file cache is stale).

    Args:
        reload: If True (default), immediately reload YAML-based caches
            (fallback sequences, indicators metadata). If False, caches
            are cleared but not reloaded until next use.
        verbose: If True (default), print what was cleared.

    Returns:
        List of cleared cache names.
    """
    global FALLBACK_SEQUENCES, INDICATORS_METADATA, _client

    cleared = []

    # 1. Fallback sequences (core.py module-level)
    FALLBACK_SEQUENCES = {} if not reload else _load_fallback_sequences()
    cleared.append("fallback_sequences")

    # 2. Indicators metadata (core.py module-level)
    INDICATORS_METADATA = {} if not reload else _load_indicators_metadata()
    cleared.append("indicators_metadata")

    # 3. Global client instance (core.py)
    _client = None
    cleared.append("sdmx_client")

    # 4. Indicator registry cache (indicator_registry.py)
    from unicefdata import indicator_registry
    indicator_registry._indicator_cache = None
    indicator_registry._cache_loaded = False
    cleared.append("indicator_registry")

    # 5. Config cache (config_loader.py)
    try:
        from unicefdata.config_loader import clear_config_cache
        clear_config_cache()
        cleared.append("config_cache")
    except ImportError:
        pass

    if verbose:
        msg = f"Cleared {len(cleared)} caches: {', '.join(cleared)}"
        if reload:
            msg += " (YAML caches reloaded)"
        print(msg)

    return cleared


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
    totals: bool = False,
) -> pd.DataFrame:
    """
    Fetch indicator data with automatic dataflow fallback on 404 errors.
    
                totals=totals,
    1. Tier 1: Direct lookup in comprehensive indicators metadata (O(1))
    2. Tier 2: Prefix-based fallback sequences from canonical YAML
    3. Tier 3: Try all dataflows in sequence until success
    
    If the initial dataflow returns a 404 (Not Found), this function will
    automatically try alternative dataflows. This handles cases where the
    UNICEF API metadata reports an indicator in one dataflow but the data
    actually exists in another.
    
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
    # Build list of dataflows to try using 3-tier logic (matching R)
    dataflows_to_try = []
    
    # ==========================================================================
    # TIER 1: Direct metadata lookup (O(1) - fastest and most accurate)
    # ==========================================================================
    # Check comprehensive indicators metadata for correct dataflow
    # This matches R's .INDICATORS_METADATA_YAML lookup
    if indicator_code in INDICATORS_METADATA:
        meta = INDICATORS_METADATA[indicator_code]
        if 'dataflow' in meta or 'dataflows' in meta:
            # Handle both singular 'dataflow' and plural 'dataflows' keys
            # The metadata may have: dataflow: "CME" OR dataflows: ["FUNCTIONAL_DIFF", "GLOBAL_DATAFLOW"]
            dataflow_value = meta.get('dataflow') or meta.get('dataflows')

            # If it's a list, use all dataflows in order (first is primary)
            if isinstance(dataflow_value, list):
                for df in dataflow_value:
                    if df and df not in dataflows_to_try:
                        dataflows_to_try.append(df)
                _logger.debug(
                    f"[Tier 1] Found {indicator_code} in metadata: dataflows={dataflow_value}"
                )
            elif dataflow_value and dataflow_value not in dataflows_to_try:
                # Single dataflow string
                dataflows_to_try.append(dataflow_value)
                _logger.debug(
                    f"[Tier 1] Found {indicator_code} in metadata: dataflow={dataflow_value}"
                )
    
    # ==========================================================================
    # TIER 2: Prefix-based fallback sequences
    # ==========================================================================
    # Get indicator prefix (e.g., 'COD' from 'COD_ALCOHOL_USE_DISORDERS')
    prefix = indicator_code.split('_')[0] if '_' in indicator_code else indicator_code[:2]
    prefix = prefix.upper()
    
    # Add alternatives for this prefix from canonical YAML
    if prefix in FALLBACK_SEQUENCES:
        for alt in FALLBACK_SEQUENCES[prefix]:
            if alt not in dataflows_to_try:
                dataflows_to_try.append(alt)
        _logger.debug(
            f"[Tier 2] Using prefix-based sequence for {indicator_code} (prefix={prefix}): "
            f"{FALLBACK_SEQUENCES[prefix]}"
        )
    else:
        # Use default fallback for unknown prefixes
        for alt in FALLBACK_SEQUENCES.get('DEFAULT', ['GLOBAL_DATAFLOW']):
            if alt not in dataflows_to_try:
                dataflows_to_try.append(alt)
        _logger.debug(
            f"[Tier 2] Using DEFAULT sequence for {indicator_code} (prefix={prefix} unknown)"
        )
    
    # Add the originally requested dataflow if not already there AND not GLOBAL_DATAFLOW
    # (GLOBAL_DATAFLOW is added at the end as last resort, so don't insert it early)
    if dataflow and dataflow != 'GLOBAL_DATAFLOW' and dataflow not in dataflows_to_try:
        # Insert after metadata but before fallback sequences
        dataflows_to_try.insert(1 if dataflows_to_try else 0, dataflow)
    
    # Ensure GLOBAL_DATAFLOW is always the last resort
    if 'GLOBAL_DATAFLOW' not in dataflows_to_try:
        dataflows_to_try.append('GLOBAL_DATAFLOW')
    
    # ==========================================================================
    # TIER 3: Try all dataflows in sequence until success
    # ==========================================================================
    last_error = None
    
    _logger.info(
        f"Will try {len(dataflows_to_try)} dataflows for '{indicator_code}': {dataflows_to_try}"
    )
    
    for df_attempt in dataflows_to_try:
        # Log fallback attempts (matching R's verbose output)
        if df_attempt != dataflows_to_try[0]:
            _logger.info(f"Trying fallback dataflow '{df_attempt}'...")
        
        try:
            df = client.fetch_indicator(
                indicator_code=indicator_code,
                countries=countries,
                start_year=start_year,
                end_year=end_year,
                dataflow=df_attempt,
                sex_disaggregation=sex,
                totals=False,
                max_retries=max_retries,
                return_raw=not tidy,
            )
            
            if not df.empty:
                if df_attempt != dataflows_to_try[0]:
                    _logger.info(
                        f"Successfully fetched '{indicator_code}' using fallback "
                        f"dataflow '{df_attempt}' (primary '{dataflows_to_try[0]}' failed)"
                    )
                return df
                
        except SDMXNotFoundError as e:
            last_error = e
            if df_attempt != dataflows_to_try[-1]:
                _logger.debug(
                    f"Dataflow '{df_attempt}' returned 404 for '{indicator_code}', "
                    f"trying next dataflow..."
                )
            continue
            
        except Exception as e:
            # For non-404 errors, don't try alternatives (fatal errors)
            _logger.error(f"Error fetching '{indicator_code}': {e}")
            raise
    
    # All dataflows failed - raise exception with tried dataflows context
    if last_error:
        tried_str = ", ".join(dataflows_to_try)
        error_msg = (
            f"Not Found (404): Indicator '{indicator_code}' not found in any dataflow.\n"
            f"  Tried dataflows: {tried_str}\n"
            f"  Browse available indicators at: https://data.unicef.org/"
        )
        _logger.error(error_msg)
        raise SDMXNotFoundError(error_msg)

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
    totals: bool = False,
) -> pd.DataFrame:
    """
    Fetch multiple indicators using get_sdmx() with fallback logic.
    
            totals=totals,
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
    totals: bool = False,
    tidy: bool = True,
    country_names: bool = True,
    max_retries: int = 3,
    # NEW: Post-production options
    format: str = "long",
    pivot: Optional[Union[str, List[str]]] = None,
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
        totals: If True, explicitly append `_T` for each known dimension using
            schema to ensure totals across all dimensions (analogous to Stata's
            efficient filter). Default False.
        tidy: If True, returns cleaned DataFrame with standardized columns.
            If False, returns raw API response.
        country_names: If True, adds country name column (requires tidy=True).
        max_retries: Number of retry attempts on network failure.
        raw: If True, return raw SDMX data without column standardization.
            Default is False (clean, standardized output matching R package).
        
        # Post-production options:
        format: Output format. Options:
            - "long" (default): One row per observation
            - "wide": Years as columns (time-series format, aligned with Stata)
            - "wide_indicators": Indicators as columns
            - "wide_attributes": Disaggregation dimension as columns (requires pivot=)
        pivot: For format="wide_attributes", the dimension(s) to pivot.
            - Single dimension: pivot="sex"
            - Compound: pivot=["sex", "wealth_quintile"]
            - Valid dimensions: sex, age, wealth_quintile, residence, maternal_edu_lvl
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
        >>> from unicefdata import unicefData
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
    if isinstance(indicator, str):
        # Normalize single string: strip whitespace and discard if empty
        normalized = indicator.strip()
        indicators = [normalized] if normalized else []
    else:
        # Normalize iterable: skip None, strip whitespace, and discard empties
        indicators = []
        for ind in indicator:
            if ind is None:
                continue
            code = str(ind).strip()
            if code:
                indicators.append(code)
    if not indicators:
        raise ValueError(
            "No valid indicator codes provided (all values were None or empty/whitespace)."
        )
    
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
        totals=totals,
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
        result = _apply_format(result, format, indicators, pivot=pivot)
    
    # 6. Simplify columns
    if simplify:
        result = _simplify_columns(result, format)

    # 7. Standardize column order for cross-platform consistency
    # Order: iso3, country, period, geo_type, indicator, indicator_name, then rest
    if not raw and result is not None and len(result) > 0 and format == "long":
        standard_order = [
            'iso3', 'country', 'period', 'geo_type', 'indicator', 'indicator_name',
            'value', 'unit', 'unit_name', 'sex', 'sex_name', 'age',
            'wealth_quintile', 'wealth_quintile_name', 'residence', 'maternal_edu_lvl',
            'lower_bound', 'upper_bound', 'obs_status', 'obs_status_name',
            'data_source', 'ref_period', 'country_notes'
        ]

        # Get columns present in result that are in standard order
        present_standard = [col for col in standard_order if col in result.columns]
        # Get remaining columns not in standard order
        remaining = [col for col in result.columns if col not in standard_order]
        # Reorder: standard columns first, then remaining
        result = result[present_standard + remaining]

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


def _apply_format(df: pd.DataFrame, format: str, indicators: List[str], pivot: str = None) -> pd.DataFrame:
    """Transform between long and wide formats.

    Args:
        df: Input DataFrame
        format: One of "long", "wide", "wide_indicators", "wide_attributes"
        indicators: List of indicator codes
        pivot: For wide_attributes, the dimension to pivot (e.g., "sex", "age")
    """
    if format == "wide":
        # Years as columns (time-series format) - aligned with Stata behavior
        print("Note: format='wide' returns years as columns (time-series format).")
        print("      Other options: 'wide_indicators' (indicators as columns),")
        print("                     'wide_attributes' with pivot= (disaggregation as columns)")

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

    elif format == "wide_attributes":
        # Disaggregation dimension becomes columns
        # Valid pivot dimensions: sex, age, wealth_quintile, residence, maternal_edu_lvl
        valid_pivots = ['sex', 'age', 'wealth_quintile', 'residence', 'maternal_edu_lvl']

        if pivot is None:
            print("Error: 'wide_attributes' requires pivot= parameter.")
            print(f"       Valid options: {', '.join(valid_pivots)}")
            return df

        # Handle compound pivot (list of dimensions)
        if isinstance(pivot, str):
            pivot_cols = [pivot]
        else:
            pivot_cols = list(pivot)

        # Validate pivot columns
        for p in pivot_cols:
            if p not in valid_pivots:
                print(f"Warning: '{p}' is not a standard disaggregation dimension.")
                print(f"         Valid options: {', '.join(valid_pivots)}")
            if p not in df.columns:
                print(f"Error: Column '{p}' not found in data. Cannot pivot.")
                return df

        # Identify columns to keep as index
        index_cols = ['iso3', 'period']
        if 'country' in df.columns:
            index_cols.insert(1, 'country')
        if 'indicator' in df.columns:
            index_cols.append('indicator')
        for col in ['region', 'income_group', 'continent']:
            if col in df.columns:
                index_cols.append(col)
        # Add non-pivot disaggregation dimensions to index
        for dim in valid_pivots:
            if dim in df.columns and dim not in pivot_cols:
                index_cols.append(dim)

        # Pivot on the specified dimension(s)
        df = df.pivot_table(
            index=index_cols,
            columns=pivot_cols,
            values='value',
            aggfunc='first'
        ).reset_index()

        # Flatten column names if multi-index
        if isinstance(df.columns, pd.MultiIndex):
            df.columns = ['_'.join(str(c) for c in col if c) if isinstance(col, tuple) else col for col in df.columns]
        else:
            # Rename value columns with prefix
            df.columns = [f"value_{c}" if c not in index_cols else c for c in df.columns]

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




"""
unicef_api: Python library for downloading UNICEF indicators via SDMX API

This library provides a simplified interface for fetching child welfare and development 
indicators from UNICEF's SDMX data repository.

Main features:
- Download indicator data from UNICEF SDMX API
- Support for multiple dataflows (GLOBAL_DATAFLOW, CME, NUTRITION, EDUCATION, etc.)
- Automatic data cleaning and standardization
- Comprehensive error handling
- Caching support for offline work
- Country code validation

Basic usage:
    >>> from unicef_api import get_unicef
    >>> 
    >>> # Fetch under-5 mortality for specific countries
    >>> df = get_unicef(
    ...     indicator="CME_MRY0T4",
    ...     countries=["ALB", "USA", "BRA"],
    ...     start_year=2015,
    ...     end_year=2023
    ... )
    >>> 
    >>> # Fetch all countries, all years
    >>> df = get_unicef(indicator="NT_ANT_HAZ_NE2_MOD")

For more details, see: https://data.unicef.org/sdmx-api-documentation/
"""

__version__ = "0.3.0"
__author__ = "Joao Pedro Azevedo"
__email__ = "jazevedo@unicef.org"

from typing import List, Optional, Union
import pandas as pd

from unicef_api.sdmx_client import (
    UNICEFSDMXClient,
    SDMXError,
    SDMXBadRequestError,
    SDMXNotFoundError,
    SDMXServerError,
    SDMXAuthenticationError,
    SDMXForbiddenError,
    SDMXUnavailableError,
)

from unicef_api.config import (
    UNICEF_DATAFLOWS,
    COMMON_INDICATORS,
)

from unicef_api.indicator_registry import (
    get_dataflow_for_indicator,
    get_indicator_info,
    list_indicators,
    search_indicators,
    list_categories,
    refresh_indicator_cache,
    get_cache_info,
)

from unicef_api.utils import (
    validate_country_codes,
    validate_year_range,
    load_country_codes,
    clean_dataframe,
)

from unicef_api.metadata import (
    MetadataSync,
    DataflowMetadata,
    IndicatorMetadata,
    CodelistMetadata,
    sync_metadata,
    ensure_metadata,
    validate_indicator_data,
    list_vintages,
    compare_vintages,
)


# =============================================================================
# Unified get_unicef() function - Primary API
# =============================================================================

# Module-level client instance (lazy initialization)
_client: Optional[UNICEFSDMXClient] = None


def get_unicef(
    indicator: Union[str, List[str]],
    countries: Optional[List[str]] = None,
    start_year: Optional[int] = None,
    end_year: Optional[int] = None,
    dataflow: Optional[str] = None,
    sex: str = "_T",
    tidy: bool = True,
    country_names: bool = True,
    max_retries: int = 3,
) -> pd.DataFrame:
    """
    Fetch UNICEF indicator data from SDMX API.
    
    This is the primary function for downloading indicator data. It provides
    a simple, consistent interface matching the R package's get_unicef().
    
    Args:
        indicator: Indicator code(s). Single string or list of codes.
            Examples: "CME_MRY0T4" (under-5 mortality), "NT_ANT_HAZ_NE2_MOD" (stunting)
        countries: ISO 3166-1 alpha-3 country codes. If None, fetches all countries.
            Examples: ["ALB", "USA", "BRA"]
        start_year: First year of data (e.g., 2015). If None, fetches from earliest.
        end_year: Last year of data (e.g., 2023). If None, fetches to latest.
        dataflow: SDMX dataflow ID. If None, auto-detected from indicator.
            Examples: "CME", "NUTRITION", "EDUCATION_UIS_SDG"
        sex: Sex disaggregation filter.
            "_T" = Total (default), "F" = Female, "M" = Male
        tidy: If True, returns cleaned DataFrame with standardized columns.
            If False, returns raw API response.
        country_names: If True, adds country name column (requires tidy=True).
        max_retries: Number of retry attempts on network failure.
    
    Returns:
        pandas.DataFrame with columns:
            - iso3: ISO 3166-1 alpha-3 country code
            - country: Country name (if country_names=True)
            - indicator: Indicator code
            - period: Year
            - value: Observation value
            - (additional columns depending on dataflow)
    
    Raises:
        SDMXNotFoundError: Indicator or country not found
        SDMXBadRequestError: Invalid parameters
        SDMXServerError: API server error
    
    Examples:
        >>> from unicef_api import get_unicef
        >>> 
        >>> # Basic usage - under-5 mortality for specific countries
        >>> df = get_unicef(
        ...     indicator="CME_MRY0T4",
        ...     countries=["ALB", "USA", "BRA"],
        ...     start_year=2015,
        ...     end_year=2023
        ... )
        >>> 
        >>> # Fetch multiple indicators
        >>> df = get_unicef(
        ...     indicator=["CME_MRY0T4", "CME_MRM0"],
        ...     start_year=2020
        ... )
        >>> 
        >>> # All countries, all years (large download)
        >>> df = get_unicef(indicator="NT_ANT_HAZ_NE2_MOD")
    
    See Also:
        - UNICEFSDMXClient: Advanced class-based interface
        - list_dataflows(): List available dataflows
        - COMMON_INDICATORS: Pre-defined indicator metadata
    """
    global _client
    
    # Lazy initialization of client
    if _client is None:
        _client = UNICEFSDMXClient()
    
    # Handle single indicator or list
    indicators = [indicator] if isinstance(indicator, str) else indicator
    
    # Auto-detect dataflow if not provided
    if dataflow is None:
        dataflow = get_dataflow_for_indicator(indicators[0])
    
    # Fetch each indicator
    dfs = []
    for ind in indicators:
        df = _client.fetch_indicator(
            indicator_code=ind,
            countries=countries,
            start_year=start_year,
            end_year=end_year,
            dataflow=dataflow,
            sex_disaggregation=sex,
            max_retries=max_retries,
            return_raw=not tidy,
        )
        if not df.empty:
            dfs.append(df)
    
    # Combine results
    if not dfs:
        return pd.DataFrame()
    
    result = pd.concat(dfs, ignore_index=True)
    
    # Country names are added by the client's _clean_dataframe when tidy=True
    # No additional processing needed here
    
    return result


def list_dataflows(max_retries: int = 3) -> pd.DataFrame:
    """
    List all available UNICEF SDMX dataflows.
    
    Returns:
        DataFrame with columns: id, name, agency, version
    
    Example:
        >>> from unicef_api import list_dataflows
        >>> flows = list_dataflows()
        >>> print(flows.head())
    """
    import requests
    
    url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF?references=none&detail=full"
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=60)
            response.raise_for_status()
            
            # Parse XML response
            import xml.etree.ElementTree as ET
            root = ET.fromstring(response.content)
            
            # Extract dataflows
            ns = {'s': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure'}
            dataflows = []
            
            for df in root.findall('.//s:Dataflow', ns):
                name_elem = df.find('.//s:Name', ns)
                dataflows.append({
                    'id': df.get('id'),
                    'agency': df.get('agencyID'),
                    'version': df.get('version'),
                    'name': name_elem.text if name_elem is not None else ''
                })
            
            return pd.DataFrame(dataflows)
            
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            import time
            time.sleep(1)
    
    return pd.DataFrame()


__all__ = [
    # Primary API
    "get_unicef",
    "list_dataflows",
    # Client (advanced)
    "UNICEFSDMXClient",
    # Exceptions
    "SDMXError",
    "SDMXBadRequestError",
    "SDMXNotFoundError",
    "SDMXServerError",
    "SDMXAuthenticationError",
    "SDMXForbiddenError",
    "SDMXUnavailableError",
    # Config
    "UNICEF_DATAFLOWS",
    "COMMON_INDICATORS",
    "get_dataflow_for_indicator",
    # Utils
    "validate_country_codes",
    "validate_year_range",
    "load_country_codes",
    "clean_dataframe",
    # Metadata
    "MetadataSync",
    "DataflowMetadata",
    "IndicatorMetadata",
    "CodelistMetadata",
    "sync_metadata",
    "ensure_metadata",
    "validate_indicator_data",
    "list_vintages",
    "compare_vintages",
]

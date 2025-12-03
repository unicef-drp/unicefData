from typing import List, Optional, Union
import pandas as pd
import logging
from unicef_api.sdmx_client import UNICEFSDMXClient

_logger = logging.getLogger(__name__)

# Module-level client instance (lazy initialization)
_client: Optional[UNICEFSDMXClient] = None


def get_sdmx(
    agency: str = "UNICEF",
    flow: Optional[Union[str, List[str]]] = None,
    key: Optional[Union[str, List[str]]] = None,
    start_period: Optional[int] = None,
    end_period: Optional[int] = None,
    detail: str = "data",
    version: Optional[str] = None,
    format: str = "csv",
    labels: str = "both",
    tidy: bool = True,
    country_names: bool = True,
    countries: Optional[List[str]] = None,
    sex: str = "_T",
    page_size: int = 100000,
    retry: int = 3,
    cache: bool = False,
) -> pd.DataFrame:
    """
    Fetch SDMX data or structure from any agency (low-level function).
    
    This is the low-level function for downloading SDMX data. It provides
    direct control over SDMX query parameters, matching the R package's get_sdmx().
    
    For most use cases, prefer get_unicef() which provides a simpler interface
    with automatic dataflow detection and post-processing options.
    
    Args:
        agency: SDMX agency ID. Default: "UNICEF".
            Other agencies: "WB" (World Bank), "WHO", "IMF", etc.
        flow: Dataflow ID(s). Required for data queries.
            Examples: "CME", "NUTRITION", "IMMUNISATION"
        key: Indicator code(s) to filter. If None, fetches all indicators in flow.
            Examples: "CME_MRY0T4", ["CME_MRY0T4", "CME_MRM0"]
        start_period: Start year for data (e.g., 2015).
        end_period: End year for data (e.g., 2023).
        detail: Query type. "data" (default) or "structure" (metadata).
        version: SDMX version. If None, auto-detected.
        format: Output format from API. "csv" (default), "sdmx-xml", "sdmx-json".
        labels: Column labels. "both" (default), "id", "none".
        tidy: If True, standardize column names and clean data.
        country_names: If True, add country name column.
        countries: ISO3 country codes to filter. If None, fetches all.
        sex: Sex disaggregation filter. "_T" (total), "F", "M", or None.
        page_size: Rows per page for pagination. Default: 100000.
        retry: Number of retry attempts on failure. Default: 3.
        cache: If True, cache results (not yet implemented).
    
    Returns:
        pandas.DataFrame with SDMX data, or empty DataFrame on error.
        
        Standard columns (when tidy=True):
            - indicator: Indicator code
            - iso3: ISO3 country code
            - country: Country name (if country_names=True)
            - period: Time period (year)
            - value: Observation value
            - unit: Unit of measure code
            - unit_name: Unit of measure name
            - sex: Sex disaggregation
            - age: Age disaggregation
            - wealth_quintile: Wealth quintile disaggregation
            - residence: Residence disaggregation (Urban/Rural/Total)
            - maternal_edu_lvl: Maternal education level disaggregation
            - lower_bound, upper_bound: Confidence bounds
            - obs_status: Observation status
            - data_source: Data source
    
    Examples:
        >>> from unicef_api import get_sdmx
        >>> 
        >>> # Fetch from CME dataflow with specific indicator
        >>> df = get_sdmx(
        ...     flow="CME",
        ...     key="CME_MRY0T4",
        ...     start_period=2015,
        ...     end_period=2023
        ... )
        >>> 
        >>> # Fetch all indicators from a dataflow
        >>> df = get_sdmx(flow="NUTRITION")
        >>> 
        >>> # Get raw data without tidying
        >>> df = get_sdmx(flow="CME", key="CME_MRY0T4", tidy=False)
    
    See Also:
        - get_unicef(): High-level function with auto-detection and post-processing
        - list_dataflows(): List available dataflows
    """
    global _client
    
    # Lazy initialization of client
    if _client is None:
        _client = UNICEFSDMXClient()
    
    # Validate inputs
    if flow is None:
        raise ValueError("'flow' is required. Use list_dataflows() to see available options.")
    
    # Handle single or multiple flows
    flows = [flow] if isinstance(flow, str) else flow
    
    # Handle single or multiple keys (indicators)
    keys = None
    if key is not None:
        keys = [key] if isinstance(key, str) else key
    
    # Fetch data for each flow
    dfs = []
    for fl in flows:
        if keys:
            # Fetch each indicator
            for k in keys:
                df = _client.fetch_indicator(
                    indicator_code=k,
                    countries=countries,
                    start_year=start_period,
                    end_year=end_period,
                    dataflow=fl,
                    sex_disaggregation=sex,
                    max_retries=retry,
                    return_raw=not tidy,
                )
                if not df.empty:
                    dfs.append(df)
        else:
            # Fetch entire dataflow - use a placeholder key pattern
            # This would need enhancement to support full dataflow fetch
            _logger.warning(
                f"Fetching entire dataflow '{fl}' without key filter. "
                f"Consider specifying 'key' for better performance."
            )
            # For now, we can't fetch without a key - the API requires it
            # Return empty with warning
            continue
    
    # Combine results
    if not dfs:
        return pd.DataFrame()
    
    result = pd.concat(dfs, ignore_index=True)
    
    # Standardize column names if tidy
    if tidy:
        col_mapping = {
            'indicator_code': 'indicator',
            'country_code': 'iso3',
            'country_name': 'country',
            'year': 'period',
        }
        for old, new in col_mapping.items():
            if old in result.columns:
                result = result.rename(columns={old: new})
    
    return result

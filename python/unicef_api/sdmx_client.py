"""
UNICEF SDMX API Client
======================

Fetches official child welfare statistics from UNICEF's SDMX data repository.

This module provides a robust Python interface for downloading indicator data from 
the UNICEF SDMX API with comprehensive error handling, retry logic, and data cleaning.

SDMX API Documentation: https://data.unicef.org/sdmx-api-documentation/

Features:
- Automatic retry with exponential backoff
- Comprehensive error handling with helpful error messages
- Data validation and cleaning
- Support for multiple dataflows
- Country and year filtering
- CSV output with optional pandas DataFrame conversion

Example:
    >>> from unicef_api import UNICEFSDMXClient
    >>> client = UNICEFSDMXClient()
    >>> 
    >>> # Fetch under-5 mortality for specific countries
    >>> df = client.fetch_indicator(
    ...     'CME_MRY0T4', 
    ...     countries=['ALB', 'USA', 'BRA'],
    ...     start_year=2015,
    ...     end_year=2023
    ... )
    >>> 
    >>> # Fetch all countries with auto-detect dataflow
    >>> df = client.fetch_indicator('NT_ANT_HAZ_NE2_MOD')
"""

import requests
import pandas as pd
from typing import List, Optional, Union, Dict
from io import StringIO
import time
import logging
from unicef_api.metadata_manager import MetadataManager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ============================================================================
# Exception Classes
# ============================================================================

class SDMXError(Exception):
    """Base exception for SDMX API errors"""
    pass


class SDMXBadRequestError(SDMXError):
    """HTTP 400: Bad Request - malformed query or invalid parameters"""
    pass


class SDMXAuthenticationError(SDMXError):
    """HTTP 401: Authentication failed"""
    pass


class SDMXForbiddenError(SDMXError):
    """HTTP 403: Access forbidden to resource"""
    pass


class SDMXNotFoundError(SDMXError):
    """HTTP 404: Resource not found (indicator, country, or dataflow)"""
    pass


class SDMXServerError(SDMXError):
    """HTTP 500: Server error on SDMX API side"""
    pass


class SDMXUnavailableError(SDMXError):
    """HTTP 503: Service temporarily unavailable"""
    pass


# ============================================================================
# UNICEF SDMX Client
# ============================================================================

class UNICEFSDMXClient:
    """
    Client for UNICEF SDMX REST API
    
    Provides methods to fetch indicator data from UNICEF's SDMX data repository
    with comprehensive error handling, automatic retries, and data cleaning.
    
    Attributes:
        base_url (str): Base URL for SDMX API endpoint
        agency (str): Data agency identifier (default: 'UNICEF')
        default_dataflow (str): Default dataflow identifier (default: 'GLOBAL_DATAFLOW')
        version (str): Dataflow version (default: '1.0')
        session (requests.Session): HTTP session for connection pooling
    
    SDMX API Error Reference:
        - 400 Bad Request: Invalid parameters or malformed query
        - 401 Unauthorized: Authentication failed (if API requires key)
        - 403 Forbidden: Access denied to the requested resource
        - 404 Not Found: Indicator or dataflow doesn't exist
        - 500 Server Error: SDMX API server issue
        - 503 Service Unavailable: API temporarily down
    
    Example:
        >>> client = UNICEFSDMXClient()
        >>> df = client.fetch_indicator('CME_MRY0T4', countries=['USA', 'BRA'])
    """

    def __init__(
        self, 
        base_url: str = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest",
        agency: str = "UNICEF",
        default_dataflow: str = "GLOBAL_DATAFLOW",
        version: str = "1.0"
    ):
        """
        Initialize UNICEF SDMX client
        
        Args:
            base_url: Base URL for SDMX API endpoint
            agency: Data agency identifier (default: 'UNICEF')
            default_dataflow: Default dataflow identifier
            version: Dataflow version (default: '1.0')
        """
        self.base_url = base_url
        self.agency = agency
        self.default_dataflow = default_dataflow
        self.version = version
        self.session = requests.Session()
        self.metadata_manager = MetadataManager()
        
        # Set default headers
        self.session.headers.update({
            'User-Agent': 'unicef-api-python/0.1.0',
            'Accept-Encoding': 'gzip, deflate',
        })

    def fetch_indicator(
        self,
        indicator_code: str,
        countries: Optional[List[str]] = None,
        start_year: Optional[int] = None,
        end_year: Optional[int] = None,
        dataflow: Optional[str] = None,
        sex_disaggregation: str = "_T",
        max_retries: int = 3,
        return_raw: bool = False,
        dropna: bool = True,
    ) -> pd.DataFrame:
        """
        Fetch data for a specific indicator using CSV format
        
        This is the main method for downloading indicator data from UNICEF SDMX API.
        
        Args:
            indicator_code: UNICEF indicator code (e.g., 'CME_MRY0T4' for under-5 mortality)
                See: https://data.unicef.org/ for available indicators
            countries: List of ISO 3166-1 alpha-3 country codes (e.g., ['ALB', 'USA']).
                If None, fetches ALL countries.
            start_year: Starting year for data (e.g., 2015). If None, fetches from earliest available.
            end_year: Ending year for data (e.g., 2023). If None, fetches up to latest available.
            dataflow: SDMX dataflow name (e.g., 'CME', 'NUTRITION'). 
                If None, uses GLOBAL_DATAFLOW (recommended).
            sex_disaggregation: Sex filter for data ('_T' for total, 'F' for female, 'M' for male)
                Default: '_T' (total population)
            max_retries: Number of retry attempts on failure (default: 3)
            return_raw: If True, returns raw DataFrame without cleaning (default: False)
        
        Returns:
            pandas.DataFrame with indicator data, or empty DataFrame on error
            
        Raises:
            SDMXBadRequestError: Invalid indicator or country codes
            SDMXNotFoundError: Indicator or country not found in database
            SDMXServerError: SDMX API server error
            
        Example:
            >>> client = UNICEFSDMXClient()
            >>> 
            >>> # Fetch under-5 mortality for Albania and USA, 2015-2023
            >>> df = client.fetch_indicator(
            ...     'CME_MRY0T4',
            ...     countries=['ALB', 'USA'],
            ...     start_year=2015,
            ...     end_year=2023
            ... )
            >>> 
            >>> # Fetch all countries, all years
            >>> df = client.fetch_indicator('NT_ANT_HAZ_NE2_MOD')
        """
        
        # Validate inputs
        self._validate_inputs(indicator_code, countries, start_year, end_year)
        
        # Use provided dataflow or fall back to default
        current_dataflow = dataflow if dataflow else self.default_dataflow
        
        # Validate filters against schema
        # We construct a filter dict from the arguments
        # Note: 'countries' is handled post-fetch in this implementation, so we don't validate it here as a pre-fetch filter
        # But 'sex_disaggregation' is used in _clean_dataframe, so we can validate it.
        # 'indicator_code' is part of the key.
        
        filters_to_validate = {
            'INDICATOR': indicator_code,
        }
        if sex_disaggregation:
            filters_to_validate['SEX'] = sex_disaggregation
            
        warnings = self.metadata_manager.validate_filters(filters_to_validate, current_dataflow)
        for w in warnings:
            logger.warning(w)
        
        # Build data query - format: .INDICATOR.
        # Note: Country filtering is done post-fetch for compatibility with all dataflows
        data_key = f".{indicator_code}."
        
        # Build URL
        url = f"{self.base_url}/data/{self.agency},{current_dataflow},{self.version}/{data_key}"
        
        # Build query parameters
        params = {"format": "csv", "labels": "both"}
        if start_year:
            params["startPeriod"] = str(start_year)
        if end_year:
            params["endPeriod"] = str(end_year)
        
        # Log request details
        if countries and len(countries) > 0:
            logger.info(
                f"Fetching {indicator_code} for {len(countries)} countries "
                f"(will filter post-fetch)"
            )
        else:
            logger.info(f"Fetching {indicator_code} for ALL countries")
        
        # Retry loop
        for attempt in range(max_retries):
            try:
                logger.info(
                    f"API request attempt {attempt + 1}/{max_retries}: {indicator_code}"
                )
                logger.debug(f"URL: {url}")
                logger.debug(f"Params: {params}")
                
                # Make request
                response = self.session.get(url, params=params, timeout=120)
                response.raise_for_status()
                
                # Parse CSV response
                df = pd.read_csv(StringIO(response.text))
                
                # Validate against schema
                self.metadata_manager.validate_dataframe(df, current_dataflow)
                
                if return_raw:
                    logger.info(f"Successfully fetched {len(df)} raw observations")
                    return df
                
                # Clean and filter data
                df = self._clean_dataframe(
                    df, 
                    indicator_code, 
                    countries, 
                    sex_disaggregation,
                    dropna=dropna,
                    dataflow=current_dataflow
                )
                
                logger.info(
                    f"Successfully fetched and cleaned {len(df)} observations "
                    f"for {df['iso3'].nunique()} countries"
                )
                return df
                
            except requests.exceptions.HTTPError as e:
                self._handle_http_error(e, indicator_code, attempt, max_retries)
                if attempt < max_retries - 1:
                    sleep_time = 2 ** attempt
                    logger.info(f"Retrying in {sleep_time} seconds...")
                    time.sleep(sleep_time)
                    
            except requests.exceptions.Timeout:
                logger.warning(
                    f"Timeout on attempt {attempt + 1}/{max_retries}: "
                    f"API did not respond within 120 seconds"
                )
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)
                else:
                    logger.error("Failed after max retries due to timeout")
                    return pd.DataFrame()
                    
            except requests.exceptions.ConnectionError as e:
                logger.warning(
                    f"Connection error on attempt {attempt + 1}/{max_retries}: {e}"
                )
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)
                else:
                    logger.error(
                        "Failed after max retries due to connection error. "
                        "Check internet connection and SDMX API availability."
                    )
                    return pd.DataFrame()
                    
            except pd.errors.ParserError as e:
                logger.error(
                    f"Failed to parse CSV response: {e}. "
                    f"The API may have returned an error page instead of data."
                )
                return pd.DataFrame()
                
            except Exception as e:
                logger.error(
                    f"Unexpected error processing response: {type(e).__name__}: {e}"
                )
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)
                else:
                    return pd.DataFrame()
        
        return pd.DataFrame()
    
    def fetch_multiple_indicators(
        self,
        indicator_codes: List[str],
        countries: Optional[List[str]] = None,
        start_year: Optional[int] = None,
        end_year: Optional[int] = None,
        dataflow: Optional[str] = None,
        combine: bool = True,
    ) -> Union[pd.DataFrame, dict]:
        """
        Fetch multiple indicators at once
        
        Args:
            indicator_codes: List of indicator codes to fetch
            countries: List of country codes (None = all countries)
            start_year: Start year for all indicators
            end_year: End year for all indicators
            dataflow: Dataflow to use for all indicators
            combine: If True, combine into single DataFrame; if False, return dict
        
        Returns:
            Single DataFrame (if combine=True) or dict of DataFrames (if combine=False)
            
        Example:
            >>> indicators = ['CME_MRY0T4', 'NT_ANT_HAZ_NE2_MOD', 'IM_DTP3']
            >>> df = client.fetch_multiple_indicators(
            ...     indicators,
            ...     countries=['ALB', 'USA'],
            ...     start_year=2015
            ... )
        """
        results = {}
        
        for indicator in indicator_codes:
            logger.info(f"Fetching indicator {indicator}...")
            df = self.fetch_indicator(
                indicator,
                countries=countries,
                start_year=start_year,
                end_year=end_year,
                dataflow=dataflow,
            )
            
            if not df.empty:
                results[indicator] = df
            else:
                logger.warning(f"No data retrieved for {indicator}")
        
        if combine:
            if results:
                combined_df = pd.concat(results.values(), ignore_index=True)
                logger.info(
                    f"Combined {len(results)} indicators into single DataFrame "
                    f"with {len(combined_df)} total observations"
                )
                return combined_df
            else:
                logger.warning("No data retrieved for any indicator")
                return pd.DataFrame()
        else:
            return results
    
    def _validate_inputs(
        self,
        indicator_code: str,
        countries: Optional[List[str]],
        start_year: Optional[int],
        end_year: Optional[int],
    ) -> None:
        """Validate input parameters before API call"""
        
        if not indicator_code or not isinstance(indicator_code, str):
            raise SDMXBadRequestError(
                f"Invalid indicator code: '{indicator_code}'. "
                f"Indicator code must be a non-empty string (e.g., 'CME_MRY0T4')."
            )
        
        if countries is not None:
            if not isinstance(countries, list):
                raise SDMXBadRequestError(
                    f"countries must be a list, got {type(countries).__name__}"
                )
            for code in countries:
                if not isinstance(code, str) or len(code) != 3:
                    raise SDMXBadRequestError(
                        f"Invalid country code: '{code}'. "
                        f"Country codes must be ISO 3166-1 alpha-3 codes (e.g., 'ALB', 'USA')."
                    )
        
        if start_year is not None and (
            not isinstance(start_year, int) or start_year < 1900
        ):
            raise SDMXBadRequestError(
                f"Invalid start_year: {start_year}. Must be an integer >= 1900."
            )
        
        if end_year is not None and (
            not isinstance(end_year, int) or end_year < 1900
        ):
            raise SDMXBadRequestError(
                f"Invalid end_year: {end_year}. Must be an integer >= 1900."
            )
        
        if (
            start_year is not None
            and end_year is not None
            and start_year > end_year
        ):
            raise SDMXBadRequestError(
                f"Invalid year range: start_year ({start_year}) > end_year ({end_year})"
            )
    
    def _handle_http_error(
        self,
        error: requests.exceptions.HTTPError,
        indicator_code: str,
        attempt: int,
        max_retries: int,
    ) -> None:
        """Handle HTTP errors with detailed error messages"""
        
        status_code = error.response.status_code
        response_text = error.response.text[:500]  # First 500 chars
        
        if status_code == 400:
            error_msg = (
                f"Bad Request (400): Invalid API parameters for '{indicator_code}'.\n"
                f"Verify:\n"
                f"  - Indicator code format (e.g., 'CME_MRY0T4')\n"
                f"  - Country codes are ISO 3166-1 alpha-3 (e.g., 'ALB', 'USA')\n"
                f"  - Year parameters are valid integers\n"
                f"API Response: {response_text}\n"
                f"See: https://data.unicef.org/sdmx-api-documentation/"
            )
            logger.error(error_msg)
            raise SDMXBadRequestError(error_msg)
            
        elif status_code == 401:
            error_msg = (
                f"Authentication Error (401): API authentication failed. "
                f"Check credentials or API key validity."
            )
            logger.error(error_msg)
            raise SDMXAuthenticationError(error_msg)
            
        elif status_code == 403:
            error_msg = (
                f"Access Denied (403): You do not have permission to access '{indicator_code}'."
            )
            logger.error(error_msg)
            raise SDMXForbiddenError(error_msg)
            
        elif status_code == 404:
            error_msg = (
                f"Not Found (404): Indicator '{indicator_code}' does not exist.\n"
                f"Browse available indicators at: https://data.unicef.org/"
            )
            logger.error(error_msg)
            raise SDMXNotFoundError(error_msg)
            
        elif status_code == 500:
            error_msg = (
                f"Server Error (500): SDMX API internal error "
                f"(attempt {attempt + 1}/{max_retries}). "
                f"This may be temporary. Will retry."
            )
            logger.warning(error_msg)
            
        elif status_code == 503:
            error_msg = (
                f"Service Unavailable (503): SDMX API is temporarily down "
                f"(attempt {attempt + 1}/{max_retries})."
            )
            logger.warning(error_msg)
            
        else:
            error_msg = (
                f"HTTP Error {status_code}: Unexpected error from SDMX API.\n"
                f"Response: {response_text}"
            )
            logger.warning(error_msg)
    
    def _clean_dataframe(
        self,
        df: pd.DataFrame,
        indicator_code: str,
        countries: Optional[List[str]] = None,
        sex_filter: Union[str, List[str]] = "_T",
        dropna: bool = True,
        dataflow: Optional[str] = None,
    ) -> pd.DataFrame:
        """
        Clean and standardize the CSV dataframe
        
        Args:
            df: Raw DataFrame from API
            indicator_code: Indicator code being fetched
            countries: List of countries to filter to
            sex_filter: Sex disaggregation to filter ('_T', 'F', 'M', or None for all)
            dropna: If True (default), drop rows with missing year or value
            dataflow: Dataflow ID for schema-based standardization
        
        Returns:
            Cleaned DataFrame with standardized columns
        """
        try:
            # Rename columns to standard format
            # Map ALL columns from the API - never drop data
            # Use consistent naming with R: iso3, indicator, period
            column_mapping = {
                "REF_AREA": "iso3",
                "Geographic area": "country",
                "GEO_TYPE": "geo_type",  # Geographic type (country, region, etc.)
                "INDICATOR": "indicator",
                "Indicator": "indicator_name",
                "TIME_PERIOD": "period",
                "OBS_VALUE": "value",
                "UNIT_MEASURE": "unit",
                "Unit of measure": "unit_name",
                "SEX": "sex",
                "Sex": "sex_name",
                "AGE": "age",
                "WEALTH_QUINTILE": "wealth_quintile",
                "Wealth Quintile": "wealth_quintile_name",
                "RESIDENCE": "residence",
                "MATERNAL_EDU_LVL": "maternal_edu_lvl",
                "LOWER_BOUND": "lower_bound",
                "UPPER_BOUND": "upper_bound",
                "OBS_STATUS": "obs_status",
                "Observation Status": "obs_status_name",
                "DATA_SOURCE": "data_source",
                "REF_PERIOD": "ref_period",
                "COUNTRY_NOTES": "country_notes",
            }
            
            # Update with schema-based mapping if available
            if dataflow:
                schema_mapping = self.metadata_manager.get_column_mapping(dataflow)
                # We want schema mapping to take precedence for dimensions
                column_mapping.update(schema_mapping)
            
            df = df.rename(columns=column_mapping)
            
            # Filter by country if specified
            if countries and len(countries) > 0 and "iso3" in df.columns:
                df = df[df["iso3"].isin(countries)]
                logger.debug(
                    f"Filtered to {len(df)} observations for {len(countries)} countries"
                )
            
            # Convert numeric columns
            if "value" in df.columns:
                df["value"] = pd.to_numeric(df["value"], errors="coerce")
            
            # Convert period column - handle YYYY-MM format by converting to decimal
            # e.g., "2006-01" -> 2006 + 1/12 = 2006.0833, "2006-11" -> 2006 + 11/12 = 2006.9167
            if "period" in df.columns:
                def convert_period_to_decimal(val):
                    """Convert TIME_PERIOD to decimal year (YYYY-MM -> YYYY + MM/12)"""
                    if pd.isna(val):
                        return None
                    val_str = str(val)
                    # Check for YYYY-MM format
                    if '-' in val_str and len(val_str) >= 7:
                        parts = val_str.split('-')
                        if len(parts) >= 2:
                            try:
                                year = int(parts[0])
                                month = int(parts[1])
                                return year + month / 12
                            except (ValueError, IndexError):
                                pass
                    # Try direct numeric conversion for YYYY format
                    try:
                        return float(val)
                    except (ValueError, TypeError):
                        return None
                
                df["period"] = df["period"].apply(convert_period_to_decimal)
            
            if "lower_bound" in df.columns:
                df["lower_bound"] = pd.to_numeric(df["lower_bound"], errors="coerce")
            if "upper_bound" in df.columns:
                df["upper_bound"] = pd.to_numeric(df["upper_bound"], errors="coerce")
            
            # =================================================================
            # Drop rows with missing period or value (data quality requirement)
            # =================================================================
            if dropna:
                initial_rows = len(df)
                
                # Check for rows with missing period or value
                missing_period = df["period"].isna() if "period" in df.columns else pd.Series([False] * len(df))
                missing_value = df["value"].isna() if "value" in df.columns else pd.Series([False] * len(df))
                
                # Log cross-tabulation for transparency
                both_missing = (missing_period & missing_value).sum()
                period_only_missing = (missing_period & ~missing_value).sum()
                value_only_missing = (~missing_period & missing_value).sum()
                
                # Drop rows with missing period OR missing value
                df = df[~(missing_period | missing_value)].copy()
                
                n_dropped = initial_rows - len(df)
                if n_dropped > 0:
                    logger.info(
                        f"Dropped {n_dropped} rows with missing data: "
                        f"{both_missing} with both missing, "
                        f"{period_only_missing} with missing period only, "
                        f"{value_only_missing} with missing value only. "
                        f"Use dropna=False to keep these rows."
                    )
            
            # =================================================================
            # Filter to totals by default (sex, age, wealth_quintile)
            # This provides clean aggregated data; disaggregations available on request
            # =================================================================
            
            # Check what disaggregations are available and log them
            available_disaggregations = []
            defaults_applied = []
            
            # Filter by sex (default: total)
            if "sex" in df.columns:
                sex_values = df["sex"].dropna().unique().tolist()
                if len(sex_values) > 1 or (len(sex_values) == 1 and sex_values[0] != "_T"):
                    available_disaggregations.append(f"sex: {sex_values}")
                
                if sex_filter:
                    if isinstance(sex_filter, list):
                        # Filter by list of values
                        # Only filter if at least one value is present
                        if any(s in sex_values for s in sex_filter):
                            df = df[df["sex"].isin(sex_filter)].copy()
                            logger.debug(f"Filtered to sex in {sex_filter}")
                            defaults_applied.append(f"sex={sex_filter}")
                    elif sex_filter in sex_values:
                        # Filter by single value
                        df = df[df["sex"] == sex_filter].copy()
                        logger.debug(f"Filtered to sex={sex_filter}")
                        defaults_applied.append(f"sex='{sex_filter}'")
            
            # Filter by age (default: total "_T" or indicator-specific total like "Y0T4")
            if "age" in df.columns:
                age_values = df["age"].dropna().unique().tolist()
                if len(age_values) > 1:
                    available_disaggregations.append(f"age: {age_values}")
                    # Keep only total age groups
                    total_ages = ["_T", "Y0T4", "Y0T14", "Y0T17", "Y15T49", "ALLAGE"]
                    age_totals = [a for a in total_ages if a in age_values]
                    if age_totals:
                        df = df[df["age"].isin(age_totals)].copy()
                        logger.debug(f"Filtered to total age groups: {age_totals}")
                        defaults_applied.append(f"age={age_totals}")
            
            # Filter by wealth quintile (default: total)
            if "wealth_quintile" in df.columns:
                wq_values = df["wealth_quintile"].dropna().unique().tolist()
                if len(wq_values) > 1 or (len(wq_values) == 1 and wq_values[0] != "_T"):
                    available_disaggregations.append(f"wealth_quintile: {wq_values}")
                if "_T" in df["wealth_quintile"].values:
                    df = df[df["wealth_quintile"] == "_T"].copy()
                    logger.debug("Filtered to wealth_quintile=_T")
                    defaults_applied.append("wealth_quintile='_T'")
            
            # Filter by residence (default: total)
            if "residence" in df.columns:
                res_values = df["residence"].dropna().unique().tolist()
                if len(res_values) > 1 or (len(res_values) == 1 and res_values[0] != "_T"):
                    available_disaggregations.append(f"residence: {res_values}")
                if "_T" in df["residence"].values:
                    df = df[df["residence"] == "_T"].copy()
                    logger.debug("Filtered to residence=_T")
                    defaults_applied.append("residence='_T'")
            
            # Filter by maternal education level (default: total)
            if "maternal_edu_lvl" in df.columns:
                edu_values = df["maternal_edu_lvl"].dropna().unique().tolist()
                if len(edu_values) > 1 or (len(edu_values) == 1 and edu_values[0] != "_T"):
                    available_disaggregations.append(f"maternal_edu_lvl: {edu_values}")
                if "_T" in df["maternal_edu_lvl"].values:
                    df = df[df["maternal_edu_lvl"] == "_T"].copy()
                    logger.debug("Filtered to maternal_edu_lvl=_T")
                    defaults_applied.append("maternal_edu_lvl='_T'")
            
            # Log available disaggregations
            if available_disaggregations:
                msg = f"Note: Disaggregated data available for {indicator_code}: {', '.join(available_disaggregations)}."
                if defaults_applied:
                    msg += f"\nDefaults used: {', '.join(defaults_applied)}."
                msg += "\nUse raw=True or adjust filters to access."
                logger.info(msg)
            
            # Standard output columns - always include all for cross-language consistency
            # Including all disaggregation columns and names for transparency
            # PRINCIPLE: Never drop columns - preserve all data from API
            standard_columns = [
                "indicator",
                "indicator_name",
                "iso3",
                "country",
                "geo_type",  # Geographic type (country, region, etc.)
                "period",
                "value",
                "unit",
                "unit_name",
                "sex",
                "sex_name",
                "age",
                "wealth_quintile",
                "wealth_quintile_name",
                "residence",
                "maternal_edu_lvl",
                "lower_bound",
                "upper_bound",
                "obs_status",
                "obs_status_name",
                "data_source",
                "ref_period",
                "country_notes",
            ]
            
            # Add missing columns with NA
            for col in standard_columns:
                if col not in df.columns:
                    df[col] = None
            
            # Reorder standard columns first, then add any extra columns not in standard list
            extra_cols = [c for c in df.columns if c not in standard_columns]
            df = df[standard_columns + extra_cols]
            
            # Sort by country and period
            if "iso3" in df.columns and "period" in df.columns:
                df = df.sort_values(["iso3", "period"]).reset_index(drop=True)
            
            return df
            
        except Exception as e:
            logger.error(f"Error cleaning dataframe: {e}")
            return df

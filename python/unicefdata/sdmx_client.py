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
    >>> from unicefdata import UNICEFSDMXClient
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

import os
import requests
import pandas as pd
import yaml
from typing import List, Optional, Union, Dict, Set
from io import StringIO
import time
import logging
from unicefdata.metadata_manager import MetadataManager

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


class SDMXTimeoutError(SDMXError):
    """Request timed out after all retries"""
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

    # Critical columns for metadata="light" mode (cross-platform consistency)
    CRITICAL_COLUMNS = [
        'iso3', 'country', 'period', 'geo_type',
        'indicator', 'indicator_name',
        'value', 'unit', 'unit_name',
        'sex', 'age', 'wealth_quintile', 'residence', 'maternal_edu_lvl',
        'lower_bound', 'upper_bound',
        'obs_status', 'obs_status_name',
        'data_source', 'ref_period', 'country_notes',
        'time_detail', 'current_age'
    ]

    def __init__(
        self,
        base_url: str = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest",
        agency: str = "UNICEF",
        default_dataflow: str = "GLOBAL_DATAFLOW",
        version: str = "1.0",
        metadata_dir: Optional[str] = None,
        timeout: int = 120
    ):
        """
        Initialize UNICEF SDMX client

        Args:
            base_url: Base URL for SDMX API endpoint
            agency: Data agency identifier (default: 'UNICEF')
            default_dataflow: Default dataflow identifier
            version: Dataflow version (default: '1.0')
            metadata_dir: Path to metadata directory with canonical YAML files
            timeout: Request timeout in seconds (default: 120)
        """
        self.base_url = base_url
        self.agency = agency
        self.default_dataflow = default_dataflow
        self.version = version
        self.timeout = timeout
        self.session = requests.Session()
        self.metadata_manager = MetadataManager(metadata_dir=metadata_dir)
        # Track last request for debugging/parity checks
        self._last_url: Optional[str] = None
        self._last_params: Optional[Dict[str, str]] = None
        # Load comprehensive indicators metadata (primary source)
        self._indicators_metadata = self._load_indicators_metadata()
        # Load canonical fallback sequences (fallback for indicators not in metadata)
        self._fallback_sequences = self._load_canonical_fallback_sequences()
        # Load region/aggregate codes for geo_type classification
        self._region_codes: Set[str] = self._load_region_codes()
        
        # Set default headers with dynamic User-Agent
        try:
            from unicefdata import __version__
            import platform
            py_ver = platform.python_version()
            system = platform.system()
            ua = f"unicefData-Python/{__version__} (Python/{py_ver}; {system}) (+https://github.com/unicef-drp/unicefData)"
        except Exception:
            ua = 'unicefData-Python/unknown (+https://github.com/unicef-drp/unicefData)'
        self.session.headers.update({
            'User-Agent': ua,
            'Accept-Encoding': 'gzip, deflate',
        })

    def _load_indicators_metadata(self) -> Dict[str, dict]:
        """
        Load comprehensive indicators metadata from canonical YAML file.
        
        This enables direct dataflow lookup by indicator code instead of using
        prefix-based fallback sequences. Much faster (O(1) vs trying multiple dataflows).
        
        Priority:
        1. Metadata directory (from MetadataManager)
        2. Workspace root metadata/current/
        3. Stata src folder (canonical source in private -dev repo)
        4. Fallback to empty dict (uses prefix fallback method if not available)
        
        Returns:
            Dict mapping indicator code -> {dataflow: str, ...metadata}
        """
        import yaml
        import os
        
        candidates = []
        
        # Add metadata_dir if available
        if self.metadata_manager.metadata_dir:
            candidates.append(
                os.path.join(self.metadata_manager.metadata_dir, '_unicefdata_indicators_metadata.yaml')
            )
        
        # Add bundled metadata inside the package (unicefdata/metadata/current/)
        package_dir = os.path.dirname(__file__)
        candidates.append(
            os.path.join(package_dir, 'metadata', 'current', '_unicefdata_indicators_metadata.yaml')
        )

        # Add workspace locations (dev mode)
        try:
            package_root = os.path.abspath(os.path.join(package_dir, '..', '..'))
            candidates.extend([
                os.path.join(package_root, 'metadata', 'current', '_unicefdata_indicators_metadata.yaml'),
                os.path.join(package_root, 'stata', 'src', '_', '_unicefdata_indicators_metadata.yaml'),
            ])
        except Exception:
            pass
        
        # Try each candidate
        for candidate in candidates:
            if os.path.exists(candidate):
                try:
                    with open(candidate, 'r', encoding='utf-8') as f:
                        data = yaml.safe_load(f)
                        if data and 'indicators' in data:
                            logger.info(f"Loaded comprehensive indicators metadata from: {candidate}")
                            return data['indicators']
                except Exception as e:
                    logger.warning(f"Error loading {candidate}: {e}. Trying next location...")
        
        # No metadata file found - will fall back to prefix-based logic
        logger.debug("No comprehensive indicators metadata found. Will use prefix-based fallback sequences.")
        return {}

    def _load_canonical_fallback_sequences(self) -> Dict[str, list]:
        """
        Load canonical fallback sequences from shared YAML file.
        
        Used as fallback when comprehensive indicators metadata is not available.
        
        Priority:
        1. Metadata directory (from MetadataManager)
        2. Workspace root metadata/current/
        3. Stata src folder (canonical source in private -dev repo)
        4. Hardcoded defaults (backward compatibility)
        
        This ensures Python, R, and Stata all use identical dataflow resolution.
        """
        import yaml
        import os
        
        candidates = []
        
        # Add metadata_dir if available
        if self.metadata_manager.metadata_dir:
            candidates.append(
                os.path.join(self.metadata_manager.metadata_dir, '_dataflow_fallback_sequences.yaml')
            )
        
        # Add bundled metadata inside the package (unicefdata/metadata/current/)
        package_dir = os.path.dirname(__file__)
        candidates.append(
            os.path.join(package_dir, 'metadata', 'current', '_dataflow_fallback_sequences.yaml')
        )

        # Add workspace locations (dev mode)
        try:
            package_root = os.path.abspath(os.path.join(package_dir, '..', '..'))
            candidates.extend([
                os.path.join(package_root, 'metadata', 'current', '_dataflow_fallback_sequences.yaml'),
                os.path.join(package_root, 'stata', 'src', '_', '_dataflow_fallback_sequences.yaml'),
            ])
        except Exception:
            pass
        
        # Try each candidate
        for candidate in candidates:
            if os.path.exists(candidate):
                try:
                    with open(candidate, 'r', encoding='utf-8') as f:
                        data = yaml.safe_load(f)
                        if data and 'fallback_sequences' in data:
                            logger.info(f"Loaded canonical fallback sequences from: {candidate}")
                            return data['fallback_sequences']
                except Exception as e:
                    logger.warning(f"Error loading {candidate}: {e}. Trying next location...")
        
        # Hardcoded fallback (backward compatibility)
        logger.warning(
            "Could not load canonical _dataflow_fallback_sequences.yaml. "
            "Using hardcoded defaults. To use latest metadata, ensure "
            "metadata/current/_dataflow_fallback_sequences.yaml exists."
        )
        return {
            'CME': ['CME', 'CME_DF_2021_WQ', 'MORTALITY', 'GLOBAL_DATAFLOW'],
            'COD': ['CAUSE_OF_DEATH', 'CME', 'MORTALITY', 'GLOBAL_DATAFLOW'],
            'ED': ['EDUCATION_UIS_SDG', 'EDUCATION', 'GLOBAL_DATAFLOW'],
            'PT': ['PT', 'PT_CM', 'PT_FGM', 'CHILD_PROTECTION', 'GLOBAL_DATAFLOW'],
            'NT': ['NUTRITION', 'GLOBAL_DATAFLOW'],
            'WS': ['WASH_HOUSEHOLDS', 'WASH_SCHOOLS', 'WASH_HEALTHCARE_FACILITY', 'GLOBAL_DATAFLOW'],
            'HVA': ['HIV_AIDS', 'GLOBAL_DATAFLOW'],
            'IM': ['IMMUNISATION', 'GLOBAL_DATAFLOW'],
            'MNCH': ['MNCH', 'GLOBAL_DATAFLOW'],
            'ECD': ['ECD', 'GLOBAL_DATAFLOW'],
            'PV': ['CHLD_PVTY', 'GLOBAL_DATAFLOW'],
            'DM': ['DM', 'GLOBAL_DATAFLOW'],
            'MG': ['MIGRATION', 'GLOBAL_DATAFLOW'],
            'FP': ['FAMILY_PLANNING', 'GLOBAL_DATAFLOW'],
            'GN': ['GENDER', 'GLOBAL_DATAFLOW'],
            'SPP': ['SOC_PROTECTION', 'GLOBAL_DATAFLOW'],
            'WT': ['PT', 'CHILD_PROTECTION', 'GLOBAL_DATAFLOW'],
            'FD': ['EDUCATION', 'EDUCATION_FLS', 'GLOBAL_DATAFLOW'],
            'TRGT': ['CHILD_RELATED_SDG', 'GLOBAL_DATAFLOW'],
            'ECON': ['ECONOMIC', 'GLOBAL_DATAFLOW'],
            'DEFAULT': ['GLOBAL_DATAFLOW'],
        }

    def _load_region_codes(self) -> Set[str]:
        """
        Load aggregate/region ISO3 codes from canonical YAML.

        Priority order mirrors Stata: metadata_dir, workspace metadata/current,
        and the canonical Stata source under stata/src/_. Returns an empty set
        if no file can be loaded.
        """
        candidates = []

        if self.metadata_manager.metadata_dir:
            candidates.append(
                os.path.join(self.metadata_manager.metadata_dir, '_unicefdata_regions.yaml')
            )

        # Add bundled metadata inside the package (unicefdata/metadata/current/)
        package_dir = os.path.dirname(__file__)
        candidates.append(
            os.path.join(package_dir, 'metadata', 'current', '_unicefdata_regions.yaml')
        )

        try:
            package_root = os.path.abspath(os.path.join(package_dir, '..', '..'))
            candidates.extend([
                os.path.join(package_root, 'metadata', 'current', '_unicefdata_regions.yaml'),
                os.path.join(package_root, 'stata', 'src', '_', '_unicefdata_regions.yaml'),
            ])
        except Exception:
            pass

        for candidate in candidates:
            if os.path.exists(candidate):
                try:
                    with open(candidate, 'r', encoding='utf-8') as f:
                        data = yaml.safe_load(f)
                        if data and 'regions' in data and isinstance(data['regions'], dict):
                            codes = set(data['regions'].keys())
                            logger.info(f"Loaded aggregate/region codes from: {candidate} ({len(codes)} codes)")
                            return codes
                except Exception as e:
                    logger.warning(f"Error loading {candidate}: {e}. Trying next location...")

        logger.warning(
            "Could not load _unicefdata_regions.yaml. geo_type will default to country (0). "
            "Ensure metadata/current/_unicefdata_regions.yaml is available for parity with Stata/R."
        )
        return set()

    def _get_fallback_dataflows(self, indicator_code: str, primary_dataflow: str) -> list:
        """
        Get ordered list of fallback dataflows for an indicator.
        
        Uses comprehensive indicators metadata (direct lookup) or falls back to
        prefix-based sequences. This ensures all platforms use identical logic.
        
        Args:
            indicator_code: Indicator code (e.g., 'CME_MRY0T4')
            primary_dataflow: Primary dataflow to try first
        
        Returns:
            Ordered list of dataflows to try, starting with primary_dataflow
        """
        candidates = [primary_dataflow]
        
        # Priority 1: Direct lookup in comprehensive indicators metadata
        if indicator_code in self._indicators_metadata:
            meta = self._indicators_metadata[indicator_code]
            if 'dataflow' in meta:
                dataflow = meta['dataflow']
                if dataflow != primary_dataflow and dataflow not in candidates:
                    candidates.append(dataflow)
                logger.debug(
                    f"Found indicator {indicator_code} in metadata: dataflow={dataflow}"
                )
                return candidates
        
        # Priority 2: Prefix-based fallback sequences (fallback for indicators not in metadata)
        prefix = indicator_code.split('_')[0].upper()
        if prefix in self._fallback_sequences:
            fallbacks = self._fallback_sequences[prefix]
        else:
            # Unknown prefix: use DEFAULT sequence
            fallbacks = self._fallback_sequences.get('DEFAULT', ['GLOBAL_DATAFLOW'])
        
        # Add fallback flows
        for flow in fallbacks:
            if flow != primary_dataflow and flow not in candidates:
                candidates.append(flow)
        
        logger.debug(
            f"Using fallback sequence for {indicator_code} (prefix={prefix}): {candidates}"
        )
        return candidates

    def _build_schema_aware_key(
        self,
        indicator_code: str,
        dataflow: str,
        sex_disaggregation: str = "_T",
        nofilter: bool = False,
        totals: bool = False,
    ) -> str:
        """
        Build SDMX data key using schema-aware dimension construction.
        
        This method dynamically extracts dimension structure from dataflow schema
        and constructs an efficient pre-fetch filter key with explicit dimension values.
        
        When nofilter=True:
            Constructs: .{INDICATOR}.... (all values for all dimensions)
            Server returns ALL disaggregations, 50-100x more data
        
        When totals=True (and nofilter=False):
            Constructs: .{INDICATOR}._T._T._T... using schema (one _T per known dimension)
            Ensures explicit totals filtering across all dimensions

        Special case: WS_HCF_* indicators expand HCF_TYPE and RESIDENCE dimensions.
        
        Args:
            indicator_code: UNICEF indicator code
            dataflow: Dataflow name (CME, GLOBAL_DATAFLOW, WASH_HEALTHCARE_FACILITY, etc.)
            sex_disaggregation: Sex filter ('_T' for total, 'F' for female, 'M' for male)
                Only used when nofilter=False
            nofilter: If True, fetch all disaggregations (empty string for dims)
                If False (default), use _T for all dimensions (pre-fetch filtering)
        
        Returns:
            SDMX data key string for URL construction
        """
        # Load schema to get dimension structure and ordering
        schema = self.metadata_manager.get_schema(dataflow) or {}
        dimensions = schema.get("dimensions", [])
        
        # Handle special case: WS_HCF_* indicators in WASH_HEALTHCARE_FACILITY
        if indicator_code.upper().startswith("WS_HCF_") and dataflow == "WASH_HEALTHCARE_FACILITY":
            # Map indicator prefix to service type
            tail = indicator_code.upper().split("WS_HCF_")[1]
            service_type_map = {
                "W-": "WAT",    # Water
                "S-": "SAN",    # Sanitation
                "H-": "HYG",    # Hygiene
                "WM-": "HCW",   # Healthcare workers
                "C-": "CLEAN"   # Cleaning
            }
            service_type = next(
                (v for prefix, v in service_type_map.items() if tail.startswith(prefix)),
                ""
            )
            
            # Extract dimension lists from schema
            dims_dict = {d.get("id"): d for d in dimensions}
            
            hcf_vals = []
            res_vals = []
            
            if "HCF_TYPE" in dims_dict and dims_dict["HCF_TYPE"].get("values"):
                hcf_vals = dims_dict["HCF_TYPE"]["values"]
            else:
                hcf_vals = ["_T", "NON_HOS", "HOS", "GOV", "NON_GOV"]
            
            if "RESIDENCE" in dims_dict and dims_dict["RESIDENCE"].get("values"):
                res_vals = dims_dict["RESIDENCE"]["values"]
            else:
                res_vals = ["_T", "U", "R"]
            
            hcf_part = "+".join(hcf_vals)
            res_part = "+".join(res_vals)
            
            # REF_AREA left empty for all countries
            # Key order per schema: REF_AREA.INDICATOR.SERVICE_TYPE.HCF_TYPE.RESIDENCE
            if service_type:
                return f".{indicator_code}.{service_type}.{hcf_part}.{res_part}"
            else:
                # Fallback: no service_type mapping found
                return f".{indicator_code}..{hcf_part}.{res_part}"
        
        # Standard case: Use R's simpler approach
        # R uses: .INDICATOR. without dimension wildcards
        # This lets the server decide which dimensions to include
        # Python's schema-aware ._T._T._T approach caused 404s for some dataflows
        
        # For nofilter mode, use empty strings for all dimensions (fetch all disaggregations)
        if nofilter:
            key_parts = [indicator_code]
            for dim in dimensions:
                dim_id = dim.get("id")
                # Skip REF_AREA and INDICATOR (handled specially)
                if dim_id in ["REF_AREA", "INDICATOR"]:
                    continue
                # Empty string = all values for this dimension
                key_parts.append("")
            return "." + ".".join(key_parts)
        
        # For filtered mode (default):
        if totals:
            # Explicit totals per known dimensions (exclude REF_AREA and INDICATOR)
            dim_ids = [d.get("id") for d in dimensions if d.get("id") not in ["REF_AREA", "INDICATOR"]]
            key_suffix = ""
            if len(dim_ids) > 0:
                key_suffix = "." + ".".join(["_T" for _ in dim_ids])
            else:
                # Fallback: apply single _T when schema unavailable
                key_suffix = "._T"
            return f".{indicator_code}{key_suffix}"
        # Default: R's simple .INDICATOR. pattern (no explicit wildcards)
        return f".{indicator_code}."

    def fetch_indicator(
        self,
        indicator_code: str,
        countries: Optional[List[str]] = None,
        start_year: Optional[int] = None,
        end_year: Optional[int] = None,
        dataflow: Optional[str] = None,
        sex_disaggregation: str = "_T",
        nofilter: bool = False,
        totals: bool = False,
        max_retries: int = 3,
        return_raw: bool = False,
        dropna: bool = True,
        labels: str = "id",
        metadata: str = "light",
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
                Default: '_T' (total population). Ignored if nofilter=True.
            nofilter: If True, fetches ALL disaggregations (50-100x more data).
                Default: False.
            totals: If True (and nofilter=False), explicitly append _T for each known
                dimension using schema to ensure totals across all dimensions.
            max_retries: Number of retry attempts on failure (default: 3)
            return_raw: If True, returns raw DataFrame without cleaning (default: False)
            dropna: If True (default), drops rows with missing values
            labels: Column label format. Options: "id" (codes only, default), "both" (codes + labels), "none"
                Default: "id" for cross-platform consistency with R and Stata
            metadata: Column selection mode. Options: "light" (critical columns only, default), "full" (all columns)
                Default: "light" returns ~23 critical columns for cross-platform consistency with R and Stata
        
        Returns:
            pandas.DataFrame with indicator data, or empty DataFrame on error.

        Column schema (cross-platform parity):
            This client requests SDMX with `labels=id` (codes-only) and returns
            code columns without duplicate human-readable label columns. The
            resulting column structure aligns with the default R and Stata
            implementations (codes-only by default). Human-readable labels can
            be joined from metadata if needed.
            
        Raises:
            SDMXBadRequestError: Invalid indicator or country codes
            SDMXNotFoundError: Indicator or country not found in database
            SDMXServerError: SDMX API server error
            
        Example:
            >>> client = UNICEFSDMXClient()
            >>> 
            >>> # Fetch under-5 mortality for Albania and USA, 2015-2023 (totals only)
            >>> df = client.fetch_indicator(
            ...     'CME_MRY0T4',
            ...     countries=['ALB', 'USA'],
            ...     start_year=2015,
            ...     end_year=2023
            ... )
            >>> 
            >>> # Fetch ALL disaggregations (sex/age/wealth/etc)
            >>> df = client.fetch_indicator(
            ...     'CME_MRY0T4',
            ...     countries=['ALB', 'USA'],
            ...     start_year=2015,
            ...     end_year=2023,
            ...     nofilter=True
            ... )
            >>> 
            >>> # Fetch all countries, all years
            >>> df = client.fetch_indicator('NT_ANT_HAZ_NE2_MOD')
        """
        
        # Validate inputs
        self._validate_inputs(indicator_code, countries, start_year, end_year)
        
        # Use provided dataflow or fall back to default
        current_dataflow = dataflow if dataflow else self.default_dataflow
        # Special-case mapping for indicators requiring specific dataflows
        # WS_HCF_H-L should use the WASH_HEALTHCARE_FACILITY dataflow to expose service_type/hcf_type
        if indicator_code.upper() == "WS_HCF_H-L" and (not dataflow or dataflow == self.default_dataflow):
            current_dataflow = "WASH_HEALTHCARE_FACILITY"
        
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
        
        # Build data query using schema-aware dimension construction
        # Dynamically extract dimension structure from dataflow schema to construct efficient pre-fetch filters
        data_key = self._build_schema_aware_key(
            indicator_code, 
            current_dataflow, 
            sex_disaggregation,
            nofilter,
            totals
        )
        
        # Build URL
        url = f"{self.base_url}/data/{self.agency},{current_dataflow},{self.version}/{data_key}"
        
        # Validate labels parameter
        if labels not in ["id", "both", "none"]:
            raise ValueError(f"labels must be 'id', 'both', or 'none', got '{labels}'")

        # Validate metadata parameter
        if metadata not in ["light", "full"]:
            raise ValueError(f"metadata must be 'light' or 'full', got '{metadata}'")

        # Build query parameters
        # Default: request codes only to avoid duplicate label columns (cross-platform consistency)
        # SDMX will return code values; human-readable labels can be added client-side if needed
        params = {"format": "csv", "labels": labels}
        if start_year:
            params["startPeriod"] = str(start_year)
        if end_year:
            params["endPeriod"] = str(end_year)
        # Save for external inspection
        self._last_url = url
        self._last_params = params.copy()
        
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
                # Build complete URL with query parameters for easy browser testing
                param_str = "&".join([f"{k}={v}" for k, v in params.items()])
                complete_url = f"{url}?{param_str}" if param_str else url
                logger.info(f"Requesting SDMX CSV: {complete_url}")
                
                # Make request
                response = self.session.get(url, params=params, timeout=self.timeout)
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

                # Apply column filtering based on metadata parameter
                if metadata == "light" and not df.empty:
                    # Keep only critical columns that exist in the dataframe
                    available_critical = [col for col in self.CRITICAL_COLUMNS if col in df.columns]
                    df = df[available_critical]
                    logger.debug(f"metadata=light: kept {len(available_critical)}/{len(self.CRITICAL_COLUMNS)} critical columns")

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
                    f"API did not respond within {self.timeout} seconds"
                )
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)
                else:
                    raise SDMXTimeoutError(
                        f"Request timed out after {max_retries} attempts "
                        f"({self.timeout}s each). Indicator: {indicator_code}"
                    )
                    
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
    
    def _load_indicators_metadata_for_enrichment(self) -> Dict[str, dict]:
        """
        Load indicators metadata for enrichment (indicator names).
        
        Returns:
            Dict mapping indicator code -> {name: str, ...metadata}
        """
        import yaml
        import os
        
        candidates = []
        
        # Add metadata_dir if available
        if self.metadata_manager.metadata_dir:
            candidates.append(
                os.path.join(self.metadata_manager.metadata_dir, '_unicefdata_indicators.yaml')
            )
        
        # Add workspace locations
        try:
            package_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
            candidates.extend([
                os.path.join(package_root, 'metadata', 'current', '_unicefdata_indicators.yaml'),
                os.path.join(package_root, 'stata', 'src', '_', '_unicefdata_indicators.yaml'),
            ])
        except Exception:
            pass
        
        # Try each candidate
        for candidate in candidates:
            if os.path.exists(candidate):
                try:
                    with open(candidate, 'r', encoding='utf-8') as f:
                        data = yaml.safe_load(f)
                        if data and 'indicators' in data:
                            logger.debug(f"Loaded indicators metadata for enrichment from: {candidate}")
                            # Convert 'name' field to standard format
                            result = {}
                            for code, meta in data['indicators'].items():
                                result[code] = {
                                    'name': meta.get('name', ''),
                                    **meta
                                }
                            return result
                except Exception as e:
                    logger.debug(f"Error loading {candidate}: {e}")
        
        logger.debug("Could not load indicators metadata for enrichment")
        return {}

    def _load_countries_metadata_for_enrichment(self) -> Dict[str, str]:
        """
        Load countries metadata for enrichment (country names).
        
        Returns:
            Dict mapping ISO3 code -> country name
        """
        import yaml
        import os
        
        candidates = []
        
        # Add metadata_dir if available
        if self.metadata_manager.metadata_dir:
            candidates.append(
                os.path.join(self.metadata_manager.metadata_dir, '_unicefdata_countries.yaml')
            )
        
        # Add workspace locations
        try:
            package_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
            candidates.extend([
                os.path.join(package_root, 'metadata', 'current', '_unicefdata_countries.yaml'),
                os.path.join(package_root, 'stata', 'src', '_', '_unicefdata_countries.yaml'),
            ])
        except Exception:
            pass
        
        # Try each candidate
        for candidate in candidates:
            if os.path.exists(candidate):
                try:
                    with open(candidate, 'r', encoding='utf-8') as f:
                        data = yaml.safe_load(f)
                        if data and 'countries' in data:
                            logger.debug(f"Loaded countries metadata for enrichment from: {candidate}")
                            return data['countries']
                except Exception as e:
                    logger.debug(f"Error loading {candidate}: {e}")
        
        logger.debug("Could not load countries metadata for enrichment")
        return {}

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

            # geo_type: 1 for aggregates in YAML, 0 otherwise (numeric)
            if "iso3" in df.columns:
                if not self._region_codes:
                    logger.warning(
                        "geo_type classification skipped: region codes not loaded; treating all as country (0)."
                    )
                def classify_geo_type(code):
                    if pd.isna(code):
                        return None
                    return 1 if str(code) in self._region_codes else 0
                df["geo_type"] = df["iso3"].apply(classify_geo_type)
            elif "geo_type" in df.columns:
                df["geo_type"] = pd.to_numeric(df["geo_type"], errors="coerce")
            else:
                df["geo_type"] = None
            
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
            # Filter to totals by default using metadata-driven logic
            # Uses disaggregations_with_totals from indicator metadata
            # =================================================================

            available_disaggregations = []
            defaults_applied = []

            # Get indicator metadata for smart filtering
            indicator_meta = self._indicators_metadata.get(indicator_code, {})
            dims_with_totals = indicator_meta.get('disaggregations_with_totals', [])
            all_disaggregations = indicator_meta.get('disaggregations', [])

            # Map SDMX dimension names to lowercase column names
            dim_name_map = {
                'SEX': 'sex',
                'AGE': 'age',
                'WEALTH_QUINTILE': 'wealth_quintile',
                'RESIDENCE': 'residence',
                'MATERNAL_EDU_LVL': 'maternal_edu_lvl',
                'DISABILITY_STATUS': 'disability_status',
                'EDUCATION_LEVEL': 'education_level',
                'ETHNIC_GROUP': 'ethnic_group',
            }

            # Convert dims_with_totals to lowercase column names
            cols_with_totals = [dim_name_map.get(d, d.lower()) for d in dims_with_totals]

            # Special handling for sex (user can override with sex_filter parameter)
            if "sex" in df.columns:
                sex_values = df["sex"].dropna().unique().tolist()
                if len(sex_values) > 1 or (len(sex_values) == 1 and sex_values[0] != "_T"):
                    available_disaggregations.append(f"sex: {sex_values}")

                if sex_filter:
                    if isinstance(sex_filter, list):
                        if any(s in sex_values for s in sex_filter):
                            df = df[df["sex"].isin(sex_filter)].copy()
                            defaults_applied.append(f"sex={sex_filter}")
                    elif sex_filter in sex_values:
                        df = df[df["sex"] == sex_filter].copy()
                        defaults_applied.append(f"sex='{sex_filter}'")

            # Special handling for age (multiple possible totals)
            # NUTRITION dataflow uses Y0T4 (0-4 years) as default since _T doesn't exist
            if "age" in df.columns:
                age_values = df["age"].dropna().unique().tolist()
                if len(age_values) > 1:
                    available_disaggregations.append(f"age: {age_values}")

                    # Special case: NUTRITION dataflow uses Y0T4 instead of _T
                    # The AGE dimension in NUTRITION has specific age groups but no _T total
                    df_upper = dataflow.upper() if dataflow else ""
                    if df_upper == "NUTRITION" and "Y0T4" in age_values and "_T" not in age_values:
                        df = df[df["age"] == "Y0T4"].copy()
                        defaults_applied.append("age='Y0T4' (NUTRITION default)")
                        logger.info("Note: NUTRITION dataflow uses age=Y0T4 (0-4 years) as default instead of _T")
                    else:
                        total_ages = ["_T", "Y0T4", "Y0T14", "Y0T17", "Y15T49", "ALLAGE"]
                        age_totals = [a for a in total_ages if a in age_values]
                        if age_totals:
                            # Prefer _T if available, otherwise use first available total
                            if "_T" in age_totals:
                                df = df[df["age"] == "_T"].copy()
                                defaults_applied.append("age='_T'")
                            else:
                                preferred_age = age_totals[0]
                                df = df[df["age"] == preferred_age].copy()
                                defaults_applied.append(f"age='{preferred_age}' (_T not available)")

            # Dynamic filtering for dimensions WITH totals (from metadata)
            # These dimensions have _T values and should be filtered to _T
            for col in ['wealth_quintile', 'residence', 'maternal_edu_lvl', 'education_level', 'ethnic_group']:
                if col in df.columns:
                    col_values = df[col].dropna().unique().tolist()
                    if len(col_values) > 1 or (len(col_values) == 1 and col_values[0] != "_T"):
                        available_disaggregations.append(f"{col}: {col_values}")

                    # Only filter to _T if this dimension is in disaggregations_with_totals
                    # OR if no metadata available (fallback to safe default)
                    if (col in cols_with_totals or not dims_with_totals) and "_T" in col_values:
                        df = df[df[col] == "_T"].copy()
                        defaults_applied.append(f"{col}='_T'")

            # Special handling for dimensions WITHOUT totals (not in disaggregations_with_totals)
            # DISABILITY_STATUS: no _T exists, use PD (without disabilities) as baseline
            if "disability_status" in df.columns:
                dis_values = df["disability_status"].dropna().unique().tolist()
                if len(dis_values) > 1 or (len(dis_values) == 1 and dis_values[0] not in ["_T", "PD"]):
                    available_disaggregations.append(f"disability_status: {dis_values}")

                # Check if DISABILITY_STATUS has totals according to metadata
                has_totals = 'disability_status' in cols_with_totals or 'DISABILITY_STATUS' in dims_with_totals

                if has_totals and "_T" in dis_values:
                    df = df[df["disability_status"] == "_T"].copy()
                    defaults_applied.append("disability_status='_T'")
                elif not has_totals and "PD" in dis_values and len(dis_values) > 1:
                    # PD = "People without Disabilities" - baseline when no total exists
                    df = df[df["disability_status"] == "PD"].copy()
                    defaults_applied.append("disability_status='PD' (no _T available)")

            # Log available disaggregations
            if available_disaggregations:
                msg = f"Note: Disaggregated data available for {indicator_code}: {', '.join(available_disaggregations)}."
                if defaults_applied:
                    msg += f"\nDefaults used: {', '.join(defaults_applied)}."
                msg += "\nUse raw=True or adjust filters to access."
                logger.info(msg)
            
            # =================================================================
            # METADATA ENRICHMENT: Add indicator_name and country name
            # =================================================================
            # Load and add indicator metadata (indicator_name)
            if "indicator" in df.columns:
                # Load comprehensive indicators metadata
                indicators_meta = self._load_indicators_metadata_for_enrichment()
                if indicators_meta:
                    df["indicator_name"] = df["indicator"].apply(
                        lambda code: indicators_meta.get(code, {}).get("name", "")
                    )
            
            # Load and add country names  
            if "iso3" in df.columns:
                countries_meta = self._load_countries_metadata_for_enrichment()
                if countries_meta:
                    df["country"] = df["iso3"].apply(
                        lambda code: countries_meta.get(code, "")
                    )
            
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

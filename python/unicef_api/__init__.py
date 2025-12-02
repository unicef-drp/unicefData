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
    >>> from unicef_api import UNICEFSDMXClient
    >>> client = UNICEFSDMXClient()
    >>> df = client.fetch_indicator('CME_MRY0T4', countries=['ALB', 'USA'])

For more details, see: https://data.unicef.org/sdmx-api-documentation/
"""

__version__ = "0.2.0"
__author__ = "Joao Pedro Azevedo"
__email__ = "jazevedo@unicef.org"

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
    get_dataflow_for_indicator,
)

from unicef_api.utils import (
    validate_country_codes,
    validate_year_range,
    load_country_codes,
    clean_dataframe,
)

__all__ = [
    # Client
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
]

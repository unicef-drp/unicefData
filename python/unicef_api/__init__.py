"""
unicef_api: Python library for downloading UNICEF indicators via SDMX API

This library provides a simplified interface for fetching child welfare and development 
indicators from UNICEF's SDMX data repository.
"""

__version__ = "1.5.0"
__author__ = "Joao Pedro Azevedo"
__email__ = "jazevedo@unicef.org"

from unicef_api.core import unicefData, unicefdata, parse_year
from unicef_api.sdmx import get_sdmx
from unicef_api.flows import list_dataflows, dataflow_schema, print_dataflow_schema
from unicef_api.indicator_registry import (
    get_dataflow_for_indicator,
    get_indicator_info,
    list_indicators,
    search_indicators,
    list_categories,
)
from unicef_api.utils import (
    validate_country_codes,
    load_country_codes,
    clean_dataframe,
)
from unicef_api.sdmx_client import (
    UNICEFSDMXClient,
    SDMXError,
    SDMXBadRequestError,
    SDMXNotFoundError,
    SDMXServerError,
)
from unicef_api.config import (
    COMMON_INDICATORS,
    UNICEF_DATAFLOWS,
)
from unicef_api.metadata import (
    list_vintages,
    compare_vintages,
    sync_metadata,
)

__all__ = [
    # Primary functions
    "unicefData",
    "unicefdata",  # lowercase alias for Stata compatibility
    "parse_year",  # year parameter parser
    "get_sdmx",
    # Discovery functions
    "list_dataflows",
    "dataflow_schema",
    "print_dataflow_schema",
    "list_indicators",
    "search_indicators",
    "list_categories",
    # Utility functions
    "get_dataflow_for_indicator",
    "get_indicator_info",
    "validate_country_codes",
    "load_country_codes",
    "clean_dataframe",
    # Classes
    "UNICEFSDMXClient",
    # Exceptions
    "SDMXError",
    "SDMXBadRequestError",
    "SDMXNotFoundError",
    "SDMXServerError",
    # Config
    "COMMON_INDICATORS",
    "UNICEF_DATAFLOWS",
    # Metadata
    "list_vintages",
    "compare_vintages",
    "sync_metadata",
]

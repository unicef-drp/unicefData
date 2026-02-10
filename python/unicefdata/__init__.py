"""
unicefdata: Python library for downloading UNICEF indicators via SDMX API

This library provides a simplified interface for fetching child welfare and development
indicators from UNICEF's SDMX data repository.
"""

__version__ = "2.1.1"

def build_user_agent() -> str:
    """Build a User-Agent string including package version and Python runtime."""
    import platform
    py_ver = platform.python_version()
    system = platform.system()
    return f"unicefData-Python/{__version__} (Python/{py_ver}; {system}) (+https://github.com/unicef-drp/unicefData)"
__author__ = "Joao Pedro Azevedo"
__email__ = "jpazevedo@unicef.org"
__url__ = "https://jpazvd.github.io/"

from unicefdata.unicefdata import unicefData, unicefdata, parse_year, clear_cache
from unicefdata.sdmx import get_sdmx
from unicefdata.flows import list_dataflows, dataflow_schema, print_dataflow_schema
from unicefdata.indicator_registry import (
    get_dataflow_for_indicator,
    get_indicator_info,
    list_indicators,
    search_indicators,
    list_categories,
)
from unicefdata.utils import (
    validate_country_codes,
    load_country_codes,
    clean_dataframe,
)
from unicefdata.sdmx_client import (
    UNICEFSDMXClient,
    SDMXError,
    SDMXBadRequestError,
    SDMXNotFoundError,
    SDMXServerError,
    SDMXTimeoutError,
)
# Note: COMMON_INDICATORS and UNICEF_DATAFLOWS removed
# Use UNICEFSDMXClient._indicators_metadata instead
from unicefdata.metadata import (
    list_vintages,
    compare_vintages,
    sync_metadata,
)

__all__ = [
    # Primary functions
    "unicefData",
    "unicefdata",  # lowercase alias for Stata compatibility
    "parse_year",  # year parameter parser
    "clear_cache",  # unified cache clearing
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
    "SDMXTimeoutError",
    # Metadata
    "list_vintages",
    "compare_vintages",
    "sync_metadata",
]

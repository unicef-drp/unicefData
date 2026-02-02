"""
Configuration for UNICEF SDMX API
==================================

Dataflow definitions, indicator mappings, and API endpoint configurations.

This module provides both:
1. Hardcoded fallback indicator/dataflow definitions
2. Support for loading from shared config/indicators.yaml

The shared YAML config is the source of truth - hardcoded values are fallbacks.
"""

from typing import Dict, List, Optional
import os


# ============================================================================
# API Configuration
# ============================================================================

UNICEF_API_BASE_URL = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
UNICEF_AGENCY = "UNICEF"
DEFAULT_VERSION = "1.0"


# ============================================================================
# Shared Config Loading
# ============================================================================

def _try_load_shared_config():
    """Try to load indicators from shared YAML config file.
    
    Returns:
        Tuple of (indicators_dict, dataflows_dict) or (None, None) if not found
    """
    try:
        from unicef_api.config_loader import load_indicators, load_dataflows
        return load_indicators(), load_dataflows()
    except (ImportError, FileNotFoundError):
        return None, None


# ============================================================================
# UNICEF Dataflows
# ============================================================================
# REMOVED: Hardcoded UNICEF_DATAFLOWS dictionary
# All dataflow information now loaded from:
# - _unicefdata_indicators_metadata.yaml (comprehensive indicators metadata)
# - _dataflow_fallback_sequences.yaml (prefix-based fallback sequences)
#
# This ensures all platforms (Stata, Python, R) use identical canonical metadata.


# ============================================================================
# Common Indicators (SDG-related)
# ============================================================================
# REMOVED: Hardcoded COMMON_INDICATORS dictionary
# All indicator metadata now loaded from:
# - _unicefdata_indicators_metadata.yaml (733 indicators with full metadata)
#
# To access indicator metadata, use UNICEFSDMXClient._indicators_metadata
# loaded at client initialization from canonical YAML source.


# ============================================================================
# Helper Functions
# ============================================================================

# REMOVED: get_dataflow_for_indicator() function
# Dataflow resolution now handled by UNICEFSDMXClient._get_fallback_dataflows()
# which uses direct O(1) lookup from _indicators_metadata dictionary.
#
# For backward compatibility with external code that may import this function,
# use the sdmx_client instead:
#   from unicef_api.sdmx_client import UNICEFSDMXClient
#   client = UNICEFSDMXClient()
#   dataflows = client._get_fallback_dataflows(indicator_code, 'GLOBAL_DATAFLOW')


# REMOVED: get_indicator_metadata() function
# Indicator metadata now accessed via UNICEFSDMXClient._indicators_metadata
#
# For backward compatibility:
#   from unicef_api.sdmx_client import UNICEFSDMXClient
#   client = UNICEFSDMXClient()
#   metadata = client._indicators_metadata.get(indicator_code)


# REMOVED: list_indicators_by_sdg() function
# SDG filtering now available via comprehensive metadata:
#   client._indicators_metadata with sdg_target field


# REMOVED: list_indicators_by_dataflow() function
# Dataflow filtering now available via comprehensive metadata:
#   [code for code, meta in client._indicators_metadata.items() if meta.get('dataflow') == dataflow]


# REMOVED: get_all_sdg_targets() function
# SDG target enumeration now available via comprehensive metadata:
#   sorted(set(meta.get('sdg_target') for meta in client._indicators_metadata.values() if meta.get('sdg_target')))


# ============================================================================
# Dynamic Config Loading (with fallback to hardcoded values)
# ============================================================================

# REMOVED: get_indicators() function
# Indicator definitions now loaded via UNICEFSDMXClient._load_indicators_metadata()
# All 733 indicators available from canonical YAML at client initialization.


# REMOVED: get_dataflows() function
# Dataflow information now embedded in indicators metadata.
# Access via: client._indicators_metadata[code]['dataflow']


def get_indicator_codes(
    category: Optional[str] = None,
    sdg_goal: Optional[str] = None,
    dataflow: Optional[str] = None,
    use_shared_config: bool = True
) -> List[str]:
    """Get list of indicator codes with optional filtering.
    
    Args:
        category: Filter by category (e.g., 'mortality', 'nutrition')
        sdg_goal: Filter by SDG goal (e.g., '3', '4')
        dataflow: Filter by dataflow (e.g., 'CME', 'NUTRITION')
        use_shared_config: If True, try to load from shared YAML config first
        
    Returns:
        List of indicator codes matching the filters
        
    Example:
        >>> codes = get_indicator_codes(category='mortality')
        ['CME_MRM0', 'CME_MRY0T4']
        
        >>> codes = get_indicator_codes(sdg_goal='3')
        ['CME_MRM0', 'CME_MRY0T4', 'IM_DTP3', 'IM_MCV1', ...]
    """
    indicators = get_indicators(use_shared_config)
    
    result = []
    for code, info in indicators.items():
        # Apply filters
        if category and info.get('category') != category:
            continue
        if sdg_goal and not info.get('sdg', '').startswith(f"{sdg_goal}."):
            continue
        if dataflow and info.get('dataflow') != dataflow:
            continue
        result.append(code)
    
    return sorted(result)

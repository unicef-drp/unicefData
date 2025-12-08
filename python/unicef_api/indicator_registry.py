"""
Indicator Registry - Auto-sync UNICEF indicator metadata
=========================================================

This module automatically fetches and caches the complete UNICEF indicator
codelist from the SDMX API. The cache is created on first use and can be
refreshed on demand.

Key features:
- Automatic download of indicator codelist from UNICEF SDMX API
- Maps each indicator code to its dataflow (category)
- Caches metadata locally in config/unicef_indicators_metadata.yaml
- Supports offline usage after initial sync
- Version tracking for cache freshness

Usage:
    >>> from unicef_api.indicator_registry import get_dataflow_for_indicator
    >>> 
    >>> # Auto-detects dataflow from indicator code
    >>> dataflow = get_dataflow_for_indicator("CME_MRY0T4")
    >>> print(dataflow)  # "CME"
    >>> 
    >>> # Refresh cache manually
    >>> from unicef_api.indicator_registry import refresh_indicator_cache
    >>> refresh_indicator_cache()
"""

import os
import yaml
import logging
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple
from xml.etree import ElementTree as ET

logger = logging.getLogger(__name__)

# ============================================================================
# Configuration
# ============================================================================

# SDMX API endpoints
CODELIST_URL = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0"

# Cache settings
CACHE_FILENAME = "unicef_indicators_metadata.yaml"
CACHE_MAX_AGE_DAYS = 30  # Refresh cache if older than this


def _get_cache_path() -> Path:
    """Get path to the indicator cache file.
    
    Saves to Python-specific metadata directory:
    1. python/metadata/current/ (relative to package)
    2. Fallback: User's home directory (~/.unicef_api/)
    
    Returns:
        Path to cache file
    """
    # Primary location: python/metadata/current/ directory
    package_dir = Path(__file__).parent  # unicef_api/
    python_dir = package_dir.parent  # python/
    metadata_dir = python_dir / "metadata" / "current"
    
    # Create directory if it doesn't exist (should already exist from other metadata)
    if metadata_dir.exists() or python_dir.exists():
        metadata_dir.mkdir(parents=True, exist_ok=True)
        return metadata_dir / CACHE_FILENAME
    
    # Fallback to user home directory (for installed packages)
    home_cache = Path.home() / ".unicef_api"
    home_cache.mkdir(parents=True, exist_ok=True)
    
    return home_cache / CACHE_FILENAME


def _parse_codelist_xml(xml_content: str) -> Dict[str, dict]:
    """Parse SDMX codelist XML response into indicator dictionary.
    
    Args:
        xml_content: Raw XML from SDMX API
        
    Returns:
        Dictionary mapping indicator codes to their metadata
    """
    # Define SDMX namespaces
    namespaces = {
        'message': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message',
        'structure': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
        'common': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common',
    }
    
    root = ET.fromstring(xml_content)
    indicators = {}
    
    # Find all Code elements
    for code_elem in root.findall('.//structure:Code', namespaces):
        code_id = code_elem.get('id')
        if not code_id:
            continue
        
        # Extract name (first available language)
        name_elem = code_elem.find('.//common:Name', namespaces)
        name = name_elem.text if name_elem is not None else ""
        
        # Extract description
        desc_elem = code_elem.find('.//common:Description', namespaces)
        description = desc_elem.text if desc_elem is not None else ""
        
        # Extract URN if available
        urn = code_elem.get('urn', '')
        
        # Infer category (dataflow) from indicator code prefix
        # Most UNICEF indicators follow the pattern: CATEGORY_SUFFIX
        # e.g., CME_MRY0T4 -> CME, NT_ANT_HAZ_NE2 -> NT (which maps to NUTRITION)
        category = _infer_category(code_id)
        
        indicators[code_id] = {
            'code': code_id,
            'name': name,
            'description': description,
            'urn': urn,
            'category': category,
        }
    
    return indicators


def _infer_category(indicator_code: str) -> str:
    """Infer the dataflow category from an indicator code.
    
    UNICEF indicator codes typically follow patterns like:
    - CME_MRY0T4 -> CME (Child Mortality Estimates)
    - NT_ANT_HAZ -> NT -> NUTRITION
    - IM_DTP3 -> IM -> IMMUNISATION
    - ED_ANAR_L1 -> ED -> EDUCATION
    
    Args:
        indicator_code: The indicator code
        
    Returns:
        Inferred category/dataflow name
    """
    # =========================================================================
    # KNOWN DATAFLOW OVERRIDES
    # =========================================================================
    # Some indicators exist in dataflows that don't match their prefix or the
    # metadata reports the wrong dataflow. These are known exceptions that 
    # require explicit mapping.
    #
    # Issue: The UNICEF SDMX API metadata sometimes reports indicators in a
    # generic dataflow (e.g., "PT", "EDUCATION") but the data only exists in
    # a more specific dataflow (e.g., "PT_CM", "EDUCATION_UIS_SDG").
    #
    # These mappings were discovered by testing against the production script:
    # PROD-SDG-REP-2025/01_data_prep/012_codes/0121_get_data_api.R
    # =========================================================================
    
    INDICATOR_DATAFLOW_OVERRIDES = {
        # Child Marriage - metadata says PT but data is in PT_CM
        'PT_F_20-24_MRD_U18_TND': 'PT_CM',
        'PT_F_20-24_MRD_U15': 'PT_CM',
        
        # FGM - metadata says PT but data is in PT_FGM
        'PT_F_15-49_FGM': 'PT_FGM',
        'PT_F_0-14_FGM': 'PT_FGM',
        'PT_F_15-19_FGM_TND': 'PT_FGM',
        'PT_F_15-49_FGM_TND': 'PT_FGM',
        'PT_F_15-49_FGM_ELIM': 'PT_FGM',
        'PT_M_15-49_FGM_ELIM': 'PT_FGM',
        
        # Education UIS SDG indicators - metadata says EDUCATION but data is in EDUCATION_UIS_SDG
        'ED_CR_L1_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_CR_L2_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_CR_L3_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_ROFST_L1_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_ROFST_L2_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_ROFST_L3_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_ANAR_L02': 'EDUCATION_UIS_SDG',
        'ED_MAT_G23': 'EDUCATION_UIS_SDG',
        'ED_MAT_L1': 'EDUCATION_UIS_SDG',
        'ED_MAT_L2': 'EDUCATION_UIS_SDG',
        'ED_READ_G23': 'EDUCATION_UIS_SDG',
        'ED_READ_L1': 'EDUCATION_UIS_SDG',
        'ED_READ_L2': 'EDUCATION_UIS_SDG',
        
        # Child Poverty - confirm correct dataflow
        'PV_CHLD_DPRV-S-L1-HS': 'CHLD_PVTY',
    }
    
    # Check if indicator has a known override
    if indicator_code in INDICATOR_DATAFLOW_OVERRIDES:
        return INDICATOR_DATAFLOW_OVERRIDES[indicator_code]
    
    # Mapping of prefixes to dataflows
    PREFIX_TO_DATAFLOW = {
        'CME': 'CME',
        'NT': 'NUTRITION',
        'IM': 'IMMUNISATION',
        'ED': 'EDUCATION',
        'WS': 'WASH_HOUSEHOLDS',
        'HVA': 'HIV_AIDS',
        'MNCH': 'MNCH',
        'PT': 'PT',
        'ECD': 'ECD',
        'DM': 'DM',
        'ECON': 'ECON',
        'GN': 'GENDER',
        'MG': 'MIGRATION',
        'FD': 'FUNCTIONAL_DIFF',
        'PP': 'POPULATION',
        'EMPH': 'EMPH',
        'EDUN': 'EDUCATION',
        'SDG4': 'EDUCATION_UIS_SDG',
        'PV': 'CHLD_PVTY',
    }
    
    # Try to match prefix
    parts = indicator_code.split('_')
    if parts:
        prefix = parts[0]
        if prefix in PREFIX_TO_DATAFLOW:
            return PREFIX_TO_DATAFLOW[prefix]
    
    # Default to GLOBAL_DATAFLOW for unrecognized patterns
    return 'GLOBAL_DATAFLOW'


def _fetch_codelist() -> Dict[str, dict]:
    """Fetch the indicator codelist from UNICEF SDMX API.
    
    Returns:
        Dictionary of indicator metadata
        
    Raises:
        ConnectionError: If API is unreachable
        ValueError: If response cannot be parsed
    """
    import requests
    
    logger.info(f"Fetching indicator codelist from {CODELIST_URL}")
    
    try:
        response = requests.get(CODELIST_URL, timeout=60)
        response.raise_for_status()
        
        indicators = _parse_codelist_xml(response.text)
        logger.info(f"Successfully fetched {len(indicators)} indicators")
        
        return indicators
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to fetch codelist: {e}")
        raise ConnectionError(f"Could not fetch indicator codelist: {e}")


def _load_cache() -> Tuple[Optional[Dict], Optional[datetime]]:
    """Load cached indicator metadata if available.
    
    Returns:
        Tuple of (indicators_dict, last_updated_datetime) or (None, None)
    """
    cache_path = _get_cache_path()
    
    if not cache_path.exists():
        return None, None
    
    try:
        with open(cache_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        if not data or 'indicators' not in data:
            return None, None
        
        # Parse last updated date
        last_updated = None
        if 'metadata' in data and 'last_updated' in data['metadata']:
            try:
                last_updated = datetime.fromisoformat(data['metadata']['last_updated'])
            except (ValueError, TypeError):
                pass
        
        return data['indicators'], last_updated
        
    except Exception as e:
        logger.warning(f"Failed to load cache: {e}")
        return None, None


def _save_cache(indicators: Dict[str, dict]) -> None:
    """Save indicator metadata to cache file.
    
    Args:
        indicators: Dictionary of indicator metadata
    """
    cache_path = _get_cache_path()
    
    # Ensure directory exists
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    
    data = {
        'metadata': {
            'version': '1.0',
            'source': 'UNICEF SDMX Codelist CL_UNICEF_INDICATOR',
            'url': CODELIST_URL,
            'last_updated': datetime.now().isoformat(),
            'description': 'Comprehensive UNICEF indicator codelist with metadata (auto-generated)',
            'indicator_count': len(indicators),
        },
        'indicators': indicators,
    }
    
    try:
        with open(cache_path, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False, width=10000)
        
        logger.info(f"Saved {len(indicators)} indicators to {cache_path}")
        
    except Exception as e:
        logger.error(f"Failed to save cache: {e}")


def _is_cache_stale(last_updated: Optional[datetime]) -> bool:
    """Check if cache is too old and needs refresh.
    
    Args:
        last_updated: When cache was last updated
        
    Returns:
        True if cache should be refreshed
    """
    if last_updated is None:
        return True
    
    age = datetime.now() - last_updated
    return age > timedelta(days=CACHE_MAX_AGE_DAYS)


# ============================================================================
# Module-level cache (for performance)
# ============================================================================

_indicator_cache: Optional[Dict[str, dict]] = None
_cache_loaded: bool = False


def _ensure_cache_loaded(force_refresh: bool = False) -> Dict[str, dict]:
    """Ensure indicator cache is loaded, fetching if necessary.
    
    Args:
        force_refresh: If True, always fetch fresh data from API
        
    Returns:
        Dictionary of indicator metadata
    """
    global _indicator_cache, _cache_loaded
    
    # Return memory cache if already loaded
    if _cache_loaded and _indicator_cache and not force_refresh:
        return _indicator_cache
    
    # Try to load from file cache
    cached_indicators, last_updated = _load_cache()
    
    # Use file cache if valid and not stale
    if cached_indicators and not _is_cache_stale(last_updated) and not force_refresh:
        _indicator_cache = cached_indicators
        _cache_loaded = True
        logger.debug(f"Loaded {len(cached_indicators)} indicators from cache")
        return _indicator_cache
    
    # Fetch fresh data from API
    try:
        fresh_indicators = _fetch_codelist()
        _save_cache(fresh_indicators)
        _indicator_cache = fresh_indicators
        _cache_loaded = True
        return _indicator_cache
        
    except ConnectionError as e:
        # If fetch fails but we have stale cache, use it
        if cached_indicators:
            logger.warning(f"Using stale cache (fetch failed): {e}")
            _indicator_cache = cached_indicators
            _cache_loaded = True
            return _indicator_cache
        
        # No cache and no connection - return empty
        logger.error("No cache available and cannot fetch from API")
        _indicator_cache = {}
        _cache_loaded = True
        return _indicator_cache


# ============================================================================
# Public API
# ============================================================================

def get_dataflow_for_indicator(indicator_code: str, default: str = "GLOBAL_DATAFLOW") -> str:
    """Get the dataflow (category) for a given indicator code.
    
    This function automatically loads the indicator cache on first use,
    fetching from the UNICEF SDMX API if necessary.
    
    IMPORTANT: Known dataflow overrides are checked FIRST as an optimization.
    This avoids unnecessary 404 errors for indicators where the API metadata
    is known to be incorrect. The get_unicef() function also has fallback 
    logic that will try alternative dataflows if the returned one fails.
    
    Args:
        indicator_code: UNICEF indicator code (e.g., "CME_MRY0T4")
        default: Default dataflow if indicator not found
        
    Returns:
        Dataflow name (e.g., "CME", "NUTRITION", "EDUCATION")
        
    Examples:
        >>> get_dataflow_for_indicator("CME_MRY0T4")
        'CME'
        
        >>> get_dataflow_for_indicator("NT_ANT_HAZ_NE2_MOD")
        'NUTRITION'
        
        >>> get_dataflow_for_indicator("ED_CR_L1_UIS_MOD")
        'EDUCATION_UIS_SDG'  # Uses known override to avoid 404
        
        >>> get_dataflow_for_indicator("UNKNOWN_IND")
        'GLOBAL_DATAFLOW'
    """
    # FIRST: Check known overrides (optimization to avoid 404 errors)
    # These are indicators where the API metadata reports the wrong dataflow.
    # Even if we remove these, the fallback logic in get_unicef() would still work,
    # but this saves an unnecessary failed API request.
    KNOWN_CORRECT_DATAFLOWS = {
        # Child Marriage - metadata says PT but data is in PT_CM
        'PT_F_20-24_MRD_U18_TND': 'PT_CM',
        'PT_F_20-24_MRD_U15': 'PT_CM',
        # FGM - metadata says PT but data is in PT_FGM
        'PT_F_15-49_FGM': 'PT_FGM',
        'PT_F_0-14_FGM': 'PT_FGM',
        'PT_F_15-19_FGM_TND': 'PT_FGM',
        'PT_F_15-49_FGM_TND': 'PT_FGM',
        'PT_F_15-49_FGM_ELIM': 'PT_FGM',
        'PT_M_15-49_FGM_ELIM': 'PT_FGM',
        # Education UIS SDG indicators - metadata says EDUCATION but data is in EDUCATION_UIS_SDG
        'ED_CR_L1_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_CR_L2_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_CR_L3_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_ROFST_L1_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_ROFST_L2_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_ROFST_L3_UIS_MOD': 'EDUCATION_UIS_SDG',
        'ED_ANAR_L02': 'EDUCATION_UIS_SDG',
        'ED_MAT_G23': 'EDUCATION_UIS_SDG',
        'ED_MAT_L1': 'EDUCATION_UIS_SDG',
        'ED_MAT_L2': 'EDUCATION_UIS_SDG',
        'ED_READ_G23': 'EDUCATION_UIS_SDG',
        'ED_READ_L1': 'EDUCATION_UIS_SDG',
        'ED_READ_L2': 'EDUCATION_UIS_SDG',
        'PV_CHLD_DPRV-S-L1-HS': 'CHLD_PVTY',
    }
    
    if indicator_code in KNOWN_CORRECT_DATAFLOWS:
        return KNOWN_CORRECT_DATAFLOWS[indicator_code]
    
    # SECOND: Check cache
    indicators = _ensure_cache_loaded()
    
    if indicator_code in indicators:
        return indicators[indicator_code].get('category', default)
    
    # THIRD: Use prefix-based inference
    inferred = _infer_category(indicator_code)
    if inferred != 'GLOBAL_DATAFLOW':
        return inferred
    
    return default


def get_indicator_info(indicator_code: str) -> Optional[dict]:
    """Get full metadata for an indicator.
    
    Args:
        indicator_code: UNICEF indicator code
        
    Returns:
        Dictionary with indicator metadata or None if not found
        
    Examples:
        >>> info = get_indicator_info("CME_MRY0T4")
        >>> print(info['name'])
        'Under-five mortality rate'
    """
    indicators = _ensure_cache_loaded()
    return indicators.get(indicator_code)


def list_indicators(
    dataflow: Optional[str] = None,
    name_contains: Optional[str] = None,
) -> Dict[str, dict]:
    """List all known indicators, optionally filtered.
    
    Args:
        dataflow: Filter by dataflow/category (e.g., "CME", "NUTRITION")
        name_contains: Filter by name substring (case-insensitive)
        
    Returns:
        Dictionary of matching indicators
        
    Examples:
        >>> mortality = list_indicators(dataflow="CME")
        >>> len(mortality)
        45
        
        >>> stunting = list_indicators(name_contains="stunting")
    """
    indicators = _ensure_cache_loaded()
    
    result = {}
    for code, info in indicators.items():
        # Apply dataflow filter
        if dataflow and info.get('category') != dataflow:
            continue
        
        # Apply name filter
        if name_contains:
            name = info.get('name', '').lower()
            if name_contains.lower() not in name:
                continue
        
        result[code] = info
    
    return result


def search_indicators(
    query: Optional[str] = None,
    category: Optional[str] = None,
    limit: int = 50,
    show_description: bool = True,
) -> None:
    """Search and display UNICEF indicators in a user-friendly format.
    
    This function allows analysts to search the indicator metadata to find
    indicator codes they need. Results are printed to the screen in a
    formatted table.
    
    Args:
        query: Search term to match in indicator code, name, or description
               (case-insensitive). If None, shows all indicators.
        category: Filter by dataflow/category (e.g., "CME", "NUTRITION", "IMMUNISATION").
                  Use list_categories() to see available categories.
        limit: Maximum number of results to display (default: 50).
               Set to None or 0 to show all matches.
        show_description: If True, includes description column (default: True).
        
    Returns:
        None. Results are printed to the screen.
        
    Examples:
        >>> # Search for mortality-related indicators
        >>> search_indicators("mortality")
        
        >>> # List all nutrition indicators
        >>> search_indicators(category="NUTRITION")
        
        >>> # Search for stunting across all categories
        >>> search_indicators("stunting")
        
        >>> # List all indicators (first 50)
        >>> search_indicators()
        
        >>> # List all CME indicators without limit
        >>> search_indicators(category="CME", limit=0)
    """
    indicators = _ensure_cache_loaded()
    
    # Filter indicators
    matches = []
    query_lower = query.lower() if query else None
    
    for code, info in indicators.items():
        # Apply category filter
        if category and info.get('category', '').upper() != category.upper():
            continue
        
        # Apply query filter (search in code, name, and description)
        if query_lower:
            code_match = query_lower in code.lower()
            name_match = query_lower in info.get('name', '').lower()
            desc_match = query_lower in info.get('description', '').lower()
            
            if not (code_match or name_match or desc_match):
                continue
        
        matches.append({
            'code': code,
            'name': info.get('name', ''),
            'category': info.get('category', ''),
            'description': info.get('description', '') or ''
        })
    
    # Sort by category, then by code
    matches.sort(key=lambda x: (x['category'], x['code']))
    
    # Apply limit
    total_matches = len(matches)
    if limit and limit > 0:
        matches = matches[:limit]
    
    # Print header
    print("\n" + "=" * 100)
    if query and category:
        print(f"  UNICEF Indicators matching '{query}' in category '{category}'")
    elif query:
        print(f"  UNICEF Indicators matching '{query}'")
    elif category:
        print(f"  UNICEF Indicators in category '{category}'")
    else:
        print("  All UNICEF Indicators")
    print("=" * 100)
    
    if not matches:
        print("\n  No indicators found matching your criteria.\n")
        print("  Tips:")
        print("  - Try a different search term")
        print("  - Use list_categories() to see available categories")
        print("  - Use search_indicators() with no arguments to see all indicators")
        print()
        return
    
    # Print results
    print(f"\n  Found {total_matches} indicator(s)", end="")
    if limit and limit > 0 and total_matches > limit:
        print(f" (showing first {limit})")
    else:
        print()
    print("-" * 100)
    
    # Calculate column widths
    code_width = max(len(m['code']) for m in matches)
    code_width = max(code_width, 15)  # Minimum width
    cat_width = max(len(m['category']) for m in matches)
    cat_width = max(cat_width, 10)
    
    # Available width for name (and description)
    if show_description:
        name_width = 35
        desc_width = 100 - code_width - cat_width - name_width - 10  # padding
    else:
        name_width = 100 - code_width - cat_width - 6
        desc_width = 0
    
    # Print column headers
    header = f"  {'CODE':<{code_width}}  {'CATEGORY':<{cat_width}}  {'NAME':<{name_width}}"
    if show_description:
        header += f"  {'DESCRIPTION':<{desc_width}}"
    print(header)
    print("-" * 100)
    
    # Print each indicator
    for m in matches:
        name = m['name'][:name_width-2] + ".." if len(m['name']) > name_width else m['name']
        
        row = f"  {m['code']:<{code_width}}  {m['category']:<{cat_width}}  {name:<{name_width}}"
        
        if show_description:
            desc = m['description'][:desc_width-2] + ".." if len(m['description']) > desc_width else m['description']
            row += f"  {desc}"
        
        print(row)
    
    print("-" * 100)
    
    # Print footer with tips
    if total_matches > len(matches):
        print(f"\n  Showing {len(matches)} of {total_matches} results. Use limit=0 to see all.")
    
    print("\n  Usage tips:")
    print("  - get_unicef(indicator='CODE') to fetch data for an indicator")
    print("  - get_indicator_info('CODE') to see full metadata for an indicator")
    print("  - list_categories() to see all available categories")
    print()


def list_categories() -> None:
    """List all available indicator categories (dataflows) with counts.
    
    Prints a formatted table of categories showing how many indicators
    are in each category.
    
    Examples:
        >>> list_categories()
    """
    indicators = _ensure_cache_loaded()
    
    # Count indicators per category
    category_counts = {}
    for code, info in indicators.items():
        cat = info.get('category', 'UNKNOWN')
        category_counts[cat] = category_counts.get(cat, 0) + 1
    
    # Sort by count (descending)
    sorted_cats = sorted(category_counts.items(), key=lambda x: -x[1])
    
    print("\n" + "=" * 50)
    print("  Available Indicator Categories")
    print("=" * 50)
    print(f"\n  {'CATEGORY':<25} {'COUNT':>10}")
    print("-" * 50)
    
    for cat, count in sorted_cats:
        print(f"  {cat:<25} {count:>10}")
    
    print("-" * 50)
    print(f"  {'TOTAL':<25} {sum(category_counts.values()):>10}")
    print()
    print("  Use search_indicators(category='CATEGORY_NAME') to see indicators")
    print()


def refresh_indicator_cache() -> int:
    """Force refresh of the indicator cache from UNICEF SDMX API.
    
    Returns:
        Number of indicators in the refreshed cache
        
    Raises:
        ConnectionError: If API is unreachable
    """
    indicators = _ensure_cache_loaded(force_refresh=True)
    return len(indicators)


def get_cache_info() -> dict:
    """Get information about the current cache state.
    
    Returns:
        Dictionary with cache metadata
    """
    cache_path = _get_cache_path()
    _, last_updated = _load_cache()
    
    return {
        'cache_path': str(cache_path),
        'exists': cache_path.exists(),
        'last_updated': last_updated.isoformat() if last_updated else None,
        'is_stale': _is_cache_stale(last_updated),
        'max_age_days': CACHE_MAX_AGE_DAYS,
        'indicator_count': len(_indicator_cache) if _indicator_cache else 0,
    }


# ============================================================================
# Initialization
# ============================================================================

def _init_registry():
    """Initialize the registry on module import (lazy loading).
    
    This doesn't actually load the cache - it just sets up the module.
    The cache is loaded on first use of any public function.
    """
    pass


_init_registry()

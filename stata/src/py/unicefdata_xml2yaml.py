#!/usr/bin/env python3
"""
XML to YAML converter for UNICEF SDMX data
Called from Stata to process large XML files that exceed Stata's line limits

Usage:
    python unicefdata_xml2yaml.py <type> <input_xml> <output_yaml> [options]

Types:
    dataflows, codelists, countries, regions, dimensions, attributes, indicators

Options:
    --version VERSION        Version string for metadata (default: 2.0.0)
    --agency AGENCY          Agency ID (default: UNICEF)
    --source SOURCE          Source identifier
    --codelist-id ID         Codelist ID for code types
    --codelist-name NAME     Codelist name for code types
    --enrich-dataflows       For indicators: query API to add dataflows field
"""

import xml.etree.ElementTree as ET
import argparse
import sys
import os
from datetime import datetime
from typing import Dict, List, Optional, Any, Set
from collections import defaultdict

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

# SDMX namespaces
NAMESPACES = {
    'mes': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message',
    'str': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
    'com': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common',
}

# Type configuration registry
TYPE_CONFIG = {
    'dataflows': {
        'xpath': './/str:Dataflow',
        'list_name': 'dataflows',
        'content_type': 'dataflow'
    },
    'codelists': {
        'xpath': './/str:Code',
        'list_name': 'codes',
        'content_type': 'codelist'
    },
    'countries': {
        'xpath': './/str:Code',
        'list_name': 'countries',
        'content_type': 'codelist'
    },
    'regions': {
        'xpath': './/str:Code',
        'list_name': 'regions',
        'content_type': 'codelist'
    },
    'dimensions': {
        'xpath': './/str:Dimension',
        'list_name': 'dimensions',
        'content_type': 'datastructure'
    },
    'attributes': {
        'xpath': './/str:Attribute',
        'list_name': 'attributes',
        'content_type': 'datastructure'
    },
    'indicators': {
        'xpath': './/str:Code',
        'list_name': 'indicators',
        'content_type': 'codelist'
    }
}


def escape_yaml_string(s: str) -> str:
    """Escape special characters for YAML string values."""
    if not s:
        return ''
    # Replace backslashes first
    s = s.replace('\\', '\\\\')
    # Replace single quotes
    s = s.replace("'", "''")
    # Replace newlines
    s = s.replace('\n', ' ').replace('\r', '')
    return s


def get_text(element: ET.Element, xpath: str, namespaces: dict) -> str:
    """Get text content of a child element."""
    child = element.find(xpath, namespaces)
    if child is not None and child.text:
        return child.text.strip()
    return ''


def parse_dataflow(element: ET.Element) -> Dict[str, Any]:
    """Parse a Dataflow element."""
    return {
        'id': element.get('id', ''),
        'name': escape_yaml_string(get_text(element, 'com:Name', NAMESPACES)),
        'version': element.get('version', ''),
        'agency_id': element.get('agencyID', '')
    }


def parse_code(element: ET.Element, include_category: bool = False, codelist_id: str = '') -> Dict[str, Any]:
    """Parse a Code element (for codelists, countries, regions, indicators)."""
    code_id = element.get('id', '')
    result = {
        'id': code_id,
        'name': escape_yaml_string(get_text(element, 'com:Name', NAMESPACES)),
        'description': escape_yaml_string(get_text(element, 'com:Description', NAMESPACES))
    }
    
    # Add category for indicators - use full code for dynamic pattern matching
    # Aligned with Python/R indicator_registry.py mappings
    if include_category and code_id:
        # Add URN for indicators
        if codelist_id:
            result['urn'] = f"urn:sdmx:org.sdmx.infomodel.codelist.Code=UNICEF:{codelist_id}(1.0).{code_id}"
        
        # Extract parent from <str:Parent><Ref id="..."/></str:Parent>
        parent_elem = element.find('str:Parent/Ref', NAMESPACES)
        if parent_elem is not None:
            parent_id = parent_elem.get('id', '')
            if parent_id:
                result['parent'] = parent_id
    
    return result


# DEPRECATED: Prefix-to-dataflow mapping is now only used for 'category' field
# (organizational purposes). Actual dataflow detection at runtime uses:
# - _dataflow_fallback_sequences.yaml (tries multiple dataflows per prefix)
# - WS_HCF_* -> WASH_HEALTHCARE_FACILITY, WS_SCH_* -> WASH_SCHOOLS, etc.
# See: _get_dataflow_direct.ado and _get_dataflow_for_indicator.ado
PREFIX_TO_CATEGORY = {
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
    # Added mappings to reduce GLOBAL_DATAFLOW catch-all
    'COD': 'CAUSE_OF_DEATH',      # Cause of death indicators (83)
    'TRGT': 'CHILD_RELATED_SDG',  # SDG/National targets (77)
    'SPP': 'SOC_PROTECTION',      # Social protection programs (10)
    'WT': 'PT',                   # Child labour/adolescent indicators (7)
}


def _map_prefix_to_dataflow(indicator_code: str) -> str:
    """Map an indicator code to a category name (for organizational purposes).
    
    DEPRECATED for dataflow detection. This function now only provides the
    'category' field value. Actual dataflow detection at runtime uses
    _dataflow_fallback_sequences.yaml which tries multiple dataflows per prefix.
    
    Uses dynamic pattern matching for sub-categories (FGM, CM, UIS)
    before falling back to prefix-based mapping.
    """
    # =========================================================================
    # DYNAMIC PATTERN-BASED OVERRIDES
    # =========================================================================
    # These patterns catch indicators that belong to specific sub-dataflows
    # based on content in their code, not just the prefix.
    # =========================================================================
    
    # FGM indicators: PT_*_FGM* -> PT_FGM
    if indicator_code.startswith('PT_') and '_FGM' in indicator_code:
        return 'PT_FGM'
    
    # Child Marriage indicators: PT_*_MRD_* -> PT_CM
    if indicator_code.startswith('PT_') and '_MRD_' in indicator_code:
        return 'PT_CM'
    
    # UIS SDG Education indicators: ED_*_UIS* -> EDUCATION_UIS_SDG
    if indicator_code.startswith('ED_') and '_UIS' in indicator_code:
        return 'EDUCATION_UIS_SDG'
    
    # Fall back to prefix-based mapping (for category field only, not dataflow)
    prefix = indicator_code.split('_')[0] if '_' in indicator_code else indicator_code
    return PREFIX_TO_CATEGORY.get(prefix, 'GLOBAL_DATAFLOW')


def parse_dimension(element: ET.Element) -> Dict[str, Any]:
    """Parse a Dimension element."""
    result = {
        'id': element.get('id', ''),
        'position': element.get('position', '')
    }
    
    # Look for codelist reference
    local_rep = element.find('.//str:LocalRepresentation', NAMESPACES)
    if local_rep is not None:
        enum = local_rep.find('.//str:Enumeration/Ref', NAMESPACES)
        if enum is not None:
            result['codelist'] = enum.get('id', '')
    
    return result


# ===========================================================================
# Dataflow Enrichment Functions
# ===========================================================================

# SDMX API endpoints for dataflow enrichment
DATAFLOW_URL = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/all/latest"
DATA_URL_TEMPLATE = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,{dataflow},1.0/all?format=sdmx-compact-2.1&detail=serieskeysonly"

# Namespaces for data queries
DATA_NAMESPACES = {
    'message': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message',
    'structure': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
    'common': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common',
    'generic': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/data/generic',
    'compact': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/data/compact',
}


def fetch_dataflows() -> List[str]:
    """Fetch all available dataflow IDs from UNICEF SDMX API."""
    if not HAS_REQUESTS:
        print("Warning: 'requests' package not available, skipping dataflow enrichment", file=sys.stderr)
        return []
    
    response = requests.get(DATAFLOW_URL, headers={'Accept': 'application/xml'}, timeout=60)
    response.raise_for_status()
    
    root = ET.fromstring(response.content)
    
    dataflows = []
    for df in root.findall('.//structure:Dataflow', DATA_NAMESPACES):
        df_id = df.get('id')
        if df_id:
            dataflows.append(df_id)
    
    return sorted(dataflows)


def fetch_indicators_for_dataflow(dataflow: str) -> Set[str]:
    """Fetch all indicator codes from a dataflow using serieskeysonly."""
    url = DATA_URL_TEMPLATE.format(dataflow=dataflow)
    
    try:
        response = requests.get(url, headers={'Accept': 'application/xml'}, timeout=120)
        response.raise_for_status()
    except requests.exceptions.HTTPError:
        return set()
    except requests.exceptions.Timeout:
        return set()
    except Exception:
        return set()
    
    indicators = set()
    
    try:
        root = ET.fromstring(response.content)
        
        # Try compact format (most common)
        for series in root.findall('.//{http://www.sdmx.org/resources/sdmxml/schemas/v2_1/data/compact}Series'):
            indicator = series.get('INDICATOR')
            if indicator:
                indicators.add(indicator)
        
        # Also try without namespace
        if not indicators:
            for series in root.iter():
                if series.tag.endswith('Series'):
                    indicator = series.get('INDICATOR')
                    if indicator:
                        indicators.add(indicator)
        
        # Try generic format if compact didn't work
        if not indicators:
            for obs_key in root.findall('.//generic:SeriesKey/generic:Value[@id="INDICATOR"]', DATA_NAMESPACES):
                indicator = obs_key.get('value')
                if indicator:
                    indicators.add(indicator)
    
    except ET.ParseError:
        return set()
    
    return indicators


def build_indicator_to_dataflow_map(data: List[Dict], verbose: bool = True) -> Dict[str, List[str]]:
    """Build mapping of indicator code -> list of dataflows containing it.
    
    Initializes with ALL indicators from data (including orphans with empty list),
    then populates dataflows for indicators found in API queries.
    """
    if not HAS_REQUESTS:
        return {}
    
    # Initialize mapping with all indicators (orphans get empty list)
    indicator_to_dataflows = {item['id']: [] for item in data if item.get('id')}
    total_indicators = len(indicator_to_dataflows)
    
    if verbose:
        print("Enriching indicators with dataflow information...")
        print(f"  Starting with all {total_indicators} indicators from codelist")
        print("  Fetching dataflow list...", end=" ", flush=True)
    
    dataflows = fetch_dataflows()
    if verbose:
        print(f"found {len(dataflows)}")
    
    dataflows_with_data = 0
    indicators_with_dataflows = 0
    
    for i, dataflow in enumerate(dataflows, 1):
        if verbose:
            print(f"  [{i}/{len(dataflows)}] {dataflow}...", end=" ", flush=True)
        
        indicators = fetch_indicators_for_dataflow(dataflow)
        
        if indicators:
            dataflows_with_data += 1
            for indicator in indicators:
                if indicator in indicator_to_dataflows:
                    indicator_to_dataflows[indicator].append(dataflow)
                    if len(indicator_to_dataflows[indicator]) == 1:
                        indicators_with_dataflows += 1
            if verbose:
                print(f"{len(indicators)} indicators")
        else:
            if verbose:
                print("no data")
    
    if verbose:
        orphans = total_indicators - indicators_with_dataflows
        print(f"  Dataflows with data: {dataflows_with_data}")
        print(f"  Total indicators in codelist: {total_indicators}")
        print(f"  Indicators with dataflows: {indicators_with_dataflows}")
        print(f"  Orphan indicators (no dataflows): {orphans}")
    
    return indicator_to_dataflows


def generate_fallback_sequences(indicator_to_dataflows: Dict[str, List[str]], output_path: str, verbose: bool = True):
    """Generate fallback sequences YAML from indicator-to-dataflow mapping.
    
    Analyzes which dataflows contain indicators with each prefix, then creates
    ordered fallback sequences based on frequency (most common dataflow first).
    """
    if verbose:
        print("Generating fallback sequences...")
    
    # Build prefix -> dataflow -> count mapping
    prefix_dataflow_counts = defaultdict(lambda: defaultdict(int))
    
    for indicator, dataflows in indicator_to_dataflows.items():
        # Extract prefix (first part before underscore)
        prefix = indicator.split('_')[0] if '_' in indicator else indicator
        for df in dataflows:
            prefix_dataflow_counts[prefix][df] += 1
    
    # Sort dataflows by frequency for each prefix
    fallback_sequences = {}
    for prefix in sorted(prefix_dataflow_counts.keys()):
        df_counts = prefix_dataflow_counts[prefix]
        # Sort by count descending, then alphabetically
        sorted_dfs = sorted(df_counts.keys(), key=lambda x: (-df_counts[x], x))
        # Always end with GLOBAL_DATAFLOW if not already present
        if 'GLOBAL_DATAFLOW' not in sorted_dfs:
            sorted_dfs.append('GLOBAL_DATAFLOW')
        fallback_sequences[prefix] = sorted_dfs
    
    # Build dataflow categories (group related dataflows)
    dataflow_categories = defaultdict(list)
    category_keywords = {
        'MORTALITY': ['CME', 'CAUSE_OF_DEATH', 'MORTALITY'],
        'HEALTH': ['MNCH', 'IMMUNISATION', 'NUTRITION', 'HIV', 'HEALTH', 'FUNCTIONAL'],
        'EDUCATION': ['EDUCATION', 'ECD', 'UIS'],
        'WASH': ['WASH'],
        'PROTECTION': ['PT', 'PROTECTION', 'FGM', 'CONFLICT'],
        'SOCIAL_DEVELOPMENT': ['SOC_PROTECTION', 'POVERTY', 'GENDER', 'PVTY'],
        'DEMOGRAPHICS': ['DM', 'DEMOGRAPHICS', 'POPULATION', 'MIGRATION'],
        'ECONOMIC': ['ECONOMIC', 'LABOUR', 'EMPLOYMENT'],
        'EMERGENCY': ['COVID', 'EMERGENCY'],
    }
    
    all_dataflows = set()
    for dfs in indicator_to_dataflows.values():
        all_dataflows.update(dfs)
    
    for df in sorted(all_dataflows):
        for category, keywords in category_keywords.items():
            if any(kw in df.upper() for kw in keywords):
                dataflow_categories[category].append(df)
                break
    
    # Write YAML
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('metadata:\n')
        f.write("  version: '1.1.0'\n")
        f.write(f"  created: '{datetime.now().strftime('%Y-%m-%d')}'\n")
        f.write(f"  last_updated: '{datetime.now().strftime('%Y-%m-%d')}'\n")
        f.write(f'  source: UNICEF SDMX Dataflow Analysis ({len(all_dataflows)} dataflows)\n')
        f.write('  author: Auto-generated from API data\n')
        f.write('  description: |\n')
        f.write('    Canonical fallback sequences for cross-platform indicator dataflow resolution.\n')
        f.write('    Used by Python, R, and Stata to consistently resolve indicators to SDMX dataflows.\n')
        f.write('    Each prefix maps to a sequence of dataflows to try in order.\n')
        f.write('    Generated from actual API data - most common dataflow listed first.\n')
        f.write('\n')
        
        f.write('# Fallback sequences organized by indicator prefix\n')
        f.write('# Format: prefix -> list of dataflows (try in order until one succeeds)\n')
        f.write(f'# Based on {len(all_dataflows)} unique SDMX dataflows analyzed {datetime.now().strftime("%Y-%m-%d")}\n')
        f.write('fallback_sequences:\n')
        
        for prefix in sorted(fallback_sequences.keys()):
            dfs = fallback_sequences[prefix]
            f.write(f'  {prefix}:\n')
            for df in dfs:
                f.write(f'    - {df}\n')
            f.write('\n')
        
        # Add DEFAULT fallback
        f.write('  # Default fallback for unknown/unmapped prefixes\n')
        f.write('  DEFAULT:\n')
        f.write('    - GLOBAL_DATAFLOW\n')
        f.write('\n')
        
        # Write dataflow categories
        f.write('# Additional metadata: mapping of dataflows to categories\n')
        f.write('# Useful for diagnostics and understanding indicator routing\n')
        f.write('dataflow_categories:\n')
        for category in sorted(dataflow_categories.keys()):
            dfs = sorted(dataflow_categories[category])
            f.write(f'  {category}:\n')
            for df in dfs:
                f.write(f'    - {df}\n')
            f.write('\n')
    
    if verbose:
        print(f"  Generated fallback sequences for {len(fallback_sequences)} prefixes")
        print(f"  Output: {output_path}")


def parse_attribute(element: ET.Element) -> Dict[str, Any]:
    """Parse an Attribute element."""
    result = {
        'id': element.get('id', ''),
        'name': escape_yaml_string(get_text(element, 'com:Name', NAMESPACES))
    }
    
    # Look for codelist reference
    local_rep = element.find('.//str:LocalRepresentation', NAMESPACES)
    if local_rep is not None:
        enum = local_rep.find('.//str:Enumeration/Ref', NAMESPACES)
        if enum is not None:
            result['codelist'] = enum.get('id', '')
    
    return result


def write_yaml(
    output_path: str,
    data: List[Dict],
    data_type: str,
    version: str,
    agency: str,
    source: Optional[str] = None,
    codelist_id: Optional[str] = None,
    codelist_name: Optional[str] = None,
    indicator_to_dataflows: Optional[Dict[str, List[str]]] = None
):
    """Write parsed data to YAML file in R-compatible dict format."""
    config = TYPE_CONFIG.get(data_type, {})
    list_name = config.get('list_name', data_type)
    content_type = config.get('content_type', data_type)
    
    # Build URL based on type
    if data_type == 'indicators':
        url = f'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/{agency}/CL_UNICEF_INDICATOR/1.0'
    elif data_type == 'countries':
        url = f'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/{agency}/CL_REF_AREA/1.0'
    elif data_type == 'regions':
        url = f'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/{agency}/CL_REF_AREA_SDG/1.0'
    elif data_type == 'dataflows':
        url = f'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/{agency}/all/latest'
    else:
        url = f'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/{agency}/{codelist_id or "ALL"}/latest'
    
    # Count indicators with dataflow mappings
    indicators_with_dataflows = 0
    if indicator_to_dataflows:
        for item in data:
            if item.get('id') in indicator_to_dataflows:
                indicators_with_dataflows += 1
    
    with open(output_path, 'w', encoding='utf-8') as f:
        # Write metadata header (R-compatible format)
        f.write('metadata:\n')
        f.write(f"  version: '{version}'\n")
        if data_type == 'indicators':
            f.write(f'  source: {agency} SDMX Codelist CL_UNICEF_INDICATOR\n')
        elif codelist_id:
            f.write(f'  source: {agency} SDMX Codelist {codelist_id}\n')
        else:
            f.write(f'  source: {agency} SDMX {content_type}\n')
        f.write(f'  url: {url}\n')
        f.write(f"  last_updated: {datetime.now().strftime('%Y-%m-%dT%H:%M:%S')}\n")
        f.write(f'  description: Comprehensive {agency} {data_type} {content_type} with metadata (auto-generated)\n')
        f.write(f'  {data_type.rstrip("s")}_count: {len(data)}\n')
        
        # Additional metadata for enriched indicators
        if data_type == 'indicators' and indicator_to_dataflows:
            # Count indicators with and without dataflows
            with_dfs = sum(1 for dfs in indicator_to_dataflows.values() if dfs)
            orphans = len(indicator_to_dataflows) - with_dfs
            f.write(f'  indicators_with_dataflows: {with_dfs}\n')
            if orphans > 0:
                f.write(f'  orphan_indicators: {orphans}\n')
            # Count unique dataflows
            all_dataflows = set()
            for dfs in indicator_to_dataflows.values():
                all_dataflows.update(dfs)
            f.write(f'  dataflow_count: {len(all_dataflows)}\n')
        
        # Write dict-based data (R-compatible format)
        f.write(f'{list_name}:\n')
        
        # Write each item as dict entry (keyed by ID)
        for item in data:
            item_id = item.get('id', '')
            if not item_id:
                continue
            
            f.write(f'  {item_id}:\n')
            f.write(f'    code: {item_id}\n')
            
            # Name field - always quote to handle colons and special chars
            name = item.get('name', '')
            if name:
                f.write(f"    name: '{name}'\n")
            
            # Description field - always quote
            desc = item.get('description', '')
            if desc:
                f.write(f"    description: '{desc}'\n")
            else:
                f.write("    description: ''\n")
            
            if data_type == 'indicators':
                # URN field
                urn = item.get('urn', '')
                if urn:
                    f.write(f'    urn: {urn}\n')
                # Parent field (hierarchical relationship from SDMX)
                parent = item.get('parent', '')
                if parent:
                    f.write(f'    parent: {parent}\n')
                # Dataflows field (from API enrichment) - ALWAYS write for completeness
                if indicator_to_dataflows and item_id in indicator_to_dataflows:
                    dfs = indicator_to_dataflows[item_id]
                    if dfs:  # Has dataflows
                        dfs_sorted = sorted(dfs)
                        if len(dfs_sorted) == 1:
                            f.write(f'    dataflows: {dfs_sorted[0]}\n')
                        else:
                            f.write('    dataflows:\n')
                            for df in dfs_sorted:
                                f.write(f'      - {df}\n')
                    else:  # Orphan indicator (in codelist but not in any dataflow)
                        f.write('    dataflows: []\n')
            
            elif data_type == 'dataflows':
                if item.get('version'):
                    f.write(f"    version: '{item['version']}'\n")
                if item.get('agency_id'):
                    f.write(f'    agency_id: {item["agency_id"]}\n')
            
            elif data_type == 'dimensions':
                if item.get('position'):
                    f.write(f'    position: {item["position"]}\n')
                if item.get('codelist'):
                    f.write(f'    codelist: {item["codelist"]}\n')
            
            elif data_type == 'attributes':
                if item.get('codelist'):
                    f.write(f'    codelist: {item["codelist"]}\n')


def parse_xml(input_path: str, data_type: str, codelist_id: str = '') -> List[Dict]:
    """Parse XML file and return list of elements."""
    config = TYPE_CONFIG.get(data_type)
    if not config:
        raise ValueError(f"Unknown type: {data_type}")
    
    # Parse XML
    tree = ET.parse(input_path)
    root = tree.getroot()
    
    # Try to extract codelist ID from XML if not provided
    if not codelist_id and data_type == 'indicators':
        codelist_el = root.find('.//str:Codelist', NAMESPACES)
        if codelist_el is not None:
            codelist_id = codelist_el.get('id', 'CL_UNICEF_INDICATOR')
        else:
            codelist_id = 'CL_UNICEF_INDICATOR'
    
    # Find elements
    xpath = config['xpath']
    elements = root.findall(xpath, NAMESPACES)
    
    # Parse based on type
    result = []
    if data_type == 'dataflows':
        result = [parse_dataflow(el) for el in elements]
    elif data_type == 'indicators':
        # Include category and URN for indicators
        result = [parse_code(el, include_category=True, codelist_id=codelist_id) for el in elements]
    elif data_type in ('codelists', 'countries', 'regions'):
        result = [parse_code(el) for el in elements]
    elif data_type == 'dimensions':
        result = [parse_dimension(el) for el in elements]
    elif data_type == 'attributes':
        result = [parse_attribute(el) for el in elements]
    
    return result


def main():
    parser = argparse.ArgumentParser(
        description='Convert UNICEF SDMX XML to YAML format'
    )
    parser.add_argument('type', choices=list(TYPE_CONFIG.keys()),
                        help='Type of data to parse')
    parser.add_argument('input', help='Input XML file path')
    parser.add_argument('output', help='Output YAML file path')
    parser.add_argument('--version', default='2.0.0',
                        help='Version string for metadata')
    parser.add_argument('--agency', default='UNICEF',
                        help='Agency ID')
    parser.add_argument('--source', help='Source identifier')
    parser.add_argument('--codelist-id', help='Codelist ID')
    parser.add_argument('--codelist-name', help='Codelist name')
    parser.add_argument('--enrich-dataflows', action='store_true',
                        help='For indicators: query API to add dataflows field (requires requests package)')
    parser.add_argument('--fallback-sequences-output', 
                        help='Also generate fallback sequences YAML to this path (only with --enrich-dataflows)')
    
    args = parser.parse_args()
    
    # Verify input file exists
    if not os.path.exists(args.input):
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Parse XML
        data = parse_xml(args.input, args.type)
        
        # Build indicator-to-dataflow mapping if requested
        indicator_to_dataflows = None
        if args.enrich_dataflows and args.type == 'indicators':
            if not HAS_REQUESTS:
                print("Warning: --enrich-dataflows requires 'requests' package. Install with: pip install requests", file=sys.stderr)
            else:
                indicator_to_dataflows = build_indicator_to_dataflow_map(data, verbose=True)
                
                # Generate fallback sequences if requested
                if args.fallback_sequences_output and indicator_to_dataflows:
                    generate_fallback_sequences(indicator_to_dataflows, args.fallback_sequences_output, verbose=True)
        
        # Write YAML
        write_yaml(
            args.output,
            data,
            args.type,
            args.version,
            args.agency,
            args.source,
            getattr(args, 'codelist_id', None),
            getattr(args, 'codelist_name', None),
            indicator_to_dataflows
        )
        
        print(f"Success: Parsed {len(data)} {args.type}")
        if indicator_to_dataflows:
            print(f"  Enriched with dataflow info: {len(indicator_to_dataflows)} indicators have dataflows")
        print(f"Output: {args.output}")
        
    except ET.ParseError as e:
        print(f"XML Parse Error: {e}", file=sys.stderr)
        sys.exit(2)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(3)


if __name__ == '__main__':
    main()

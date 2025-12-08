#!/usr/bin/env python3
"""
XML to YAML converter for UNICEF SDMX data
Called from Stata to process large XML files that exceed Stata's line limits

Usage:
    python python_xml_helper.py <type> <input_xml> <output_yaml> [options]

Types:
    dataflows, codelists, countries, regions, dimensions, attributes, indicators

Options:
    --version VERSION        Version string for metadata (default: 2.0.0)
    --agency AGENCY          Agency ID (default: UNICEF)
    --source SOURCE          Source identifier
    --codelist-id ID         Codelist ID for code types
    --codelist-name NAME     Codelist name for code types
"""

import xml.etree.ElementTree as ET
import argparse
import sys
import os
from datetime import datetime
from typing import Dict, List, Optional, Any

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
    
    # Add category for indicators (prefix before first underscore)
    if include_category and code_id:
        if '_' in code_id:
            result['category'] = code_id.split('_')[0]
        else:
            result['category'] = code_id
        
        # Add URN for indicators
        if codelist_id:
            result['urn'] = f"urn:sdmx:org.sdmx.infomodel.codelist.Code=UNICEF:{codelist_id}(1.0).{code_id}"
    
    return result


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
    codelist_name: Optional[str] = None
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
                # Category field
                category = item.get('category', '')
                if category:
                    f.write(f'    category: {category}\n')
            
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
    
    args = parser.parse_args()
    
    # Verify input file exists
    if not os.path.exists(args.input):
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Parse XML
        data = parse_xml(args.input, args.type)
        
        # Write YAML
        write_yaml(
            args.output,
            data,
            args.type,
            args.version,
            args.agency,
            args.source,
            args.codelist_id,
            args.codelist_name
        )
        
        print(f"Success: Parsed {len(data)} {args.type}")
        print(f"Output: {args.output}")
        
    except ET.ParseError as e:
        print(f"XML Parse Error: {e}", file=sys.stderr)
        sys.exit(2)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(3)


if __name__ == '__main__':
    main()

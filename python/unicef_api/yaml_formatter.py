"""
YAML Formatter for unicefData package.

This module provides standardized YAML formatting across all platforms
(Python, R, Stata) to ensure consistent metadata files.

Usage:
    from unicef_api.yaml_formatter import YAMLFormatter
    
    formatter = YAMLFormatter()
    formatter.format_file('input.yaml', 'output.yaml')
    
    # Or format dict to string
    yaml_str = formatter.dumps(data)
"""

import yaml
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Union
import re


class YAMLFormatter:
    """
    Standardized YAML formatter for unicefData metadata files.
    
    Ensures consistent formatting across all platforms:
    - 2-space indentation
    - No line wrapping (width=10000)
    - Sorted keys disabled by default (preserve order)
    - UTF-8 encoding
    - Consistent metadata headers
    """
    
    # Standard metadata header template
    METADATA_HEADER_TEMPLATE = {
        '_metadata': {
            'platform': None,  # 'python', 'R', 'stata'
            'version': '2.0.0',
            'synced_at': None,  # ISO format timestamp
            'source': None,     # e.g., 'SDMX API', 'unicef_api.config'
            'agency': 'UNICEF',
            'content_type': None,  # e.g., 'dataflows', 'indicators', 'countries'
        }
    }
    
    # Alternative header for indicator_metadata files
    INDICATOR_METADATA_HEADER = {
        'metadata': {
            'version': '1.0',
            'source': 'UNICEF SDMX Codelist CL_UNICEF_INDICATOR',
            'url': 'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0',
            'last_updated': None,
            'description': 'Comprehensive UNICEF indicator codelist with metadata (auto-generated)',
            'indicator_count': None,
        }
    }
    
    # Header for dataflow_index files
    DATAFLOW_INDEX_HEADER = {
        'metadata_version': '1.0',
        'synced_at': None,
        'source': 'SDMX API Data Structure Definitions',
        'agency': 'UNICEF',
        'total_dataflows': None,
    }
    
    # Header for individual dataflow schema files
    DATAFLOW_SCHEMA_HEADER = {
        'version': '1.0',
        'synced_at': None,
        'agency': 'UNICEF',
    }
    
    def __init__(
        self,
        indent: int = 2,
        width: int = 10000,
        sort_keys: bool = False,
        default_flow_style: bool = False,
        allow_unicode: bool = True,
    ):
        """
        Initialize the YAML formatter.
        
        Args:
            indent: Number of spaces for indentation (default: 2)
            width: Maximum line width before wrapping (default: 10000 = no wrap)
            sort_keys: Whether to sort dictionary keys (default: False)
            default_flow_style: Use flow style for collections (default: False)
            allow_unicode: Allow Unicode characters (default: True)
        """
        self.indent = indent
        self.width = width
        self.sort_keys = sort_keys
        self.default_flow_style = default_flow_style
        self.allow_unicode = allow_unicode
        
        # Configure custom representer for cleaner output
        self._setup_representer()
    
    def _setup_representer(self):
        """Setup custom YAML representers for cleaner output."""
        # Use literal block style for multiline strings
        def str_representer(dumper, data):
            if '\n' in data:
                return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
            return dumper.represent_scalar('tag:yaml.org,2002:str', data)
        
        yaml.add_representer(str, str_representer)
    
    def dumps(self, data: Dict[str, Any]) -> str:
        """
        Dump data to YAML string with standard formatting.
        
        Args:
            data: Dictionary to convert to YAML
            
        Returns:
            Formatted YAML string
        """
        return yaml.dump(
            data,
            default_flow_style=self.default_flow_style,
            allow_unicode=self.allow_unicode,
            indent=self.indent,
            width=self.width,
            sort_keys=self.sort_keys,
        )
    
    def loads(self, yaml_str: str) -> Dict[str, Any]:
        """
        Load YAML string to dictionary.
        
        Args:
            yaml_str: YAML formatted string
            
        Returns:
            Parsed dictionary
        """
        return yaml.safe_load(yaml_str)
    
    def format_file(
        self,
        input_path: Union[str, Path],
        output_path: Optional[Union[str, Path]] = None,
    ) -> None:
        """
        Read, reformat, and write a YAML file with standard formatting.
        
        Args:
            input_path: Path to input YAML file
            output_path: Path to output file (defaults to input_path)
        """
        input_path = Path(input_path)
        output_path = Path(output_path) if output_path else input_path
        
        with open(input_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(self.dumps(data))
    
    def create_metadata_header(
        self,
        platform: str,
        content_type: str,
        source: str,
        extra_fields: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Create a standardized metadata header.
        
        Args:
            platform: Platform name ('python', 'R', 'stata')
            content_type: Type of content ('dataflows', 'indicators', etc.)
            source: Data source description
            extra_fields: Additional fields to include
            
        Returns:
            Metadata header dictionary
        """
        header = {
            '_metadata': {
                'platform': platform,
                'version': '2.0.0',
                'synced_at': datetime.now(timezone.utc).isoformat(),
                'source': source,
                'agency': 'UNICEF',
                'content_type': content_type,
            }
        }
        
        if extra_fields:
            header['_metadata'].update(extra_fields)
        
        return header
    
    def add_header_to_file(
        self,
        file_path: Union[str, Path],
        header_type: str = 'standard',
        platform: str = 'python',
        **kwargs,
    ) -> None:
        """
        Add or update metadata header in a YAML file.
        
        Args:
            file_path: Path to YAML file
            header_type: Type of header ('standard', 'indicator_metadata', 'dataflow_index', 'dataflow_schema')
            platform: Platform name
            **kwargs: Additional header fields
        """
        file_path = Path(file_path)
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        # Remove existing metadata headers
        for key in ['_metadata', 'metadata', 'metadata_version']:
            if key in data:
                del data[key]
        
        # Create new header based on type
        if header_type == 'standard':
            header = self.create_metadata_header(
                platform=platform,
                content_type=kwargs.get('content_type', 'unknown'),
                source=kwargs.get('source', 'SDMX API'),
                extra_fields=kwargs.get('extra_fields'),
            )
            # Merge header with data, header first
            new_data = {**header, **data}
            
        elif header_type == 'indicator_metadata':
            indicator_count = len(data.get('indicators', {}))
            header = {
                'metadata': {
                    'version': '1.0',
                    'source': 'UNICEF SDMX Codelist CL_UNICEF_INDICATOR',
                    'url': 'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0',
                    'last_updated': datetime.now(timezone.utc).isoformat(),
                    'description': 'Comprehensive UNICEF indicator codelist with metadata (auto-generated)',
                    'indicator_count': indicator_count,
                }
            }
            new_data = {**header, **data}
            
        elif header_type == 'dataflow_index':
            total = len(data.get('dataflows', []))
            header = {
                'metadata_version': '1.0',
                'synced_at': datetime.now(timezone.utc).isoformat(),
                'source': 'SDMX API Data Structure Definitions',
                'agency': 'UNICEF',
                'total_dataflows': total,
            }
            # For dataflow_index, header fields come before 'dataflows' key
            new_data = {**header, 'dataflows': data.get('dataflows', [])}
            
        elif header_type == 'dataflow_schema':
            header = {
                'version': '1.0',
                'synced_at': datetime.now(timezone.utc).isoformat(),
                'agency': 'UNICEF',
            }
            new_data = {**header, **data}
        else:
            new_data = data
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(self.dumps(new_data))
    
    @staticmethod
    def get_timestamp() -> str:
        """Get current UTC timestamp in ISO format."""
        return datetime.now(timezone.utc).isoformat()


def normalize_yaml_files(
    directory: Union[str, Path],
    recursive: bool = True,
) -> int:
    """
    Normalize all YAML files in a directory to standard formatting.
    
    Args:
        directory: Directory containing YAML files
        recursive: Whether to process subdirectories
        
    Returns:
        Number of files processed
    """
    directory = Path(directory)
    formatter = YAMLFormatter()
    
    pattern = '**/*.yaml' if recursive else '*.yaml'
    files = list(directory.glob(pattern))
    
    for file_path in files:
        try:
            formatter.format_file(file_path)
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    
    return len(files)


if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='YAML Formatter for unicefData')
    parser.add_argument('path', help='File or directory to format')
    parser.add_argument('--recursive', '-r', action='store_true', help='Process subdirectories')
    parser.add_argument('--add-header', choices=['standard', 'indicator_metadata', 'dataflow_index', 'dataflow_schema'])
    parser.add_argument('--platform', default='python', choices=['python', 'R', 'stata'])
    
    args = parser.parse_args()
    
    path = Path(args.path)
    
    if path.is_dir():
        count = normalize_yaml_files(path, args.recursive)
        print(f"Formatted {count} files")
    else:
        formatter = YAMLFormatter()
        if args.add_header:
            formatter.add_header_to_file(path, args.add_header, args.platform)
        else:
            formatter.format_file(path)
        print(f"Formatted {path}")

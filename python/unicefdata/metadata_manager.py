import os
import yaml
import pandas as pd
from typing import Dict, List, Optional, Any
import logging
from unicefdata.schema_sync import get_dataflow_schema

logger = logging.getLogger(__name__)

class MetadataManager:
    """
    Manages loading and applying dataflow schemas for validation and standardization.
    """
    
    def __init__(self, metadata_dir: str = None):
        """
        Initialize MetadataManager with session-level schema caching.
        
        Args:
            metadata_dir: Path to metadata directory. If None, attempts to locate
                         it relative to this file.
        """
        if metadata_dir is None:
            # Default to bundled metadata inside the package (unicefdata/metadata/current/)
            current_dir = os.path.dirname(os.path.abspath(__file__))
            bundled = os.path.join(current_dir, 'metadata', 'current')
            if os.path.exists(bundled):
                self.metadata_dir = bundled
            else:
                # Fallback: legacy path (python/metadata/current/)
                package_root = os.path.dirname(current_dir)
                self.metadata_dir = os.path.join(package_root, 'metadata', 'current')
        else:
            self.metadata_dir = metadata_dir
            
        # Session-level in-memory cache for dataflow schemas
        # Key: dataflow_id (e.g., 'CME', 'GLOBAL_DATAFLOW')
        # Value: schema dictionary
        # Avoids redundant YAML file reads for same dataflow
        self.schemas = {}
        self.codelists = None
        
    def _load_codelists(self):
        """Load codelists from codelists.yaml if not already loaded."""
        if self.codelists is not None:
            return
            
        codelists_path = os.path.join(self.metadata_dir, 'codelists.yaml')
        if not os.path.exists(codelists_path):
            logger.warning(f"Codelists file not found at {codelists_path}")
            self.codelists = {}
            return
            
        try:
            with open(codelists_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
                self.codelists = data.get('codelists', {})
        except Exception as e:
            logger.error(f"Error loading codelists: {e}")
            self.codelists = {}

    def get_codelist(self, codelist_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a specific codelist by ID.
        
        Args:
            codelist_id: ID of the codelist (e.g., 'CL_SEX')
            
        Returns:
            Dictionary containing codelist data, or None if not found.
        """
        self._load_codelists()
        return self.codelists.get(codelist_id)
        
    def get_schema(self, dataflow_id: str) -> Optional[Dict[str, Any]]:
        """
        Load schema for a dataflow with session-level caching.
        
        Uses in-memory cache: First call loads from disk/API, subsequent
        calls for the same dataflow return the cached copy. This means
        fetching multiple indicators from the same dataflow (e.g.,
        CME_MRY0T4, CME_TMY0T4) only reads the CME schema once per session.
        
        Args:
            dataflow_id: ID of the dataflow (e.g., 'CME', 'GLOBAL_DATAFLOW')
            
        Returns:
            Dictionary containing the schema, or None if not found.
        """
        # Check session-level cache first (avoids redundant disk I/O)
        if dataflow_id in self.schemas:
            return self.schemas[dataflow_id]
            
        # Try to find the file
        schema_path = os.path.join(self.metadata_dir, 'dataflows', f'{dataflow_id}.yaml')
        
        if not os.path.exists(schema_path):
            # Try to fetch schema on-demand
            logger.info(f"Schema for {dataflow_id} not found locally. Fetching from API...")
            try:
                schema = get_dataflow_schema(dataflow_id)
                if schema:
                    # Ensure directory exists
                    os.makedirs(os.path.dirname(schema_path), exist_ok=True)
                    
                    # Save schema
                    with open(schema_path, 'w', encoding='utf-8') as f:
                        yaml.dump(schema, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
                    
                    self.schemas[dataflow_id] = schema
                    logger.info(f"Successfully fetched and saved schema for {dataflow_id}")
                    return schema
                else:
                    logger.warning(f"Could not fetch schema for {dataflow_id}")
                    return None
            except Exception as e:
                logger.error(f"Error fetching schema for {dataflow_id}: {e}")
                return None
            
        try:
            with open(schema_path, 'r', encoding='utf-8') as f:
                schema = yaml.safe_load(f)
            self.schemas[dataflow_id] = schema
            return schema
        except Exception as e:
            logger.error(f"Error loading schema for {dataflow_id}: {e}")
            return None

    def validate_filters(self, filters: Dict[str, Any], dataflow_id: str) -> List[str]:
        """
        Validate filter keys and values against schema and codelists.
        
        Args:
            filters: Dictionary of filters (e.g., {'SEX': 'F', 'REF_AREA': 'AFG'})
            dataflow_id: ID of the dataflow
            
        Returns:
            List of warning messages. Empty list if all valid.
        """
        schema = self.get_schema(dataflow_id)
        if not schema:
            return [f"Schema for {dataflow_id} not found. Cannot validate filters."]
            
        warnings = []
        dimensions = {d['id']: d for d in schema.get('dimensions', [])}
        
        for key, value in filters.items():
            # 1. Check if dimension exists
            if key not in dimensions:
                # Check if it's a time dimension or attribute, which might be valid but not in dimensions list
                if key == schema.get('time_dimension'):
                    continue
                # Attributes are usually not used for filtering in SDMX, but let's check
                is_attribute = any(a['id'] == key for a in schema.get('attributes', []))
                if not is_attribute:
                    warnings.append(f"Filter key '{key}' is not a valid dimension in {dataflow_id}")
                continue
                
            # 2. Check if value is valid (if codelist exists)
            dim_info = dimensions[key]
            codelist_id = dim_info.get('codelist')
            
            if codelist_id:
                codelist = self.get_codelist(codelist_id)
                if codelist and 'codes' in codelist:
                    valid_codes = codelist['codes']
                    
                    # Handle list of values
                    values_to_check = value if isinstance(value, list) else [value]
                    
                    for v in values_to_check:
                        if v not in valid_codes:
                            warnings.append(
                                f"Value '{v}' for filter '{key}' is not in codelist {codelist_id}. "
                                f"Valid codes include: {list(valid_codes.keys())[:5]}..."
                            )
            
        return warnings

    def validate_dataframe(self, df: pd.DataFrame, dataflow_id: str) -> bool:
        """
        Check if DataFrame columns match schema dimensions.
        
        Args:
            df: DataFrame to validate
            dataflow_id: ID of the dataflow
            
        Returns:
            True if valid (or schema not found), False if missing dimensions.
        """
        schema = self.get_schema(dataflow_id)
        if not schema:
            return True # Cannot validate without schema, assume valid
            
        dimensions = [d['id'] for d in schema.get('dimensions', [])]
        
        # Add time dimension
        if schema.get('time_dimension'):
            dimensions.append(schema['time_dimension'])
            
        # Check if all dimensions are present in columns
        # Note: Columns might have been renamed already, so we need to be careful.
        # This assumes raw SDMX output before standardization.
        missing = [d for d in dimensions if d not in df.columns]
        
        if missing:
            logger.warning(f"DataFrame missing expected dimensions for {dataflow_id}: {missing}")
            return False
            
        return True

    def get_column_mapping(self, dataflow_id: str) -> Dict[str, str]:
        """
        Get column renaming map based on schema.
        
        Args:
            dataflow_id: ID of the dataflow
            
        Returns:
            Dictionary mapping SDMX codes to internal names.
        """
        schema = self.get_schema(dataflow_id)
        if not schema:
            return {}
            
        rename_map = {}
        
        # Standard mappings
        for dim in schema.get('dimensions', []):
            dim_id = dim['id']
            if dim_id == 'REF_AREA':
                rename_map['REF_AREA'] = 'iso3'
            elif dim_id == 'COUNTRY':
                # SDG_PROG_ASSESSMENT uses COUNTRY instead of REF_AREA
                rename_map['COUNTRY'] = 'iso3'
            elif dim_id == 'INDICATOR':
                rename_map['INDICATOR'] = 'indicator'
            elif dim_id == 'SEX':
                rename_map['SEX'] = 'sex'
            elif dim_id == 'OBS_VALUE':
                rename_map['OBS_VALUE'] = 'value'
            elif dim_id == 'UNIT_MEASURE':
                rename_map['UNIT_MEASURE'] = 'unit'
            else:
                # For other dimensions, convert to lowercase
                rename_map[dim_id] = dim_id.lower()
                
        if schema.get('time_dimension') == 'TIME_PERIOD':
            rename_map['TIME_PERIOD'] = 'period'
            
        # Attributes
        for attr in schema.get('attributes', []):
            attr_id = attr['id']
            if attr_id == 'UNIT_MEASURE':
                rename_map['UNIT_MEASURE'] = 'unit'
            elif attr_id == 'OBS_STATUS':
                rename_map['OBS_STATUS'] = 'obs_status'
            elif attr_id == 'DATA_SOURCE':
                rename_map['DATA_SOURCE'] = 'data_source'
            else:
                rename_map[attr_id] = attr_id.lower()
                
        return rename_map

    def standardize_dataframe(self, df: pd.DataFrame, dataflow_id: str) -> pd.DataFrame:
        """
        Rename columns to standard names based on schema and apply types.
        
        Args:
            df: DataFrame to standardize
            dataflow_id: ID of the dataflow
            
        Returns:
            Standardized DataFrame
        """
        rename_map = self.get_column_mapping(dataflow_id)
        
        # Apply renaming
        df = df.rename(columns=rename_map)
        
        return df

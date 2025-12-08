"""
Metadata synchronization, validation, and vintage control for UNICEF SDMX API

This module provides functionality to:
1. Sync dataflow and indicator metadata from the UNICEF SDMX API
2. Cache metadata locally as YAML files for offline use
3. Validate downloaded data against cached metadata
4. Track metadata versions (vintages) for reproducibility and auditing
5. Auto-sync on first use with configurable staleness

Usage:
    >>> from unicef_api.metadata import MetadataSync, sync_metadata
    >>> sync = MetadataSync()
    >>> sync.ensure_synced()  # Auto-syncs if needed
    >>> sync.load_indicators(vintage="2025-12-01")  # Use specific vintage
    >>> sync.compare_vintages("2025-11-01", "2025-12-01")  # Detect changes
"""

import os
import yaml
import shutil
import requests
import xml.etree.ElementTree as ET
from pathlib import Path
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
import hashlib

# Package version - used in watermarks
__version__ = "0.2.2"
__sync_version__ = "1.0.0"


@dataclass
class DataflowMetadata:
    """Metadata for a UNICEF SDMX dataflow"""
    id: str
    name: str
    agency: str
    version: str
    description: Optional[str] = None
    dimensions: Optional[List[str]] = None
    indicators: Optional[List[str]] = None
    last_updated: Optional[str] = None


@dataclass 
class IndicatorMetadata:
    """Metadata for a UNICEF indicator"""
    code: str
    name: str
    dataflow: str
    sdg_target: Optional[str] = None
    unit: Optional[str] = None
    description: Optional[str] = None
    dimensions: Optional[List[str]] = None
    source: Optional[str] = None


@dataclass
class CodelistMetadata:
    """Metadata for an SDMX codelist"""
    id: str
    agency: str
    version: str
    codes: Dict[str, str]  # code -> description mapping
    last_updated: Optional[str] = None
    name: Optional[str] = None  # Codelist's descriptive name (e.g., "Statistical Reference Areas")


class MetadataSync:
    """Synchronize and cache UNICEF SDMX metadata with vintage control.
    
    Downloads metadata from UNICEF's SDMX API and stores it as YAML files
    for offline reference, validation, and version tracking. Supports
    multiple vintages for reproducibility and change detection.
    
    Directory Structure:
        metadata/
        ├── current/                          # Latest metadata
        │   ├── _unicefdata_dataflows.yaml
        │   ├── _unicefdata_indicators.yaml
        │   ├── _unicefdata_codelists.yaml
        │   ├── _unicefdata_countries.yaml
        │   └── _unicefdata_regions.yaml
        ├── vintages/
        │   ├── 2025-12-01/                   # Historical snapshots
        │   └── 2025-11-01/
        └── _unicefdata_sync_history.yaml     # Log of all syncs
    
    Example:
        >>> sync = MetadataSync(cache_dir='./metadata')
        >>> sync.ensure_synced()  # Auto-sync if needed
        >>> dataflows = sync.load_dataflows()
        >>> dataflows = sync.load_dataflows(vintage="2025-11-01")  # Specific vintage
        >>> changes = sync.compare_vintages("2025-11-01", "2025-12-01")
    """
    
    BASE_URL = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    AGENCY = "UNICEF"
    DEFAULT_MAX_AGE_DAYS = 30
    METADATA_VERSION = "2.0.0"  # Version for watermark tracking
    
    # Standard file names with _unicefdata_ prefix
    FILE_DATAFLOWS = "_unicefdata_dataflows.yaml"
    FILE_INDICATORS = "_unicefdata_indicators.yaml"
    FILE_CODELISTS = "_unicefdata_codelists.yaml"
    FILE_COUNTRIES = "_unicefdata_countries.yaml"
    FILE_REGIONS = "_unicefdata_regions.yaml"
    FILE_SYNC_HISTORY = "_unicefdata_sync_history.yaml"
    
    # XML namespaces for SDMX parsing
    NAMESPACES = {
        'message': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/message',
        'str': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/structure',
        'com': 'http://www.sdmx.org/resources/sdmxml/schemas/v2_1/common'
    }
    
    def __init__(
        self, 
        cache_dir: Optional[str] = None,
        base_url: Optional[str] = None,
        agency: str = "UNICEF",
        max_age_days: int = 30
    ):
        """Initialize metadata sync with vintage control.
        
        Args:
            cache_dir: Directory for YAML cache files. Defaults to ./metadata/
            base_url: SDMX API base URL. Defaults to UNICEF API.
            agency: SDMX agency identifier. Defaults to 'UNICEF'.
            max_age_days: Days before metadata is considered stale. Default 30.
        """
        if cache_dir is None:
            cache_dir = Path.cwd() / "metadata"
        self.cache_dir = Path(cache_dir)
        self.current_dir = self.cache_dir / "current"
        self.vintages_dir = self.cache_dir / "vintages"
        
        # Create directories
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.current_dir.mkdir(parents=True, exist_ok=True)
        self.vintages_dir.mkdir(parents=True, exist_ok=True)
        
        self.base_url = base_url or self.BASE_URL
        self.agency = agency
        self.max_age_days = max_age_days
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'unicefData/0.2.1 (+https://github.com/unicef-drp/unicefData)'
        })
    
    # -------------------------------------------------------------------------
    # Watermark Generation
    # -------------------------------------------------------------------------
    
    def _create_watermarked_dict(
        self,
        content_type: str,
        source_url: str,
        content: Dict[str, Any],
        counts: Dict[str, Any],
        extra_metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Create a dictionary with standardized watermark header.
        
        All YAML files include a watermark with:
        - platform: Which platform generated the file (Python/R/Stata)
        - version: Metadata schema version
        - synced_at: ISO 8601 timestamp
        - source: API endpoint URL
        - agency: SDMX agency identifier
        - counts: Item counts for quick reference
        - extra_metadata: Optional additional metadata (e.g., codelist_name)
        
        Args:
            content_type: Type of content (dataflows, indicators, etc.)
            source_url: URL(s) used to fetch this data
            content: The actual content dictionary
            counts: Count statistics for the watermark
            extra_metadata: Optional additional metadata fields
            
        Returns:
            Dictionary with _metadata watermark and content
        """
        metadata_dict = {
            'platform': 'python',
            'version': self.METADATA_VERSION,
            'synced_at': datetime.utcnow().isoformat() + 'Z',
            'source': source_url,
            'agency': self.agency,
            'content_type': content_type,
            **counts
        }
        # Add extra metadata fields if provided
        if extra_metadata:
            metadata_dict.update(extra_metadata)
            
        watermark = {'_metadata': metadata_dict}
        # Merge watermark with content
        return {**watermark, **content}
    
    # -------------------------------------------------------------------------
    # Auto-Sync and Staleness
    # -------------------------------------------------------------------------
    
    def ensure_synced(self, max_age_days: Optional[int] = None, verbose: bool = False) -> bool:
        """Ensure metadata is synced, auto-syncing if stale or missing.
        
        Args:
            max_age_days: Override default staleness threshold
            verbose: Print progress messages
            
        Returns:
            True if sync was performed, False if cache was fresh
        """
        if max_age_days is None:
            max_age_days = self.max_age_days
        
        if self._is_stale(max_age_days):
            if verbose:
                print("Syncing UNICEF metadata (one-time setup or refresh)...")
            self.sync_all(verbose=verbose)
            return True
        return False
    
    def _is_stale(self, max_age_days: int) -> bool:
        """Check if cached metadata is stale or missing."""
        history = self._load_sync_history()
        if not history.get('vintages'):
            return True
        
        latest = history['vintages'][0]
        synced_at = latest.get('synced_at')
        if not synced_at:
            return True
        
        try:
            synced_date = datetime.fromisoformat(synced_at.replace('Z', '+00:00'))
            age = datetime.now(timezone.utc) - synced_date
            return age.days > max_age_days
        except (ValueError, TypeError):
            return True
    
    # -------------------------------------------------------------------------
    # Sync Functions with Vintage Support
    # -------------------------------------------------------------------------
    
    def sync_all(self, verbose: bool = True, create_vintage: bool = True) -> Dict[str, Any]:
        """Sync all metadata from UNICEF SDMX API.
        
        Downloads dataflows, codelists, countries, regions, and indicator definitions,
        saves to current/ and optionally creates a dated vintage snapshot.
        
        Args:
            verbose: Print progress messages
            create_vintage: Save a dated snapshot in vintages/
            
        Returns:
            Dictionary with sync summary including counts and timestamps
        """
        vintage_date = datetime.utcnow().strftime('%Y-%m-%d')
        
        results = {
            'synced_at': datetime.utcnow().isoformat() + 'Z',
            'vintage_date': vintage_date,
            'dataflows': 0,
            'codelists': 0,
            'countries': 0,
            'regions': 0,
            'indicators': 0,
            'files_created': [],
            'errors': []
        }
        
        if verbose:
            print("=" * 80)
            print("UNICEF Metadata Sync")
            print("=" * 80)
            print(f"Output location: {self.current_dir}")
            print(f"Timestamp: {results['synced_at']}")
            print("-" * 80)
        
        # 1. Sync dataflows
        try:
            if verbose:
                print("  📁 Fetching dataflows...")
            dataflows = self.sync_dataflows(verbose=False)
            results['dataflows'] = len(dataflows)
            results['files_created'].append(self.FILE_DATAFLOWS)
            if verbose:
                print(f"     ✓ {self.FILE_DATAFLOWS} - {len(dataflows)} dataflows")
        except Exception as e:
            results['errors'].append(f"Dataflows: {str(e)}")
            if verbose:
                print(f"     ✗ Dataflows error: {e}")
        
        # 2. Sync codelists (excluding countries/regions)
        try:
            if verbose:
                print("  📁 Fetching codelists...")
            codelists = self.sync_codelists(verbose=False)
            results['codelists'] = len(codelists)
            results['files_created'].append(self.FILE_CODELISTS)
            if verbose:
                codelist_detail = ", ".join([f"{k}: {len(v.codes)}" for k, v in list(codelists.items())[:3]])
                print(f"     ✓ {self.FILE_CODELISTS} - {len(codelists)} codelists")
                print(f"       • {codelist_detail}...")
        except Exception as e:
            results['errors'].append(f"Codelists: {str(e)}")
            if verbose:
                print(f"     ✗ Codelists error: {e}")
        
        # 3. Sync countries (separate file)
        try:
            if verbose:
                print("  📁 Fetching country codes...")
            countries = self.sync_countries(verbose=False)
            results['countries'] = len(countries)
            results['files_created'].append(self.FILE_COUNTRIES)
            if verbose:
                print(f"     ✓ {self.FILE_COUNTRIES} - {len(countries)} country codes")
        except Exception as e:
            results['errors'].append(f"Countries: {str(e)}")
            if verbose:
                print(f"     ✗ Countries error: {e}")
        
        # 4. Sync regions (separate file)
        try:
            if verbose:
                print("  📁 Fetching regional codes...")
            regions = self.sync_regions(verbose=False)
            results['regions'] = len(regions)
            results['files_created'].append(self.FILE_REGIONS)
            if verbose:
                print(f"     ✓ {self.FILE_REGIONS} - {len(regions)} regional codes")
        except Exception as e:
            results['errors'].append(f"Regions: {str(e)}")
            if verbose:
                print(f"     ✗ Regions error: {e}")
        
        # 5. Generate indicator catalog from config
        try:
            if verbose:
                print("  📁 Building indicator catalog...")
            indicators, indicators_by_dataflow = self.sync_indicators(verbose=False)
            results['indicators'] = len(indicators)
            results['indicators_by_dataflow'] = {k: len(v) for k, v in indicators_by_dataflow.items()}
            results['files_created'].append(self.FILE_INDICATORS)
            if verbose:
                print(f"     ✓ {self.FILE_INDICATORS} - {len(indicators)} indicators")
                for df, count in list(indicators_by_dataflow.items())[:5]:
                    print(f"       • {df}: {count} indicators")
                if len(indicators_by_dataflow) > 5:
                    print(f"       • ... and {len(indicators_by_dataflow) - 5} more dataflows")
        except Exception as e:
            results['errors'].append(f"Indicators: {str(e)}")
            if verbose:
                print(f"     ✗ Indicators error: {e}")
        
        # 6. Create vintage snapshot
        if create_vintage:
            self._create_vintage(vintage_date, results)
        
        # 7. Update sync history
        self._update_sync_history(results)
        results['files_created'].append(self.FILE_SYNC_HISTORY)
        
        # Summary
        if verbose:
            print("-" * 80)
            print("Summary:")
            print(f"  Total files created: {len(results['files_created'])}")
            print(f"  - Dataflows:   {results['dataflows']}")
            print(f"  - Indicators:  {results['indicators']}")
            print(f"  - Codelists:   {results['codelists']}")
            print(f"  - Countries:   {results['countries']}")
            print(f"  - Regions:     {results['regions']}")
            if results['errors']:
                print(f"  ⚠️  Errors: {len(results['errors'])}")
                for err in results['errors']:
                    print(f"     - {err}")
            print(f"  Vintage: {vintage_date}")
            print("=" * 80)
        
        return results
    
    def sync_dataflows(self, verbose: bool = True) -> Dict[str, DataflowMetadata]:
        """Sync dataflow definitions from SDMX API."""
        if verbose:
            print("  Fetching dataflows...")
        
        url = f"{self.base_url}/dataflow/{self.agency}?references=none&detail=full"
        response = self._fetch_xml(url)
        
        dataflows = {}
        doc = ET.fromstring(response)
        
        for df in doc.findall('.//str:Dataflow', self.NAMESPACES):
            df_id = df.get('id')
            agency = df.get('agencyID', self.agency)
            version = df.get('version', '1.0')
            
            name_elem = df.find('.//com:Name', self.NAMESPACES)
            name = name_elem.text if name_elem is not None else df_id
            
            desc_elem = df.find('.//com:Description', self.NAMESPACES)
            description = desc_elem.text if desc_elem is not None else None
            
            dataflows[df_id] = DataflowMetadata(
                id=df_id,
                name=name,
                agency=agency,
                version=version,
                description=description,
                last_updated=datetime.utcnow().isoformat() + 'Z'
            )
        
        # Save to current/ with watermark
        dataflows_dict = self._create_watermarked_dict(
            content_type='dataflows',
            source_url=url,
            content={'dataflows': {k: asdict(v) for k, v in dataflows.items()}},
            counts={'total_dataflows': len(dataflows)}
        )
        self._save_yaml(self.FILE_DATAFLOWS, dataflows_dict)
        
        if verbose:
            print(f"    Found {len(dataflows)} dataflows")
        
        return dataflows
    
    def sync_codelists(
        self, 
        codelist_ids: Optional[List[str]] = None,
        verbose: bool = True
    ) -> Dict[str, CodelistMetadata]:
        """Sync codelist definitions from SDMX API (excluding countries/regions)."""
        if codelist_ids is None:
            # Codelists excluding CL_REF_AREA (countries/regions handled separately)
            # Note: CL_SEX does not exist on UNICEF SDMX API
            codelist_ids = [
                'CL_AGE',
                'CL_WEALTH_QUINTILE',
                'CL_RESIDENCE',
                'CL_UNIT_MEASURE',
                'CL_OBS_STATUS',
            ]
        
        if verbose:
            print("  Fetching codelists...")
        
        codelists = {}
        for cl_id in codelist_ids:
            try:
                cl = self._fetch_codelist(cl_id)
                if cl:
                    codelists[cl_id] = cl
            except Exception as e:
                if verbose:
                    print(f"    ⚠️  Could not fetch {cl_id}: {e}")
        
        # Save with watermark
        codelists_dict = self._create_watermarked_dict(
            content_type='codelists',
            source_url=f"{self.base_url}/codelist/{self.agency}",
            content={'codelists': {k: asdict(v) for k, v in codelists.items()}},
            counts={
                'total_codelists': len(codelists),
                'codes_per_list': {k: len(v.codes) for k, v in codelists.items()}
            }
        )
        self._save_yaml(self.FILE_CODELISTS, codelists_dict)
        
        if verbose:
            print(f"    Found {len(codelists)} codelists")
        
        return codelists
    
    def sync_countries(self, verbose: bool = True) -> Dict[str, str]:
        """Sync country codes from CL_COUNTRY."""
        if verbose:
            print("  Fetching country codes...")
        
        cl = self._fetch_codelist('CL_COUNTRY')
        
        countries = {}
        codelist_name = None
        if cl:
            countries = cl.codes
            codelist_name = cl.name
        
        # Save countries with watermark (codelist_name stored in metadata)
        countries_dict = self._create_watermarked_dict(
            content_type='countries',
            source_url=f"{self.base_url}/codelist/{self.agency}/CL_COUNTRY/latest",
            content={'countries': countries},
            counts={'total_countries': len(countries)},
            extra_metadata={'codelist_id': 'CL_COUNTRY', 'codelist_name': codelist_name}
        )
        self._save_yaml(self.FILE_COUNTRIES, countries_dict)
        
        if verbose:
            print(f"    Found {len(countries)} country codes")
        
        return countries
    
    def sync_regions(self, verbose: bool = True) -> Dict[str, str]:
        """Sync regional/aggregate codes from CL_WORLD_REGIONS."""
        if verbose:
            print("  Fetching regional codes...")
        
        cl = self._fetch_codelist('CL_WORLD_REGIONS')
        
        regions = {}
        codelist_name = None
        if cl:
            regions = cl.codes
            codelist_name = cl.name
        
        # Save regions with watermark (codelist_name stored in metadata)
        regions_dict = self._create_watermarked_dict(
            content_type='regions',
            source_url=f"{self.base_url}/codelist/{self.agency}/CL_WORLD_REGIONS/latest",
            content={'regions': regions},
            counts={'total_regions': len(regions)},
            extra_metadata={'codelist_id': 'CL_WORLD_REGIONS', 'codelist_name': codelist_name}
        )
        self._save_yaml(self.FILE_REGIONS, regions_dict)
        
        if verbose:
            print(f"    Found {len(regions)} regional codes")
        
        return regions
    
    def sync_indicators(self, verbose: bool = True) -> Tuple[Dict[str, IndicatorMetadata], Dict[str, List[str]]]:
        """Sync indicator catalog from config and API.
        
        Returns:
            Tuple of (indicators dict, indicators_by_dataflow dict)
        """
        if verbose:
            print("  Building indicator catalog from shared config...")
        
        # Try to load from shared config file (same as R)
        try:
            from unicef_api.config_loader import load_shared_indicators
            COMMON_INDICATORS = load_shared_indicators()
        except (ImportError, FileNotFoundError):
            # Fall back to hardcoded config
            try:
                from unicef_api.config import COMMON_INDICATORS
            except ImportError:
                COMMON_INDICATORS = {}
        
        indicators = {}
        indicators_by_dataflow = {}
        
        for code, info in COMMON_INDICATORS.items():
            sdg_target = info.get('sdg')
            dataflow = info.get('dataflow', 'GLOBAL_DATAFLOW')
            
            indicators[code] = IndicatorMetadata(
                code=code,
                name=info.get('name', code),
                dataflow=dataflow,
                sdg_target=sdg_target,
                unit=info.get('unit'),
                description=info.get('description'),
                source='config'
            )
            
            # Track by dataflow
            if dataflow not in indicators_by_dataflow:
                indicators_by_dataflow[dataflow] = []
            indicators_by_dataflow[dataflow].append(code)
        
        # Save with watermark
        indicators_dict = self._create_watermarked_dict(
            content_type='indicators',
            source_url='unicef_api.config + SDMX API',
            content={'indicators': {k: asdict(v) for k, v in indicators.items()}},
            counts={
                'total_indicators': len(indicators),
                'dataflows_covered': len(indicators_by_dataflow),
                'indicators_per_dataflow': {k: len(v) for k, v in indicators_by_dataflow.items()}
            }
        )
        self._save_yaml(self.FILE_INDICATORS, indicators_dict)
        
        if verbose:
            print(f"    Cataloged {len(indicators)} indicators")
        
        return indicators, indicators_by_dataflow
    
    # -------------------------------------------------------------------------
    # Vintage Management
    # -------------------------------------------------------------------------
    
    def _create_vintage(self, vintage_date: str, results: Dict[str, Any]) -> Path:
        """Create a dated vintage snapshot of current metadata."""
        vintage_path = self.vintages_dir / vintage_date
        
        # If vintage already exists today, skip (don't overwrite)
        if vintage_path.exists():
            return vintage_path
        
        vintage_path.mkdir(parents=True, exist_ok=True)
        
        # Copy current files to vintage (using new naming convention)
        vintage_files = [
            self.FILE_DATAFLOWS,
            self.FILE_INDICATORS,
            self.FILE_CODELISTS,
            self.FILE_COUNTRIES,
            self.FILE_REGIONS,
        ]
        for filename in vintage_files:
            src = self.current_dir / filename
            if src.exists():
                shutil.copy2(src, vintage_path / filename)
        
        # Save vintage summary
        vintage_summary = {
            'vintage_date': vintage_date,
            'synced_at': results['synced_at'],
            'dataflows': results['dataflows'],
            'indicators': results['indicators'],
            'codelists': results['codelists'],
            'countries': results.get('countries', 0),
            'regions': results.get('regions', 0),
        }
        with open(vintage_path / 'summary.yaml', 'w') as f:
            yaml.dump(vintage_summary, f, default_flow_style=False)
        
        return vintage_path
    
    def list_vintages(self) -> List[str]:
        """List all available vintage dates, newest first.
        
        Returns:
            List of vintage date strings (e.g., ['2025-12-01', '2025-11-01'])
        """
        vintages = []
        if self.vintages_dir.exists():
            for d in self.vintages_dir.iterdir():
                # Check for new naming convention first, then legacy
                has_new_format = (d / self.FILE_DATAFLOWS).exists()
                has_legacy = (d / 'dataflows.yaml').exists()
                if d.is_dir() and (has_new_format or has_legacy):
                    vintages.append(d.name)
        return sorted(vintages, reverse=True)
    
    def get_vintage_path(self, vintage: Optional[str] = None) -> Path:
        """Get path to vintage directory.
        
        Args:
            vintage: Date string (e.g., '2025-12-01') or None for current
            
        Returns:
            Path to metadata directory
        """
        if vintage is None:
            return self.current_dir
        
        vintage_path = self.vintages_dir / vintage
        if not vintage_path.exists():
            available = self.list_vintages()
            raise ValueError(
                f"Vintage '{vintage}' not found. Available: {available[:5]}"
            )
        return vintage_path
    
    def compare_vintages(
        self, 
        vintage1: str, 
        vintage2: Optional[str] = None
    ) -> Dict[str, Any]:
        """Compare two vintages to detect changes.
        
        Args:
            vintage1: Earlier vintage date (e.g., '2025-11-01')
            vintage2: Later vintage date (default: current)
            
        Returns:
            Dictionary with added/removed/changed items
        """
        path1 = self.get_vintage_path(vintage1)
        path2 = self.get_vintage_path(vintage2)
        
        changes = {
            'vintage1': vintage1,
            'vintage2': vintage2 or 'current',
            'dataflows': {'added': [], 'removed': [], 'changed': []},
            'indicators': {'added': [], 'removed': [], 'changed': []},
        }
        
        # Compare dataflows
        df1 = self._load_yaml_from_path(path1 / 'dataflows.yaml')
        df2 = self._load_yaml_from_path(path2 / 'dataflows.yaml')
        
        flows1 = set(df1.get('dataflows', {}).keys())
        flows2 = set(df2.get('dataflows', {}).keys())
        
        changes['dataflows']['added'] = list(flows2 - flows1)
        changes['dataflows']['removed'] = list(flows1 - flows2)
        
        # Compare indicators
        ind1 = self._load_yaml_from_path(path1 / 'indicators.yaml')
        ind2 = self._load_yaml_from_path(path2 / 'indicators.yaml')
        
        inds1 = set(ind1.get('indicators', {}).keys())
        inds2 = set(ind2.get('indicators', {}).keys())
        
        changes['indicators']['added'] = list(inds2 - inds1)
        changes['indicators']['removed'] = list(inds1 - inds2)
        
        return changes
    
    # -------------------------------------------------------------------------
    # Load Functions with Vintage Support
    # -------------------------------------------------------------------------
    
    def load_dataflows(self, vintage: Optional[str] = None) -> Dict[str, Any]:
        """Load cached dataflow metadata from YAML.
        
        Args:
            vintage: Vintage date string (e.g., '2025-12-01') or None for current
        """
        path = self.get_vintage_path(vintage)
        return self._load_yaml_from_path(path / 'dataflows.yaml')
    
    def load_codelists(self, vintage: Optional[str] = None) -> Dict[str, Any]:
        """Load cached codelist metadata from YAML."""
        path = self.get_vintage_path(vintage)
        return self._load_yaml_from_path(path / 'codelists.yaml')
    
    def load_indicators(self, vintage: Optional[str] = None) -> Dict[str, Any]:
        """Load cached indicator metadata from YAML."""
        path = self.get_vintage_path(vintage)
        return self._load_yaml_from_path(path / 'indicators.yaml')
    
    def load_sync_summary(self) -> Dict[str, Any]:
        """Load last sync summary (from history)."""
        history = self._load_sync_history()
        if history.get('vintages'):
            return history['vintages'][0]
        return {}
    
    def get_dataflow(self, dataflow_id: str, vintage: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Get metadata for a specific dataflow."""
        dataflows = self.load_dataflows(vintage=vintage)
        return dataflows.get('dataflows', {}).get(dataflow_id)
    
    def get_indicator(self, indicator_code: str, vintage: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Get metadata for a specific indicator."""
        indicators = self.load_indicators(vintage=vintage)
        return indicators.get('indicators', {}).get(indicator_code)
    
    def get_codelist(self, codelist_id: str, vintage: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Get metadata for a specific codelist."""
        codelists = self.load_codelists(vintage=vintage)
        return codelists.get('codelists', {}).get(codelist_id)
    
    # -------------------------------------------------------------------------
    # Validation Functions
    # -------------------------------------------------------------------------
    
    def validate_dataframe(
        self, 
        df, 
        indicator_code: str,
        strict: bool = False,
        vintage: Optional[str] = None
    ) -> Tuple[bool, List[str]]:
        """Validate a DataFrame against cached metadata.
        
        Args:
            df: pandas DataFrame to validate
            indicator_code: Expected indicator code
            strict: If True, fail on any warning
            vintage: Use specific vintage for validation
            
        Returns:
            Tuple of (is_valid, list of issues)
        """
        issues = []
        
        # Ensure metadata exists
        self.ensure_synced(verbose=False)
        
        # Check indicator exists
        indicator = self.get_indicator(indicator_code, vintage=vintage)
        if indicator is None:
            issues.append(f"Indicator '{indicator_code}' not found in catalog")
        
        # Check required columns
        required_cols = ['REF_AREA', 'TIME_PERIOD', 'OBS_VALUE']
        for col in required_cols:
            if col not in df.columns:
                issues.append(f"Missing required column: {col}")
        
        # Validate country codes if codelist available
        codelists = self.load_codelists(vintage=vintage)
        ref_area_codes = codelists.get('codelists', {}).get('CL_REF_AREA', {}).get('codes', {})
        if ref_area_codes and 'REF_AREA' in df.columns:
            invalid_countries = set(df['REF_AREA'].unique()) - set(ref_area_codes.keys())
            if invalid_countries:
                issues.append(f"Invalid country codes: {list(invalid_countries)[:5]}...")
        
        # Check for empty data
        if len(df) == 0:
            issues.append("DataFrame is empty")
        
        # Check for null values in key columns
        if 'OBS_VALUE' in df.columns:
            null_pct = df['OBS_VALUE'].isna().mean() * 100
            if null_pct > 50:
                issues.append(f"High null rate in OBS_VALUE: {null_pct:.1f}%")
        
        is_valid = len(issues) == 0 if strict else not any('Missing' in i for i in issues)
        return is_valid, issues
    
    def compute_data_hash(self, df) -> str:
        """Compute hash of DataFrame for version tracking."""
        df_sorted = df.sort_values(by=list(df.columns)).reset_index(drop=True)
        content = df_sorted.to_csv(index=False)
        return hashlib.sha256(content.encode()).hexdigest()[:16]
    
    def create_data_version(
        self,
        df,
        indicator_code: str,
        version_id: Optional[str] = None,
        notes: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create version record for a downloaded dataset."""
        version = {
            'version_id': version_id or datetime.utcnow().strftime('v%Y%m%d_%H%M%S'),
            'created_at': datetime.utcnow().isoformat() + 'Z',
            'indicator_code': indicator_code,
            'data_hash': self.compute_data_hash(df),
            'row_count': len(df),
            'column_count': len(df.columns),
            'columns': list(df.columns),
            'notes': notes
        }
        
        if 'REF_AREA' in df.columns:
            version['unique_countries'] = df['REF_AREA'].nunique()
        if 'TIME_PERIOD' in df.columns:
            version['year_range'] = [
                int(df['TIME_PERIOD'].min()),
                int(df['TIME_PERIOD'].max())
            ]
        if 'OBS_VALUE' in df.columns:
            version['value_range'] = [
                float(df['OBS_VALUE'].min()),
                float(df['OBS_VALUE'].max())
            ]
        
        return version
    
    # -------------------------------------------------------------------------
    # Sync History
    # -------------------------------------------------------------------------
    
    def _load_sync_history(self) -> Dict[str, Any]:
        """Load sync history from YAML."""
        filepath = self.cache_dir / self.FILE_SYNC_HISTORY
        if not filepath.exists():
            return {'vintages': []}
        with open(filepath, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f) or {'vintages': []}
    
    def _update_sync_history(self, results: Dict[str, Any]) -> None:
        """Update sync history with new sync results."""
        history = self._load_sync_history()
        
        entry = {
            'vintage_date': results.get('vintage_date'),
            'synced_at': results.get('synced_at'),
            'dataflows': results.get('dataflows', 0),
            'indicators': results.get('indicators', 0),
            'codelists': results.get('codelists', 0),
            'countries': results.get('countries', 0),
            'regions': results.get('regions', 0),
            'errors': results.get('errors', []),
        }
        
        # Add to front of list
        history['vintages'].insert(0, entry)
        
        # Keep only last 50 entries
        history['vintages'] = history['vintages'][:50]
        
        filepath = self.cache_dir / self.FILE_SYNC_HISTORY
        with open(filepath, 'w', encoding='utf-8') as f:
            yaml.dump(history, f, default_flow_style=False, allow_unicode=True)
    
    # -------------------------------------------------------------------------
    # Private Helpers
    # -------------------------------------------------------------------------
    
    def _fetch_xml(self, url: str, retries: int = 3) -> str:
        """Fetch XML from URL with retries."""
        for attempt in range(retries):
            try:
                response = self.session.get(url, timeout=30)
                response.raise_for_status()
                return response.text
            except requests.RequestException as e:
                if attempt == retries - 1:
                    raise
                import time
                time.sleep(2 ** attempt)
        return ""
    
    def _fetch_codelist(self, codelist_id: str) -> Optional[CodelistMetadata]:
        """Fetch a single codelist from the API."""
        url = f"{self.base_url}/codelist/{self.agency}/{codelist_id}/latest"
        
        try:
            response = self._fetch_xml(url)
            doc = ET.fromstring(response)
            
            # Extract codelist's own name (from Codelist element, not Code elements)
            codelist_name = None
            codelist_elem = doc.find('.//str:Codelist', self.NAMESPACES)
            if codelist_elem is not None:
                name_elem = codelist_elem.find('com:Name', self.NAMESPACES)
                if name_elem is not None:
                    codelist_name = name_elem.text
            
            codes = {}
            for code_elem in doc.findall('.//str:Code', self.NAMESPACES):
                code_id = code_elem.get('id')
                name_elem = code_elem.find('.//com:Name', self.NAMESPACES)
                name = name_elem.text if name_elem is not None else code_id
                codes[code_id] = name
            
            return CodelistMetadata(
                id=codelist_id,
                agency=self.agency,
                version='latest',
                codes=codes,
                last_updated=datetime.utcnow().isoformat() + 'Z',
                name=codelist_name  # Codelist's own descriptive name
            )
        except Exception:
            return None
    
    def _save_yaml(self, filename: str, data: Dict[str, Any]) -> Path:
        """Save dictionary to YAML file in current/."""
        filepath = self.current_dir / filename
        with open(filepath, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        return filepath
    
    def _load_yaml(self, filename: str) -> Dict[str, Any]:
        """Load dictionary from YAML file in current/."""
        return self._load_yaml_from_path(self.current_dir / filename)
    
    def _load_yaml_from_path(self, filepath: Path) -> Dict[str, Any]:
        """Load dictionary from YAML file at given path."""
        if not filepath.exists():
            return {}
        with open(filepath, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f) or {}


# =============================================================================
# Convenience Functions
# =============================================================================

def sync_metadata(
    cache_dir: Optional[str] = None, 
    verbose: bool = True,
    max_age_days: int = 30,
    force: bool = False
) -> Dict[str, Any]:
    """Sync all UNICEF metadata to local YAML files.
    
    Args:
        cache_dir: Directory for cache files (default: ./metadata/)
        verbose: Print progress messages
        max_age_days: Days before auto-refresh (default: 30)
        force: Force sync even if cache is fresh
        
    Returns:
        Sync summary dictionary
        
    Example:
        >>> from unicef_api.metadata import sync_metadata
        >>> sync_metadata('./my_cache/')
        >>> sync_metadata(force=True)  # Force refresh
    """
    sync = MetadataSync(cache_dir=cache_dir, max_age_days=max_age_days)
    
    if force or sync._is_stale(max_age_days):
        return sync.sync_all(verbose=verbose)
    else:
        if verbose:
            print(f"Metadata is fresh (synced within {max_age_days} days). Use force=True to refresh.")
        return sync.load_sync_summary()


def ensure_metadata(cache_dir: Optional[str] = None, max_age_days: int = 30) -> MetadataSync:
    """Ensure metadata exists and is fresh, syncing if needed.
    
    This is the recommended way to get a MetadataSync instance for use.
    
    Args:
        cache_dir: Directory for cache files
        max_age_days: Days before auto-refresh
        
    Returns:
        MetadataSync instance with fresh metadata
    """
    sync = MetadataSync(cache_dir=cache_dir, max_age_days=max_age_days)
    sync.ensure_synced(verbose=False)
    return sync


def validate_indicator_data(
    df,
    indicator_code: str,
    cache_dir: Optional[str] = None,
    vintage: Optional[str] = None
) -> Tuple[bool, List[str]]:
    """Validate DataFrame against cached metadata.
    
    Args:
        df: pandas DataFrame to validate
        indicator_code: Expected indicator code
        cache_dir: Metadata cache directory
        vintage: Use specific vintage for validation
        
    Returns:
        Tuple of (is_valid, list of issues)
    """
    sync = MetadataSync(cache_dir=cache_dir)
    return sync.validate_dataframe(df, indicator_code, vintage=vintage)


def list_vintages(cache_dir: Optional[str] = None) -> List[str]:
    """List all available metadata vintages.
    
    Args:
        cache_dir: Metadata cache directory
        
    Returns:
        List of vintage date strings, newest first
    """
    sync = MetadataSync(cache_dir=cache_dir)
    return sync.list_vintages()


def compare_vintages(
    vintage1: str,
    vintage2: Optional[str] = None,
    cache_dir: Optional[str] = None
) -> Dict[str, Any]:
    """Compare two metadata vintages to detect changes.
    
    Args:
        vintage1: Earlier vintage date
        vintage2: Later vintage date (default: current)
        cache_dir: Metadata cache directory
        
    Returns:
        Dictionary with added/removed/changed items
    """
    sync = MetadataSync(cache_dir=cache_dir)
    return sync.compare_vintages(vintage1, vintage2)

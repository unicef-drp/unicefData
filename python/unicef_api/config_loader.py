"""
Shared Configuration Loader
============================

Loads indicator and dataflow configurations from the shared YAML config file.
This ensures R and Python packages use identical indicator definitions.
"""

import os
import yaml
from pathlib import Path
from typing import Dict, Any, Optional, List


def get_shared_indicators_path() -> Path:
    """Get path to the shared common_indicators.yaml config file.
    
    Searches in order:
    1. UNICEF_SHARED_CONFIG_PATH environment variable
    2. ../../config/common_indicators.yaml relative to this file
    3. ./config/common_indicators.yaml relative to current working directory
    
    Returns:
        Path to common_indicators.yaml
        
    Raises:
        FileNotFoundError: If config file not found
    """
    # Check environment variable first
    env_path = os.environ.get('UNICEF_SHARED_CONFIG_PATH')
    if env_path:
        path = Path(env_path)
        if path.exists():
            return path
    
    # Check relative to this module
    module_dir = Path(__file__).parent
    relative_path = module_dir.parent.parent / 'config' / 'common_indicators.yaml'
    if relative_path.exists():
        return relative_path
    
    # Check relative to cwd
    cwd_path = Path.cwd() / 'config' / 'common_indicators.yaml'
    if cwd_path.exists():
        return cwd_path
    
    raise FileNotFoundError(
        "Could not find common_indicators.yaml config file. "
        "Set UNICEF_SHARED_CONFIG_PATH environment variable or ensure config/common_indicators.yaml exists."
    )


def load_shared_indicators() -> Dict[str, Dict[str, Any]]:
    """Load indicator definitions from shared common_indicators.yaml.
    
    This ensures Python, R, and Stata use identical indicator definitions.
    
    Returns dictionary compatible with COMMON_INDICATORS format:
    {
        "CME_MRY0T4": {
            "code": "CME_MRY0T4",
            "name": "Under-5 mortality rate",
            "dataflow": "CME",
            "sdg": "3.2.1",
            "unit": "Deaths per 1,000 live births",
        },
        ...
    }
    """
    config_path = get_shared_indicators_path()
    
    with open(config_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    
    indicators = config.get('COMMON_INDICATORS', {})
    
    # Transform to match expected format (rename sdg_target to sdg if needed)
    result = {}
    for code, info in indicators.items():
        result[code] = {
            'code': info.get('code', code),
            'name': info.get('name', code),
            'dataflow': info.get('dataflow'),
            'sdg': info.get('sdg'),  # Already named 'sdg' in common_indicators.yaml
            'unit': info.get('unit'),
            'description': info.get('description'),
        }
    
    return result


def get_config_path() -> Path:
    """Get path to the shared indicators.yaml config file.
    
    Searches in order:
    1. UNICEF_CONFIG_PATH environment variable
    2. ../../config/indicators.yaml relative to this file
    3. ./config/indicators.yaml relative to current working directory
    
    Returns:
        Path to indicators.yaml
        
    Raises:
        FileNotFoundError: If config file not found
    """
    # Check environment variable first
    env_path = os.environ.get('UNICEF_CONFIG_PATH')
    if env_path:
        path = Path(env_path)
        if path.exists():
            return path
    
    # Check relative to this module
    module_dir = Path(__file__).parent
    relative_path = module_dir.parent.parent / 'config' / 'indicators.yaml'
    if relative_path.exists():
        return relative_path
    
    # Check relative to cwd
    cwd_path = Path.cwd() / 'config' / 'indicators.yaml'
    if cwd_path.exists():
        return cwd_path
    
    raise FileNotFoundError(
        "Could not find indicators.yaml config file. "
        "Set UNICEF_CONFIG_PATH environment variable or ensure config/indicators.yaml exists."
    )


def load_config(config_path: Optional[Path] = None) -> Dict[str, Any]:
    """Load the full configuration from YAML.
    
    Args:
        config_path: Optional explicit path to config file
        
    Returns:
        Full configuration dictionary
    """
    if config_path is None:
        config_path = get_config_path()
    
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def load_indicators(config_path: Optional[Path] = None) -> Dict[str, Dict[str, Any]]:
    """Load indicator definitions from shared config.
    
    Returns dictionary compatible with COMMON_INDICATORS format:
    {
        "CME_MRY0T4": {
            "code": "CME_MRY0T4",
            "name": "Under-5 mortality rate",
            "dataflow": "CME",
            "sdg": "3.2.1",
            "unit": "Deaths per 1,000 live births",
        },
        ...
    }
    """
    config = load_config(config_path)
    indicators = config.get('indicators', {})
    
    # Transform to COMMON_INDICATORS format (rename sdg_target to sdg)
    result = {}
    for code, info in indicators.items():
        result[code] = {
            'code': info.get('code', code),
            'name': info.get('name', code),
            'dataflow': info.get('dataflow'),
            'sdg': info.get('sdg_target'),  # Rename for compatibility
            'unit': info.get('unit'),
            'category': info.get('category'),
            'description': info.get('description'),
        }
    
    return result


def load_dataflows(config_path: Optional[Path] = None) -> Dict[str, Dict[str, Any]]:
    """Load dataflow definitions from shared config."""
    config = load_config(config_path)
    return config.get('dataflows', {})


def load_categories(config_path: Optional[Path] = None) -> Dict[str, Dict[str, Any]]:
    """Load category definitions from shared config."""
    config = load_config(config_path)
    return config.get('categories', {})


def get_indicators_by_category(
    category: str, 
    config_path: Optional[Path] = None
) -> List[str]:
    """Get list of indicator codes for a given category.
    
    Args:
        category: Category name (e.g., 'mortality', 'nutrition')
        
    Returns:
        List of indicator codes in that category
    """
    config = load_config(config_path)
    indicators = config.get('indicators', {})
    
    return [
        code for code, info in indicators.items()
        if info.get('category') == category
    ]


def get_indicators_by_sdg(
    sdg_goal: str,
    config_path: Optional[Path] = None
) -> List[str]:
    """Get list of indicator codes for a given SDG goal.
    
    Args:
        sdg_goal: SDG goal number (e.g., '3', '4')
        
    Returns:
        List of indicator codes for that SDG
    """
    config = load_config(config_path)
    indicators = config.get('indicators', {})
    
    return [
        code for code, info in indicators.items()
        if info.get('sdg_target', '').startswith(f"{sdg_goal}.")
    ]


def get_indicators_by_dataflow(
    dataflow: str,
    config_path: Optional[Path] = None
) -> List[str]:
    """Get list of indicator codes for a given dataflow.
    
    Args:
        dataflow: Dataflow name (e.g., 'CME', 'NUTRITION')
        
    Returns:
        List of indicator codes in that dataflow
    """
    config = load_config(config_path)
    indicators = config.get('indicators', {})
    
    return [
        code for code, info in indicators.items()
        if info.get('dataflow') == dataflow
    ]


# Module-level cached config
_cached_config = None


def get_cached_config(config_path: Optional[Path] = None) -> Dict[str, Any]:
    """Get cached configuration (loads once, reuses thereafter)."""
    global _cached_config
    if _cached_config is None:
        _cached_config = load_config(config_path)
    return _cached_config


def clear_config_cache():
    """Clear the cached configuration."""
    global _cached_config
    _cached_config = None

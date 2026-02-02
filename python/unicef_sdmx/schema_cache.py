"""
Schema Caching System for UNICEF SDMX API
==========================================

Implements in-memory caching of SDMX metadata schemas to reduce API calls
and improve performance during interactive analysis sessions.

Features:
---------
1. Session-level schema cache to avoid redundant API calls
2. LRU cache with size limits
3. Automatic expiry based on age
4. Cache statistics and monitoring
5. Programmatic cache invalidation

Usage:
------
    from unicef_sdmx.schema_cache import SchemaCacheManager
    
    cache = SchemaCacheManager(max_size_mb=100, max_age_hours=24)
    
    # Manual operations
    cache.info()
    cache.clear()
    
    # Automatic caching (via get_sdmx)
    df = get_sdmx(indicator="SP.POP.TOTL", cache=True)
"""

import json
import time
from datetime import datetime, timedelta
from functools import wraps
from typing import Any, Callable, Dict, Optional, Tuple
import hashlib


class SchemaCacheManager:
    """
    Manages in-memory caching of SDMX schemas with size and age limits.
    
    Parameters
    ----------
    max_size_mb : int, default=100
        Maximum total cache size in MB. When exceeded, least-recently-used items
        are evicted.
    max_age_hours : float, default=24
        Maximum age of cached items in hours. Older items are automatically
        removed.
    """
    
    def __init__(self, max_size_mb: int = 100, max_age_hours: float = 24):
        self.max_size_bytes = max_size_mb * 1024 * 1024
        self.max_age_seconds = max_age_hours * 3600
        self._cache: Dict[str, Dict[str, Any]] = {}
        self._access_times: Dict[str, float] = {}
        self._sizes: Dict[str, int] = {}
        self._current_size = 0
    
    def _compute_hash(self, *args, **kwargs) -> str:
        """Compute hash of arguments for cache key."""
        key_str = json.dumps((args, kwargs), sort_keys=True, default=str)
        return hashlib.sha256(key_str.encode()).hexdigest()[:16]
    
    def _estimate_size(self, obj: Any) -> int:
        """Estimate object size in bytes."""
        if isinstance(obj, dict):
            return sum(len(str(k)) + self._estimate_size(v) for k, v in obj.items())
        elif isinstance(obj, list):
            return sum(self._estimate_size(item) for item in obj)
        else:
            return len(str(obj).encode())
    
    def _evict_lru(self, needed_size: int) -> None:
        """Evict least-recently-used items to make space."""
        while self._current_size + needed_size > self.max_size_bytes and self._cache:
            # Find least recently used key
            lru_key = min(self._access_times, key=self._access_times.get)
            self._current_size -= self._sizes.pop(lru_key, 0)
            del self._cache[lru_key]
            del self._access_times[lru_key]
    
    def _remove_expired(self) -> None:
        """Remove expired cache entries."""
        now = time.time()
        expired_keys = [
            key for key, cached_time in self._access_times.items()
            if now - cached_time > self.max_age_seconds
        ]
        for key in expired_keys:
            self._current_size -= self._sizes.pop(key, 0)
            del self._cache[key]
            del self._access_times[key]
    
    def get(self, key: str) -> Optional[Any]:
        """
        Retrieve item from cache.
        
        Parameters
        ----------
        key : str
            Cache key
            
        Returns
        -------
        Cached object if found and not expired, None otherwise
        """
        self._remove_expired()
        
        if key not in self._cache:
            return None
        
        self._access_times[key] = time.time()
        return self._cache[key]
    
    def set(self, key: str, value: Any) -> None:
        """
        Store item in cache.
        
        Parameters
        ----------
        key : str
            Cache key
        value : Any
            Value to cache
        """
        self._remove_expired()
        
        value_size = self._estimate_size(value)
        
        # Evict if necessary
        if value_size > self.max_size_bytes * 0.9:  # Don't cache items >90% of total size
            return
        
        self._evict_lru(value_size)
        
        # Remove old value if exists
        if key in self._cache:
            self._current_size -= self._sizes[key]
        
        # Store new value
        self._cache[key] = value
        self._sizes[key] = value_size
        self._access_times[key] = time.time()
        self._current_size += value_size
    
    def clear(self) -> None:
        """Clear all cached items."""
        self._cache.clear()
        self._access_times.clear()
        self._sizes.clear()
        self._current_size = 0
        print("✓ Schema cache cleared")
    
    def info(self) -> Dict[str, Any]:
        """
        Get cache statistics.
        
        Returns
        -------
        dict
            Cache information including item count and total size
        """
        self._remove_expired()
        
        num_items = len(self._cache)
        size_mb = self._current_size / 1024 / 1024
        
        print(f"Cache: {num_items} items ({size_mb:.2f} MB / {self.max_size_bytes / 1024 / 1024:.0f} MB max)")
        
        if num_items > 0:
            items_info = [
                (key, self._sizes[key] / 1024, self._access_times[key])
                for key in sorted(self._cache.keys())
            ]
            for key, size_kb, access_time in items_info:
                age = datetime.fromtimestamp(access_time)
                print(f"  • {key}: {size_kb:.1f} KB (last: {age.strftime('%H:%M:%S')})")
        
        return {
            "num_items": num_items,
            "total_size_mb": size_mb,
            "max_size_mb": self.max_size_bytes / 1024 / 1024,
            "utilization": num_items / (self.max_size_bytes / 1024 / 1024 * 100) if num_items > 0 else 0
        }
    
    def cache_function(self, func: Callable) -> Callable:
        """
        Decorator to cache function results.
        
        Parameters
        ----------
        func : callable
            Function to cache
            
        Returns
        -------
        callable
            Wrapped function with caching
            
        Example
        -------
        @cache.cache_function
        def expensive_function(a, b):
            return a + b
        """
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Compute cache key
            key_str = json.dumps((args, kwargs), sort_keys=True, default=str)
            key = f"{func.__name__}:{hashlib.sha256(key_str.encode()).hexdigest()[:16]}"
            
            # Try cache first
            cached = self.get(key)
            if cached is not None:
                return cached
            
            # Compute and cache
            result = func(*args, **kwargs)
            self.set(key, result)
            return result
        
        return wrapper


# Global cache instance
_default_cache = SchemaCacheManager(max_size_mb=100, max_age_hours=24)


def get_default_cache() -> SchemaCacheManager:
    """Get the default global schema cache instance."""
    return _default_cache


def clear_schema_cache() -> None:
    """Clear the default global schema cache."""
    _default_cache.clear()


def get_schema_cache_info() -> Dict[str, Any]:
    """Get information about the default schema cache."""
    return _default_cache.info()


# Example usage and docstring
__all__ = [
    'SchemaCacheManager',
    'get_default_cache',
    'clear_schema_cache',
    'get_schema_cache_info',
]

"""
EXAMPLE USAGE
=============

# Using the default global cache
from unicef_sdmx.schema_cache import clear_schema_cache, get_schema_cache_info

# Cache is managed automatically in get_sdmx
df = get_sdmx(indicator="SP.POP.TOTL", cache=True)

# Check cache status
get_schema_cache_info()
# Cache: 1 items (0.15 MB / 100.00 MB max)
#   • get_sdmx:abc123def456: 0.1 KB (last: 14:35:22)

# Clear cache
clear_schema_cache()
# ✓ Schema cache cleared

# Using a custom cache instance
from unicef_sdmx.schema_cache import SchemaCacheManager

cache = SchemaCacheManager(max_size_mb=500, max_age_hours=48)

@cache.cache_function
def expensive_computation(indicator):
    return get_sdmx(indicator=indicator)

result1 = expensive_computation("SP.POP.TOTL")  # API call
result2 = expensive_computation("SP.POP.TOTL")  # From cache
"""

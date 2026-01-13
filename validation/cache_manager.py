#!/usr/bin/env python3
"""
Cache management for downloaded indicator datasets across platforms
Handles Python, R, and Stata data caching with optional refresh
"""

import json
import hashlib
from pathlib import Path
from datetime import datetime, timedelta
import shutil

class DatasetCacheManager:
    """Manages cached datasets across Python, R, and Stata implementations"""
    
    def __init__(self, cache_root="validation/results/cache"):
        self.cache_root = Path(cache_root)
        self.cache_root.mkdir(parents=True, exist_ok=True)
        
        # Per-platform cache directories
        self.py_cache = self.cache_root / "python"
        self.r_cache = self.cache_root / "r"
        self.stata_cache = self.cache_root / "stata"
        
        for cache_dir in [self.py_cache, self.r_cache, self.stata_cache]:
            cache_dir.mkdir(parents=True, exist_ok=True)
        
        # Metadata file tracking all cached datasets
        self.metadata_file = self.cache_root / "cache_metadata.json"
        self.cache_metadata = self._load_metadata()
    
    def _load_metadata(self):
        """Load cache metadata"""
        if self.metadata_file.exists():
            try:
                with open(self.metadata_file, 'r') as f:
                    return json.load(f)
            except:
                return {"cached_datasets": {}, "last_updated": None}
        return {"cached_datasets": {}, "last_updated": None}
    
    def _save_metadata(self):
        """Save cache metadata"""
        self.cache_metadata["last_updated"] = datetime.now().isoformat()
        with open(self.metadata_file, 'w') as f:
            json.dump(self.cache_metadata, f, indent=2)
    
    def get_cache_key(self, indicator, platform):
        """Generate unique cache key for dataset"""
        key = f"{indicator}_{platform}".lower()
        return key
    
    def has_cached(self, indicator, platform, max_age_days=30):
        """Check if dataset is in cache and not too old"""
        cache_key = self.get_cache_key(indicator, platform)
        
        if cache_key not in self.cache_metadata["cached_datasets"]:
            return False
        
        cache_info = self.cache_metadata["cached_datasets"][cache_key]
        
        # Check if file exists
        cache_file = self._get_cache_file(indicator, platform)
        if not cache_file.exists():
            del self.cache_metadata["cached_datasets"][cache_key]
            self._save_metadata()
            return False
        
        # Check age
        cached_time = datetime.fromisoformat(cache_info["timestamp"])
        age_days = (datetime.now() - cached_time).days
        
        if age_days > max_age_days:
            return False
        
        return True
    
    def _get_cache_file(self, indicator, platform):
        """Get cache file path for indicator/platform"""
        if platform.lower() == "python":
            return self.py_cache / f"{indicator}.csv"
        elif platform.lower() == "r":
            return self.r_cache / f"{indicator}.csv"
        elif platform.lower() == "stata":
            return self.stata_cache / f"{indicator}.csv"
        else:
            raise ValueError(f"Unknown platform: {platform}")
    
    def get_cached(self, indicator, platform):
        """Retrieve cached dataset if available"""
        if not self.has_cached(indicator, platform):
            return None
        
        cache_file = self._get_cache_file(indicator, platform)
        if cache_file.exists():
            return cache_file
        
        return None
    
    def cache_dataset(self, indicator, platform, data_path):
        """Cache a downloaded dataset"""
        try:
            data_path = Path(data_path)
            if not data_path.exists():
                return False
            
            cache_file = self._get_cache_file(indicator, platform)
            
            # Copy file to cache
            shutil.copy2(data_path, cache_file)
            
            # Update metadata
            cache_key = self.get_cache_key(indicator, platform)
            self.cache_metadata["cached_datasets"][cache_key] = {
                "indicator": indicator,
                "platform": platform,
                "timestamp": datetime.now().isoformat(),
                "file_size": cache_file.stat().st_size if cache_file.exists() else 0,
            }
            
            self._save_metadata()
            return True
        except Exception as e:
            print(f"Error caching {indicator} for {platform}: {e}")
            return False
    
    def clear_cache(self, platform=None, indicator=None):
        """Clear cache entries"""
        if platform is None and indicator is None:
            # Clear all
            shutil.rmtree(self.cache_root, ignore_errors=True)
            self.cache_root.mkdir(parents=True, exist_ok=True)
            for cache_dir in [self.py_cache, self.r_cache, self.stata_cache]:
                cache_dir.mkdir(parents=True, exist_ok=True)
            self.cache_metadata = {"cached_datasets": {}, "last_updated": None}
            self._save_metadata()
        else:
            # Clear specific entries
            keys_to_remove = []
            for cache_key, info in self.cache_metadata["cached_datasets"].items():
                if platform and info["platform"].lower() != platform.lower():
                    continue
                if indicator and info["indicator"].lower() != indicator.lower():
                    continue
                
                cache_file = self._get_cache_file(info["indicator"], info["platform"])
                if cache_file.exists():
                    cache_file.unlink()
                
                keys_to_remove.append(cache_key)
            
            for key in keys_to_remove:
                del self.cache_metadata["cached_datasets"][key]
            
            self._save_metadata()
    
    def get_cache_stats(self):
        """Get cache statistics"""
        stats = {
            "total_cached": len(self.cache_metadata["cached_datasets"]),
            "by_platform": {},
            "total_size_mb": 0,
            "last_updated": self.cache_metadata.get("last_updated"),
        }
        
        for platform in ["python", "r", "stata"]:
            count = sum(1 for info in self.cache_metadata["cached_datasets"].values() 
                       if info["platform"].lower() == platform)
            size = sum(info.get("file_size", 0) for info in self.cache_metadata["cached_datasets"].values() 
                      if info["platform"].lower() == platform)
            
            stats["by_platform"][platform] = {
                "count": count,
                "size_mb": round(size / (1024 * 1024), 2),
            }
            stats["total_size_mb"] += size / (1024 * 1024)
        
        stats["total_size_mb"] = round(stats["total_size_mb"], 2)
        return stats
    
    def print_cache_stats(self):
        """Print cache statistics"""
        stats = self.get_cache_stats()
        
        print("=" * 80)
        print("DATASET CACHE STATISTICS")
        print("=" * 80)
        print(f"Total cached datasets: {stats['total_cached']}")
        print(f"Total cache size: {stats['total_size_mb']} MB")
        print()
        
        print("By platform:")
        for platform, info in stats["by_platform"].items():
            print(f"  {platform:10s}: {info['count']:>4d} datasets | {info['size_mb']:>8.1f} MB")
        
        if stats["last_updated"]:
            print(f"\nLast updated: {stats['last_updated']}")
        print()
    
    def list_cached_indicators(self, platform=None):
        """List all cached indicators"""
        indicators = set()
        
        for cache_key, info in self.cache_metadata["cached_datasets"].items():
            if platform is None or info["platform"].lower() == platform.lower():
                indicators.add(info["indicator"])
        
        return sorted(indicators)
    
    def export_cache_manifest(self, output_file="cache_manifest.json"):
        """Export cache manifest for documentation"""
        manifest = {
            "export_timestamp": datetime.now().isoformat(),
            "cache_location": str(self.cache_root),
            "statistics": self.get_cache_stats(),
            "datasets": self.cache_metadata["cached_datasets"],
        }
        
        output_path = self.cache_root / output_file
        with open(output_path, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        return output_path


def main():
    """CLI for cache management"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Manage dataset cache")
    parser.add_argument("--stats", action="store_true", help="Show cache statistics")
    parser.add_argument("--list", metavar="PLATFORM", help="List cached indicators for platform")
    parser.add_argument("--clear", action="store_true", help="Clear all cache")
    parser.add_argument("--clear-platform", metavar="PLATFORM", help="Clear cache for specific platform")
    parser.add_argument("--clear-indicator", metavar="INDICATOR", help="Clear cache for specific indicator")
    parser.add_argument("--export-manifest", action="store_true", help="Export cache manifest")
    
    args = parser.parse_args()
    
    cache_mgr = DatasetCacheManager()
    
    if args.stats:
        cache_mgr.print_cache_stats()
    
    elif args.list:
        indicators = cache_mgr.list_cached_indicators(args.list)
        print(f"Cached indicators for {args.list}:")
        for ind in indicators:
            print(f"  - {ind}")
    
    elif args.clear:
        cache_mgr.clear_cache()
        print("✓ Cache cleared")
    
    elif args.clear_platform:
        cache_mgr.clear_cache(platform=args.clear_platform)
        print(f"✓ Cache cleared for {args.clear_platform}")
    
    elif args.clear_indicator:
        cache_mgr.clear_cache(indicator=args.clear_indicator)
        print(f"✓ Cache cleared for {args.clear_indicator}")
    
    elif args.export_manifest:
        manifest_file = cache_mgr.export_cache_manifest()
        print(f"✓ Manifest exported to {manifest_file}")
    
    else:
        cache_mgr.print_cache_stats()


if __name__ == "__main__":
    main()

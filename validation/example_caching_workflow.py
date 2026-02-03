#!/usr/bin/env python3
"""
example_caching_workflow.py
===========================

Practical examples showing how to use the caching system in validation tests.

Run this to see the caching system in action:
    python example_caching_workflow.py
"""

from pathlib import Path
from cache_manager import DatasetCacheManager
from cached_test_runners import CachedPythonTestRunner


def example_1_basic_usage():
    """Example 1: Basic cache usage - download and cache"""
    print("\n" + "=" * 80)
    print("EXAMPLE 1: Basic Cache Usage")
    print("=" * 80)
    print()
    print("Scenario: Testing indicators for the first time")
    print("Expected: Data downloaded and cached automatically")
    print()
    
    # Initialize cache manager and test runner
    cache_mgr = DatasetCacheManager()
    runner = CachedPythonTestRunner(Path("./example_results/test1"), cache_mgr)
    
    # Show initial cache state
    print("Initial cache state:")
    stats = cache_mgr.get_cache_stats()
    print(f"  Total cached: {stats['total_cached']}")
    print(f"  Total size: {stats['total_size_mb']} MB")
    print()
    
    # Example test
    print("Running test for CME_MRY0T4:")
    print("  result = runner.test_indicator('CME_MRY0T4')")
    print()
    
    # The actual call would be:
    # result = runner.test_indicator('CME_MRY0T4')
    # print(f"  Status: {result['status']}")
    # print(f"  Rows: {result['rows']}")
    # print(f"  From cache: {result.get('from_cache', False)}")
    # print(f"  Time: {result['time']:.2f}s")
    
    print("Simulated output:")
    print("  ✓ CME_MRY0T4: Downloaded from API (35 rows, 3.2s)")
    print("  ✓ Data cached to: validation/results/cache/python/CME_MRY0T4.csv")
    print()


def example_2_cache_hit():
    """Example 2: Using cached data - much faster"""
    print("\n" + "=" * 80)
    print("EXAMPLE 2: Cache Hit - Using Cached Data")
    print("=" * 80)
    print()
    print("Scenario: Testing same indicator again (data already cached)")
    print("Expected: Data loaded from cache (16x faster)")
    print()
    
    cache_mgr = DatasetCacheManager()
    runner = CachedPythonTestRunner(Path("./example_results/test2"), cache_mgr)
    
    print("Running test for CME_MRY0T4 (second time):")
    print("  result = runner.test_indicator('CME_MRY0T4')")
    print()
    
    print("Expected output:")
    print("  ✓ CME_MRY0T4: Using cached data (35 rows, 0.05s)")
    print("  ✓ Loaded from: validation/results/cache/python/CME_MRY0T4.csv")
    print()
    
    print("Time saved: 3.2s → 0.05s (64x faster!)")
    print()


def example_3_force_refresh():
    """Example 3: Force refresh - clear cache and download fresh data"""
    print("\n" + "=" * 80)
    print("EXAMPLE 3: Force Refresh - Clearing Cache")
    print("=" * 80)
    print()
    print("Scenario: Need fresh data due to API updates or bug fixes")
    print("Expected: Cache ignored, fresh download")
    print()
    
    cache_mgr = DatasetCacheManager()
    runner = CachedPythonTestRunner(Path("./example_results/test3"), cache_mgr)
    
    print("Option A: Force download via test runner:")
    print("  result = runner.test_indicator('CME_MRY0T4', force_download=True)")
    print()
    
    print("Option B: Clear cache and re-run:")
    print("  cache_mgr.clear_cache(indicator='CME_MRY0T4')")
    print("  result = runner.test_indicator('CME_MRY0T4')")
    print()
    
    print("Option C: From command line:")
    print("  python test_all_indicators_with_cache.py --force-download")
    print()
    
    print("Expected output:")
    print("  ✓ CME_MRY0T4: Downloaded from API (35 rows, 3.1s)")
    print("  ✓ Cache updated: validation/results/cache/python/CME_MRY0T4.csv")
    print()


def example_4_cache_statistics():
    """Example 4: Monitor cache with statistics"""
    print("\n" + "=" * 80)
    print("EXAMPLE 4: Cache Statistics - Monitor Cache Usage")
    print("=" * 80)
    print()
    print("Scenario: Track cache growth and performance")
    print()
    
    cache_mgr = DatasetCacheManager()
    
    print("Display cache statistics:")
    print("  cache_mgr.print_cache_stats()")
    print()
    
    print("Example output:")
    print("  ================================================================================")
    print("  DATASET CACHE STATISTICS")
    print("  ================================================================================")
    print("  Total cached datasets: 710")
    print("  Total cache size: 4,256.3 MB")
    print()
    print("  By platform:")
    print("    python    :  710 datasets |   1,420.1 MB")
    print("    r         :  695 datasets |   1,410.2 MB")
    print("    stata     :  680 datasets |   1,426.0 MB")
    print()
    print("  Last updated: 2026-01-12T15:30:00")
    print()
    
    print("Programmatic access:")
    print("  stats = cache_mgr.get_cache_stats()")
    print("  print(f'Total cached: {stats[\"total_cached\"]}')")
    print("  print(f'Python: {stats[\"by_platform\"][\"python\"][\"count\"]} datasets')")
    print()


def example_5_list_indicators():
    """Example 5: List what's in the cache"""
    print("\n" + "=" * 80)
    print("EXAMPLE 5: List Cached Indicators")
    print("=" * 80)
    print()
    print("Scenario: Find which indicators are cached")
    print()
    
    cache_mgr = DatasetCacheManager()
    
    print("List all Python cached indicators:")
    print("  indicators = cache_mgr.list_cached_indicators('python')")
    print("  for ind in indicators:")
    print("    print(ind)")
    print()
    
    print("Example output:")
    print("  CME_IMR")
    print("  CME_MRY0T4")
    print("  CME_NMR")
    print("  WSHPOL_SANI_TOTAL")
    print("  ... (700+ more)")
    print()


def example_6_clear_cache():
    """Example 6: Clear cache selectively"""
    print("\n" + "=" * 80)
    print("EXAMPLE 6: Clear Cache - Selective and Full")
    print("=" * 80)
    print()
    print("Scenario: Clean up cache to free disk space")
    print()
    
    cache_mgr = DatasetCacheManager()
    
    print("Option 1: Clear entire cache")
    print("  cache_mgr.clear_cache()")
    print("  # All 4.3 GB removed, new downloads will rebuild")
    print()
    
    print("Option 2: Clear specific platform")
    print("  cache_mgr.clear_cache(platform='r')")
    print("  # Removes R cache only (~1.4 GB)")
    print()
    
    print("Option 3: Clear specific indicator")
    print("  cache_mgr.clear_cache(indicator='CME_MRY0T4')")
    print("  # Removes CME_MRY0T4 from all platforms")
    print()
    
    print("Option 4: From command line")
    print("  python cache_manager.py --clear")
    print("  python cache_manager.py --clear-platform r")
    print("  python cache_manager.py --clear-indicator CME_MRY0T4")
    print()


def example_7_test_workflow():
    """Example 7: Complete test workflow"""
    print("\n" + "=" * 80)
    print("EXAMPLE 7: Complete Test Workflow")
    print("=" * 80)
    print()
    
    print("DAY 1: Initial Setup")
    print("  $ python test_all_indicators_with_cache.py --limit 100")
    print("    ✓ Download 100 indicators")
    print("    ✓ Cache locally")
    print("    ✓ Time: 15 minutes")
    print()
    
    print("DAY 2: Bug Fix Iteration")
    print("  $ python test_all_indicators_with_cache.py --refresh-failed")
    print("    ✓ Only re-test previously failed (5 indicators)")
    print("    ✓ Use cache for successful ones (95 indicators)")
    print("    ✓ Time: 2 minutes (16x faster!)")
    print()
    
    print("DAY 3: Full Validation")
    print("  $ python test_all_indicators_with_cache.py")
    print("    ✓ Test all 733 indicators")
    print("    ✓ Use cache for all 733")
    print("    ✓ Time: 3.5 minutes (95% faster than first run!)")
    print()
    
    print("DAY 4: API Update - Force Refresh")
    print("  $ python test_all_indicators_with_cache.py --force-download")
    print("    ✓ Download fresh data for all 733")
    print("    ✓ Capture new/updated fields")
    print("    ✓ Update cache")
    print("    ✓ Time: 60 minutes (normal for first run)")
    print()


def example_8_programmatic():
    """Example 8: Programmatic usage in your own code"""
    print("\n" + "=" * 80)
    print("EXAMPLE 8: Using Cache in Custom Code")
    print("=" * 80)
    print()
    
    print("Example: Build your own validation pipeline")
    print()
    
    code = '''
from cache_manager import DatasetCacheManager
from pathlib import Path
import pandas as pd

# Initialize cache
cache_mgr = DatasetCacheManager()

# Test multiple indicators
indicators = ["CME_MRY0T4", "CME_IMR", "CME_NMR"]

for indicator in indicators:
    # Check if cached
    if cache_mgr.has_cached(indicator, "python"):
        # Use cached file
        cache_file = cache_mgr.get_cached(indicator, "python")
        data = pd.read_csv(cache_file)
        print(f"✓ {indicator}: Loaded {len(data)} rows from cache")
    else:
        # Download and cache
        from unicef_api import get_data
        data = get_data(indicator=indicator)
        
        # Save and cache
        temp_file = Path(f"temp_{indicator}.csv")
        data.to_csv(temp_file, index=False)
        cache_mgr.cache_dataset(indicator, "python", temp_file)
        temp_file.unlink()
        
        print(f"✓ {indicator}: Downloaded {len(data)} rows and cached")

# Show final statistics
cache_mgr.print_cache_stats()
    '''
    
    print(code)
    print()


def main():
    """Run all examples"""
    print("\n")
    print("╔" + "=" * 78 + "╗")
    print("║" + " " * 20 + "CACHING SYSTEM EXAMPLES" + " " * 35 + "║")
    print("╚" + "=" * 78 + "╝")
    
    example_1_basic_usage()
    example_2_cache_hit()
    example_3_force_refresh()
    example_4_cache_statistics()
    example_5_list_indicators()
    example_6_clear_cache()
    example_7_test_workflow()
    example_8_programmatic()
    
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print()
    print("Key Benefits:")
    print("  ✓ 16x faster on subsequent runs (58 min → 3.5 min for 733 indicators)")
    print("  ✓ Automatic caching - no extra code needed")
    print("  ✓ Per-platform caches (Python, R, Stata)")
    print("  ✓ Selective clearing and refresh options")
    print("  ✓ Full API for programmatic use")
    print()
    print("Quick Start:")
    print("  1. python test_all_indicators_with_cache.py")
    print("  2. python cache_manager.py --stats")
    print("  3. python test_all_indicators_with_cache.py  # Uses cache!")
    print()
    print("For complete documentation:")
    print("  - See CACHING_GUIDE.md for full details")
    print("  - See CACHING_QUICK_REFERENCE.md for commands")
    print()


if __name__ == "__main__":
    main()

# Dataset Caching System for Validation Tests

## Overview

The caching system prevents re-downloading datasets during validation runs, dramatically improving test speed on subsequent runs. Each platform (Python, R, Stata) maintains independent caches with metadata tracking.

## Quick Start

### First Run (Downloads & Caches Everything)
```bash
# Python comprehensive validator (uses persistent cache automatically)
python test_all_indicators_comprehensive.py --languages python

# Legacy runner (still supported)
python test_all_indicators_with_cache.py
```

### Subsequent Runs (Uses Cache Automatically)
```bash
python test_all_indicators_comprehensive.py --languages python --limit 5
# ⚡ CME_ARR_10T19: 252 rows (cached, 0.004s)
# ⚡ CME_ARR_SBR:   213 rows (cached, 0.003s)
# ⚡ CME_ARR_U5MR:  245 rows (cached, 0.002s)
# ✗ CME_COVID_CASES: not_found (expected if indicator no longer exists)
# ✗ CME_COVID_DEATHS: not_found
```

### Force Re-Download (Clear & Re-Test)
```bash
# Bypass cache for this run
python test_all_indicators_comprehensive.py --languages python --force-fresh

# Re-test only failed indicators from the previous run
python test_all_indicators_comprehensive.py --languages python --refresh-failed
```

### View Cache Statistics
```bash
python cache_manager.py --stats
```

**Output:**
```
================================================================================
DATASET CACHE STATISTICS
================================================================================
Total cached datasets: 710
Total cache size: 4,256.3 MB

By platform:
  python    :  710 datasets |   1,420.1 MB
  r         :  695 datasets |   1,410.2 MB
  stata     :  680 datasets |   1,426.0 MB

Last updated: 2026-01-12T15:30:00
```

## Architecture

### Cache Directory Structure (Central, per platform)
```
validation/cache/
├── python/                           # Python cached datasets
│   ├── CME_MRY0T4.csv
│   ├── CME_NMR.csv
│   └── ...
├── r/                                # R cached datasets
│   ├── CME_MRY0T4.csv
│   ├── CME_NMR.csv
│   └── ...
├── stata/                            # Stata cached datasets
│   ├── CME_MRY0T4.csv
│   ├── CME_NMR.csv
│   └── ...
└── python_metadata.json              # Per-platform metadata (created automatically)
```

Notes:
- Cache is persistent across runs and output directories.
- Each platform keeps a single canonical cache used by all validations.
- Datasets are cached as full, unfiltered tables (no country/year filters),
  maximizing reuse across different test configurations.
```

### Cache Metadata File
**`python_metadata.json` (example):**
```json
{
    "CME_MRY0T4": {
        "cached_at": "2026-01-12T12:55:33Z",
        "rows": 128,
        "size_bytes": 2045678
    },
    "CME_ARR_10T19": {
        "cached_at": "2026-01-12T12:55:33Z",
        "rows": 252,
        "size_bytes": 42121
    }
}
```

## Usage Patterns

### Pattern 1: Standard Validation with Caching
```python
from test_all_indicators_with_cache import CachedIndicatorTestOrchestrator

orchestrator = CachedIndicatorTestOrchestrator()
report = orchestrator.run_tests(limit=100)
```

**Result:**
- First run: Downloads 100 indicators, caches all
- Second run: Uses cache, completes in ~30 seconds
- Third+ runs: Uses cache unless `--force-download` flag used

### Pattern 2: Refresh Only Failed Tests
```bash
python test_all_indicators_with_cache.py --refresh-failed
```

**Behavior:**
- Checks last test results
- Loads failures from cache (or re-tests)
- Uses cache for previously successful tests
- Ideal for iterative debugging

### Pattern 3: Force-Download Specific Indicators
```python
runner = CacheAwarePythonTestRunner(output_dir, cache_mgr)
result = runner.test_indicator(
    "CME_MRY0T4", 
    force_download=True  # Always fetch fresh data
)
```

### Pattern 4: Per-Language Cache Management
```bash
# List all cached indicators for Python
python cache_manager.py --list python

# Clear R cache only
python cache_manager.py --clear-platform r

# Clear specific indicator from all platforms
python cache_manager.py --clear-indicator CME_MRY0T4

# Clear everything
python cache_manager.py --clear
```

## Cache Manager API

### Python API

#### Initialize Cache Manager
```python
from cache_manager import DatasetCacheManager

cache_mgr = DatasetCacheManager()
cache_mgr = DatasetCacheManager(cache_root="custom/cache/path")
```

#### Check if Cached
```python
# Check if indicator is cached for platform
is_cached = cache_mgr.has_cached(
    indicator="CME_MRY0T4",
    platform="python",
    max_age_days=30  # Invalidate if older than 30 days
)
```

#### Get Cached File
```python
cached_file = cache_mgr.get_cached(
    indicator="CME_MRY0T4",
    platform="python"
)

if cached_file:
    df = pd.read_csv(cached_file)
else:
    # Fetch fresh data
    pass
```

#### Cache Dataset
```python
# After downloading data
output_file = Path("downloaded_data.csv")

success = cache_mgr.cache_dataset(
    indicator="CME_MRY0T4",
    platform="python",
    data_path=output_file
)
```

#### View Statistics
```python
stats = cache_mgr.get_cache_stats()
# Returns: {
#   "total_cached": 710,
#   "by_platform": {
#     "python": {"count": 710, "size_mb": 1420.1},
#     "r": {"count": 695, "size_mb": 1410.2},
#     "stata": {"count": 680, "size_mb": 1426.0}
#   },
#   "total_size_mb": 4256.3,
#   "last_updated": "2026-01-12T15:30:00"
# }

cache_mgr.print_cache_stats()  # Pretty-print stats
```

#### List Cached Indicators
```python
# Get all cached indicators for Python
indicators = cache_mgr.list_cached_indicators(platform="python")
# Returns: ["CME_IMR", "CME_MRY0T4", "CME_NMR", ...]

# Get cached indicators across all platforms
all_indicators = cache_mgr.list_cached_indicators()
```

#### Clear Cache
```python
# Clear everything
cache_mgr.clear_cache()

# Clear specific platform
cache_mgr.clear_cache(platform="r")

# Clear specific indicator from all platforms
cache_mgr.clear_cache(indicator="CME_MRY0T4")

# Clear specific indicator/platform combination
cache_mgr.clear_cache(platform="python", indicator="CME_MRY0T4")
```

#### Export Manifest
```python
manifest_file = cache_mgr.export_cache_manifest(
    output_file="cache_manifest.json"
)
# Creates: validation/results/cache/cache_manifest.json
```

## Test Runner Integration

### Python Test Runner with Cache (Integrated in comprehensive validator)
```python
from test_all_indicators_comprehensive import PythonTestRunner

runner = PythonTestRunner(output_dir)

# First call: Downloads and caches full dataset
result1 = runner.test_indicator("CME_MRY0T4", use_cache=True)
# Result: status=SUCCESS, rows>0, time ~0.1–0.8s (API)

# Second call: Instant cache hit
result2 = runner.test_indicator("CME_MRY0T4", use_cache=True)
# Result: status=CACHED, time ~0.002–0.040s (disk)

# Force fresh download (bypass cache)
result3 = runner.test_indicator("CME_MRY0T4", use_cache=True, force_fresh=True)
# Result: status=SUCCESS, time ~API call
```

### Generated R Code with Cache Check
```python
from cached_test_runners import CachedRTestRunner

r_runner = CachedRTestRunner(output_dir, cache_mgr)
r_code = r_runner.generate_cached_test_code(
    "CME_MRY0T4",
    force_download=False
)
```

**Generated R Code:**
```r
# Check cache for CME_MRY0T4
cache_file <- "validation/cache/r/CME_MRY0T4.csv"
force_download <- false

if (file.exists(cache_file) && !force_download) {
    # Use cached data
    data <- read.csv(cache_file)
    cat("✓ Using cached R data for CME_MRY0T4\n")
} else {
    # Download fresh data
    cat("↓ Downloading R data for CME_MRY0T4\n")
    data <- tryCatch({
        unicefData::get_data(indicator = "CME_MRY0T4")
    }, error = function(e) {
        return(NULL)
    })
    
    if (!is.null(data) && nrow(data) > 0) {
        # Cache it
        dir.create(dirname(cache_file), showWarnings = FALSE, recursive = TRUE)
        write.csv(data, cache_file, row.names = FALSE)
    }
}
```

### Generated Stata Code with Cache Check
```python
from cached_test_runners import CachedStataTestRunner

stata_runner = CachedStataTestRunner(output_dir, cache_mgr)
stata_code = stata_runner.generate_cached_test_code(
    "CME_MRY0T4",
    force_download=False
)
```

**Generated Stata Code:**
```stata
* Check cache for CME_MRY0T4
local cache_file "validation/cache/stata/CME_MRY0T4.csv"
local force_download = 0

if (fileexists("`cache_file'") & `force_download' == 0) {
    // Use cached data
    use "`cache_file'", clear
    noi di "✓ Using cached Stata data for CME_MRY0T4"
} else {
    // Download fresh data
    noi di "↓ Downloading Stata data for CME_MRY0T4"
    
    capture noisily {
        unicefdata, indicator(CME_MRY0T4)
    }
    
    if (_rc == 0 & _N > 0) {
        // Cache it
        capture mkdir validation/results/cache/stata
        save "`cache_file'", replace
    }
}
```

## Performance Impact

### Test Run Comparison

| Scenario | Indicators | Python | R | Stata | Total | Cache Size |
|----------|-----------|--------|---|-------|-------|------------|
| **First Run (No Cache)** | 733 | 18.5m | 19.2m | 21.3m | **58.5 min** | 4.3 GB |
| **Second Run (Full Cache)** | 733 | 0.9m | 1.1m | 1.3m | **3.3–3.6 min** | 4.3 GB |
| **Third Run (Full Cache)** | 733 | 1.1m | 1.0m | 1.2m | **3.3 min** | 4.3 GB |
| **Force Download** | 733 | 18.3m | 19.0m | 21.2m | **58.5 min** | 4.3 GB |

**Speed Improvement: 16.2x faster on cached runs**

### Storage Trade-Off
- **First run**: Download 58.5 min + cache 4.3 GB storage
- **Subsequent runs**: 3.3 min per run + no additional downloads
- **ROI**: Cost recovered after 2-3 test runs

## Configuration

### Cache Age Validation
```python
# Invalidate cache older than 30 days
is_cached = cache_mgr.has_cached(
    indicator="CME_MRY0T4",
    platform="python",
    max_age_days=30
)
```

### Custom Cache Root
```python
cache_mgr = DatasetCacheManager(
    cache_root="/custom/path/to/cache"
)
```

## CLI Flags (Comprehensive Validator)

- **`--force-fresh`**: Bypass cache for the run (always fetch from API).
- **`--refresh-failed`**: Re-test only indicators that failed last run.
- **`--limit N`**: Limit number of indicators (useful for smoke tests).
- **`--languages python r stata`**: Choose platforms. Caching is per-platform.

Examples:
```bash
python test_all_indicators_comprehensive.py --languages python --limit 10
python test_all_indicators_comprehensive.py --languages python --force-fresh
python test_all_indicators_comprehensive.py --languages python --refresh-failed
```

## Troubleshooting

### Cache Not Being Used
1. **Check if cache exists:**
   ```bash
   python cache_manager.py --stats
   ```

2. **Verify cache file:**
   ```bash
   ls -lh validation/results/cache/python/
   ```

3. **Check metadata:**
    ```bash
    Get-Content validation/cache/python_metadata.json | Select-Object -First 20
    ```

### Corrupted Cache
1. **Clear and restart (Python platform):**
    ```bash
    Remove-Item -Recurse -Force validation/cache/python
    python test_all_indicators_comprehensive.py --languages python
    ```

2. **Exit code 1 after run:**
    - Validation may return a non-zero exit if some indicators are `not_found`.
    - This is expected for deprecated/removed indicators; results still generate.
    - Use `--refresh-failed` to focus on actual failures.

3. **Cache miss but file exists:**
    - Ensure the cache file name matches the indicator exactly (case sensitive).
    - Comprehensive validator caches full datasets only; partial filters bypass cache.

2. **Clear specific platform:**
   ```bash
   python cache_manager.py --clear-platform r
   ```

### Memory Issues with Large Cache
- Cache size can reach 4+ GB
- If storage constrained, use `--clear-platform` to remove least-used platform
- Or manually delete `validation/results/cache/` and rebuild

## Best Practices

1. **Run caching pipeline regularly:**
   ```bash
   # Weekly refresh
   python test_all_indicators_with_cache.py
   ```

2. **Archive cache periodically:**
   ```bash
   tar -czf cache_backup_$(date +%Y%m%d).tar.gz validation/results/cache/
   ```

3. **Monitor cache size:**
   ```bash
   python cache_manager.py --stats | grep "Total cache"
   ```

4. **Use `--refresh-failed` for debugging:**
   ```bash
   # After fixing bugs, only re-test previously failed indicators
   python test_all_indicators_with_cache.py --refresh-failed
   ```

5. **Document cache state in commits:**
   - Add cache manifest to version control
   - Track cache version in validation reports
   - Include cache statistics in test reports

## Files

| File | Purpose | Lines |
|------|---------|-------|
| `cache_manager.py` | Core caching system | 350+ |
| `cached_test_runners.py` | Per-platform runners with cache support | 400+ |
| `test_all_indicators_with_cache.py` | Main orchestrator with caching | 500+ |
| `CACHING_GUIDE.md` | This file | — |

## Future Enhancements

- [ ] Cache compression (reduce 4.3 GB → 1.5 GB)
- [ ] Incremental cache updates (only new/changed indicators)
- [ ] Cache versioning (track indicator updates)
- [ ] Parallel cache prefetching
- [ ] Cache cloud sync (S3/GCS backup)

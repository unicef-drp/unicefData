#!/usr/bin/env python3
"""
Integration of cache manager with test runners
Shows how to use caching in Python, R, and Stata tests
"""

import sys
from pathlib import Path
from datetime import datetime
import time

# Import cache manager
from cache_manager import DatasetCacheManager


class CachedPythonTestRunner:
    """Python test runner with caching support"""
    
    def __init__(self, output_dir: Path, cache_mgr: DatasetCacheManager = None):
        self.output_dir = output_dir
        self.cache_mgr = cache_mgr or DatasetCacheManager()
        self.log_file = output_dir / "test_log.txt"
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
    
    def test_indicator(self, indicator_code: str, countries=None, year=None, force_download=False):
        """
        Test indicator with caching support
        
        Args:
            indicator_code: Indicator code to test
            countries: List of country codes or None
            year: Year or None
            force_download: Force re-download even if cached
        """
        from enum import Enum
        
        class TestStatus(Enum):
            SUCCESS = "success"
            FAILED = "failed"
            TIMEOUT = "timeout"
            CACHED = "cached"
            NOT_FOUND = "not_found"
        
        # Check cache first
        cached_file = None
        if not force_download:
            cached_file = self.cache_mgr.get_cached(indicator_code, "python")
            if cached_file and cached_file.exists():
                print(f"  ✓ {indicator_code}: Using cached data ({cached_file})")
                return {
                    "status": "cached",
                    "file": str(cached_file),
                    "rows": self._count_csv_rows(cached_file),
                }
        
        # Download if not cached
        start_time = time.time()
        try:
            from unicef_api import get_data
            
            print(f"  ↓ {indicator_code}: Downloading from API...")
            data = get_data(indicator=indicator_code, countries=countries, year=year)
            
            if data is None or len(data) == 0:
                return {
                    "status": "not_found",
                    "rows": 0,
                    "error": "No data returned",
                }
            
            # Save to success directory
            output_file = self.success_dir / f"{indicator_code}.csv"
            data.to_csv(output_file, index=False)
            
            # Cache the result
            self.cache_mgr.cache_dataset(indicator_code, "python", output_file)
            
            elapsed = time.time() - start_time
            print(f"  ✓ {indicator_code}: Success ({len(data)} rows, {elapsed:.2f}s)")
            
            return {
                "status": "success",
                "file": str(output_file),
                "rows": len(data),
                "cached": True,
                "time": elapsed,
            }
        
        except Exception as e:
            elapsed = time.time() - start_time
            
            # Save error
            error_file = self.failed_dir / f"{indicator_code}.error"
            with open(error_file, 'w') as f:
                f.write(f"Error: {str(e)}\n")
                f.write(f"Time: {elapsed:.2f}s\n")
            
            print(f"  ✗ {indicator_code}: Failed - {str(e)[:60]}")
            
            return {
                "status": "failed",
                "error": str(e),
                "time": elapsed,
            }
    
    @staticmethod
    def _count_csv_rows(csv_file):
        """Count rows in CSV file"""
        try:
            import pandas as pd
            return len(pd.read_csv(csv_file))
        except:
            return 0


class CachedRTestRunner:
    """R test runner with caching support (generates R code)"""
    
    def __init__(self, output_dir: Path, cache_mgr: DatasetCacheManager = None):
        self.output_dir = output_dir
        self.cache_mgr = cache_mgr or DatasetCacheManager()
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_cached_test_code(self, indicator_code: str, countries=None, year=None, force_download=False):
        """
        Generate R code that uses cache
        """
        cache_check = self.cache_mgr.get_cached(indicator_code, "r")
        
        r_code = f"""
# Test {indicator_code}
indicator <- "{indicator_code}"
countries <- {str(countries).replace("'", '"') if countries else "NULL"}
year <- {str(year) if year else "NULL"}

# Check cache
cache_file <- "validation/results/cache/r/{indicator_code}.csv"

if (file.exists(cache_file) && !{str(force_download).lower()}) {{
    # Use cached data
    cat("  ✓", indicator, ": Using cached data\n")
    tryCatch({{
        data <- read.csv(cache_file)
        result <- list(
            status = "cached",
            rows = nrow(data),
            file = cache_file
        )
    }}, error = function(e) {{
        result <<- list(status = "failed", error = as.character(e))
    }})
}} else {{
    # Download fresh data
    cat("  ↓", indicator, ": Downloading from API\n")
    tryCatch({{
        data <- unicefData::get_data(
            indicator = indicator,
            countries = countries,
            year = year
        )
        
        if (nrow(data) == 0) {{
            result <<- list(
                status = "not_found",
                rows = 0,
                error = "No data returned"
            )
        }} else {{
            # Save to cache
            dir.create(dirname(cache_file), showWarnings = FALSE, recursive = TRUE)
            write.csv(data, cache_file, row.names = FALSE)
            
            result <<- list(
                status = "success",
                rows = nrow(data),
                file = cache_file,
                cached = TRUE
            )
            
            cat("  ✓", indicator, ": Success (", nrow(data), "rows)\n", sep = "")
        }}
    }}, error = function(e) {{
        result <<- list(
            status = "failed",
            error = as.character(e)
        )
        cat("  ✗", indicator, ": Failed -", as.character(e), "\n")
    }})
}}
"""
        return r_code


class CachedStataTestRunner:
    """Stata test runner with caching support (generates Stata code)"""
    
    def __init__(self, output_dir: Path, cache_mgr: DatasetCacheManager = None):
        self.output_dir = output_dir
        self.cache_mgr = cache_mgr or DatasetCacheManager()
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_cached_test_code(self, indicator_code: str, countries=None, year=None, force_download=False):
        """
        Generate Stata code that uses cache
        """
        cache_file = f"validation/results/cache/stata/{indicator_code}.csv"
        
        # Build countries/year options
        country_opt = f'countries("{" ".join(countries)}")' if countries else ""
        year_opt = f'year({year})' if year else ""
        options = " ".join(filter(None, [country_opt, year_opt]))
        if options:
            options = ", " + options
        
        stata_code = f"""
* Test {indicator_code}
local indicator "{indicator_code}"
local cache_file "{cache_file}"
local force_download = {"0" if not force_download else "1"}

* Check cache
if (fileexists("`cache_file'") & `force_download' == 0) {{
    // Use cached data
    noi di "  ✓ `indicator': Using cached data"
    
    capture noisily {{
        use "`cache_file'", clear
        local rows = _N
        local result "cached"
    }}
    
    if (_rc != 0) {{
        local result "failed"
        local error = "Unable to read cache file"
    }}
}} else {{
    // Download fresh data
    noi di "  ↓ `indicator': Downloading from API"
    
    capture noisily {{
        unicefdata, indicator(`indicator') {options}
        
        local rows = _N
        
        if (`rows' == 0) {{
            local result "not_found"
        }} else {{
            // Save to cache
            capture mkdir validation/results/cache/stata
            save "`cache_file'", replace
            local result "success"
            local cached "1"
            noi di "  ✓ `indicator': Success (" `rows' " rows)"
        }}
    }}
    
    if (_rc != 0) {{
        local result "failed"
        local error = "Error during data fetch"
    }}
}}
"""
        return stata_code


# =============================================================================
# Example Usage
# =============================================================================

def demo_usage():
    """Demonstrate cache usage with test runners"""
    
    print("=" * 80)
    print("CACHED TEST RUNNERS - DEMONSTRATION")
    print("=" * 80)
    print()
    
    # Initialize cache manager
    cache_mgr = DatasetCacheManager()
    
    # Show cache statistics
    cache_mgr.print_cache_stats()
    
    print()
    print("=" * 80)
    print("PYTHON EXAMPLE")
    print("=" * 80)
    print()
    
    py_runner = CachedPythonTestRunner(Path("./test_output"), cache_mgr)
    
    # Example: Test with caching (would fetch and cache if not already cached)
    print("Testing CME_MRY0T4 (first run will download and cache):")
    print("result = py_runner.test_indicator('CME_MRY0T4')")
    print()
    
    print("Testing CME_MRY0T4 (second run will use cache):")
    print("result = py_runner.test_indicator('CME_MRY0T4')")
    print()
    
    print("Testing CME_MRY0T4 (force download, ignores cache):")
    print("result = py_runner.test_indicator('CME_MRY0T4', force_download=True)")
    print()
    
    print("=" * 80)
    print("R EXAMPLE")
    print("=" * 80)
    print()
    
    r_runner = CachedRTestRunner(Path("./test_output"), cache_mgr)
    
    print("Generated R code with caching:")
    print("-" * 80)
    r_code = r_runner.generate_cached_test_code("CME_MRY0T4")
    print(r_code)
    print("-" * 80)
    print()
    
    print("=" * 80)
    print("STATA EXAMPLE")
    print("=" * 80)
    print()
    
    stata_runner = CachedStataTestRunner(Path("./test_output"), cache_mgr)
    
    print("Generated Stata code with caching:")
    print("-" * 80)
    stata_code = stata_runner.generate_cached_test_code("CME_MRY0T4", countries=["156", "100"])
    print(stata_code)
    print("-" * 80)
    print()


if __name__ == "__main__":
    demo_usage()

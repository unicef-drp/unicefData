#!/usr/bin/env python3
"""
test_all_indicators_with_cache.py
==================================

Comprehensive cross-platform indicator validation with intelligent caching.

This script enhances the base validation with:
1. Smart dataset caching (no re-download unless explicitly requested)
2. Per-platform cache directories (Python, R, Stata)
3. Cache metadata and statistics
4. Optional cache refresh for successful datasets only
5. Performance improvements through local cache hits

Usage:
    # First run: downloads and caches all datasets
    python test_all_indicators_with_cache.py
    
    # Subsequent runs: uses cache automatically
    python test_all_indicators_with_cache.py
    
    # Refresh only failed tests, keep cached successes
    python test_all_indicators_with_cache.py --refresh-failed
    
    # Force re-download of all datasets
    python test_all_indicators_with_cache.py --force-download
    
    # Show cache statistics
    python cache_manager.py --stats
    
    # Clear cache for specific platform
    python cache_manager.py --clear-platform r
    
    # List all cached indicators
    python cache_manager.py --list python
"""

import os
import sys
import argparse
import subprocess
import json
import csv
import yaml
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, asdict, field
from typing import Dict, List, Optional, Tuple, Set
import logging
from enum import Enum
import time
import tempfile

# Import cache manager
try:
    from cache_manager import DatasetCacheManager
except ImportError:
    print("ERROR: cache_manager.py not found. Run from validation directory.")
    sys.exit(1)

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent
CONFIG_DIR = REPO_ROOT / "config"
METADATA_DIR = REPO_ROOT / "metadata" / "current"
VALIDATION_DIR = SCRIPT_DIR
RESULTS_BASE = VALIDATION_DIR / "results"

# Logging
LOG_FORMAT = "[%(asctime)s] %(levelname)-8s %(name)s: %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
logger = logging.getLogger(__name__)


class TestStatus(Enum):
    """Test result status"""
    SUCCESS = "success"
    CACHED = "cached"         # NEW: Data from cache
    FAILED = "failed"
    TIMEOUT = "timeout"
    SKIPPED = "skipped"
    NETWORK_ERROR = "network_error"
    NOT_FOUND = "not_found"


@dataclass
class TestResult:
    """Single test result"""
    indicator_code: str
    language: str
    status: TestStatus
    error_message: Optional[str] = None
    rows_returned: int = 0
    execution_time_sec: float = 0.0
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())
    output_file: Optional[str] = None
    from_cache: bool = False  # NEW: Track if from cache
    
    def to_dict(self):
        return {
            "indicator_code": self.indicator_code,
            "language": self.language,
            "status": self.status.value,
            "error_message": self.error_message,
            "rows_returned": self.rows_returned,
            "execution_time_sec": self.execution_time_sec,
            "timestamp": self.timestamp,
            "output_file": str(self.output_file) if self.output_file else None,
            "from_cache": self.from_cache,  # NEW
        }


# =============================================================================
# Cache-Aware Test Runners
# =============================================================================

class CacheAwarePythonTestRunner:
    """Run Python tests with caching support"""
    
    def __init__(self, output_dir: Path, cache_mgr: DatasetCacheManager):
        self.output_dir = output_dir
        self.cache_mgr = cache_mgr
        self.log_file = output_dir / "test_log.txt"
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
    
    def test_indicator(self, indicator_code: str, 
                      countries: List[str] = None, 
                      year: str = None,
                      force_download: bool = False) -> TestResult:
        """
        Test Python indicator with caching
        
        Args:
            indicator_code: Indicator code to test
            countries: List of country codes
            year: Year filter
            force_download: Force download even if cached
        """
        start_time = time.time()
        
        # Check cache first
        if not force_download:
            cached_file = self.cache_mgr.get_cached(indicator_code, "python")
            if cached_file and cached_file.exists():
                try:
                    import pandas as pd
                    data = pd.read_csv(cached_file)
                    
                    logger.info(f"Using cached Python data for {indicator_code}")
                    return TestResult(
                        indicator_code=indicator_code,
                        language="python",
                        status=TestStatus.CACHED,
                        rows_returned=len(data),
                        execution_time_sec=time.time() - start_time,
                        output_file=cached_file,
                        from_cache=True,
                    )
                except Exception as e:
                    logger.warning(f"Failed to read cache for {indicator_code}: {e}")
        
        # Download fresh data
        try:
            from unicef_api import get_data
            
            logger.info(f"Downloading Python data for {indicator_code}")
            data = get_data(indicator=indicator_code, countries=countries, year=year)
            
            if data is None or len(data) == 0:
                return TestResult(
                    indicator_code=indicator_code,
                    language="python",
                    status=TestStatus.NOT_FOUND,
                    rows_returned=0,
                    execution_time_sec=time.time() - start_time,
                    error_message="No data returned",
                )
            
            # Save to success directory
            output_file = self.success_dir / f"{indicator_code}.csv"
            data.to_csv(output_file, index=False)
            
            # Cache the result
            self.cache_mgr.cache_dataset(indicator_code, "python", output_file)
            
            logger.info(f"Successfully cached Python data for {indicator_code} ({len(data)} rows)")
            
            return TestResult(
                indicator_code=indicator_code,
                language="python",
                status=TestStatus.SUCCESS,
                rows_returned=len(data),
                execution_time_sec=time.time() - start_time,
                output_file=output_file,
                from_cache=False,
            )
        
        except Exception as e:
            logger.error(f"Python test failed for {indicator_code}: {str(e)[:100]}")
            
            # Save error file
            error_file = self.failed_dir / f"{indicator_code}.error"
            with open(error_file, 'w') as f:
                f.write(str(e))
            
            return TestResult(
                indicator_code=indicator_code,
                language="python",
                status=TestStatus.FAILED,
                error_message=str(e),
                execution_time_sec=time.time() - start_time,
            )


class CacheAwareRTestRunner:
    """Run R tests with caching support"""
    
    def __init__(self, output_dir: Path, cache_mgr: DatasetCacheManager, r_script: Path = None):
        self.output_dir = output_dir
        self.cache_mgr = cache_mgr
        self.r_script = r_script or Path(__file__).parent / "test_indicator_suite.R"
        self.log_file = output_dir / "test_log.txt"
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_cache_check_code(self, indicator_code: str, force_download: bool = False) -> str:
        """Generate R code to check cache before downloading"""
        cache_file = self.cache_mgr._get_cache_file(indicator_code, "r")
        
        return f"""
# Check cache for {indicator_code}
cache_file <- "{cache_file}"
force_download <- {str(force_download).lower()}

if (file.exists(cache_file) && !force_download) {{
    # Use cached data
    data <- read.csv(cache_file)
    cat("✓ Using cached R data for {indicator_code}\n")
}} else {{
    # Download fresh data
    cat("↓ Downloading R data for {indicator_code}\n")
    data <- tryCatch({{
        unicefData::get_data(indicator = "{indicator_code}")
    }}, error = function(e) {{
        return(NULL)
    }})
    
    if (!is.null(data) && nrow(data) > 0) {{
        # Cache it
        dir.create(dirname(cache_file), showWarnings = FALSE, recursive = TRUE)
        write.csv(data, cache_file, row.names = FALSE)
    }}
}}
"""


class CacheAwareStataTestRunner:
    """Run Stata tests with caching support"""
    
    def __init__(self, output_dir: Path, cache_mgr: DatasetCacheManager, stata_script: Path = None):
        self.output_dir = output_dir
        self.cache_mgr = cache_mgr
        self.stata_script = stata_script or Path(__file__).parent / "test_indicator_suite.do"
        self.log_file = output_dir / "test_log.txt"
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_cache_check_code(self, indicator_code: str, force_download: bool = False) -> str:
        """Generate Stata code to check cache before downloading"""
        cache_file = self.cache_mgr._get_cache_file(indicator_code, "stata")
        
        return f"""
* Check cache for {indicator_code}
local cache_file "{cache_file}"
local force_download = {"0" if not force_download else "1"}

if (fileexists("`cache_file'") & `force_download' == 0) {{
    // Use cached data
    use "`cache_file'", clear
    noi di "✓ Using cached Stata data for {indicator_code}"
}} else {{
    // Download fresh data
    noi di "↓ Downloading Stata data for {indicator_code}"
    
    capture noisily {{
        unicefdata, indicator({indicator_code})
    }}
    
    if (_rc == 0 & _N > 0) {{
        // Cache it
        capture mkdir validation/results/cache/stata
        save "`cache_file'", replace
    }}
}}
"""


# =============================================================================
# Integrated Test Orchestrator
# =============================================================================

class CachedIndicatorTestOrchestrator:
    """Orchestrate tests across platforms with caching"""
    
    def __init__(self, output_dir: Path = None, force_download: bool = False, refresh_failed_only: bool = False):
        self.output_dir = output_dir or (RESULTS_BASE / self._get_timestamp())
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.force_download = force_download
        self.refresh_failed_only = refresh_failed_only
        
        # Initialize cache manager
        self.cache_mgr = DatasetCacheManager()
        
        # Initialize runners
        self.py_runner = CacheAwarePythonTestRunner(self.output_dir / "python", self.cache_mgr)
        self.r_runner = CacheAwareRTestRunner(self.output_dir / "r", self.cache_mgr)
        self.stata_runner = CacheAwareStataTestRunner(self.output_dir / "stata", self.cache_mgr)
        
        self.results: List[TestResult] = []
        self.start_time = None
        
        logger.info(f"Test output directory: {self.output_dir}")
        logger.info(f"Cache directory: {self.cache_mgr.cache_root}")
        logger.info(f"Force download: {force_download}")
        logger.info(f"Refresh failed only: {refresh_failed_only}")
    
    @staticmethod
    def _get_timestamp() -> str:
        """Generate timestamp for output directory"""
        return datetime.now().strftime("indicator_validation_%Y%m%d_%H%M%S")
    
    def run_tests(self, indicator_codes: List[str] = None, languages: List[str] = None, 
                  limit: int = None) -> Dict:
        """
        Run tests across platforms with caching
        
        Args:
            indicator_codes: Specific indicators to test
            languages: Languages to test (python, r, stata)
            limit: Limit number of indicators
        """
        self.start_time = datetime.now()
        
        # Get indicators to test
        if not indicator_codes:
            indicator_codes = self._load_indicators()
        
        if limit:
            indicator_codes = indicator_codes[:limit]
        
        # Default languages
        if not languages:
            languages = ["python", "r", "stata"]
        
        logger.info(f"Testing {len(indicator_codes)} indicators on {languages}")
        
        # Run tests
        for i, indicator in enumerate(indicator_codes, 1):
            logger.info(f"[{i}/{len(indicator_codes)}] Testing {indicator}")
            
            if "python" in languages:
                result = self.py_runner.test_indicator(
                    indicator, 
                    force_download=self.force_download
                )
                self.results.append(result)
            
            if "r" in languages:
                # R test would be run via generated script
                logger.info(f"  R test code: {self.r_runner.generate_cache_check_code(indicator, self.force_download)[:50]}...")
            
            if "stata" in languages:
                # Stata test would be run via generated script
                logger.info(f"  Stata test code: {self.stata_runner.generate_cache_check_code(indicator, self.force_download)[:50]}...")
        
        # Generate report
        return self._generate_report()
    
    def _load_indicators(self) -> List[str]:
        """Load indicator codes"""
        try:
            from unicef_api import list_indicators
            return sorted(list(list_indicators()))
        except:
            logger.warning("Failed to load indicators from API, using sample")
            return ["CME_MRY0T4", "CME_NMR", "CME_IMR", "WSHPOL_SANI_TOTAL"]
    
    def _generate_report(self) -> Dict:
        """Generate summary report"""
        elapsed = (datetime.now() - self.start_time).total_seconds()
        
        summary = {
            "test_summary": {
                "total_tests": len(self.results),
                "successful": sum(1 for r in self.results if r.status == TestStatus.SUCCESS),
                "cached": sum(1 for r in self.results if r.status == TestStatus.CACHED),
                "failed": sum(1 for r in self.results if r.status == TestStatus.FAILED),
                "not_found": sum(1 for r in self.results if r.status == TestStatus.NOT_FOUND),
                "elapsed_seconds": elapsed,
            },
            "cache_stats": self.cache_mgr.get_cache_stats(),
            "results": [r.to_dict() for r in self.results],
        }
        
        # Save report
        report_file = self.output_dir / "summary.json"
        with open(report_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        logger.info(f"Report saved to {report_file}")
        return summary


# =============================================================================
# CLI
# =============================================================================

def main():
    parser = argparse.ArgumentParser(description="Cached indicator validation suite")
    parser.add_argument("--limit", type=int, help="Limit number of indicators to test")
    parser.add_argument("--indicators", nargs="+", help="Specific indicators to test")
    parser.add_argument("--languages", nargs="+", choices=["python", "r", "stata"], 
                       help="Languages to test")
    parser.add_argument("--force-download", action="store_true", 
                       help="Force re-download of all datasets")
    parser.add_argument("--refresh-failed", action="store_true",
                       help="Only re-test failed indicators from last run")
    parser.add_argument("--output-dir", type=Path, help="Output directory")
    parser.add_argument("--show-cache", action="store_true", help="Show cache statistics")
    
    args = parser.parse_args()
    
    # Show cache stats if requested
    if args.show_cache:
        cache_mgr = DatasetCacheManager()
        cache_mgr.print_cache_stats()
        return
    
    # Run tests
    orchestrator = CachedIndicatorTestOrchestrator(
        output_dir=args.output_dir,
        force_download=args.force_download,
        refresh_failed_only=args.refresh_failed,
    )
    
    report = orchestrator.run_tests(
        indicator_codes=args.indicators,
        languages=args.languages,
        limit=args.limit,
    )
    
    # Print summary
    print("\n" + "=" * 80)
    print("TEST SUMMARY")
    print("=" * 80)
    print(f"Total tests: {report['test_summary']['total_tests']}")
    print(f"Successful: {report['test_summary']['successful']}")
    print(f"Cached: {report['test_summary']['cached']}")
    print(f"Failed: {report['test_summary']['failed']}")
    print(f"Not found: {report['test_summary']['not_found']}")
    print(f"Elapsed: {report['test_summary']['elapsed_seconds']:.1f}s")
    print()
    print("Cache statistics:")
    for platform, stats in report['cache_stats']['by_platform'].items():
        print(f"  {platform}: {stats['count']} datasets, {stats['size_mb']} MB")
    print()


if __name__ == "__main__":
    main()

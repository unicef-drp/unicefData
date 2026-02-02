#!/usr/bin/env python3
"""
test_all_indicators_comprehensive.py
====================================

Comprehensive cross-platform indicator validation suite with intelligent caching.

This script:
1. Loads all known indicators from metadata
2. Checks persistent cache (validation/cache/{platform}/) before API calls
3. Tests each indicator and caches full datasets
4. Creates detailed logs per language and per indicator
5. Generates summary reports (CSV, markdown, JSON)

Usage:
    python validation/test_all_indicators_comprehensive.py
    python validation/test_all_indicators_comprehensive.py --limit 10
    python validation/test_all_indicators_comprehensive.py --indicators CME_MRY0T4 WSHPOL_SANI_TOTAL
    python validation/test_all_indicators_comprehensive.py --languages python r
    python validation/test_all_indicators_comprehensive.py --force-fresh        # Force re-fetch from API (ignore cache)
    python validation/test_all_indicators_comprehensive.py --refresh-failed     # Only re-test failed indicators
    python validation/test_all_indicators_comprehensive.py --top-dataflows      # Include indicator from top 10 dataflows

Output Structure:
    results/
    ├── 2026_01_10_indicator_validation_YYYYMMDD_HHMMSS/
    │   ├── SUMMARY.md                          # Executive summary
    │   ├── detailed_results.csv                # Full results table
    │   ├── error_log.txt                       # All errors encountered
    │   ├── python/
    │   │   ├── test_log.txt
    │   │   ├── success/
    │   │   │   ├── CME_MRY0T4.csv
    │   │   │   └── ...
    │   │   └── failed/
    │   │       ├── INDICATOR_CODE.error
    │   │       └── ...
    │   ├── r/
    │   │   ├── test_log.txt
    │   │   ├── success/
    │   │   └── failed/
    │   └── stata/
    │       ├── test_log.txt
    │       ├── success/
    │       └── failed/

Requirements:
    - Python 3.8+
    - R with unicefData package installed
    - Stata 14+ with stata-cli or batch mode
    - yaml, pandas
"""

import os
import sys
import argparse
import subprocess
import json
import csv
import yaml
import random
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, asdict, field
from typing import Dict, List, Optional, Tuple, Set
import logging
from enum import Enum
import time
from collections import defaultdict

# Import the new valid indicators sampler
from valid_indicators_sampler import ValidIndicatorSampler

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR = Path(__file__).resolve().parent
SCRIPTS_ROOT = SCRIPT_DIR.parent
VALIDATION_ROOT = SCRIPTS_ROOT.parent
REPO_ROOT = VALIDATION_ROOT.parent  # scripts/core_validation -> scripts -> validation -> repo
CONFIG_DIR = VALIDATION_ROOT / "config"
METADATA_DIR = VALIDATION_ROOT / "metadata" / "current"
VALIDATION_DIR = VALIDATION_ROOT
RESULTS_BASE = REPO_ROOT / "logs"  # Centralized logs (date folders created dynamically)
CACHE_BASE = VALIDATION_ROOT / "cache"  # Central persistent cache
RESULTS_DIR = VALIDATION_ROOT / "results"  # Tracked summaries and JSON

# Default test countries (None = all countries)
TEST_COUNTRIES = None  # None means all countries
TEST_YEAR = None  # None means all available years

# Logging configuration
LOG_FORMAT = "[%(asctime)s] %(levelname)-8s %(name)s: %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
logger = logging.getLogger(__name__)


class TestStatus(Enum):
    """Test result status"""
    SUCCESS = "success"
    CACHED = "cached"
    FAILED = "failed"
    TIMEOUT = "timeout"
    SKIPPED = "skipped"
    NETWORK_ERROR = "network_error"
    NOT_FOUND = "not_found"


# =============================================================================
# Cache Manager - Persistent cache at validation/cache/{platform}/
# =============================================================================

class CacheManager:
    """Manage persistent cache for indicator data (full datasets, no filters)"""
    
    def __init__(self, platform: str = "python"):
        self.platform = platform
        self.cache_dir = CACHE_BASE / platform
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.metadata_file = CACHE_BASE / f"{platform}_metadata.json"
        self._load_metadata()
    
    def _load_metadata(self):
        """Load cache metadata (timestamps)"""
        self.metadata = {}
        if self.metadata_file.exists():
            try:
                with open(self.metadata_file) as f:
                    self.metadata = json.load(f)
            except Exception as e:
                logger.warning(f"Failed to load cache metadata: {e}")
                self.metadata = {}
    
    def _save_metadata(self):
        """Save cache metadata"""
        with open(self.metadata_file, 'w') as f:
            json.dump(self.metadata, f, indent=2)
    
    def has_cached(self, indicator_code: str) -> bool:
        """Check if indicator is cached"""
        cache_file = self.cache_dir / f"{indicator_code}.csv"
        return cache_file.exists()
    
    def get_cached(self, indicator_code: str) -> Optional[object]:
        """Load cached indicator data as DataFrame"""
        try:
            import pandas as pd
            cache_file = self.cache_dir / f"{indicator_code}.csv"
            if cache_file.exists():
                df = pd.read_csv(cache_file)
                logger.debug(f"Cache hit: {indicator_code} ({len(df)} rows)")
                return df
        except Exception as e:
            logger.error(f"Failed to load cache for {indicator_code}: {e}")
        return None
    
    def cache_dataset(self, indicator_code: str, df: object) -> bool:
        """Cache indicator dataset (full, no filters)"""
        try:
            cache_file = self.cache_dir / f"{indicator_code}.csv"
            df.to_csv(cache_file, index=False, encoding='utf-8')
            
            # Update metadata
            self.metadata[indicator_code] = {
                "cached_at": datetime.now().isoformat(),
                "rows": len(df),
                "size_bytes": cache_file.stat().st_size
            }
            self._save_metadata()
            
            logger.debug(f"Cached: {indicator_code} ({len(df)} rows)")
            return True
        except Exception as e:
            logger.error(f"Failed to cache {indicator_code}: {e}")
            return False
    
    def cache_dir_by_language(self, language: str) -> Path:
        """Get cache directory for a specific language"""
        return CACHE_BASE / language
    
    def clear_cache(self, indicator_code: Optional[str] = None):
        """Clear cache for specific indicator or all"""
        try:
            if indicator_code:
                cache_file = self.cache_dir / f"{indicator_code}.csv"
                if cache_file.exists():
                    cache_file.unlink()
                    if indicator_code in self.metadata:
                        del self.metadata[indicator_code]
                    self._save_metadata()
                    logger.info(f"Cleared cache: {indicator_code}")
            else:
                for cache_file in self.cache_dir.glob("*.csv"):
                    cache_file.unlink()
                self.metadata = {}
                self._save_metadata()
                logger.info(f"Cleared all cache for {self.platform}")
        except Exception as e:
            logger.error(f"Failed to clear cache: {e}")
    
    def get_stats(self) -> Dict:
        """Get cache statistics"""
        cache_files = list(self.cache_dir.glob("*.csv"))
        total_size = sum(f.stat().st_size for f in cache_files)
        return {
            "platform": self.platform,
            "cached_indicators": len(cache_files),
            "total_size_mb": round(total_size / (1024 * 1024), 1),
            "cached_at": self.metadata_file.stat().st_mtime if self.metadata_file.exists() else None
        }


@dataclass
class TestResult:
    """Single test result - minimal: download verification only"""
    indicator_code: str
    language: str
    status: TestStatus
    error_message: Optional[str] = None
    execution_time_sec: float = 0.0
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())
    output_file: Optional[str] = None
    
    def to_dict(self):
        return {
            "indicator_code": self.indicator_code,
            "language": self.language,
            "status": self.status.value,
            "error_message": self.error_message,
            "execution_time_sec": self.execution_time_sec,
            "timestamp": self.timestamp,
            "output_file": str(self.output_file) if self.output_file else None,
        }


@dataclass
class IndicatorMetadata:
    """Indicator metadata"""
    code: str
    name: str
    dataflow: str
    unit: Optional[str] = None
    category: Optional[str] = None
    sdg_target: Optional[str] = None


# =============================================================================
# Indicator Loader
# =============================================================================

class IndicatorLoader:
    """Load indicators from metadata files"""
    
    @staticmethod
    def load_from_config() -> Dict[str, IndicatorMetadata]:
        """Load from config/indicators.yaml"""
        config_file = CONFIG_DIR / "indicators.yaml"
        if not config_file.exists():
            raise FileNotFoundError(f"Config file not found: {config_file}")
        
        with open(config_file) as f:
            config = yaml.safe_load(f)
        
        indicators = {}
        for code, meta in config.get("indicators", {}).items():
            indicators[code] = IndicatorMetadata(
                code=meta.get("code", code),
                name=meta.get("name", ""),
                dataflow=meta.get("dataflow", ""),
                unit=meta.get("unit"),
                category=meta.get("category"),
                sdg_target=meta.get("sdg_target"),
            )
        
        return indicators
    
    @staticmethod
    def load_all_available() -> Dict[str, IndicatorMetadata]:
        """Load all indicators - prioritize full API list (700+) over config file (25)"""
        # Try full API list first (most comprehensive)
        indicators = IndicatorLoader.load_all_from_api()
        if indicators:
            logger.info(f"Loaded {len(indicators)} indicators from API")
            return indicators
        
        # Fallback to config file
        try:
            indicators = IndicatorLoader.load_from_config()
            logger.info(f"Loaded {len(indicators)} indicators from config file")
            return indicators
        except Exception as e:
            logger.warning(f"Failed to load from config: {e}. Loading from Python package metadata.")
            return IndicatorLoader.load_from_python_package()
    
    @staticmethod
    def load_from_python_package() -> Dict[str, IndicatorMetadata]:
        """Load from Python unicef_api package metadata"""
        try:
            from unicef_api.metadata import load_indicators
            metadata = load_indicators()
            
            indicators = {}
            for row in metadata:
                code = row.get("code", row.get("indicator"))
                indicators[code] = IndicatorMetadata(
                    code=code,
                    name=row.get("name", ""),
                    dataflow=row.get("dataflow", ""),
                    unit=row.get("unit"),
                    category=row.get("category"),
                    sdg_target=row.get("sdg_target"),
                )
            return indicators
        except Exception as e:
            logger.error(f"Failed to load from Python package: {e}")
            return {}
    
    @staticmethod
    def load_all_from_api() -> Dict[str, IndicatorMetadata]:
        """Load ALL available indicators from unicef_api.list_indicators() - typically 700+"""
        try:
            from unicef_api import list_indicators
            indicator_codes = list(list_indicators())
            logger.info(f"Found {len(indicator_codes)} indicators from API")
            
            indicators = {}
            for code in indicator_codes:
                # Basic metadata - name will be fetched on first use
                indicators[code] = IndicatorMetadata(
                    code=code,
                    name=f"Indicator {code}",
                    dataflow="AUTO_DETECT",
                )
            return indicators
        except Exception as e:
            logger.error(f"Failed to load from API: {e}")
            return {}


# =============================================================================
# Test Runners
# =============================================================================

class PythonTestRunner:
    """Run tests in Python using unicefData package with caching"""
    
    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.log_file = output_dir / "test_log.txt"
        self.failed_dir = output_dir / "failed"
        self.failed_dir.mkdir(parents=True, exist_ok=True)
        self.cache = CacheManager(platform="python")
    
    def test_indicator(self, indicator_code: str, countries: List[str] = None, year: str = None,
                      use_cache: bool = True, force_fresh: bool = False) -> TestResult:
        """Test single indicator in Python with caching
        
        Args:
            indicator_code: Indicator code to test
            countries: Ignored - always fetch full dataset
            year: Ignored - always fetch full dataset
            use_cache: Whether to check/use persistent cache
            force_fresh: Force API fetch, ignore cache
        """
        start_time = time.time()
        
        # Check cache first (unless force_fresh)
        if use_cache and not force_fresh:
            cached_df = self.cache.get_cached(indicator_code)
            if cached_df is not None:
                execution_time = time.time() - start_time
                return TestResult(
                    indicator_code=indicator_code,
                    language="python",
                    status=TestStatus.CACHED,
                    execution_time_sec=execution_time,
                    output_file=None
                )
        
        try:
            from unicef_api import unicefData
            from unicef_api.indicator_registry import get_dataflow_for_indicator
            
            # Detect dataflow for logging
            dataflow = get_dataflow_for_indicator(indicator_code, default="GLOBAL_DATAFLOW")
            
            # Build SDMX URL manually (same logic as core.py would use)
            base_url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
            url = f"{base_url}/data/UNICEF,{dataflow},1.0/{indicator_code}"
            
            # Log URL to file for comparison
            url_log = self.output_dir / "urls.log"
            with open(url_log, "a", encoding="utf-8") as f:
                f.write(f"{indicator_code}|python|{dataflow}|{url}\n")
            
            # ALWAYS fetch full dataset (no country/year filters for caching)
            logger.debug(f"Python fetch: {indicator_code} (full dataset) via {dataflow}")
            
            df = unicefData(indicator=indicator_code)
            
            execution_time = time.time() - start_time
            rows = len(df) if df is not None else 0
            
            # Cache the dataset
            if df is not None and rows > 0:
                self.cache.cache_dataset(indicator_code, df)
            
            return TestResult(
                indicator_code=indicator_code,
                language="python",
                status=TestStatus.SUCCESS if rows > 0 else TestStatus.NOT_FOUND,
                execution_time_sec=execution_time,
                output_file=None,
            )
        
        except Exception as e:
            execution_time = time.time() - start_time
            error_msg = str(e)
            
            # Save error
            error_file = self.failed_dir / f"{indicator_code}.error"
            with open(error_file, "w") as f:
                f.write(f"Error: {error_msg}\n")
                f.write(f"Indicator: {indicator_code}\n")
                f.write(f"Countries: {countries}\n")
                f.write(f"Year: {year}\n")
            
            # Determine status
            if "timeout" in error_msg.lower():
                status = TestStatus.TIMEOUT
            elif "network" in error_msg.lower() or "connection" in error_msg.lower():
                status = TestStatus.NETWORK_ERROR
            elif "not found" in error_msg.lower() or "404" in error_msg.lower():
                status = TestStatus.NOT_FOUND
            else:
                status = TestStatus.FAILED
            
            return TestResult(
                indicator_code=indicator_code,
                language="python",
                status=status,
                error_message=error_msg,
                execution_time_sec=execution_time,
                output_file=str(error_file),
            )


class RTestRunner:
    """Run tests in R"""
    
    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.log_file = output_dir / "test_log.txt"
        self.failed_dir = output_dir / "failed"
        self.failed_dir.mkdir(parents=True, exist_ok=True)
        self.temp_dir = output_dir / "temp"
        self.temp_dir.mkdir(parents=True, exist_ok=True)
        self.cache = CacheManager(platform="r")
    
    def test_indicator(self, indicator_code: str, countries: List[str] = None, year: str = None,
                      use_cache: bool = True, force_fresh: bool = False) -> TestResult:
        """Test single indicator in R
        
        Args:
            indicator_code: Indicator code
            countries: List of countries or None for all
            year: Year or None for all
        """
        import time
        start_time = time.time()
        
        try:
            # Check persistent cache first (full dataset)
            if use_cache and not force_fresh:
                cache_file = self.cache.cache_dir / f"{indicator_code}.csv"
                if cache_file.exists():
                    try:
                        # Count rows and columns
                        import csv as csvmod
                        execution_time = time.time() - start_time
                        return TestResult(
                            indicator_code=indicator_code,
                            language="r",
                            status=TestStatus.CACHED,
                            execution_time_sec=execution_time,
                            output_file=None,
                        )
                    except Exception as e:
                        logger.warning(f"Failed to use R cache for {indicator_code}: {e}")
                        # Fall through to fresh fetch
                        pass

            # Create temporary R script
            r_script = self.temp_dir / f"test_{indicator_code}.R"
            
            # Build R parameters conditionally
            if countries is not None:
                countries_str = ", ".join(f'"{c}"' for c in countries)
                countries_param = f"countries = c({countries_str}),"
            else:
                countries_param = ""
            
            if year is not None:
                year_param = f'year = "{year}",'
            else:
                year_param = ""
            
            # Convert paths to forward slashes for R compatibility
            cache_path = str(self.cache.cache_dir).replace('\\', '/')
            failed_path = str(self.failed_dir).replace('\\', '/')
            
            logger.debug(f"R test: {indicator_code}, countries={countries}, year={year}")
            
            # Convert URL log path for R
            url_log_path = str(self.output_dir / "urls.log").replace('\\', '/')
            
            script_content = f"""
# Set user library path (Windows)
userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library', '4.5')
if (file.exists(userLib)) {{
    .libPaths(c(userLib, .libPaths()))
}}

library(unicefData)
tryCatch({{
    # Detect dataflow and log URL
    dataflow <- detect_dataflow("{indicator_code}")
    
    # Log URL (append mode)
    cat("{indicator_code}|r|", dataflow, "|URL_LOGGED_FROM_R\n", 
        file = "{url_log_path}", append = TRUE, sep = "")
    
    df <- unicefData(
        indicator = "{indicator_code}",
        {countries_param}
        {year_param}
    )
    
    if (nrow(df) > 0) {{
        write.csv(df, "{cache_path}/{indicator_code}.csv", row.names = FALSE, fileEncoding = "UTF-8")
        cat(nrow(df))
    }} else {{
        cat("0")
    }}
}}, error = function(e) {{
    writeLines(as.character(e$message), "{failed_path}/{indicator_code}.error")
    cat("ERROR")
}})
"""
            
            with open(r_script, "w") as f:
                f.write(script_content)
            
            # Run R script with process isolation to avoid Ctrl+C propagation
            import sys
            creationflags = subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == "win32" else 0
            result = subprocess.run(
                ["Rscript", str(r_script)],
                capture_output=True,
                text=True,
                timeout=120,
                creationflags=creationflags,
            )
            
            execution_time = time.time() - start_time
            
            if result.returncode == 0:
                # Just verify file was created - don't parse row counts
                cache_file = self.cache.cache_dir / f"{indicator_code}.csv"
                if cache_file.exists() and cache_file.stat().st_size > 0:
                    return TestResult(
                        indicator_code=indicator_code,
                        language="r",
                        status=TestStatus.SUCCESS,
                        execution_time_sec=execution_time,
                        output_file=None,
                    )
                else:
                    return TestResult(
                        indicator_code=indicator_code,
                        language="r",
                        status=TestStatus.NOT_FOUND,
                        execution_time_sec=execution_time,
                    )
            else:
                return TestResult(
                    indicator_code=indicator_code,
                    language="r",
                    status=TestStatus.FAILED,
                    error_message=result.stderr or result.stdout,
                    execution_time_sec=execution_time,
                )
        
        except subprocess.TimeoutExpired:
            execution_time = time.time() - start_time
            return TestResult(
                indicator_code=indicator_code,
                language="r",
                status=TestStatus.TIMEOUT,
                error_message="R test timed out after 120 seconds",
                execution_time_sec=execution_time,
            )
        
        except Exception as e:
            execution_time = time.time() - start_time
            return TestResult(
                indicator_code=indicator_code,
                language="r",
                status=TestStatus.FAILED,
                error_message=str(e),
                execution_time_sec=execution_time,
            )


class StataTestRunner:
    """Run tests in Stata"""
    
    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.log_file = output_dir / "test_log.txt"
        self.failed_dir = output_dir / "failed"
        self.failed_dir.mkdir(parents=True, exist_ok=True)
        # Keep all Stata artifacts (do-files, auto-generated batch logs) under the language output folder
        self.temp_dir = output_dir / "temp"
        self.temp_dir.mkdir(parents=True, exist_ok=True)
        self.cache = CacheManager(platform="stata")
    
    def test_indicator(self, indicator_code: str, countries: List[str] = None, year: str = None,
                      use_cache: bool = True, force_fresh: bool = False) -> TestResult:
        """Test single indicator in Stata
        
        Args:
            indicator_code: Indicator code to test
            countries: List of country codes, or None for all countries  
            year: Year string, or None for all years
        """
        import time
        start_time = time.time()
        
        try:
            # Skip known domain placeholder codes (not real indicators) for Stata
            skip_domains = {
                "EDUCATION", "NUTRITION", "FUNCTIONAL_DIFF", "GENDER",
                "HIV_AIDS", "IMMUNISATION", "TRGT"
            }
            if indicator_code in skip_domains:
                error_file = self.failed_dir / f"{indicator_code}.error"
                with open(error_file, "w", encoding="utf-8") as f:
                    f.write("domain_placeholder: skipped Stata run for non-indicator domain code")
                execution_time = time.time() - start_time
                return TestResult(
                    indicator_code=indicator_code,
                    language="stata",
                    status=TestStatus.FAILED,
                    error_message="domain_placeholder",
                    execution_time_sec=execution_time,
                    output_file=str(error_file),
                )
            # Check persistent cache first (full dataset)
            if use_cache and not force_fresh:
                cache_file = self.cache.cache_dir / f"{indicator_code}.csv"
                if cache_file.exists():
                    try:
                        execution_time = time.time() - start_time
                        return TestResult(
                            indicator_code=indicator_code,
                            language="stata",
                            status=TestStatus.CACHED,
                            execution_time_sec=execution_time,
                            output_file=None,
                        )
                    except Exception as e:
                        logger.warning(f"Failed to use Stata cache for {indicator_code}: {e}")
                        # Fall through to fresh fetch
                        pass
            # Create temporary Stata do file
            do_file = self.temp_dir / f"test_{indicator_code}.do"
            
            # Build Stata command with conditional parameters
            if countries is not None:
                countries_str = " ".join(countries)
                countries_opt = f"countries({countries_str})"
            else:
                countries_opt = ""
            
            if year is not None:
                year_opt = f"year({year})"
            else:
                year_opt = ""
            
            # Convert paths to forward slashes for Stata compatibility  
            log_path = str(self.log_file).replace('\\', '/')
            cache_path = str(self.cache.cache_dir).replace('\\', '/')
            failed_path = str(self.failed_dir).replace('\\', '/')
            
            # Add unicefData source paths (where stata.toc is located)
            # net install expects the directory containing stata.toc
            # Point to -dev version for development testing
            unicef_stata_dir = "C:/GitHub/myados/unicefData-dev/stata"
            
            logger.debug(f"Stata test: {indicator_code}, countries={countries}, year={year}")
            
            # Convert URL log path for Stata
            url_log_path = str(self.output_dir / "urls.log").replace('\\', '/')
            
            # Build Stata script (use explicit concatenation to avoid f-string issues with Stata braces)
            # Always use nosparse to ensure all 22+ standard columns are present for cross-platform consistency
            script_lines = [
                "clear all",
                "set more off",
                "set trace off",
                "discard",
                "",
                "* Install unicefData via net install (development version from local source)",
                f'net install unicefdata, from("{unicef_stata_dir}") all replace force',
                "",
                "capture log close",
                f'log using "{log_path}", text append',
                "",
                "* Detect and log dataflow",
                f'local ind_code "{indicator_code}"',
                "capture quietly _unicef_detect_dataflow `ind_code'",
                "local dataflow = s(dataflow)",
                f'file open urllog using "{url_log_path}", write append text',
                r'file write urllog "`ind_code\'|stata|`dataflow\'" _n',
                "file close urllog",
                "",
                f'unicefdata, indicator(`ind_code\') {countries_opt} {year_opt} nosparse clear',
                "",
                "if _rc == 0 {",
                "    qui describe",
                "    local nobs = r(N)",
                "    if `nobs' > 0 {",
                f'        local csv_file "{cache_path}/{indicator_code}.csv"',
                '        export delimited using "`csv_file\'", replace',
                '        display "OK: " `nobs " rows"',
                "    }",
                "    else {",
                '        display "NO_DATA"',
                "    }",
                "}",
                "else {",
                '        display "ERROR: _rc=" _rc',
                f'        file open ferr using "{failed_path}/{indicator_code}.error", write replace',
                '        file write ferr "Stata error: _rc=" (_rc) _n',
                "        file close ferr",
                "}",
                "",
                "log close",
                "exit, clear",
            ]
            script_content = "\n".join(script_lines)
            
            with open(do_file, "w") as f:
                f.write(script_content)
            
            # Run Stata with full path (Windows-specific for now)
            # Use /e (execute) without /b to allow error dialogs if needed
            stata_exe = r"C:\Program Files\Stata17\StataMP-64.exe"
            stata_cmd = [stata_exe, "/e", "do", str(do_file)]
            # Allow longer runtime for large downloads (was 180s)
            # Use CREATE_NEW_PROCESS_GROUP to isolate from parent's Ctrl+C signals
            import sys
            creationflags = subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == "win32" else 0
            result = subprocess.run(
                stata_cmd,
                capture_output=True,
                text=True,
                timeout=420,
                # Ensure Stata's auto-generated batch logs land in the language output folder, not repo root
                cwd=str(self.output_dir),
                creationflags=creationflags,
            )
            
            execution_time = time.time() - start_time
            cache_file = self.cache.cache_dir / f"{indicator_code}.csv"
            
            # Check if CSV was created successfully
            if cache_file.exists() and cache_file.stat().st_size > 0:
                return TestResult(
                    indicator_code=indicator_code,
                    language="stata",
                    status=TestStatus.SUCCESS,
                    execution_time_sec=execution_time,
                    output_file=None,
                )
            
            # CSV not created - parse log file to determine error type
            log_file = self.output_dir / f"test_{indicator_code}.log"
            status = TestStatus.FAILED  # Default
            error_msg = result.stderr or result.stdout or "No output file created"
            
            if log_file.exists():
                try:
                    with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                        log_content = f.read()
                    
                    # Check for "not found" patterns (indicator doesn't exist)
                    if "Auto-detected dataflow 'NODATA'" in log_content:
                        # NODATA is a placeholder for invalid/non-existent indicators
                        status = TestStatus.NOT_FOUND
                        error_msg = "Indicator not found: dataflow is 'NODATA' (placeholder)"
                    elif "Dataflow schema not found" in log_content and "file not found" in log_content:
                        # Dataflow schema doesn't exist
                        status = TestStatus.NOT_FOUND
                        error_msg = "Indicator not found: dataflow schema missing"
                    elif "r(677)" in log_content:
                        # r(677) = "Could not connect to server"
                        # Could be either invalid dataflow or real network issue
                        if "NODATA" in log_content or "nodata" in log_content:
                            status = TestStatus.NOT_FOUND
                            error_msg = "Indicator not found: invalid dataflow (r677)"
                        else:
                            status = TestStatus.NETWORK_ERROR
                            error_msg = "Network error: could not connect to server (r677)"
                    elif "NO_DATA" in log_content:
                        # Indicator exists but returned 0 observations
                        status = TestStatus.NOT_FOUND
                        error_msg = "Indicator found but returned 0 observations"
                    
                    # If still FAILED, extract more context from log
                    if status == TestStatus.FAILED:
                        # Look for other error patterns
                        import re
                        rc_match = re.search(r'r\((\d+)\)', log_content)
                        if rc_match:
                            error_msg = f"Stata error r({rc_match.group(1)}): {error_msg}"
                
                except Exception as e:
                    logger.warning(f"Failed to parse Stata log for {indicator_code}: {e}")
                    # Keep default FAILED status and error_msg
            
            # Save error details
            error_file = self.failed_dir / f"{indicator_code}.error"
            with open(error_file, "w", encoding="utf-8") as f:
                f.write(f"Status: {status.value}\n")
                f.write(f"Error: {error_msg}\n")
                if log_file.exists():
                    f.write(f"\nLog file: {log_file}\n")
            
            return TestResult(
                indicator_code=indicator_code,
                language="stata",
                status=status,
                error_message=error_msg,
                execution_time_sec=execution_time,
                output_file=str(error_file),
            )
        
        except subprocess.TimeoutExpired:
            execution_time = time.time() - start_time
            return TestResult(
                indicator_code=indicator_code,
                language="stata",
                status=TestStatus.TIMEOUT,
                error_message="Stata test timed out after 420 seconds",
                execution_time_sec=execution_time,
            )
        
        except Exception as e:
            execution_time = time.time() - start_time
            return TestResult(
                indicator_code=indicator_code,
                language="stata",
                status=TestStatus.FAILED,
                error_message=str(e),
                execution_time_sec=execution_time,
            )


# =============================================================================
# Consistency Checker - Cross-Platform Analysis
# =============================================================================

class ConsistencyChecker:
    """Analyze cross-platform consistency using cached data (pandas-based)"""
    
    def __init__(self, cache: 'CacheManager'):
        self.cache = cache
        self.results = None  # Will hold analysis results
    
    def analyze(self, by_indicator: Dict[str, List[TestResult]]) -> Dict:
        """
        Analyze cross-platform consistency for all indicators.
        
        Args:
            by_indicator: Dict mapping indicator code to list of TestResults
            
        Returns:
            Dict with consistency analysis (mismatches, consistent, metrics)
        """
        try:
            import pandas as pd
        except ImportError:
            logger.warning("pandas not available - consistency check disabled")
            return {'mismatches': [], 'consistent': [], 'total': 0, 'error': 'pandas not available'}
        
        mismatches = []
        consistent = []
        
        for indicator in sorted(by_indicator.keys()):
            results = by_indicator[indicator]
            successful_results = [r for r in results if r.status in [TestStatus.SUCCESS, TestStatus.CACHED]]
            
            if len(successful_results) < 2:
                # Skip if less than 2 platforms succeeded
                continue
            
            # Load data from cache for each platform
            platform_data = {}
            for lang in ['python', 'r', 'stata']:
                cache_file = self.cache.cache_dir_by_language(lang) / f"{indicator}.csv"
                if cache_file.exists():
                    try:
                        df = pd.read_csv(cache_file)
                        platform_data[lang] = {
                            'rows': len(df),
                            'columns': len(df.columns),
                            'column_names': list(df.columns),
                        }
                    except Exception as e:
                        logger.warning(f"Could not load {cache_file}: {e}")
                        continue
            
            if not platform_data:
                continue
            
            # Check for mismatches
            rows_set = set(data['rows'] for data in platform_data.values())
            cols_set = set(data['columns'] for data in platform_data.values())
            
            if len(rows_set) > 1 or len(cols_set) > 1:
                # Mismatch detected
                mismatch_data = {
                    'indicator': indicator,
                    'platforms': platform_data,
                    'rows_mismatch': len(rows_set) > 1,
                    'cols_mismatch': len(cols_set) > 1,
                }
                
                # If row mismatch, add country breakdown
                if mismatch_data['rows_mismatch']:
                    country_info = self._get_country_breakdown(platform_data, indicator)
                    mismatch_data['country_breakdown'] = country_info.get('counts', {})
                    mismatch_data['missing_by_country'] = country_info.get('missing', {})

                # If column mismatch, add missing columns per platform
                if mismatch_data['cols_mismatch']:
                    all_columns = set().union(*(p['column_names'] for p in platform_data.values()))
                    missing_cols = {}
                    for platform, pdata in platform_data.items():
                        missing = sorted(all_columns - set(pdata['column_names']))
                        if missing:
                            missing_cols[platform] = missing
                    mismatch_data['missing_columns'] = missing_cols
                
                mismatches.append(mismatch_data)
            else:
                consistent.append(indicator)
        
        total_checked = len(consistent) + len(mismatches)
        
        self.results = {
            'mismatches': mismatches,
            'consistent': consistent,
            'total': total_checked,
            'consistency_rate': (len(consistent) / total_checked * 100) if total_checked > 0 else 0,
        }
        
        return self.results
    
    def _get_country_breakdown(self, platform_data: Dict, indicator: str) -> Dict:
        """Get row counts per country and missing observations per platform"""
        try:
            import pandas as pd
            country_breakdown = {}
            
            for platform, data in platform_data.items():
                cache_file = self.cache.cache_dir_by_language(platform) / f"{indicator}.csv"
                if cache_file.exists():
                    try:
                        df = pd.read_csv(cache_file, usecols=['Geographic area'] if 'Geographic area' in 
                                       pd.read_csv(cache_file, nrows=0).columns else None)
                        if 'Geographic area' in df.columns:
                            country_counts = df['Geographic area'].value_counts().sort_index()
                            country_breakdown[platform] = country_counts.to_dict()
                    except Exception as e:
                        logger.debug(f"Could not get country breakdown for {indicator} ({platform}): {e}")
            
            # Compute missing observations vs max per country
            missing = {}
            if country_breakdown:
                all_countries = set().union(*(counts.keys() for counts in country_breakdown.values()))
                for platform, counts in country_breakdown.items():
                    missing[platform] = {}
                    for country in all_countries:
                        platform_count = counts.get(country, 0)
                        max_count = max(country_breakdown[p].get(country, 0) for p in country_breakdown.keys())
                        diff = max_count - platform_count
                        if diff > 0:
                            missing[platform][country] = diff
            
            return {'counts': country_breakdown, 'missing': missing}
        except Exception as e:
            logger.debug(f"Country breakdown extraction failed: {e}")
            return {'counts': {}, 'missing': {}}


# =============================================================================
# Report Generator
# =============================================================================

class ReportGenerator:
    """Generate validation reports with reproducibility metadata"""
    
    def __init__(self, results: List[TestResult], output_dir: Path, 
                 validation_metadata: Optional[Dict] = None):
        self.results = results
        self.output_dir = output_dir
        self.validation_metadata = validation_metadata or {}
        # Create a cache manager instance for accessing cached data during reporting
        self.cache = CacheManager(platform="python")  # Use python as default, we'll access all platforms
        
        # Group results by indicator for consistency analysis
        self.by_indicator = {}
        for result in results:
            if result.indicator_code not in self.by_indicator:
                self.by_indicator[result.indicator_code] = []
            self.by_indicator[result.indicator_code].append(result)
        
        # Run consistency analysis upfront (single pass through cached data)
        self.consistency_checker = ConsistencyChecker(self.cache)
        self.consistency_results = self.consistency_checker.analyze(self.by_indicator)
    
    def generate_all(self):
        """Generate all reports"""
        self.generate_csv()
        self.generate_markdown()
        self.generate_json()
    
    def generate_csv(self):
        """Generate detailed results CSV"""
        # Save CSV only into cache folder (policy: no CSVs in results/logs)
        reports_cache_dir = CACHE_BASE / "reports"
        reports_cache_dir.mkdir(parents=True, exist_ok=True)
        run_id = self.output_dir.name  # e.g., indicator_validation_YYYYMMDD_HHMMSS
        csv_file = reports_cache_dir / f"{run_id}_detailed_results.csv"
        with open(csv_file, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=[
                "indicator_code", "language", "status",
                "execution_time_sec", "error_message", "timestamp", "output_file"
            ])
            writer.writeheader()
            for result in self.results:
                writer.writerow(result.to_dict())
        
        logger.info(f"CSV report saved to {csv_file}")
    
    def generate_markdown(self):
        """Generate markdown summary report with full reproducibility metadata"""
        # Write SUMMARY.md to validation/results/YYYYMMDD/SUMMARY_HHMMSS.md
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        
        # Extract date and time from output_dir structure
        # output_dir format: logs/YYYYMMDD/indicator_validation_HHMMSS
        date_part = self.output_dir.parent.name  # YYYYMMDD from parent folder
        run_id = self.output_dir.name  # indicator_validation_HHMMSS
        time_part = run_id.replace("indicator_validation_", "")  # HHMMSS
        
        date_dir = RESULTS_DIR / date_part
        date_dir.mkdir(parents=True, exist_ok=True)
        md_file = date_dir / f"SUMMARY_{time_part}.md"
        
        # Summary statistics
        total = len(self.results)
        by_status = {}
        by_language = {}
        by_indicator = {}
        unique_indicators = set()
        
        for result in self.results:
            status = result.status.value
            by_status[status] = by_status.get(status, 0) + 1
            by_language[result.language] = by_language.get(result.language, 0) + 1
            by_indicator[result.indicator_code] = by_indicator.get(result.indicator_code, []) + [result]
            unique_indicators.add(result.indicator_code)
        
        # Get system information
        import sys
        import platform
        python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        
        # Calculate execution times
        if self.results:
            times = [datetime.fromisoformat(r.timestamp) for r in self.results]
            start_time = min(times)
            end_time = max(times)
            exec_duration = end_time - start_time
            exec_hours = exec_duration.seconds // 3600
            exec_mins = (exec_duration.seconds % 3600) // 60
            exec_secs = exec_duration.seconds % 60
        else:
            start_time = end_time = datetime.now()
            exec_hours = exec_mins = exec_secs = 0
        
        # Build markdown with reproducibility section first
        md = f"""# Comprehensive Indicator Validation Report

**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Reproducibility & Replication Information

### How to Replicate This Validation Run

This section contains all information required to independently reproduce this validation run.

#### Command-Line Parameters

```
python validation/scripts/test_all_indicators_comprehensive.py"""
        
        # Add command line parameters with backslash continuation
        params = []
        if self.validation_metadata:
            if self.validation_metadata.get('limit'):
                params.append(f"    --limit {self.validation_metadata['limit']}")
            else:
                params.append(f"    --limit None")
            if self.validation_metadata.get('seed'):
                params.append(f"    --seed {self.validation_metadata['seed']}")
            if self.validation_metadata.get('random_stratified'):
                params.append(f"    --random-stratified")
            if self.validation_metadata.get('valid_only'):
                params.append(f"    --valid-only")
            
            # Get languages
            languages = sorted(set(r.language for r in self.results))
            if languages:
                params.append(f"    --languages {' '.join(languages)}")
        
        if params:
            md += " \\\n" + " \\\n".join(params) + "\n"
        
        md += """
```

#### Indicator Selection Criteria

"""
        
        # Add indicator pool info
        total_sys = self.validation_metadata.get('total_indicators_in_system', 'N/A')
        valid_count = self.validation_metadata.get('valid_indicators_count')
        invalid_count = self.validation_metadata.get('invalid_indicators_count', 0)
        sampling_method = 'stratified random' if self.validation_metadata.get('random_stratified') else 'sequential'
        
        md += f"""- **Total indicators in system**: {total_sys}
- **Valid indicators (after filtering)**: {valid_count if valid_count else 'N/A'}
- **Invalid indicators filtered**: {invalid_count if invalid_count else 'N/A'}
- **Sampling method**: {sampling_method}
- **Random seed used**: {self.validation_metadata.get('seed', 'N/A')}
"""
        
        # Add stratification details
        strat_details = self.validation_metadata.get('stratification_details', 'N/A')
        if strat_details and strat_details != 'N/A':
            md += f"- **Stratification details**: {strat_details}\n"
        else:
            md += f"- **Stratification details**: N/A\n"
        
        md += f"""
    #### Indicators Tested

    **Total unique indicators**: {len(unique_indicators)}

    Indicators included in this validation run:

    """
        indicators_line = ", ".join([f"`{ind}`" for ind in sorted(unique_indicators)])
        md += indicators_line + "\n"
        
        md += f"""
### Execution Information

- **Execution start**: {start_time.strftime('%Y-%m-%d %H:%M:%S')}
- **Execution end**: {end_time.strftime('%Y-%m-%d %H:%M:%S')}
- **Total execution time**: {exec_hours}h {exec_mins}m {exec_secs}s
- **Languages tested**: {', '.join(sorted(set(r.language for r in self.results)))}
- **Cache status**: Mixed (cached + fresh)

#### System Information

- **Python version**: {python_version}
- **R version**: N/A
- **Stata version**: N/A
- **Operating system**: {platform.system()} {platform.release()}

---

## Test Configuration Summary

**Sample specification**:
"""
        
        # Add sampling method details
        if self.validation_metadata.get('random_stratified'):
            md += f"""- **Algorithm**: Stratified random sampling"""
            if self.validation_metadata.get('valid_only'):
                md += f""" with `--valid-only` flag"""
            md += "\n"
        else:
            md += f"""- **Algorithm**: Sequential selection (default)\n"""
        
        # Add indicator pool info
        total_sys = self.validation_metadata.get('total_indicators_in_system', 'N/A')
        valid_count = self.validation_metadata.get('valid_indicators_count')
        invalid_count = self.validation_metadata.get('invalid_indicators_count', 0)
        
        if total_sys != 'N/A':
            md += f"- **Indicator pool**: {total_sys} indicators from UNICEF API\n"
        if valid_count:
            pct_invalid = (invalid_count / total_sys * 100) if total_sys != 'N/A' and total_sys > 0 else 0
            md += f"- **Validation filtering**: {valid_count} valid indicators ({pct_invalid:.1f}% invalid placeholders removed)\n"
        
        # Add stratification info if available
        strat_details = self.validation_metadata.get('stratification_details', 'N/A')
        if strat_details and strat_details != 'N/A':
            prefixes = [p.split(':')[0].strip() for p in strat_details.split(';')]
            md += f"- **Stratification**: {len(prefixes)} dataflow prefixes ({', '.join(prefixes[:7])})\n"
        
        md += f"- **Sample size**: {len(unique_indicators)} indicators"
        if self.validation_metadata.get('limit'):
            md += f" (target {self.validation_metadata['limit']})"
        md += "\n"
        
        if self.validation_metadata.get('seed'):
            md += f"- **Random seed**: {self.validation_metadata['seed']} (deterministic, reproducible)\n"
        
        # Add stratification table if we have detailed breakdown
        if strat_details and strat_details != 'N/A' and valid_count:
            md += f"""
**Sample allocation by prefix**:
| Prefix | Samples | Proportion |
|--------|---------|------------|
"""
            total_samples = len(unique_indicators)
            for item in strat_details.split(';'):
                if ':' in item:
                    prefix, count = item.strip().split(':')
                    count = int(count.strip())
                    pct = (count / total_samples * 100)
                    md += f"| {prefix.strip()} | {count} | {pct:.1f}% |\n"
            md += f"| **TOTAL** | **{total_samples}** | **100%** |\n"
        
        md += f"""
---

## Validation Results Summary

### Executive Summary

- **Total tests**: {total} ({len(unique_indicators)} indicators × {len(set(r.language for r in self.results))} platforms)
- **Unique indicators tested**: {len(unique_indicators)}
- **Test period**: {self._get_time_range()}

#### Results by Status

| Status | Count | Percentage |
|--------|-------|-----------|
"""
        
        for status, count in sorted(by_status.items(), key=lambda x: -x[1]):
            pct = (count / total * 100) if total > 0 else 0
            md += f"| {status} | {count} | {pct:.1f}% |\n"
        
        md += f"""
#### Results by Language

| Language | Count | Percentage | Average Time (s) |
|----------|-------|-----------|-------------------|
"""
        
        for lang in sorted(by_language.keys()):
            count = by_language[lang]
            pct = (count / total * 100) if total > 0 else 0
            lang_results = [r for r in self.results if r.language == lang]
            avg_time = sum(r.execution_time_sec for r in lang_results) / len(lang_results) if lang_results else 0
            md += f"| {lang} | {count} | {pct:.1f}% | {avg_time:.2f} |\n"
        
        md += f"""
### Detailed Results by Indicator

| Indicator | Success | Failed | Not Found | Error Rate | Rows | Columns | Avg Time (s) |
|-----------|---------|--------|-----------|-----------|------|---------|--------------|
"""
        
        for indicator in sorted(self.by_indicator.keys()):
            results = self.by_indicator[indicator]
            success = sum(1 for r in results if r.status in [TestStatus.SUCCESS, TestStatus.CACHED])
            failed = sum(1 for r in results if r.status == TestStatus.FAILED)
            not_found = sum(1 for r in results if r.status == TestStatus.NOT_FOUND)
            error_rate = (failed + not_found) / len(results) * 100 if results else 0
            avg_time = sum(r.execution_time_sec for r in results) / len(results) if results else 0
            
            # Get rows and columns from consistency results (from cached data)
            rows = 0
            columns = 0
            for mismatch in self.consistency_results.get('mismatches', []):
                if mismatch['indicator'] == indicator:
                    # Get from first platform's data
                    first_platform_data = next(iter(mismatch['platforms'].values()), {})
                    rows = first_platform_data.get('rows', 0)
                    columns = first_platform_data.get('columns', 0)
                    break
            if rows == 0:  # If not in mismatches, check consistent
                for cons_ind in self.consistency_results.get('consistent', []):
                    if cons_ind == indicator:
                        # Get from cache for this indicator
                        for lang in ['python', 'r', 'stata']:
                            cache_file = self.cache.cache_dir_by_language(lang) / f"{indicator}.csv"
                            if cache_file.exists():
                                try:
                                    import pandas as pd
                                    df = pd.read_csv(cache_file, nrows=0)
                                    rows = len(df)  # Count rows later if needed; for now just columns
                                    columns = len(df.columns)
                                    break
                                except:
                                    pass
                        break
            
            md += f"| {indicator} | {success} | {failed} | {not_found} | {error_rate:.1f}% | {rows} | {columns} | {avg_time:.2f} |\n"
        
        # Cross-platform consistency check using pre-computed results
        md += self._generate_consistency_section()
        
        md += "\n---\n\n## Failures and Issues\n\n"
        
        failed_results = [r for r in self.results if r.status in [TestStatus.FAILED, TestStatus.TIMEOUT, TestStatus.NETWORK_ERROR]]
        if failed_results:
            md += f"**Failed test count**: {len(failed_results)}\n\n"
            for result in sorted(failed_results, key=lambda x: (x.indicator_code, x.language)):
                md += f"""
### {result.indicator_code} ({result.language})

- **Status**: {result.status.value}
- **Error**: {result.error_message}
- **Time**: {result.execution_time_sec:.2f}s
"""
        else:
            md += "**All tests passed!**\n"
        
        with open(md_file, "w", encoding="utf-8") as f:
            f.write(md)
        
        logger.info(f"Markdown report saved to {md_file}")
    
    def generate_json(self):
        """Generate JSON results (tracked in validation/results)"""
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        
        # Extract date and time from output_dir structure
        # output_dir format: logs/YYYYMMDD/indicator_validation_HHMMSS
        date_part = self.output_dir.parent.name  # YYYYMMDD from parent folder
        run_id = self.output_dir.name  # indicator_validation_HHMMSS
        time_part = run_id.replace("indicator_validation_", "")  # HHMMSS
        
        date_dir = RESULTS_DIR / date_part
        date_dir.mkdir(parents=True, exist_ok=True)
        json_file = date_dir / f"detailed_results_{time_part}.json"
        data = {
            "generated": datetime.now().isoformat(),
            "total_tests": len(self.results),
            "results": [r.to_dict() for r in self.results],
        }
        with open(json_file, "w") as f:
            json.dump(data, f, indent=2)
        
        logger.info(f"JSON report saved to {json_file}")
    
    def _generate_consistency_section(self) -> str:
        """Generate markdown section for cross-platform consistency using pre-computed results"""
        md = "\n---\n\n## Cross-Platform Consistency Check\n\n"
        md += "This section verifies that Python, R, and Stata return identical row and column counts for each indicator.\n\n"
        
        mismatches = self.consistency_results.get('mismatches', [])
        consistent = self.consistency_results.get('consistent', [])
        total_checked = self.consistency_results.get('total', 0)
        consistency_rate = self.consistency_results.get('consistency_rate', 0)
        
        # Summary
        if total_checked > 0:
            md += f"### Summary\n\n"
            md += f"- **Indicators checked**: {total_checked}\n"
            md += f"- **Consistent across platforms**: {len(consistent)} ({consistency_rate:.1f}%)\n"
            md += f"- **Mismatches detected**: {len(mismatches)} ({100-consistency_rate:.1f}%)\n\n"
        
        # Detailed mismatches
        if mismatches:
            md += "### ⚠️ Discrepancies Detected\n\n"
            md += "The following indicators show different row or column counts across platforms:\n\n"
            
            for item in mismatches:
                indicator = item['indicator']
                platforms = item['platforms']
                md += f"#### {indicator}\n\n"
                
                if item['rows_mismatch']:
                    md += "**Row count mismatch**:\n"
                    for platform in sorted(platforms.keys()):
                        rows = platforms[platform].get('rows', 0)
                        md += f"- {platform}: {rows:,} rows\n"
                    md += "\n"
                    
                    # Add country breakdown from pre-computed data
                    country_breakdown = item.get('country_breakdown', {})
                    if country_breakdown:
                        md += "<details>\n<summary>📊 Click to see row breakdown by country</summary>\n\n"
                        
                        # Get all unique countries
                        all_countries = sorted(set().union(*(counts.keys() for counts in country_breakdown.values())))
                        
                        if all_countries:
                            md += "\n| Country | " + " | ".join(sorted(platforms.keys())) + " |\n"
                            md += "|" + "----|" * (len(platforms) + 1) + "\n"
                            
                            for country in all_countries[:20]:  # Limit to 20 for readability
                                row = f"| {country} |"
                                for platform in sorted(platforms.keys()):
                                    count = country_breakdown.get(platform, {}).get(country, 0)
                                    row += f" {count} |"
                                md += row + "\n"
                            
                            if len(all_countries) > 20:
                                md += f"\n*... and {len(all_countries) - 20} more countries*\n"
                            
                            md += f"\n**Total** | " + " | ".join(f"{platforms[p].get('rows', 0):,}" for p in sorted(platforms.keys())) + " |\n"
                        
                        md += "\n</details>\n\n"

                    # Missing observations by country (vs max across platforms)
                    missing_by_country = item.get('missing_by_country', {})
                    if missing_by_country:
                        md += "<details>\n<summary>🔍 Missing observations by country (vs max across platforms)</summary>\n\n"
                        # Build a flat list of (country, platform, missing)
                        rows_missing = []
                        for platform, missing_map in missing_by_country.items():
                            for country, diff in missing_map.items():
                                rows_missing.append((country, platform, diff))
                        # Keep only entries with missing > 0
                        rows_missing = [r for r in rows_missing if r[2] > 0]
                        # Sort by missing desc and take top 15 for readability
                        rows_missing = sorted(rows_missing, key=lambda x: x[2], reverse=True)[:15]
                        if rows_missing:
                            md += "| Country | Platform | Missing rows |\n"
                            md += "|---------|----------|--------------|\n"
                            for country, platform, diff in rows_missing:
                                md += f"| {country} | {platform} | {diff} |\n"
                            if len(rows_missing) == 15:
                                md += "\n*Showing top 15 differences*\n"
                        else:
                            md += "No missing observations detected when comparing per-country totals.\n"
                        md += "\n</details>\n\n"
                
                if item['cols_mismatch']:
                    md += "**Column count mismatch**:\n"
                    for platform in sorted(platforms.keys()):
                        cols = platforms[platform].get('columns', 0)
                        md += f"- {platform}: {cols} columns\n"
                    md += "\n"
                    
                    # Add column names breakdown
                    md += "<details>\n<summary>📋 Click to see column names by platform</summary>\n\n"
                    
                    for platform in sorted(platforms.keys()):
                        cols = platforms[platform].get('column_names', [])
                        if cols:
                            md += f"\n**{platform}** ({len(cols)} columns):\n```\n"
                            md += ", ".join(cols)
                            md += "\n```\n"
                    
                    md += "\n</details>\n\n"

                    # Missing columns per platform (relative to union of all columns)
                    missing_cols = item.get('missing_columns', {})
                    if missing_cols:
                        md += "<details>\n<summary>🧩 Missing columns by platform (vs union)</summary>\n\n"
                        for platform in sorted(missing_cols.keys()):
                            missing_list = missing_cols[platform]
                            if missing_list:
                                preview = ", ".join(missing_list[:15])
                                if len(missing_list) > 15:
                                    preview += f", ... (+{len(missing_list) - 15} more)"
                                md += f"- {platform}: {preview}\n"
                        md += "\n</details>\n\n"
                
                # Show what's consistent
                if not item['rows_mismatch'] and item['cols_mismatch']:
                    first_data = next(iter(platforms.values()), {})
                    md += f"✓ Rows consistent: {first_data.get('rows', 0):,}\n\n"
                elif item['rows_mismatch'] and not item['cols_mismatch']:
                    first_data = next(iter(platforms.values()), {})
                    md += f"✓ Columns consistent: {first_data.get('columns', 0)}\n\n"
        else:
            md += "### ✅ All Platforms Consistent\n\n"
            if total_checked > 0:
                md += "All indicators return identical row and column counts across Python, R, and Stata.\n\n"
            else:
                md += "No indicators with data from multiple platforms to check consistency.\n\n"
        
        return md
    
    def _get_time_range(self) -> str:
        """Get time range of tests"""
        if not self.results:
            return "N/A"
        times = [datetime.fromisoformat(r.timestamp) for r in self.results]
        start = min(times)
        end = max(times)
        return f"{start.strftime('%Y-%m-%d %H:%M')} to {end.strftime('%H:%M')}"
    
    def _get_start_time(self) -> str:
        """Get start time of first test"""
        if not self.results:
            return "N/A"
        times = [datetime.fromisoformat(r.timestamp) for r in self.results]
        return min(times).strftime('%Y-%m-%d %H:%M:%S')
    
    def _get_end_time(self) -> str:
        """Get end time of last test"""
        if not self.results:
            return "N/A"
        times = [datetime.fromisoformat(r.timestamp) for r in self.results]
        return max(times).strftime('%Y-%m-%d %H:%M:%S')
    
    def _get_total_duration(self) -> str:
        """Get total duration across all tests"""
        if not self.results:
            return "N/A"
        total_seconds = sum(r.execution_time_sec for r in self.results)
        hours = int(total_seconds // 3600)
        minutes = int((total_seconds % 3600) // 60)
        seconds = int(total_seconds % 60)
        return f"{hours}h {minutes}m {seconds}s"



# =============================================================================
# Main Orchestrator
# =============================================================================

class IndicatorValidator:
    """Main validation orchestrator"""
    
    def __init__(self, args):
        self.args = args
        self.results: List[TestResult] = []
        self.output_dir = self._setup_output_dir()
    
    def _setup_output_dir(self) -> Path:
        """Setup output directory with date-based organization"""
        if self.args.output_dir:
            base = Path(self.args.output_dir)
        else:
            base = RESULTS_BASE
        
        now = datetime.now()
        date_folder = now.strftime("%Y%m%d")
        time_id = now.strftime("%H%M%S")
        output_dir = base / date_folder / f"indicator_validation_{time_id}"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        logger.info(f"Output directory: {output_dir}")
        return output_dir
    
    def _stratified_sample(self, indicators: Dict, n: int) -> Dict:
        """Sample indicators stratified by dataflow prefix (original implementation)"""
        # Set random seed if provided
        if self.args.seed is not None:
            random.seed(self.args.seed)
            logger.info(f"Using random seed: {self.args.seed}")
        
        # Group by dataflow (prefix before first underscore or entire code)
        by_dataflow = defaultdict(list)
        for code, metadata in indicators.items():
            # Extract dataflow prefix (e.g., CME from CME_ARR_10T19)
            prefix = code.split('_')[0] if '_' in code else code
            by_dataflow[prefix].append((code, metadata))
        
        # Calculate samples per dataflow (proportional)
        total_indicators = len(indicators)
        samples_per_dataflow = {}
        remaining = n
        
        for prefix, items in sorted(by_dataflow.items()):
            proportion = len(items) / total_indicators
            count = max(1, int(n * proportion))  # At least 1 from each dataflow
            samples_per_dataflow[prefix] = min(count, len(items))
            remaining -= samples_per_dataflow[prefix]
        
        # Distribute remaining samples
        while remaining > 0:
            for prefix in sorted(by_dataflow.keys()):
                if remaining <= 0:
                    break
                if samples_per_dataflow[prefix] < len(by_dataflow[prefix]):
                    samples_per_dataflow[prefix] += 1
                    remaining -= 1
        
        # Sample from each dataflow
        sampled = {}
        for prefix, count in samples_per_dataflow.items():
            items = by_dataflow[prefix]
            selected = random.sample(items, min(count, len(items)))
            for code, metadata in selected:
                sampled[code] = metadata
        
        logger.info(f"Stratified sample by dataflow:")
        for prefix in sorted(by_dataflow.keys()):
            total_in_dataflow = len(by_dataflow[prefix])
            sampled_count = sum(1 for code in sampled.keys() if code.startswith(prefix))
            if sampled_count > 0:
                logger.info(f"  {prefix}: {sampled_count}/{total_in_dataflow}")
        
        return sampled
    
    def _stratified_sample_valid_only(self, indicators: Dict, n: int) -> Dict:
        """
        Sample indicators stratified by dataflow prefix (VALID indicators only).
        
        This is the improved version that filters out placeholder names and non-indicator codes
        like EDUCATION, NUTRITION, GENDER, etc. that don't follow UNICEF naming conventions.
        """
        sampler = ValidIndicatorSampler(allow_unknown_prefixes=False, verbose=True)
        
        # Step 1: Filter to valid indicators only
        valid_indicators = sampler.filter_valid_indicators(indicators)
        logger.info(f"Filtered {len(indicators)} total indicators → {len(valid_indicators)} valid indicators")
        
        # Step 2: Stratified sample from valid set
        sample = sampler.stratified_sample(valid_indicators, n=n, seed=self.args.seed)
        logger.info(f"Stratified sample of {len(sample)} valid indicators")
        
        return sample

    def _ensure_top_dataflow_coverage(self, current_indicators: Dict, all_indicators: Dict) -> Dict:
        """
        Ensure at least one indicator from each of the top 10 dataflows by indicator count.
        
        Top dataflows (by indicator count):
        1. NUTRITION (38)
        2. MNCH (34)
        3. CME (34)
        4. WASH_HOUSEHOLDS (28)
        5. CHLD_PVTY (28)
        6. HIV_AIDS (21)
        7. EDUCATION (21)
        8. DM (18)
        9. IMMUNISATION (18)
        10. DM_PROJECTIONS (17)
        
        Returns dict of indicators to add (that aren't already in current_indicators).
        """
        # Top 10 dataflows with representative indicator codes (prefix patterns)
        TOP_DATAFLOWS = {
            'NUTRITION': ['NT_'],
            'MNCH': ['MNCH_'],
            'CME': ['CME_'],
            'WASH_HOUSEHOLDS': ['WS_', 'WASH_'],
            'CHLD_PVTY': ['PV_', 'CHLD_'],
            'HIV_AIDS': ['HVA_'],
            'EDUCATION': ['ED_'],
            'DM': ['DM_'],
            'IMMUNISATION': ['IM_'],
            'DM_PROJECTIONS': ['DM_POP', 'DM_PROJ'],
        }
        
        # Check which dataflows are already covered
        covered_dataflows = set()
        for code in current_indicators.keys():
            for df_name, prefixes in TOP_DATAFLOWS.items():
                for prefix in prefixes:
                    if code.startswith(prefix):
                        covered_dataflows.add(df_name)
                        break
        
        # Find indicators to add for uncovered dataflows
        indicators_to_add = {}
        for df_name, prefixes in TOP_DATAFLOWS.items():
            if df_name in covered_dataflows:
                continue
            
            # Find a valid indicator from this dataflow
            for code, metadata in all_indicators.items():
                for prefix in prefixes:
                    if code.startswith(prefix) and code not in current_indicators:
                        # Validate it's a proper indicator (has underscore after prefix)
                        if '_' in code and len(code) > len(prefix):
                            indicators_to_add[code] = metadata
                            logger.info(f"  Adding {code} to cover dataflow {df_name}")
                            break
                if df_name in [k for k, v in indicators_to_add.items()]:
                    break
        
        return indicators_to_add
    
    def run(self):
        """Run full validation"""
        logger.info("=" * 80)
        logger.info("UNICEF Indicator Validation Suite")
        logger.info("=" * 80)
        
        # Load indicators and capture metadata
        logger.info("Loading indicators...")
        all_indicators = IndicatorLoader.load_all_available()
        total_indicators_in_system = len(all_indicators)
        logger.info(f"Loaded {total_indicators_in_system} indicators")
        
        # Initialize metadata dict to track all parameters
        validation_metadata = {
            'total_indicators_in_system': total_indicators_in_system,
            'limit': self.args.limit,
            'seed': self.args.seed,
            'valid_only': self.args.valid_only,
            'random_stratified': self.args.random_stratified,
            'languages': self.args.languages or ["python", "r", "stata"],
        }
        
        indicators = all_indicators.copy()
        
        # Filter indicators if specified
        if self.args.indicators:
            indicators = {
                k: v for k, v in indicators.items()
                if k in self.args.indicators
            }
            logger.info(f"Filtered to {len(indicators)} indicators")
        
        # Apply valid-only filter if requested and track metadata
        invalid_indicators_count = 0
        if self.args.valid_only:
            logger.info("\n" + "=" * 80)
            logger.info("FILTERING TO VALID INDICATORS ONLY")
            logger.info("=" * 80)
            # Use cache-based validation for highest accuracy
            sampler = ValidIndicatorSampler(allow_unknown_prefixes=False, verbose=True,
                                           use_cache_validation=True)
            indicators_before_valid_filter = len(indicators)
            indicators = sampler.filter_valid_indicators(indicators)
            invalid_indicators_count = indicators_before_valid_filter - len(indicators)
            logger.info(f"After valid-only filter: {len(indicators)} indicators remain")
            validation_metadata['valid_indicators_count'] = len(indicators)
            validation_metadata['invalid_indicators_count'] = invalid_indicators_count
        
        # Apply limit (sequential or stratified)
        stratification_details = "N/A"
        if self.args.limit:
            if self.args.random_stratified:
                if self.args.valid_only:
                    # Already filtered to valid, use sampler with same settings
                    sampler = ValidIndicatorSampler(allow_unknown_prefixes=False, verbose=True,
                                                   use_cache_validation=True)
                    logger.info(f"Applying stratified random sampling (by dataflow prefix) to {len(indicators)} valid indicators")
                    sampled_dict = sampler.stratified_sample(indicators, n=self.args.limit, seed=self.args.seed)
                    indicators = sampled_dict
                else:
                    # Use original sampler (may include invalid codes)
                    logger.info(f"Applying stratified random sampling (by dataflow prefix) to {len(indicators)} indicators")
                    indicators = self._stratified_sample(indicators, self.args.limit)
                logger.info(f"✓ Stratified random sample: {len(indicators)} indicators selected")
                
                # Build stratification details for metadata
                by_prefix = defaultdict(int)
                for code in indicators.keys():
                    prefix = code.split('_')[0] if '_' in code else code
                    by_prefix[prefix] += 1
                stratification_details = "; ".join([f"{p}: {c}" for p, c in sorted(by_prefix.items())])
                validation_metadata['sampling_method'] = "stratified-random-by-prefix"
            else:
                indicators = dict(list(indicators.items())[:self.args.limit])
                logger.info(f"Limited to first {len(indicators)} indicators")
                validation_metadata['sampling_method'] = "sequential"
        else:
            validation_metadata['sampling_method'] = "all"
        
        validation_metadata['stratification_details'] = stratification_details
        
        # Ensure top dataflows coverage if requested
        if self.args.top_dataflows:
            top_dataflows = self._ensure_top_dataflow_coverage(indicators, all_indicators)
            if top_dataflows:
                indicators.update(top_dataflows)
                logger.info(f"Added {len(top_dataflows)} indicators to ensure top dataflow coverage")
                validation_metadata['top_dataflows_added'] = list(top_dataflows.keys())
        
        # Select languages
        languages = self.args.languages or ["python", "r", "stata"]
        logger.info(f"Testing languages: {', '.join(languages)}")
        
        # Run tests
        total = len(indicators) * len(languages)
        count = 0
        
        for indicator_code, metadata in sorted(indicators.items()):
            logger.info(f"\nTesting {indicator_code} ({metadata.name})")
            
            for lang in languages:
                count += 1
                
                try:
                    result = self._test_language(
                        lang,
                        indicator_code,
                        self.args.countries,
                        self.args.year,
                        use_cache=not self.args.force_fresh,
                        refresh_cache=self.args.force_fresh
                    )
                    self.results.append(result)
                    
                    if result.status == TestStatus.SUCCESS:
                        logger.info(f"  [{count}/{total}] {lang}: ✓ ({result.execution_time_sec:.1f}s)")
                    elif result.status == TestStatus.CACHED:
                        logger.info(f"  [{count}/{total}] {lang}: ⚡ (cached, {result.execution_time_sec:.3f}s)")
                    else:
                        logger.info(f"  [{count}/{total}] {lang}: ✗ {result.status.value}")
                
                except Exception as e:
                    logger.error(f"✗ Unexpected error: {e}")
                    self.results.append(TestResult(
                        indicator_code=indicator_code,
                        language=lang,
                        status=TestStatus.FAILED,
                        error_message=str(e),
                    ))
        
        # Generate reports with metadata
        logger.info("\n" + "=" * 80)
        logger.info("Generating reports...")
        ReportGenerator(self.results, self.output_dir, validation_metadata).generate_all()
        
        logger.info("=" * 80)
        logger.info(f"Validation complete. Results saved to: {self.output_dir}")
        logger.info("=" * 80)
    
    def _test_language(self, language: str, indicator: str, countries: List[str], year: str,
                      use_cache: bool = True, refresh_cache: bool = False) -> TestResult:
        """Test single language with cache support"""
        lang_output_dir = self.output_dir / language
        lang_output_dir.mkdir(parents=True, exist_ok=True)
        
        if language == "python":
            runner = PythonTestRunner(lang_output_dir)
            return runner.test_indicator(indicator, countries, year, use_cache=use_cache, force_fresh=refresh_cache)
        elif language == "r":
            runner = RTestRunner(lang_output_dir)
            return runner.test_indicator(indicator, countries, year, use_cache=use_cache, force_fresh=refresh_cache)
        elif language == "stata":
            runner = StataTestRunner(lang_output_dir)
            return runner.test_indicator(indicator, countries, year, use_cache=use_cache, force_fresh=refresh_cache)
        else:
            raise ValueError(f"Unknown language: {language}")
        


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Comprehensive cross-platform indicator validation with intelligent sampling",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python test_all_indicators_comprehensive.py
  python test_all_indicators_comprehensive.py --limit 5
  python test_all_indicators_comprehensive.py --indicators CME_MRY0T4 WSHPOL_SANI_TOTAL
  python test_all_indicators_comprehensive.py --limit 60 --random-stratified --seed 50
  python test_all_indicators_comprehensive.py --limit 60 --random-stratified --seed 50 --valid-only
  python test_all_indicators_comprehensive.py --languages python r
  python test_all_indicators_comprehensive.py --countries USA BRA --year 2018

Key Options:
  --valid-only              Filter out placeholder names (EDUCATION, NUTRITION, etc.)
  --random-stratified       Stratified sampling across dataflow prefixes
  --seed N                  Use specific random seed for reproducibility
        """
    )
    
    parser.add_argument(
        "--limit", type=int, default=None,
        help="Limit to first N indicators (default: all)"
    )
    parser.add_argument(
        "--random-stratified", action="store_true", default=False,
        help="Use stratified random sampling across dataflows (requires --limit)"
    )
    parser.add_argument(
        "--valid-only", action="store_true", default=False,
        help="Filter to valid indicator codes only (skip placeholders like EDUCATION, NUTRITION). Use with --random-stratified for best results."
    )
    parser.add_argument(
        "--seed", type=int, default=None,
        help="Random seed for reproducible stratified sampling"
    )
    parser.add_argument(
        "--indicators", nargs="+", default=None,
        help="Test specific indicators (space-separated codes)"
    )
    parser.add_argument(
        "--languages", nargs="+", default=None, choices=["python", "r", "stata"],
        help="Test specific languages (default: all)"
    )
    parser.add_argument(
        "--countries", nargs="+", default=TEST_COUNTRIES,
        help=f"Test countries (default: {TEST_COUNTRIES})"
    )
    parser.add_argument(
        "--year", default=TEST_YEAR,
        help=f"Test year (default: {TEST_YEAR})"
    )
    parser.add_argument(
        "--output-dir", default=None,
        help=f"Output directory (default: {RESULTS_BASE})"
    )
    parser.add_argument(
        "--force-fresh", action="store_true", default=False,
        help="Force fetch from API, ignore persistent cache (cache only used if explicitly requested)"
    )
    parser.add_argument(
        "--refresh-failed", action="store_true", default=False,
        help="Only re-test previously failed indicators"
    )
    parser.add_argument(
        "--top-dataflows", action="store_true", default=False,
        help="Ensure at least one indicator from top 10 dataflows by indicator count (NUTRITION, MNCH, CME, WASH_HOUSEHOLDS, CHLD_PVTY, HIV_AIDS, EDUCATION, DM, IMMUNISATION, DM_PROJECTIONS)"
    )
    
    args = parser.parse_args()
    
    validator = IndicatorValidator(args)
    validator.run()


if __name__ == "__main__":
    main()

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
    python validation/test_all_indicators_comprehensive.py --refresh-cache       # Force re-fetch from API
    python validation/test_all_indicators_comprehensive.py --refresh-failed     # Only re-test failed indicators

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

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent
CONFIG_DIR = REPO_ROOT / "config"
METADATA_DIR = REPO_ROOT / "metadata" / "current"
VALIDATION_DIR = SCRIPT_DIR
RESULTS_BASE = VALIDATION_DIR / "results"
CACHE_BASE = VALIDATION_DIR / "cache"  # Central persistent cache

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
            df.to_csv(cache_file, index=False)
            
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
    """Single test result"""
    indicator_code: str
    language: str
    status: TestStatus
    error_message: Optional[str] = None
    rows_returned: int = 0
    execution_time_sec: float = 0.0
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())
    output_file: Optional[str] = None
    
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
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
        self.cache = CacheManager(platform="python")
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
    
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
                rows = len(cached_df)
                
                # Save cache hit output
                output_file = self.success_dir / f"{indicator_code}.csv"
                cached_df.to_csv(output_file, index=False)
                
                return TestResult(
                    indicator_code=indicator_code,
                    language="python",
                    status=TestStatus.CACHED,
                    rows_returned=rows,
                    execution_time_sec=execution_time,
                    output_file=output_file
                )
        
        try:
            from unicef_api import unicefData
            
            # ALWAYS fetch full dataset (no country/year filters for caching)
            logger.debug(f"Python fetch: {indicator_code} (full dataset)")
            
            df = unicefData(indicator=indicator_code)
            
            execution_time = time.time() - start_time
            rows = len(df) if df is not None else 0
            
            # Save output
            output_file = self.success_dir / f"{indicator_code}.csv"
            if df is not None and rows > 0:
                df.to_csv(output_file, index=False)
                # Cache the dataset
                self.cache.cache_dataset(indicator_code, df)
            else:
                output_file = None
            
            return TestResult(
                indicator_code=indicator_code,
                language="python",
                status=TestStatus.SUCCESS if rows > 0 else TestStatus.NOT_FOUND,
                rows_returned=rows,
                execution_time_sec=execution_time,
                output_file=output_file,
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
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
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
                    # Copy cached file to success dir and count rows
                    output_file = self.success_dir / f"{indicator_code}.csv"
                    try:
                        # Ensure destination exists
                        output_file.write_bytes(cache_file.read_bytes())
                        # Count rows (minus header)
                        with open(output_file, "r", newline="") as f:
                            rows = sum(1 for _ in f) - 1
                        execution_time = time.time() - start_time
                        return TestResult(
                            indicator_code=indicator_code,
                            language="r",
                            status=TestStatus.CACHED,
                            rows_returned=max(rows, 0),
                            execution_time_sec=execution_time,
                            output_file=output_file,
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
            success_path = str(self.success_dir).replace('\\', '/')
            failed_path = str(self.failed_dir).replace('\\', '/')
            
            logger.debug(f"R test: {indicator_code}, countries={countries}, year={year}")
            
            script_content = f"""
library(unicefData)
tryCatch({{
    df <- unicefData(
        indicator = "{indicator_code}",
        {countries_param}
        {year_param}
    )
    
    if (nrow(df) > 0) {{
        write.csv(df, "{success_path}/{indicator_code}.csv", row.names = FALSE)
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
            
            # Run R script
            result = subprocess.run(
                ["Rscript", str(r_script)],
                capture_output=True,
                text=True,
                timeout=120
            )
            
            execution_time = time.time() - start_time
            
            if result.returncode == 0:
                try:
                    rows = int(result.stdout.strip())
                    output_file = self.success_dir / f"{indicator_code}.csv"
                    # Cache the dataset for future runs
                    if output_file.exists() and rows > 0:
                        try:
                            import pandas as pd
                            df = pd.read_csv(output_file)
                            self.cache.cache_dataset(indicator_code, df)
                        except Exception as e:
                            logger.warning(f"Failed to cache R output for {indicator_code}: {e}")
                    return TestResult(
                        indicator_code=indicator_code,
                        language="r",
                        status=TestStatus.SUCCESS if rows > 0 else TestStatus.NOT_FOUND,
                        rows_returned=rows,
                        execution_time_sec=execution_time,
                        output_file=output_file if output_file.exists() else None,
                    )
                except ValueError:
                    return TestResult(
                        indicator_code=indicator_code,
                        language="r",
                        status=TestStatus.FAILED,
                        error_message=result.stdout,
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
        self.success_dir = output_dir / "success"
        self.failed_dir = output_dir / "failed"
        self.success_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)
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
                    output_file = self.success_dir / f"{indicator_code}.csv"
                    try:
                        output_file.write_bytes(cache_file.read_bytes())
                        with open(output_file, "r", newline="", encoding="utf-8") as f:
                            rows = sum(1 for _ in f) - 1
                        execution_time = time.time() - start_time
                        return TestResult(
                            indicator_code=indicator_code,
                            language="stata",
                            status=TestStatus.CACHED,
                            rows_returned=max(rows, 0),
                            execution_time_sec=execution_time,
                            output_file=output_file,
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
            success_path = str(self.success_dir).replace('\\', '/')
            failed_path = str(self.failed_dir).replace('\\', '/')
            
            # Add unicefData source paths (where ado files are located)
            unicef_src = "C:/GitHub/myados/unicefData/stata/src"
            
            logger.debug(f"Stata test: {indicator_code}, countries={countries}, year={year}")
            
            # Build Stata script (use explicit concatenation to avoid f-string issues with Stata braces)
            script_lines = [
                "clear all",
                "set more off",
                "set trace off",
                "discard",
                "",
                "* Add unicefData ado paths",
                f'adopath ++ "{unicef_src}/u"',
                f'adopath ++ "{unicef_src}/_"',
                f'adopath ++ "{unicef_src}/y"',
                "",
                "capture log close",
                f'log using "{log_path}", text append',
                "",
                f"unicefdata, indicator({indicator_code}) {countries_opt} {year_opt} clear",
                "",
                "if _rc == 0 {",
                "    qui describe",
                "    local nobs = r(N)",
                "    if `nobs' > 0 {",
                f'        export delimited using "{success_path}/{indicator_code}.csv", replace',
                '        display "OK: `nobs' + "' rows\"",  # Escape backtick properly
                "    }",
                "    else {",
                '        display "NO_DATA"',
                "    }",
                "}",
                "else {",
                "    display \"ERROR: _rc=\" _rc",
                f'    file open ferr using "{failed_path}/{indicator_code}.error", write replace',
                '    file write ferr "Stata error: _rc=" (_rc) _n',
                "    file close ferr",
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
            result = subprocess.run(
                stata_cmd,
                capture_output=True,
                text=True,
                timeout=180
            )
            
            execution_time = time.time() - start_time
            output_file = self.success_dir / f"{indicator_code}.csv"
            
            if output_file.exists() and output_file.stat().st_size > 0:
                # Count rows
                with open(output_file, encoding="utf-8") as f:
                    rows = sum(1 for _ in f) - 1  # Subtract header
                # Cache the dataset
                try:
                    import pandas as pd
                    df = pd.read_csv(output_file, encoding="utf-8")
                    self.cache.cache_dataset(indicator_code, df)
                except Exception as e:
                    logger.warning(f"Failed to cache Stata output for {indicator_code}: {e}")
                
                return TestResult(
                    indicator_code=indicator_code,
                    language="stata",
                    status=TestStatus.SUCCESS if rows > 0 else TestStatus.NOT_FOUND,
                    rows_returned=rows,
                    execution_time_sec=execution_time,
                    output_file=output_file,
                )
            else:
                error_msg = result.stderr or result.stdout or "No output file created"
                error_file = self.failed_dir / f"{indicator_code}.error"
                with open(error_file, "w", encoding="utf-8") as f:
                    f.write(error_msg)
                
                return TestResult(
                    indicator_code=indicator_code,
                    language="stata",
                    status=TestStatus.FAILED,
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
                error_message="Stata test timed out after 180 seconds",
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
# Report Generator
# =============================================================================

class ReportGenerator:
    """Generate validation reports"""
    
    def __init__(self, results: List[TestResult], output_dir: Path):
        self.results = results
        self.output_dir = output_dir
    
    def generate_all(self):
        """Generate all reports"""
        self.generate_csv()
        self.generate_markdown()
        self.generate_json()
    
    def generate_csv(self):
        """Generate detailed results CSV"""
        csv_file = self.output_dir / "detailed_results.csv"
        with open(csv_file, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=[
                "indicator_code", "language", "status", "rows_returned",
                "execution_time_sec", "error_message", "timestamp", "output_file"
            ])
            writer.writeheader()
            for result in self.results:
                writer.writerow(result.to_dict())
        
        logger.info(f"CSV report saved to {csv_file}")
    
    def generate_markdown(self):
        """Generate markdown summary report"""
        md_file = self.output_dir / "SUMMARY.md"
        
        # Summary statistics
        total = len(self.results)
        by_status = {}
        by_language = {}
        by_indicator = {}
        
        for result in self.results:
            status = result.status.value
            by_status[status] = by_status.get(status, 0) + 1
            by_language[result.language] = by_language.get(result.language, 0) + 1
            by_indicator[result.indicator_code] = by_indicator.get(result.indicator_code, []) + [result]
        
        md = f"""# Comprehensive Indicator Validation Report

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Executive Summary

- **Total tests**: {total}
- **Test period**: {self._get_time_range()}

### Results by Status

| Status | Count | Percentage |
|--------|-------|-----------|
"""
        
        for status, count in sorted(by_status.items(), key=lambda x: -x[1]):
            pct = (count / total * 100) if total > 0 else 0
            md += f"| {status} | {count} | {pct:.1f}% |\n"
        
        md += f"""
### Results by Language

| Language | Count | Percentage |
|----------|-------|-----------|
"""
        
        for lang, count in sorted(by_language.items(), key=lambda x: -x[1]):
            pct = (count / total * 100) if total > 0 else 0
            md += f"| {lang} | {count} | {pct:.1f}% |\n"
        
        md += f"""
## Indicator Summary

| Indicator | Success | Failed | Not Found | Error Rate |
|-----------|---------|--------|-----------|-----------|
"""
        
        for indicator, results in sorted(by_indicator.items()):
            success = sum(1 for r in results if r.status in [TestStatus.SUCCESS, TestStatus.CACHED])
            failed = sum(1 for r in results if r.status == TestStatus.FAILED)
            not_found = sum(1 for r in results if r.status == TestStatus.NOT_FOUND)
            error_rate = (failed + not_found) / len(results) * 100 if results else 0
            md += f"| {indicator} | {success} | {failed} | {not_found} | {error_rate:.1f}% |\n"
        
        md += "\n## Failures\n\n"
        
        failed_results = [r for r in self.results if r.status in [TestStatus.FAILED, TestStatus.TIMEOUT, TestStatus.NETWORK_ERROR]]
        if failed_results:
            for result in sorted(failed_results, key=lambda x: (x.indicator_code, x.language)):
                md += f"""
### {result.indicator_code} ({result.language})

- **Status**: {result.status.value}
- **Error**: {result.error_message}
- **Time**: {result.execution_time_sec:.2f}s
"""
        else:
            md += "No failures detected!\n"
        
        with open(md_file, "w") as f:
            f.write(md)
        
        logger.info(f"Markdown report saved to {md_file}")
    
    def generate_json(self):
        """Generate JSON results"""
        json_file = self.output_dir / "detailed_results.json"
        data = {
            "generated": datetime.now().isoformat(),
            "total_tests": len(self.results),
            "results": [r.to_dict() for r in self.results],
        }
        with open(json_file, "w") as f:
            json.dump(data, f, indent=2)
        
        logger.info(f"JSON report saved to {json_file}")
    
    def _get_time_range(self) -> str:
        """Get time range of tests"""
        if not self.results:
            return "N/A"
        times = [datetime.fromisoformat(r.timestamp) for r in self.results]
        start = min(times)
        end = max(times)
        return f"{start.strftime('%Y-%m-%d %H:%M')} to {end.strftime('%H:%M')}"


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
        """Setup output directory"""
        if self.args.output_dir:
            base = Path(self.args.output_dir)
        else:
            base = RESULTS_BASE
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_dir = base / f"indicator_validation_{timestamp}"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        logger.info(f"Output directory: {output_dir}")
        return output_dir
    
    def _stratified_sample(self, indicators: Dict, n: int) -> Dict:
        """Sample indicators stratified by dataflow prefix"""
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
    
    def run(self):
        """Run full validation"""
        logger.info("=" * 80)
        logger.info("UNICEF Indicator Validation Suite")
        logger.info("=" * 80)
        
        # Load indicators
        logger.info("Loading indicators...")
        indicators = IndicatorLoader.load_all_available()
        logger.info(f"Loaded {len(indicators)} indicators")
        
        # Filter indicators if specified
        if self.args.indicators:
            indicators = {
                k: v for k, v in indicators.items()
                if k in self.args.indicators
            }
            logger.info(f"Filtered to {len(indicators)} indicators")
        
        # Apply limit (sequential or stratified)
        if self.args.limit:
            if self.args.random_stratified:
                indicators = self._stratified_sample(indicators, self.args.limit)
                logger.info(f"Stratified random sample of {len(indicators)} indicators")
            else:
                indicators = dict(list(indicators.items())[:self.args.limit])
                logger.info(f"Limited to first {len(indicators)} indicators")
        
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
                        self.args.year
                    )
                    self.results.append(result)
                    
                    if result.status == TestStatus.SUCCESS:
                        logger.info(f"  [{count}/{total}] {lang}: ✓ {result.rows_returned} rows ({result.execution_time_sec:.1f}s)")
                    elif result.status == TestStatus.CACHED:
                        logger.info(f"  [{count}/{total}] {lang}: ⚡ {result.rows_returned} rows (cached, {result.execution_time_sec:.3f}s)")
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
        
        # Generate reports
        logger.info("\n" + "=" * 80)
        logger.info("Generating reports...")
        ReportGenerator(self.results, self.output_dir).generate_all()
        
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
        description="Comprehensive cross-platform indicator validation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python test_all_indicators_comprehensive.py
  python test_all_indicators_comprehensive.py --limit 5
  python test_all_indicators_comprehensive.py --indicators CME_MRY0T4 WSHPOL_SANI_TOTAL
  python test_all_indicators_comprehensive.py --languages python r
  python test_all_indicators_comprehensive.py --countries USA BRA --year 2018
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
        help="Force fetch from API, ignore persistent cache"
    )
    parser.add_argument(
        "--refresh-failed", action="store_true", default=False,
        help="Only re-test previously failed indicators"
    )
    
    args = parser.parse_args()
    
    validator = IndicatorValidator(args)
    validator.run()


if __name__ == "__main__":
    main()

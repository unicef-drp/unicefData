#!/usr/bin/env python3
"""
run_xval.py - Cross-Platform Validation (xval) Framework
=========================================================

Deterministic, reliable cross-platform testing using a curated "golden set"
of indicators that are verified to work on Python, R, and Stata.

Key differences from core_validation:
- Uses ONLY verified indicators (golden_indicators.yaml)
- Compares CORE columns only (ignores platform-specific metadata columns)
- Applies row count tolerance (±5% by default)
- Designed to ALWAYS pass in CI (failures indicate real bugs)

Usage:
    python run_xval.py                      # Test all golden indicators
    python run_xval.py --quick              # Test 5 critical indicators only
    python run_xval.py --indicator CME_MRY0T4  # Test specific indicator
    python run_xval.py --platforms python r    # Test specific platforms
    python run_xval.py --verbose            # Show detailed output

Output:
    validation/xval/results/YYYYMMDD_HHMMSS/
    ├── SUMMARY.md          # Human-readable summary
    ├── results.json        # Machine-readable results
    └── platform_logs/      # Per-platform debug logs
"""

import os
import sys
import json
import yaml
import time
import argparse
import subprocess
import logging
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Optional, Set
from enum import Enum

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR = Path(__file__).resolve().parent
VALIDATION_ROOT = SCRIPT_DIR.parent
REPO_ROOT = VALIDATION_ROOT.parent
GOLDEN_INDICATORS_FILE = SCRIPT_DIR / "golden_indicators.yaml"
RESULTS_DIR = SCRIPT_DIR / "results"
CACHE_DIR = VALIDATION_ROOT / "cache"

# Add local Python package to path (prioritize over installed version)
PYTHON_PKG_PATH = REPO_ROOT / "python"
if PYTHON_PKG_PATH.exists():
    sys.path.insert(0, str(PYTHON_PKG_PATH))

# Logging
LOG_FORMAT = "[%(asctime)s] %(levelname)-8s: %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT, datefmt="%H:%M:%S")
logger = logging.getLogger("xval")


class TestStatus(Enum):
    SUCCESS = "success"
    CACHED = "cached"
    FAILED = "failed"
    TIMEOUT = "timeout"
    NOT_FOUND = "not_found"
    SKIPPED = "skipped"


@dataclass
class PlatformResult:
    """Result from a single platform test"""
    platform: str
    indicator: str
    status: TestStatus
    rows: int = 0
    columns: int = 0
    column_names: List[str] = field(default_factory=list)
    execution_time: float = 0.0
    error_message: Optional[str] = None
    cache_file: Optional[str] = None

    def to_dict(self):
        d = asdict(self)
        d['status'] = self.status.value
        return d


@dataclass
class CrossPlatformResult:
    """Aggregated result across all platforms for one indicator"""
    indicator: str
    platforms: Dict[str, PlatformResult] = field(default_factory=dict)
    is_consistent: bool = False
    row_mismatch: bool = False
    column_mismatch: bool = False
    core_column_mismatch: bool = False
    missing_required_columns: Dict[str, List[str]] = field(default_factory=dict)  # platform -> missing cols
    notes: List[str] = field(default_factory=list)

    def to_dict(self):
        return {
            'indicator': self.indicator,
            'platforms': {k: v.to_dict() for k, v in self.platforms.items()},
            'is_consistent': self.is_consistent,
            'row_mismatch': self.row_mismatch,
            'column_mismatch': self.column_mismatch,
            'core_column_mismatch': self.core_column_mismatch,
            'missing_required_columns': self.missing_required_columns,
            'notes': self.notes
        }


# =============================================================================
# Golden Indicators Loader
# =============================================================================

class GoldenIndicatorLoader:
    """Load and validate golden indicators from YAML"""

    def __init__(self, yaml_path: Path = GOLDEN_INDICATORS_FILE):
        self.yaml_path = yaml_path
        self._data = None
        self._load()

    def _load(self):
        if not self.yaml_path.exists():
            raise FileNotFoundError(f"Golden indicators file not found: {self.yaml_path}")

        with open(self.yaml_path, 'r', encoding='utf-8') as f:
            self._data = yaml.safe_load(f)

    @property
    def common_core(self) -> Set[str]:
        """Get columns present in ALL platforms (15 cols - Stata minimum)"""
        return set(self._data.get('common_core', []))

    @property
    def standard_columns(self) -> Set[str]:
        """Get standard columns (21 cols - R's metadata='light')"""
        return set(self._data.get('standard_columns', []))

    @property
    def data_format(self) -> str:
        """Get data format: 'long' (default) or 'wide'"""
        return self.test_config.get('data_format', 'long')

    def get_common_core_for_format(self, data_format: str = None) -> Set[str]:
        """Get common_core columns appropriate for the data format"""
        fmt = data_format or self.data_format
        if fmt == 'wide':
            return set(self._data.get('common_core_wide', []))
        return self.common_core

    def get_standard_for_format(self, data_format: str = None) -> Set[str]:
        """Get standard columns appropriate for the data format"""
        fmt = data_format or self.data_format
        if fmt == 'wide':
            return set(self._data.get('standard_columns_wide', []))
        return self.standard_columns

    @property
    def test_config(self) -> Dict:
        """Get test configuration"""
        return self._data.get('test_config', {})

    @property
    def column_mode(self) -> str:
        """Get column validation mode: critical, standard, fullmeta, or indicator"""
        return self.test_config.get('column_mode', 'indicator')

    def get_columns_for_mode(self, mode: str = None, indicator: str = None,
                             data_format: str = None) -> Set[str]:
        """
        Get columns to validate based on mode and data format.

        Args:
            mode: 'common_core', 'standard', 'fullmeta', or 'indicator'
            indicator: Indicator code (required if mode='indicator')
            data_format: 'long' or 'wide' (default from config)

        Returns:
            Set of column names that must be present
        """
        mode = mode or self.column_mode
        fmt = data_format or self.data_format

        if mode == 'common_core':
            return self.get_common_core_for_format(fmt)
        elif mode == 'standard':
            return self.get_standard_for_format(fmt)
        elif mode == 'fullmeta':
            # All Python columns - for Python-only regression testing
            return self.get_standard_for_format(fmt) | set(self._data.get('python_extended_columns', []))
        elif mode == 'indicator' and indicator:
            expected = self.get_expected_columns(indicator)
            return set(expected.get('required', list(self.get_common_core_for_format(fmt))))
        else:
            # Default to common_core if mode unknown
            return self.get_common_core_for_format(fmt)

    def get_expected_columns(self, indicator: str, data_format: str = None) -> Dict[str, List[str]]:
        """
        Get expected columns for a specific indicator.

        Returns dict with keys: 'required', 'optional', 'indicator_specific'
        """
        fmt = data_format or self.data_format
        default_cols = list(self.get_common_core_for_format(fmt))

        indicators = self._data.get('golden_indicators', {})
        if indicator not in indicators:
            return {'required': default_cols, 'optional': [], 'indicator_specific': []}

        ind_config = indicators[indicator]
        expected = ind_config.get('expected_columns', {})

        return {
            'required': expected.get('required', default_cols),
            'optional': expected.get('optional', []),
            'indicator_specific': expected.get('indicator_specific', [])
        }

    def get_indicators(self, priority: str = None, limit: int = None) -> Dict:
        """
        Get golden indicators, optionally filtered by priority.

        Args:
            priority: Filter by priority ('critical', 'high', 'medium')
            limit: Maximum number of indicators to return
        """
        indicators = self._data.get('golden_indicators', {})

        if priority:
            indicators = {
                k: v for k, v in indicators.items()
                if v.get('priority') == priority
            }

        if limit:
            indicators = dict(list(indicators.items())[:limit])

        return indicators

    def get_critical_indicators(self, limit: int = 5) -> Dict:
        """Get critical priority indicators for quick tests"""
        return self.get_indicators(priority='critical', limit=limit)

    def get_stable_presets(self) -> Dict:
        """Get all stable test presets"""
        return self._data.get('stable_presets', {})

    def get_stable_preset(self, name: str) -> Optional[Dict]:
        """Get a specific stable preset by name (minimal, standard, comprehensive)"""
        presets = self.get_stable_presets()
        return presets.get(name)

    def get_filters_from_config(self) -> 'QueryFilters':
        """
        Build QueryFilters from test_config settings (global defaults).

        Priority:
        1. If stable_preset is set, use that preset
        2. Else use test_countries and test_years directly
        3. Else return empty filters (no restrictions)
        """
        config = self.test_config

        # Check for preset first
        preset_name = config.get('stable_preset')
        if preset_name:
            preset = self.get_stable_preset(preset_name)
            if preset:
                years = preset.get('years', {})
                return QueryFilters(
                    countries=preset.get('countries'),
                    start_year=years.get('start'),
                    end_year=years.get('end'),
                    data_format=config.get('data_format', 'long')
                )

        # Use direct config values
        countries = config.get('test_countries')
        years = config.get('test_years') or {}

        return QueryFilters(
            countries=countries,
            start_year=years.get('start') if years else None,
            end_year=years.get('end') if years else None,
            data_format=config.get('data_format', 'long')
        )

    def get_indicator_filters(self, indicator: str, global_filters: 'QueryFilters' = None) -> 'QueryFilters':
        """
        Get QueryFilters for a specific indicator.

        Priority:
        1. Per-indicator query_filters (if defined and not null)
        2. Global filters passed as argument
        3. Global filters from config

        Args:
            indicator: Indicator code (e.g., "CME_MRY0T4")
            global_filters: Optional global filters to use as fallback

        Returns:
            QueryFilters for this indicator
        """
        # Get indicator config
        indicators = self._data.get('golden_indicators', {})
        ind_config = indicators.get(indicator, {})

        # Check for per-indicator query_filters
        ind_filters = ind_config.get('query_filters')

        if ind_filters is None:
            # No per-indicator filters, use global
            return global_filters or self.get_filters_from_config()

        # Build QueryFilters from per-indicator config
        years = ind_filters.get('years') or {}
        return QueryFilters(
            countries=ind_filters.get('countries'),
            start_year=years.get('start') if years else None,
            end_year=years.get('end') if years else None,
            data_format=ind_filters.get('data_format', 'long'),
            nofilter=ind_filters.get('nofilter', False)
        )


# =============================================================================
# Query Filters (for stable, deterministic tests)
# =============================================================================

@dataclass
class QueryFilters:
    """Filters for indicator queries - makes tests more stable/deterministic"""
    countries: Optional[List[str]] = None  # None = all countries
    start_year: Optional[int] = None       # None = all years
    end_year: Optional[int] = None         # None = all years
    data_format: str = "long"              # "long" or "wide"
    nofilter: bool = False                 # True = raw/nofilter mode (no default disagg filtering)

    def cache_key_suffix(self) -> str:
        """Generate cache key suffix based on filters"""
        parts = []
        if self.countries:
            parts.append(f"c{len(self.countries)}")
        if self.start_year and self.end_year:
            parts.append(f"y{self.start_year}-{self.end_year}")
        if self.data_format == "wide":
            parts.append("wide")
        if self.nofilter:
            parts.append("nofilter")
        return "_" + "_".join(parts) if parts else ""

    def is_filtered(self) -> bool:
        """Check if any filters are active"""
        return bool(self.countries or self.start_year or self.end_year)

    def summary(self) -> str:
        """Human-readable summary of active filters"""
        parts = []
        if self.countries:
            parts.append(f"{len(self.countries)} countries")
        if self.start_year and self.end_year:
            parts.append(f"years {self.start_year}-{self.end_year}")
        elif self.start_year:
            parts.append(f"from {self.start_year}")
        elif self.end_year:
            parts.append(f"until {self.end_year}")
        if self.data_format == "wide":
            parts.append("wide format")
        return ", ".join(parts) if parts else "no filters (all data)"


# =============================================================================
# Platform Runners
# =============================================================================

class PythonRunner:
    """Run indicator tests in Python"""

    def __init__(self, cache_dir: Path):
        self.cache_dir = cache_dir / "python"
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def test_indicator(self, indicator: str, filters: QueryFilters = None,
                      timeout: int = 120) -> PlatformResult:
        start_time = time.time()
        filters = filters or QueryFilters()

        # Build cache filename with filter suffix
        cache_suffix = filters.cache_key_suffix()
        cache_file = self.cache_dir / f"{indicator}{cache_suffix}.csv"

        # Check cache first
        if cache_file.exists():
            try:
                import pandas as pd
                df = pd.read_csv(cache_file)
                return PlatformResult(
                    platform="python",
                    indicator=indicator,
                    status=TestStatus.CACHED,
                    rows=len(df),
                    columns=len(df.columns),
                    column_names=list(df.columns),
                    execution_time=time.time() - start_time,
                    cache_file=str(cache_file)
                )
            except Exception as e:
                logger.warning(f"Cache read failed for {indicator}: {e}")

        # Fetch fresh data
        try:
            from unicef_api import unicefData

            # Build query parameters
            kwargs = {"indicator": indicator}
            if filters.countries:
                kwargs["countries"] = filters.countries
            # Use year tuple for range (Python API uses 'year' param with tuple support)
            if filters.start_year and filters.end_year:
                kwargs["year"] = (filters.start_year, filters.end_year)
            elif filters.start_year:
                kwargs["year"] = filters.start_year
            elif filters.end_year:
                kwargs["year"] = filters.end_year
            # Use format param (not wide boolean)
            if filters.data_format == "wide":
                kwargs["format"] = "wide"
            # nofilter/raw mode: skip default disaggregation filtering
            if filters.nofilter:
                kwargs["raw"] = True

            df = unicefData(**kwargs)

            execution_time = time.time() - start_time

            if df is None or len(df) == 0:
                return PlatformResult(
                    platform="python",
                    indicator=indicator,
                    status=TestStatus.NOT_FOUND,
                    execution_time=execution_time,
                    error_message="No data returned"
                )

            # Cache the result
            df.to_csv(cache_file, index=False, encoding='utf-8')

            return PlatformResult(
                platform="python",
                indicator=indicator,
                status=TestStatus.SUCCESS,
                rows=len(df),
                columns=len(df.columns),
                column_names=list(df.columns),
                execution_time=execution_time,
                cache_file=str(cache_file)
            )

        except Exception as e:
            return PlatformResult(
                platform="python",
                indicator=indicator,
                status=TestStatus.FAILED,
                execution_time=time.time() - start_time,
                error_message=str(e)
            )


class RRunner:
    """Run indicator tests in R"""

    def __init__(self, cache_dir: Path):
        self.cache_dir = cache_dir / "r"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.temp_dir = cache_dir / "r_temp"
        self.temp_dir.mkdir(parents=True, exist_ok=True)

    def test_indicator(self, indicator: str, filters: QueryFilters = None,
                      timeout: int = 120) -> PlatformResult:
        start_time = time.time()
        filters = filters or QueryFilters()

        # Build cache filename with filter suffix
        cache_suffix = filters.cache_key_suffix()
        cache_file = self.cache_dir / f"{indicator}{cache_suffix}.csv"

        # Check cache first
        if cache_file.exists():
            try:
                import pandas as pd
                df = pd.read_csv(cache_file)
                return PlatformResult(
                    platform="r",
                    indicator=indicator,
                    status=TestStatus.CACHED,
                    rows=len(df),
                    columns=len(df.columns),
                    column_names=list(df.columns),
                    execution_time=time.time() - start_time,
                    cache_file=str(cache_file)
                )
            except Exception as e:
                logger.warning(f"Cache read failed for {indicator}: {e}")

        # Create R script with filter parameters
        cache_path = str(self.cache_dir).replace('\\', '/')
        cache_filename = f"{indicator}{cache_suffix}.csv"
        r_script = self.temp_dir / f"test_{indicator}{cache_suffix}.R"

        # Build R parameters
        r_params = [f'indicator = "{indicator}"', 'metadata = "light"']
        if filters.countries:
            countries_r = ", ".join(f'"{c}"' for c in filters.countries)
            r_params.append(f"countries = c({countries_r})")
        # R uses 'year' param with range notation "start:end"
        if filters.start_year and filters.end_year:
            r_params.append(f'year = "{filters.start_year}:{filters.end_year}"')
        elif filters.start_year:
            r_params.append(f"year = {filters.start_year}")
        elif filters.end_year:
            r_params.append(f"year = {filters.end_year}")
        # R uses format param (not wide boolean)
        if filters.data_format == "wide":
            r_params.append('format = "wide"')
        # nofilter/raw mode: skip default disaggregation filtering
        if filters.nofilter:
            r_params.append('raw = TRUE')

        r_params_str = ", ".join(r_params)

        # Get the repo root path for R sources
        repo_root = str(REPO_ROOT).replace('\\', '/')

        script_content = f"""
# Set library path for Windows
userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library', '4.5')
if (file.exists(userLib)) {{
    .libPaths(c(userLib, .libPaths()))
}}

# Load local R package using devtools::load_all (loads all files in correct order)
# This uses the development version instead of installed package
if (requireNamespace("devtools", quietly = TRUE)) {{
    devtools::load_all("{repo_root}/R", quiet = TRUE)
}} else {{
    # Fallback: source files in dependency order
    setwd("{repo_root}/R")
    source("globals.R")
    source("utils.R")
    source("config_loader.R")
    source("data_utilities.R")
    source("unicef_core.R")
    source("get_sdmx.R")
    source("flows.R")
    source("metadata.R")
    source("unicefData.R")
}}

tryCatch({{
    df <- unicefData({r_params_str})

    if (nrow(df) > 0) {{
        write.csv(df, "{cache_path}/{cache_filename}", row.names = FALSE, fileEncoding = "UTF-8")
        cat(paste0("SUCCESS:", nrow(df), ":", ncol(df)))
    }} else {{
        cat("NOT_FOUND:0:0")
    }}
}}, error = function(e) {{
    cat(paste0("ERROR:", e$message))
}})
"""

        with open(r_script, 'w') as f:
            f.write(script_content)

        try:
            creationflags = subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == "win32" else 0
            result = subprocess.run(
                ["Rscript", str(r_script)],
                capture_output=True,
                text=True,
                timeout=timeout,
                creationflags=creationflags
            )

            execution_time = time.time() - start_time
            output = result.stdout.strip()

            if output.startswith("SUCCESS:"):
                parts = output.split(":")
                rows = int(parts[1]) if len(parts) > 1 else 0
                cols = int(parts[2]) if len(parts) > 2 else 0

                # Read column names from cached file
                column_names = []
                if cache_file.exists():
                    try:
                        import pandas as pd
                        df = pd.read_csv(cache_file, nrows=0)
                        column_names = list(df.columns)
                    except:
                        pass

                return PlatformResult(
                    platform="r",
                    indicator=indicator,
                    status=TestStatus.SUCCESS,
                    rows=rows,
                    columns=cols,
                    column_names=column_names,
                    execution_time=execution_time,
                    cache_file=str(cache_file)
                )
            elif output.startswith("NOT_FOUND"):
                return PlatformResult(
                    platform="r",
                    indicator=indicator,
                    status=TestStatus.NOT_FOUND,
                    execution_time=execution_time
                )
            else:
                error_msg = output.replace("ERROR:", "") if output.startswith("ERROR:") else result.stderr
                return PlatformResult(
                    platform="r",
                    indicator=indicator,
                    status=TestStatus.FAILED,
                    execution_time=execution_time,
                    error_message=error_msg
                )

        except subprocess.TimeoutExpired:
            return PlatformResult(
                platform="r",
                indicator=indicator,
                status=TestStatus.TIMEOUT,
                execution_time=time.time() - start_time,
                error_message=f"Timeout after {timeout}s"
            )
        except Exception as e:
            return PlatformResult(
                platform="r",
                indicator=indicator,
                status=TestStatus.FAILED,
                execution_time=time.time() - start_time,
                error_message=str(e)
            )


class StataRunner:
    """Run indicator tests in Stata"""

    def __init__(self, cache_dir: Path):
        self.cache_dir = cache_dir / "stata"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.temp_dir = cache_dir / "stata_temp"
        self.temp_dir.mkdir(parents=True, exist_ok=True)

    def test_indicator(self, indicator: str, filters: QueryFilters = None,
                      timeout: int = 300) -> PlatformResult:
        start_time = time.time()
        filters = filters or QueryFilters()

        # Build cache filename with filter suffix
        cache_suffix = filters.cache_key_suffix()
        cache_file = self.cache_dir / f"{indicator}{cache_suffix}.csv"
        cache_filename = f"{indicator}{cache_suffix}.csv"

        # Check cache first
        if cache_file.exists():
            try:
                import pandas as pd
                # Stata on Windows may produce Latin-1 encoded CSV files
                # Try UTF-8 first, fall back to Latin-1
                try:
                    df = pd.read_csv(cache_file, encoding='utf-8')
                except UnicodeDecodeError:
                    df = pd.read_csv(cache_file, encoding='latin-1')
                return PlatformResult(
                    platform="stata",
                    indicator=indicator,
                    status=TestStatus.CACHED,
                    rows=len(df),
                    columns=len(df.columns),
                    column_names=list(df.columns),
                    execution_time=time.time() - start_time,
                    cache_file=str(cache_file)
                )
            except Exception as e:
                logger.warning(f"Cache read failed for {indicator}: {e}")

        # Create Stata do-file with filter parameters
        cache_path = str(self.cache_dir).replace('\\', '/')
        stata_src = str(REPO_ROOT / "stata").replace('\\', '/')
        do_file = self.temp_dir / f"test_{indicator}{cache_suffix}.do"

        # Build Stata options
        stata_opts = ["nosparse"]
        if filters.countries:
            countries_stata = " ".join(filters.countries)
            stata_opts.append(f"countries({countries_stata})")
        # Stata uses year() with range notation "start:end"
        if filters.start_year and filters.end_year:
            stata_opts.append(f"year({filters.start_year}:{filters.end_year})")
        elif filters.start_year:
            stata_opts.append(f"year({filters.start_year})")
        elif filters.end_year:
            stata_opts.append(f"year({filters.end_year})")
        # Stata uses 'wide' flag (not a parameter)
        if filters.data_format == "wide":
            stata_opts.append("wide")
        # nofilter mode: skip default disaggregation filtering
        if filters.nofilter:
            stata_opts.append("nofilter")

        stata_opts_str = " ".join(stata_opts)

        script_content = f"""
clear all
set more off
capture log close

* Install unicefdata from local dev source
net install unicefdata, from("{stata_src}") all replace force

* Fetch indicator with filter options
capture noisily unicefdata, indicator({indicator}) {stata_opts_str} clear

if _rc == 0 {{
    qui describe
    local nobs = r(N)
    local nvars = r(k)

    if `nobs' > 0 {{
        export delimited using "{cache_path}/{cache_filename}", replace
        di "SUCCESS:`nobs':`nvars'"
    }}
    else {{
        di "NOT_FOUND:0:0"
    }}
}}
else {{
    di "ERROR:rc=" _rc
}}

exit, clear
"""

        with open(do_file, 'w') as f:
            f.write(script_content)

        try:
            stata_exe = r"C:\Program Files\Stata17\StataMP-64.exe"
            if not Path(stata_exe).exists():
                return PlatformResult(
                    platform="stata",
                    indicator=indicator,
                    status=TestStatus.SKIPPED,
                    execution_time=0,
                    error_message="Stata not found"
                )

            creationflags = subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == "win32" else 0
            result = subprocess.run(
                [stata_exe, "/e", "do", str(do_file)],
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=str(self.temp_dir),
                creationflags=creationflags
            )

            execution_time = time.time() - start_time

            # Check if CSV was created
            if cache_file.exists() and cache_file.stat().st_size > 0:
                try:
                    import pandas as pd
                    # Stata on Windows may produce Latin-1 encoded CSV files
                    try:
                        df = pd.read_csv(cache_file, encoding='utf-8')
                    except UnicodeDecodeError:
                        df = pd.read_csv(cache_file, encoding='latin-1')
                    return PlatformResult(
                        platform="stata",
                        indicator=indicator,
                        status=TestStatus.SUCCESS,
                        rows=len(df),
                        columns=len(df.columns),
                        column_names=list(df.columns),
                        execution_time=execution_time,
                        cache_file=str(cache_file)
                    )
                except Exception as e:
                    pass

            return PlatformResult(
                platform="stata",
                indicator=indicator,
                status=TestStatus.NOT_FOUND,
                execution_time=execution_time,
                error_message="No data exported"
            )

        except subprocess.TimeoutExpired:
            return PlatformResult(
                platform="stata",
                indicator=indicator,
                status=TestStatus.TIMEOUT,
                execution_time=time.time() - start_time,
                error_message=f"Timeout after {timeout}s"
            )
        except Exception as e:
            return PlatformResult(
                platform="stata",
                indicator=indicator,
                status=TestStatus.FAILED,
                execution_time=time.time() - start_time,
                error_message=str(e)
            )


# =============================================================================
# Cross-Platform Consistency Checker
# =============================================================================

class ConsistencyChecker:
    """Check consistency across platforms using configurable column validation"""

    def __init__(self, loader: 'GoldenIndicatorLoader', row_tolerance_pct: float = 5.0,
                 column_mode: str = None):
        self.loader = loader
        self.row_tolerance_pct = row_tolerance_pct
        self.column_mode = column_mode or loader.column_mode

    def check(self, results: Dict[str, PlatformResult],
              indicator_key: str = None) -> CrossPlatformResult:
        """
        Check consistency across platform results.

        Validates:
        1. Required columns based on column_mode (critical/standard/indicator)
        2. Row counts within tolerance (±5% default)
        3. Total column counts (informational only)

        Args:
            results: Dict of platform name -> PlatformResult
            indicator_key: YAML key for indicator (e.g., "NT_ANT_HAZ_NE2_nofilter")
                          Used for expected_columns lookup. Falls back to
                          PlatformResult.indicator if not provided.
        """
        # Use indicator_key for column lookup, fall back to actual indicator code
        indicator_code = list(results.values())[0].indicator if results else "unknown"
        lookup_key = indicator_key or indicator_code
        xp_result = CrossPlatformResult(indicator=indicator_code, platforms=results)

        # Get required columns based on mode - use lookup_key for config lookup
        required_cols = self.loader.get_columns_for_mode(self.column_mode, lookup_key)

        # Get successful results only
        successful = {k: v for k, v in results.items()
                     if v.status in [TestStatus.SUCCESS, TestStatus.CACHED]}

        if len(successful) < 2:
            xp_result.notes.append(f"Only {len(successful)} platforms succeeded")
            xp_result.is_consistent = len(successful) == len(results)
            return xp_result

        # Check row consistency with tolerance
        row_counts = {k: v.rows for k, v in successful.items()}
        max_rows = max(row_counts.values())
        min_rows = min(row_counts.values())

        if max_rows > 0:
            row_diff_pct = ((max_rows - min_rows) / max_rows) * 100
            if row_diff_pct > self.row_tolerance_pct:
                xp_result.row_mismatch = True
                xp_result.notes.append(
                    f"Row mismatch: {row_counts} (diff: {row_diff_pct:.1f}%)"
                )

        # Check REQUIRED columns (from indicator-specific config)
        has_missing_required = False
        for platform, result in successful.items():
            present_cols = set(result.column_names)
            missing_required = required_cols - present_cols

            if missing_required:
                has_missing_required = True
                xp_result.missing_required_columns[platform] = sorted(missing_required)
                xp_result.notes.append(
                    f"{platform} missing required: {sorted(missing_required)}"
                )

        if has_missing_required:
            xp_result.core_column_mismatch = True

        # Total column count (informational only, not a failure)
        col_counts = {k: v.columns for k, v in successful.items()}
        if len(set(col_counts.values())) > 1:
            xp_result.column_mismatch = True
            xp_result.notes.append(f"Column counts differ (expected): {col_counts}")

        # Final consistency determination
        # Consistent = no row mismatch AND no missing required columns
        xp_result.is_consistent = (
            not xp_result.row_mismatch and
            not has_missing_required
        )

        return xp_result


# =============================================================================
# Report Generator
# =============================================================================

class ReportGenerator:
    """Generate validation reports"""

    def __init__(self, results: List[CrossPlatformResult], output_dir: Path,
                 filters: QueryFilters = None):
        self.results = results
        self.output_dir = output_dir
        self.filters = filters or QueryFilters()
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate_all(self):
        self.generate_json()
        self.generate_markdown()

    def generate_json(self):
        data = {
            "generated": datetime.now().isoformat(),
            "total_indicators": len(self.results),
            "consistent_count": sum(1 for r in self.results if r.is_consistent),
            "filters": {
                "countries": self.filters.countries,
                "start_year": self.filters.start_year,
                "end_year": self.filters.end_year,
                "data_format": self.filters.data_format
            },
            "results": [r.to_dict() for r in self.results]
        }

        json_file = self.output_dir / "results.json"
        with open(json_file, 'w') as f:
            json.dump(data, f, indent=2)

        logger.info(f"JSON report: {json_file}")

    def generate_markdown(self):
        consistent = sum(1 for r in self.results if r.is_consistent)
        total = len(self.results)

        md = f"""# Cross-Platform Validation (xval) Report

**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Summary

- **Total indicators tested**: {total}
- **Consistent across platforms**: {consistent} ({consistent/total*100:.1f}%)
- **Inconsistent**: {total - consistent}

## Results by Indicator

| Indicator | Python | R | Stata | Consistent | Notes |
|-----------|--------|---|-------|------------|-------|
"""

        for result in self.results:
            py = result.platforms.get('python')
            r = result.platforms.get('r')
            stata = result.platforms.get('stata')

            py_status = f"{py.status.value} ({py.rows})" if py else "N/A"
            r_status = f"{r.status.value} ({r.rows})" if r else "N/A"
            stata_status = f"{stata.status.value} ({stata.rows})" if stata else "N/A"

            consistent_mark = "✅" if result.is_consistent else "❌"
            notes = "; ".join(result.notes[:2]) if result.notes else ""

            md += f"| {result.indicator} | {py_status} | {r_status} | {stata_status} | {consistent_mark} | {notes} |\n"

        loader = GoldenIndicatorLoader()

        # Build filter info section
        filter_info = ""
        if self.filters.is_filtered():
            filter_info = f"""
## Query Filters

- **Countries**: {', '.join(self.filters.countries) if self.filters.countries else 'All'}
- **Years**: {f'{self.filters.start_year}-{self.filters.end_year}' if self.filters.start_year and self.filters.end_year else 'All'}
- **Data format**: {self.filters.data_format}
"""
        else:
            filter_info = """
## Query Filters

No filters applied (full data fetch).
"""

        md += filter_info
        md += f"""
## Consistency Rules

Column validation mode: **{loader.column_mode}**

| Mode | Columns | Platforms |
|------|---------|-----------|
| common_core | {len(loader.common_core)} | All (Python, R, Stata) |
| standard | {len(loader.standard_columns)} | Python + R only |
| indicator | Per-indicator | Varies |

- Row counts must match within ±5% tolerance
- Required columns (per mode) must be present
- Extra platform-specific columns are ignored (not a failure)

## Files

- `results.json` - Machine-readable results
- Platform cache: `validation/cache/{{python,r,stata}}/`
"""

        md_file = self.output_dir / "SUMMARY.md"
        with open(md_file, 'w', encoding='utf-8') as f:
            f.write(md)

        logger.info(f"Markdown report: {md_file}")


# =============================================================================
# Main Orchestrator
# =============================================================================

class XvalRunner:
    """Main cross-validation orchestrator"""

    def __init__(self, platforms: List[str] = None, cache_dir: Path = CACHE_DIR,
                 column_mode: str = None, filters: QueryFilters = None):
        self.platforms = platforms or ['python', 'r', 'stata']
        self.cache_dir = cache_dir

        # Initialize runners
        self.runners = {}
        if 'python' in self.platforms:
            self.runners['python'] = PythonRunner(cache_dir)
        if 'r' in self.platforms:
            self.runners['r'] = RRunner(cache_dir)
        if 'stata' in self.platforms:
            self.runners['stata'] = StataRunner(cache_dir)

        # Load golden indicators
        self.loader = GoldenIndicatorLoader()

        # Determine filters (CLI override > config default)
        if filters is None:
            self.filters = self.loader.get_filters_from_config()
        else:
            self.filters = filters

        if self.filters.is_filtered():
            logger.info(f"Query filters: {self.filters.summary()}")
        else:
            logger.info("Query filters: none (fetching all data)")

        # Determine column mode (CLI override > config default)
        effective_column_mode = column_mode or self.loader.column_mode
        logger.info(f"Column validation mode: {effective_column_mode}")

        self.checker = ConsistencyChecker(
            loader=self.loader,
            row_tolerance_pct=self.loader.test_config.get('row_tolerance_percent', 5.0),
            column_mode=effective_column_mode
        )

    def run(self, indicators: Dict = None, quick: bool = False) -> List[CrossPlatformResult]:
        """
        Run cross-validation on indicators.

        Args:
            indicators: Dict of indicators to test (default: all golden)
            quick: If True, test only critical indicators
        """
        if indicators is None:
            if quick:
                indicators = self.loader.get_critical_indicators(limit=5)
                logger.info(f"Quick mode: testing {len(indicators)} critical indicators")
            else:
                indicators = self.loader.get_indicators()
                logger.info(f"Full mode: testing {len(indicators)} golden indicators")

        results = []
        total = len(indicators) * len(self.platforms)
        count = 0

        for indicator_key in indicators:
            # Check if there's an indicator_code override (for nofilter tests etc.)
            ind_config = indicators.get(indicator_key, {})
            indicator_code = ind_config.get('indicator_code', indicator_key)

            logger.info(f"\n{'='*60}")
            logger.info(f"Testing: {indicator_key}")
            if indicator_code != indicator_key:
                logger.info(f"  (indicator_code: {indicator_code})")
            logger.info(f"{'='*60}")

            # Get per-indicator filters (falls back to global if not defined)
            indicator_filters = self.loader.get_indicator_filters(indicator_key, self.filters)
            if indicator_filters.is_filtered() or indicator_filters.nofilter:
                filter_summary = indicator_filters.summary()
                if indicator_filters.nofilter:
                    filter_summary = f"{filter_summary}, nofilter" if filter_summary else "nofilter"
                logger.info(f"  Filters: {filter_summary}")

            platform_results = {}

            for platform, runner in self.runners.items():
                count += 1
                logger.info(f"  [{count}/{total}] {platform}...")

                # Pass indicator-specific filters to each platform runner
                result = runner.test_indicator(indicator_code, filters=indicator_filters)
                platform_results[platform] = result

                status_icon = "✓" if result.status in [TestStatus.SUCCESS, TestStatus.CACHED] else "✗"
                logger.info(f"    {status_icon} {result.status.value} ({result.rows} rows, {result.execution_time:.1f}s)")

            # Check cross-platform consistency
            # Pass indicator_key for correct expected_columns lookup (handles nofilter tests)
            xp_result = self.checker.check(platform_results, indicator_key=indicator_key)
            results.append(xp_result)

            consistency_icon = "✅" if xp_result.is_consistent else "❌"
            logger.info(f"  Consistent: {consistency_icon}")

        return results


# =============================================================================
# CLI Entry Point
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Cross-Platform Validation (xval) - Deterministic testing with golden indicators",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python run_xval.py                      # Test all golden indicators
  python run_xval.py --quick              # Test 5 critical indicators
  python run_xval.py --indicator CME_MRY0T4  # Test specific indicator
  python run_xval.py --platforms python r    # Skip Stata
  python run_xval.py --force-fresh        # Ignore cache, fetch fresh

Filter examples (for stable, deterministic tests):
  python run_xval.py --preset minimal     # 5 countries, 3 years
  python run_xval.py --preset standard    # 10 countries, 6 years
  python run_xval.py --countries USA GBR IND --start-year 2018 --end-year 2020
  python run_xval.py --data-format wide   # Test wide format output
        """
    )

    parser.add_argument("--quick", action="store_true",
                       help="Quick mode: test only 5 critical indicators")
    parser.add_argument("--indicator", type=str,
                       help="Test specific indicator only")
    parser.add_argument("--platforms", nargs="+", default=["python", "r", "stata"],
                       choices=["python", "r", "stata"],
                       help="Platforms to test (default: all)")
    parser.add_argument("--force-fresh", action="store_true",
                       help="Force fresh fetch, ignore cache")
    parser.add_argument("--column-mode", type=str,
                       choices=["common_core", "standard", "indicator"],
                       default=None,
                       help="Column validation mode: common_core (15 cols, all platforms), "
                            "standard (21 cols, Python+R), indicator (per-indicator required)")
    parser.add_argument("--verbose", action="store_true",
                       help="Enable verbose output")

    # Filter arguments for stable, deterministic tests
    filter_group = parser.add_argument_group('Query Filters',
                       'Restrict queries for faster, more stable tests')
    filter_group.add_argument("--preset", type=str,
                       choices=["minimal", "standard", "comprehensive"],
                       help="Use predefined filter preset (overrides --countries/--years)")
    filter_group.add_argument("--countries", nargs="+", type=str,
                       help="ISO3 country codes to test (e.g., USA GBR IND)")
    filter_group.add_argument("--start-year", type=int,
                       help="Start year for data (e.g., 2015)")
    filter_group.add_argument("--end-year", type=int,
                       help="End year for data (e.g., 2020)")
    filter_group.add_argument("--data-format", type=str,
                       choices=["long", "wide"], default=None,
                       help="Data format: long (default) or wide (years as columns)")

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Setup output directory
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = RESULTS_DIR / timestamp

    # Build QueryFilters from CLI args
    filters = None
    if args.preset:
        # Use preset (overrides individual filter args)
        loader = GoldenIndicatorLoader()
        preset = loader.get_stable_preset(args.preset)
        if preset:
            years = preset.get('years', {})
            filters = QueryFilters(
                countries=preset.get('countries'),
                start_year=years.get('start'),
                end_year=years.get('end'),
                data_format=args.data_format or 'long'
            )
        else:
            logger.warning(f"Preset '{args.preset}' not found, using defaults")
    elif args.countries or args.start_year or args.end_year or args.data_format:
        # Use individual filter args
        filters = QueryFilters(
            countries=args.countries,
            start_year=args.start_year,
            end_year=args.end_year,
            data_format=args.data_format or 'long'
        )
    # If filters is None, XvalRunner will use config defaults

    # Determine column mode for display
    column_mode_display = args.column_mode or "indicator (default)"

    # Determine filter display
    if filters:
        filter_display = filters.summary()
    else:
        filter_display = "from config (or none)"

    print("\n" + "="*70)
    print("XVAL - Cross-Platform Validation Framework")
    print("="*70)
    print(f"Platforms: {', '.join(args.platforms)}")
    print(f"Mode: {'Quick (critical only)' if args.quick else 'Full (all golden)'}")
    print(f"Column validation: {column_mode_display}")
    print(f"Query filters: {filter_display}")
    print(f"Output: {output_dir}")
    print("="*70 + "\n")

    # Clear cache if force-fresh
    if args.force_fresh:
        logger.info("Force-fresh mode: clearing cache...")
        for platform in args.platforms:
            cache_path = CACHE_DIR / platform
            if cache_path.exists():
                for f in cache_path.glob("*.csv"):
                    f.unlink()

    # Run validation
    runner = XvalRunner(platforms=args.platforms, column_mode=args.column_mode, filters=filters)

    if args.indicator:
        # Test single indicator
        indicators = {args.indicator: {"name": args.indicator}}
    else:
        indicators = None  # Use defaults based on --quick flag

    results = runner.run(indicators=indicators, quick=args.quick)

    # Generate reports (pass the actual filters used by the runner)
    reporter = ReportGenerator(results, output_dir, filters=runner.filters)
    reporter.generate_all()

    # Summary
    consistent = sum(1 for r in results if r.is_consistent)
    total = len(results)

    print("\n" + "="*70)
    print("XVAL COMPLETE")
    print("="*70)
    print(f"Results: {consistent}/{total} indicators consistent ({consistent/total*100:.1f}%)")
    print(f"Report: {output_dir / 'SUMMARY.md'}")
    print("="*70 + "\n")

    # Exit with error if any inconsistencies (for CI)
    sys.exit(0 if consistent == total else 1)


if __name__ == "__main__":
    main()

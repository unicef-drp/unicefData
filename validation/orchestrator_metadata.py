#!/usr/bin/env python3
"""
orchestrator_metadata.py - Orchestrator to sync metadata for Python, R, and Stata
==================================================================================

This script orchestrates metadata synchronization across all three languages
by calling the standalone sync scripts:
  - sync_metadata_python.py
  - sync_metadata_r.R  
  - sync_metadata_stata.do (and sync_metadata_stataonly.do)

Usage:
    python validation/orchestrator_metadata.py [--python] [--r] [--stata] [--all] [--verbose]

Examples:
    python validation/orchestrator_metadata.py --all          # Sync all languages
    python validation/orchestrator_metadata.py --python       # Python only
    python validation/orchestrator_metadata.py --stata        # Stata only  
    python validation/orchestrator_metadata.py -R             # R only
    python validation/orchestrator_metadata.py --python -R    # Python and R
"""

import sys
import subprocess
import argparse
import shutil
import logging
from pathlib import Path
from datetime import datetime

# Get repository root
SCRIPT_DIR = Path(__file__).parent.resolve()
REPO_ROOT = SCRIPT_DIR.parent
LOG_DIR = SCRIPT_DIR / "logs"

# Ensure log directory exists
LOG_DIR.mkdir(exist_ok=True)

# Configure logging to file and console
log_file = LOG_DIR / "orchestrator_metadata.log"
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        logging.FileHandler(log_file, mode='w', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


def print_header(title: str):
    """Print a formatted header."""
    logger.info("")
    logger.info("=" * 60)
    logger.info(f" {title}")
    logger.info("=" * 60)


def print_section(title: str):
    """Print a section header."""
    logger.info("")
    logger.info(f"[{title}]")
    logger.info("-" * 40)


def find_rscript() -> str | None:
    """Find Rscript executable."""
    rscript = shutil.which("Rscript")
    if rscript:
        return rscript
    
    # Try common R installation paths on Windows
    r_paths = [
        r"C:\Program Files\R\R-4.5.1\bin\Rscript.exe",
        r"C:\Program Files\R\R-4.5.0\bin\Rscript.exe",
        r"C:\Program Files\R\R-4.4.1\bin\Rscript.exe",
        r"C:\Program Files\R\R-4.4.0\bin\Rscript.exe",
        r"C:\Program Files\R\R-4.3.3\bin\Rscript.exe",
    ]
    for path in r_paths:
        if Path(path).exists():
            return path
    return None


def find_stata() -> str | None:
    """Find Stata executable."""
    # Try common Stata installation paths
    stata_paths = [
        r"C:\Program Files\Stata18\StataMP-64.exe",
        r"C:\Program Files\Stata17\StataMP-64.exe",
        r"C:\Program Files\Stata18\StataSE-64.exe",
        r"C:\Program Files\Stata17\StataSE-64.exe",
        r"C:\Program Files\Stata18\Stata-64.exe",
        r"C:\Program Files\Stata17\Stata-64.exe",
    ]
    for path in stata_paths:
        if Path(path).exists():
            return path
    
    # Try PATH
    return shutil.which("stata-mp") or shutil.which("stata-se") or shutil.which("stata")


def sync_python(verbose: bool = False) -> bool:
    """Sync Python metadata by calling sync_metadata_python.py."""
    print_section("Python")
    
    script = SCRIPT_DIR / "sync_metadata_python.py"
    if not script.exists():
        logger.error(f"  ✗ Script not found: {script}")
        return False
    
    logger.info(f"  Running: {script.name}")
    
    cmd = [sys.executable, str(script)]
    if verbose:
        cmd.append("--verbose")
    
    try:
        result = subprocess.run(
            cmd,
            cwd=str(REPO_ROOT),
            timeout=600,  # 10 minute timeout
        )
        
        if result.returncode == 0:
            logger.info("  ✓ Python sync completed successfully")
            return True
        else:
            logger.error(f"  ✗ Python sync failed (exit code {result.returncode})")
            return False
            
    except subprocess.TimeoutExpired:
        logger.error("  ✗ Python sync timed out after 10 minutes")
        return False
    except Exception as e:
        logger.error(f"  ✗ Error: {e}")
        return False


def sync_r(verbose: bool = False) -> bool:
    """Sync R metadata by calling sync_metadata_r.R."""
    print_section("R")
    
    script = SCRIPT_DIR / "sync_metadata_r.R"
    if not script.exists():
        logger.error(f"  ✗ Script not found: {script}")
        return False
    
    rscript = find_rscript()
    if not rscript:
        logger.error("  ✗ Rscript not found in PATH")
        logger.info("    Please install R and ensure Rscript is in your PATH")
        return False
    
    logger.info(f"  Using: {rscript}")
    logger.info(f"  Running: {script.name}")
    
    try:
        result = subprocess.run(
            [rscript, str(script)],
            cwd=str(REPO_ROOT),
            timeout=600,  # 10 minute timeout
        )
        
        if result.returncode == 0:
            logger.info("  ✓ R sync completed successfully")
            return True
        else:
            logger.error(f"  ✗ R sync failed (exit code {result.returncode})")
            return False
            
    except subprocess.TimeoutExpired:
        logger.error("  ✗ R sync timed out after 10 minutes")
        return False
    except Exception as e:
        logger.error(f"  ✗ Error: {e}")
        return False


def sync_stata(verbose: bool = False, stataonly: bool = False) -> bool:
    """Sync Stata metadata by calling sync_metadata_stata.do."""
    print_section("Stata" + (" (pure parser)" if stataonly else ""))
    
    if stataonly:
        script = SCRIPT_DIR / "sync_metadata_stataonly.do"
    else:
        script = SCRIPT_DIR / "sync_metadata_stata.do"
    
    if not script.exists():
        logger.error(f"  ✗ Script not found: {script}")
        return False
    
    stata_exe = find_stata()
    if not stata_exe:
        logger.error("  ✗ Stata executable not found")
        logger.info("    Install Stata or run the .do file manually")
        return False
    
    logger.info(f"  Using: {stata_exe}")
    logger.info(f"  Running: {script.name}")
    
    try:
        result = subprocess.run(
            [stata_exe, "/e", "do", str(script)],
            cwd=str(REPO_ROOT),
            timeout=600,  # 10 minute timeout
        )
        
        # Check log file for results
        log_name = script.stem + ".log"
        stata_log = SCRIPT_DIR / "logs" / log_name
        
        if stata_log.exists():
            log_content = stata_log.read_text(encoding='utf-8', errors='ignore')
            if verbose:
                logger.info(log_content)
            
            # Check for errors in log
            if "error" in log_content.lower() and "r(" in log_content:
                logger.error("  ✗ Stata sync encountered errors")
                return False
        
        if result.returncode == 0:
            logger.info("  ✓ Stata sync completed successfully")
            return True
        else:
            logger.error(f"  ✗ Stata sync failed (exit code {result.returncode})")
            return False
            
    except subprocess.TimeoutExpired:
        logger.error("  ✗ Stata sync timed out after 10 minutes")
        return False
    except Exception as e:
        logger.error(f"  ✗ Error: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Orchestrate metadata sync for Python, R, and Stata"
    )
    parser.add_argument("--python", action="store_true", help="Sync Python metadata")
    parser.add_argument("--r", "-R", action="store_true", dest="r", help="Sync R metadata")
    parser.add_argument("--stata", action="store_true", help="Sync Stata metadata (Python-assisted)")
    parser.add_argument("--stataonly", action="store_true", help="Sync Stata metadata (pure Stata parser)")
    parser.add_argument("--all", action="store_true", help="Sync all languages (default)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    
    args = parser.parse_args()
    
    # Default to --all if no language specified
    if not any([args.python, args.r, args.stata, args.stataonly]):
        args.all = True
    
    print_header("unicefData Metadata Sync Orchestrator")
    logger.info(f"Repository: {REPO_ROOT}")
    logger.info(f"Timestamp:  {datetime.now().isoformat()}")
    
    results = {}
    
    if args.all or args.python:
        results["Python"] = sync_python(args.verbose)
    
    if args.all or args.r:
        results["R"] = sync_r(args.verbose)
    
    if args.all or args.stata:
        results["Stata"] = sync_stata(args.verbose, stataonly=False)
    
    if args.stataonly:
        results["Stata (pure)"] = sync_stata(args.verbose, stataonly=True)
    
    # Summary
    print_header("Summary")
    
    all_passed = True
    for lang, status in results.items():
        if status is None:
            logger.info(f"  {lang}: SKIPPED")
        elif status:
            logger.info(f"  {lang}: ✓ PASSED")
        else:
            logger.info(f"  {lang}: ✗ FAILED")
            all_passed = False
    
    logger.info("")
    logger.info(f"Log saved to: {log_file}")
    
    if all_passed:
        logger.info("All metadata sync completed successfully!")
        return 0
    else:
        logger.info("Some sync tasks failed. Check logs above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())

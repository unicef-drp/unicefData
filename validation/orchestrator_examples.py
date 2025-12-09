#!/usr/bin/env python3
"""
orchestrator_examples.py - Run examples across all languages
=============================================================

Orchestrates running example scripts for Python, R, and Stata to generate
CSV outputs in validation/data/<language>/ for cross-language validation.

Usage:
    python validation/orchestrator_examples.py --all          # All languages
    python validation/orchestrator_examples.py --python       # Python only
    python validation/orchestrator_examples.py -R             # R only
    python validation/orchestrator_examples.py --stata        # Stata only
    python validation/orchestrator_examples.py --python -R    # Python and R
    python validation/orchestrator_examples.py --example 00   # Specific example
"""

import argparse
import subprocess
import sys
import os
from pathlib import Path
from datetime import datetime

# Paths
SCRIPT_DIR = Path(__file__).parent
BASE_DIR = SCRIPT_DIR.parent
LOG_DIR = SCRIPT_DIR / "logs"

# Example scripts (numbered prefix)
EXAMPLES = [
    "00_quick_start",
    "01_indicator_discovery",
    "02_sdg_indicators",
    "03_data_formats",
    "04_metadata_options",
    "05_advanced_features",
    "06_test_fallback",
]


def log(msg, level="INFO"):
    """Print timestamped log message."""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] [{level}] {msg}")


def run_python_examples(examples=None, verbose=False):
    """Run Python example scripts."""
    log("Running Python examples...")
    
    examples_dir = BASE_DIR / "python" / "examples"
    if not examples_dir.exists():
        log(f"Python examples directory not found: {examples_dir}", "ERROR")
        return False
    
    success = True
    for example in (examples or EXAMPLES):
        script = examples_dir / f"{example}.py"
        if not script.exists():
            log(f"  Skipping {example}.py (not found)", "WARN")
            continue
        
        log(f"  Running {example}.py...")
        try:
            env = os.environ.copy()
            env["PYTHONPATH"] = str(BASE_DIR / "python")
            
            result = subprocess.run(
                [sys.executable, str(script)],
                cwd=str(examples_dir),
                capture_output=not verbose,
                text=True,
                env=env,
                timeout=300  # 5 minute timeout per script
            )
            
            if result.returncode != 0:
                log(f"  {example}.py failed (exit code {result.returncode})", "ERROR")
                if not verbose and result.stderr:
                    print(result.stderr[:500])
                success = False
            else:
                log(f"  {example}.py completed successfully")
                
        except subprocess.TimeoutExpired:
            log(f"  {example}.py timed out", "ERROR")
            success = False
        except Exception as e:
            log(f"  {example}.py error: {e}", "ERROR")
            success = False
    
    return success


def run_r_examples(examples=None, verbose=False):
    """Run R example scripts."""
    log("Running R examples...")
    
    examples_dir = BASE_DIR / "R" / "examples"
    if not examples_dir.exists():
        log(f"R examples directory not found: {examples_dir}", "ERROR")
        return False
    
    # Check if Rscript is available
    try:
        subprocess.run(["Rscript", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        log("Rscript not found. Skipping R examples.", "WARN")
        return False
    
    success = True
    for example in (examples or EXAMPLES):
        script = examples_dir / f"{example}.R"
        if not script.exists():
            log(f"  Skipping {example}.R (not found)", "WARN")
            continue
        
        log(f"  Running {example}.R...")
        try:
            result = subprocess.run(
                ["Rscript", str(script)],
                cwd=str(examples_dir),
                capture_output=not verbose,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                log(f"  {example}.R failed (exit code {result.returncode})", "ERROR")
                if not verbose and result.stderr:
                    print(result.stderr[:500])
                success = False
            else:
                log(f"  {example}.R completed successfully")
                
        except subprocess.TimeoutExpired:
            log(f"  {example}.R timed out", "ERROR")
            success = False
        except Exception as e:
            log(f"  {example}.R error: {e}", "ERROR")
            success = False
    
    return success


def run_stata_examples(examples=None, verbose=False):
    """Run Stata example scripts."""
    log("Running Stata examples...")
    
    examples_dir = BASE_DIR / "stata" / "examples"
    if not examples_dir.exists():
        log(f"Stata examples directory not found: {examples_dir}", "ERROR")
        return False
    
    # Check if Stata is available (try common paths)
    stata_exe = None
    stata_paths = [
        "stata-mp", "stata-se", "stata",  # Unix/Mac
        r"C:\Program Files\Stata18\StataMP-64.exe",
        r"C:\Program Files\Stata17\StataMP-64.exe",
        r"C:\Program Files\Stata18\StataSE-64.exe",
        r"C:\Program Files\Stata17\StataSE-64.exe",
    ]
    
    for path in stata_paths:
        try:
            subprocess.run([path, "-e", "di 1"], capture_output=True, timeout=10)
            stata_exe = path
            break
        except:
            continue
    
    if not stata_exe:
        log("Stata not found. Skipping Stata examples.", "WARN")
        log("Run Stata examples manually: do stata/examples/00_quick_start.do", "INFO")
        return False
    
    success = True
    for example in (examples or EXAMPLES):
        script = examples_dir / f"{example}.do"
        if not script.exists():
            log(f"  Skipping {example}.do (not found)", "WARN")
            continue
        
        log(f"  Running {example}.do...")
        try:
            result = subprocess.run(
                [stata_exe, "-e", f"do {script}"],
                cwd=str(examples_dir),
                capture_output=not verbose,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                log(f"  {example}.do failed (exit code {result.returncode})", "ERROR")
                success = False
            else:
                log(f"  {example}.do completed successfully")
                
        except subprocess.TimeoutExpired:
            log(f"  {example}.do timed out", "ERROR")
            success = False
        except Exception as e:
            log(f"  {example}.do error: {e}", "ERROR")
            success = False
    
    return success


def main():
    parser = argparse.ArgumentParser(
        description="Run example scripts across Python, R, and Stata"
    )
    parser.add_argument("--all", action="store_true", help="Run all languages")
    parser.add_argument("--python", action="store_true", help="Run Python examples")
    parser.add_argument("-R", "--r", action="store_true", help="Run R examples")
    parser.add_argument("--stata", action="store_true", help="Run Stata examples")
    parser.add_argument("--example", help="Run specific example(s), e.g., '00' or '00,02'")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show script output")
    
    args = parser.parse_args()
    
    # Default to --all if no language specified
    if not (args.all or args.python or args.r or args.stata):
        args.all = True
    
    # Filter examples if specified
    examples = None
    if args.example:
        prefixes = args.example.split(",")
        examples = [e for e in EXAMPLES if any(e.startswith(p) for p in prefixes)]
        if not examples:
            log(f"No examples match: {args.example}", "ERROR")
            return 1
    
    # Create log directory
    LOG_DIR.mkdir(exist_ok=True)
    
    log("=" * 60)
    log("UNICEF Data Example Orchestrator")
    log("=" * 60)
    
    results = {}
    
    if args.all or args.python:
        results["Python"] = run_python_examples(examples, args.verbose)
    
    if args.all or args.r:
        results["R"] = run_r_examples(examples, args.verbose)
    
    if args.all or args.stata:
        results["Stata"] = run_stata_examples(examples, args.verbose)
    
    # Summary
    log("")
    log("=" * 60)
    log("SUMMARY")
    log("=" * 60)
    
    for lang, success in results.items():
        status = "OK" if success else "FAILED"
        log(f"  {lang:10s}: {status}")
    
    # Output locations
    log("")
    log("Output directories:")
    log(f"  Python: {SCRIPT_DIR / 'data' / 'python'}")
    log(f"  R:      {SCRIPT_DIR / 'data' / 'r'}")
    log(f"  Stata:  {SCRIPT_DIR / 'data' / 'stata'}")
    
    log("")
    log("To validate outputs, run:")
    log("  python validation/validate_outputs.py --all")
    
    return 0 if all(results.values()) else 1


if __name__ == "__main__":
    sys.exit(main())

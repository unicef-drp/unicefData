#!/usr/bin/env python3
"""
sync_examples_python.py - Run all Python examples
===================================================

Runs all Python example scripts to generate CSV outputs in validation/data/python/

Usage:
    python validation/sync_examples_python.py
    python validation/sync_examples_python.py --verbose
    python validation/sync_examples_python.py --example 00_quick_start
"""

import sys
import os
from pathlib import Path

# Add python package to path
SCRIPT_DIR = Path(__file__).parent
BASE_DIR = SCRIPT_DIR.parent
PYTHON_DIR = BASE_DIR / "python"
sys.path.insert(0, str(PYTHON_DIR))

EXAMPLES_DIR = PYTHON_DIR / "examples"
OUTPUT_DIR = SCRIPT_DIR / "data" / "python"

# Example scripts to run
EXAMPLES = [
    "00_quick_start.py",
    "01_indicator_discovery.py",
    "02_sdg_indicators.py",
    "03_data_formats.py",
    "04_metadata_options.py",
    "05_advanced_features.py",
    "06_test_fallback.py",
]


def run_example(script_name, verbose=False):
    """Run a single example script."""
    script_path = EXAMPLES_DIR / script_name
    
    if not script_path.exists():
        print(f"  [SKIP] {script_name} not found")
        return None
    
    print(f"  Running {script_name}...")
    
    # Save current directory and change to examples dir
    original_dir = os.getcwd()
    os.chdir(EXAMPLES_DIR)
    
    try:
        # Import and run the script
        spec = __import__(script_name[:-3])  # Remove .py extension
        print(f"  [OK] {script_name}")
        return True
    except Exception as e:
        print(f"  [FAIL] {script_name}: {e}")
        if verbose:
            import traceback
            traceback.print_exc()
        return False
    finally:
        os.chdir(original_dir)


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Run Python examples")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed output")
    parser.add_argument("--example", help="Run specific example (without .py)")
    args = parser.parse_args()
    
    print("=" * 60)
    print("Running Python Examples")
    print("=" * 60)
    print(f"Output directory: {OUTPUT_DIR}")
    print()
    
    # Ensure output directory exists
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Filter examples if specified
    examples = EXAMPLES
    if args.example:
        examples = [e for e in EXAMPLES if args.example in e]
        if not examples:
            print(f"No examples match: {args.example}")
            return 1
    
    results = []
    for example in examples:
        result = run_example(example, args.verbose)
        results.append((example, result))
    
    # Summary
    print()
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    
    passed = sum(1 for _, r in results if r is True)
    failed = sum(1 for _, r in results if r is False)
    skipped = sum(1 for _, r in results if r is None)
    
    print(f"  Passed:  {passed}")
    print(f"  Failed:  {failed}")
    print(f"  Skipped: {skipped}")
    print()
    print(f"CSV outputs saved to: {OUTPUT_DIR}")
    
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())

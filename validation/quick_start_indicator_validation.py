#!/usr/bin/env python3
"""
quick_start_indicator_validation.py

Quick-start examples for running indicator validation tests.

Usage:
    python validation/quick_start_indicator_validation.py
"""

import subprocess
import sys
from pathlib import Path

VALIDATION_DIR = Path(__file__).parent
MAIN_SCRIPT = VALIDATION_DIR / "test_all_indicators_comprehensive.py"

def run_example(name, description, args):
    """Run example"""
    print("\n" + "=" * 80)
    print(f"Example: {name}")
    print("=" * 80)
    print(f"Description: {description}")
    print(f"\nCommand: python test_all_indicators_comprehensive.py {' '.join(args)}")
    print("\nRunning...\n")
    
    try:
        result = subprocess.run(
            [sys.executable, str(MAIN_SCRIPT)] + args,
            cwd=VALIDATION_DIR.parent
        )
        if result.returncode == 0:
            print(f"\n✓ Example completed successfully")
        else:
            print(f"\n✗ Example failed with exit code {result.returncode}")
    except KeyboardInterrupt:
        print("\n⚠ Interrupted by user")
    except Exception as e:
        print(f"\n✗ Error: {e}")

def main():
    print("=" * 80)
    print("UNICEF Indicator Validation - Quick Start Examples")
    print("=" * 80)
    
    examples = [
        {
            "name": "Test First 5 Indicators",
            "description": "Quick test with first 5 indicators across all languages (Python, R, Stata). Good for initial validation.",
            "args": ["--limit", "5"]
        },
        {
            "name": "Test Single Indicator (All Languages)",
            "description": "Thoroughly test one specific indicator (CME_MRY0T4) across all three languages to verify consistency.",
            "args": ["--indicators", "CME_MRY0T4"]
        },
        {
            "name": "Test Multiple Indicators (Python Only)",
            "description": "Quick test of 10 indicators in Python only (fast - no R/Stata dependency).",
            "args": ["--languages", "python", "--limit", "10"]
        },
        {
            "name": "Test Specific Region (All Indicators)",
            "description": "Test all indicators for specific countries (USA, CAN, MEX) in 2018.",
            "args": ["--countries", "USA", "CAN", "MEX", "--year", "2018"]
        },
        {
            "name": "Full Comprehensive Test (All Indicators)",
            "description": "Complete test of ALL indicators across all languages. WARNING: This will take 30-60 minutes.",
            "args": []
        }
    ]
    
    print("\nAvailable Examples:\n")
    for i, ex in enumerate(examples, 1):
        print(f"{i}. {ex['name']}")
        print(f"   {ex['description']}")
        print()
    
    # Try to get user input if interactive
    try:
        choice = input("Select example (1-5) or 'q' to quit [default: 1]: ").strip()
        if choice == 'q':
            print("Exiting.")
            return
        
        if not choice:
            choice = "1"
        
        idx = int(choice) - 1
        if 0 <= idx < len(examples):
            ex = examples[idx]
            run_example(ex["name"], ex["description"], ex["args"])
        else:
            print("Invalid choice")
    except (ValueError, EOFError):
        # Running non-interactively - run example 1
        print("Running in non-interactive mode - Example 1")
        ex = examples[0]
        run_example(ex["name"], ex["description"], ex["args"])

if __name__ == "__main__":
    main()

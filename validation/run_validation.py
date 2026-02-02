#!/usr/bin/env python3
"""
UNICEF Data Validation Framework - Main Entry Point

This script runs comprehensive validation of UNICEF indicator metadata and data
availability. CRITICAL: Understand indicator tier classification to interpret results.

ABOUT INDICATOR TIERS:
  Tier 1: Indicators with actual data available (expected to pass validation)
  Tier 2: Indicators officially defined but with NO data (expected to pass with "no data" status)
  Tier 3: Indicators under development (expected to have incomplete metadata)

The most common interpretation error is treating Tier 2 indicators as "failures" when
they actually pass (they have metadata but correctly show no data available).

QUICK START:
  python run_validation.py
  
  This runs the full validation suite and generates results in validation/results/.

UNDERSTANDING YOUR RESULTS:
  
  After validation completes, read these documents in this order:
  
  1. TIER CLASSIFICATION REFERENCE (required first read):
     validation/docs/INDICATOR_TIER_CLASSIFICATION.md
     - Defines what each tier means
     - Shows how to interpret results for each tier
     - Explains why Tier 2 indicators show "no data" (that's correct!)
  
  2. YOUR SPECIFIC VALIDATION RESULTS:
     validation/results/[TIMESTAMP]/README.md
     - Navigation guide for your results
     - Explains what passed and why
     - Shows tier composition of your validation run
  
  3. DETAILED ANALYSIS (if results are unexpected):
     validation/results/[TIMESTAMP]/TIER_CLASSIFICATION_ANALYSIS.md
     - Deep dive into how tiers were classified
     - Examples of indicators in each tier
     - Troubleshooting guide for misinterpretations
  
  4. COMPLETE DOCUMENTATION INDEX (for reference):
     validation/DOCUMENTATION_INDEX.md
     - Master reference with all documents
     - Quick reference tables
     - Command examples for querying metadata

COMMON QUESTIONS ANSWERED IN DOCUMENTATION:
  Q: Why did my indicator fail validation?
     A: See INDICATOR_TIER_CLASSIFICATION.md -> check its tier -> read tier section
  
  Q: ED_LN_R_L2 says "no data" - is this a failure?
     A: No! It's Tier 2. See validation/results/[TIMESTAMP]/README.md section on Tier 2
  
  Q: How do I know what tier my indicator is?
     A: Query the metadata. See INDICATOR_TIER_CLASSIFICATION.md for Stata/Python/query examples

VALIDATION FRAMEWORK FILES:
  validation/run_validation.py     <- You are here (entry point)
  validation/test_*.py             <- Individual test modules
  validation/scripts/               <- Validation logic and utilities
  validation/docs/                  <- Reference documentation
  validation/results/               <- Outputs from validation runs

REPRODUCING VALIDATION:
  From validation/ directory:
  
  python run_validation.py
  
  Results written to: validation/results/[TIMESTAMP]/
  
  Then read: validation/results/[TIMESTAMP]/README.md

DEBUGGING:
  Enable verbose output: python run_validation.py --verbose
  Run specific indicator: python run_validation.py --indicator ED_LN_R_L2
  
  For encoding issues (especially on Windows), ensure Python is using UTF-8:
    set PYTHONIOENCODING=utf-8
    python run_validation.py

RELATED PROJECTS:
  Python metadata scripts: unicefData-dev/python/unicef_api/
  Stata validation code:   unicefData-dev/stata/validation/
  R validation code:       unicefData-dev/R/validation/

For questions, refer to validation/DOCUMENTATION_INDEX.md or docs/INDICATOR_TIER_CLASSIFICATION.md

python scripts/orchestration/orchestrator_indicator_tests.py --limit 10 --seed 42 --languages python r stata --valid-only 2>&1


"""

# Main execution
if __name__ == "__main__":
    import sys
    import os
    import subprocess
    import argparse
    from pathlib import Path
    from datetime import datetime
    
    # Ensure UTF-8 encoding on Windows
    if sys.platform == "win32":
        os.environ["PYTHONIOENCODING"] = "utf-8"
    
    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description="UNICEF Data Validation Framework",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python run_validation.py                    # Default: 10 indicators, all platforms, seed 42
  python run_validation.py --limit 20         # 20 indicators
  python run_validation.py --languages python r   # Only Python and R
  python run_validation.py --seed 123         # Different random seed
  python run_validation.py --verbose          # Show debug output
        """
    )
    parser.add_argument("--limit", type=int, default=10, help="Number of indicators to test (default: 10)")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for reproducibility (default: 42)")
    parser.add_argument("--languages", nargs="+", default=["python", "r", "stata"], 
                       help="Languages to test (default: python r stata)")
    parser.add_argument("--valid-only", action="store_true", default=True,
                       help="Only test Tier 1 indicators (default: True)")
    parser.add_argument("--random-stratified", action="store_true", default=False,
                       help="Use stratified random sampling across dataflow prefixes (default: False)")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output")
    
    args = parser.parse_args()
    
    print("\n" + "="*80)
    print("UNICEF Data Validation Framework - Running Validation")
    print("="*80)
    print("\nConfiguration:")
    print(f"  Indicators:  {args.limit}")
    print(f"  Seed:        {args.seed}")
    print(f"  Languages:   {', '.join(args.languages)}")
    print(f"  Mode:        Tier 1 only (valid indicators)")
    print(f"  Sampling:    {'Stratified by dataflow' if args.random_stratified else 'Sequential'}")
    print(f"  Start time:  {datetime.now().isoformat()}")
    print("\n" + "="*80 + "\n")
    
    # Build orchestrator command
    orchestrator_path = Path(__file__).parent / "scripts" / "orchestration" / "orchestrator_indicator_tests.py"
    
    if not orchestrator_path.exists():
        print(f"ERROR: Orchestrator not found at {orchestrator_path}")
        sys.exit(1)
    
    cmd = [
        sys.executable,
        str(orchestrator_path),
        "--limit", str(args.limit),
        "--seed", str(args.seed),
        "--languages"] + args.languages + ["--valid-only"]
    
    if args.random_stratified:
        cmd.append("--random-stratified")
    
    if args.verbose:
        cmd.append("--verbose")
    
    print(f"Running: {' '.join(cmd)}\n")
    
    # Execute orchestrator with process isolation on Windows
    import sys
    creationflags = subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == "win32" else 0
    try:
        result = subprocess.run(cmd, cwd=Path(__file__).parent, creationflags=creationflags)
        
        if result.returncode == 0:
            print("\n" + "="*80)
            print("[SUCCESS] Validation completed")
            print("="*80 + "\n")
            print("To view results:")
            print("  1. Look in: validation/results/")
            print("  2. Read:    README.md (start here)")
            print("  3. Then:    TIER_CLASSIFICATION_ANALYSIS.md")
            print("\nFor interpretation guidance:")
            print("  • validation/docs/INDICATOR_TIER_CLASSIFICATION.md")
            print("="*80 + "\n")
        else:
            print("\n" + "="*80)
            print(f"[ERROR] Validation failed with exit code {result.returncode}")
            print("="*80 + "\n")
        
        sys.exit(result.returncode)
    except Exception as e:
        print(f"ERROR: Failed to run validation: {e}")
        sys.exit(1)

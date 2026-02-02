#!/usr/bin/env python3
"""
Test Stata verbose URL logging.
Shows the constructed URLs from the Stata unicefdata command with verbose enabled.
"""

import os
import subprocess
from datetime import datetime

STATA_EXE = r"C:\Program Files\Stata17\StataMP-64.exe"
REPO_ROOT = r"C:\GitHub\myados\unicefData-dev"
STATA_DIR = os.path.join(REPO_ROOT, "stata")

# Create results directory
RESULTS_DIR = os.path.join(REPO_ROOT, "validation", "results", "stata_url_test_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
os.makedirs(RESULTS_DIR, exist_ok=True)

TEST_INDICATORS = [
    "ED_MAT_G23",
    "ECD_CHLD_U5_BKS-HM",
    "WS_HCF_H-L",
]

def test_indicator_verbose(indicator: str):
    """Test a single indicator with verbose URL logging."""
    print(f"\n{'='*80}")
    print(f"Testing: {indicator}")
    print(f"{'='*80}")
    
    # Create Stata do-file
    do_path = os.path.join(RESULTS_DIR, f"test_{indicator.replace('-', '_')}.do")
    
    do_code = f"""
clear all
set more off
discard

* Install unicefdata command
net install unicefdata, from("{REPO_ROOT}\\stata") replace

* Fetch with verbose enabled to see URL construction
* Verbose shows:
* - Fetching from URL with constructed disaggregation filters (sex=_T, age=_T, etc.)
* - Dataflow lookup source
* - If fallback occurs, the alternative dataflow URLs tried
unicefdata, indicator({indicator}) verbose clear

* Display summary
di ""
di "Result: " _N " observations"
di "Variables: " c(k)

* Export for analysis
capture export delimited "{RESULTS_DIR}/{indicator}_data.csv", replace
"""
    
    with open(do_path, "w", encoding="utf-8") as f:
        f.write(do_code)
    
    # Run Stata
    print(f"\nRunning Stata with verbose URL logging...")
    print(f"Do-file: {do_path}")
    
    cmd = [STATA_EXE, "/e", "do", do_path]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd=STATA_DIR)
    
    print(f"\nStata Output:")
    print("-" * 80)
    
    # Parse output for URL lines
    for line in proc.stdout.split('\n'):
        # Show important lines
        if any(x in line for x in ['Fetching from:', 'Disaggregation', 'Trying dataflow:', 'URL:', 'Dataflow lookup', 'Result:', 'Variables:']):
            print(line)
    
    print("-" * 80)
    
    # Save full output
    log_path = os.path.join(RESULTS_DIR, f"{indicator}_output.log")
    with open(log_path, "w", encoding="utf-8") as f:
        f.write(proc.stdout)
    
    print(f"Full output saved to: {log_path}")
    
    # Check if CSV was created
    csv_path = os.path.join(RESULTS_DIR, f"{indicator}_data.csv")
    if os.path.exists(csv_path):
        with open(csv_path, "r") as f:
            lines = f.readlines()
        print(f"Data fetched: {len(lines) - 1} rows (excluding header)")
    

def main():
    print("STATA VERBOSE URL LOGGING TEST")
    print("=" * 80)
    print("\nThis script tests the new verbose option in unicefdata that shows")
    print("the actual URLs being constructed with disaggregation filters.")
    print("\nURLs will show:")
    print("  - Full SDMX API endpoint")
    print("  - Disaggregation filters (sex=_T, age=_T, wealth=_T, residence=_T)")
    print("  - Query parameters (format, labels, page size, etc.)")
    print("  - Any fallback dataflows if primary fetch fails")
    print("=" * 80)
    
    for indicator in TEST_INDICATORS:
        try:
            test_indicator_verbose(indicator)
        except Exception as e:
            print(f"ERROR testing {indicator}: {e}")
    
    print("\n" + "=" * 80)
    print("Test complete!")
    print(f"Results saved to: {RESULTS_DIR}")
    print("=" * 80)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Quick single-case test for debugging Stata fetch
"""
import os
import sys
import subprocess
import pandas as pd

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(project_root, 'python'))

from unicef_api import UNICEFSDMXClient

def test_single_indicator():
    # Test Python
    print("=== Python Test ===")
    client = UNICEFSDMXClient()
    df = client.fetch_indicator('NT_CF_MMF')
    print(f"Python: {len(df)} rows")
    
    # Test Stata
    print("\n=== Stata Test ===")
    do_file = os.path.join(project_root, 'internal', 'quick_stata_test.do')
    with open(do_file, 'w') as f:
        f.write("""
clear all
set more off
capture noisily unicefdata, indicator(NT_CF_MMF) clear verbose
if _rc == 0 {
    display "{hline 80}"
    display "SUCCESS: `=_N' observations"
}
else {
    display as error "FAILED with rc = " _rc
}
""")
    
    stata_exe = r"C:\Program Files\Stata17\StataMP-64.exe"
    result = subprocess.run(
        [stata_exe, "/e", "do", do_file],
        cwd=project_root,
        capture_output=True,
        text=True,
        timeout=30
    )
    
    # Read log
    log_file = do_file.replace('.do', '.log')
    if os.path.exists(log_file):
        with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
            log_content = f.read()
        print("Stata log (last 50 lines):")
        print('\n'.join(log_content.split('\n')[-50:]))
    else:
        print("No log file created")

if __name__ == '__main__':
    test_single_indicator()

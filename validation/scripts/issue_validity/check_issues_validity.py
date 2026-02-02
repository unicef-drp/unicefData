#!/usr/bin/env python3
"""
Issue Validity Checker for Cross-Platform Dataset Schema Issues

Validates which issues documented in CROSS_PLATFORM_DATASET_SCHEMA_ISSUES.md
are still active, fixed, or changed.

Issues to check:
1. Duplicate columns in Stata (cause_group + causegroup)
2. Missing dimensions in Python/R (service_type, hcf_type for WS_HCF_H-L)
3. Row count discrepancies across platforms
4. Stata filtering out data (ED_MAT_G23, FD_FOUNDATIONAL_LEARNING)
5. Python-specific row count issues (NT_CF_ISSSF_FL, NT_CF_MMF)
"""

import os
import sys
import json
import time
import shutil
import subprocess
from datetime import datetime
from typing import Dict, Any, Optional, Tuple, List
from pathlib import Path

import pandas as pd

# Ensure we can import the local Python client
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
PYTHON_SRC = os.path.join(REPO_ROOT, "python")
if PYTHON_SRC not in sys.path:
    sys.path.insert(0, PYTHON_SRC)

try:
    from unicef_api.sdmx_client import UNICEFSDMXClient
except Exception as e:
    print(f"ERROR: Could not import UNICEFSDMXClient from {PYTHON_SRC}: {e}")
    sys.exit(1)

# Stata path
STATA_EXE = r"C:\Program Files\Stata17\StataMP-64.exe"
STATA_DIR = os.path.join(REPO_ROOT, "stata")

RESULTS_DIR = os.path.join(REPO_ROOT, "validation", "results", "issue_validity", datetime.now().strftime("%Y%m%d_%H%M%S"))
os.makedirs(RESULTS_DIR, exist_ok=True)

TMP_DIR = os.path.join(RESULTS_DIR, "tmp")
os.makedirs(TMP_DIR, exist_ok=True)

# Color codes for terminal output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"
BOLD = "\033[1m"


def log_message(msg: str, level: str = "INFO"):
    """Print formatted message with timestamp."""
    timestamp = datetime.now().strftime("%H:%M:%S")
    if level == "INFO":
        print(f"{BLUE}[{timestamp} INFO]{RESET} {msg}")
    elif level == "SUCCESS":
        print(f"{GREEN}[{timestamp} ✓]{RESET} {msg}")
    elif level == "ERROR":
        print(f"{RED}[{timestamp} ✗]{RESET} {msg}")
    elif level == "WARNING":
        print(f"{YELLOW}[{timestamp} !]{RESET} {msg}")


def run_stata_fetch(indicator: str, out_csv: str) -> Tuple[bool, Optional[str], int]:
    """Run Stata to fetch an indicator and export CSV.
    
    Returns:
        (success, error_message, row_count)
    """
    do_path = os.path.join(TMP_DIR, f"fetch_{indicator.replace('-', '_')}.do")
    log_path = os.path.join(TMP_DIR, f"fetch_{indicator.replace('-', '_')}.log")
    
    do_content = f"""clear all
set more off
log using "{log_path}", text replace
discard
display "Fetching indicator: {indicator}"
capture noisily unicefdata, indicator({indicator}) clear
if _rc == 0 {{
    display "Success: " _N " observations"
    export delimited "{out_csv}", replace
}} else {{
    display "Error code: " _rc
}}
log close
"""
    
    with open(do_path, 'w') as f:
        f.write(do_content)
    
    try:
        result = subprocess.run(
            [STATA_EXE, "/q", "/e", "do", do_path],
            capture_output=True,
            timeout=120
        )
        
        if not os.path.exists(out_csv):
            return False, f"Output CSV not created for {indicator}", 0
        
        df = pd.read_csv(out_csv)
        return True, None, len(df)
    
    except Exception as e:
        return False, str(e), 0


def run_python_fetch(indicator: str) -> Tuple[bool, Optional[str], int, List[str]]:
    """Run Python to fetch an indicator.
    
    Returns:
        (success, error_message, row_count, columns)
    """
    try:
        client = UNICEFSDMXClient()
        df = client.fetch(indicator, start_year=None, end_year=None, verbose=False)
        return True, None, len(df), list(df.columns)
    except Exception as e:
        return False, str(e), 0, []


def check_issue_1_stata_duplicates(indicator: str = "COD_SELF_HARM") -> Dict[str, Any]:
    """Check Issue 1: Duplicate columns in Stata (code + label).
    
    Expected: Only code columns (lowercase, no duplicates with different cases)
    Actual (broken): Both cause_group AND causegroup, unit_multiplier AND unitmultiplier
    """
    log_message(f"Checking Issue 1: Stata duplicate columns (using {indicator})...", "INFO")
    
    result = {
        "issue": "Stata Duplicate Columns",
        "status": "UNKNOWN",
        "details": {},
        "tested_indicator": indicator
    }
    
    csv_path = os.path.join(TMP_DIR, f"{indicator}.csv")
    success, error, row_count = run_stata_fetch(indicator, csv_path)
    
    if not success:
        result["status"] = "UNABLE_TO_TEST"
        result["error"] = error
        return result
    
    df = pd.read_csv(csv_path)
    columns = list(df.columns)
    
    # Look for patterns: lowercase dimension + CamelCase/mixedCase variant
    duplicates_found = []
    checked_pairs = set()
    
    for col in columns:
        # Check if there's a similar column in different case
        col_lower = col.lower()
        col_no_underscore = col.lower().replace('_', '')
        
        for other_col in columns:
            if col == other_col:
                continue
            
            pair_key = tuple(sorted([col, other_col]))
            if pair_key in checked_pairs:
                continue
            
            # Check for: cause_group vs causegroup pattern
            if col_no_underscore == other_col.lower().replace('_', ''):
                # Verify they're actually different columns (not same data)
                if col != other_col.lower() and col.lower() != other_col:
                    duplicates_found.append((col, other_col))
                    checked_pairs.add(pair_key)
    
    result["rows"] = row_count
    result["total_columns"] = len(columns)
    result["duplicate_column_pairs"] = duplicates_found
    
    if duplicates_found:
        result["status"] = "STILL_VALID"
        log_message(f"  Found {len(duplicates_found)} duplicate column pairs: {duplicates_found}", "ERROR")
    else:
        result["status"] = "FIXED"
        log_message(f"  No duplicate columns found - ISSUE APPEARS FIXED", "SUCCESS")
    
    return result


def check_issue_2_missing_dimensions_ws_hcf(indicator: str = "WS_HCF_H-L") -> Dict[str, Any]:
    """Check Issue 2: Missing dimensions in Python/R for WS_HCF_H-L.
    
    Expected: service_type and hcf_type dimensions present
    Current (broken): Only 269 rows in Python/R vs 1,017 in Stata
    """
    log_message(f"Checking Issue 2: Missing dimensions in Python/R ({indicator})...", "INFO")
    
    result = {
        "issue": "Missing Dimensions in Python/R",
        "status": "UNKNOWN",
        "details": {},
        "tested_indicator": indicator
    }
    
    # Fetch from Python
    py_success, py_error, py_rows, py_cols = run_python_fetch(indicator)
    result["python"] = {
        "success": py_success,
        "error": py_error,
        "rows": py_rows,
        "columns": py_cols
    }
    
    # Fetch from Stata
    csv_path = os.path.join(TMP_DIR, f"{indicator}_stata.csv")
    stata_success, stata_error, stata_rows = run_stata_fetch(indicator, csv_path)
    result["stata"] = {
        "success": stata_success,
        "error": stata_error,
        "rows": stata_rows
    }
    
    if not py_success or not stata_success:
        result["status"] = "UNABLE_TO_TEST"
        return result
    
    # Check for missing dimensions
    missing_dims = []
    expected_dims = ["service_type", "hcf_type"]
    
    for dim in expected_dims:
        if dim not in py_cols:
            missing_dims.append(dim)
    
    result["missing_dimensions"] = missing_dims
    
    # Check row count ratio
    if py_rows > 0:
        ratio = stata_rows / py_rows
        result["row_count_ratio"] = ratio
        result["details"] = {
            "python_rows": py_rows,
            "stata_rows": stata_rows,
            "ratio_stata_to_python": round(ratio, 2),
            "missing_dims": missing_dims
        }
        
        if missing_dims and ratio > 2.0:  # Significant discrepancy
            result["status"] = "STILL_VALID"
            log_message(f"  ISSUE CONFIRMED: Python {py_rows} rows, Stata {stata_rows} rows (ratio: {ratio:.2f}x)", "ERROR")
            log_message(f"  Missing dimensions: {missing_dims}", "ERROR")
        elif missing_dims or ratio > 1.5:
            result["status"] = "PARTIALLY_FIXED"
            log_message(f"  ISSUE STILL PRESENT (but less severe): ratio {ratio:.2f}x", "WARNING")
        else:
            result["status"] = "FIXED"
            log_message(f"  Issue appears FIXED: ratio {ratio:.2f}x", "SUCCESS")
    else:
        result["status"] = "ERROR"
        log_message(f"  Cannot evaluate: Python fetch returned 0 rows", "ERROR")
    
    return result


def check_issue_3_row_discrepancies() -> Dict[str, Any]:
    """Check Issue 3: Row count discrepancies across platforms.
    
    Indicators to check:
    - WS_HCF_H-L: Stata >> Py/R
    - ECD_CHLD_U5_BKS-HM: Stata > Py/R (small)
    - ED_MAT_G23: Py/R > Stata (reverse!)
    - FD_FOUNDATIONAL_LEARNING: Py/R >> Stata (reverse!)
    - NT_CF_ISSSF_FL: Py < R/Stata
    - NT_CF_MMF: Py < R/Stata
    """
    log_message("Checking Issue 3: Row count discrepancies across platforms...", "INFO")
    
    indicators_to_test = [
        ("WS_HCF_H-L", "Stata >> Py/R"),
        ("ECD_CHLD_U5_BKS-HM", "Stata > Py/R (small)"),
        ("ED_MAT_G23", "Py/R > Stata (reverse)"),
        ("FD_FOUNDATIONAL_LEARNING", "Py/R >> Stata (reverse)"),
        ("NT_CF_ISSSF_FL", "Py < R/Stata"),
        ("NT_CF_MMF", "Py < R/Stata")
    ]
    
    result = {
        "issue": "Row Count Discrepancies",
        "status": "UNKNOWN",
        "tested_indicators": [],
        "summary": {}
    }
    
    for indicator, pattern in indicators_to_test:
        log_message(f"  Testing {indicator} (expected pattern: {pattern})...", "INFO")
        
        # Fetch from Python
        py_success, py_error, py_rows, _ = run_python_fetch(indicator)
        
        # Fetch from Stata
        csv_path = os.path.join(TMP_DIR, f"{indicator}_discrepancy.csv")
        stata_success, stata_error, stata_rows = run_stata_fetch(indicator, csv_path)
        
        if py_success and stata_success:
            ratio = stata_rows / py_rows if py_rows > 0 else 0
            status = "MATCH" if stata_rows == py_rows else "MISMATCH"
            result["summary"][indicator] = {
                "python_rows": py_rows,
                "stata_rows": stata_rows,
                "ratio": round(ratio, 2),
                "status": status,
                "expected_pattern": pattern
            }
            log_message(f"    {indicator}: Py={py_rows}, Stata={stata_rows}, ratio={ratio:.2f}x", 
                       "SUCCESS" if status == "MATCH" else "WARNING")
        else:
            result["summary"][indicator] = {
                "status": "ERROR",
                "python_error": py_error if not py_success else None,
                "stata_error": stata_error if not stata_success else None
            }
            log_message(f"    {indicator}: UNABLE TO TEST", "ERROR")
    
    # Determine overall status
    mismatches = sum(1 for v in result["summary"].values() if v.get("status") == "MISMATCH")
    matches = sum(1 for v in result["summary"].values() if v.get("status") == "MATCH")
    errors = sum(1 for v in result["summary"].values() if v.get("status") == "ERROR")
    
    if errors == len(indicators_to_test):
        result["status"] = "UNABLE_TO_TEST"
    elif mismatches > 0:
        result["status"] = "STILL_VALID" if mismatches > 2 else "PARTIALLY_FIXED"
    else:
        result["status"] = "FIXED"
    
    result["tested_count"] = len(indicators_to_test)
    result["matches"] = matches
    result["mismatches"] = mismatches
    result["errors"] = errors
    
    return result


def check_issue_4_encoding_fallback() -> Dict[str, Any]:
    """Check Issue 4: UTF-8 encoding issues and fallback to latin-1.
    
    Indicators affected: ECD_CHLD_U5_BKS-HM, NT_CF_ISSSF_FL
    """
    log_message("Checking Issue 4: UTF-8 encoding fallback behavior...", "INFO")
    
    indicators_to_test = [
        "ECD_CHLD_U5_BKS-HM",
        "NT_CF_ISSSF_FL"
    ]
    
    result = {
        "issue": "UTF-8 Encoding Fallback",
        "status": "UNKNOWN",
        "tested_indicators": {},
        "encoding_issues_found": []
    }
    
    for indicator in indicators_to_test:
        log_message(f"  Testing {indicator}...", "INFO")
        
        try:
            py_success, py_error, py_rows, _ = run_python_fetch(indicator)
            
            if py_success:
                result["tested_indicators"][indicator] = {
                    "status": "SUCCESS",
                    "rows": py_rows,
                    "encoding_issue": "NONE"
                }
                log_message(f"    {indicator}: Fetched {py_rows} rows successfully", "SUCCESS")
            else:
                result["tested_indicators"][indicator] = {
                    "status": "ERROR",
                    "error": py_error,
                    "encoding_issue": "POSSIBLE"
                }
                result["encoding_issues_found"].append(indicator)
                log_message(f"    {indicator}: Error - {py_error}", "ERROR")
        
        except Exception as e:
            result["tested_indicators"][indicator] = {
                "status": "ERROR",
                "error": str(e),
                "encoding_issue": "LIKELY"
            }
            result["encoding_issues_found"].append(indicator)
            log_message(f"    {indicator}: Exception - {e}", "ERROR")
    
    if result["encoding_issues_found"]:
        result["status"] = "ENCODING_ISSUES_DETECTED"
    else:
        result["status"] = "NO_ENCODING_ISSUES"
    
    return result


def generate_report(issues_results: List[Dict[str, Any]]) -> str:
    """Generate comprehensive report of issue validity checks."""
    report = []
    report.append("=" * 80)
    report.append("CROSS-PLATFORM DATASET SCHEMA ISSUES - VALIDITY CHECK REPORT")
    report.append("=" * 80)
    report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("")
    
    # Summary table
    report.append("ISSUES STATUS SUMMARY")
    report.append("-" * 80)
    report.append(f"{'Issue':<40} {'Status':<20} {'Details':<40}")
    report.append("-" * 80)
    
    status_counts = {}
    
    for issue_result in issues_results:
        issue_name = issue_result.get("issue", "Unknown")
        status = issue_result.get("status", "UNKNOWN")
        
        status_counts[status] = status_counts.get(status, 0) + 1
        
        # Get details
        if issue_result.get("duplicate_column_pairs"):
            details = f"{len(issue_result['duplicate_column_pairs'])} duplicate pairs found"
        elif issue_result.get("row_count_ratio"):
            details = f"Ratio: {issue_result['row_count_ratio']:.2f}x"
        elif issue_result.get("mismatches"):
            details = f"{issue_result['mismatches']} mismatches, {issue_result['matches']} matches"
        else:
            details = ""
        
        status_display = f"[{status}]"
        report.append(f"{issue_name:<40} {status_display:<20} {details:<40}")
    
    report.append("")
    report.append("OVERALL SUMMARY")
    report.append("-" * 80)
    for status, count in sorted(status_counts.items()):
        report.append(f"{status}: {count}")
    
    report.append("")
    report.append("DETAILED FINDINGS")
    report.append("-" * 80)
    
    for issue_result in issues_results:
        report.append("")
        report.append(f"Issue: {issue_result.get('issue', 'Unknown')}")
        report.append(f"Status: {issue_result.get('status', 'UNKNOWN')}")
        report.append(json.dumps(issue_result, indent=2, default=str))
    
    report.append("")
    report.append("=" * 80)
    
    return "\n".join(report)


def main():
    """Run all issue validity checks."""
    print(f"\n{BOLD}Cross-Platform Dataset Schema Issues - Validity Checker{RESET}")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Results Directory: {RESULTS_DIR}\n")
    
    all_results = []
    
    # Run all checks
    log_message("=" * 80, "INFO")
    log_message("STARTING ISSUE VALIDITY CHECKS", "INFO")
    log_message("=" * 80, "INFO")
    
    all_results.append(check_issue_1_stata_duplicates())
    all_results.append(check_issue_2_missing_dimensions_ws_hcf())
    all_results.append(check_issue_3_row_discrepancies())
    all_results.append(check_issue_4_encoding_fallback())
    
    # Generate report
    log_message("Generating report...", "INFO")
    report = generate_report(all_results)
    
    # Save report
    report_path = os.path.join(RESULTS_DIR, "issue_validity_report.txt")
    with open(report_path, 'w') as f:
        f.write(report)
    
    # Save JSON results
    json_path = os.path.join(RESULTS_DIR, "issue_validity_results.json")
    with open(json_path, 'w') as f:
        json.dump(all_results, f, indent=2, default=str)
    
    # Print report
    print(report)
    print(f"\n{GREEN}✓ Report saved to: {report_path}{RESET}")
    print(f"{GREEN}✓ JSON results saved to: {json_path}{RESET}")
    print(f"\n{BOLD}Completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{RESET}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Test numerical precision across Python, R, and Stata implementations
Compares floating-point values to ensure consistency across platforms
"""

import pandas as pd
import numpy as np
from pathlib import Path
import json
from datetime import datetime

def compare_numerical_precision():
    """
    Compare numerical variables across Python, R, and Stata outputs
    to detect precision differences or data type issues
    """
    
    # Find latest results
    results_base = Path("validation/results")
    result_dirs = sorted(results_base.glob("indicator_validation_*"))
    
    if not result_dirs:
        print("ERROR: No test results found")
        return
    
    latest_dir = result_dirs[-1]
    py_success = latest_dir / "python" / "success"
    r_success = latest_dir / "r" / "success"
    stata_success = latest_dir / "stata" / "success"
    
    if not all([py_success.exists(), r_success.exists(), stata_success.exists()]):
        print("ERROR: Success folders not found for all languages")
        return
    
    print("=" * 100)
    print("NUMERICAL PRECISION COMPARISON - PYTHON vs R vs STATA")
    print("=" * 100)
    print(f"Results directory: {latest_dir}")
    print()
    
    # Find common indicators across all three platforms
    py_files = set(f.stem for f in py_success.glob("*.csv"))
    r_files = set(f.stem for f in r_success.glob("*.csv"))
    stata_files = set(f.stem for f in stata_success.glob("*.csv"))
    
    common_indicators = py_files & r_files & stata_files
    print(f"Indicators in all three platforms: {len(common_indicators)}")
    print()
    
    # Initialize results tracking
    precision_report = {
        "timestamp": datetime.now().isoformat(),
        "total_common_indicators": len(common_indicators),
        "indicators_tested": [],
        "precision_issues": [],
        "summary": {
            "perfect_match": 0,
            "minor_precision_differences": 0,
            "major_discrepancies": 0,
            "row_count_mismatches": 0,
            "column_mismatches": 0,
        }
    }
    
    issues_found = []
    
    # Test each common indicator
    for idx, indicator in enumerate(sorted(common_indicators)[:50], 1):  # Test first 50 for efficiency
        py_file = py_success / f"{indicator}.csv"
        r_file = r_success / f"{indicator}.csv"
        stata_file = stata_success / f"{indicator}.csv"
        
        try:
            py_df = pd.read_csv(py_file)
            r_df = pd.read_csv(r_file)
            stata_df = pd.read_csv(stata_file)
        except Exception as e:
            issues_found.append({
                "indicator": indicator,
                "issue_type": "read_error",
                "details": str(e)
            })
            continue
        
        # Check row counts
        py_rows = len(py_df)
        r_rows = len(r_df)
        stata_rows = len(stata_df)
        
        if not (py_rows == r_rows == stata_rows):
            issues_found.append({
                "indicator": indicator,
                "issue_type": "row_count_mismatch",
                "python_rows": py_rows,
                "r_rows": r_rows,
                "stata_rows": stata_rows,
            })
            precision_report["summary"]["row_count_mismatches"] += 1
            continue
        
        # Identify numerical columns
        py_numeric_cols = py_df.select_dtypes(include=[np.number]).columns.tolist()
        r_numeric_cols = r_df.select_dtypes(include=[np.number]).columns.tolist()
        stata_numeric_cols = stata_df.select_dtypes(include=[np.number]).columns.tolist()
        
        # Check for column mismatches
        if not (set(py_numeric_cols) == set(r_numeric_cols) == set(stata_numeric_cols)):
            issues_found.append({
                "indicator": indicator,
                "issue_type": "column_mismatch",
                "python_numeric_cols": sorted(py_numeric_cols),
                "r_numeric_cols": sorted(r_numeric_cols),
                "stata_numeric_cols": sorted(stata_numeric_cols),
            })
            precision_report["summary"]["column_mismatches"] += 1
            continue
        
        # Compare numerical values
        indicator_passed = True
        precision_differences = []
        
        for col in py_numeric_cols:
            # Convert to numpy arrays, handling NaN
            py_vals = pd.to_numeric(py_df[col], errors='coerce').values
            r_vals = pd.to_numeric(r_df[col], errors='coerce').values
            stata_vals = pd.to_numeric(stata_df[col], errors='coerce').values
            
            # Check for NaN count differences
            py_nan_count = np.isnan(py_vals).sum()
            r_nan_count = np.isnan(r_vals).sum()
            stata_nan_count = np.isnan(stata_vals).sum()
            
            if not (py_nan_count == r_nan_count == stata_nan_count):
                precision_differences.append({
                    "column": col,
                    "issue": "nan_count_mismatch",
                    "python_nans": int(py_nan_count),
                    "r_nans": int(r_nan_count),
                    "stata_nans": int(stata_nan_count),
                })
                indicator_passed = False
                continue
            
            # Compare non-NaN values
            valid_mask = ~np.isnan(py_vals)
            if valid_mask.sum() > 0:
                py_valid = py_vals[valid_mask]
                r_valid = r_vals[valid_mask]
                stata_valid = stata_vals[valid_mask]
                
                # Calculate precision metrics
                max_abs_diff_py_r = np.max(np.abs(py_valid - r_valid)) if len(py_valid) > 0 else 0
                max_abs_diff_py_stata = np.max(np.abs(py_valid - stata_valid)) if len(py_valid) > 0 else 0
                max_abs_diff_r_stata = np.max(np.abs(r_valid - stata_valid)) if len(r_valid) > 0 else 0
                
                # Check if differences are within tolerance (machine epsilon for floats)
                tolerance = 1e-10
                
                if max_abs_diff_py_r > tolerance or max_abs_diff_py_stata > tolerance or max_abs_diff_r_stata > tolerance:
                    precision_differences.append({
                        "column": col,
                        "max_diff_python_r": float(max_abs_diff_py_r),
                        "max_diff_python_stata": float(max_abs_diff_py_stata),
                        "max_diff_r_stata": float(max_abs_diff_r_stata),
                        "non_null_values": int(valid_mask.sum()),
                    })
                    if max(max_abs_diff_py_r, max_abs_diff_py_stata, max_abs_diff_r_stata) > 0.01:
                        indicator_passed = False
        
        # Record results
        if indicator_passed and not precision_differences:
            precision_report["summary"]["perfect_match"] += 1
            status = "✓ PERFECT MATCH"
        elif precision_differences:
            precision_report["summary"]["minor_precision_differences"] += 1
            status = "⚠ MINOR PRECISION DIFFERENCES"
            issues_found.append({
                "indicator": indicator,
                "issue_type": "precision_difference",
                "details": precision_differences
            })
        else:
            precision_report["summary"]["major_discrepancies"] += 1
            status = "✗ MAJOR DISCREPANCY"
        
        precision_report["indicators_tested"].append({
            "indicator": indicator,
            "status": status,
            "row_count": py_rows,
            "numeric_columns": len(py_numeric_cols)
        })
        
        print(f"[{idx:3d}] {indicator:30s} | Rows: {py_rows:>6d} | Num Cols: {len(py_numeric_cols):>2d} | {status}")
    
    # Print summary
    print()
    print("=" * 100)
    print("SUMMARY STATISTICS")
    print("=" * 100)
    summary = precision_report["summary"]
    print(f"✓ Perfect Match:                {summary['perfect_match']:>3d}")
    print(f"⚠ Minor Precision Differences:  {summary['minor_precision_differences']:>3d}")
    print(f"✗ Major Discrepancies:          {summary['major_discrepancies']:>3d}")
    print(f"✗ Row Count Mismatches:         {summary['row_count_mismatches']:>3d}")
    print(f"✗ Column Mismatches:            {summary['column_mismatches']:>3d}")
    print()
    
    # Print issues in detail
    if issues_found:
        print("=" * 100)
        print("DETAILED ISSUES")
        print("=" * 100)
        
        for i, issue in enumerate(issues_found, 1):
            print(f"\n{i}. Indicator: {issue['indicator']}")
            print(f"   Type: {issue['issue_type']}")
            
            if issue['issue_type'] == 'row_count_mismatch':
                print(f"   Python: {issue['python_rows']} rows")
                print(f"   R:      {issue['r_rows']} rows")
                print(f"   Stata:  {issue['stata_rows']} rows")
            
            elif issue['issue_type'] == 'column_mismatch':
                print(f"   Python columns: {issue['python_numeric_cols']}")
                print(f"   R columns:      {issue['r_numeric_cols']}")
                print(f"   Stata columns:  {issue['stata_numeric_cols']}")
            
            elif issue['issue_type'] == 'precision_difference':
                for detail in issue['details'][:5]:  # Show first 5 columns
                    print(f"   Column: {detail['column']}")
                    if 'max_diff_python_r' in detail:
                        print(f"     Python-R max diff:    {detail['max_diff_python_r']:.2e}")
                        print(f"     Python-Stata max diff: {detail['max_diff_python_stata']:.2e}")
                        print(f"     R-Stata max diff:     {detail['max_diff_r_stata']:.2e}")
                    elif 'issue' in detail:
                        print(f"     Issue: {detail['issue']}")
                        print(f"     Python NaNs: {detail['python_nans']}, R: {detail['r_nans']}, Stata: {detail['stata_nans']}")
    
    # Save detailed report
    output_file = latest_dir / "precision_comparison_report.json"
    with open(output_file, 'w') as f:
        json.dump(precision_report, f, indent=2)
    
    print()
    print(f"Detailed report saved to: {output_file}")
    print()
    
    return precision_report

if __name__ == "__main__":
    compare_numerical_precision()

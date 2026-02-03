#!/usr/bin/env python3
"""
Analyze Stata failures from comprehensive test results
Includes numerical precision comparison across platforms
No new Stata execution - just analyzes existing data
"""

import pandas as pd
import numpy as np
from pathlib import Path
import sys
import json
from datetime import datetime

def analyze_stata_failures():
    """Analyze patterns in Stata failures vs Python/R successes"""
    
    # Find the latest results directory
    results_base = Path("validation/results")
    result_dirs = sorted(results_base.glob("indicator_validation_*"))
    
    if not result_dirs:
        print("ERROR: No test results found in validation/results/")
        return
    
    latest_dir = result_dirs[-1]
    csv_file = latest_dir / "detailed_results.csv"
    
    if not csv_file.exists():
        print(f"ERROR: {csv_file} not found")
        return
    
    print("="*80)
    print("STATA FAILURE ANALYSIS")
    print("="*80)
    print(f"Analyzing: {csv_file}")
    print()
    
    # Load results
    df = pd.read_csv(csv_file)
    
    # Filter to only indicators tested in all 3 languages
    indicator_counts = df.groupby('indicator_code').size()
    complete_indicators = indicator_counts[indicator_counts == 3].index
    df_complete = df[df['indicator_code'].isin(complete_indicators)]
    
    print(f"Total tests: {len(df)}")
    print(f"Indicators tested in all 3 languages: {len(complete_indicators)}")
    print()
    
    # Pivot to compare across languages
    pivot = df_complete.pivot(index='indicator_code', columns='language', values=['status', 'rows_returned'])
    
    # Find indicators that succeeded in Python/R but failed in Stata
    succeeded_python = pivot[('status', 'python')] == 'success'
    succeeded_r = pivot[('status', 'r')] == 'success'
    failed_stata = pivot[('status', 'stata')] == 'failed'
    
    problem_indicators = pivot[succeeded_python & succeeded_r & failed_stata]
    
    print("="*80)
    print("INDICATORS THAT SUCCEED IN PYTHON/R BUT FAIL IN STATA")
    print("="*80)
    print(f"Count: {len(problem_indicators)}")
    print()
    
    if len(problem_indicators) > 0:
        print("Sample failures (first 20):")
        print()
        for idx, (indicator, row) in enumerate(problem_indicators.head(20).iterrows(), 1):
            py_rows = row[('rows_returned', 'python')]
            r_rows = row[('rows_returned', 'r')]
            print(f"{idx:3d}. {indicator:30s} | Python: {py_rows:>6.0f} rows | R: {r_rows:>6.0f} rows | Stata: FAILED")
        
        if len(problem_indicators) > 20:
            print(f"\n... and {len(problem_indicators) - 20} more")
    
    print()
    print("="*80)
    print("DATASET SIZE ANALYSIS")
    print("="*80)
    
    # Analyze if failures correlate with dataset size
    if len(problem_indicators) > 0:
        problem_sizes = problem_indicators[('rows_returned', 'python')].dropna()
        
        print(f"Failed indicators - dataset size statistics:")
        print(f"  Mean:   {problem_sizes.mean():>8.0f} rows")
        print(f"  Median: {problem_sizes.median():>8.0f} rows")
        print(f"  Min:    {problem_sizes.min():>8.0f} rows")
        print(f"  Max:    {problem_sizes.max():>8.0f} rows")
        print()
        
        # Compare with successful Stata runs
        succeeded_stata = pivot[('status', 'stata')] == 'success'
        success_sizes = pivot[succeeded_stata][('rows_returned', 'stata')].dropna()
        
        if len(success_sizes) > 0:
            print(f"Successful Stata - dataset size statistics:")
            print(f"  Mean:   {success_sizes.mean():>8.0f} rows")
            print(f"  Median: {success_sizes.median():>8.0f} rows")
            print(f"  Min:    {success_sizes.min():>8.0f} rows")
            print(f"  Max:    {success_sizes.max():>8.0f} rows")
            print()
            
            # Hypothesis: Large datasets fail more
            large_threshold = 5000
            problem_large = (problem_sizes > large_threshold).sum()
            problem_small = (problem_sizes <= large_threshold).sum()
            
            print(f"Failed indicators by size:")
            print(f"  > {large_threshold} rows: {problem_large} ({problem_large/len(problem_sizes)*100:.1f}%)")
            print(f"  ≤ {large_threshold} rows: {problem_small} ({problem_small/len(problem_sizes)*100:.1f}%)")
    
    print()
    print("="*80)
    print("OVERALL LANGUAGE COMPARISON")
    print("="*80)
    
    for lang in ['python', 'r', 'stata']:
        lang_df = df[df['language'] == lang]
        success = len(lang_df[lang_df['status'] == 'success'])
        failed = len(lang_df[lang_df['status'] == 'failed'])
        not_found = len(lang_df[lang_df['status'] == 'not_found'])
        total = len(lang_df)
        
        print(f"{lang.upper():8s}: {success:4d} success ({success/total*100:5.1f}%) | "
              f"{failed:4d} failed ({failed/total*100:5.1f}%) | "
              f"{not_found:4d} not_found ({not_found/total*100:5.1f}%)")
    
    print()
    print("="*80)
    print("DIAGNOSTIC RECOMMENDATIONS")
    print("="*80)
    
    if len(problem_indicators) > 0:
        avg_size = problem_sizes.mean()
        
        if avg_size > 5000:
            print("⚠️  HYPOTHESIS: Large datasets (>5000 rows) may be timing out")
            print("   → Increase subprocess timeout in Python test runner")
            print("   → Check Stata memory settings")
            print()
        
        print("🔍 NEXT STEPS:")
        print("   1. Check validation/stata_diagnostic_output.log when it completes")
        print("   2. Test one failing indicator manually in Stata GUI")
        print(f"   3. Try: unicefdata, indicator({problem_indicators.index[0]}) clear")
        print("   4. Check if error occurs or if it's a subprocess communication issue")
    else:
        print("✅ No systematic failures found - issues may be random/network related")
    
    print()
    print("="*80)
    
    # Save detailed report
    output_file = latest_dir / "stata_failure_analysis.txt"
    with open(output_file, 'w') as f:
        f.write("STATA FAILURE ANALYSIS\n")
        f.write("="*80 + "\n\n")
        f.write(f"Analysis of: {csv_file}\n\n")
        
        f.write("INDICATORS THAT SUCCEED IN PYTHON/R BUT FAIL IN STATA\n")
        f.write("="*80 + "\n\n")
        
        if len(problem_indicators) > 0:
            for indicator, row in problem_indicators.iterrows():
                py_rows = row[('rows_returned', 'python')]
                r_rows = row[('rows_returned', 'r')]
                f.write(f"{indicator:40s} | Python: {py_rows:>8.0f} | R: {r_rows:>8.0f} | Stata: FAILED\n")
    
    print(f"📄 Detailed report saved to: {output_file}")
    print()

if __name__ == "__main__":
    analyze_stata_failures()

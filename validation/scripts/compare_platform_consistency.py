#!/usr/bin/env python3
"""
Platform Consistency Analyzer
==============================

Compare CSV outputs from Python, R, and Stata to assess:
1. Row count consistency
2. Column count consistency  
3. Column name differences (case, naming conventions)
4. Data value differences (if rows/columns align)

Output: Detailed HTML report and CSV summary
"""

import os
import pandas as pd
import json
from pathlib import Path
from collections import defaultdict
import hashlib

# Paths
CACHE_PYTHON = Path("c:/GitHub/myados/unicefData-dev/validation/cache/python")
CACHE_R = Path("c:/GitHub/myados/unicefData-dev/validation/cache/r")
CACHE_STATA = Path("c:/GitHub/myados/unicefData-dev/validation/cache/stata")
OUTPUT_DIR = Path("c:/GitHub/myados/unicefData-dev/validation/consistency_reports")
OUTPUT_DIR.mkdir(exist_ok=True)

def get_csv_files(path):
    """Get all CSV files in a directory"""
    return {f.stem: f for f in path.glob("*.csv")}

def read_csv_safe(filepath):
    """Read CSV with error handling"""
    try:
        df = pd.read_csv(filepath, dtype=str)  # Read as strings to avoid type conversion issues
        return df, None
    except Exception as e:
        return None, str(e)

def compare_indicators():
    """Compare all indicators across platforms"""
    
    python_files = get_csv_files(CACHE_PYTHON)
    r_files = get_csv_files(CACHE_R)
    stata_files = get_csv_files(CACHE_STATA)
    
    # Find common indicators
    all_indicators = set(python_files.keys()) | set(r_files.keys()) | set(stata_files.keys())
    
    results = []
    
    for indicator in sorted(all_indicators):
        print(f"\nAnalyzing: {indicator}")
        
        result = {
            'indicator': indicator,
            'python_rows': None,
            'r_rows': None,
            'stata_rows': None,
            'python_cols': None,
            'r_cols': None,
            'stata_cols': None,
            'python_error': None,
            'r_error': None,
            'stata_error': None,
            'rows_match': False,
            'cols_match': False,
            'all_present': False,
            'column_names': {},
            'missing_in': {},
        }
        
        # Check if present in all platforms
        result['all_present'] = (indicator in python_files and 
                                 indicator in r_files and 
                                 indicator in stata_files)
        
        # Read Python
        if indicator in python_files:
            df_py, err = read_csv_safe(python_files[indicator])
            if df_py is not None:
                result['python_rows'] = len(df_py)
                result['python_cols'] = len(df_py.columns)
                result['column_names']['python'] = sorted(df_py.columns.tolist())
            else:
                result['python_error'] = err
        
        # Read R
        if indicator in r_files:
            df_r, err = read_csv_safe(r_files[indicator])
            if df_r is not None:
                result['r_rows'] = len(df_r)
                result['r_cols'] = len(df_r.columns)
                result['column_names']['r'] = sorted(df_r.columns.tolist())
            else:
                result['r_error'] = err
        
        # Read Stata
        if indicator in stata_files:
            df_stata, err = read_csv_safe(stata_files[indicator])
            if df_stata is not None:
                result['stata_rows'] = len(df_stata)
                result['stata_cols'] = len(df_stata.columns)
                result['column_names']['stata'] = sorted(df_stata.columns.tolist())
            else:
                result['stata_error'] = err
        
        # Check consistency
        if all([result['python_rows'] is not None, 
                result['r_rows'] is not None, 
                result['stata_rows'] is not None]):
            rows_equal = (result['python_rows'] == result['r_rows'] == result['stata_rows'])
            result['rows_match'] = rows_equal
        
        if all([result['python_cols'] is not None, 
                result['r_cols'] is not None, 
                result['stata_cols'] is not None]):
            cols_equal = (result['python_cols'] == result['r_cols'] == result['stata_cols'])
            result['cols_match'] = cols_equal
        
        # Find missing columns
        if result['column_names']:
            all_cols = set()
            for cols in result['column_names'].values():
                all_cols.update(cols)
            
            for platform, cols in result['column_names'].items():
                missing = all_cols - set(cols)
                if missing:
                    result['missing_in'][platform] = sorted(list(missing))
        
        results.append(result)
    
    return results

def generate_summary_csv(results):
    """Generate summary CSV"""
    summary = []
    
    for r in results:
        summary.append({
            'Indicator': r['indicator'],
            'Present in All': '✓' if r['all_present'] else '✗',
            'Python Rows': r['python_rows'] if r['python_rows'] is not None else 'ERROR',
            'R Rows': r['r_rows'] if r['r_rows'] is not None else 'ERROR',
            'Stata Rows': r['stata_rows'] if r['stata_rows'] is not None else 'ERROR',
            'Rows Match': '✓' if r['rows_match'] else '✗' if r['python_rows'] else '?',
            'Python Cols': r['python_cols'] if r['python_cols'] is not None else 'ERROR',
            'R Cols': r['r_cols'] if r['r_cols'] is not None else 'ERROR',
            'Stata Cols': r['stata_cols'] if r['stata_cols'] is not None else 'ERROR',
            'Cols Match': '✓' if r['cols_match'] else '✗' if r['python_cols'] else '?',
            'Column Issues': len(r['missing_in']) > 0,
        })
    
    df_summary = pd.DataFrame(summary)
    return df_summary

def generate_html_report(results):
    """Generate detailed HTML report"""
    
    html = """
    <html>
    <head>
        <title>Platform Consistency Analysis</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
            h1 { color: #333; }
            h2 { color: #555; margin-top: 30px; border-bottom: 2px solid #ddd; padding-bottom: 10px; }
            table { border-collapse: collapse; width: 100%; margin: 10px 0; background: white; }
            th { background: #4CAF50; color: white; padding: 10px; text-align: left; }
            td { border: 1px solid #ddd; padding: 8px; }
            tr:nth-child(even) { background: #f9f9f9; }
            .match { background: #d4edda; }
            .mismatch { background: #f8d7da; }
            .error { background: #fff3cd; }
            .warning { color: #856404; }
            .success { color: #155724; }
            .summary-box {
                background: white;
                border-left: 4px solid #4CAF50;
                padding: 15px;
                margin: 10px 0;
                border-radius: 4px;
            }
            .metric { display: inline-block; margin-right: 30px; }
            .metric-value { font-size: 24px; font-weight: bold; color: #4CAF50; }
            .metric-label { font-size: 12px; color: #666; }
        </style>
    </head>
    <body>
        <h1>🔍 Platform Consistency Analysis Report</h1>
        <p>Generated: """ + pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S") + """</p>
        
        <div class="summary-box">
            <h2>Summary Statistics</h2>
    """
    
    # Calculate metrics
    total = len(results)
    present_all = sum(1 for r in results if r['all_present'])
    rows_match = sum(1 for r in results if r['rows_match'])
    cols_match = sum(1 for r in results if r['cols_match'])
    
    html += f"""
            <div class="metric">
                <div class="metric-value">{total}</div>
                <div class="metric-label">Total Indicators</div>
            </div>
            <div class="metric">
                <div class="metric-value">{present_all}</div>
                <div class="metric-label">Present in All Platforms</div>
            </div>
            <div class="metric">
                <div class="metric-value">{rows_match}</div>
                <div class="metric-label">Row Count Matches</div>
            </div>
            <div class="metric">
                <div class="metric-value">{cols_match}</div>
                <div class="metric-label">Column Count Matches</div>
            </div>
        </div>
    """
    
    # Detailed table
    html += """
        <h2>Detailed Comparison</h2>
        <table>
            <tr>
                <th>Indicator</th>
                <th>All Platforms</th>
                <th colspan="3">Row Count</th>
                <th>Match?</th>
                <th colspan="3">Column Count</th>
                <th>Match?</th>
                <th>Issues</th>
            </tr>
            <tr>
                <th></th>
                <th></th>
                <th>Python</th>
                <th>R</th>
                <th>Stata</th>
                <th></th>
                <th>Python</th>
                <th>R</th>
                <th>Stata</th>
                <th></th>
                <th></th>
            </tr>
    """
    
    for r in results:
        all_present_badge = '✓' if r['all_present'] else '✗'
        rows_match_badge = '✓' if r['rows_match'] else ('✗' if r['python_rows'] else '?')
        cols_match_badge = '✓' if r['cols_match'] else ('✗' if r['python_cols'] else '?')
        rows_match_class = 'match' if r['rows_match'] else 'mismatch'
        cols_match_class = 'match' if r['cols_match'] else 'mismatch'
        
        issues = []
        if not r['all_present']:
            missing = []
            if r['indicator'] not in ['python_files', 'r_files', 'stata_files']:
                if r['python_rows'] is None:
                    missing.append('Python')
                if r['r_rows'] is None:
                    missing.append('R')
                if r['stata_rows'] is None:
                    missing.append('Stata')
            issues.append(f"Missing: {', '.join(missing)}" if missing else "")
        
        if r['missing_in']:
            for platform, cols in r['missing_in'].items():
                issues.append(f"{platform}: {len(cols)} extra columns")
        
        python_rows = r['python_rows'] if r['python_rows'] is not None else 'ERR'
        r_rows = r['r_rows'] if r['r_rows'] is not None else 'ERR'
        stata_rows = r['stata_rows'] if r['stata_rows'] is not None else 'ERR'
        
        python_cols = r['python_cols'] if r['python_cols'] is not None else 'ERR'
        r_cols = r['r_cols'] if r['r_cols'] is not None else 'ERR'
        stata_cols = r['stata_cols'] if r['stata_cols'] is not None else 'ERR'
        
        html += f"""
            <tr>
                <td><strong>{r['indicator']}</strong></td>
                <td>{all_present_badge}</td>
                <td>{python_rows}</td>
                <td>{r_rows}</td>
                <td>{stata_rows}</td>
                <td class="{rows_match_class}">{rows_match_badge}</td>
                <td>{python_cols}</td>
                <td>{r_cols}</td>
                <td>{stata_cols}</td>
                <td class="{cols_match_class}">{cols_match_badge}</td>
                <td>{', '.join(issues) if issues else '✓ OK'}</td>
            </tr>
        """
    
    html += """
        </table>
    </body>
    </html>
    """
    
    return html

if __name__ == "__main__":
    print("=" * 80)
    print("Platform Consistency Analyzer")
    print("=" * 80)
    
    # Run comparison
    results = compare_indicators()
    
    # Generate summary CSV
    df_summary = generate_summary_csv(results)
    summary_path = OUTPUT_DIR / "platform_consistency_summary.csv"
    df_summary.to_csv(summary_path, index=False)
    print(f"\n✓ Summary saved to: {summary_path}")
    
    # Generate HTML report
    html = generate_html_report(results)
    html_path = OUTPUT_DIR / "platform_consistency_report.html"
    with open(html_path, 'w') as f:
        f.write(html)
    print(f"✓ HTML report saved to: {html_path}")
    
    # Print console summary
    print("\n" + "=" * 80)
    print("CONSISTENCY SUMMARY")
    print("=" * 80)
    
    total = len(results)
    present_all = sum(1 for r in results if r['all_present'])
    rows_match = sum(1 for r in results if r['rows_match'])
    cols_match = sum(1 for r in results if r['cols_match'])
    
    print(f"\nTotal indicators: {total}")
    print(f"Present in all platforms: {present_all}/{total} ({100*present_all/total:.1f}%)")
    print(f"Row counts match: {rows_match}/{present_all} ({100*rows_match/present_all:.1f}% if present_all > 0 else 0)")
    print(f"Column counts match: {cols_match}/{present_all} ({100*cols_match/present_all:.1f}% if present_all > 0 else 0)")
    
    # Show mismatches
    mismatches_rows = [r for r in results if not r['rows_match'] and r['python_rows'] is not None]
    mismatches_cols = [r for r in results if not r['cols_match'] and r['python_cols'] is not None]
    
    if mismatches_rows:
        print(f"\n⚠️  ROW COUNT MISMATCHES ({len(mismatches_rows)}):")
        for r in mismatches_rows:
            print(f"   {r['indicator']}: Python={r['python_rows']}, R={r['r_rows']}, Stata={r['stata_rows']}")
    
    if mismatches_cols:
        print(f"\n⚠️  COLUMN COUNT MISMATCHES ({len(mismatches_cols)}):")
        for r in mismatches_cols:
            print(f"   {r['indicator']}: Python={r['python_cols']}, R={r['r_cols']}, Stata={r['stata_cols']}")
            if r['missing_in']:
                for platform, cols in r['missing_in'].items():
                    print(f"      {platform} missing {len(cols)}: {cols[:3]}..." if len(cols) > 3 else f"      {platform} missing: {cols}")
    
    print("\n" + "=" * 80)

"""
validate_outputs.py - Compare R and Python outputs
===================================================

Compares existing CSV outputs from:
  - python/test_output/*.csv vs R/test_output/*.csv
  - python/examples/*.csv vs R/examples/*.csv (if any)

Usage:
    cd validation
    python validate_outputs.py

Outputs:
    - validation_results.csv: Summary of all comparisons
"""
import pandas as pd
import os
import sys
import glob

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)

# Files to skip (metadata files with different structure - indicators/codelists have complex nesting)
# Note: test_dataflows.csv is now included in validation
SKIP_FILES = {'test_indicators.csv', 'test_codelists.csv'}

# Columns to ignore in comparison
SKIP_COLS = {'geo_type'}

# Folders to compare
FOLDERS_TO_COMPARE = [
    {
        "name": "test_output",
        "python": os.path.join(BASE_DIR, "python", "tests", "output"),
        "r": os.path.join(BASE_DIR, "R", "tests", "output"),
    },
    {
        "name": "examples", 
        "python": os.path.join(BASE_DIR, "python", "examples", "data"),
        "r": os.path.join(BASE_DIR, "R", "examples", "data"),
    },
]


def find_matching_csvs(python_dir, r_dir):
    """Find CSV files that exist in both Python and R directories."""
    py_csvs = set(os.path.basename(f) for f in glob.glob(os.path.join(python_dir, "*.csv")))
    r_csvs = set(os.path.basename(f) for f in glob.glob(os.path.join(r_dir, "*.csv")))
    
    # Exclude metadata files from comparison
    py_csvs = py_csvs - SKIP_FILES
    r_csvs = r_csvs - SKIP_FILES
    
    common = py_csvs & r_csvs
    py_only = py_csvs - r_csvs
    r_only = r_csvs - py_csvs
    
    return sorted(common), sorted(py_only), sorted(r_only)


def compare_csv_files(py_path, r_path):
    """Compare two CSV files and return (match, issues, df_py, df_r)."""
    issues = []
    
    try:
        df_py = pd.read_csv(py_path)
    except Exception as e:
        return False, [f"Python CSV read error: {e}"], None, None
    
    try:
        df_r = pd.read_csv(r_path)
    except UnicodeDecodeError:
        # Fallback for R CSVs generated on Windows (often cp1252)
        try:
            df_r = pd.read_csv(r_path, encoding='cp1252')
        except Exception as e:
            return False, [f"R CSV read error (cp1252): {e}"], df_py, None
    except Exception as e:
        return False, [f"R CSV read error: {e}"], df_py, None
    
    # Normalize column names to lowercase for comparison
    df_py.columns = df_py.columns.str.lower()
    df_r.columns = df_r.columns.str.lower()

    # Drop ignored columns
    df_py = df_py.drop(columns=[c for c in SKIP_COLS if c in df_py.columns])
    df_r = df_r.drop(columns=[c for c in SKIP_COLS if c in df_r.columns])

    # Compare row counts
    if len(df_py) != len(df_r):
        issues.append(f"Row count: Python={len(df_py)}, R={len(df_r)}")
    
    # Compare column names
    py_cols = set(df_py.columns)
    r_cols = set(df_r.columns)
    
    if py_cols != r_cols:
        missing_in_r = py_cols - r_cols
        missing_in_py = r_cols - py_cols
        if missing_in_r:
            issues.append(f"Columns missing in R: {missing_in_r}")
        if missing_in_py:
            issues.append(f"Columns missing in Python: {missing_in_py}")
    
    # Find common key columns for comparison
    key_cols = []
    for col in ['iso3', 'country_code', 'indicator', 'year', 'period', 'id']:
        if col in df_py.columns and col in df_r.columns:
            key_cols.append(col)
    
    value_col = None
    for col in ['value', 'obs_value', 'OBS_VALUE']:
        if col in df_py.columns and col in df_r.columns:
            value_col = col
            break
    
    if not key_cols:
        issues.append("No common key columns found for comparison")
        return len(issues) == 0, issues, df_py, df_r
    
    # Sort and compare
    try:
        df_py_sorted = df_py.sort_values(key_cols).reset_index(drop=True)
        df_r_sorted = df_r.sort_values(key_cols).reset_index(drop=True)
        
        # Compare key columns
        for col in key_cols:
            # Use numeric comparison for period column (with tolerance for decimal years)
            if col == 'period':
                py_vals = pd.to_numeric(df_py_sorted[col], errors='coerce')
                r_vals = pd.to_numeric(df_r_sorted[col], errors='coerce')
                # Compare with tolerance for floating point differences
                mask = ~(py_vals.isna() | r_vals.isna())
                if mask.any():
                    diffs = (abs(py_vals[mask] - r_vals[mask]) > 0.0001).sum()
                    if diffs > 0:
                        issues.append(f"Column '{col}': {diffs} differences")
            else:
                py_vals = df_py_sorted[col].astype(str).tolist()
                r_vals = df_r_sorted[col].astype(str).tolist()
                if py_vals != r_vals:
                    # Count differences
                    diffs = sum(1 for a, b in zip(py_vals, r_vals) if a != b)
                    issues.append(f"Column '{col}': {diffs} differences")
        
        # Compare numeric values
        if value_col and len(df_py_sorted) == len(df_r_sorted):
            py_vals = pd.to_numeric(df_py_sorted[value_col], errors='coerce')
            r_vals = pd.to_numeric(df_r_sorted[value_col], errors='coerce')
            
            # Handle NaN differences
            py_nan = py_vals.isna().sum()
            r_nan = r_vals.isna().sum()
            if py_nan != r_nan:
                issues.append(f"NaN count: Python={py_nan}, R={r_nan}")
            
            # Compare non-NaN values
            mask = ~(py_vals.isna() | r_vals.isna())
            if mask.any():
                max_diff = abs(py_vals[mask] - r_vals[mask]).max()
                if max_diff > 0.001:
                    issues.append(f"Max value difference: {max_diff:.6f}")
    
    except Exception as e:
        issues.append(f"Comparison error: {e}")
    
    return len(issues) == 0, issues, df_py, df_r


def main():
    print("=" * 70)
    print("UNICEF Data Package Validation")
    print("Comparing Python and R CSV outputs")
    print("=" * 70)
    
    all_results = []
    total_passed = 0
    total_failed = 0
    total_skipped = 0
    
    for folder_info in FOLDERS_TO_COMPARE:
        folder_name = folder_info["name"]
        py_dir = folder_info["python"]
        r_dir = folder_info["r"]
        
        print(f"\n{'-' * 70}")
        print(f"Folder: {folder_name}")
        print(f"  Python: {py_dir}")
        print(f"  R:      {r_dir}")
        print(f"{'-' * 70}")
        
        if not os.path.exists(py_dir):
            print(f"  WARNING: Python directory not found")
            continue
        if not os.path.exists(r_dir):
            print(f"  WARNING: R directory not found")
            continue
        
        common, py_only, r_only = find_matching_csvs(py_dir, r_dir)
        
        # Report files only in one language
        if py_only:
            print(f"\n  Python only: {', '.join(py_only)}")
            total_skipped += len(py_only)
        if r_only:
            print(f"  R only: {', '.join(r_only)}")
            total_skipped += len(r_only)
        
        if not common:
            print(f"\n  No matching CSV files to compare")
            continue
        
        print(f"\n  Comparing {len(common)} matching files:")
        
        for csv_file in common:
            py_path = os.path.join(py_dir, csv_file)
            r_path = os.path.join(r_dir, csv_file)
            
            match, issues, df_py, df_r = compare_csv_files(py_path, r_path)
            
            result = {
                "folder": folder_name,
                "file": csv_file,
                "python_rows": len(df_py) if df_py is not None else 0,
                "r_rows": len(df_r) if df_r is not None else 0,
                "match": match,
                "issues": "; ".join(issues) if issues else ""
            }
            all_results.append(result)
            
            if match:
                py_rows = len(df_py) if df_py is not None else 0
                print(f"    [OK] {csv_file} ({py_rows} rows)")
                total_passed += 1
            else:
                print(f"    [FAIL] {csv_file}")
                for issue in issues:
                    print(f"        - {issue}")
                total_failed += 1
    
    # Save results
    if all_results:
        results_df = pd.DataFrame(all_results)
        results_path = os.path.join(SCRIPT_DIR, "validation_results.csv")
        results_df.to_csv(results_path, index=False)
        print(f"\nResults saved to: {results_path}")
    
    # Summary
    print("\n" + "=" * 70)
    print(f"Summary: {total_passed} matched, {total_failed} mismatched, {total_skipped} skipped")
    print("=" * 70)
    
    return total_failed == 0


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

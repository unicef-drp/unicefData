"""
validate_outputs.py - Compare Python, R, and Stata outputs
===========================================================

Validates that all language implementations produce consistent results
by comparing CSV outputs from test runs.

Comparison paths:
  - python/tests/output/*.csv
  - R/tests/output/*.csv
  - stata/tests/output/*.csv

Usage:
    cd validation
    python validate_outputs.py              # Python vs R (auto-include Stata if present)
    python validate_outputs.py --python-r   # Only compare Python vs R
    python validate_outputs.py --all        # Compare all three languages

Outputs:
    - validation_results.csv: Summary of all comparisons
"""
import pandas as pd
import os
import sys
import glob
import argparse

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)

# Files to skip (metadata files with different structure)
SKIP_FILES = {'test_indicators.csv', 'test_codelists.csv'}

# Columns to ignore in comparison
SKIP_COLS = {'geo_type'}

# Language configurations
LANGUAGES = {
    "python": {
        "name": "Python",
        "test_output": os.path.join(BASE_DIR, "python", "tests", "output"),
        "examples": os.path.join(SCRIPT_DIR, "data", "python"),
    },
    "r": {
        "name": "R",
        "test_output": os.path.join(BASE_DIR, "R", "tests", "output"),
        "examples": os.path.join(SCRIPT_DIR, "data", "r"),
    },
    "stata": {
        "name": "Stata",
        "test_output": os.path.join(BASE_DIR, "stata", "tests", "output"),
        "examples": os.path.join(SCRIPT_DIR, "data", "stata"),
    },
}


def find_csvs_in_dir(directory):
    """Find CSV files in a directory, excluding skipped files."""
    if not os.path.exists(directory):
        return set()
    csvs = set(os.path.basename(f) for f in glob.glob(os.path.join(directory, "*.csv")))
    return csvs - SKIP_FILES


def compare_csv_files(path1, path2, lang1="file1", lang2="file2"):
    """Compare two CSV files and return (match, issues, df1, df2)."""
    issues = []
    
    # Read first file
    try:
        df1 = pd.read_csv(path1)
    except Exception as e:
        return False, [f"{lang1} CSV read error: {e}"], None, None
    
    # Read second file (try multiple encodings for cross-platform compatibility)
    df2 = None
    for encoding in [None, 'utf-8', 'cp1252', 'latin1']:
        try:
            df2 = pd.read_csv(path2, encoding=encoding)
            break
        except:
            continue
    
    if df2 is None:
        return False, [f"{lang2} CSV read error: could not decode"], df1, None
    
    # Normalize column names to lowercase for comparison
    df1.columns = df1.columns.str.lower()
    df2.columns = df2.columns.str.lower()

    # Drop ignored columns
    df1 = df1.drop(columns=[c for c in SKIP_COLS if c in df1.columns])
    df2 = df2.drop(columns=[c for c in SKIP_COLS if c in df2.columns])

    # Compare row counts
    if len(df1) != len(df2):
        issues.append(f"Row count: {lang1}={len(df1)}, {lang2}={len(df2)}")
    
    # Compare column names
    cols1 = set(df1.columns)
    cols2 = set(df2.columns)
    
    if cols1 != cols2:
        missing_in_2 = cols1 - cols2
        missing_in_1 = cols2 - cols1
        if missing_in_2:
            issues.append(f"Columns missing in {lang2}: {missing_in_2}")
        if missing_in_1:
            issues.append(f"Columns missing in {lang1}: {missing_in_1}")
    
    # Find common key columns for comparison
    key_cols = []
    for col in ['iso3', 'country_code', 'indicator', 'year', 'period', 'id']:
        if col in df1.columns and col in df2.columns:
            key_cols.append(col)
    
    value_col = None
    for col in ['value', 'obs_value', 'OBS_VALUE']:
        if col in df1.columns and col in df2.columns:
            value_col = col
            break
    
    if not key_cols:
        issues.append("No common key columns found for comparison")
        return len(issues) == 0, issues, df1, df2
    
    # Sort and compare
    try:
        df1_sorted = df1.sort_values(key_cols).reset_index(drop=True)
        df2_sorted = df2.sort_values(key_cols).reset_index(drop=True)
        
        # Compare key columns
        for col in key_cols:
            # Use numeric comparison for period column (with tolerance for decimal years)
            if col == 'period':
                vals1 = pd.to_numeric(df1_sorted[col], errors='coerce')
                vals2 = pd.to_numeric(df2_sorted[col], errors='coerce')
                # Compare with tolerance for floating point differences
                mask = ~(vals1.isna() | vals2.isna())
                if mask.any():
                    diffs = (abs(vals1[mask] - vals2[mask]) > 0.0001).sum()
                    if diffs > 0:
                        issues.append(f"Column '{col}': {diffs} differences")
            else:
                vals1 = df1_sorted[col].astype(str).tolist()
                vals2 = df2_sorted[col].astype(str).tolist()
                if vals1 != vals2:
                    # Count differences
                    diffs = sum(1 for a, b in zip(vals1, vals2) if a != b)
                    issues.append(f"Column '{col}': {diffs} differences")
        
        # Compare numeric values
        if value_col and len(df1_sorted) == len(df2_sorted):
            vals1 = pd.to_numeric(df1_sorted[value_col], errors='coerce')
            vals2 = pd.to_numeric(df2_sorted[value_col], errors='coerce')
            
            # Handle NaN differences
            nan1 = vals1.isna().sum()
            nan2 = vals2.isna().sum()
            if nan1 != nan2:
                issues.append(f"NaN count: {lang1}={nan1}, {lang2}={nan2}")
            
            # Compare non-NaN values
            mask = ~(vals1.isna() | vals2.isna())
            if mask.any():
                max_diff = abs(vals1[mask] - vals2[mask]).max()
                if max_diff > 0.001:
                    issues.append(f"Max value difference: {max_diff:.6f}")
    
    except Exception as e:
        issues.append(f"Comparison error: {e}")
    
    return len(issues) == 0, issues, df1, df2


def compare_folder(folder_type, languages_to_compare):
    """Compare CSV files across specified languages for a folder type."""
    results = []
    
    # Get directories and find all CSV files
    dirs = {}
    all_csvs = set()
    for lang in languages_to_compare:
        lang_dir = LANGUAGES[lang].get(folder_type)
        if lang_dir and os.path.exists(lang_dir):
            dirs[lang] = lang_dir
            all_csvs.update(find_csvs_in_dir(lang_dir))
    
    if len(dirs) < 2:
        return results, 0, 0, 0
    
    passed = 0
    failed = 0
    skipped = 0
    
    # Compare each CSV file
    for csv_file in sorted(all_csvs):
        # Find which languages have this file
        lang_paths = {}
        for lang, dir_path in dirs.items():
            path = os.path.join(dir_path, csv_file)
            if os.path.exists(path):
                lang_paths[lang] = path
        
        if len(lang_paths) < 2:
            skipped += 1
            continue
        
        # Pairwise comparisons
        langs = list(lang_paths.keys())
        all_match = True
        all_issues = []
        row_counts = {}
        
        for i, lang1 in enumerate(langs):
            for lang2 in langs[i+1:]:
                match, issues, df1, df2 = compare_csv_files(
                    lang_paths[lang1], lang_paths[lang2],
                    LANGUAGES[lang1]["name"], LANGUAGES[lang2]["name"]
                )
                if df1 is not None:
                    row_counts[lang1] = len(df1)
                if df2 is not None:
                    row_counts[lang2] = len(df2)
                
                if not match:
                    all_match = False
                    all_issues.extend([f"{LANGUAGES[lang1]['name']} vs {LANGUAGES[lang2]['name']}: {iss}" for iss in issues])
        
        result = {
            "folder": folder_type,
            "file": csv_file,
            "languages": ", ".join(sorted(lang_paths.keys())),
            "match": all_match,
            "issues": "; ".join(all_issues) if all_issues else ""
        }
        for lang in languages_to_compare:
            result[f"{lang}_rows"] = row_counts.get(lang, 0)
        
        results.append(result)
        
        if all_match:
            passed += 1
        else:
            failed += 1
    
    return results, passed, failed, skipped


def main():
    parser = argparse.ArgumentParser(description="Validate outputs across Python, R, and Stata")
    parser.add_argument("--python-r", action="store_true", help="Only compare Python vs R")
    parser.add_argument("--all", action="store_true", help="Compare all three languages")
    args = parser.parse_args()
    
    # Determine which languages to compare
    if args.all:
        languages = ["python", "r", "stata"]
    elif args.python_r:
        languages = ["python", "r"]
    else:
        # Default: Python and R (auto-include Stata if output exists)
        languages = ["python", "r"]
        stata_test_dir = LANGUAGES["stata"]["test_output"]
        if os.path.exists(stata_test_dir):
            stata_csvs = find_csvs_in_dir(stata_test_dir)
            if stata_csvs:
                languages.append("stata")
                print("Note: Stata output detected, including in comparison\n")
    
    print("=" * 70)
    print("UNICEF Data Package Validation")
    print(f"Comparing: {', '.join(LANGUAGES[l]['name'] for l in languages)}")
    print("=" * 70)
    
    all_results = []
    total_passed = 0
    total_failed = 0
    total_skipped = 0
    
    for folder_type in ["test_output", "examples"]:
        print(f"\n{'-' * 70}")
        print(f"Folder type: {folder_type}")
        
        # Show paths being compared
        for lang in languages:
            path = LANGUAGES[lang].get(folder_type, "N/A")
            exists = os.path.exists(path) if path != "N/A" else False
            status = "exists" if exists else "missing"
            print(f"  {LANGUAGES[lang]['name']:8s}: {path} [{status}]")
        
        print(f"{'-' * 70}")
        
        results, passed, failed, skipped = compare_folder(folder_type, languages)
        
        all_results.extend(results)
        total_passed += passed
        total_failed += failed
        total_skipped += skipped
        
        if not results:
            print("  No matching files to compare")
            continue
        
        print(f"\n  Comparing {len(results)} files:")
        for r in results:
            if r["match"]:
                rows_info = ", ".join(f"{l}={r.get(f'{l}_rows', 0)}" for l in languages if r.get(f'{l}_rows', 0) > 0)
                print(f"    [OK] {r['file']} ({rows_info})")
            else:
                print(f"    [FAIL] {r['file']}")
                for issue in r["issues"].split("; "):
                    if issue:
                        print(f"        - {issue}")
    
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

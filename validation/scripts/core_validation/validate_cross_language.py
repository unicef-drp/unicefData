#!/usr/bin/env python3
"""
validate_cross_language.py - Robust Cross-Language Validation
===============================================================

Comprehensive validation of CSV outputs across Python, R, and Stata.
Identifies and documents all differences with detailed reporting.

Validation Levels:
    Level 1: Structure   - Files, rows, columns
    Level 2: Core Data   - iso3, indicator, period, value (MUST match)
    Level 3: Metadata    - country names, indicator names
    Level 4: Optional    - Extra columns, footnotes (allowed to differ)

Usage:
    python validation/validate_cross_language.py                    # Full validation
    python validation/validate_cross_language.py --summary          # Summary only
    python validation/validate_cross_language.py --file 00_ex1      # Specific file
    python validation/validate_cross_language.py --report report.md # Save report

Output:
    - Console report with detailed findings
    - Optional markdown report file
    - validation_detailed_results.csv with all comparisons
"""

import argparse
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass, field
import sys

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR / "data"

LANGUAGES = {
    "python": DATA_DIR / "python",
    "r": DATA_DIR / "r",
    "stata": DATA_DIR / "stata",
}

# Core columns that MUST match exactly (case-insensitive)
CORE_COLUMNS = {"iso3", "indicator", "period", "value", "country"}

# Columns to ignore in comparison (known differences)
IGNORE_COLUMNS = {"geo_type"}  # R includes this, Python doesn't

# Tolerance for numeric comparisons
NUMERIC_TOLERANCE = 1e-6
RELATIVE_TOLERANCE = 1e-4


# =============================================================================
# Data Classes for Results
# =============================================================================

@dataclass
class ColumnDiff:
    """Difference in column structure."""
    only_lang1: Set[str] = field(default_factory=set)
    only_lang2: Set[str] = field(default_factory=set)
    case_diffs: List[Tuple[str, str]] = field(default_factory=list)  # (lang1_name, lang2_name)
    common: Set[str] = field(default_factory=set)


@dataclass
class ValueDiff:
    """Difference in column values."""
    column: str
    diff_type: str  # 'numeric', 'string', 'missing'
    n_diffs: int
    max_diff: Optional[float] = None
    examples: List[Tuple[int, str, str]] = field(default_factory=list)  # (row, val1, val2)


@dataclass
class FileComparison:
    """Results of comparing one file between two languages."""
    filename: str
    lang1: str
    lang2: str
    
    # Structure
    rows_lang1: int = 0
    rows_lang2: int = 0
    rows_match: bool = False
    
    # Columns
    column_diff: Optional[ColumnDiff] = None
    columns_match: bool = False
    
    # Values
    value_diffs: List[ValueDiff] = field(default_factory=list)
    core_columns_match: bool = False
    all_values_match: bool = False
    
    # Overall
    status: str = "UNKNOWN"  # PASS, WARN, FAIL, SKIP
    messages: List[str] = field(default_factory=list)


# =============================================================================
# Comparison Functions
# =============================================================================

def normalize_column_name(name: str) -> str:
    """Normalize column name for comparison."""
    return name.lower().strip()


def get_csv_files(directory: Path) -> List[str]:
    """Get list of CSV files in directory."""
    if not directory.exists():
        return []
    return sorted([f.name for f in directory.glob("*.csv")])


def compare_columns(df1: pd.DataFrame, df2: pd.DataFrame) -> ColumnDiff:
    """Compare column structures between two DataFrames."""
    diff = ColumnDiff()
    
    # Original column names
    cols1 = set(df1.columns)
    cols2 = set(df2.columns)
    
    # Normalized column names for matching
    norm1 = {normalize_column_name(c): c for c in cols1}
    norm2 = {normalize_column_name(c): c for c in cols2}
    
    norm_keys1 = set(norm1.keys())
    norm_keys2 = set(norm2.keys())
    
    # Find common columns (by normalized name)
    common_norm = norm_keys1 & norm_keys2
    diff.common = common_norm
    
    # Find columns only in one
    diff.only_lang1 = {norm1[n] for n in (norm_keys1 - norm_keys2)}
    diff.only_lang2 = {norm2[n] for n in (norm_keys2 - norm_keys1)}
    
    # Find case differences in common columns
    for norm_name in common_norm:
        orig1 = norm1[norm_name]
        orig2 = norm2[norm_name]
        if orig1 != orig2:
            diff.case_diffs.append((orig1, orig2))
    
    return diff


def compare_values(df1: pd.DataFrame, df2: pd.DataFrame, 
                   common_cols: Set[str], key_cols: List[str]) -> List[ValueDiff]:
    """Compare values between two DataFrames for common columns."""
    diffs = []
    
    # Create normalized column mapping
    norm_to_orig1 = {normalize_column_name(c): c for c in df1.columns}
    norm_to_orig2 = {normalize_column_name(c): c for c in df2.columns}
    
    # Sort DataFrames by key columns if possible
    available_keys = [k for k in key_cols if k in common_cols]
    
    if available_keys and len(df1) == len(df2):
        try:
            # Use normalized key columns
            key1 = [norm_to_orig1.get(k, k) for k in available_keys if k in norm_to_orig1]
            key2 = [norm_to_orig2.get(k, k) for k in available_keys if k in norm_to_orig2]
            
            if key1 and key2:
                df1_sorted = df1.sort_values(key1).reset_index(drop=True)
                df2_sorted = df2.sort_values(key2).reset_index(drop=True)
            else:
                df1_sorted = df1.reset_index(drop=True)
                df2_sorted = df2.reset_index(drop=True)
        except Exception:
            df1_sorted = df1.reset_index(drop=True)
            df2_sorted = df2.reset_index(drop=True)
    else:
        df1_sorted = df1.reset_index(drop=True)
        df2_sorted = df2.reset_index(drop=True)
    
    # Compare each common column
    for norm_col in sorted(common_cols):
        if norm_col in IGNORE_COLUMNS:
            continue
            
        orig1 = norm_to_orig1.get(norm_col)
        orig2 = norm_to_orig2.get(norm_col)
        
        if orig1 is None or orig2 is None:
            continue
        
        col1 = df1_sorted[orig1]
        col2 = df2_sorted[orig2]
        
        # Handle different lengths
        if len(col1) != len(col2):
            diffs.append(ValueDiff(
                column=norm_col,
                diff_type="length",
                n_diffs=abs(len(col1) - len(col2)),
            ))
            continue
        
        # Compare based on dtype
        if pd.api.types.is_numeric_dtype(col1) and pd.api.types.is_numeric_dtype(col2):
            diff_result = compare_numeric_column(col1, col2, norm_col)
        else:
            diff_result = compare_string_column(col1, col2, norm_col)
        
        if diff_result:
            diffs.append(diff_result)
    
    return diffs


def compare_numeric_column(col1: pd.Series, col2: pd.Series, col_name: str) -> Optional[ValueDiff]:
    """Compare numeric columns with tolerance."""
    # Handle NaN
    nan1 = col1.isna()
    nan2 = col2.isna()
    
    # Check NaN positions match
    nan_mismatch = (nan1 != nan2).sum()
    
    # Compare non-NaN values
    mask = ~nan1 & ~nan2
    if mask.sum() == 0:
        if nan_mismatch > 0:
            return ValueDiff(
                column=col_name,
                diff_type="missing",
                n_diffs=nan_mismatch,
            )
        return None
    
    v1 = col1[mask].values
    v2 = col2[mask].values
    
    abs_diff = np.abs(v1 - v2)
    max_val = np.maximum(np.abs(v1), np.abs(v2))
    
    with np.errstate(divide='ignore', invalid='ignore'):
        rel_diff = np.where(max_val > NUMERIC_TOLERANCE, abs_diff / max_val, abs_diff)
    
    # Check if differences exceed tolerance
    exceeds = (abs_diff > NUMERIC_TOLERANCE) & (rel_diff > RELATIVE_TOLERANCE)
    n_exceeds = exceeds.sum() + nan_mismatch
    
    if n_exceeds == 0:
        return None
    
    # Get examples
    examples = []
    exceed_idx = np.where(exceeds)[0][:3]
    orig_idx = mask[mask].index[exceed_idx]
    for i, idx in enumerate(orig_idx):
        examples.append((int(idx), f"{v1[exceed_idx[i]]:.6f}", f"{v2[exceed_idx[i]]:.6f}"))
    
    return ValueDiff(
        column=col_name,
        diff_type="numeric",
        n_diffs=n_exceeds,
        max_diff=float(abs_diff.max()),
        examples=examples,
    )


def compare_string_column(col1: pd.Series, col2: pd.Series, col_name: str) -> Optional[ValueDiff]:
    """Compare string columns."""
    s1 = col1.fillna("").astype(str).str.strip()
    s2 = col2.fillna("").astype(str).str.strip()
    
    mismatches = s1 != s2
    n_diffs = mismatches.sum()
    
    if n_diffs == 0:
        return None
    
    # Get examples
    examples = []
    mismatch_idx = mismatches[mismatches].index[:3]
    for idx in mismatch_idx:
        v1 = s1.loc[idx][:50]  # Truncate long strings
        v2 = s2.loc[idx][:50]
        examples.append((int(idx), v1, v2))
    
    return ValueDiff(
        column=col_name,
        diff_type="string",
        n_diffs=n_diffs,
        examples=examples,
    )


def compare_files(file1: Path, file2: Path, lang1: str, lang2: str) -> FileComparison:
    """Compare two CSV files comprehensively."""
    result = FileComparison(
        filename=file1.name,
        lang1=lang1,
        lang2=lang2,
    )
    
    # Load files
    if not file1.exists():
        result.status = "SKIP"
        result.messages.append(f"Missing in {lang1}")
        return result
    
    if not file2.exists():
        result.status = "SKIP"
        result.messages.append(f"Missing in {lang2}")
        return result
    
    try:
        df1 = pd.read_csv(file1)
        df2 = pd.read_csv(file2)
    except Exception as e:
        result.status = "FAIL"
        result.messages.append(f"Error loading files: {e}")
        return result
    
    # Compare structure
    result.rows_lang1 = len(df1)
    result.rows_lang2 = len(df2)
    result.rows_match = (result.rows_lang1 == result.rows_lang2)
    
    # Compare columns
    result.column_diff = compare_columns(df1, df2)
    
    # Filter out ignored columns from "only" sets
    result.column_diff.only_lang1 -= IGNORE_COLUMNS
    result.column_diff.only_lang2 -= IGNORE_COLUMNS
    
    result.columns_match = (
        len(result.column_diff.only_lang1) == 0 and
        len(result.column_diff.only_lang2) == 0
    )
    
    # Compare values
    if result.rows_match and result.column_diff.common:
        key_cols = ["iso3", "indicator", "period"]
        result.value_diffs = compare_values(
            df1, df2, result.column_diff.common, key_cols
        )
        
        # Check core columns
        core_diffs = [d for d in result.value_diffs 
                     if d.column in CORE_COLUMNS]
        result.core_columns_match = len(core_diffs) == 0
        result.all_values_match = len(result.value_diffs) == 0
    
    # Determine status
    if not result.rows_match:
        result.status = "FAIL"
        result.messages.append(f"Row count mismatch: {lang1}={result.rows_lang1}, {lang2}={result.rows_lang2}")
    elif not result.core_columns_match:
        result.status = "FAIL"
        core_diffs = [d.column for d in result.value_diffs if d.column in CORE_COLUMNS]
        result.messages.append(f"Core column differences: {core_diffs}")
    elif not result.columns_match or not result.all_values_match:
        result.status = "WARN"
        if not result.columns_match:
            result.messages.append("Column differences (non-core)")
        if not result.all_values_match:
            diff_cols = [d.column for d in result.value_diffs]
            result.messages.append(f"Value differences in: {diff_cols}")
    else:
        result.status = "PASS"
        result.messages.append("All checks passed")
    
    return result


# =============================================================================
# Reporting Functions
# =============================================================================

def format_comparison_report(comparisons: List[FileComparison], 
                             lang1: str, lang2: str,
                             verbose: bool = True) -> str:
    """Format comparison results as a detailed report."""
    lines = []
    
    lines.append("=" * 70)
    lines.append(f"CROSS-LANGUAGE VALIDATION: {lang1.upper()} vs {lang2.upper()}")
    lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("=" * 70)
    
    # Summary counts
    n_pass = sum(1 for c in comparisons if c.status == "PASS")
    n_warn = sum(1 for c in comparisons if c.status == "WARN")
    n_fail = sum(1 for c in comparisons if c.status == "FAIL")
    n_skip = sum(1 for c in comparisons if c.status == "SKIP")
    
    lines.append(f"\nSummary: {n_pass} PASS, {n_warn} WARN, {n_fail} FAIL, {n_skip} SKIP")
    lines.append("-" * 70)
    
    # Detailed results
    for comp in comparisons:
        status_icon = {"PASS": "✓", "WARN": "⚠", "FAIL": "✗", "SKIP": "⊘"}[comp.status]
        lines.append(f"\n{status_icon} {comp.filename} [{comp.status}]")
        
        # Structure
        if comp.rows_match:
            lines.append(f"  Rows: {comp.rows_lang1} (match)")
        else:
            lines.append(f"  Rows: {lang1}={comp.rows_lang1}, {lang2}={comp.rows_lang2} ✗")
        
        # Columns
        if comp.column_diff:
            if comp.columns_match and not comp.column_diff.case_diffs:
                lines.append(f"  Columns: {len(comp.column_diff.common)} (match)")
            else:
                lines.append(f"  Columns: {len(comp.column_diff.common)} common")
                
                if comp.column_diff.only_lang1:
                    lines.append(f"    Only in {lang1}: {sorted(comp.column_diff.only_lang1)}")
                if comp.column_diff.only_lang2:
                    lines.append(f"    Only in {lang2}: {sorted(comp.column_diff.only_lang2)}")
                if comp.column_diff.case_diffs and verbose:
                    lines.append(f"    Case differences: {len(comp.column_diff.case_diffs)}")
                    for c1, c2 in comp.column_diff.case_diffs[:5]:
                        lines.append(f"      {c1} ↔ {c2}")
        
        # Values
        if comp.value_diffs:
            lines.append(f"  Value differences:")
            for vd in comp.value_diffs:
                is_core = "⚠ CORE" if vd.column in CORE_COLUMNS else ""
                if vd.diff_type == "numeric":
                    lines.append(f"    {vd.column}: {vd.n_diffs} diffs (max: {vd.max_diff:.2e}) {is_core}")
                else:
                    lines.append(f"    {vd.column}: {vd.n_diffs} {vd.diff_type} diffs {is_core}")
                
                if verbose and vd.examples:
                    for row, v1, v2 in vd.examples[:2]:
                        lines.append(f"      Row {row}: '{v1}' ↔ '{v2}'")
        elif comp.status != "SKIP":
            lines.append(f"  Values: All match ✓")
        
        # Messages
        if verbose:
            for msg in comp.messages:
                lines.append(f"  → {msg}")
    
    lines.append("\n" + "=" * 70)
    
    # Overall assessment
    if n_fail > 0:
        lines.append("RESULT: VALIDATION FAILED")
        lines.append("  Core data differences detected - investigate immediately")
    elif n_warn > 0:
        lines.append("RESULT: VALIDATION PASSED WITH WARNINGS")
        lines.append("  Non-critical differences found - review recommended")
    else:
        lines.append("RESULT: VALIDATION PASSED")
        lines.append("  All outputs match between languages")
    
    lines.append("=" * 70)
    
    return "\n".join(lines)


def save_results_csv(comparisons: List[FileComparison], output_path: Path):
    """Save detailed results to CSV."""
    rows = []
    for comp in comparisons:
        row = {
            "filename": comp.filename,
            "lang1": comp.lang1,
            "lang2": comp.lang2,
            "status": comp.status,
            "rows_lang1": comp.rows_lang1,
            "rows_lang2": comp.rows_lang2,
            "rows_match": comp.rows_match,
            "columns_match": comp.columns_match,
            "core_match": comp.core_columns_match,
            "values_match": comp.all_values_match,
            "n_value_diffs": len(comp.value_diffs),
            "diff_columns": ", ".join(d.column for d in comp.value_diffs),
            "messages": "; ".join(comp.messages),
        }
        rows.append(row)
    
    df = pd.DataFrame(rows)
    df.to_csv(output_path, index=False, encoding='utf-8')


def save_markdown_report(comparisons: List[FileComparison], 
                         lang1: str, lang2: str,
                         output_path: Path):
    """Save report as markdown file."""
    lines = []
    
    lines.append(f"# Cross-Language Validation Report")
    lines.append(f"\n**Comparing:** {lang1} vs {lang2}")
    lines.append(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Summary table
    lines.append("\n## Summary\n")
    lines.append("| File | Status | Rows | Columns | Core Data | Values |")
    lines.append("|------|--------|------|---------|-----------|--------|")
    
    for comp in comparisons:
        rows = f"{comp.rows_lang1}" if comp.rows_match else f"{comp.rows_lang1}≠{comp.rows_lang2}"
        cols = "✓" if comp.columns_match else "⚠"
        core = "✓" if comp.core_columns_match else "✗"
        vals = "✓" if comp.all_values_match else f"⚠ {len(comp.value_diffs)}"
        lines.append(f"| {comp.filename} | {comp.status} | {rows} | {cols} | {core} | {vals} |")
    
    # Detailed findings
    lines.append("\n## Detailed Findings\n")
    
    for comp in comparisons:
        if comp.status == "SKIP":
            continue
            
        lines.append(f"### {comp.filename}\n")
        lines.append(f"**Status:** {comp.status}\n")
        
        if comp.column_diff:
            if comp.column_diff.only_lang1 or comp.column_diff.only_lang2:
                lines.append("**Column Differences:**")
                if comp.column_diff.only_lang1:
                    lines.append(f"- Only in {lang1}: `{', '.join(sorted(comp.column_diff.only_lang1))}`")
                if comp.column_diff.only_lang2:
                    lines.append(f"- Only in {lang2}: `{', '.join(sorted(comp.column_diff.only_lang2))}`")
                lines.append("")
            
            if comp.column_diff.case_diffs:
                lines.append("**Case Differences:**")
                for c1, c2 in comp.column_diff.case_diffs[:10]:
                    lines.append(f"- `{c1}` ↔ `{c2}`")
                lines.append("")
        
        if comp.value_diffs:
            lines.append("**Value Differences:**")
            lines.append("| Column | Type | Count | Details |")
            lines.append("|--------|------|-------|---------|")
            for vd in comp.value_diffs:
                core_mark = "⚠ CORE" if vd.column in CORE_COLUMNS else ""
                detail = f"max diff: {vd.max_diff:.2e}" if vd.max_diff else ""
                lines.append(f"| {vd.column} | {vd.diff_type} | {vd.n_diffs} | {detail} {core_mark} |")
            lines.append("")
    
    # Legend
    lines.append("\n## Legend\n")
    lines.append("- **PASS**: All checks passed")
    lines.append("- **WARN**: Non-critical differences (column case, extra columns)")
    lines.append("- **FAIL**: Core data mismatch (iso3, indicator, period, value)")
    lines.append("- **SKIP**: File missing in one language")
    lines.append(f"- **Core columns**: {', '.join(sorted(CORE_COLUMNS))}")
    lines.append(f"- **Ignored columns**: {', '.join(sorted(IGNORE_COLUMNS))}")
    
    output_path.write_text("\n".join(lines), encoding="utf-8")


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Robust cross-language validation for unicefData outputs"
    )
    parser.add_argument("--summary", action="store_true",
                       help="Show summary only (less detail)")
    parser.add_argument("--file", help="Validate specific file(s), e.g., '00_ex1'")
    parser.add_argument("--report", help="Save markdown report to file")
    parser.add_argument("--languages", nargs=2, default=["python", "r"],
                       help="Languages to compare (default: python r)")
    
    args = parser.parse_args()
    
    lang1, lang2 = args.languages
    dir1 = LANGUAGES.get(lang1)
    dir2 = LANGUAGES.get(lang2)
    
    if not dir1 or not dir2:
        print(f"Error: Unknown language. Available: {list(LANGUAGES.keys())}")
        return 1
    
    if not dir1.exists():
        print(f"Error: {lang1} data directory not found: {dir1}")
        return 1
    
    if not dir2.exists():
        print(f"Error: {lang2} data directory not found: {dir2}")
        return 1
    
    # Get files to compare
    files1 = set(get_csv_files(dir1))
    files2 = set(get_csv_files(dir2))
    all_files = sorted(files1 | files2)
    
    if args.file:
        all_files = [f for f in all_files if args.file in f]
    
    if not all_files:
        print("No CSV files found to compare")
        return 1
    
    # Compare files
    comparisons = []
    for filename in all_files:
        comp = compare_files(dir1 / filename, dir2 / filename, lang1, lang2)
        comparisons.append(comp)
    
    # Generate report
    report = format_comparison_report(comparisons, lang1, lang2, verbose=not args.summary)
    print(report)
    
    # Save results
    csv_path = SCRIPT_DIR / "validation_detailed_results.csv"
    save_results_csv(comparisons, csv_path)
    print(f"\nDetailed results saved to: {csv_path}")
    
    if args.report:
        md_path = Path(args.report)
        save_markdown_report(comparisons, lang1, lang2, md_path)
        print(f"Markdown report saved to: {md_path}")
    
    # Return code based on results
    has_failures = any(c.status == "FAIL" for c in comparisons)
    return 1 if has_failures else 0


if __name__ == "__main__":
    sys.exit(main())

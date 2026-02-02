#!/usr/bin/env python3
"""
Compare API queries across Python, R, and Stata platforms with verbose output.
Shows actual URLs and parameters being sent to the SDMX API.
"""

import os
import sys
import json
import subprocess
from datetime import datetime
from typing import Dict, Any, Optional, Tuple
from urllib.parse import urlencode, parse_qs, urlparse

import pandas as pd

# Ensure we can import the local Python client
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PYTHON_SRC = os.path.join(REPO_ROOT, "python")
if PYTHON_SRC not in sys.path:
    sys.path.insert(0, PYTHON_SRC)

try:
    from unicef_api.sdmx_client import UNICEFSDMXClient
except Exception as e:
    print(f"ERROR: Could not import UNICEFSDMXClient from {PYTHON_SRC}: {e}")
    sys.exit(1)

# Stata path per workspace instructions
STATA_EXE = r"C:\Program Files\Stata17\StataMP-64.exe"
STATA_DIR = os.path.join(REPO_ROOT, "stata")

RESULTS_DIR = os.path.join(REPO_ROOT, "validation", "results", "query_comparison_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
os.makedirs(RESULTS_DIR, exist_ok=True)

TMP_DIR = os.path.join(RESULTS_DIR, "tmp")
os.makedirs(TMP_DIR, exist_ok=True)


def fetch_python_verbose(indicator: str, nofilter: bool = False) -> Tuple[Optional[str], Optional[str], Optional[str], Optional[pd.DataFrame]]:
    """Fetch with Python client and capture verbose request details.
    
    Returns:
        (url, params_json, error_msg, dataframe)
    """
    try:
        client = UNICEFSDMXClient()
        kwargs: Dict[str, Any] = {"return_raw": True}
        
        if nofilter:
            kwargs["sex_disaggregation"] = None
        else:
            kwargs["sex_disaggregation"] = "_T"
        
        print(f"\n{'='*80}")
        print(f"PYTHON CLIENT - {indicator}")
        print(f"{'='*80}")
        print(f"Fetching with sex_disaggregation={kwargs.get('sex_disaggregation')}")
        
        df = client.fetch_indicator(indicator, **kwargs)
        
        # Capture request details
        url = getattr(client, "_last_url", None)
        params = getattr(client, "_last_params", {}) or {}
        
        if url:
            # Build complete URL with query parameters for easy browser testing
            param_str = "&".join([f"{k}={v}" for k, v in params.items()])
            complete_url = f"{url}?{param_str}" if param_str else url
            print(f"\n[OK] Python Complete Request URL (copy/paste ready):")
            print(f"  {complete_url}")
            print(f"\n[OK] Python Query Parameters:")
            for k, v in params.items():
                print(f"  {k}: {v}")
            
            print(f"\n[OK] Result: {len(df)} rows, {len(df.columns)} columns")
            print(f"  Columns: {list(df.columns)[:5]}...")
            
            # Tabulate SEX dimension if present
            if 'SEX' in df.columns:
                print(f"\n[OK] Python SEX Dimension Tabulation:")
                sex_counts = df['SEX'].value_counts().sort_index()
                for sex_val, count in sex_counts.items():
                    pct = (count / len(df)) * 100
                    print(f"  {sex_val:10} : {count:6} rows ({pct:5.1f}%)")
            else:
                print(f"\n  (SEX dimension not in result)")
            
            params_json = json.dumps(params, indent=2)
            return url, params_json, None, df
        else:
            return None, None, "No URL captured from Python client", None
            
    except Exception as e:
        return None, None, f"Python fetch failed: {e}", None


def fetch_r_verbose(indicator: str, py_url: str, py_params: Dict[str, Any], nofilter: bool = False) -> Tuple[Optional[str], Optional[str], Optional[str], Optional[pd.DataFrame]]:
    """Fetch with R and capture verbose request details.
    
    Returns:
        (url, params_json, error_msg, dataframe)
    """
    try:
        print(f"\n{'='*80}")
        print(f"R CLIENT - {indicator}")
        print(f"{'='*80}")
        
        if not py_url:
            return None, None, "No Python URL available for R to mirror", None
        
        # Build full URL with params
        query = urlencode(py_params)
        full_url = f"{py_url}?{query}"
        
        print(f"\n[OK] R Request URL (from Python params):")
        print(f"  {full_url}")
        print(f"\n[OK] R Query Parameters:")
        for k, v in py_params.items():
            print(f"  {k}: {v}")
        
        # Create R script to fetch
        r_path = os.path.join(TMP_DIR, f"fetch_r_{indicator.replace('-', '_')}.R")
        csv_out_path = os.path.join(TMP_DIR, f"r_{indicator.replace('-', '_')}_data.csv").replace('\\', '/')
        r_code = f"""
# Verbose R fetch with detailed output and SEX tabulation
library(readr)

url <- "{full_url}"
cat("R Request URL:\\n")
cat(url, "\\n\\n")

# Fetch the data
tryCatch({{
  df <- read_csv(url, show_col_types=FALSE)
  cat("\\nR Result:\\n")
  cat(paste("  Rows:", nrow(df), "\\n"))
  cat(paste("  Columns:", ncol(df), "\\n"))
  cat(paste("  Column names:", paste(head(names(df), 5), collapse=", "), "...\\n"))
  
  # Tabulate SEX if present
  if ("SEX" %in% names(df)) {{
    cat("\\nR SEX Dimension Tabulation:\\n")
    sex_tab <- table(df$SEX)
    for (sex_val in names(sex_tab)) {{
      count <- sex_tab[sex_val]
      pct <- (count / nrow(df)) * 100
      cat(sprintf("  %-10s : %6d rows (%5.1f%%)\\n", sex_val, count, pct))
    }}
  }} else {{
    cat("\\n  (SEX dimension not in result)\\n")
  }}
  
  # Save to CSV for later reading
  write.csv(df, "{csv_out_path}", row.names=FALSE)
}}, error=function(e) {{
  cat("ERROR:", e$message, "\\n")
  quit(status=1)
}})
"""
        with open(r_path, "w", encoding="utf-8") as f:
            f.write(r_code)
        
        proc = subprocess.run(["Rscript", r_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if proc.returncode == 0:
            print(proc.stdout)
            
            # Try to read the CSV that R saved
            csv_path = os.path.join(TMP_DIR, f"r_{indicator.replace('-', '_')}_data.csv")
            r_df = None
            if os.path.exists(csv_path):
                try:
                    r_df = pd.read_csv(csv_path)
                except Exception as e:
                    print(f"Warning: Could not read R CSV: {e}")
            
            params_json = json.dumps(py_params, indent=2)
            return full_url, params_json, None, r_df
        else:
            error_msg = f"R fetch failed: {proc.stderr}"
            print(f"ERROR: {error_msg}")
            return full_url, None, error_msg, None
            
    except Exception as e:
        return None, None, f"R execution failed: {e}", None


def fetch_stata_verbose(indicator: str, nofilter: bool = False) -> Tuple[Optional[str], Optional[str], Optional[pd.DataFrame]]:
    """Fetch with Stata and capture verbose request details with API logging enabled.
    
    Returns:
        (stata_command, error_msg, dataframe)
    """
    try:
        print(f"\n{'='*80}")
        print(f"STATA CLIENT - {indicator}")
        print(f"{'='*80}")
        
        # Create Stata do-file with debugging and tracing
        do_path = os.path.join(TMP_DIR, f"fetch_stata_{indicator.replace('-', '_')}.do")
        
        # Enable HTTP logging for debugging with verbose and debug URL logging
        lines = [
            "clear all",
            "set more off",
            "discard",
            "",
            "* Enable debug tracing for HTTP requests and verbose URL output",
            "set debug on",
            "",
            f"net install unicefdata, from(\"{REPO_ROOT}\\stata\") replace",
            "",
            "* Fetch with verbose option to show URL construction",
            f"capture noisily unicefdata, indicator({indicator}) verbose clear",
            "",
            "* Display data summary",
            "di \"\"",
            "di \"Stata Result:\"",
            "di \"  Observations: \" _N",
            "di \"  Variables: \" c(k)",
            "",
            "* Tabulate SEX if present",
            "capture confirm variable SEX",
            "if _rc == 0 {",
            "    di \"\"",
            "    di \"Stata SEX Dimension Tabulation:\"",
            "    tabulate SEX, missing",
            "}",
            "else {",
            "    di \"  (SEX dimension not in result)\"",
            "}",
            "",
            "* Export to CSV for analysis",
            f"export delimited using \"{TMP_DIR}\\stata_{indicator.replace('-', '_')}_data.csv\", replace",
        ]
        
        do_content = "\n".join(lines) + "\n"
        
        with open(do_path, "w", encoding="utf-8") as f:
            f.write(do_content)
        
        print(f"\n[OK] Stata Command Being Executed:")
        print(f"  unicefdata, indicator({indicator}) clear")
        print(f"\n  Debugging Enabled:")
        print(f"    - set debug on (captures macro expansion and command flow)")
        print(f"    - SEX tabulation (if present in data)")
        
        # Run Stata with output capture to see debug info
        cmd = [STATA_EXE, "/e", "do", do_path]
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd=STATA_DIR)
        
        print(f"\n[OK] Stata Output:")
        # Parse output to show URL and disaggregation filters
        lines_output = []
        in_result = False
        for line in proc.stdout.split('\n'):
            # Capture URL and disaggregation info
            if 'Fetching from:' in line or 'Disaggregation' in line or 'Trying dataflow:' in line or 'URL:' in line:
                lines_output.append(line)
                print(f"  {line}")
            # Capture result counts
            if any(x in line.lower() for x in ['result', 'observations', 'variables', 'sex', 'dimension', 'tabulate', 'export', 'successfully']):
                if 'Observations:' in line or 'Variables:' in line or 'tabulate' in line or 'dimesion' in line:
                    lines_output.append(line)
                    print(f"  {line}")
        
        # Try to read the CSV that Stata exported
        csv_path = os.path.join(TMP_DIR, f"stata_{indicator.replace('-', '_')}_data.csv")
        stata_df = None
        if os.path.exists(csv_path):
            try:
                stata_df = pd.read_csv(csv_path)
                print(f"\n[OK] Stata CSV exported: {len(stata_df)} rows")
            except Exception as e:
                print(f"Warning: Could not read Stata CSV: {e}")
        
        if proc.returncode == 0:
            stata_cmd = f"unicefdata, indicator({indicator}) clear"
            return stata_cmd, None, stata_df
        else:
            # Still return partial info even if return code is non-zero
            print(f"\n[WARN] Stata execution returned code {proc.returncode}")
            stata_cmd = f"unicefdata, indicator({indicator}) clear"
            return stata_cmd, None, stata_df
            
    except Exception as e:
        return None, f"Stata execution failed: {e}", None


def main():
    """Compare queries across all three platforms."""
    
    # Test with a subset of indicators for detailed comparison
    test_cases = [
        {"name": "WS_HCF_H-L", "year": 2015},
        {"name": "ED_MAT_G23", "year": None},
        {"name": "ECD_CHLD_U5_BKS-HM", "year": None},
    ]
    
    summary = {
        "timestamp": datetime.now().isoformat(),
        "comparisons": []
    }
    
    for case in test_cases:
        name = case["name"]
        year = case["year"]
        nofilter = False
        
        print(f"\n\n{'#'*80}")
        print(f"# COMPARING QUERIES FOR: {name}")
        print(f"{'#'*80}")
        
        # Python
        py_url, py_params_json, py_error, py_df = fetch_python_verbose(name, nofilter=nofilter)
        
        # R (mirrors Python)
        py_params = json.loads(py_params_json) if py_params_json else {}
        r_url, r_params_json, r_error, r_df = fetch_r_verbose(name, py_url, py_params, nofilter=nofilter)
        
        # Stata
        stata_cmd, stata_error, stata_df = fetch_stata_verbose(name, nofilter=nofilter)
        
        # Summary for this indicator
        comparison = {
            "indicator": name,
            "python": {
                "url": py_url,
                "params": json.loads(py_params_json) if py_params_json else None,
                "rows": len(py_df) if py_df is not None else None,
                "error": py_error
            },
            "r": {
                "url": r_url,
                "params": json.loads(r_params_json) if r_params_json else None,
                "rows": len(r_df) if r_df is not None else None,
                "error": r_error
            },
            "stata": {
                "command": stata_cmd,
                "rows": len(stata_df) if stata_df is not None else None,
                "error": stata_error
            }
        }
        summary["comparisons"].append(comparison)
    
    # Save comparison summary
    summary_path = os.path.join(RESULTS_DIR, "query_comparison_summary.json")
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)
    
    # Also save human-readable comparison
    report_path = os.path.join(RESULTS_DIR, "query_comparison_report.txt")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("QUERY COMPARISON REPORT - PYTHON vs R vs STATA\n")
        f.write("=" * 80 + "\n\n")
        
        for comp in summary["comparisons"]:
            f.write(f"\nINDICATOR: {comp['indicator']}\n")
            f.write("-" * 80 + "\n")
            
            f.write("\nPYTHON:\n")
            if comp['python']['url']:
                f.write(f"  URL: {comp['python']['url']}\n")
                f.write(f"  Params: {json.dumps(comp['python']['params'], indent=4)}\n")
                f.write(f"  Rows: {comp['python'].get('rows', 'N/A')}\n")
            else:
                f.write(f"  ERROR: {comp['python']['error']}\n")
            
            f.write("\nR:\n")
            if comp['r']['url']:
                f.write(f"  URL: {comp['r']['url']}\n")
                if comp['r']['params']:
                    f.write(f"  Params: {json.dumps(comp['r']['params'], indent=4)}\n")
                f.write(f"  Rows: {comp['r'].get('rows', 'N/A')}\n")
            else:
                f.write(f"  ERROR: {comp['r']['error']}\n")
            
            f.write("\nSTATA:\n")
            if comp['stata']['command']:
                f.write(f"  Command: {comp['stata']['command']}\n")
                f.write(f"  Rows: {comp['stata'].get('rows', 'N/A')}\n")
                if comp['stata']['error']:
                    f.write(f"  Error: {comp['stata']['error']}\n")
                else:
                    f.write(f"  Note: Debugging with set debug on enabled to trace macro expansion\n")
            else:
                f.write(f"  ERROR: {comp['stata']['error']}\n")
            
            f.write("\n")
    
    print(f"\n\n{'='*80}")
    print(f"Comparison report saved to:")
    print(f"  {summary_path}")
    print(f"  {report_path}")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    main()

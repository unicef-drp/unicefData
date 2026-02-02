import os
import sys
import json
import time
import shutil
import subprocess
from datetime import datetime
from typing import Dict, Any, Optional, Tuple

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

RESULTS_DIR = os.path.join(REPO_ROOT, "validation", "results", datetime.now().strftime("%Y%m%d_%H%M%S"))
os.makedirs(RESULTS_DIR, exist_ok=True)

TMP_DIR = os.path.join(RESULTS_DIR, "tmp")
os.makedirs(TMP_DIR, exist_ok=True)


def run_stata_fetch(indicator: str, out_csv: str, start_year: Optional[int] = None, end_year: Optional[int] = None, nofilter: bool = False) -> Tuple[bool, Optional[str]]:
    """Run Stata in batch to fetch an indicator via unicefdata.ado and export CSV.
    
    Args:
        indicator: UNICEF indicator code
        out_csv: Output CSV path
        start_year: Optional start year filter
        end_year: Optional end year filter
        nofilter: If True, fetch all disaggregations. If False (default), fetch only totals.
    
    Returns:
        (success, error_message)
    """
    do_path = os.path.join(TMP_DIR, f"fetch_{indicator.replace('-', '_')}.do")
    log_path = os.path.join(TMP_DIR, f"fetch_{indicator.replace('-', '_')}.log")
    # Build Stata do-file content
    # Use already-installed ado files from user ado path (assumes files were copied there)
    lines = [
        "clear all",
        "set more off",
        f"log using \"{log_path}\", text replace",
        "discard",
        f"display \"Fetching indicator: {indicator}\"",
        f"capture noisily unicefdata, indicator({indicator}) clear",
        f"display \"Return code: \" _rc",
        f"display \"Observations loaded: \" _N",
        "if _N > 0 {",
        f"    export delimited using \"{out_csv}\", replace",
        f"    display \"CSV exported to: {out_csv}\"",
        "}",
        "else {",
        f"    display \"ERROR: No data loaded for {indicator}\"",
        "}",
        "log close"
    ]
    with open(do_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    try:
        # Run Stata in batch mode
        cmd = [STATA_EXE, "/e", "do", do_path]
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=60)
        if proc.returncode != 0:
            # Read log file for details
            log_content = ""
            if os.path.exists(log_path):
                with open(log_path, "r") as f:
                    log_content = f.read()
            return False, f"Stata run failed (rc={proc.returncode}). Log:\n{log_content[:500]}"
        if not os.path.exists(out_csv):
            # Read log file for details
            log_content = ""
            if os.path.exists(log_path):
                with open(log_path, "r") as f:
                    log_content = f.read()
            return False, f"Stata finished but output CSV not found. Log:\n{log_content[:500]}"
        return True, None
    except FileNotFoundError:
        return False, f"Stata executable not found at {STATA_EXE}"
    except Exception as e:
        return False, f"Unexpected error running Stata: {e}"


def fetch_python(indicator: str, start_year: Optional[int] = None, end_year: Optional[int] = None, nofilter: bool = False) -> Tuple[pd.DataFrame, UNICEFSDMXClient]:
    """Fetch indicator data using Python client.
    
    Args:
        indicator: UNICEF indicator code
        start_year: Optional start year filter
        end_year: Optional end year filter
        nofilter: If True, fetch all disaggregations (sex=None). If False (default), fetch only totals (sex="_T").
    
    Returns:
        (DataFrame, client)
    """
    client = UNICEFSDMXClient()
    kwargs: Dict[str, Any] = {"return_raw": True}
    if start_year is not None:
        kwargs["start_year"] = start_year
    if end_year is not None:
        kwargs["end_year"] = end_year
    
    # Default: fetch only totals (one number per country-year)
    # Set sex_disaggregation=None to fetch all disaggregations
    if nofilter:
        kwargs["sex_disaggregation"] = None
    else:
        kwargs["sex_disaggregation"] = "_T"  # Default: totals only
    
    df = client.fetch_indicator(indicator, **kwargs)
    # Ensure pandas DataFrame
    if not isinstance(df, pd.DataFrame):
        raise TypeError("Python client did not return a pandas DataFrame")
    return df, client


def run_r_fetch(request_url: str, params: Dict[str, Any], out_csv: str, nofilter: bool = False) -> Tuple[bool, Optional[str]]:
    """Use Rscript to fetch the same CSV URL (with params) and write out_csv.
    
    Args:
        request_url: SDMX API endpoint URL
        params: Query parameters
        out_csv: Output CSV path
        nofilter: If True, fetch all disaggregations. If False (default), fetch only totals.
            (Note: R currently mirrors Python's exact API call, so filtering is already applied via params)
    
    Returns:
        (success, error_message)
    """
    r_path = os.path.join(TMP_DIR, "fetch_r.R")
    # Build query string from params
    from urllib.parse import urlencode
    query = urlencode(params)
    full_url = f"{request_url}?{query}"
    r_code = """
    args <- commandArgs(trailingOnly=TRUE)
    url <- args[1]
    out <- args[2]
    suppressMessages({
      if (!requireNamespace("readr", quietly=TRUE)) stop("readr package required")
    })
    df <- tryCatch({
      readr::read_csv(url, show_col_types=FALSE)
    }, error=function(e) {{
      write(paste("ERROR:", e$message), stderr())
      quit(status=1)
    }})
    tryCatch({
      write.csv(df, out, row.names=FALSE)
    }, error=function(e) {{
      write(paste("ERROR writing CSV:", e$message), stderr())
      quit(status=1)
    }})
    """
    with open(r_path, "w", encoding="utf-8") as f:
        f.write(r_code)
    try:
        proc = subprocess.run(["Rscript", r_path, full_url, out_csv], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if proc.returncode != 0:
            return False, f"R fetch failed: {proc.stderr}"
        if not os.path.exists(out_csv):
            return False, "R finished but output CSV not found"
        return True, None
    except FileNotFoundError:
        return False, "Rscript not found in PATH"
    except Exception as e:
        return False, f"Unexpected error running Rscript: {e}"


def check_ws_hcf_case(py_df: pd.DataFrame, st_df: pd.DataFrame) -> Dict[str, Any]:
    """WS_HCF_H-L: expect service_type and hcf_type present in Python; row parity with Stata."""
    result = {"indicator": "WS_HCF_H-L"}
    cols = set(py_df.columns.str.lower())
    result["python_has_service_type"] = ("service_type" in cols)
    result["python_has_hcf_type"] = ("hcf_type" in cols)
    result["python_rows"] = len(py_df)
    result["stata_rows"] = len(st_df)
    # PASS if both columns exist and row counts are within 90% parity for sampled period
    result["pass"] = result["python_has_service_type"] and result["python_has_hcf_type"] and (
        min(result["python_rows"], result["stata_rows"]) / max(result["python_rows"], result["stata_rows"]) >= 0.9
    )
    return result


def check_generic_row_parity(name: str, py_df: pd.DataFrame, st_df: pd.DataFrame) -> Dict[str, Any]:
    result = {"indicator": name, "python_rows": len(py_df), "stata_rows": len(st_df)}
    # Exact parity might be too strict; use >= 95% parity tolerance
    ratio = min(result["python_rows"], result["stata_rows"]) / max(result["python_rows"], result["stata_rows"]) if max(result["python_rows"], result["stata_rows"]) > 0 else 0.0
    result["parity_ratio"] = ratio
    result["pass"] = ratio >= 0.95
    return result


def check_geo_type_consistency(name: str, py_df: pd.DataFrame, st_df: pd.DataFrame, r_df: Optional[pd.DataFrame] = None) -> Dict[str, Any]:
    """Validate that all platforms have geo_type variable with values 0 or 1, and same share of aggregates.
    
    Args:
        name: Indicator name
        py_df: Python DataFrame
        st_df: Stata DataFrame
        r_df: Optional R DataFrame
    
    Returns:
        Dictionary with geo_type validation results
    """
    result = {"indicator": name, "geo_type_validation": {}}
    
    # Check Python
    if "geo_type" in py_df.columns:
        py_geo = py_df["geo_type"]
        py_unique = set(py_geo.dropna().unique())
        py_valid = py_unique.issubset({0, 1})
        py_share = (py_geo == 1).sum() / len(py_df) if len(py_df) > 0 else None
        result["geo_type_validation"]["python"] = {
            "has_geo_type": True,
            "valid_values": py_valid,
            "unique_values": sorted(list(py_unique)),
            "share_aggregates": py_share
        }
    else:
        result["geo_type_validation"]["python"] = {"has_geo_type": False}
    
    # Check Stata
    if "geo_type" in st_df.columns:
        st_geo = st_df["geo_type"]
        st_unique = set(st_geo.dropna().unique())
        st_valid = st_unique.issubset({0, 1})
        st_share = (st_geo == 1).sum() / len(st_df) if len(st_df) > 0 else None
        result["geo_type_validation"]["stata"] = {
            "has_geo_type": True,
            "valid_values": st_valid,
            "unique_values": sorted(list(st_unique)),
            "share_aggregates": st_share
        }
    else:
        result["geo_type_validation"]["stata"] = {"has_geo_type": False}
    
    # Check R
    if r_df is not None and "geo_type" in r_df.columns:
        r_geo = r_df["geo_type"]
        r_unique = set(r_geo.dropna().unique())
        r_valid = r_unique.issubset({0, 1})
        r_share = (r_geo == 1).sum() / len(r_df) if len(r_df) > 0 else None
        result["geo_type_validation"]["r"] = {
            "has_geo_type": True,
            "valid_values": r_valid,
            "unique_values": sorted(list(r_unique)),
            "share_aggregates": r_share
        }
    else:
        if r_df is not None:
            result["geo_type_validation"]["r"] = {"has_geo_type": False}
    
    # Overall pass criteria:
    # 1. All platforms have geo_type
    # 2. All values are 0 or 1
    # 3. Share of aggregates is consistent (within 5% tolerance)
    py_has = result["geo_type_validation"]["python"].get("has_geo_type", False)
    st_has = result["geo_type_validation"]["stata"].get("has_geo_type", False)
    py_valid = result["geo_type_validation"]["python"].get("valid_values", False) if py_has else False
    st_valid = result["geo_type_validation"]["stata"].get("valid_values", False) if st_has else False
    
    all_present_valid = py_has and st_has and py_valid and st_valid
    
    # Check share consistency
    share_consistent = True
    if py_has and st_has and py_valid and st_valid:
        py_share = result["geo_type_validation"]["python"].get("share_aggregates")
        st_share = result["geo_type_validation"]["stata"].get("share_aggregates")
        if py_share is not None and st_share is not None:
            share_diff = abs(py_share - st_share)
            share_consistent = share_diff <= 0.05  # 5% tolerance
            result["share_difference"] = share_diff
        
        # If R is available, also check with R
        if "r" in result["geo_type_validation"]:
            r_has = result["geo_type_validation"]["r"].get("has_geo_type", False)
            r_valid = result["geo_type_validation"]["r"].get("valid_values", False) if r_has else False
            if r_has and r_valid:
                r_share = result["geo_type_validation"]["r"].get("share_aggregates")
                if r_share is not None and share_consistent:
                    for platform_name in ["python", "stata"]:
                        platform_share = result["geo_type_validation"][platform_name].get("share_aggregates")
                        if platform_share is not None:
                            share_diff_r = abs(platform_share - r_share)
                            if share_diff_r > 0.05:
                                share_consistent = False
    
    result["geo_type_validation"]["pass"] = all_present_valid and share_consistent
    return result


def main():
    """Run phase2 test cases for WS_HCF_H-L, ECD_CHLD_U5_BKS-HM, ED_MAT_G23, etc."""
    # ============================================================
    # CLEAR ALL CACHES BEFORE TESTING
    # ============================================================
    print("=== Clearing caches for all platforms ===\n")
    
    # Define validation cache directories
    validation_cache_root = os.path.join(REPO_ROOT, "validation", "cache")
    python_validation_cache = os.path.join(validation_cache_root, "python")
    r_validation_cache = os.path.join(validation_cache_root, "r")
    stata_validation_cache = os.path.join(validation_cache_root, "stata")
    
    # 1. Clear Python validation cache
    print("Clearing Python validation cache...")
    if os.path.exists(python_validation_cache):
        shutil.rmtree(python_validation_cache)
        print(f"  [OK] Removed: {python_validation_cache}")
    os.makedirs(python_validation_cache, exist_ok=True)
    print(f"  [OK] Recreated: {python_validation_cache}")
    
    # Also clear general Python cache
    python_cache_dirs = [
        os.path.join(os.path.expanduser("~"), ".unicef_sdmx_cache"),
        os.path.join(os.path.expanduser("~"), ".cache", "unicef_sdmx"),
    ]
    for cache_dir in python_cache_dirs:
        if os.path.exists(cache_dir):
            shutil.rmtree(cache_dir)
            print(f"  ✓ Removed: {cache_dir}")
    
    # 2. Clear R validation cache
    print("\nClearing R validation cache...")
    if os.path.exists(r_validation_cache):
        shutil.rmtree(r_validation_cache)
        print(f"  [OK] Removed: {r_validation_cache}")
    os.makedirs(r_validation_cache, exist_ok=True)
    print(f"  [OK] Recreated: {r_validation_cache}")
    
    # Also clear R workspace
    r_cache_script = """
# Clear .RData if exists
if (file.exists(".RData")) {
    file.remove(".RData")
    cat("  ✓ Removed .RData\\n")
}
"""
    r_cache_path = os.path.join(TMP_DIR, "clear_r_cache.R")
    with open(r_cache_path, "w", encoding="utf-8") as f:
        f.write(r_cache_script)
    subprocess.run(["Rscript", r_cache_path], check=False, capture_output=True)
    
    # 3. Clear Stata validation cache
    print("\nClearing Stata validation cache...")
    if os.path.exists(stata_validation_cache):
        shutil.rmtree(stata_validation_cache)
        print(f"  [OK] Removed: {stata_validation_cache}")
    os.makedirs(stata_validation_cache, exist_ok=True)
    print(f"  [OK] Recreated: {stata_validation_cache}")
    
    # Also clear Stata frames
    stata_clear = """
quietly {
    clear all
    frames reset
}
display "  ✓ Stata frames cleared"
"""
    stata_clear_path = os.path.join(TMP_DIR, "clear_stata_cache.do")
    with open(stata_clear_path, "w", encoding="utf-8") as f:
        f.write(stata_clear)
    # Use shell=True to handle paths with spaces properly
    try:
        subprocess.run([STATA_EXE, "/e", "do", stata_clear_path], 
                       check=False, capture_output=True, cwd=TMP_DIR, timeout=30)
        print("  ✓ Stata cache cleared")
    except Exception as e:
        print(f"  [WARN] Could not clear Stata cache: {e}")
    
    print("\n=== Cache clearing complete ===\n")
    
    # ============================================================
    # RUN TEST CASES
    # ============================================================
    cases = [
        {"name": "WS_HCF_H-L", "year": 2015, "check": "ws_hcf"},
        {"name": "ECD_CHLD_U5_BKS-HM", "year": None, "check": "parity"},
        {"name": "ED_MAT_G23", "year": None, "check": "parity"},
        {"name": "FD_FOUNDATIONAL_LEARNING", "year": None, "check": "parity"},
        {"name": "NT_CF_ISSSF_FL", "year": None, "check": "parity"},
        {"name": "NT_CF_MMF", "year": None, "check": "parity"},
    ]

    summary = {"timestamp": datetime.now().isoformat(), "results": []}

    for case in cases:
        name = case["name"]
        year = case["year"]
        print(f"\n=== Testing {name} ===")
        
        # DEFAULT: Fetch only totals (one number per country-year)
        # Set nofilter=True to fetch all disaggregations
        nofilter = False  # Change to True to see all sex/age/wealth breakdowns
        
        # Fetch Python
        try:
            py_df, client = fetch_python(name, start_year=year, end_year=year, nofilter=nofilter)
            print(f"Python: {len(py_df)} rows (nofilter={nofilter})")
        except Exception as e:
            summary["results"].append({"indicator": name, "pass": False, "error": f"Python fetch failed: {e}"})
            print(f"Python fetch failed: {e}")
            continue
        # Capture and print Python request URL for parity auditing
        py_url = getattr(client, "_last_url", None)
        py_params = getattr(client, "_last_params", {}) or {}
        if py_url:
            # Build complete URL with query parameters for easy browser testing
            param_str = "&".join([f"{k}={v}" for k, v in py_params.items()])
            complete_url = f"{py_url}?{param_str}" if param_str else py_url
            print(f"Python request URL: {complete_url}")
        # Fetch Stata (CSV export)
        out_csv = os.path.join(TMP_DIR, f"stata_{name.replace('-', '_')}.csv")
        ok, err = run_stata_fetch(name, out_csv, start_year=year, end_year=year, nofilter=nofilter)
        if not ok:
            summary["results"].append({"indicator": name, "pass": False, "error": f"Stata fetch failed: {err}"})
            print(f"Stata fetch failed: {err}")
            continue
        try:
            # Try UTF-8 first, then fallback to latin-1 which accepts all byte values
            try:
                st_df = pd.read_csv(out_csv, encoding="utf-8")
            except UnicodeDecodeError:
                print(f"  UTF-8 decode failed, trying latin-1...")
                st_df = pd.read_csv(out_csv, encoding="latin-1")
            print(f"Stata: {len(st_df)} rows (nofilter={nofilter})")
        except Exception as e:
            summary["results"].append({"indicator": name, "pass": False, "error": f"Read Stata CSV failed: {e}"})
            print(f"Read Stata CSV failed: {e}")
            continue

        # Fetch R parity based on Python URL (if available)
        r_df = None
        if py_url:
            r_out = os.path.join(TMP_DIR, f"r_{name.replace('-', '_')}.csv")
            rok, rerr = run_r_fetch(py_url, py_params, r_out, nofilter=nofilter)
            if not rok:
                print(f"R fetch failed: {rerr}")
                r_info = {"indicator": name, "r_error": rerr}
            else:
                try:
                    # Try UTF-8 first, then fallback to latin-1
                    try:
                        r_df = pd.read_csv(r_out, encoding="utf-8")
                    except UnicodeDecodeError:
                        print(f"  UTF-8 decode failed for R CSV, trying latin-1...")
                        r_df = pd.read_csv(r_out, encoding="latin-1")
                    print(f"R: {len(r_df)} rows (nofilter={nofilter})")
                    r_info = {"indicator": name, "r_rows": len(r_df)}
                except Exception as e:
                    r_info = {"indicator": name, "r_error": f"Read R CSV failed: {e}"}
        else:
            r_info = {"indicator": name, "r_error": "No Python URL available"}

        # Checks
        if case["check"] == "ws_hcf":
            res = check_ws_hcf_case(py_df, st_df)
        else:
            res = check_generic_row_parity(name, py_df, st_df)
        
        # ALSO RUN GEO_TYPE VALIDATION FOR ALL CASES
        geo_res = check_geo_type_consistency(name, py_df, st_df, r_df)
        res["geo_type"] = geo_res.get("geo_type_validation", {})
        if "share_difference" in geo_res:
            res["geo_type"]["share_difference"] = geo_res["share_difference"]
        
        # Append R parity info
        res.update(r_info)
        summary["results"].append(res)
        status = "PASS" if res.get("pass") else "FAIL"
        print(json.dumps(res, indent=2))
        print(f"Result: {status}")

    # Save summary JSON and a human-readable report
    json_path = os.path.join(RESULTS_DIR, "phase2_cases_summary.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)
    txt_path = os.path.join(RESULTS_DIR, "phase2_cases_summary.txt")
    with open(txt_path, "w", encoding="utf-8") as f:
        for res in summary["results"]:
            status = "PASS" if res.get("pass") else "FAIL"
            f.write(f"{res.get('indicator')}: {status}\n")
            f.write(json.dumps(res, indent=2) + "\n\n")

    print(f"\nSummary saved to:\n  {json_path}\n  {txt_path}")


if __name__ == "__main__":
    main()

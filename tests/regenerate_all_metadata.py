#!/usr/bin/env python3
"""
regenerate_all_metadata.py - Regenerate YAML metadata for Python, R, and Stata
==============================================================================

This script regenerates all metadata files for the trilingual unicefData package.
It calls the appropriate sync functions for each language.

Usage:
    python tests/regenerate_all_metadata.py [--python] [--r] [--stata] [--all] [--verbose]

Examples:
    python tests/regenerate_all_metadata.py --all          # Regenerate all
    python tests/regenerate_all_metadata.py --python       # Python only
    python tests/regenerate_all_metadata.py --stata        # Stata only
    python tests/regenerate_all_metadata.py -R           # R only
    python tests/regenerate_all_metadata.py --python -R  # Python and R
"""

import os
import sys
import subprocess
import argparse
import shutil
from pathlib import Path
from datetime import datetime

# Get repository root
SCRIPT_DIR = Path(__file__).parent.resolve()
REPO_ROOT = SCRIPT_DIR.parent


def print_header(title: str):
    """Print a formatted header."""
    print("\n" + "=" * 60)
    print(f" {title}")
    print("=" * 60)


def print_section(title: str):
    """Print a section header."""
    print(f"\n[{title}]")
    print("-" * 40)


def clean_metadata_folder(folder: Path, verbose: bool = False) -> int:
    """Clean YAML files from a metadata folder.
    
    Returns:
        Number of files deleted
    """
    deleted = 0
    if not folder.exists():
        return 0
    
    # Clean YAML files in current folder
    for yaml_file in folder.glob("*.yaml"):
        if verbose:
            print(f"  Removing: {yaml_file.name}")
        yaml_file.unlink()
        deleted += 1
    
    # Clean YAML files in dataflows subfolder
    dataflows_dir = folder / "dataflows"
    if dataflows_dir.exists():
        for yaml_file in dataflows_dir.glob("*.yaml"):
            if verbose:
                print(f"  Removing: dataflows/{yaml_file.name}")
            yaml_file.unlink()
            deleted += 1
    
    return deleted


def regenerate_python(verbose: bool = False) -> bool:
    """Regenerate Python metadata using metadata.py sync_all."""
    print_section("Python")
    
    python_dir = REPO_ROOT / "python"
    metadata_dir = python_dir / "metadata" / "current"
    
    # Clean existing metadata
    deleted = clean_metadata_folder(metadata_dir, verbose)
    print(f"  Cleaned {deleted} existing files")
    
    # Add python directory to path
    sys.path.insert(0, str(python_dir))
    
    try:
        # Import and run the metadata sync
        print("  Syncing metadata from UNICEF SDMX API...")
        from unicef_api.metadata import MetadataSync
        
        sync = MetadataSync(cache_dir=str(python_dir / "metadata"))
        results = sync.sync_all(verbose=verbose, create_vintage=False)
        
        # Count generated files
        file_count = len(list(metadata_dir.glob("*.yaml")))
        dataflow_count = len(list((metadata_dir / "dataflows").glob("*.yaml"))) if (metadata_dir / "dataflows").exists() else 0
        
        print(f"  ✓ Generated {file_count} metadata files + {dataflow_count} dataflow schemas")
        print(f"  ✓ Dataflows: {results.get('dataflows', 'N/A')}")
        print(f"  ✓ Countries: {results.get('countries', 'N/A')}")
        print(f"  ✓ Regions: {results.get('regions', 'N/A')}")
        print(f"  ✓ Indicators: {results.get('indicators', 'N/A')}")
        
        return len(results.get('errors', [])) == 0
        
    except ImportError as e:
        print(f"  ✗ Import error: {e}")
        print("    Make sure you have the required packages: pip install requests pyyaml")
        return False
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False
    finally:
        # Remove from path
        if str(python_dir) in sys.path:
            sys.path.remove(str(python_dir))


def regenerate_r(verbose: bool = False) -> bool:
    """Regenerate R metadata using metadata_sync.R, schema_sync.R, and indicator_registry.R."""
    print_section("R")
    
    r_dir = REPO_ROOT / "R"
    metadata_dir = r_dir / "metadata" / "current"
    
    # Clean existing metadata
    deleted = clean_metadata_folder(metadata_dir, verbose)
    print(f"  Cleaned {deleted} existing files")
    
    # Check if Rscript is available
    rscript = shutil.which("Rscript")
    if not rscript:
        # Try common R installation paths on Windows
        r_paths = [
            r"C:\Program Files\R\R-4.5.0\bin\Rscript.exe",
            r"C:\Program Files\R\R-4.4.0\bin\Rscript.exe",
            r"C:\Program Files\R\R-4.3.1\bin\Rscript.exe",
            r"C:\Program Files\R\R-4.3.0\bin\Rscript.exe",
            r"C:\Program Files\R\R-4.2.0\bin\Rscript.exe",
            r"C:\Program Files\R\R-4.1.3\bin\Rscript.exe",
        ]
        for path in r_paths:
            if Path(path).exists():
                rscript = path
                break
    
    if not rscript:
        print("  ✗ Rscript not found in PATH")
        print("    Please install R and ensure Rscript is in your PATH")
        return False
    
    print(f"  Using: {rscript}")
    
    # R code to run all three sync scripts
    r_code = f"""
setwd('{str(r_dir).replace(chr(92), "/")}')

# Step 1: Consolidated metadata (dataflows, codelists, countries, regions, indicators)
if (file.exists('metadata_sync.R')) {{
    cat("\\n[1/3] Running metadata_sync.R...\\n")
    source('metadata_sync.R')
    tryCatch({{
        sync_all_metadata(verbose = TRUE)
    }}, error = function(e) {{
        cat("Error in metadata_sync:", conditionMessage(e), "\\n")
    }})
}} else {{
    cat("\\n[1/3] metadata_sync.R not found, skipping...\\n")
}}

# Step 2: Full indicator metadata (733 indicators)
if (file.exists('indicator_registry.R')) {{
    cat("\\n[2/3] Running indicator_registry.R...\\n")
    source('indicator_registry.R')
    tryCatch({{
        n <- refresh_indicator_cache()
        cat("Generated", n, "indicators\\n")
    }}, error = function(e) {{
        cat("Error in indicator_registry:", conditionMessage(e), "\\n")
    }})
}} else {{
    cat("\\n[2/3] indicator_registry.R not found, skipping...\\n")
}}

# Step 3: Dataflow schemas (69 individual files)
if (file.exists('schema_sync.R')) {{
    cat("\\n[3/3] Running schema_sync.R...\\n")
    source('schema_sync.R')
    tryCatch({{
        sync_dataflow_schemas()
        cat("\\nR sync completed successfully\\n")
    }}, error = function(e) {{
        cat("Error in schema_sync:", conditionMessage(e), "\\n")
    }})
}} else {{
    cat("\\n[3/3] schema_sync.R not found, skipping...\\n")
}}
"""
    
    try:
        result = subprocess.run(
            [rscript, "--vanilla", "-e", r_code],
            capture_output=True,
            text=True,
            timeout=600  # 10 minute timeout
        )
        
        if verbose:
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                print(result.stderr)
        
        if result.returncode == 0:
            file_count = len(list(metadata_dir.glob("*.yaml"))) if metadata_dir.exists() else 0
            print(f"  ✓ Generated {file_count} metadata files")
            return True
        else:
            print(f"  ✗ R sync failed (exit code {result.returncode})")
            if not verbose and result.stderr:
                print(f"    {result.stderr[:200]}...")
            return False
            
    except subprocess.TimeoutExpired:
        print("  ✗ R sync timed out after 10 minutes")
        return False
    except Exception as e:
        print(f"  ✗ Error running R: {e}")
        return False


def regenerate_stata(verbose: bool = False) -> bool:
    """Regenerate Stata metadata using unicefdata_sync command."""
    print_section("Stata")
    
    stata_dir = REPO_ROOT / "stata"
    metadata_dir = stata_dir / "metadata" / "current"
    
    # Clean existing metadata
    deleted = clean_metadata_folder(metadata_dir, verbose)
    print(f"  Cleaned {deleted} existing files")
    
    # Find Stata executable
    stata_exe = None
    stata_paths = [
        r"C:\Program Files\Stata18\StataMP-64.exe",
        r"C:\Program Files\Stata17\StataMP-64.exe",
        r"C:\Program Files\Stata18\StataSE-64.exe",
        r"C:\Program Files\Stata17\StataSE-64.exe",
        r"C:\Program Files\Stata18\Stata-64.exe",
        r"C:\Program Files\Stata17\Stata-64.exe",
        r"/usr/local/stata18/stata-mp",
        r"/usr/local/stata17/stata-mp",
    ]
    
    for path in stata_paths:
        if Path(path).exists():
            stata_exe = path
            break
    
    if not stata_exe:
        # Try to find stata in PATH
        stata_exe = shutil.which("stata-mp") or shutil.which("stata-se") or shutil.which("stata")
    
    if not stata_exe:
        print("  ✗ Stata executable not found")
        print("    To run manually in Stata:")
        print(f'      adopath ++ "{stata_dir / "src" / "u"}"')
        print(f'      adopath ++ "{stata_dir / "src" / "_"}"')
        print("      unicefdata_sync, verbose")
        return False
    
    print(f"  Using Stata: {stata_exe}")
    
    # Create temporary do-file
    temp_do = REPO_ROOT / "temp_sync.do"
    src_u = str(stata_dir / "src" / "u").replace("\\", "/")
    src_underscore = str(stata_dir / "src" / "_").replace("\\", "/")
    
    do_content = f"""// Temporary do-file for metadata regeneration
clear all
set more off

// Add the package to adopath
adopath ++ "{src_u}"
adopath ++ "{src_underscore}"

// Run sync with verbose output  
unicefdata_sync, verbose

// Exit
exit, clear STATA
"""
    
    try:
        temp_do.write_text(do_content, encoding='ascii')
        
        print("  Running unicefdata_sync...")
        print("  (This may take a few minutes to fetch from SDMX API)")
        
        result = subprocess.run(
            [stata_exe, "/e", "do", str(temp_do)],
            capture_output=True,
            text=True,
            timeout=600,  # 10 minute timeout
            cwd=str(REPO_ROOT)
        )
        
        # Check log file for results
        log_file = REPO_ROOT / "temp_sync.log"
        if log_file.exists():
            log_content = log_file.read_text(encoding='utf-8', errors='ignore')
            if verbose:
                print(log_content)
            
            # Check for success indicators
            if "Sync complete" in log_content or "successfully" in log_content.lower():
                file_count = len(list(metadata_dir.glob("*.yaml"))) if metadata_dir.exists() else 0
                print(f"  ✓ Generated {file_count} metadata files")
                return True
            elif "error" in log_content.lower():
                print("  ✗ Stata sync encountered errors")
                if not verbose:
                    # Show last few lines of log
                    lines = log_content.strip().split('\n')
                    for line in lines[-10:]:
                        print(f"    {line}")
                return False
        
        # Check if files were created
        file_count = len(list(metadata_dir.glob("*.yaml"))) if metadata_dir.exists() else 0
        if file_count > 0:
            print(f"  ✓ Generated {file_count} metadata files")
            return True
        else:
            print("  ✗ No metadata files generated")
            return False
            
    except subprocess.TimeoutExpired:
        print("  ✗ Stata sync timed out after 10 minutes")
        return False
    except Exception as e:
        print(f"  ✗ Error running Stata: {e}")
        return False
    finally:
        # Clean up temporary files
        if temp_do.exists():
            temp_do.unlink()
        log_file = REPO_ROOT / "temp_sync.log"
        if log_file.exists():
            log_file.unlink()


def main():
    parser = argparse.ArgumentParser(
        description="Regenerate YAML metadata for Python, R, and Stata"
    )
    parser.add_argument("--python", action="store_true", help="Regenerate Python metadata")
    parser.add_argument("--r", "-R", action="store_true", dest="r", help="Regenerate R metadata")
    parser.add_argument("--stata", action="store_true", help="Regenerate Stata metadata")
    parser.add_argument("--all", action="store_true", help="Regenerate all (default)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    
    args = parser.parse_args()
    
    # Default to --all if no language specified
    if not any([args.python, args.r, args.stata]):
        args.all = True
    
    print_header("unicefData Metadata Regeneration")
    print(f"Repository: {REPO_ROOT}")
    print(f"Timestamp:  {datetime.now().isoformat()}")
    
    results = {}
    
    if args.all or args.python:
        results["Python"] = regenerate_python(args.verbose)
    
    if args.all or args.r:
        results["R"] = regenerate_r(args.verbose)
    
    if args.all or args.stata:
        results["Stata"] = regenerate_stata(args.verbose)
    
    # Summary
    print_header("Summary")
    
    all_passed = True
    for lang, status in results.items():
        if status is None:
            print(f"  {lang}: SKIPPED")
        elif status:
            print(f"  {lang}: ✓ PASSED")
        else:
            print(f"  {lang}: ✗ FAILED")
            all_passed = False
    
    print()
    if all_passed:
        print("All metadata regeneration completed successfully!")
        return 0
    else:
        print("Some regeneration tasks failed. Check output above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
Verify UTF-8 encoding compliance across unicefData codebase
Checks Python, YAML generation, and documentation
"""

import os
import sys
from pathlib import Path

def check_python_utf8_declaration(filepath):
    """Check if Python file has UTF-8 encoding declared"""
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        first_lines = [f.readline() for _ in range(5)]
    
    for line in first_lines:
        if 'utf-8' in line.lower() or 'coding' in line.lower():
            return True, line.strip()
    return False, None

def check_yaml_write_encoding(filepath):
    """Check if Python file writes YAML with UTF-8 encoding"""
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Check for file writes with encoding
    utf8_writes = content.count("encoding='utf-8'") + content.count('encoding="utf-8"')
    file_writes = content.count("open(") + content.count(".write(")
    
    return utf8_writes, file_writes, utf8_writes > 0

def verify_project_utf8():
    """Verify UTF-8 encoding across project"""
    base_path = Path(".")
    
    print("=" * 80)
    print("unicefData UTF-8 Encoding Compliance Check")
    print("=" * 80)
    print()
    
    # Check Python metadata scripts
    print("1. PYTHON METADATA SCRIPTS")
    print("-" * 80)
    
    py_scripts = [
        "stata/src/py/build_dataflow_metadata.py",
        "stata/src/py/unicefdata_xml2yaml.py",
    ]
    
    py_ok = True
    for script in py_scripts:
        filepath = base_path / script
        if filepath.exists():
            has_encoding, declaration = check_python_utf8_declaration(filepath)
            utf8_writes, total_writes, has_yaml_encoding = check_yaml_write_encoding(filepath)
            
            status = "✅" if has_encoding and has_yaml_encoding else "⚠️ "
            py_ok = py_ok and has_encoding and has_yaml_encoding
            
            print(f"{status} {script}")
            if has_encoding:
                print(f"   ✓ UTF-8 declared: {declaration[:50]}")
            else:
                print(f"   ✗ Missing UTF-8 declaration")
            if has_yaml_encoding:
                print(f"   ✓ YAML writes with encoding: {utf8_writes} locations")
            else:
                print(f"   ✗ Missing encoding in {total_writes} file writes")
        else:
            print(f"⚠️  {script} - NOT FOUND")
    
    print()
    
    # Check Stata files
    print("2. STATA DATA IMPORT")
    print("-" * 80)
    
    stata_files = [
        "stata/src/g/get_sdmx.ado",
        "stata/src/u/unicefdata.ado",
    ]
    
    stata_ok = True
    for stafile in stata_files:
        filepath = base_path / stafile
        if filepath.exists():
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            # Check for encoding mentions or import delimited
            has_import_delim = "import delimited" in content
            has_encoding_note = "utf-8" in content.lower() or "encoding" in content.lower()
            
            status = "✅" if has_encoding_note else "⚠️ "
            stata_ok = stata_ok and has_encoding_note
            
            print(f"{status} {stafile}")
            if has_encoding_note:
                print(f"   ✓ UTF-8 encoding support documented/implemented")
            if has_import_delim:
                print(f"   ✓ Uses import delimited (supports encoding)")
        else:
            print(f"⚠️  {stafile} - NOT FOUND")
    
    print()
    
    # Check R metadata scripts
    print("3. R METADATA GENERATION")
    print("-" * 80)
    
    r_files = [
        "R/metadata_sync.R",
    ]
    
    r_ok = True
    for rfile in r_files:
        filepath = base_path / rfile
        if filepath.exists():
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            has_utf8_encoding = 'encoding = "UTF-8"' in content or "encoding='UTF-8'" in content
            
            status = "✅" if has_utf8_encoding else "⚠️ "
            r_ok = r_ok and has_utf8_encoding
            
            print(f"{status} {rfile}")
            if has_utf8_encoding:
                print(f"   ✓ YAML writes with UTF-8 encoding")
        else:
            print(f"⚠️  {rfile} - NOT FOUND")
    
    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    
    all_ok = py_ok and stata_ok and r_ok
    
    print()
    if all_ok:
        print("✅ ALL CHECKS PASSED - UTF-8 encoding properly implemented")
        return 0
    else:
        print("⚠️  SOME CHECKS FAILED - Review above for details")
        if not py_ok:
            print("   - Python scripts may need UTF-8 declarations or encoding in writes")
        if not stata_ok:
            print("   - Stata files may need UTF-8 encoding notes")
        if not r_ok:
            print("   - R scripts may need UTF-8 encoding in file writes")
        return 1

if __name__ == "__main__":
    exit(verify_project_utf8())

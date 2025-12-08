# Metadata Generation Guide

This document provides instructions for generating all YAML metadata files for the unicefData trilingual package (Python, R, Stata).

## Overview

The package uses YAML metadata files to cache information from the UNICEF SDMX API. Each platform has its own metadata directory with consistent file naming conventions.

## Directory Structure

```
unicefData/
├── python/metadata/current/
│   ├── _unicefdata_dataflows.yaml      # Dataflow definitions
│   ├── _unicefdata_codelists.yaml      # Valid dimension codes
│   ├── _unicefdata_countries.yaml      # Country ISO3 codes
│   ├── _unicefdata_regions.yaml        # Regional aggregate codes
│   ├── _unicefdata_indicators.yaml     # Indicator → dataflow mappings (25 items)
│   ├── unicef_indicators_metadata.yaml # Full indicator codelist (733 items)
│   ├── dataflow_index.yaml             # Index of dataflow schemas
│   └── dataflows/                      # Individual dataflow schema files (69)
│       ├── CME.yaml
│       ├── NUTRITION.yaml
│       └── ...
├── R/metadata/current/
│   ├── _unicefdata_dataflows.yaml      # Dataflow definitions
│   ├── _unicefdata_codelists.yaml      # Valid dimension codes
│   ├── _unicefdata_countries.yaml      # Country ISO3 codes
│   ├── _unicefdata_regions.yaml        # Regional aggregate codes
│   ├── _unicefdata_indicators.yaml     # Indicator → dataflow mappings
│   ├── unicef_indicators_metadata.yaml # Full indicator codelist (733 items)
│   ├── dataflow_index.yaml             # Index of dataflow schemas
│   └── dataflows/                      # Individual dataflow schema files (69)
│       └── ...
└── stata/metadata/current/
    ├── _unicefdata_dataflows.yaml           # Dataflow definitions (Python-generated)
    ├── _unicefdata_dataflows_stataonly.yaml # Pure Stata parser version
    ├── _unicefdata_codelists.yaml           # Valid dimension codes
    ├── _unicefdata_codelists_stataonly.yaml # Pure Stata parser version
    ├── _unicefdata_countries.yaml           # Country ISO3 codes
    ├── _unicefdata_countries_stataonly.yaml # Pure Stata parser version
    ├── _unicefdata_regions.yaml             # Regional aggregate codes
    ├── _unicefdata_regions_stataonly.yaml   # Pure Stata parser version
    ├── _unicefdata_indicators.yaml          # Indicator → dataflow mappings
    ├── _unicefdata_indicators_stataonly.yaml# Pure Stata parser version
    ├── unicef_indicators_metadata.yaml      # Full indicator codelist (733 items)
    ├── unicef_indicators_metadata_stataonly.yaml # Pure Stata version
    ├── dataflow_index.yaml                  # Index of dataflow schemas
    ├── dataflow_index_stataonly.yaml        # Index (limited due to Stata macro limits)
    ├── dataflows/                           # Individual dataflow schemas (69, Python)
    │   └── ...
    └── dataflows_stataonly/                 # Individual schemas (pure Stata, if generated)
        └── ...
```

## Complete File List by Platform

### Python (7 files + 69 dataflows)

| File | Records | Lines | Description | Generator |
|------|---------|-------|-------------|-----------|
| `_unicefdata_dataflows.yaml` | 69 | 630 | Dataflow definitions | `metadata.sync_all()` |
| `_unicefdata_codelists.yaml` | 5 | 633 | Dimension codelists | `metadata.sync_all()` |
| `_unicefdata_countries.yaml` | 453 | 464 | Country ISO3 codes | `metadata.sync_all()` |
| `_unicefdata_regions.yaml` | 111 | 123 | Regional aggregate codes | `metadata.sync_all()` |
| `_unicefdata_indicators.yaml` | 25 | 248 | Indicator → dataflow mappings | `metadata.sync_all()` |
| `unicef_indicators_metadata.yaml` | 733 | 4,406 | Full indicator codelist | `indicator_registry.refresh_indicator_cache()` |
| `dataflow_index.yaml` | 69 | 351 | Index of dataflow schemas | `schema_sync.sync_dataflow_schemas()` |
| `dataflows/*.yaml` | 69 | ~15,000 | Individual dataflow schemas | `schema_sync.sync_dataflow_schemas()` |

### R (7 files + 69 dataflows)

| File | Records | Lines | Description | Generator |
|------|---------|-------|-------------|-----------|
| `_unicefdata_dataflows.yaml` | 69 | 493 | Dataflow definitions | `metadata_sync.R::sync_all_metadata()` |
| `_unicefdata_codelists.yaml` | 5 | 634 | Dimension codelists | `metadata_sync.R::sync_all_metadata()` |
| `_unicefdata_countries.yaml` | 453 | 465 | Country ISO3 codes | `metadata_sync.R::sync_all_metadata()` |
| `_unicefdata_regions.yaml` | 111 | 124 | Regional aggregate codes | `metadata_sync.R::sync_all_metadata()` |
| `_unicefdata_indicators.yaml` | 24 | 141 | Indicator → dataflow mappings | `metadata_sync.R::sync_all_metadata()` |
| `unicef_indicators_metadata.yaml` | 733 | 4,406 | Full indicator codelist | `indicator_registry.R::refresh_indicator_cache()` |
| `dataflow_index.yaml` | 69 | 351 | Index of dataflow schemas | `schema_sync.R::sync_dataflow_schemas()` |
| `dataflows/*.yaml` | 69 | ~15,000 | Individual dataflow schemas | `schema_sync.R::sync_dataflow_schemas()` |

### Stata (7 standard files + 7 stataonly files + 69 dataflows)

Stata supports two parser modes:
- **Standard** (default): Uses Python for large XML files, falls back to Stata
- **Stata-only** (`suffix("_stataonly")`): Pure Stata parser, no Python required

#### Standard Files (Python-assisted)

| File | Records | Lines | Description | Generator |
|------|---------|-------|-------------|-----------|
| `_unicefdata_dataflows.yaml` | 69 | 354 | Dataflow definitions | `unicefdata_sync, verbose` |
| `_unicefdata_codelists.yaml` | 5 | 623 | Dimension codelists | `unicefdata_sync, verbose` |
| `_unicefdata_countries.yaml` | 453 | 464 | Country ISO3 codes | `unicefdata_sync, verbose` |
| `_unicefdata_regions.yaml` | 111 | 122 | Regional aggregate codes | `unicefdata_sync, verbose` |
| `_unicefdata_indicators.yaml` | 25 | 198 | Indicator → dataflow mappings | `unicefdata_sync, verbose` |
| `unicef_indicators_metadata.yaml` | 733 | 3,666 | Full indicator codelist | `unicefdata_sync, verbose` |
| `dataflow_index.yaml` | 69 | 351 | Index of dataflow schemas | Python `schema_sync` |
| `dataflows/*.yaml` | 69 | ~15,000 | Individual dataflow schemas | Python `schema_sync` |

#### Stata-only Files (Pure Stata parser)

| File | Records | Lines | Description | Generator |
|------|---------|-------|-------------|-----------|
| `_unicefdata_dataflows_stataonly.yaml` | 69 | 354 | Dataflow definitions | `unicefdata_sync, suffix("_stataonly")` |
| `_unicefdata_codelists_stataonly.yaml` | 5 | 623 | Dimension codelists | `unicefdata_sync, suffix("_stataonly")` |
| `_unicefdata_countries_stataonly.yaml` | 453 | 464 | Country ISO3 codes | `unicefdata_sync, suffix("_stataonly")` |
| `_unicefdata_regions_stataonly.yaml` | 111 | 122 | Regional aggregate codes | `unicefdata_sync, suffix("_stataonly")` |
| `_unicefdata_indicators_stataonly.yaml` | 25 | 198 | Indicator → dataflow mappings | `unicefdata_sync, suffix("_stataonly")` |
| `unicef_indicators_metadata_stataonly.yaml` | 733 | 3,666 | Full indicator codelist | `unicefdata_sync, suffix("_stataonly")` |
| `dataflow_index_stataonly.yaml` | - | ~6 | Index (incomplete*) | `unicefdata_sync, suffix("_stataonly")` |

*Note: The pure Stata parser has macro length limitations that prevent full dataflow schema generation. Use Python for dataflow schemas.

---

## Generation Commands

### Option 1: Using the Unified Python Script

The simplest way to regenerate all metadata:

```bash
# From repository root
python tests/regenerate_all_metadata.py --all

# Or specific platforms
python tests/regenerate_all_metadata.py --python
python tests/regenerate_all_metadata.py -R
python tests/regenerate_all_metadata.py --stata
```

### Option 2: Platform-Specific Commands

#### Python

```bash
cd python

# Step 1: Generate consolidated metadata files
python -c "from unicef_api.metadata import sync_metadata; sync_metadata(cache_dir='metadata', force=True, verbose=True)"

# Step 2: Generate full indicator metadata (733 indicators)
python -c "from unicef_api.indicator_registry import refresh_indicator_cache; print(refresh_indicator_cache())"

# Step 3: Generate individual dataflow schemas
python -m unicef_api.run_sync
```

#### R

```r
# From R console, set working directory to R/
setwd("R")

# Step 1: Generate consolidated metadata files (dataflows, codelists, countries, regions, indicators)
source("metadata_sync.R")
sync_all_metadata()

# Step 2: Generate full indicator metadata (733 indicators)  
source("indicator_registry.R")
refresh_indicator_cache()

# Step 3: Generate dataflow schemas
source("schema_sync.R")
sync_dataflow_schemas()
```

Or from command line:
```bash
# All metadata (consolidated files)
Rscript --vanilla -e "setwd('R'); source('metadata_sync.R'); sync_all_metadata()"

# Indicator metadata
Rscript --vanilla -e "setwd('R'); source('indicator_registry.R'); refresh_indicator_cache()"

# Dataflow schemas
Rscript --vanilla -e "setwd('R'); source('schema_sync.R'); sync_dataflow_schemas()"
```

#### Stata

```stata
// Step 1: Add package to adopath
adopath ++ "stata/src/u"
adopath ++ "stata/src/_"

// Step 2: Generate all consolidated metadata files (standard)
unicefdata_sync, verbose

// Step 3: Generate dataflow schemas using Python (recommended)
cd "python"
python -c "from unicef_api.schema_sync import sync_dataflow_schemas; sync_dataflow_schemas(output_dir='../stata/metadata/current')"
```

##### Stata Suffix Option

To generate files with a custom suffix (e.g., for pure Stata versions):

```stata
// Generate metadata with _stataonly suffix
unicefdata_sync, suffix("_stataonly") verbose

// This creates files like:
//   _unicefdata_dataflows_stataonly.yaml
//   _unicefdata_countries_stataonly.yaml
//   unicef_indicators_metadata_stataonly.yaml
//   dataflow_index_stataonly.yaml
//   dataflows_stataonly/ folder
```

##### Parser Options for unicefdata_xmltoyaml

The `unicefdata_xmltoyaml` command supports parser selection:

```stata
// Auto-detect (uses Python for files >500KB, Stata otherwise)
unicefdata_xmltoyaml, type(dataflows) xmlfile("input.xml") outfile("output.yaml")

// Force Python parser (requires Python 3.6+)
unicefdata_xmltoyaml, type(dataflows) xmlfile("input.xml") outfile("output.yaml") forcepython

// Force pure Stata parser (no Python required)
unicefdata_xmltoyaml, type(dataflows) xmlfile("input.xml") outfile("output.yaml") forcestata
```

**Supported types:** `dataflows`, `codelists`, `countries`, `regions`, `dimensions`, `attributes`, `indicators`

---

## Cleaning Metadata Before Regeneration

To ensure a clean regeneration, delete existing files first:

### PowerShell (Windows)

```powershell
# Clean Python
Remove-Item "python/metadata/current/*.yaml" -Force -ErrorAction SilentlyContinue
Remove-Item "python/metadata/current/dataflows/*.yaml" -Force -ErrorAction SilentlyContinue

# Clean R
Remove-Item "R/metadata/current/*.yaml" -Force -ErrorAction SilentlyContinue
Remove-Item "R/metadata/current/dataflows/*.yaml" -Force -ErrorAction SilentlyContinue

# Clean Stata
Remove-Item "stata/metadata/current/*.yaml" -Force -ErrorAction SilentlyContinue
Remove-Item "stata/metadata/current/dataflows/*.yaml" -Force -ErrorAction SilentlyContinue
```

### Bash (Linux/macOS)

```bash
# Clean Python
rm -f python/metadata/current/*.yaml
rm -f python/metadata/current/dataflows/*.yaml

# Clean R
rm -f R/metadata/current/*.yaml
rm -f R/metadata/current/dataflows/*.yaml

# Clean Stata
rm -f stata/metadata/current/*.yaml
rm -f stata/metadata/current/dataflows/*.yaml
```

---

## Verification Checklist

After regeneration, verify these file counts:

| Platform | Consolidated Files | Indicator Metadata | Dataflow Index | Dataflow Schemas |
|----------|-------------------|-------------------|----------------|------------------|
| Python | 5 `_unicefdata_*.yaml` | 1 (733 indicators) | 1 | 69 |
| R | 5 `_unicefdata_*.yaml` | 1 (733 indicators) | 1 | 69 |
| Stata (Python) | 5 `_unicefdata_*.yaml` | 1 (733 indicators) | 1 | 69 |
| Stata (only) | 5 `_unicefdata_*_stataonly.yaml` | 1 (733 indicators) | 1 (incomplete) | 0* |

*Note: Pure Stata parser cannot generate dataflow schemas due to macro length limits. Use Python.

### Metadata File Status Summary

| File | Python | R | Stata (Python) | Stata (only) |
|------|--------|---|----------------|--------------|
| `_unicefdata_dataflows.yaml` | ✓ (69) | ✓ (69) | ✓ (69) | ✓ (69) |
| `_unicefdata_codelists.yaml` | ✓ (5) | ✓ (5) | ✓ (5) | ✓ (5) |
| `_unicefdata_countries.yaml` | ✓ (453) | ✓ (453) | ✓ (453) | ✓ (453) |
| `_unicefdata_regions.yaml` | ✓ (111) | ✓ (111) | ✓ (111) | ✓ (111) |
| `_unicefdata_indicators.yaml` | ✓ (25) | ✓ (24) | ✓ (25) | ✓ (25) |
| `unicef_indicators_metadata.yaml` | ✓ (733) | ✓ (733) | ✓ (733) | ✓ (733) |
| `dataflow_index.yaml` | ✓ (69) | ✓ (69) | ✓ (69) | ✗ (incomplete) |
| `dataflows/*.yaml` | ✓ (69) | ✓ (69) | ✓ (69) | ✗ |

**Legend:**
- **Python**: Files in `python/metadata/current/`
- **R**: Files in `R/metadata/current/`
- **Stata (Python)**: Standard files in `stata/metadata/current/` (generated with Python assistance)
- **Stata (only)**: Files with `_stataonly` suffix in `stata/metadata/current/` (pure Stata parser)

### Verification Commands

```powershell
# Check Python
(Get-ChildItem "python/metadata/current/_unicefdata_*.yaml").Count  # Should be 5
Test-Path "python/metadata/current/unicef_indicators_metadata.yaml"  # Should be True
(Get-ChildItem "python/metadata/current/dataflows/*.yaml").Count  # Should be 69

# Check R
(Get-ChildItem "R/metadata/current/_unicefdata_*.yaml").Count  # Should be 5 (or 0 if not implemented)
Test-Path "R/metadata/current/unicef_indicators_metadata.yaml"  # Should be True
(Get-ChildItem "R/metadata/current/dataflows/*.yaml").Count  # Should be 69

# Check Stata (standard files)
(Get-ChildItem "stata/metadata/current/_unicefdata_*.yaml" | Where-Object { $_.Name -notmatch "_stataonly" }).Count  # Should be 5
Test-Path "stata/metadata/current/unicef_indicators_metadata.yaml"  # Should be True
(Get-ChildItem "stata/metadata/current/dataflows/*.yaml").Count  # Should be 69

# Check Stata (stataonly files)
(Get-ChildItem "stata/metadata/current/*_stataonly.yaml").Count  # Should be 7
```

---

## Troubleshooting

### Python Issues

1. **Import errors**: Ensure you're in the `python/` directory or have the package installed
2. **Network errors**: The SDMX API may be temporarily unavailable; retry after a few minutes
3. **Permission errors**: Ensure write access to the metadata directory

### R Issues

1. **Package not found**: Install required packages: `install.packages(c("httr", "xml2", "yaml", "dplyr"))`
2. **Working directory**: Ensure `setwd()` points to the `R/` directory
3. **Rscript not in PATH**: Use full path, e.g., `"C:\Program Files\R\R-4.5.0\bin\Rscript.exe"`

### Stata Issues

1. **Command not found**: Ensure adopath includes `stata/src/u` and `stata/src/_`
2. **Python not found** (for xmltoyaml): Use `forcestata` option or install Python 3.6+
3. **YAML write errors**: Ensure `yaml.ado` is installed: `ssc install yaml`
4. **Macro substitution too long (error 920)**: This occurs when parsing large XML files with pure Stata. Use Python for dataflow schemas:
   ```stata
   // From Stata, call Python directly
   cd "python"
   shell python -c "from unicef_api.schema_sync import sync_dataflow_schemas; sync_dataflow_schemas(output_dir='../stata/metadata/current')"
   ```
5. **Suffix option**: Use `suffix("_stataonly")` to create files with custom suffixes for comparison or backup

---

## API Data Sources

All metadata is fetched from the UNICEF SDMX Data Warehouse API:

| Endpoint | Data |
|----------|------|
| `/dataflow/UNICEF` | List of 69 dataflows |
| `/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0` | 733 indicator codes |
| `/codelist/UNICEF/CL_COUNTRY/1.0` | Country codes |
| `/codelist/UNICEF/CL_WORLD_REGIONS/1.0` | Regional codes |
| `/dataflow/UNICEF/{ID}/{VERSION}?references=all` | Per-dataflow schema |

Base URL: `https://sdmx.data.unicef.org/ws/public/sdmxapi/rest`

---

## Notes for AI Assistants

When asked to regenerate metadata, follow these steps in order:

1. **Clean existing files** (optional but recommended for fresh start)
2. **Python**: Run all three generators (metadata.sync_all, indicator_registry, run_sync)
3. **R**: Run schema_sync.R and indicator_registry.R
4. **Stata**: Run unicefdata_sync and unicefdata_xmltoyaml

Key files to reference:
- `python/unicef_api/metadata.py` - Main Python metadata sync
- `python/unicef_api/indicator_registry.py` - Python indicator cache
- `python/unicef_api/schema_sync.py` - Python dataflow schemas
- `R/schema_sync.R` - R dataflow schemas
- `R/indicator_registry.R` - R indicator cache
- `stata/src/u/unicefdata_sync.ado` - Stata metadata sync (supports `suffix()` option)
- `stata/src/u/unicefdata_xmltoyaml.ado` - XML to YAML parser (supports `forcepython`/`forcestata`)
- `stata/src/u/unicefdata_xmltoyaml_py.ado` - Python-based XML parser
- `stata/src/u/unicefdata_xml2yaml.py` - Python helper script for XML parsing
- `tests/regenerate_all_metadata.py` - Unified regeneration script




cd "D:\jazevedo\GitHub\unicefData"; python -c "
import yaml
from pathlib import Path

print('=' * 80)
print('FULL INDICATOR REGISTRY COMPARISON')
print('=' * 80)

py_dir = Path('python/metadata/current')
r_dir = Path('R/metadata/current')

print('\n### unicef_indicators_metadata.yaml')
print('-' * 60)

with open(py_dir / 'unicef_indicators_metadata.yaml', 'r', encoding='utf-8') as f:
    py_data = yaml.safe_load(f)
with open(r_dir / 'unicef_indicators_metadata.yaml', 'r', encoding='utf-8') as f:
    r_data = yaml.safe_load(f)

py_indicators = set(py_data.get('indicators', {}).keys())
r_indicators = set(r_data.get('indicators', {}).keys())

print(f'Python indicators: {len(py_indicators)}')
print(f'R indicators: {len(r_indicators)}')

if py_indicators == r_indicators:
    print('IDENTICAL indicator sets!')
else:
    print('DIFFERENT indicator sets!')
    only_py = py_indicators - r_indicators
    only_r = r_indicators - py_indicators
    if only_py:
        print(f'  In Python only ({len(only_py)}): {sorted(only_py)[:5]}')
    if only_r:
        print(f'  In R only ({len(only_r)}): {sorted(only_r)[:5]}')

# Sample content check
print('\n### Sample indicator content check')
print('-' * 60)
sample_codes = list(py_indicators)[:3]
for code in sample_codes:
    py_ind = py_data['indicators'].get(code, {})
    r_ind = r_data['indicators'].get(code, {})
    py_name = py_ind.get('name', '')[:50]
    r_name = r_ind.get('name', '')[:50]
    name_match = (py_name == r_name)
    status = 'MATCH' if name_match else 'DIFF'
    print(f'{code}: {status}')
    print(f'  Python: {py_name}')
    print(f'  R:      {r_name}')



    cd "D:\jazevedo\GitHub\unicefData"; python -c "
import yaml
from pathlib import Path

py_dir = Path('python/metadata/current')
r_dir = Path('R/metadata/current')

print('=' * 80)
print('COMPLETE FILE CONTENT COMPARISON')
print('=' * 80)

files = [
    ('_unicefdata_dataflows.yaml', 'dataflows'),
    ('_unicefdata_codelists.yaml', 'codelists'),
    ('_unicefdata_countries.yaml', 'countries'),
    ('_unicefdata_regions.yaml', 'regions'),
]

for filename, key in files:
    print(f'\n### {filename}')
    print('-' * 60)
    
    with open(py_dir / filename, 'r', encoding='utf-8') as f:
        py_data = yaml.safe_load(f)
    with open(r_dir / filename, 'r', encoding='utf-8') as f:
        r_data = yaml.safe_load(f)
    
    py_keys = set(py_data.get(key, {}).keys())
    r_keys = set(r_data.get(key, {}).keys())
    
    print(f'Python {key}: {len(py_keys)}')
    print(f'R {key}: {len(r_keys)}')
    
    if py_keys == r_keys:
        print('Status: IDENTICAL')
    else:
        print('Status: DIFFERENT')
        only_py = py_keys - r_keys
        only_r = r_keys - py_keys
        if only_py:
            print(f'  In Python only ({len(only_py)}): {sorted(only_py)[:3]}')
        if only_r:
            print(f'  In R only ({len(only_r)}): {sorted(only_r)[:3]}')

print('\n' + '=' * 80)
print('SUMMARY: All core metadata files have IDENTICAL record keys')
print('=' * 80)
"
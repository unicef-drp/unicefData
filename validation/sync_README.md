# unicefData Test Suite

This directory contains test scripts and metadata synchronization utilities for the unicefData package.

## Directory Structure

```
validation/
├── README.md                          # This file
├── logs/                              # Log files from script executions
│   └── .gitkeep
├── metadata/                          # Test metadata snapshots
│   ├── current/                       # Current test metadata
│   └── vintages/                      # Historical snapshots by date
├── testthat/                          # R unit tests (testthat framework)
│   ├── test-available_indicators.R
│   ├── test-build_indicator_catalog.R
│   └── test-get_unicef.R
├── testthat.R                         # R CMD check test runner
│
├── # === Orchestrators === #
├── orchestrator_metadata.py           # Master orchestrator (Python)
├── orchestrator_metadata.ps1          # Master orchestrator (PowerShell)
│
├── # === Standalone Sync Scripts === #
├── sync_metadata_python.py            # Python metadata sync
├── sync_metadata_r.R                  # R metadata sync
├── sync_metadata_stata.do             # Stata metadata sync (Python-assisted)
├── sync_metadata_stataonly.do         # Stata metadata sync (pure Stata parser)
│
├── # === Reporting === #
├── report_metadata_status.py          # Compare metadata across platforms
│
└── # === Additional Tests === #
    └── test_prod_sdg_indicators.py    # PROD-SDG-REP-2025 indicator tests
```

## Quick Start

### Sync All Metadata (Recommended)

Use the orchestrator to sync metadata for all languages in one command:

```powershell
# From repository root
python validation/orchestrator_metadata.py --all

# Or using PowerShell orchestrator
.\tests\orchestrator_metadata.ps1 -All
```

### Sync Individual Languages

```powershell
# Python only
python validation/sync_metadata_python.py

# R only
Rscript validation/sync_metadata_r.R

# Stata only (with Python helper - recommended)
do validation/sync_metadata_stata.do

# Stata only (pure Stata parser - may hit macro limits)
do validation/sync_metadata_stataonly.do
```

## Script Reference

### Orchestrators

These scripts coordinate metadata synchronization across all three languages.

| Script | Description |
|--------|-------------|
| `orchestrator_metadata.py` | Python-based orchestrator that calls standalone sync scripts |
| `orchestrator_metadata.ps1` | PowerShell-based orchestrator with interactive prompts |

**Python Orchestrator Usage:**
```powershell
python validation/orchestrator_metadata.py --all          # Sync all languages
python validation/orchestrator_metadata.py --python       # Python only
python validation/orchestrator_metadata.py --stata        # Stata only
python validation/orchestrator_metadata.py -R             # R only
python validation/orchestrator_metadata.py --python -R    # Python and R
python validation/orchestrator_metadata.py --verbose      # Verbose output
```

**PowerShell Orchestrator Usage:**
```powershell
.\tests\orchestrator_metadata.ps1 -All          # Sync all (prompts if files exist)
.\tests\orchestrator_metadata.ps1 -Python       # Python only
.\tests\orchestrator_metadata.ps1 -Stata        # Stata only
.\tests\orchestrator_metadata.ps1 -R            # R only
.\tests\orchestrator_metadata.ps1 -All -Force   # Overwrite without prompting
```

### Standalone Sync Scripts

Each language has its own standalone sync script that can be run independently.

| Script | Language | Parser | Output Directory |
|--------|----------|--------|------------------|
| `sync_metadata_python.py` | Python | Native | `python/metadata/current/` |
| `sync_metadata_r.R` | R | Native | `R/metadata/current/` |
| `sync_metadata_stata.do` | Stata | Python-assisted | `stata/metadata/current/` |
| `sync_metadata_stataonly.do` | Stata | Pure Stata | `stataonly/metadata/current/` |

**Note:** The `sync_metadata_stataonly.do` script uses a pure Stata YAML parser, which may hit Stata's macro length limits for very large files (like the indicator metadata with 730+ indicators). Its output goes to a separate `stataonly/` folder for cleaner git tracking.

### Reporting

| Script | Description |
|--------|-------------|
| `report_metadata_status.py` | Generates a comparison table showing metadata status across all platforms |

**Usage:**
```powershell
python validation/report_metadata_status.py              # Default markdown output
python validation/report_metadata_status.py --output csv # CSV output
python validation/report_metadata_status.py --detailed   # Detailed per-file stats
python validation/report_metadata_status.py --compare    # Compare record counts
```

### Unit Tests (R)

The `testthat/` directory contains R unit tests using the testthat framework.

```r
# Run all R tests
devtools::test()

# Run from command line
Rscript -e "devtools::test()"

# Run during R CMD check
R CMD check .
```

### Additional Tests

| Script | Description |
|--------|-------------|
| `test_prod_sdg_indicators.py` | Tests the `get_unicef()` function by downloading indicators used in PROD-SDG-REP-2025 |

## Log Files

All scripts write their output to `validation/logs/`:

| Log File | Source Script |
|----------|---------------|
| `orchestrator_metadata.log` | `orchestrator_metadata.py` or `orchestrator_metadata.ps1` |
| `sync_metadata_python.log` | `sync_metadata_python.py` |
| `sync_metadata_r.log` | `sync_metadata_r.R` |
| `sync_metadata_stata.log` | `sync_metadata_stata.do` |
| `sync_metadata_stataonly.log` | `sync_metadata_stataonly.do` |
| `report_metadata_status.log` | `report_metadata_status.py` |

## Metadata Output Locations

After running sync scripts, metadata files are written to:

| Platform | Directory | Key Files |
|----------|-----------|-----------|
| Python | `python/metadata/current/` | `unicef_indicators_metadata.yaml`, `dataflows/*.yaml` |
| R | `R/metadata/current/` | `unicef_indicators_metadata.yaml`, `dataflows/*.yaml` |
| Stata | `stata/metadata/current/` | `unicef_indicators_metadata.yaml`, `dataflows/*.yaml` |
| Stata (pure) | `stataonly/metadata/current/` | Core metadata files (no large files due to macro limits) |

## Prerequisites

- **Python 3.10+** with virtual environment at `C:\GitHub\.venv`
- **R 4.3+** with devtools, testthat, yaml packages
- **Stata 17+** (MP or SE edition)

## Troubleshooting

### Stata Macro Limits
The `sync_metadata_stataonly.do` script may fail for large metadata files due to Stata's macro length limits. Use `sync_metadata_stata.do` (Python-assisted) for reliable syncing.

### Missing Dependencies
Ensure the virtual environment is activated and packages are installed:
```powershell
& C:\GitHub\.venv\Scripts\Activate.ps1
pip install requests pyyaml
```

### R Package Loading
If R scripts fail to load the package, ensure you're in the repository root:
```r
setwd("C:/GitHub/others/unicefData")
devtools::load_all(".")
```

# Validation & Testing Infrastructure

This directory contains the validation and metadata synchronization infrastructure for the `unicefData` package. It ensures consistency across R, Python, and Stata implementations.

## Quick Reference

| Task | Command |
|------|---------|
| Run R tests | `Rscript -e "setwd('C:/GitHub/others/unicefData'); devtools::test()"` |
| Run Python tests | `cd python && pytest tests/ -v` |
| Sync all metadata | `python validation/orchestrator_metadata.py --all` |
| Compare R/Python outputs | `python validation/validate_outputs.py` |
| Check metadata status | `python validation/report_metadata_status.py` |

## Directory Structure

```
validation/
├── README.md                          # This file
├── logs/                              # Log files from script executions
├── data/                              # Example outputs for cross-language validation
│   ├── python/                        # Python example outputs
│   ├── r/                             # R example outputs
│   └── stata/                         # Stata example outputs
│
├── # === Orchestrators === #
├── orchestrator_metadata.py           # Master orchestrator (Python)
├── orchestrator_metadata.ps1          # Master orchestrator (PowerShell)
│
├── # === Sync Scripts === #
├── sync_metadata_python.py            # Python metadata sync
├── sync_metadata_r.R                  # R metadata sync  
├── sync_metadata_stata.do             # Stata metadata sync (Python-assisted)
├── sync_metadata_stataonly.do         # Stata metadata sync (pure Stata)
│
├── # === Validation === #
├── validate_outputs.py                # Compare R vs Python vs Stata outputs
├── report_metadata_status.py          # Metadata comparison report
└── test_prod_sdg_indicators.py        # SDG indicator tests
```

## Unit Tests

### R Tests (testthat)

The R package uses the standard testthat framework. Tests are in `tests/testthat/`:

```powershell
# Run all R unit tests
Rscript -e "setwd('C:/GitHub/others/unicefData'); devtools::test()"

# Run R CMD check (includes tests)
Rscript -e "setwd('C:/GitHub/others/unicefData'); devtools::check()"
```

Test files:
- `test-unicefData.R` - Core `unicefData()` function tests
- `test-available_indicators.R` - Indicator discovery tests
- `test-build_indicator_catalog.R` - Catalog building tests

### Python Tests (pytest)

```powershell
cd C:\GitHub\others\unicefData\python
$env:PYTHONPATH = "C:\GitHub\others\unicefData\python"
pytest tests/ -v
```

Test files:
- `test_unicef_api.py` - Core API and client tests
- `test_metadata_manager.py` - Metadata management tests

### Additional Test Scripts

Located in `R/tests/` and `python/tests/`:

| Script | Description |
|--------|-------------|
| `R/tests/run_tests.R` | Comprehensive R test suite with CSV output |
| `R/tests/test_prod_sdg_indicators.R` | SDG Report indicator tests |
| `R/tests/test_fallback.R` | Dataflow fallback logic tests |
| `python/tests/run_tests.py` | Comprehensive Python test suite |

---

## Metadata Synchronization

### Sync All Platforms

Use the orchestrator to sync metadata for all languages:

```powershell
# Sync all (Python, R, Stata)
python validation/orchestrator_metadata.py --all

# Verbose output
python validation/orchestrator_metadata.py --all --verbose
```

### Sync Individual Platforms

```powershell
# Python only
python validation/sync_metadata_python.py

# R only
Rscript validation/sync_metadata_r.R

# Stata (Python-assisted - recommended)
do validation/sync_metadata_stata.do

# Stata (pure Stata parser)
do validation/sync_metadata_stataonly.do
```

### Orchestrator Options

**Python Orchestrator (`orchestrator_metadata.py`):**

```powershell
python validation/orchestrator_metadata.py --all          # All platforms
python validation/orchestrator_metadata.py --python       # Python only
python validation/orchestrator_metadata.py --stata        # Stata only
python validation/orchestrator_metadata.py -R             # R only
python validation/orchestrator_metadata.py --python -R    # Python and R
```

**PowerShell Orchestrator (`orchestrator_metadata.ps1`):**

```powershell
.\validation\orchestrator_metadata.ps1 -All          # All (prompts if files exist)
.\validation\orchestrator_metadata.ps1 -Python       # Python only
.\validation\orchestrator_metadata.ps1 -R            # R only
.\validation\orchestrator_metadata.ps1 -All -Force   # Overwrite without prompting
```

### Metadata Output Locations

| Platform | Directory |
|----------|-----------|
| Python | `python/metadata/current/` |
| R | `R/metadata/current/` |
| Stata | `stata/metadata/current/` |
| Stata (pure) | `stataonly/metadata/current/` |

---

## Output Validation

### Compare R vs Python vs Stata Outputs

Validates that all language implementations produce identical results:

```powershell
# Compare all languages (auto-detect available outputs)
python validation/validate_outputs.py

# Explicitly include all three languages
python validation/validate_outputs.py --all

# Compare only Python and R
python validation/validate_outputs.py --python-r
```

**What it checks:**
1. Matching CSV files in `validation/data/python/`, `validation/data/r/`, `validation/data/stata/`
2. Row counts and column names
3. Key column values (iso3, indicator, period)
4. Numeric values with tolerance (0.001)

**Output:** `validation/validation_results.csv`

### Generate Example Outputs

Run the example scripts to generate CSV outputs for comparison:

```powershell
# Python examples
cd python/examples && python 00_quick_start.py

# R examples  
Rscript R/examples/00_quick_start.R

# Stata examples (in Stata)
do stata/examples/00_quick_start.do
```

Outputs are saved to:
- `validation/data/python/*.csv`
- `validation/data/r/*.csv`
- `validation/data/stata/*.csv`

### Metadata Status Report

Compare metadata across platforms:

```powershell
python validation/report_metadata_status.py              # Markdown output
python validation/report_metadata_status.py --output csv # CSV output
python validation/report_metadata_status.py --detailed   # Per-file stats
python validation/report_metadata_status.py --compare    # Compare record counts
```

---

## Workflow: Full Validation

1. **Sync metadata** (if needed):
   ```powershell
   python validation/orchestrator_metadata.py --all
   ```

2. **Run R tests**:
   ```powershell
   Rscript -e "setwd('C:/GitHub/others/unicefData'); devtools::test()"
   ```

3. **Run Python tests**:
   ```powershell
   cd C:\GitHub\others\unicefData\python
   pytest tests/ -v
   ```

4. **Run comprehensive tests** (generates output files):
   ```powershell
   Rscript R/tests/run_tests.R
   python python/tests/run_tests.py
   ```

5. **Validate outputs match**:
   ```powershell
   python validation/validate_outputs.py
   ```

6. **R CMD check** (before PR):
   ```powershell
   Rscript -e "setwd('C:/GitHub/others/unicefData'); devtools::check()"
   ```

---

## Log Files

Scripts write logs to `validation/logs/`:

| Log File | Source |
|----------|--------|
| `orchestrator_metadata.log` | Orchestrator scripts |
| `sync_metadata_python.log` | Python sync |
| `sync_metadata_r.log` | R sync |
| `sync_metadata_stata.log` | Stata sync |

---

## Troubleshooting

### Stata Macro Limits
The `sync_metadata_stataonly.do` may fail for large files due to Stata's macro limits. Use `sync_metadata_stata.do` (Python-assisted) instead.

### Python Environment
```powershell
& C:\GitHub\.venv\Scripts\Activate.ps1
pip install requests pyyaml pytest
```

### R Package Loading
```r
setwd("C:/GitHub/others/unicefData")
devtools::load_all(".")
```

### Missing Dependencies
```powershell
# R packages
Rscript -e "install.packages(c('devtools', 'testthat', 'yaml', 'httr', 'dplyr'))"

# Python packages
pip install requests pyyaml pandas pytest
```

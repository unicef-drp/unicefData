# Validation

This folder contains scripts to validate that the R and Python packages produce identical outputs.

## Usage

```bash
cd validation
python validate_outputs.py
```

## What it does

1. Scans for matching CSV files in:
   - `python/tests/output/*.csv` vs `R/tests/output/*.csv`
   - `python/examples/data/*.csv` vs `R/examples/data/*.csv`
2. Skips metadata files (`test_indicators.csv`, `test_codelists.csv`)
3. Compares each matching pair for:
   - Row counts
   - Column names
   - Key column values (iso3, indicator, period) with numeric tolerance
   - Numeric values (with 0.001 tolerance)
4. Generates `validation_results.csv` with summary

## Output

```
validation/
├── validate_outputs.py      # Main validation script
├── validation_results.csv   # Results summary (generated)
└── README.md
```

## Workflow

1. Run tests in Python: `python python/tests/run_tests.py`
2. Run tests in R: `Rscript R/tests/run_tests.R`
3. Run examples in Python:
   ```bash
   python python/examples/00_quick_start.py
   python python/examples/01_indicator_discovery.py
   python python/examples/02_sdg_indicators.py
   ```
4. Run examples in R:
   ```bash
   Rscript R/examples/00_quick_start.R
   Rscript R/examples/01_indicator_discovery.R
   Rscript R/examples/02_sdg_indicators.R
   ```
5. Validate outputs match: `python validation/validate_outputs.py`

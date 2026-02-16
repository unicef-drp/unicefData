# Comprehensive Indicator Validation Suite

## Overview

This validation suite provides **comprehensive cross-platform testing** of all indicators supported by the unicefData package across Python, R, and Stata. It tests each indicator's download functionality, captures detailed error logs, and generates unified reports.

## Architecture

### Scripts

| Script | Language | Purpose |
|--------|----------|---------|
| `test_all_indicators_comprehensive.py` | Python | Master orchestrator for Python-based validation |
| `test_indicator_suite.R` | R | Comprehensive R indicator test suite |
| `test_indicator_suite.do` | Stata | Comprehensive Stata indicator test suite |
| `orchestrator_indicator_tests.py` | Python | Wrapper for Python orchestrator |
| `orchestrator_full_indicator_tests.ps1` | PowerShell | Master orchestrator for all languages |

### Output Structure

```
validation/results/
├── indicator_validation_YYYYMMDD_HHMMSS/  (Python runs this)
│   ├── SUMMARY.md                        # Executive summary (all indicators)
│   ├── detailed_results.csv              # All results as CSV
│   ├── detailed_results.json             # All results as JSON
│   ├── python/
│   │   ├── test_log.txt
│   │   ├── success/
│   │   │   ├── CME_MRY0T4.csv           # Downloaded data
│   │   │   └── ...
│   │   └── failed/
│   │       ├── INDICATOR_CODE.error     # Error messages
│   │       └── ...
│   ├── r/
│   │   ├── test_log.txt
│   │   ├── success/
│   │   └── failed/
│   └── stata/
│       ├── test_log.txt
│       ├── success/
│       └── failed/
│
└── full_validation_YYYYMMDD_HHMMSS/      (PowerShell runs this)
    ├── orchestrator_log.txt              # Master log
    ├── python_test.log
    ├── r_test.log
    ├── stata_test.log
    ├── CROSS_LANGUAGE_REPORT.md         # Comparison report
    └── comparison.log
```

## Usage

### Quick Start (Python)

```bash
# Test first 10 indicators (default countries: USA, BRA, IND, KEN, CHN)
python validation/test_all_indicators_comprehensive.py --limit 10

# Test specific indicators only
python validation/test_all_indicators_comprehensive.py \
    --indicators CME_MRY0T4 WSHPOL_SANI_TOTAL NUTRI_STU_0TO4_TOT

# Test only Python and R (skip Stata)
python validation/test_all_indicators_comprehensive.py \
    --languages python r --limit 5
```

### Full Cross-Platform Test

```powershell
# Run all languages (Python, R, Stata)
.\validation\orchestrator_full_indicator_tests.ps1

# Test only R
.\validation\orchestrator_full_indicator_tests.ps1 -OnlyR

# Test first 5 indicators across all languages
.\validation\orchestrator_full_indicator_tests.ps1 -Limit 5

# Test specific indicators with custom year
.\validation\orchestrator_full_indicator_tests.ps1 `
    -Indicators CME_MRY0T4,WSHPOL_SANI_TOTAL `
    -Year 2018
```

### Advanced Usage

```bash
# Python: Test with different countries and year
python validation/test_all_indicators_comprehensive.py \
    --countries USA BRA IND \
    --year 2015 \
    --limit 20

# Python: Generate reports to custom directory
python validation/test_all_indicators_comprehensive.py \
    --output-dir ./my_results \
    --limit 50

# R: Standalone test
Rscript validation/test_indicator_suite.R

# Stata: Standalone test
stata-cli do validation/test_indicator_suite.do
```

## Output Files

### Summary Report (SUMMARY.md)

Example output:

```markdown
# Comprehensive Indicator Validation Report

Generated: 2026-01-10 14:30:00

## Executive Summary

- **Total tests**: 150 (50 indicators × 3 languages)

### Results by Status

| Status | Count | Percentage |
|--------|-------|-----------|
| success | 145 | 96.7% |
| failed | 3 | 2.0% |
| not_found | 2 | 1.3% |

### Results by Language

| Language | Count | Percentage |
|----------|-------|-----------|
| python | 50 | 33.3% |
| r | 50 | 33.3% |
| stata | 50 | 33.3% |

## Failures

### CME_MRM0 (python)
- **Status**: failed
- **Error**: Connection timeout after 30 seconds
- **Time**: 30.15s

### NUTRI_STU_0TO4_TOT (stata)
- **Status**: not_found
- **Error**: Indicator not available in dataflow
```

### Detailed Results (detailed_results.csv)

```csv
indicator_code,language,status,rows_returned,execution_time_sec,error_message,timestamp,output_file
CME_MRY0T4,python,success,25,3.5,,2026-01-10T14:30:00,python/success/CME_MRY0T4.csv
CME_MRY0T4,r,success,25,4.2,,2026-01-10T14:30:05,r/success/CME_MRY0T4.csv
CME_MRY0T4,stata,success,25,5.1,,2026-01-10T14:30:10,stata/success/CME_MRY0T4.csv
WSHPOL_SANI_TOTAL,python,success,30,2.8,,2026-01-10T14:30:15,python/success/WSHPOL_SANI_TOTAL.csv
```

### Error Files (python/failed/INDICATOR.error)

```
Error: HTTPError 404 Client Error: Not Found for url: https://sdmx.data.unicef.org/...
Indicator: INVALID_CODE
Countries: ['USA', 'BRA']
Year: 2020
```

## Success Criteria

An indicator test passes if:

1. **HTTP request succeeds** (status 200)
2. **Data is returned** (≥ 1 row)
3. **Core columns present**: iso3, indicator, period, value
4. **Output saved** to success directory

Indicators are flagged for:

- `failed`: HTTP errors, parsing errors, timeout
- `not_found`: 404 or empty result sets
- `timeout`: Exceeded 120s (R) or 180s (Stata) or 30s (Python)

## Interpreting Results

### All Languages Match

```
Indicator: CME_MRY0T4
python: success, 25 rows
r:      success, 25 rows
stata:  success, 25 rows
```

✅ **Action**: No action needed. Indicator is fully supported.

### Language Mismatch

```
Indicator: WSHPOL_SANI_TOTAL
python: success, 28 rows
r:      success, 28 rows
stata:  not_found, 0 rows
```

⚠️ **Action**: Investigate Stata implementation for this dataflow. Check if the indicator code maps to the correct dataflow in Stata.

### Complete Failure

```
Indicator: NUTRI_WST_0TO4_TOT
python: failed (404)
r:      failed (404)
stata:  not_found (0 rows)
```

❌ **Action**: Indicator may no longer exist in API, or is deprecated. Check UNICEF SDMX documentation.

### Partial Data

```
Indicator: MAT_SBA
python: success, 50 rows
r:      success, 50 rows
stata:  success, 12 rows
```

⚠️ **Action**: Possible filter mismatch in Stata (e.g., disaggregation levels differ). Compare CSV outputs to identify filter differences.

## Troubleshooting

### Script Doesn't Run

**Python**:
```bash
python -m pip install pyyaml pandas
python validation/test_all_indicators_comprehensive.py --limit 1
```

**R**:
```r
install.packages(c("unicefData", "dplyr", "readr"))
system("Rscript validation/test_indicator_suite.R")
```

**Stata**:
```stata
// Ensure unicefdata is installed
net install unicefdata, from(https://raw.githubusercontent.com/unicef-drp/unicefdata/main/stata/ssc)
discard
do validation/test_indicator_suite.do
```

### Network Timeout

Increase default timeout in scripts:

- **Python**: Modify `TIMEOUT_SECONDS` in test script
- **R**: Modify `timeout()` in `options()`
- **Stata**: Modify `timeout(180)` in do-file

### Memory Issues (Large Indicator Sets)

Reduce scope:

```bash
# Test fewer indicators
python validation/test_all_indicators_comprehensive.py --limit 10

# Test fewer countries
python validation/test_all_indicators_comprehensive.py \
    --countries USA BRA --limit 30
```

### Missing Data vs. API Errors

Check error files to distinguish:

```bash
# 404 (indicator not found)
grep "404" validation/results/*/failed/*.error

# Network error
grep "Connection" validation/results/*/failed/*.error

# Empty result (valid but no data)
grep "No data" validation/results/*/failed/*.error
```

## Performance Metrics

Typical execution time per indicator:

| Language | Success | Not Found | Failed |
|----------|---------|-----------|--------|
| Python | 2-5s | 0.5-2s | 5-10s |
| R | 3-6s | 1-3s | 5-15s |
| Stata | 4-8s | 1-4s | 8-20s |

**Total for 50 indicators**: ~30-45 minutes (all languages)

## Maintenance

### Update Indicator List

Edit `config/indicators.yaml` to add new indicators:

```yaml
indicators:
  NEW_INDICATOR_CODE:
    code: "NEW_INDICATOR_CODE"
    name: "Indicator Description"
    dataflow: "DATAFLOW_ID"
    unit: "Unit of measurement"
    category: "Category name"
```

### Test Specific Countries/Year

```bash
python validation/test_all_indicators_comprehensive.py \
    --countries ALB DZA AGO \
    --year 2022 \
    --limit 20
```

### Generate Compare Against Baseline

```bash
# Save baseline
python validation/test_all_indicators_comprehensive.py > baseline_results.json

# Compare to new run
python validation/test_all_indicators_comprehensive.py > new_results.json

# Diff (use external tool)
diff baseline_results.json new_results.json
```

## API Reference

### Python

```python
from validation.test_all_indicators_comprehensive import (
    IndicatorLoader,
    PythonTestRunner,
    TestResult,
    ReportGenerator
)

# Load all indicators
indicators = IndicatorLoader.load_all_available()

# Test single indicator
runner = PythonTestRunner(output_dir)
result = runner.test_indicator("CME_MRY0T4", ["USA", "BRA"], "2020")

# Generate reports
ReportGenerator(results, output_dir).generate_all()
```

### R

```r
source("validation/test_indicator_suite.R")

# Test runs automatically when script is sourced
```

### Stata

```stata
do validation/test_indicator_suite.do
// Results saved to validation/results/stata/
```

## Contributing

To add a new indicator test:

1. Add to `config/indicators.yaml`
2. Run validation suite
3. Check for failures in `failed/` directories
4. File issue if API-side problem detected

## License

MIT - See repo LICENSE

---

**Last Updated**: 2026-01-10  
**Version**: 1.0.0  
**Maintained by**: UNICEF Data and Analytics Team

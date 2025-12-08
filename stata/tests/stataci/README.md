# unicefdata Stata Tests (stataci Framework)

Test suite for the `unicefdata` Stata package using the stataci testing framework.

## Overview

These tests mirror the Python (`unicef_api`) and R (`unicefData`) test suites to ensure
consistent behavior across all three language implementations.

## Test Structure

```
stataci/
├── run_tests.do              # Master test runner
├── assert_utils.ado          # Enhanced assertion utilities
├── test_config.do            # Environment configuration tests
├── test_indicators_basic.do  # Basic indicator download tests
├── test_indicators_prod_sdg.do # Full PROD-SDG indicator suite
├── test_data_validation.do   # Data quality validation
├── test_api_comparison.do    # Cross-platform comparison
├── logs/                     # Test output logs
└── output/                   # Downloaded data files
```

## Running Tests

### From Stata

```stata
cd "D:\jazevedo\GitHub\unicefData\stata\tests\stataci"
do run_tests.do
```

### From Command Line (CI)

```powershell
cd D:\jazevedo\GitHub\unicefData\stata\tests\stataci
stata-mp -b do run_tests.do
```

### Run Individual Tests

```stata
cd "D:\jazevedo\GitHub\unicefData\stata\tests\stataci"
do test_indicators_basic.do
```

## Test Categories

### 1. Configuration (`test_config.do`)
- Verifies unicefdata command availability
- Checks network connectivity to UNICEF SDMX API
- Validates directory structure

### 2. Basic Indicators (`test_indicators_basic.do`)
Mirrors Python/R basic tests:
- Child Mortality (CME_MRY0T4)
- Stunting (NT_ANT_HAZ_NE2)
- Immunization (IM_DTP3)
- Multiple indicators

### 3. PROD-SDG Indicators (`test_indicators_prod_sdg.do`)
Full replication of PROD-SDG-REP-2025 indicators:
- Mortality (CME)
- Nutrition
- Education (UIS)
- Immunization
- HIV/AIDS
- WASH
- MNCH
- Child Protection
- Child Marriage
- FGM
- Child Poverty
- ECD

### 4. Data Validation (`test_data_validation.do`)
- Column structure validation
- Variable type checking
- Value range validation
- ISO3 code validation
- Missing value handling
- Duplicate detection

### 5. Cross-Platform Comparison (`test_api_comparison.do`)
- Compares Stata output with R/Python reference files
- Validates column harmonization
- Checks row count consistency
- Verifies value ranges match

## Assertion Utilities

Enhanced assertion library in `assert_utils.ado`:

### Numeric Assertions
```stata
assert_equal_num r(mean) 5.5
assert_approx r(mean) 5.5, tolerance(0.01)
assert_greater `a' `b'
assert_inrange `val' 0 100
```

### String Assertions
```stata
assert_equal_str "`var'" "price"
assert_contains "`text'" "search"
```

### Data Assertions
```stata
assert_nobs_min 100
assert_varexists iso3 indicator period
assert_vartype iso3, type(string)
assert_nomissing iso3 period
assert_unique iso3 period indicator
assert_values_in sex, values("_T M F")
```

### File Assertions
```stata
assert_file_exists "output/data.dta"
assert_dir_exists "output"
```

### Return Code Assertions
```stata
assert_rc_zero
assert_error 198
```

## Cross-Platform Validation

To validate consistency across Python, R, and Stata:

1. Run Python tests:
   ```bash
   cd unicefData/python/tests
   python run_tests.py
   ```

2. Run R tests:
   ```r
   source("unicefData/R/tests/run_tests.R")
   run_all_tests()
   ```

3. Run Stata tests:
   ```stata
   do run_tests.do
   ```

4. Compare outputs in `output/` directories

## CI Integration

Example GitHub Actions workflow:

```yaml
name: Stata Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: self-hosted  # Requires Stata license
    steps:
      - uses: actions/checkout@v4
      - name: Run Stata tests
        run: |
          cd stata/tests/stataci
          stata-mp -b do run_tests.do
      - name: Check results
        run: |
          if (Test-Path "stata/tests/stataci/logs/_PASSED.txt") {
            echo "Tests passed"
          } else {
            exit 1
          }
```

## Expected Output

Successful test run:
```
==============================================================================
     UNICEFDATA STATA PACKAGE - TEST SUITE (stataci)
     Date: 05 Dec 2025  Time: 14:30:00
     Stata: 17.0  OS: Windows
==============================================================================

----------------------------------------------------------------------
Running test: test_config
----------------------------------------------------------------------
[PASS] test_config

----------------------------------------------------------------------
Running test: test_indicators_basic
----------------------------------------------------------------------
[PASS] test_indicators_basic

...

==============================================================================
                           TEST SUMMARY
==============================================================================

     ALL TESTS PASSED SUCCESSFULLY

     Total:  5
     Passed: 5
     Failed: 0
```

## Author

João Pedro Azevedo (jpazevedo@unicef.org)

## Related

- Python package: `unicefData/python/unicef_api/`
- R package: `unicefData/R/`
- stataci framework: `ados/stataci/`

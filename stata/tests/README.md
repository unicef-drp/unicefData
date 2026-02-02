# Stata Tests with Mock API Fixtures

This directory contains Stata tests that use shared mock API fixtures from `tests/fixtures/api_responses/`.

## Philosophy

Unlike Python (which uses HTTP mocking with `responses` library), Stata tests read CSV fixture files directly. This approach:

- ✅ Simple and straightforward
- ✅ Fast (no HTTP overhead)
- ✅ Uses same fixture data as Python tests
- ✅ Tests data processing logic without API dependency

## Test Files

### test_mock_data.do

Tests basic fixture loading and data structure validation:
- Loads CSV files from `tests/fixtures/api_responses/`
- Verifies column structure matches SDMX schema
- Validates data types (numeric time_period, obs_value)
- Checks time series ordering
- Tests empty responses
- Compares cross-country data

**Run from stata/tests/ directory:**
```stata
cd stata/tests
do test_mock_data.do
```

## Fixture Files Used

All fixtures located in: `../../tests/fixtures/api_responses/`

| File | Purpose | Rows | Countries |
|------|---------|------|-----------|
| cme_albania_valid.csv | Valid CME data | 3 | ALB |
| cme_usa_valid.csv | Valid USA data | 2 | USA |
| empty_response.csv | Empty 404 response | 0 | - |
| dataflows.xml | Dataflow list (not used in Stata yet) | - | - |

## Expected CSV Structure

All data CSV files follow SDMX format:

```csv
DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS
CME,ALB,CME_MRY0T4,_T,2020,8.5,PER_1000_LIVEBIRTHS,AVAILABLE
```

**Columns**:
- `DATAFLOW`: Dataflow ID (CME, NUTRITION, etc.)
- `REF_AREA`: ISO 3166-1 alpha-3 country code
- `INDICATOR`: Indicator code (e.g., CME_MRY0T4)
- `SEX`: Sex disaggregation (_T=total, M=male, F=female)
- `TIME_PERIOD`: Year (numeric)
- `OBS_VALUE`: Numeric observation value
- `UNIT_MEASURE`: Unit (e.g., PER_1000_LIVEBIRTHS)
- `OBS_STATUS`: Status code (AVAILABLE, ESTIMATED, etc.)

## Writing New Tests

### Pattern: Direct File Import

```stata
* Setup
local root_dir = subinstr("`c(pwd)'", "\stata\tests", "", .)
local fixtures_dir "`root_dir'/tests/fixtures/api_responses"

* Load fixture
import delimited "`fixtures_dir'/cme_albania_valid.csv", clear

* Test data processing logic
assert ref_area[1] == "ALB"
assert obs_value[1] == 8.5
```

### Pattern: Test Data Transformation

```stata
* Load raw fixture
import delimited "`fixtures_dir'/cme_albania_valid.csv", clear

* Apply transformation (e.g., reshape, calculate)
reshape wide obs_value, i(ref_area indicator) j(time_period)

* Verify result
assert obs_value2020 == 8.5
assert obs_value2021 == 8.2
```

## Future: Integration Tests

For full end-to-end tests with API calls:

```stata
* Mark as integration test (requires API access)
if "`test_mode'" == "unit" {
    di "Skipping integration test in unit mode"
    exit 0
}

* Run actual API call
unicefData, indicator("CME_MRY0T4") countries("ALB") year(2020)
```

## Comparison with Python Tests

| Aspect | Python | Stata |
|--------|--------|-------|
| HTTP Mocking | ✓ (`responses` library) | ✗ (not available) |
| Direct File Read | Indirect (via fixtures) | ✓ Direct CSV import |
| Test Speed | ~27s (28 tests) | ~1s (8 tests) |
| Fixture Location | `tests/fixtures/api_responses/` | Same |
| Fixture Format | Same CSV files | Same CSV files |

## Benefits of This Approach

1. **Same Data**: Uses identical fixtures as Python tests
2. **No Dependencies**: No need for HTTP mocking libraries
3. **Fast**: Direct file I/O is faster than HTTP
4. **Simple**: Easy to understand and maintain
5. **Portable**: Works on any Stata installation

## Limitations

- Doesn't test HTTP layer (connection, retries, error handling)
- Doesn't validate URL construction
- Doesn't test API authentication

These limitations are acceptable because:
- HTTP layer is tested in Python
- Stata code focuses on data processing, not HTTP
- Mock fixtures ensure consistent test data

## Running Tests in CI/CD

In GitHub Actions workflow:

```yaml
- name: Run Stata mock tests
  run: |
    cd stata/tests
    stata-mp -b do test_mock_data.do
    cat test_mock_data.log
```

Or using Make:

```makefile
test-stata-mock:
	cd stata/tests && stata-mp -b do test_mock_data.do
```

## Maintenance

When adding new fixtures:

1. Add CSV file to `tests/fixtures/api_responses/`
2. Update fixture README: `tests/fixtures/api_responses/README.md`
3. Add test case to `test_mock_data.do`
4. Document expected structure above

## Questions?

See also:
- [Mock API Design](../../tests/fixtures/mock_design/API_MOCK_DESIGN.md)
- [Python conftest.py](../../python/tests/conftest.py)
- [Fixture README](../../tests/fixtures/api_responses/README.md)

# API Response Fixtures

This directory contains mock API response files used for testing across all language implementations (Python, Stata, R, etc.).

## Purpose

These files simulate responses from the UNICEF SDMX API without requiring actual network requests. This allows tests to:
- Run without internet connectivity
- Avoid API rate limits and 403 errors
- Execute quickly (no network latency)
- Work in CI/CD environments
- Produce deterministic results

## Files

### Dataflow List Endpoint

**dataflows.xml**
- SDMX 2.1 XML response listing available dataflows
- Used by: List dataflows functionality
- Endpoint: `GET /dataflow/UNICEF`
- Contains: CME, NUTRITION, MNCH, GLOBAL_DATAFLOW

### Data Retrieval Endpoints

**cme_albania_valid.csv**
- Valid CME indicator data for Albania (ALB)
- Indicator: CME_MRY0T4 (Under-5 mortality rate)
- Years: 2020-2022
- Used by: Valid indicator tests

**cme_usa_valid.csv**
- Valid CME indicator data for USA
- Indicator: CME_MRY0T4
- Years: 2020-2021
- Used by: Fallback and multi-country tests

**empty_response.csv**
- Empty CSV with headers only (no data rows)
- Used by: Invalid indicator and 404 fallback tests
- Simulates: Indicator not found or no data available

## Usage

### Python (pytest)

```python
# conftest.py reads these files
import pathlib

fixtures_dir = pathlib.Path(__file__).parent.parent.parent / "tests" / "fixtures" / "api_responses"

@pytest.fixture
def mock_csv_valid_cme():
    return (fixtures_dir / "cme_albania_valid.csv").read_text()
```

### Stata

```stata
* From stata/tests/ directory
local root_dir = subinstr("`c(pwd)'", "\stata\tests", "", .)
local fixtures_dir "`root_dir'/tests/fixtures/api_responses"

* Load fixture file
import delimited "`fixtures_dir'/cme_albania_valid.csv", clear

* Verify data
assert ref_area[1] == "ALB"
assert obs_value[1] == 8.5
```

**Run Stata tests:**
```bash
cd stata/tests
stata-mp -b do run_tests.do
```

See: [stata/tests/README.md](../../../stata/tests/README.md)

### R

```r
# Read fixture file
fixtures_dir <- file.path("tests", "fixtures", "api_responses")
data <- read.csv(file.path(fixtures_dir, "cme_albania_valid.csv"))
```

## Maintenance

When updating these fixtures:
1. Ensure CSV headers match actual API response schema
2. Use realistic data values for the indicator type
3. Test across all language implementations
4. Update documentation if response structure changes

## Reference

- UNICEF SDMX API: https://data.unicef.org/sdmx-api-documentation/
- Mock Design Documentation: ../mock_design/

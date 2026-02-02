# UNICEF SDMX API Mock Design

**Date**: 2026-01-25
**Purpose**: Design comprehensive API mocks for all Python test scenarios

## API Endpoints Overview

The UNICEF SDMX API has two main endpoints we need to mock:

### 1. Dataflow List Endpoint
**Purpose**: List all available dataflows (CME, NUTRITION, etc.)

```
GET https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF
    ?references=none
    &detail=full
```

**Response Format**: SDMX 2.1 XML

**Status**: ✅ Already Mocked (conftest.py)

---

### 2. Data Retrieval Endpoint
**Purpose**: Fetch actual indicator data

```
GET https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/{AGENCY},{DATAFLOW},{VERSION}/{DATA_KEY}
    ?format=csv
    &labels=id
    &startPeriod={YEAR}
    &endPeriod={YEAR}
```

**URL Components**:
- `{AGENCY}` = "UNICEF"
- `{DATAFLOW}` = Dataflow ID (e.g., "CME", "NUTRITION", "GLOBAL_DATAFLOW")
- `{VERSION}` = "1.0"
- `{DATA_KEY}` = Indicator + Country + Filters (e.g., "CME_MRY0T4.ALB.._T")

**Response Format**: CSV (when `format=csv`)

**Status**: ❌ Needs Mocking

---

## Test Scenarios to Mock

### Scenario 1: Valid Indicator (CME_MRY0T4)
**Test**: test_valid_indicator_after_404_still_works

**Request**:
```
GET /data/UNICEF,CME,1.0/CME_MRY0T4.ALB.._T?format=csv&labels=id
```

**Response**: CSV with valid data
```csv
DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS
CME,ALB,CME_MRY0T4,_T,2020,8.5,PER_1000_LIVEBIRTHS,AVAILABLE
CME,ALB,CME_MRY0T4,_T,2021,8.2,PER_1000_LIVEBIRTHS,AVAILABLE
```

---

### Scenario 2: Invalid Indicator (404)
**Test**: test_invalid_indicator_returns_empty_dataframe

**Request**:
```
GET /data/UNICEF,GLOBAL_DATAFLOW,1.0/INVALID_XYZ_NONEXISTENT.ALB.._T?format=csv
```

**Response**: HTTP 404 or Empty CSV
```
(empty or minimal headers only)
```

---

### Scenario 3: Fallback to GLOBAL_DATAFLOW (404 → Retry)
**Test**: test_404_fallback_preserves_column_structure

**Sequence**:
1. **First attempt**: Try specific dataflow → 404
2. **Fallback**: Try GLOBAL_DATAFLOW → Empty result

**Request 1** (fails):
```
GET /data/UNICEF,CME,1.0/FAKE_INDICATOR_404_TEST.USA.._T?format=csv
→ 404 Not Found
```

**Request 2** (fallback):
```
GET /data/UNICEF,GLOBAL_DATAFLOW,1.0/FAKE_INDICATOR_404_TEST.USA.._T?format=csv
→ 200 OK (empty CSV)
```

---

### Scenario 4: Multiple Invalid Indicators
**Test**: test_multiple_invalid_indicators_handled_gracefully

**Request**:
```
GET /data/UNICEF,GLOBAL_DATAFLOW,1.0/INVALID_A.ALB.._T?format=csv
GET /data/UNICEF,GLOBAL_DATAFLOW,1.0/INVALID_B.ALB.._T?format=csv
GET /data/UNICEF,GLOBAL_DATAFLOW,1.0/INVALID_C.ALB.._T?format=csv
```

**Response**: All return empty DataFrames (no exceptions)

---

## Mock Implementation Design

### 1. Create CSV Response Fixtures

```python
# conftest.py additions

@pytest.fixture
def mock_csv_valid_data():
    """CSV response for valid indicator CME_MRY0T4"""
    return """DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS
CME,ALB,CME_MRY0T4,_T,2020,8.5,PER_1000_LIVEBIRTHS,AVAILABLE
CME,ALB,CME_MRY0T4,_T,2021,8.2,PER_1000_LIVEBIRTHS,AVAILABLE
CME,ALB,CME_MRY0T4,_T,2022,7.9,PER_1000_LIVEBIRTHS,AVAILABLE"""

@pytest.fixture
def mock_csv_empty():
    """Empty CSV response for invalid indicators"""
    return """DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS
"""  # Headers only, no data rows
```

---

### 2. Create URL Matchers

Use `responses` library's regex or callback matchers:

```python
import re
from urllib.parse import urlparse, parse_qs

def is_valid_indicator(url):
    """Check if indicator code is valid"""
    # Parse URL: /data/UNICEF,DATAFLOW,1.0/INDICATOR.COUNTRY...
    pattern = r'/data/UNICEF,([^,]+),1\.0/([^.]+)\.'
    match = re.search(pattern, url)
    if match:
        dataflow, indicator = match.groups()
        # List of valid indicators
        valid = ['CME_MRY0T4', 'NT_ANT_HAZ_NE2_MOD']
        return indicator in valid
    return False

@pytest.fixture
def mock_sdmx_data_api():
    """Setup mocks for data retrieval endpoints"""
    def _setup():
        # Mock valid indicator responses
        responses.add_callback(
            responses.GET,
            re.compile(r'https://sdmx\.data\.unicef\.org/.*CME_MRY0T4.*'),
            callback=lambda req: (200, {}, mock_csv_valid_data),
            content_type='text/csv'
        )

        # Mock invalid indicators (404)
        responses.add_callback(
            responses.GET,
            re.compile(r'https://sdmx\.data\.unicef\.org/.*INVALID.*'),
            callback=lambda req: (404, {}, ''),
            content_type='text/plain'
        )

        # Mock unknown indicators (empty CSV)
        responses.add_callback(
            responses.GET,
            re.compile(r'https://sdmx\.data\.unicef\.org/.*FAKE.*'),
            callback=lambda req: (200, {}, mock_csv_empty),
            content_type='text/csv'
        )

    return _setup
```

---

### 3. Response Decision Tree

```
Request URL
    │
    ├─ Contains "INVALID_" → 404 Not Found
    │
    ├─ Contains "FAKE_" → 200 OK (empty CSV)
    │
    ├─ Contains "CME_MRY0T4" → 200 OK (valid CSV data)
    │
    └─ Other → 404 Not Found (default)
```

---

## Detailed CSV Response Schemas

### Valid Data Response (CME_MRY0T4)

```csv
DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS
CME,ALB,CME_MRY0T4,_T,2020,8.5,PER_1000_LIVEBIRTHS,AVAILABLE
CME,ALB,CME_MRY0T4,_T,2021,8.2,PER_1000_LIVEBIRTHS,AVAILABLE
```

**Columns**:
- `DATAFLOW`: Dataflow ID (CME, NUTRITION, etc.)
- `REF_AREA`: ISO 3166-1 alpha-3 country code
- `INDICATOR`: Indicator code
- `SEX`: Sex disaggregation (_T=total, M=male, F=female)
- `TIME_PERIOD`: Year
- `OBS_VALUE`: Numeric value
- `UNIT_MEASURE`: Unit of measurement
- `OBS_STATUS`: Data status (AVAILABLE, ESTIMATED, etc.)

---

### Empty Response (Invalid Indicators)

```csv
DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE,OBS_STATUS

```

**Headers present, no data rows** - This is what pandas reads as an empty DataFrame.

---

## URL Pattern Examples

### Valid Requests

```
# Single country, specific year
GET /data/UNICEF,CME,1.0/CME_MRY0T4.ALB.._T?format=csv&startPeriod=2020&endPeriod=2020

# Multiple countries
GET /data/UNICEF,CME,1.0/CME_MRY0T4.ALB+USA+BRA.._T?format=csv

# All countries (empty filter)
GET /data/UNICEF,CME,1.0/CME_MRY0T4.._T?format=csv

# All disaggregations (no SEX filter)
GET /data/UNICEF,CME,1.0/CME_MRY0T4.ALB?format=csv

# Specific dataflow override
GET /data/UNICEF,NUTRITION,1.0/NT_ANT_HAZ_NE2_MOD.ALB.._T?format=csv

# Using GLOBAL_DATAFLOW as fallback
GET /data/UNICEF,GLOBAL_DATAFLOW,1.0/CME_MRY0T4.ALB.._T?format=csv
```

---

### Invalid Requests (Should Return 404 or Empty)

```
# Nonexistent indicator
GET /data/UNICEF,GLOBAL_DATAFLOW,1.0/INVALID_XYZ_NONEXISTENT.ALB.._T?format=csv

# Fake indicator for testing
GET /data/UNICEF,CME,1.0/FAKE_INDICATOR_404_TEST.USA.._T?format=csv
```

---

## Implementation Strategy

### Phase 1: Simple String Matching (Recommended)
Use explicit URL patterns for known test indicators:

```python
# In conftest.py
@pytest.fixture
def mock_sdmx_data_endpoints(mock_csv_valid_data, mock_csv_empty):
    def _setup():
        # Valid: CME_MRY0T4
        responses.add(
            responses.GET,
            re.compile(r'.*CME_MRY0T4.*'),
            body=mock_csv_valid_data,
            status=200,
            content_type='text/csv'
        )

        # Invalid: INVALID_*
        responses.add(
            responses.GET,
            re.compile(r'.*INVALID.*'),
            body='',
            status=404
        )

        # Fake (fallback test): FAKE_*
        responses.add(
            responses.GET,
            re.compile(r'.*FAKE.*'),
            body=mock_csv_empty,
            status=200,
            content_type='text/csv'
        )

    return _setup
```

### Phase 2: Callback-Based (Advanced)
Use callbacks for dynamic response generation:

```python
def request_callback(request):
    """Dynamic response based on URL parsing"""
    url = request.url

    # Extract indicator from URL
    match = re.search(r'/([A-Z_]+)\.[A-Z]{3}', url)
    if match:
        indicator = match.group(1)

        if indicator.startswith('INVALID'):
            return (404, {}, '')
        elif indicator.startswith('FAKE'):
            return (200, {}, mock_csv_empty)
        elif indicator == 'CME_MRY0T4':
            return (200, {}, mock_csv_valid_data)

    return (404, {}, '')

responses.add_callback(
    responses.GET,
    re.compile(r'https://sdmx\.data\.unicef\.org/.*'),
    callback=request_callback
)
```

---

## Test Coverage Matrix

| Test | Endpoint | Indicator | Expected Result | Mock Response |
|------|----------|-----------|-----------------|---------------|
| test_invalid_indicator_returns_empty_dataframe | Data | INVALID_XYZ_NONEXISTENT | Empty DF | 404 |
| test_404_fallback_preserves_column_structure | Data | FAKE_INDICATOR_404_TEST | Empty DF | 200 (empty CSV) |
| test_valid_indicator_after_404_still_works | Data | CME_MRY0T4 | Data DF | 200 (valid CSV) |
| test_multiple_invalid_indicators_handled_gracefully | Data | INVALID_A/B/C | Empty DFs | 404 × 3 |

---

## Benefits of This Design

✅ **Explicit Control**: Each test scenario has a clear mock definition
✅ **Maintainable**: Easy to add new indicators or scenarios
✅ **Realistic**: Mimics actual API behavior (404s, empty results)
✅ **Fast**: No network I/O
✅ **Deterministic**: Same input always gives same output
✅ **Debuggable**: Easy to see what mock returned what data

---

## Next Steps

1. Implement CSV fixtures in conftest.py
2. Create `mock_sdmx_data_endpoints` fixture
3. Update test_404_fallback.py to use mocks
4. Remove `@pytest.mark.integration` markers
5. Verify all tests pass with `pytest tests/`

---

## Related Files

- `conftest.py` - Mock fixtures and setup
- `test_404_fallback.py` - Tests using data endpoint mocks
- `test_list_dataflows.py` - Already mocked (dataflow list endpoint)
- `sdmx_client.py` - Client being mocked

---

**Design Date**: 2026-01-25
**Status**: Design Complete, Ready for Implementation
**Estimated Implementation Time**: 30-45 minutes

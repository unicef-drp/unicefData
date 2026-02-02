# Mock API Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Test Suite (pytest)                          │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │   @responses.activate     │  (Intercepts HTTP)
                    └─────────────┬─────────────┘
                                  │
        ┌─────────────────────────┴─────────────────────────┐
        │                                                     │
┌───────▼────────┐                                  ┌────────▼────────┐
│  Test Fixtures │                                  │  SDMX Client    │
│  (conftest.py) │                                  │  (under test)   │
└───────┬────────┘                                  └────────┬────────┘
        │                                                     │
        │  1. Setup Mock Responses                           │  2. Makes HTTP Call
        │     (before test runs)                             │     (requests.get)
        │                                                     │
        ▼                                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Responses Library                               │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  URL Pattern Matcher                                        │    │
│  │  ┌──────────────┬──────────────┬──────────────┐           │    │
│  │  │ Dataflow List│  Valid Data  │ Invalid Data │           │    │
│  │  │    Endpoint  │   Endpoint   │   Endpoint   │           │    │
│  │  └──────┬───────┴──────┬───────┴──────┬───────┘           │    │
│  │         │              │              │                    │    │
│  │         │              │              │                    │    │
│  │    ┌────▼────┐    ┌───▼────┐    ┌───▼────┐              │    │
│  │    │ SDMX XML│    │CSV Data│    │404/Empty│              │    │
│  │    │Response │    │Response│    │Response │              │    │
│  │    └────┬────┘    └───┬────┘    └───┬────┘              │    │
│  │         │              │              │                    │    │
│  └─────────┼──────────────┼──────────────┼────────────────────┘    │
│            │              │              │                          │
└────────────┼──────────────┼──────────────┼──────────────────────────┘
             │              │              │
             └──────────────┴──────────────┘
                            │
                     ┌──────▼──────┐
                     │  Test Gets  │
                     │ Mocked Data │
                     └─────────────┘
```

## Request Flow

### 1. Test Execution Flow

```
Test starts
    │
    ├─ Uses @responses.activate decorator
    │
    ├─ Calls fixture: mock_sdmx_api()
    │   └─ Registers URL patterns and responses
    │
    ├─ Calls function under test: list_dataflows()
    │   └─ Makes requests.get(url)
    │       └─ Intercepted by responses library
    │           └─ Matches URL pattern
    │               └─ Returns mocked response
    │
    └─ Asserts on returned data
```

### 2. Mock Registration Flow

```
conftest.py loads
    │
    ├─ Defines fixtures:
    │   ├─ mock_dataflows_xml
    │   ├─ mock_csv_valid_data
    │   ├─ mock_csv_empty
    │   └─ mock_sdmx_api
    │
    └─ Test imports fixture
        └─ Fixture executes
            └─ Calls responses.add()
                ├─ URL: Pattern to match
                ├─ Method: GET/POST
                ├─ Body: Response content
                ├─ Status: HTTP status code
                └─ Headers: Content-Type, etc.
```

## URL Matching Logic

```
Incoming Request: GET https://sdmx.data.unicef.org/rest/dataflow/UNICEF
                                │
                        ┌───────▼────────┐
                        │  URL Matcher   │
                        └───────┬────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
 ┌──────▼───────┐      ┌───────▼───────┐      ┌───────▼──────┐
 │  Contains:   │      │   Contains:   │      │  Contains:   │
 │  /dataflow/  │      │ CME_MRY0T4    │      │  INVALID_    │
 └──────┬───────┘      └───────┬───────┘      └───────┬──────┘
        │                      │                       │
 ┌──────▼───────┐      ┌───────▼───────┐      ┌───────▼──────┐
 │ Return:      │      │ Return:       │      │ Return:      │
 │ SDMX XML     │      │ Valid CSV     │      │ 404 Error    │
 │ (4 flows)    │      │ (3 data rows) │      │ (empty body) │
 └──────────────┘      └───────────────┘      └──────────────┘
```

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    Test: test_list_dataflows                 │
└───────────────────┬──────────────────────────────────────────┘
                    │
        1. Setup    │
        ───────────▼────────────
        mock_sdmx_api()
            │
            └─> responses.add(
                  url="https://sdmx.data.unicef.org/rest/dataflow/UNICEF",
                  body=mock_dataflows_xml,
                  status=200
                )
                    │
        2. Execute  │
        ───────────▼────────────
        list_dataflows()
            │
            └─> requests.get(url)
                    │
                    ├─> Intercepted by responses
                    │
                    └─> Returns: mock_dataflows_xml
                            │
        3. Parse    │           │
        ───────────▼───────────▼──
        ET.fromstring(xml)
            │
            └─> Extract dataflows
                    │
        4. Assert   │
        ───────────▼────────────
        assert "CME" in df["id"]
        assert "NUTRITION" in df["id"]
        ✓ Test passes
```

## Mock Response Structure

### Dataflow List Endpoint

```
Request:
    GET /dataflow/UNICEF?references=none&detail=full

Mock Response:
    Status: 200
    Content-Type: application/xml
    Body: <?xml version="1.0"?>
          <message:Structure>
              <s:Dataflows>
                  <s:Dataflow id="CME" ...>
                      <common:Name>Child Mortality</common:Name>
                  </s:Dataflow>
                  ...
              </s:Dataflows>
          </message:Structure>
```

### Data Endpoint (Valid Indicator)

```
Request:
    GET /data/UNICEF,CME,1.0/CME_MRY0T4.ALB.._T?format=csv

Mock Response:
    Status: 200
    Content-Type: text/csv
    Body: DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,...
          CME,ALB,CME_MRY0T4,_T,2020,8.5,...
          CME,ALB,CME_MRY0T4,_T,2021,8.2,...
```

### Data Endpoint (Invalid Indicator)

```
Request:
    GET /data/UNICEF,GLOBAL_DATAFLOW,1.0/INVALID_XYZ.ALB.._T?format=csv

Mock Response:
    Status: 404
    Content-Type: text/plain
    Body: (empty)
```

## Fixture Dependency Graph

```
┌─────────────────────┐
│ mock_dataflows_xml  │ (Raw XML string)
└──────────┬──────────┘
           │
           │  depends on
           ▼
┌─────────────────────┐
│  mock_sdmx_api      │ (Setup function)
└──────────┬──────────┘
           │
           │  used by
           ▼
┌─────────────────────┐
│  test_list_...      │ (Test function)
│  @responses.activate│
└─────────────────────┘


┌─────────────────────┐
│ mock_csv_valid_data │ (Valid CSV string)
└──────────┬──────────┘
           │
           │  depends on
           ▼
┌─────────────────────┐
│mock_sdmx_data_api   │ (Setup function)
└──────────┬──────────┘
           │
           │  used by
           ▼
┌─────────────────────┐
│ test_404_fallback   │ (Test function)
│ @responses.activate │
└─────────────────────┘
```

## Pattern Matching Examples

### Example 1: Exact URL Match

```python
responses.add(
    responses.GET,
    "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF",
    body=xml_response,
    status=200
)
```

**Matches**: Exact URL only
**Use Case**: Known, fixed endpoints

### Example 2: Regex Pattern Match

```python
import re

responses.add(
    responses.GET,
    re.compile(r'https://sdmx\.data\.unicef\.org/.*CME_MRY0T4.*'),
    body=csv_response,
    status=200
)
```

**Matches**: Any URL containing "CME_MRY0T4"
**Use Case**: Flexible matching for various query parameters

### Example 3: Callback-Based Match

```python
def dynamic_response(request):
    if 'INVALID' in request.url:
        return (404, {}, '')
    elif 'CME_MRY0T4' in request.url:
        return (200, {}, valid_csv)
    else:
        return (404, {}, '')

responses.add_callback(
    responses.GET,
    re.compile(r'https://sdmx\.data\.unicef\.org/.*'),
    callback=dynamic_response
)
```

**Matches**: All SDMX URLs, response determined by logic
**Use Case**: Complex routing logic

## Error Handling Flow

```
Test calls: unicefData(indicator="INVALID_XYZ")
    │
    ├─> SDMXClient.fetch_indicator()
    │       │
    │       ├─> Builds URL with INVALID_XYZ
    │       │
    │       ├─> requests.get(url)
    │       │       │
    │       │       └─> Intercepted by mock
    │       │               │
    │       │               └─> Returns 404
    │       │
    │       ├─> Catches HTTPError (404)
    │       │
    │       ├─> Tries GLOBAL_DATAFLOW fallback
    │       │       │
    │       │       └─> Mock returns empty CSV (200)
    │       │
    │       └─> Returns empty DataFrame
    │
    └─> Test asserts: df.empty == True
            │
            └─> ✓ Test passes
```

## Configuration Matrix

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| `responses` library | HTTP interception | Installed via pip |
| `@responses.activate` | Enable interception | Decorator on test |
| `conftest.py` | Fixture definitions | Auto-discovered by pytest |
| `pytest.ini` | Test configuration | Markers, paths, options |
| URL patterns | Request matching | Regex or exact strings |
| Response bodies | Mock data | XML, CSV, JSON strings |
| Status codes | HTTP responses | 200, 404, 403, 500 |

---

**Created**: 2026-01-25
**Purpose**: Visual guide to mock API architecture
**Related**: API_MOCK_DESIGN.md, conftest.py

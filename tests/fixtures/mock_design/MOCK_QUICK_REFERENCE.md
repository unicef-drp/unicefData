# Mock API Quick Reference Card

## 🚀 Quick Start

### 1. Setup (Already Done)
```bash
pip install responses  # ✓ In workflow
```

### 2. Write Test
```python
import responses

@responses.activate
def test_something(mock_sdmx_api):
    mock_sdmx_api()  # Setup mocks
    result = list_dataflows()
    assert len(result) > 0
```

### 3. Run Test
```bash
pytest tests/test_file.py
```

---

## 📋 Mock Cheat Sheet

### Pattern 1: Exact URL Match
```python
responses.add(
    responses.GET,
    "https://api.example.com/exact/path",
    body="response data",
    status=200
)
```

### Pattern 2: Regex URL Match
```python
import re

responses.add(
    responses.GET,
    re.compile(r'https://api\.example\.com/.*pattern.*'),
    body="response data",
    status=200
)
```

### Pattern 3: Dynamic Callback
```python
def callback(request):
    if 'condition' in request.url:
        return (200, {}, 'data')
    return (404, {}, '')

responses.add_callback(
    responses.GET,
    re.compile(r'https://api\.example\.com/.*'),
    callback=callback
)
```

---

## 🎯 UNICEF SDMX Endpoints

### Dataflow List (Already Mocked ✓)
```python
URL: https://sdmx.data.unicef.org/.../dataflow/UNICEF
Response: SDMX XML
Fixture: mock_dataflows_xml
```

### Data Retrieval (Need to Mock)
```python
URL: https://sdmx.data.unicef.org/.../data/UNICEF,{FLOW},1.0/{KEY}
Response: CSV
Fixtures: mock_csv_valid_data, mock_csv_empty
```

---

## 📝 Fixture Template

```python
# conftest.py

@pytest.fixture
def mock_my_response():
    """Description of what this mocks"""
    return """response content here"""

@pytest.fixture
def mock_my_api(mock_my_response):
    """Setup function for API mocking"""
    def _setup():
        responses.add(
            responses.GET,
            "https://api.url.com/path",
            body=mock_my_response,
            status=200,
            content_type='application/json'
        )
    return _setup
```

---

## 🧪 Test Template

```python
# test_file.py

import responses

class TestMyFeature:

    @responses.activate
    def test_something(self, mock_my_api):
        """Test description"""
        # 1. Setup mocks
        mock_my_api()

        # 2. Execute code under test
        result = my_function()

        # 3. Assert expectations
        assert result == expected_value
```

---

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Test hits real API | Add `@responses.activate` decorator |
| Mock not matching | Check URL pattern with regex101.com |
| 404 despite mock | Ensure `mock_setup()` is called |
| Empty DataFrame wrong | Verify CSV headers match schema |
| CI fails, local passes | Check `responses` in workflow deps |

---

## 📊 URL Pattern Examples

### Valid Indicator (CME_MRY0T4)
```
https://sdmx.data.unicef.org/rest/data/UNICEF,CME,1.0/CME_MRY0T4.ALB.._T
                                              │    │   │    │          │
                                              │    │   │    │          └─ SEX filter
                                              │    │   │    └─ Country (Albania)
                                              │    │   └─ Indicator code
                                              │    └─ Dataflow
                                              └─ Agency
```

### Regex to Match
```python
re.compile(r'https://sdmx\.data\.unicef\.org/.*CME_MRY0T4.*')
```

---

## 🎨 Response Types

### XML (Dataflow List)
```xml
<?xml version="1.0"?>
<message:Structure>
    <s:Dataflows>
        <s:Dataflow id="CME" ...>
            <common:Name>Child Mortality</common:Name>
        </s:Dataflow>
    </s:Dataflows>
</message:Structure>
```

### CSV (Data)
```csv
DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE
CME,ALB,CME_MRY0T4,_T,2020,8.5,PER_1000_LIVEBIRTHS
CME,ALB,CME_MRY0T4,_T,2021,8.2,PER_1000_LIVEBIRTHS
```

### Empty CSV (No Data)
```csv
DATAFLOW,REF_AREA,INDICATOR,SEX,TIME_PERIOD,OBS_VALUE,UNIT_MEASURE

```

---

## ⚡ Quick Commands

```bash
# Run specific test file
pytest tests/test_404_fallback.py

# Run with verbose output
pytest tests/ -v

# Run only fast tests (skip slow)
pytest tests/ -m "not slow"

# Run with coverage
pytest tests/ --cov=unicef_api

# Debug mode (print statements shown)
pytest tests/ -s

# Stop on first failure
pytest tests/ -x
```

---

## 📦 File Organization

```
python/tests/
├── conftest.py              # ← Fixtures (mock setup)
├── pytest.ini               # ← Configuration (markers)
├── test_list_dataflows.py   # ✓ Mocked (dataflow list)
├── test_404_fallback.py     # ⚠️  Need to mock (data retrieval)
├── test_unicef_api.py       # ✓ Uses local files (no API)
├── test_metadata_manager.py # ✓ Uses local files (no API)
└── *.md                     # Documentation
```

---

## 🔍 Debugging Tips

### Print Request URLs
```python
import responses

@responses.activate
def test_debug(mock_api):
    mock_api()

    # See all requests
    print(responses.calls)  # List of RequestCall objects

    # See specific URL
    for call in responses.calls:
        print(call.request.url)
```

### Check Mock Registration
```python
@responses.activate
def test_debug():
    responses.add(...)

    # Print registered mocks
    print(responses.registered())
```

### Validate Response Content
```python
@responses.activate
def test_debug(mock_api):
    mock_api()

    result = requests.get(url)
    print(f"Status: {result.status_code}")
    print(f"Content: {result.text}")
```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| API_MOCK_DESIGN.md | Complete design specification |
| MOCK_ARCHITECTURE.md | Visual architecture diagrams |
| IMPLEMENTATION_GUIDE.md | Step-by-step implementation |
| README_MOCKING.md | Testing strategy overview |
| MOCK_QUICK_REFERENCE.md | This file (quick ref) |

---

## ✅ Checklist

Before committing:
- [ ] All tests have `@responses.activate`
- [ ] All tests call mock setup function
- [ ] No `@pytest.mark.integration` markers
- [ ] Tests pass locally: `pytest tests/`
- [ ] No live API calls (check with `-s` flag)
- [ ] Documentation updated

---

**Last Updated**: 2026-01-25
**Version**: 1.0
**Status**: Production Ready

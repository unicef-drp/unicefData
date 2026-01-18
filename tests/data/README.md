# Test Data - SDMX XML Fixtures

This folder contains XML test fixtures used for testing UNICEF SDMX API responses and data structure validation.

## Files

| File | Source | Purpose |
|------|--------|---------|
| `cme_dataflow_structure.xml` | UNICEF SDMX API | CME (Child Mortality Estimation) dataflow structure definition for testing metadata parsing |
| `temp_cme.xml` | UNICEF SDMX API snapshot | CME indicator data structure sample for validation |
| `temp_world.xml` | UNICEF SDMX API snapshot | World-level aggregated data structure sample for validation |

## How These Were Obtained

These fixtures were obtained by querying the UNICEF SDMX API during development:

```bash
# CME dataflow structure
curl -s "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/datastructure/UNICEF/CME/1.0?format=sdmx-generic-2.1" \
  > cme_dataflow_structure.xml

# World-level data sample
curl -s "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF/..." \
  > temp_world.xml
```

## Usage in Tests

These fixtures are used in automated test scripts to:
- Validate XML parsing without live API calls
- Test metadata extraction and transformation
- Ensure consistent behavior across environments
- Speed up test execution (no network dependency)

**Note**: These are static snapshots and may not reflect the current live API structure. Update if API schema changes.

## Integration

Test scripts reference these files via relative paths:
```python
import os
fixture_path = os.path.join(os.path.dirname(__file__), 'data', 'cme_dataflow_structure.xml')
```


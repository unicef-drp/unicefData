# Python YAML Utilization Guide

## Overview

Python libraries **already have correct YAML loading architecture** following the independence model.

## Current Architecture

### 1. Loading Priority ([sdmx_client.py](unicef_api/sdmx_client.py))

Python searches for YAML files in this order:

```python
# Priority 1: Explicit metadata_dir (if provided to client)
metadata_dir + '/_unicefdata_indicators_metadata.yaml'

# Priority 2: Python's own metadata directory (DEFAULT)
'python/metadata/current/_unicefdata_indicators_metadata.yaml'

# Priority 3: Stata fallback (for backward compatibility)
'stata/src/_/_unicefdata_indicators_metadata.yaml'
```

### 2. Default Metadata Directory ([metadata_manager.py](unicef_api/metadata_manager.py))

```python
# Default location (if no metadata_dir specified)
self.metadata_dir = 'python/metadata/current'
```

**✅ Python is ALREADY configured to use `python/metadata/current/`!**

## Files Loaded

Python loads these YAML files:

| File | Usage | Loaded From |
|------|-------|-------------|
| `_unicefdata_indicators_metadata.yaml` | Direct indicator → dataflow mapping | `python/metadata/current/` |
| `_dataflow_fallback_sequences.yaml` | Prefix-based fallback logic | `python/metadata/current/` |
| `_unicefdata_regions.yaml` | Region/aggregate codes | `python/metadata/current/` |
| `_unicefdata_dataflows.yaml` | Dataflow metadata | `python/metadata/current/` |
| `_unicefdata_countries.yaml` | Country codes | `python/metadata/current/` |
| `_unicefdata_codelists.yaml` | SDMX codelists | `python/metadata/current/` |

## Code References

### Loading Indicators Metadata

[sdmx_client.py:169-222](unicef_api/sdmx_client.py#L169-L222)

```python
def _load_indicators_metadata(self) -> Dict[str, dict]:
    """Load comprehensive indicators metadata from canonical YAML file."""
    candidates = []

    # Add metadata_dir if available
    if self.metadata_manager.metadata_dir:
        candidates.append(
            os.path.join(self.metadata_manager.metadata_dir,
                        '_unicefdata_indicators_metadata.yaml')
        )

    # Add workspace locations
    package_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    candidates.extend([
        os.path.join(package_root, 'metadata', 'current',
                    '_unicefdata_indicators_metadata.yaml'),
        os.path.join(package_root, 'stata', 'src', '_',
                    '_unicefdata_indicators_metadata.yaml'),
    ])

    # Try each candidate
    for candidate in candidates:
        if os.path.exists(candidate):
            try:
                with open(candidate, 'r', encoding='utf-8') as f:
                    data = yaml.safe_load(f)
                    if data and 'indicators' in data:
                        logger.info(f"Loaded metadata from: {candidate}")
                        return data['indicators']
            except Exception as e:
                logger.warning(f"Error loading {candidate}: {e}")

    return {}  # Fallback to prefix-based logic
```

### Loading Fallback Sequences

[sdmx_client.py:224-299](unicef_api/sdmx_client.py#L224-L299)

Similar pattern with fallback to hardcoded defaults for backward compatibility.

## Generation

### Script Location

`python/scripts/generate_metadata.py` - Uses `MetadataSync` class

### Current Status

❌ **Unicode encoding issues on Windows** (emojis in output)

### Issue

The generation script uses Unicode emojis (📁, ✓, ✗) in print statements, which fail on Windows console with:

```
UnicodeEncodeError: 'charmap' codec can't encode character '\U0001f4c1'
```

### Workaround (Until Fixed)

Option 1: Set environment variable before running:

```bash
# Windows PowerShell
$env:PYTHONIOENCODING="utf-8"
python python/scripts/generate_metadata.py
```

```bash
# Windows CMD
set PYTHONIOENCODING=utf-8
python python\scripts\generate_metadata.py
```

Option 2: Run via wrapper script (redirecting output):

```bash
python python/scripts/generate_metadata.py > metadata_gen.log 2>&1
```

Option 3: Use R generation script instead (working):

```bash
Rscript R/scripts/generate_metadata.R
```

## Usage in Client Code

### Basic Usage

```python
from unicef_api import UNICEFSDMXClient

# Client automatically loads from python/metadata/current/
client = UNICEFSDMXClient()

# Fetch data (uses loaded metadata for dataflow resolution)
df = client.fetch_indicator('CME_MRY0T4', countries=['USA', 'BRA'])
```

### Custom Metadata Directory

```python
# Use different metadata location
client = UNICEFSDMXClient(metadata_dir='path/to/metadata')
```

### Verify Loaded Metadata

```python
client = UNICEFSDMXClient()

# Check what was loaded
print(f"Indicators loaded: {len(client._indicators_metadata)}")
print(f"Fallback sequences: {len(client._fallback_sequences)}")
print(f"Region codes: {len(client._region_codes)}")
```

## Validation

Verify Python uses its own YAMLs:

```bash
cd validation
python scripts/validate_yaml_schema.py --verbose
```

Expected output:
```
Python:
  Path: C:\GitHub\...\python\metadata\current\_unicefdata_indicators_metadata.yaml
  ✓ Valid structure
  Items: 738
  Version: 2.0.0
```

## Integration with YAML Independence Architecture

Python follows the independence model:

✅ **Independent**: Has own YAML files in `python/metadata/current/`
✅ **Aligned**: Follows same schema as R and Stata
✅ **Validated**: Schema validation ensures equivalence
⚠️ **Generation**: Script exists but needs Unicode fix

## Files in `python/metadata/current/`

Currently populated files:
- `_unicefdata_dataflows.yaml` (70 dataflows)
- `_unicefdata_regions.yaml` (111 regions)
- `_unicefdata_countries.yaml` (453 countries)
- `_unicefdata_codelists.yaml` (multiple codelists)

Missing files (generation pending):
- `_unicefdata_indicators_metadata.yaml` (needs generation)
- `_dataflow_fallback_sequences.yaml` (needs generation)

## Related Documentation

- [YAML_INDEPENDENCE_PLAN.md](../YAML_INDEPENDENCE_PLAN.md) - Overall architecture
- [validation/scripts/YAML_VALIDATION_README.md](../validation/scripts/YAML_VALIDATION_README.md) - Schema validation

---

**Last Updated**: 2026-01-25
**Status**: Loading logic ✅ complete, generation ⚠️ needs Unicode fix

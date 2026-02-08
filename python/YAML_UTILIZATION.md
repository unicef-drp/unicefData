# Python YAML Utilization Guide

## Overview

Python YAML metadata is **bundled inside the `unicefdata` package** at `unicefdata/metadata/current/`. This ensures `pip install unicefdata` includes all metadata files without external dependencies.

## Current Architecture

### 1. Loading Priority ([sdmx_client.py](unicefdata/sdmx_client.py))

Python searches for YAML files in this order:

```python
# Priority 1: Bundled metadata inside the package (DEFAULT)
# unicefdata/metadata/current/_unicefdata_indicators_metadata.yaml
package_dir = os.path.dirname(os.path.abspath(__file__))
os.path.join(package_dir, 'metadata', 'current', '_unicefdata_indicators_metadata.yaml')

# Priority 2: Explicit metadata_dir (if provided to client)
metadata_dir + '/_unicefdata_indicators_metadata.yaml'

# Priority 3: Workspace locations (development fallback)
os.path.join(package_root, 'metadata', 'current', '_unicefdata_indicators_metadata.yaml')
```

### 2. Default Metadata Directory ([metadata_manager.py](unicefdata/metadata_manager.py))

```python
# Default: bundled metadata inside the package
current_dir = os.path.dirname(os.path.abspath(__file__))
bundled = os.path.join(current_dir, 'metadata', 'current')
if os.path.exists(bundled):
    self.metadata_dir = bundled
else:
    # Fallback: legacy path (python/metadata/current/)
    package_root = os.path.dirname(current_dir)
    self.metadata_dir = os.path.join(package_root, 'metadata', 'current')
```

## Files Loaded

Python loads these YAML files from `unicefdata/metadata/current/`:

| File | Usage | Location |
|------|-------|----------|
| `_unicefdata_indicators_metadata.yaml` | Direct indicator -> dataflow mapping | `unicefdata/metadata/current/` |
| `_dataflow_fallback_sequences.yaml` | Prefix-based fallback logic | `unicefdata/metadata/current/` |
| `_unicefdata_regions.yaml` | Region/aggregate codes | `unicefdata/metadata/current/` |
| `_unicefdata_dataflows.yaml` | Dataflow metadata | `unicefdata/metadata/current/` |
| `_unicefdata_countries.yaml` | Country codes | `unicefdata/metadata/current/` |
| `_unicefdata_codelists.yaml` | SDMX codelists | `unicefdata/metadata/current/` |
| `dataflows/*.yaml` | Per-dataflow schemas | `unicefdata/metadata/current/dataflows/` |

## Bundling via pyproject.toml

YAML files are included in the wheel/sdist via:

```toml
[tool.setuptools.package-data]
unicefdata = ["metadata/**/*.yaml"]
```

This ensures all 108 YAML files (~700KB) ship with `pip install unicefdata`.

## Code References

### Loading Indicators Metadata

[sdmx_client.py](unicefdata/sdmx_client.py)

```python
def _load_indicators_metadata(self) -> Dict[str, dict]:
    """Load comprehensive indicators metadata from canonical YAML file."""
    candidates = []

    # Priority 1: Bundled metadata inside the package
    package_dir = os.path.dirname(os.path.abspath(__file__))
    candidates.append(
        os.path.join(package_dir, 'metadata', 'current',
                    '_unicefdata_indicators_metadata.yaml')
    )

    # Priority 2: metadata_dir (if available)
    if self.metadata_manager.metadata_dir:
        candidates.append(
            os.path.join(self.metadata_manager.metadata_dir,
                        '_unicefdata_indicators_metadata.yaml')
        )

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

[sdmx_client.py](unicefdata/sdmx_client.py)

Similar pattern with bundled metadata as first candidate and fallback to hardcoded defaults.

## Generation

### Script Location

`python/scripts/generate_metadata.py` - Uses `MetadataSync` class

### Running Metadata Sync

```bash
cd python/
python -m unicefdata.run_sync
```

### Known Issue: Unicode on Windows

The generation script uses Unicode emojis in print statements, which can fail on Windows console:

```
UnicodeEncodeError: 'charmap' codec can't encode character '\U0001f4c1'
```

Workaround:

```powershell
$env:PYTHONIOENCODING="utf-8"
python -m unicefdata.run_sync
```

## Usage in Client Code

### Basic Usage

```python
from unicefdata import unicefData

# Client automatically loads bundled metadata from unicefdata/metadata/current/
df = unicefData('CME_MRY0T4', countries=['USA', 'BRA'])
```

### Custom Metadata Directory

```python
from unicefdata import UNICEFSDMXClient

# Override with different metadata location
client = UNICEFSDMXClient(metadata_dir='path/to/metadata')
```

### Verify Loaded Metadata

```python
from unicefdata import UNICEFSDMXClient

client = UNICEFSDMXClient()

# Check what was loaded
print(f"Indicators loaded: {len(client._indicators_metadata)}")
print(f"Fallback sequences: {len(client._fallback_sequences)}")
print(f"Region codes: {len(client._region_codes)}")
```

### Clear Cached Metadata

```python
from unicefdata import clear_cache

# Clear all 5 cache layers and reload
clear_cache(reload=True)
```

## Integration with YAML Independence Architecture

Python follows the independence model:

- **Independent**: Has own YAML files bundled in `unicefdata/metadata/current/`
- **Aligned**: Follows same schema as R and Stata
- **Validated**: Schema validation ensures equivalence
- **Portable**: `pip install unicefdata` includes all metadata

## Files in `unicefdata/metadata/current/`

Currently populated files:
- `_unicefdata_dataflows.yaml` (70 dataflows)
- `_unicefdata_regions.yaml` (111 regions)
- `_unicefdata_countries.yaml` (453 countries)
- `_unicefdata_codelists.yaml` (multiple codelists)
- `_unicefdata_indicators_metadata.yaml`
- `_dataflow_fallback_sequences.yaml`
- `dataflows/*.yaml` (per-dataflow schemas)

## Related Documentation

- [YAML_INDEPENDENCE_PLAN.md](../YAML_INDEPENDENCE_PLAN.md) - Overall architecture
- [validation/scripts/YAML_VALIDATION_README.md](../validation/scripts/YAML_VALIDATION_README.md) - Schema validation

---

**Last Updated**: 2026-02-07
**Status**: Bundled metadata in package, loading logic complete

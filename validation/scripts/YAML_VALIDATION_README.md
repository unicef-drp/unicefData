# YAML Schema Validation

**Location**: `validation/scripts/validate_yaml_schema.py`

## Purpose

Validates that Python, R, and Stata YAML metadata files follow the same schema and naming conventions, ensuring independence with equivalence across all platforms.

## Why Here?

This is a **cross-platform validation tool** that checks YAML files from:
- `python/metadata/current/`
- `R/metadata/current/`
- `stata/src/_/`

It belongs in `validation/scripts/` (not `tests/`) because:
- It validates across **all three platforms simultaneously**
- It's part of the **schema compliance** infrastructure
- It aligns with existing cross-platform tools like `validate_cross_language.py`
- It's not language-specific (unlike tests in `tests/test_*.py`)

## Usage

### Basic Validation

```bash
cd validation
python scripts/validate_yaml_schema.py
```

### Verbose Mode

```bash
python scripts/validate_yaml_schema.py --verbose
```

### Strict Mode (fail on any mismatch)

```bash
python scripts/validate_yaml_schema.py --strict
```

## What It Validates

### 1. Naming Convention
- ✅ Files use single underscore prefix: `_unicefdata_*.yaml`
- ✅ No double underscore (`__unicefdata_*`)

### 2. Metadata Header
All YAML files must have `_metadata` block with:
- `platform`: Python, R, or Stata
- `version`: Metadata version (e.g., "2.0.0")
- `synced_at`: ISO 8601 timestamp
- `source`: API URL
- `agency`: UNICEF
- `content_type`: indicators, dataflows, regions, countries, codelists

### 3. Structure Consistency
- Indicators section exists
- Dataflows section exists
- Countries/regions are valid dictionaries

### 4. Cross-Platform Equivalence
- Indicator counts within 5% tolerance
- Common indicators have matching dataflow assignments
- Schema fields are consistent

## Files Validated

| File | Content Type | Location (each platform) |
|------|-------------|--------------------------|
| `_unicefdata_indicators_metadata.yaml` | indicators | Python, R, Stata |
| `_unicefdata_dataflows.yaml` | dataflows | Python, R, Stata |
| `_unicefdata_regions.yaml` | regions | Python, R, Stata |
| `_unicefdata_countries.yaml` | countries | Python, R, Stata |
| `_unicefdata_codelists.yaml` | codelists | Python, R, Stata |

## Exit Codes

- `0`: All validations passed
- `1`: Some validations failed

## Integration

### CI/CD Workflow

Add to `.github/workflows/yaml-schema-validation.yaml`:

```yaml
name: YAML Schema Validation

on: [push, pull_request]

jobs:
  validate-yaml-schema:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install pyyaml

      - name: Validate YAML schemas
        run: |
          cd validation
          python scripts/validate_yaml_schema.py --strict
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Validate YAML schema before commit

cd validation
python scripts/validate_yaml_schema.py

if [ $? -ne 0 ]; then
  echo "❌ YAML schema validation failed"
  echo "Fix issues or run: git commit --no-verify"
  exit 1
fi
```

## Related Documentation

- [YAML_INDEPENDENCE_PLAN.md](../../YAML_INDEPENDENCE_PLAN.md) - Overall YAML architecture
- [validation/START_HERE.md](../START_HERE.md) - Validation infrastructure overview
- [validation/SCRIPTS_NAVIGATION_GUIDE.md](../SCRIPTS_NAVIGATION_GUIDE.md) - All validation scripts

## Workflow

1. **Generate metadata** (in each language):
   ```bash
   # Python
   python python/scripts/generate_metadata.py

   # R
   Rscript R/scripts/generate_metadata.R

   # Stata
   unicefdata_sync, verbose
   ```

2. **Validate schema**:
   ```bash
   python validation/scripts/validate_yaml_schema.py --verbose
   ```

3. **Run cross-platform validation**:
   ```bash
   python validation/run_validation.py --limit 10 --languages python r stata
   ```

## Troubleshooting

### "File not found" errors

Check that metadata has been generated:
```bash
ls python/metadata/current/_unicefdata_*.yaml
ls R/metadata/current/_unicefdata_*.yaml
ls stata/src/_/_unicefdata_*.yaml
```

### "Invalid filename" errors

Ensure files use **single** underscore prefix:
- ✅ `_unicefdata_dataflows.yaml`
- ❌ `__unicefdata_dataflows.yaml` (double underscore)
- ❌ `unicefdata_dataflows.yaml` (no underscore)

### "Counts differ" errors

This is expected if platforms generated at different times. Rerun generation for all platforms, then validate again.

---

**Last Updated**: 2026-01-25
**Maintained by**: Cross-platform validation team

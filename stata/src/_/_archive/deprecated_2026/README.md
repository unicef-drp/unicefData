# Deprecated Files - January 2026

## Overview

These files were deprecated in January 2026 as part of the migration to the new indicator resolution architecture introduced in Phase 2 (MULTI-01 fix).

## Deprecated Files

| File | Original Purpose | Reason for Deprecation |
|------|-----------------|------------------------|
| `_dataflow_fallback_sequences.yaml` | Stored 500+ indicator prefix → dataflow mappings | Replaced by direct indicator-to-dataflow lookup from `_unicefdata_indicators_metadata.yaml` |
| `_unicef_load_fallback_sequences.ado` | Loaded fallback sequences from YAML into global macros | No longer needed with new YAML-based indicator metadata |
| `_load_dataflow_cache.ado` | Loaded fallback sequences into globals at session start | Replaced by `__unicef_parse_indicator_yaml.ado` which reads metadata on-demand |
| `_get_dataflow_for_indicator.ado` | Retrieved dataflow from cached globals using prefix matching | Replaced by `__unicef_get_indicator_dataflow.ado` which uses direct metadata lookup |

## Replacement Architecture

### Old Architecture (Prefix-Based Fallback)
1. `_load_dataflow_cache.ado` → Read YAML → Create globals `$dataflow_<prefix>`
2. `_get_dataflow_for_indicator.ado` → Extract prefix → Lookup global → Return dataflow list
3. Limitation: Only supported prefix-based matching, required session-wide globals

### New Architecture (Direct Metadata Lookup)
1. `__unicef_parse_indicator_yaml.ado` → Read indicator YAML → Extract dataflow from indicator entry
2. `__unicef_get_indicator_dataflow.ado` → Direct indicator code lookup → Return exact dataflow
3. Benefits: Supports exact indicator codes, no globals, more accurate mappings

## Migration Guide

If you have code that relied on these programs:

**Old:**
```stata
_load_dataflow_cache
_get_dataflow_for_indicator CME_MRY0T4
local dataflow = r(first)
```

**New:**
```stata
* Dataflow is automatically detected by unicefdata.ado
* Or use the new helper:
__unicef_get_indicator_dataflow, indicator(CME_MRY0T4)
local dataflow = r(dataflow)
```

## Date Deprecated

January 19, 2026

## Related Documentation

- [YAML_SCHEMA_REFERENCE.md](../../../../internal/YAML_SCHEMA_REFERENCE.md) - Full YAML metadata documentation
- [YAML_SCHEMA_STATA_SRC.md](../../../../internal/YAML_SCHEMA_STATA_SRC.md) - Stata-specific YAML documentation
- unicefdata.sthlp - Main help file with updated architecture

---

*These files are preserved for reference only and should not be used in new code.*

# Stata Metadata Enrichment Scripts

**Location**: `stata/src/py/`
**Purpose**: Generate complete enriched indicator metadata for Stata
**Updated**: 2026-01-24

---

## Overview

Stata uses **enriched metadata** that includes fields not present in Python/R:
- `dataflows`: Exact dataflow(s) for each indicator
- `tier`: Data quality tier (1-4)
- `tier_reason`: Explanation for tier classification
- `disaggregations`: Available dimension breakdowns
- `disaggregations_with_totals`: Dimensions with `_T` (total) values

---

## Scripts

### 1. `build_indicator_dataflow_map.py` ⭐ PREREQUISITE

**Purpose**: Creates authoritative indicator→dataflow mapping by querying ALL dataflows

**Input**: UNICEF SDMX API (all 70 dataflows)

**Output**: `_indicator_dataflow_map.yaml` (748 indicators mapped)

**Runtime**: ~5-10 minutes (queries API for each dataflow)

**Command**:
```bash
cd stata/src/py
python build_indicator_dataflow_map.py -o ../_/_indicator_dataflow_map.yaml
```

**Output Structure**:
```yaml
indicator_to_dataflow:
  CME_COVID_CASES: COVID_CASES
  CME_MRM0:
    - CME
    - GLOBAL_DATAFLOW
  NT_ANT_HAZ_NE2_MOD:
    - GLOBAL_DATAFLOW
    - NUTRITION
```

---

### 2. `build_dataflow_metadata.py` ⭐ PREREQUISITE

**Purpose**: Extracts dimension values from each dataflow

**Input**: UNICEF SDMX API (all 70 dataflows with `serieskeysonly`)

**Output**: `_unicefdata_dataflow_metadata.yaml` (dimension values per dataflow)

**Runtime**: ~10-15 minutes (queries API for each dataflow)

**Command**:
```bash
cd stata/src/py
python build_dataflow_metadata.py --outdir ../_/ --verbose
```

**Output Structure**:
```yaml
dataflows:
  CME:
    name: 'Child Mortality'
    indicator_count: 34
    dimensions:
      INDICATOR:
        values: [CME_MRM0, CME_MRY0T4, ...]
      SEX:
        values: [F, M, _T]
      WEALTH_QUINTILE:
        values: [Q1, Q2, Q3, Q4, Q5, _T]
```

---

### 3. `enrich_stata_metadata_complete.py` ⭐ MAIN ENRICHMENT

**Purpose**: **COMPLETE** enrichment in one script (dataflows + tier + disaggregations)

**Input**:
- Base indicator metadata (from Python: `unicef_indicators_metadata.yaml`)
- `_indicator_dataflow_map.yaml` (from script #1)
- `_unicefdata_dataflow_metadata.yaml` (from script #2)

**Output**: Complete enriched `_unicefdata_indicators_metadata.yaml`

**Runtime**: ~30 seconds

**Command**:
```bash
cd stata/src/py
python enrich_stata_metadata_complete.py \
  --base-indicators ../../../python/metadata/current/unicef_indicators_metadata.yaml \
  --dataflow-map ../_/_indicator_dataflow_map.yaml \
  --dataflow-metadata ../_/_unicefdata_dataflow_metadata.yaml \
  --output ../_/_unicefdata_indicators_metadata.yaml
```

**What it does**:
1. ✅ Adds `dataflows` field from indicator_dataflow_map
2. ✅ Adds `tier` and `tier_reason` fields (classifies indicators)
3. ✅ Adds `disaggregations` and `disaggregations_with_totals` fields
4. ✅ Updates metadata header with counts

**Output Fields**:
```yaml
indicators:
  CME_COVID_CASES:
    code: CME_COVID_CASES
    name: Covid cases
    description: ''
    urn: urn:sdmx:...
    parent: CME
    dataflows: COVID_CASES                # Added
    tier: 1                               # Added
    tier_reason: verified_and_downloadable # Added
    disaggregations:                      # Added
    - AGE
    - REF_AREA
    - SEX
    disaggregations_with_totals:          # Added
    - AGE
    - SEX
```

---

### 4. `enrich_indicators_metadata.py` (DEPRECATED - Use Script #3)

**Purpose**: Adds ONLY disaggregations fields (legacy script)

**Status**: ⚠️ **Use `enrich_stata_metadata_complete.py` instead**

This script assumes `dataflows`, `tier`, and `tier_reason` fields already exist.
It only adds the disaggregations fields.

For NEW enrichment from scratch, use Script #3 (complete enrichment).

---

## Complete Workflow

### Generate Complete Enriched Metadata (Fresh Start)

**Prerequisites**:
- Python 3.6+ with `requests` and `PyYAML`
- Base indicator metadata from Python package

**Steps**:

```bash
cd C:\GitHub\myados\unicefData-dev\stata\src\py

# Step 1: Build indicator→dataflow mapping (~5-10 min)
python build_indicator_dataflow_map.py -o ../_/_indicator_dataflow_map.yaml

# Step 2: Build dataflow dimension metadata (~10-15 min)
python build_dataflow_metadata.py --outdir ../_/ --verbose

# Step 3: Complete enrichment (~30 sec)
python enrich_stata_metadata_complete.py \
  --base-indicators ../../../python/metadata/current/unicef_indicators_metadata.yaml \
  --dataflow-map ../_/_indicator_dataflow_map.yaml \
  --dataflow-metadata ../_/_unicefdata_dataflow_metadata.yaml \
  --output ../_/_unicefdata_indicators_metadata.yaml

# Step 4: Deploy to ado path
cp ../_/_unicefdata_indicators_metadata.yaml "C:\Users\jpazevedo\ado\plus\_\"
```

**Total Time**: ~15-25 minutes (first 2 steps can be cached, step 3 is fast)

---

## Update Workflow (Incremental)

If you already have `_indicator_dataflow_map.yaml` and `_unicefdata_dataflow_metadata.yaml` cached:

```bash
cd stata/src/py

# Just run the enrichment (uses cached prerequisite files)
python enrich_stata_metadata_complete.py \
  --base-indicators ../../../python/metadata/current/unicef_indicators_metadata.yaml \
  --dataflow-map ../_/_indicator_dataflow_map.yaml \
  --dataflow-metadata ../_/_unicefdata_dataflow_metadata.yaml \
  --output ../_/_unicefdata_indicators_metadata.yaml

# Deploy
cp ../_/_unicefdata_indicators_metadata.yaml "C:\Users\jpazevedo\ado\plus\_\"
```

**Time**: ~30 seconds

---

## For Python/R Parity

To bring Python/R up to Stata's level, run the same enrichment:

### Python
```bash
cd stata/src/py

# Generate prerequisite files for Python
python build_indicator_dataflow_map.py -o ../../../python/metadata/current/_indicator_dataflow_map.yaml
python build_dataflow_metadata.py --outdir ../../../python/metadata/current --verbose

# Enrich Python metadata
python enrich_stata_metadata_complete.py \
  --base-indicators ../../../python/metadata/current/unicef_indicators_metadata.yaml \
  --dataflow-map ../../../python/metadata/current/_indicator_dataflow_map.yaml \
  --dataflow-metadata ../../../python/metadata/current/_unicefdata_dataflow_metadata.yaml \
  --output ../../../python/metadata/current/unicef_indicators_metadata.yaml
```

### R
```bash
cd stata/src/py

# Generate prerequisite files for R
python build_indicator_dataflow_map.py -o ../../../R/metadata/current/_indicator_dataflow_map.yaml
python build_dataflow_metadata.py --outdir ../../../R/metadata/current --verbose

# Enrich R metadata
python enrich_stata_metadata_complete.py \
  --base-indicators ../../../R/metadata/current/unicef_indicators_metadata.yaml \
  --dataflow-map ../../../R/metadata/current/_indicator_dataflow_map.yaml \
  --dataflow-metadata ../../../R/metadata/current/_unicefdata_dataflow_metadata.yaml \
  --output ../../../R/metadata/current/unicef_indicators_metadata.yaml
```

---

## Tier Classification

The enrichment script classifies indicators into tiers:

| Tier | Meaning | Criteria | Count (typical) |
|------|---------|----------|-----------------|
| 1 | Verified and downloadable | Has valid dataflow(s) | ~480 |
| 2 | Limited availability | Has dataflow but deprecated | ~245 |
| 3 | No data | Has `dataflows: nodata` | ~280 |
| 4 | Unknown | Missing dataflow mapping | ~0 |

**Tier reasons**:
- `verified_and_downloadable` - Confirmed working
- `dataflow_not_found` - Not in any dataflow
- `no_dataflow_mapping` - No mapping exists
- `unknown` - Unclassified

---

## File Locations

After enrichment, files are created in `stata/src/_/`:

```
stata/src/_/
├── _indicator_dataflow_map.yaml          # Indicator→dataflow mapping (748 indicators)
├── _unicefdata_dataflow_metadata.yaml    # Dimension values per dataflow (70 dataflows)
└── _unicefdata_indicators_metadata.yaml  # Complete enriched metadata (final output)
```

For deployment to users, copy to:
```
C:\Users\jpazevedo\ado\plus\_\
└── _unicefdata_indicators_metadata.yaml
```

---

## Verification

After enrichment, verify the output:

```bash
cd stata/src/_

# Check field counts
python -c "
import yaml
with open('_unicefdata_indicators_metadata.yaml', 'r') as f:
    data = yaml.safe_load(f)

print('Metadata counts:')
print(f\"  Total indicators: {data['metadata']['indicator_count']}\")
print(f\"  With dataflows: {data['metadata']['indicators_with_dataflows']}\")
print(f\"  Tier 1: {data['metadata']['tier_counts']['tier_1']}\")

# Count field occurrences
import subprocess
print()
print('Field occurrences:')
result = subprocess.run(['grep', '-c', 'dataflows:', '_unicefdata_indicators_metadata.yaml'],
                       capture_output=True, text=True)
print(f\"  dataflows: {result.stdout.strip()}\")

result = subprocess.run(['grep', '-c', 'disaggregations:', '_unicefdata_indicators_metadata.yaml'],
                       capture_output=True, text=True)
print(f\"  disaggregations: {result.stdout.strip()}\")
"
```

**Expected Output**:
```
Metadata counts:
  Total indicators: 733
  With dataflows: 480
  Tier 1: 480

Field occurrences:
  dataflows: 733
  disaggregations: 480
```

---

## Troubleshooting

### Error: "dataflow not found: nodata"

This is normal - some indicators don't exist in any dataflow. They get `tier: 3`.

### Error: "File not found: _indicator_dataflow_map.yaml"

Run prerequisite script #1 first.

### Error: "No 'indicators' key in base metadata"

Check that base metadata file has the correct structure. It should be from Python's `unicef_indicators_metadata.yaml`.

---

## Summary

- **Script #1**: `build_indicator_dataflow_map.py` - Creates indicator→dataflow mapping (~5-10 min, cache forever)
- **Script #2**: `build_dataflow_metadata.py` - Extracts dimensions (~10-15 min, cache forever)
- **Script #3**: `enrich_stata_metadata_complete.py` - COMPLETE enrichment (~30 sec, run whenever base metadata updates)
- ~~**Script #4**: `enrich_indicators_metadata.py`~~ - DEPRECATED (use #3 instead)

For fresh enrichment: Run scripts #1, #2, #3 in order.
For updates: Just run script #3 (if prerequisites are cached).

---

**Last Updated**: 2026-01-24
**Status**: Production Ready ✅

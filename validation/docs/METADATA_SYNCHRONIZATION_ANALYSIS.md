# YAML Metadata Synchronization Status

**Date**: 2026-01-14  
**Current Vintage**: 2025-12-07  
**Finding**: YES - The YAML files ARE aligned via a canonical shared metadata directory!

---

## Architecture Overview

```
C:\GitHub\myados\unicefData\
├── metadata/current/              ← CANONICAL (Source of Truth)
│   ├── _unicefdata_dataflows.yaml
│   ├── _unicefdata_indicators.yaml
│   ├── _unicefdata_codelists.yaml
│   ├── _unicefdata_countries.yaml
│   ├── _unicefdata_regions.yaml
│   └── vintages/
│
├── python/metadata/current/       ← Platform copy (OUTDATED)
│   ├── dataflows/
│   ├── _unicefdata_dataflows.yaml
│   └── ...
│
├── R/metadata/current/            ← Platform copy (OUTDATED)
│   ├── dataflows/
│   ├── _unicefdata_dataflows.yaml
│   └── ...
│
└── stata/src/_/                   ← Platform copy (co-located with ado files)
    ├── _dataflows/
    ├── _unicefdata_dataflows.yaml
    └── ...
```

---

## File Timestamps (Last Updated)

| Location | File | Last Updated | Notes |
|----------|------|--------------|-------|
| **metadata/current/** | _unicefdata_dataflows.yaml | 2026-01-07 01:08 UTC | ✅ NEWEST (Source) |
| python/metadata/current/ | _unicefdata_dataflows.yaml | 2025-12-09 01:11 UTC | ⚠️ Outdated (2 weeks old) |
| R/metadata/current/ | _unicefdata_dataflows.yaml | 2025-12-09 02:25 UTC | ⚠️ Outdated (2 weeks old) |
| stata/src/_/ | _unicefdata_dataflows.yaml | 2026-02-01 | ✅ Active (adopath-resolved) |

---

## Metadata Format Comparison

### Canonical Format (Python-based)
**File**: `C:\GitHub\myados\unicefData\metadata\current\_unicefdata_dataflows.yaml`

```yaml
_metadata:
  platform: python
  version: 2.0.0
  synced_at: '2026-01-07T00:26:49.329321Z'
  source: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF
  agency: UNICEF
  content_type: dataflows
  total_dataflows: 69
dataflows:
  CAUSE_OF_DEATH:
    id: CAUSE_OF_DEATH
    name: Cause of death
    agency: UNICEF
    version: '1.0'
    description: null
    dimensions: null
    indicators: null
```

### Python Platform Copy
**File**: `C:\GitHub\myados\unicefData\python\metadata\current\_unicefdata_dataflows.yaml`
- ✅ Same format as canonical (2 weeks old)
- File is a 1:1 copy
- Older sync timestamp

### R Platform Copy
**File**: `C:\GitHub\myados\unicefData\R\metadata\current\_unicefdata_dataflows.yaml`
- ✅ Same format as canonical (2 weeks old)
- File is a 1:1 copy
- Older sync timestamp

### Stata Platform Copy
**File**: `C:\GitHub\myados\unicefData\stata\metadata\current\_unicefdata_dataflows.yaml`

```yaml
metadata:
  version: '2.0.0'
  source: UNICEF SDMX dataflow
  url: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/all/latest
  last_updated: 2025-12-08T20:39:24
  description: Comprehensive UNICEF dataflows dataflow with metadata
  dataflow_count: 69
dataflows:
  CAUSE_OF_DEATH:
    code: CAUSE_OF_DEATH
    name: 'Cause of death'
    version: '1.0'
    agency_id: UNICEF
```

**Differences**:
- ❌ Different metadata header format (`metadata:` vs `_metadata:`)
- ❌ Uses `code:` instead of `id:`
- ❌ Uses `agency_id:` instead of `agency:`
- ❌ No platform tag
- ❌ Older timestamp (Dec 8 vs Jan 7)

---

## Impact Analysis

### Current State
✅ Python and R have synchronized canonical copies (though outdated)  
❌ Stata has a **different format** (not directly compatible with Python/R format)

### The Good News
1. **Canonical metadata exists** at project root
2. **Python and R can share** the same YAML format
3. **Sync mechanism is in place** - files are copied to platform-specific directories
4. **Single source of truth** already established

### The Problem
1. **Stata uses different format** - needs conversion or standardization
2. **Platform copies are outdated** - last sync was 1+ months ago
3. **No current fallback_sequences.yaml** - need to ADD this new file

---

## Recommended Solution

Instead of creating separate fallback YAML files, **extend the canonical metadata** with fallback sequences:

### Option A: Add to Canonical Metadata (RECOMMENDED)
```
metadata/current/
├── _unicefdata_dataflows.yaml         (existing - sync source)
├── _unicefdata_indicators.yaml        (existing)
├── _dataflow_fallback_sequences.yaml  ← NEW (canonical fallback mapping)
├── dataflows/                         (detailed structure by dataflow)
└── vintages/                          (historical versions)
```

Then sync to all platforms:
```
python/metadata/current/_dataflow_fallback_sequences.yaml (copy)
R/metadata/current/_dataflow_fallback_sequences.yaml      (copy)
stata/src/_/_dataflow_fallback_sequences.yaml  (converted format)
```

### Option B: Create in unicefData Submodule Root
```
unicefData/
├── metadata/current/
│   ├── _unicefdata_dataflows.yaml
│   └── _dataflow_fallback_sequences.yaml  ← NEW canonical
├── python/metadata/current/
├── R/metadata/current/
└── stata/src/_/
```

---

## Implementation Strategy

### Step 1: Create Canonical Fallback YAML
File: `C:\GitHub\myados\unicefData\metadata\current\_dataflow_fallback_sequences.yaml`

```yaml
metadata:
  version: '1.0.0'
  created: '2026-01-12'
  last_updated: '2026-01-12'
  source: UNICEF SDMX Dataflow Analysis (2026-01-12)
  author: AI Agent (GitHub Copilot)
  description: 'Canonical fallback sequences for cross-platform indicator dataflow resolution'

# Fallback sequences organized by indicator prefix
# Format: Try each dataflow in order until one succeeds
fallback_sequences:
  # Protection indicators
  PT:
    - PT
    - PT_CM
    - PT_FGM
    - PT_CONFLICT
    - CHILD_PROTECTION
    - GLOBAL_DATAFLOW

  # Education indicators
  ED:
    - EDUCATION_UIS_SDG
    - EDUCATION
    - EDUCATION_FLS
    - GLOBAL_DATAFLOW

  # Child Mortality indicators
  CME:
    - CME
    - CME_DF_2021_WQ
    - CME_SUBNATIONAL
    - GLOBAL_DATAFLOW

  # Cause of Death
  COD:
    - CME_CAUSE_OF_DEATH
    - CAUSE_OF_DEATH
    - GLOBAL_DATAFLOW

  # Water/Sanitation/Hygiene
  WS:
    - WASH_HOUSEHOLDS
    - WASH_SCHOOLS
    - WASH_HEALTHCARE_FACILITY
    - GLOBAL_DATAFLOW

  # Immunisation
  IM:
    - IMMUNISATION
    - GLOBAL_DATAFLOW

  # Child-related SDG
  TRGT:
    - CHILD_RELATED_SDG
    - GLOBAL_DATAFLOW

  # Social Protection
  SPP:
    - SOC_PROTECTION
    - GLOBAL_DATAFLOW

  # Maternal/Child Health
  MNCH:
    - MNCH
    - GLOBAL_DATAFLOW

  # Nutrition
  NT:
    - NUTRITION
    - GLOBAL_DATAFLOW

  # Early Childhood Development
  ECD:
    - ECD
    - GLOBAL_DATAFLOW

  # HIV/AIDS
  HVA:
    - HIV_AIDS
    - GLOBAL_DATAFLOW

  # Child Poverty
  PV:
    - CHLD_PVTY
    - GLOBAL_DATAFLOW

  # Demographics
  DM:
    - DM
    - DM_PROJECTIONS
    - GLOBAL_DATAFLOW

  # Migration
  MG:
    - MG
    - GLOBAL_DATAFLOW

  # Gender
  GN:
    - GENDER
    - GLOBAL_DATAFLOW

  # Functional Difficulty
  FD:
    - FUNCTIONAL_DIFF
    - GLOBAL_DATAFLOW

  # Economic
  ECO:
    - ECONOMIC
    - GLOBAL_DATAFLOW

  # COVID
  COVID:
    - COVID_CASES
    - COVID
    - GLOBAL_DATAFLOW

  # Worktable (indicators with WT prefix)
  WT:
    - WASH_HOUSEHOLDS
    - PT
    - CHILD_PROTECTION
    - GLOBAL_DATAFLOW

  # Default fallback for unknown prefixes
  DEFAULT:
    - GLOBAL_DATAFLOW
```

### Step 2: Update Python to Load
```python
# In python/unicef_api/core.py
import yaml
from pathlib import Path

def load_fallback_sequences():
    """Load canonical fallback sequences from YAML"""
    # Try canonical location first
    canonical = Path(__file__).parent.parent.parent / 'metadata/current/_dataflow_fallback_sequences.yaml'
    if canonical.exists():
        with open(canonical, 'r') as f:
            data = yaml.safe_load(f)
            return data.get('fallback_sequences', {})
    
    # Fallback to package location
    pkg_path = Path(__file__).parent / 'metadata/_dataflow_fallback_sequences.yaml'
    if pkg_path.exists():
        with open(pkg_path, 'r') as f:
            data = yaml.safe_load(f)
            return data.get('fallback_sequences', {})
    
    return {}  # Return empty if not found

# Replace DATAFLOW_ALTERNATIVES dict with:
FALLBACK_SEQUENCES = load_fallback_sequences()
```

### Step 3: Update R to Load
```r
# In R/unicef_core.R
load_fallback_sequences <- function() {
  # Try canonical location first
  canonical <- file.path(dirname(getwd()), 'metadata/current/_dataflow_fallback_sequences.yaml')
  
  if (!file.exists(canonical)) {
    canonical <- system.file('metadata/_dataflow_fallback_sequences.yaml', 
                            package = 'unicefData', mustWork = FALSE)
  }
  
  if (file.exists(canonical)) {
    return(yaml::read_yaml(canonical)$fallback_sequences)
  }
  
  return(list())  # Return empty list if not found
}

# Replace hardcoded fallbacks with:
FALLBACK_SEQUENCES <- load_fallback_sequences()
```

### Step 4: Update Stata to Load
```stata
* In _unicef_fetch_with_fallback.ado
local canonical_path "../../../../metadata/current/_dataflow_fallback_sequences.yaml"
if ("`canonical_path'" != "" & fileexists("`canonical_path'")) {
    * Parse YAML and load fallback sequences
    * (Implementation depends on yaml.ado capabilities)
}
```

### Step 5: Sync All Platform Copies
Create sync script to update all platform metadata directories:
```bash
# Copy canonical to all platforms
cp metadata/current/_dataflow_fallback_sequences.yaml python/metadata/current/
cp metadata/current/_dataflow_fallback_sequences.yaml R/metadata/current/
cp metadata/current/_dataflow_fallback_sequences.yaml stata/src/_/
```

---

## Advantages of This Approach

✅ **Single source of truth** - one YAML file for all platforms  
✅ **Version control** - changes tracked in Git  
✅ **Easy updates** - modify one file, sync to all platforms  
✅ **Leverages existing sync** - uses metadata sync infrastructure already in place  
✅ **Backward compatible** - Python/R still load from platform copies if canonical unavailable  
✅ **Extensible** - can add more metadata to the same directory  

---

## Testing

After implementation:
1. Delete old hardcoded fallback dicts from all platforms
2. Run seed-42 validation test on all platforms
3. Verify all 3 platforms return identical results
4. Document results in CHANGELOG

---

## Timeline

- **Immediate**: Create canonical YAML file (5 min)
- **Day 1**: Update Python to load from YAML (30 min)
- **Day 1**: Update R to load from YAML (30 min)
- **Day 2**: Update Stata to load from YAML (1-2 hours)
- **Day 2**: Run comprehensive validation (1 hour)
- **Day 3**: Document v1.5.2 release with unified fallback logic

---

## Key Files to Create/Modify

| File | Action | Priority |
|------|--------|----------|
| `metadata/current/_dataflow_fallback_sequences.yaml` | CREATE | HIGH |
| `python/unicef_api/core.py` | MODIFY | HIGH |
| `R/unicef_core.R` | MODIFY | HIGH |
| `stata/src/_/_unicef_fetch_with_fallback.ado` | MODIFY | HIGH |
| `python/metadata/current/_dataflow_fallback_sequences.yaml` | SYNC | MEDIUM |
| `R/metadata/current/_dataflow_fallback_sequences.yaml` | SYNC | MEDIUM |
| `stata/src/_/_dataflow_fallback_sequences.yaml` | SYNC | MEDIUM |

# Indicator Metadata Enrichment Specification

## Current State: Partial Enrichment

The file `_unicefdata_indicators_metadata.yaml` currently has **Phase 1 only**.

## Complete Enrichment Design (Per Documentation)

According to [enrich_stata_metadata_complete.py](../src/py/enrich_stata_metadata_complete.py), the complete enrichment pipeline has **3 phases**:

### Phase 1: Dataflows Field ✓ (Currently Present)

Adds `dataflows` field showing which dataflow(s) each indicator belongs to.

**Example**:
```yaml
CME_MRM0:
  code: CME_MRM0
  name: 'Neonatal mortality rate'
  dataflows:
    - CME
    - GLOBAL_DATAFLOW
```

**Source**: `_indicator_dataflow_map.yaml`

---

### Phase 2: Tier Classification ✗ (MISSING)

Adds `tier` and `tier_reason` fields to classify indicator data availability.

**Tier System**:
- **Tier 1**: Has valid dataflow(s), verified and downloadable
- **Tier 2**: Has dataflow but marked as limited/deprecated
- **Tier 3**: Has 'nodata' or empty dataflow
- **Tier 4**: No dataflow information

**Example**:
```yaml
CME_MRM0:
  code: CME_MRM0
  name: 'Neonatal mortality rate'
  dataflows:
    - CME
    - GLOBAL_DATAFLOW
  tier: 1
  tier_reason: "verified_and_downloadable"
```

**Logic**: Based on presence and validity of dataflows field

---

### Phase 3: Disaggregations ✗ (MISSING)

Adds `disaggregations` and `disaggregations_with_totals` fields showing available dimension breakdowns.

**Fields**:
- `disaggregations`: All available dimension names
- `disaggregations_with_totals`: Dimensions that include total aggregates

**Example**:
```yaml
CME_MRM0:
  code: CME_MRM0
  name: 'Neonatal mortality rate'
  dataflows:
    - CME
    - GLOBAL_DATAFLOW
  tier: 1
  tier_reason: "verified_and_downloadable"
  disaggregations:
    - sex
    - residence
    - wealth_quintile
  disaggregations_with_totals:
    - sex
    - residence
```

**Source**: `_unicefdata_dataflow_metadata.yaml` (dimensions per dataflow)

---

## Complete Enriched Structure

Full indicator entry with all three phases:

```yaml
indicators:
  CME_MRM0:
    code: CME_MRM0
    name: 'Neonatal mortality rate'
    description: 'Probability of dying during the first 28 days of life...'
    urn: urn:sdmx:org.sdmx.infomodel.codelist.Code=...
    parent: CME
    dataflows:                           # Phase 1
      - CME
      - GLOBAL_DATAFLOW
    tier: 1                              # Phase 2
    tier_reason: "verified_and_downloadable"
    disaggregations:                     # Phase 3
      - sex
      - residence
      - wealth_quintile
      - time_period
    disaggregations_with_totals:         # Phase 3
      - sex
      - residence
```

---

## Metadata Header Updates

The enrichment also updates the metadata section with statistics:

```yaml
metadata:
  version: '1.0'
  source: UNICEF SDMX Codelist CL_UNICEF_INDICATOR
  last_updated: 2026-01-24T...
  indicator_count: 738
  indicators_with_dataflows: 485        # From Phase 1
  orphan_indicators: 253                # Indicators without dataflows
  dataflow_count: 31
  tier_1_count: 485                     # From Phase 2
  tier_2_count: 0
  tier_3_count: 0
  tier_4_count: 253
```

---

## Input Files Required

1. **Base indicators**: `_unicefdata_indicators.yaml`
   - Source: SDMX API CL_UNICEF_INDICATOR codelist
   - Contains: code, name, description, urn, parent

2. **Dataflow map**: `_indicator_dataflow_map.yaml`
   - Source: Compiled from all dataflow schemas
   - Format: `indicator_code: [dataflow1, dataflow2]`

3. **Dataflow metadata**: `_unicefdata_dataflow_metadata.yaml`
   - Source: SDMX API dataflow structure definitions (DSD)
   - Contains: Dimensions and attributes per dataflow

---

## How to Generate Complete Enrichment

### Option 1: Via Stata Sync (Recommended)

```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"

* Run full sync with enrichment enabled
unicefdata_sync, all enrichdataflows verbose
```

This will:
1. Sync all base metadata files
2. Run Python enrichment script automatically
3. Generate complete `_unicefdata_indicators_metadata.yaml`

### Option 2: Direct Python Script

```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
do regenerate_enriched_metadata.do
```

Or manually:
```bash
cd C:\GitHub\myados\unicefData-dev\stata\src\py

python enrich_stata_metadata_complete.py \
  --base-indicators ../_/_unicefdata_indicators.yaml \
  --dataflow-map ../_/_indicator_dataflow_map.yaml \
  --dataflow-metadata ../_/_unicefdata_dataflow_metadata.yaml \
  --output ../_/_unicefdata_indicators_metadata.yaml
```

---

## Verification

After enrichment, verify the file contains all phases:

```bash
cd C:\GitHub\myados\unicefData-dev\stata\src\_

# Check for tier fields
grep -c "tier:" _unicefdata_indicators_metadata.yaml
# Should return: 738 (one per indicator)

# Check for disaggregations fields
grep -c "disaggregations:" _unicefdata_indicators_metadata.yaml
# Should return: 485 (indicators with dataflows)

# View sample enriched indicator
awk '/CME_MRM0:/,/^  [A-Z]/' _unicefdata_indicators_metadata.yaml | head -20
```

---

## Why Complete Enrichment Matters

1. **Tier Classification**: Helps users identify which indicators have downloadable data
2. **Disaggregations**: Shows available breakdowns (sex, age, wealth, etc.) without API call
3. **Data Discovery**: Users can filter/search indicators by tier or disaggregations
4. **Testing**: SYNC-02 test validates enrichment completeness

---

## Current Status

**File**: `C:\GitHub\myados\unicefData-dev\stata\src\_\_unicefdata_indicators_metadata.yaml`

**Enrichment Status**:
- ✓ Phase 1: dataflows (Present)
- ✗ Phase 2: tier/tier_reason (Missing)
- ✗ Phase 3: disaggregations (Missing)

**Action Required**: Run complete enrichment using one of the methods above.

---

**Document Date**: 2026-01-24
**Author**: Claude Sonnet 4.5
**Reference**: enrich_stata_metadata_complete.py documentation

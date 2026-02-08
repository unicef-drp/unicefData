# Manual Dataflow Parameter - Feature Documentation

**Date**: January 16, 2026  
**Feature**: Manual dataflow specification for `get_sdmx` command  
**Status**: ✅ Implementation Complete  

---

## Overview

The `dataflow()` parameter allows users to specify the exact SDMX dataflow ID instead of relying on automatic detection from `agency` and `indicator` parameters. This is useful for:

1. **Power users** who know the exact dataflow codes
2. **Batch operations** where dataflow IDs are pre-determined
3. **Overriding** agency detection when needed
4. **Simplifying** queries when indicator alone is insufficient to identify the dataflow

---

## Syntax

```stata
get_sdmx, indicator(string) [dataflow(string) ...]
```

### New Parameter

**`dataflow(string)`** — Manual SDMX dataflow ID  
- **Format**: `AGENCY.DATAFLOW_CODE` (e.g., `UNICEF.CME`)
- **Optional**: Yes (default: empty, uses auto-detection)
- **Effect**: When specified, bypasses `agency`+`indicator` auto-detection
- **Agency extraction**: Automatically extracts and uses AGENCY component

---

## Usage Examples

### Example 1: Auto-Detection (Baseline)

Without dataflow parameter, uses agency + indicator:

```stata
get_sdmx, indicator(SP.POP.TOTL) agency(UNICEF)
```

**Behavior**:
- Uses UNICEF as agency
- Uses SP.POP.TOTL as indicator code
- Auto-detects dataflow: UNICEF.SP.POP.TOTL

**URL generated**: `/data/UNICEF,SP.POP.TOTL/*._T?...`

---

### Example 2: Manual Dataflow Specification

With dataflow parameter, bypasses auto-detection:

```stata
get_sdmx, indicator(CME) dataflow(UNICEF.CME)
```

**Behavior**:
- Ignores `indicator(CME)` for dataflow determination
- Uses UNICEF.CME as the complete dataflow ID
- Automatically extracts UNICEF as agency
- Indicator parameter still used for reference/metadata

**URL generated**: `/data/UNICEF.CME/*._T?...`

**Verbose output**:
```
Dataflow: UNICEF.CME (manual specification, agency extracted: UNICEF)
```

---

### Example 3: Override Agency

Manual dataflow can override agency parameter:

```stata
get_sdmx, indicator(CME) agency(WB) dataflow(UNICEF.CME)
```

**Behavior**:
- `agency(WB)` parameter is ignored
- `dataflow(UNICEF.CME)` takes precedence
- UNICEF agency extracted from dataflow
- Result: Uses UNICEF, not WB

**URL generated**: `/data/UNICEF.CME/*._T?...`

---

### Example 4: Multiple Indicators with Manual Dataflow

```stata
get_sdmx, indicator(CME UNK_CME MEASLES_POP) dataflow(UNICEF.CME) cache
```

**Behavior**:
- Uses UNICEF.CME as dataflow for all indicators
- Caches the result
- Efficient for pre-fetched schemas

---

### Example 5: Structure Query with Manual Dataflow

```stata
get_sdmx, indicator(CME) dataflow(UNICEF.CME) detail(structure)
```

**Behavior**:
- Fetches dataflow structure/schema
- Uses manual dataflow: UNICEF.CME
- URL: `/structure/dataflow/UNICEF.CME?references=all&detail=full`

---

## Implementation Details

### Parsing Logic

When `dataflow()` is provided:

1. **Extract agency** from format `AGENCY.DATAFLOW_CODE`
   - Uses regex: `^([A-Z0-9]+)\.(.+)$`
   - Captures AGENCY component
   - Updates local agency macro

2. **Store complete dataflow** for URL building
   - Saves as `manual_dataflow` local macro
   - Used in both data and structure endpoints

3. **URL construction**
   - Data: `/data/{manual_dataflow}/*._T?...`
   - Structure: `/structure/dataflow/{manual_dataflow}?...`

### Backward Compatibility

✅ **100% backward compatible**:
- No changes to existing behavior when `dataflow()` not specified
- All existing code continues to work unchanged
- Optional parameter, defaults to empty
- Auto-detection still works as before

### Priority

When both agency and dataflow provided:

| Parameter | Action |
|-----------|--------|
| `dataflow()` specified | ✅ Used (takes precedence) |
| `agency()` specified | Used only if `dataflow()` empty |
| Both specified | `dataflow()` wins, `agency()` ignored |

---

## Verbose Output

### With `noisily` flag and manual dataflow:

```stata
. get_sdmx, indicator(CME) dataflow(UNICEF.CME) noisily

    Dataflow: UNICEF.CME (manual specification, agency extracted: UNICEF)
    URL: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF.CME/*._T?format=csv&labels=id

✓ Data fetched successfully via curl (user-agent: Stata/1.0)
```

---

## Test Coverage

Test file: `tests/test_manual_dataflow.do`

**Tests included**:

1. ✅ **Test 1**: Auto-detection without dataflow (baseline)
2. ✅ **Test 2**: Manual dataflow specification  
3. ✅ **Test 3**: Dataflow overrides agency parameter
4. ✅ **Test 4**: Backward compatibility verification

**Run tests**:

```stata
do stata/tests/test_manual_dataflow.do
```

---

## Known Dataflow IDs

### UNICEF

| Code | Description |
|------|-------------|
| `UNICEF.CME` | Child Mortality Estimates |
| `UNICEF.UNK` | Under-5 Nutrition Knowledge |
| `UNICEF.MEASLES_POP` | Measles Population Coverage |

### World Bank

| Code | Description |
|------|-------------|
| `WB.SP.POP` | Population (World Bank) |
| `WB.NY.GDP` | GDP (World Bank) |

### WHO

| Code | Description |
|------|-------------|
| `WHO.HEALTH` | Health indicators |

---

## Performance Considerations

### When to Use Manual Dataflow

**Benefits**:
- Slightly faster (no auto-detection step)
- More explicit and self-documenting
- Useful for reproducibility scripts

**Trade-offs**:
- Requires knowing exact dataflow ID
- Less flexible if dataflow structure changes

### Recommendation

**Use manual dataflow when**:
- You have pre-computed dataflow IDs
- Running production scripts repeatedly
- Building automated pipelines
- Documentation needs to be explicit

**Use auto-detection when**:
- Exploring data interactively
- Learning the API
- Building flexible analysis workflows

---

## Error Handling

### Invalid Dataflow Format

If dataflow format doesn't match `AGENCY.DATAFLOW_CODE`:

```stata
get_sdmx, indicator(CME) dataflow(INVALID_FORMAT)
```

**Result**: 
- Still attempts to use as-is
- May fail at API fetch stage with HTTP 404
- Clear error message showing malformed URL

---

## Integration with Other Parameters

### With `cache`:

```stata
get_sdmx, indicator(CME) dataflow(UNICEF.CME) cache
```

Caches using dataflow ID as key.

### With Time Periods:

```stata
get_sdmx, indicator(CME) dataflow(UNICEF.CME) ///
          start_period(2015) end_period(2023)
```

Time period filters applied to manual dataflow queries.

### With `detail(structure)`:

```stata
get_sdmx, indicator(CME) dataflow(UNICEF.CME) detail(structure)
```

Fetches structure for manual dataflow.

---

## Development Notes

**File**: `stata/src/u/get_sdmx.ado`  
**Lines modified**:
- Syntax block: Added `DATAflow(string)` parameter
- Dataflow parsing: Lines ~119-135
- URL building: Lines ~217-226
- Verbose output: Integrated into existing displays

**Git commits**:
- Implementation: `feat: add manual dataflow parameter to get_sdmx`
- Message includes backward compatibility assurance

---

## Related Documentation

- **SDMX API Reference**: https://sdmx.data.unicef.org/
- **Agency-Specific Docs**: See `src/_/` folder
- **curl Integration**: See `CURL_IMPLEMENTATION.md`

---

*Last updated: January 16, 2026*

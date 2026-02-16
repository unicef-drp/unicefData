# Dataflow-Based Filtering Implementation Notes

**Date**: January 19, 2026  
**Status**: Design Phase  
**Question**: Can WS_HCF_* rely on dataflow eligible filter information from metadata instead of indicator prefix?

## Answer: YES Γ£ô

All three platforms can determine eligible filters directly from YAML metadata without relying on indicator prefix conventions.

---

## Current Implementation (Prefix-Based)

### R (unicef_core.R, line 283-305)
```r
if (length(indicator) == 1 && grepl("^WS_HCF_", toupper(indicator[[1]]))) {
    dataflow <- "WASH_HEALTHCARE_FACILITY"
    code <- toupper(indicator[[1]])
    tail <- sub("^WS_HCF_", "", code)
    # Parse tail to determine service_type: WAT, SAN, HYG, HCW, CLEAN
    # Hardcoded fallback values:
    hcf_vals <- c("_T","NON_HOS","HOS","GOV","NON_GOV")
    res_vals <- c("_T","U","R")
}
```

**Pros**: Fast, works offline  
**Cons**: Brittle if dimension values change, requires prefix convention

### Python (sdmx_client.py, line 429-462)
```python
if indicator_code.upper().startswith("WS_HCF_") and dataflow == "WASH_HEALTHCARE_FACILITY":
    tail = indicator_code.upper().split("WS_HCF_")[1]
    service_type_map = {"W-": "WAT", "S-": "SAN", "H-": "HYG", "WM-": "HCW", "C-": "CLEAN"}
    # Extract dimension lists from schema
    dims_dict = {d.get("id"): d for d in dimensions}
    if "HCF_TYPE" in dims_dict and dims_dict["HCF_TYPE"].get("values"):
        hcf_vals = dims_dict["HCF_TYPE"]["values"]
    else:
        hcf_vals = ["_T", "NON_HOS", "HOS", "GOV", "NON_GOV"]
```

**Pros**: Falls back to hardcoded defaults but reads from schema when available  
**Cons**: Still uses indicator prefix parsing

### Stata (currently hardcoded in unicefdata.ado)
- Uses indicator prefix pattern matching
- No schema lookups

---

## Improved Implementation (Metadata-Driven)

### Architecture

All three platforms should:

1. **Detect** that indicator needs special dimension handling (can be done via YAML metadata or prefix)
2. **Load** the dataflow schema from YAML (already available in all platforms)
3. **Extract** actual dimension values from schema
4. **Use** schema values instead of hardcoded fallbacks

### Metadata Files Already Available

| File | Location | Content |
|------|----------|---------|
| `dataflows/WASH_HEALTHCARE_FACILITY.yaml` | Stata src, R/Python metadata/current | Complete schema with dimensions and their values |
| `_dataflow_fallback_sequences.yaml` | All platforms | Maps indicator prefix ΓåÆ dataflow |
| `_unicefdata_indicators_metadata.yaml` | All platforms | Indicator ΓåÆ dataflow mapping (enriched) |

### Implementation Pattern

#### Stata: Use `__unicef_get_indicator_filters.ado`

```stata
// Get eligible filters for a dataflow
__unicef_get_indicator_filters, dataflow("WASH_HEALTHCARE_FACILITY")
return list
// Returns: r(filter_eligible_dimensions) = "HCF_TYPE RESIDENCE"
```

**Status**: Already implemented Γ£ô

#### R: Add to `unicef_core.R`

```r
#' Get eligible filter dimensions from dataflow schema
#' @param dataflow Character string (e.g. "WASH_HEALTHCARE_FACILITY")
#' @return List with dimension names and values
#' @keywords internal
.get_dataflow_schema_dims <- function(dataflow) {
  # Load dataflow schema (e.g. C:/GitHub/myados/unicefData/stata/src/_/dataflows/WASH_HEALTHCARE_FACILITY.yaml)
  candidates <- c(
    file.path(getwd(), 'stata/src/_/dataflows', paste0(dataflow, '.yaml')),
    file.path(getwd(), 'metadata/current/dataflows', paste0(dataflow, '.yaml'))
  )
  
  for (candidate in candidates) {
    if (file.exists(candidate)) {
      schema <- yaml::read_yaml(candidate)
      if (!is.null(schema$dimensions)) {
        return(schema$dimensions)
      }
    }
  }
  
  return(NULL)  # Not found
}
```

#### Python: Already Partially Implemented

In `sdmx_client.py` line 450+:
```python
# Extract dimension lists from schema
dims_dict = {d.get("id"): d for d in dimensions}
hcf_vals = dims_dict["HCF_TYPE"].get("values", ["_T", "NON_HOS", "HOS", "GOV", "NON_GOV"])
res_vals = dims_dict["RESIDENCE"].get("values", ["_T", "U", "R"])
```

This already reads from schema! Just ensure dimensions are always available.

---

## Benefits of Metadata-Driven Approach

1. **Resilience**: Automatic handling of new dimensions if schema changes
2. **Parity**: All platforms use same source of truth (YAML schema)
3. **Maintainability**: Single place to update (YAML), not three codebases
4. **Extensibility**: Adding new indicator types (WS_SCH_*, etc.) requires only YAML update
5. **Testability**: Can validate dimension values directly from schema

---

## Risks of Current Prefix-Based Approach

1. **Brittleness**: If API adds new HCF_TYPE values (e.g., "HYBRID"), code must change
2. **Maintainability**: Hardcoded lists in three places (R, Python, comment in Stata)
3. **Inconsistency**: Different fallback logic across platforms
4. **Silent failures**: If prefix parsing fails, uses hardcoded defaults with no warning

---

## Recommended Implementation Timeline

### Phase 1 (Short-term - No changes needed)
Current approach works. Schema reading already happens in Python.

### Phase 2 (Medium-term - Recommended)
Enhance R and Stata to read dimension values from schema instead of hardcoding:
- Add schema lookup in R's `_fetch_one_flow`
- Document schema lookup pattern in Stata helpers
- Ensure all three platforms log when using fallback vs. schema values

### Phase 3 (Long-term - Infrastructure improvement)
Decouple special handling from indicator prefix:
- Add `requires_special_handling: true` to indicator YAML metadata
- Add `eligible_dimensions: [HCF_TYPE, RESIDENCE]` to schema metadata
- Reference metadata instead of guessing from prefix

---

## Code References

### Stata
- [__unicef_get_indicator_filters.ado](stata/src/_/__unicef_get_indicator_filters.ado) - Extract dimensions from schema

### R  
- [unicef_core.R line 283-305](R/unicef_core.R#L283) - Current WS_HCF prefix-based logic
- [.load_fallback_sequences_yaml()](R/unicef_core.R#L94) - Dataflow lookup

### Python
- [sdmx_client.py line 428-462](python/unicef_api/sdmx_client.py#L428) - WS_HCF handling with schema fallback
- [metadata_manager.py](python/unicef_api/metadata_manager.py) - Schema loading

---

## Conclusion

**Question**: Can WS_HCF_* rely on dataflow eligible filter information from metadata instead of indicator prefix?

**Answer**: YES. The metadata (YAML schemas) contains all eligible filter dimensions. Current implementation partially uses this (Python reads from schema), but could be enhanced in R and Stata for better resilience.

**Recommendation**: For now, keep current approach (works reliably). Document pattern for future enhancement when new indicator types emerge.

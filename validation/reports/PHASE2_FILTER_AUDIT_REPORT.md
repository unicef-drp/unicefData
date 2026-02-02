# Phase 2 Filter Audit Report

**Date**: January 2026  
**Version**: 1.0  
**Author**: AI Audit System  
**Scope**: Cross-platform filter implementation review for unicefData

---

## Executive Summary

This report documents the findings from a comprehensive audit of filter implementations across Python, R, and Stata clients for the unicefData package. The audit was conducted to understand row count discrepancies observed in Phase 2 validation testing.

### Key Findings

| Finding | Status | Impact |
|---------|--------|--------|
| All platforms default to `_T` (totals) | ✅ Verified | By design |
| Escape hatches exist for all platforms | ✅ Verified | Users can fetch all disaggregations |
| Validation script has a **critical bug** | ❌ Bug Found | Root cause of discrepancies |
| Dataflow test coverage is **incomplete** | ⚠️ Gap | Only 5 of 38+ main dataflows tested |

---

## 1. Filter Implementation Audit

### 1.1 Python Client (`sdmx_client.py`)

**Location**: `python/unicef_api/sdmx_client.py`

**Default Filter (Line 499)**:
```python
def fetch_indicator(
    self,
    indicator: str,
    ...
    sex_disaggregation: str = "_T",  # ← Default to totals
    ...
):
```

**Filter Application (`_build_schema_aware_key()` lines 345-400)**:
- When `nofilter=False`, applies `_T` to all dimensions in schema
- Comment in code: "Default to totals (_T) for all other dimensions"

**Escape Hatch**:
```python
# Fetch all disaggregations:
client.fetch_indicator("CME_MRY0T4", nofilter=True)
```

**Verdict**: ✅ **Deliberate and intentional** - clearly documented behavior with explicit escape hatch.

---

### 1.2 R Client (`unicefData.R` + `unicef_core.R`)

**Location**: `R/unicefData.R` (lines 315-320)

**Default Filter**:
```r
unicefData <- function(
  indicator,
  ...
  sex = "_T",     # ← Default to totals
  wealth = NULL,  # Will be filtered to _T
  residence = NULL,  # Will be filtered to _T
  maternal_edu = NULL,  # Will be filtered to _T
  ...
)
```

**Filter Application** (`R/unicef_core.R` lines 611-680):
```r
filter_unicef_data <- function(data, ...) {
  # Filter by sex (default is '_T' for total)
  if (!is.null(sex) && sex != "ALL") {
    data <- data %>% filter(SEX == sex)
  }
  # Similar filtering for WEALTH, RESIDENCE, MATERNAL_EDU
}
```

**Escape Hatch**:
```r
# Fetch all disaggregations:
unicefData("CME_MRY0T4", sex = "ALL")
```

**Verdict**: ✅ **Deliberate and intentional** - consistent with Python, has explicit escape hatch.

---

### 1.3 Stata Client (`unicefdata.ado`)

**Location**: `stata/src/u/unicefdata.ado` (lines 540-560)

**Default Filter Logic**:
```stata
* Apply default _T to all dimensions that exist in the schema
foreach dim in SEX WEALTH RESIDENCE MATERNAL_EDU {
    local dimval = "__`dim'_val__"
    if missing("``dimval''") {
        * If dimension exists in schema but not specified, default to _T
        if strpos("`schema_dims'", "`dim'") > 0 {
            local `dimval' = "_T"
        }
    }
}
```

**Escape Hatch**:
```stata
* Fetch all disaggregations:
unicefdata, indicator(CME_MRY0T4) nofilter clear
```

**Verdict**: ✅ **Deliberate and intentional** - mirrors Python/R design with `nofilter` option.

---

## 2. Validation Script Bug

### 2.1 Bug Location

**File**: `validation/scripts/_archive/check_phase2_cases.py`  
**Lines**: 55-70

### 2.2 Bug Description

The `run_stata_fetch()` function accepts `start_year`, `end_year`, and `nofilter` parameters but **never passes them to the Stata command**.

**Current Code (Broken)**:
```python
def run_stata_fetch(indicator, start_year=None, end_year=None, nofilter=False):
    """Run Stata fetch - NOTE: start_year, end_year, nofilter are IGNORED!"""
    
    do_content = f"""
version 17
clear all
capture adopath ++ "{adopath}"
capture noisily unicefdata, indicator({indicator}) clear
    """
    # ^^^ Parameters not used! Always runs with defaults only
```

**Fixed Code (Proposed)**:
```python
def run_stata_fetch(indicator, start_year=None, end_year=None, nofilter=False):
    """Run Stata fetch with proper option forwarding"""
    
    opts = [f"indicator({indicator})", "clear"]
    if start_year and end_year:
        opts.append(f"year({start_year}:{end_year})")
    if nofilter:
        opts.append("nofilter")
    
    do_content = f"""
version 17
clear all
capture adopath ++ "{adopath}"
capture noisily unicefdata, {' '.join(opts)}
    """
```

### 2.3 Impact

| Platform | What validation script does | Result |
|----------|----------------------------|--------|
| **Python** | Passes `sex_disaggregation="_T"` | Gets totals only |
| **R** | Passes `sex = "_T"` | Gets totals only |
| **Stata** | Passes **no options** | Gets schema defaults (should be same, but inconsistent test) |

This explains why Phase 2 validation shows **Stata returning more rows** - the validation script is not running equivalent commands across platforms.

---

## 3. Dataflow Test Coverage

### 3.1 Phase 2 Test Cases (6 indicators)

| Indicator | Primary Dataflow | Also In |
|-----------|------------------|---------|
| `WS_HCF_H-L` | WASH_HEALTHCARE_FACILITY | GLOBAL_DATAFLOW |
| `ECD_CHLD_U5_BKS-HM` | ECD | GLOBAL_DATAFLOW |
| `ED_MAT_G23` | EDUCATION, EDUCATION_UIS_SDG | GLOBAL_DATAFLOW |
| `FD_FOUNDATIONAL_LEARNING` | FUNCTIONAL_DIFF | GLOBAL_DATAFLOW |
| `NT_CF_ISSSF_FL` | NUTRITION | GLOBAL_DATAFLOW |
| `NT_CF_MMF` | NUTRITION | GLOBAL_DATAFLOW |

### 3.2 Dataflows Covered

✅ **Tested** (5 main dataflows):
1. WASH_HEALTHCARE_FACILITY
2. ECD
3. EDUCATION / EDUCATION_UIS_SDG
4. FUNCTIONAL_DIFF
5. NUTRITION

### 3.3 Dataflows NOT Covered

❌ **Not tested** (33+ main dataflows):

| Dataflow | Description |
|----------|-------------|
| **CME** | Child Mortality Estimates (flagship) |
| **IMMUNISATION** | Vaccination coverage |
| **HIV_AIDS** | HIV/AIDS indicators |
| **MNCH** | Maternal, Newborn, Child Health |
| **CHLD_PVTY** | Child Poverty |
| **GENDER** | Gender equality indicators |
| **DM** | Demographics |
| **DM_PROJECTIONS** | Demographic projections |
| **MG** | Migration |
| **PT** | Protection |
| **PT_CM** | Child Marriage |
| **PT_CONFLICT** | Conflict-related |
| **PT_FGM** | FGM indicators |
| **SOC_PROTECTION** | Social Protection |
| **CAUSE_OF_DEATH** | Causes of death |
| **CCRI** | Climate risk index |
| **CHILD_RELATED_SDG** | SDG indicators |
| **COVID** / **COVID_CASES** | COVID-19 data |
| **ECONOMIC** | Economic indicators |
| **SDG_PROG_ASSESSMENT** | SDG progress |
| **WASH_HOUSEHOLDS** | WASH household data |
| **WASH_SCHOOLS** | WASH schools data |
| **WASH_HOUSEHOLD_SUBNAT** | WASH subnational |
| **WASH_HOUSEHOLD_MH** | WASH menstrual hygiene |
| **WT** | Weight indicators |
| CME_SUBNAT_* (28 countries) | Subnational child mortality |
| PT_CM_SUBNATIONAL | Subnational child marriage |

### 3.4 Coverage Summary

| Category | Count | Percentage |
|----------|-------|------------|
| Main dataflows tested | 5 | 13% |
| Main dataflows NOT tested | 33 | 87% |
| Subnational dataflows tested | 0 | 0% |
| Subnational dataflows total | ~32 | N/A |
| **Total coverage** | 5/70 | **7%** |

---

## 4. Recommendations

### 4.1 Immediate Actions

1. **Fix validation script bug** (Priority: HIGH)
   - Update `check_phase2_cases.py` to pass options to Stata
   - Re-run all Phase 2 tests

2. **Expand test coverage** (Priority: MEDIUM)
   - Add at least one indicator from each main dataflow
   - Prioritize flagship dataflows: CME, IMMUNISATION, HIV_AIDS, MNCH

### 4.2 Suggested Test Expansion

| Dataflow | Suggested Indicator | Rationale |
|----------|---------------------|-----------|
| CME | CME_MRY0T4 | Most-used indicator, good for testing |
| IMMUNISATION | IM_DTP3 | DPT3 coverage - well-documented |
| HIV_AIDS | HIV_PMTCT_ARV_CVG | PMTCT coverage |
| MNCH | MNCH_ANC4 | Antenatal care visits |
| CHLD_PVTY | PV_CHLD_PP | Child poverty rate |
| GENDER | GN_YOUTH_READING | Youth literacy |
| DM | DM_POP_U18 | Under-18 population |
| SOC_PROTECTION | SP_COV_CHLD | Child benefit coverage |

### 4.3 Long-term Recommendations

1. **Automated coverage checks**: Script to verify all main dataflows have test cases
2. **Schema validation tests**: Test each dataflow's dimension filtering
3. **Regression testing**: Track row counts over API versions

---

## 5. Appendix: Filter Design Philosophy

### Why Default to `_T` (Totals)?

The decision to default to `_T` across all platforms is **intentional** based on:

1. **User expectation**: Most users want aggregate/total values
2. **Data volume**: Full disaggregation returns 10-50x more rows
3. **API performance**: Smaller queries are faster
4. **Consistency**: Aligns with World Bank API behavior (`wbopendata`)

### Cross-Platform Alignment

| Feature | Python | R | Stata |
|---------|--------|---|-------|
| Default sex filter | `_T` | `_T` | `_T` |
| Escape hatch | `nofilter=True` | `sex="ALL"` | `nofilter` |
| Year filtering | `start_year`, `end_year` | `year` | `year()` |
| Explicit filter | Dimension params | Dimension params | Schema-aware key |

---

## 6. Appendix: Code References

| Platform | File | Key Lines |
|----------|------|-----------|
| Python | `python/unicef_api/sdmx_client.py` | 499 (default), 345-400 (key builder) |
| R | `R/unicefData.R` | 315-320 (defaults), `unicef_core.R` 611-680 (filter) |
| Stata | `stata/src/u/unicefdata.ado` | 540-560 (defaults) |
| Stata | `stata/src/_/_unicef_build_schema_key.ado` | Full file (key construction) |
| Validation | `validation/scripts/_archive/check_phase2_cases.py` | 55-70 (BUG) |

---

*End of Report*

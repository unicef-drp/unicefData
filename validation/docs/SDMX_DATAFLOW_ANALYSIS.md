# SDMX Dataflow-Indicator Mapping Analysis

**Date**: 2026-01-12  
**Source**: Python metadata/current/dataflows YAML files  
**Total Dataflows**: 69  
**Purpose**: Identify actual indicator distribution for harmonizing fallback logic

---

## Key Findings from Actual SDMX Data

### Indicator Prefix Distribution

| Prefix | Dataflows | Sample Dataflows | Indicator Count | Notes |
|--------|-----------|-----------------|-----------------|-------|
| **CME** | 41 | CME, CME_CAUSE_OF_DEATH, CME_DF_2021_WQ, CME_SUBNATIONAL, CME_SUBNAT_* | 200+ | Child mortality has extensive subnational breakdowns |
| **PT** | 3 | PT, PT_CM, PT_FGM, PT_CONFLICT | 35+ | Protection split into subdataflows by topic |
| **WASH** | 4 | WASH_HOUSEHOLDS, WASH_SCHOOLS, WASH_HEALTHCARE_FACILITY | 40+ | WASH split by facility type |
| **ED** | 3 | EDUCATION, EDUCATION_FLS, EDUCATION_UIS_SDG | 30+ | Education split between UIS and FLS sources |
| **HIV** | 1 | HIV_AIDS | 10+ | HIV/AIDS indicators in one dataflow |
| **NT** | 1 | NUTRITION | 8+ | Nutrition in one dataflow |
| **IM** | 1 | IMMUNISATION | 10+ | Immunisation in one dataflow |
| **MNCH** | 1 | MNCH | 10+ | Maternal/Child health in one dataflow |
| **ECD** | 1 | ECD | 6+ | Early childhood development in one dataflow |
| **PV/CHLD** | 1 | CHLD_PVTY | 1+ | Child poverty in one dataflow |
| **SOC_PROTECTION** | 1 | SOC_PROTECTION | 9+ | Social protection in one dataflow |
| **MG** | 1 | MG | 6+ | Migration indicators in one dataflow |
| **DM** | 2 | DM, DM_PROJECTIONS | 4+ | Demographics and projections |
| **COVID** | 2 | COVID, COVID_CASES | 4+ | COVID-19 specific indicators |
| **GEN** | 1 | GENDER | 10+ | Gender related indicators |
| **FD** | 1 | FUNCTIONAL_DIFF | 10+ | Functional disability/difficulty |
| **ECO** | 1 | ECONOMIC | 10+ | Economic indicators |
| **SDG_PROG** | 1 | SDG_PROG_ASSESSMENT | 10+ | SDG progress tracking |
| **CCRI** | 1 | CCRI | 10+ | Climate/environment risk |
| **CAUSE_OF_DEATH** | 1 | CAUSE_OF_DEATH | 0 (metadata only) | Death causes categorization |
| **CHILD_RELATED_SDG** | 1 | CHILD_RELATED_SDG | 2 | Child-related SDG indicators |
| **GLOBAL_DATAFLOW** | 1 | GLOBAL_DATAFLOW | 10+ | Fallback dataflow with wide coverage |

---

## Critical Findings for Fallback Sequences

### 1. PT (Protection) Prefix
**Actual Distribution**: Indicators split across PT, PT_CM, PT_FGM, PT_CONFLICT
```
PT_CM_EMPLOY_12M        → PT_CM dataflow
PT_F_20-24_MRD_U18_TND  → PT_CM dataflow (child marriage)
PT_F_0-14_FGM           → PT_FGM dataflow
PT_F_15-49_FGM          → PT_FGM dataflow
PT_CHLD_CONFLICT        → PT_CONFLICT dataflow
```

**Current v1.6.0 Fallback (R/Stata)**: ✅ CORRECT
```
PT → PT_CM → PT_FGM → CHILD_PROTECTION → GLOBAL_DATAFLOW
```

**But missing**: ⚠️ PT_CONFLICT not in fallback sequence!

---

### 2. COD (Cause of Death) Prefix
**Actual Distribution**: 
- `CAUSE_OF_DEATH` dataflow exists (metadata only, 0 indicators in values)
- Child mortality causes in `CME_CAUSE_OF_DEATH` dataflow
- COVID cases in `COVID_CASES` dataflow

**Current v1.6.0 Fallback (R/Stata)**: ✅ PARTIALLY CORRECT
```
COD → CAUSE_OF_DEATH → GLOBAL_DATAFLOW
```

**Better approach**: Should also try CME_CAUSE_OF_DEATH
```
COD → CME_CAUSE_OF_DEATH → CAUSE_OF_DEATH → GLOBAL_DATAFLOW
```

---

### 3. WASH (Water/Sanitation/Hygiene) Prefix
**Actual Distribution**: Split across 4 dataflows
```
WS_PPL_H-B      → WASH_HOUSEHOLDS
WS_SCH_W-B      → WASH_SCHOOLS
WS_HCF_C-B      → WASH_HEALTHCARE_FACILITY
WS_PPL_M-NPART  → WASH_HOUSEHOLD_MH (or WASH_HOUSEHOLD_SUBNAT)
```

**Python v1.6.0**: ❌ NOT IN DATAFLOW_ALTERNATIVES
**R/Stata v1.6.0**: ❌ NOT IN FALLBACK SEQUENCES

**Needed v1.6.0 Addition**:
```
WS → WASH_HOUSEHOLDS → WASH_SCHOOLS → WASH_HEALTHCARE_FACILITY → GLOBAL_DATAFLOW
```

---

### 4. ED (Education) Prefix
**Actual Distribution**: Split across 3 dataflows
```
ED_CR_L1_UIS_MOD       → EDUCATION_UIS_SDG
ED_ANAR_L02            → EDUCATION_UIS_SDG or EDUCATION or EDUCATION_FLS
ED_FLS_READ            → EDUCATION_FLS
```

**Python v1.6.0**: ⚠️ INCOMPLETE
```python
'ED': ['EDUCATION_UIS_SDG', 'EDUCATION'],  # Missing EDUCATION_FLS
```

**R/Stata v1.6.0**: ❌ MISSING ENTIRELY

**Needed v1.6.0 Update**:
```
ED → EDUCATION_UIS_SDG → EDUCATION → EDUCATION_FLS → GLOBAL_DATAFLOW
```

---

### 5. CME (Child Mortality) Prefix
**Actual Distribution**: 41+ dataflows!
```
CME                    → Main child mortality dataflow
CME_DF_2021_WQ        → IGME estimates
CME_SUBNATIONAL       → Subnational aggregation
CME_SUBNAT_*          → Country-specific subnational
CME_CAUSE_OF_DEATH    → Mortality by cause
CME_COUNTRY_PROFILES  → Country profiles
COVID_CASES           → COVID-specific (CME_ prefix indicators)
```

**Python/R/Stata v1.6.0**: ❌ MISSING ENTIRELY (only GLOBAL_DATAFLOW fallback)

**Needed v1.6.0 Addition**:
```
CME → CME_DF_2021_WQ → CME_SUBNATIONAL → GLOBAL_DATAFLOW
```

---

### 6. IM (Immunisation) Prefix
**Actual Distribution**: All in IMMUNISATION dataflow

**Python/R/Stata v1.6.0**: ❌ MISSING ENTIRELY

**Needed v1.6.0 Addition**:
```
IM → IMMUNISATION → GLOBAL_DATAFLOW
```

---

### 7. NT (Nutrition) Prefix
**Actual Distribution**: All in NUTRITION dataflow

**Python v1.6.0**: ⚠️ INCOMPLETE
```python
'NT': ['NUTRITION', 'GLOBAL_DATAFLOW'],  # OK but could add NUTRITION_DIETS if exists
```

**R/Stata v1.6.0**: ❌ MISSING ENTIRELY

**Current**: OK, but should check for `NUTRITION_DIETS` alternative

---

### 8. WT (Worktable/Water/Other) Prefix
**Analysis Needed**: Only 0 indicators found directly...
- May be in WASH_HOUSEHOLDS or PT dataflows
- Need to verify actual usage

**Current v1.6.0 Fallback (R/Stata)**:
```
WT → PT → CHILD_PROTECTION → GLOBAL_DATAFLOW
```

**Assessment**: ⚠️ Needs validation against real WT indicator names

---

### 9. TRGT Prefix
**Analysis**: Only found in CHILD_RELATED_SDG dataflow (2 indicators)
- `SH_FPL_MTMM` (Stunting/wasting)
- `SP_DYN_ADKL` (Adolescent mortality)

**Current v1.6.0 Fallback (R/Stata)**:
```
TRGT → CHILD_RELATED_SDG → GLOBAL_DATAFLOW
```

**Assessment**: ✅ CORRECT but very limited coverage

---

### 10. SPP (Social Protection) Prefix
**Actual Distribution**: All in SOC_PROTECTION dataflow

**Current v1.6.0 Fallback (R/Stata)**: ✅ CORRECT
```
SPP → SOC_PROTECTION → GLOBAL_DATAFLOW
```

**Python v1.6.0**: ❌ MISSING ENTIRELY

---

## Harmonized v1.6.0+ Fallback Sequences

Based on actual SDMX dataflow distribution:

```yaml
# metadata/dataflow_fallback_sequences.yaml
dataflow_fallbacks:
  # Protection: 3 specific dataflows + fallback
  PT:
    - PT
    - PT_CM
    - PT_FGM
    - PT_CONFLICT          # NEW: added based on actual data
    - CHILD_PROTECTION
    - GLOBAL_DATAFLOW

  # Education: 3 dataflows
  ED:
    - EDUCATION_UIS_SDG
    - EDUCATION
    - EDUCATION_FLS
    - GLOBAL_DATAFLOW

  # Child Mortality: 3 major dataflows
  CME:
    - CME
    - CME_DF_2021_WQ
    - CME_SUBNATIONAL
    - GLOBAL_DATAFLOW

  # Cause of Death: 2 dataflows
  COD:
    - CME_CAUSE_OF_DEATH
    - CAUSE_OF_DEATH
    - GLOBAL_DATAFLOW

  # WASH: 3 facility types
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
    - CHILD_POVERTY          # Alternative name if exists
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

  # Worktable (verification needed)
  WT:
    - WASH_HOUSEHOLDS
    - PT
    - CHILD_PROTECTION
    - GLOBAL_DATAFLOW

  # Default
  DEFAULT:
    - GLOBAL_DATAFLOW
```

---

## Recommendations for v1.6.0 Harmonization

### 1. Create Canonical YAML
✅ Save this mapping to `metadata/dataflow_fallback_sequences.yaml`

### 2. Update Python (CRITICAL)
Add missing prefixes: CME, IM, NT, ED (full), WS, TRGT, SPP, MNCH, ECD, HVA, PV, DM, MG, GN, FD, ECO, COVID, WT, and DEFAULT

### 3. Update R
Add all new prefixes from canonical YAML, especially: CME, IM, NT, ED, WS, MNCH, ECD, HVA, PV, DM, MG, GN, FD, ECO, COVID, WT

### 4. Update Stata
Add all new prefixes, especially: CME, IM (already has some), WS, MNCH, DM, MG, GN, FD, ECO

### 5. Load YAML in All Platforms
Replace hardcoded fallback lists with YAML loader for single source of truth

---

## Test Validation

After implementing harmonized sequences:

- [ ] Run seed-42 test with CME prefix indicators
- [ ] Run seed-42 test with WASH prefix indicators  
- [ ] Run seed-42 test with ED prefix indicators
- [ ] Run seed-42 test with IM prefix indicators
- [ ] Run seed-42 test with PT_CONFLICT indicators
- [ ] Verify all 3 platforms return identical results
- [ ] Document any discrepancies

---

## Next Steps

1. Create `metadata/dataflow_fallback_sequences.yaml` with complete mapping
2. Update Python `unicef_api/core.py` to load from YAML
3. Update R `unicef_core.R` to load from YAML
4. Update Stata `_unicef_fetch_with_fallback.ado` to load from YAML
5. Run comprehensive cross-platform validation
6. Document version v1.5.2 with unified fallback logic

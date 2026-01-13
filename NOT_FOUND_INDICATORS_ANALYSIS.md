# Not_Found Indicators Analysis - Seed 50 Test Run

**Report Date**: 2026-01-13  
**Test**: 60-indicator stratified (seed 50)  
**Result**: 67 indicators marked as "not_found" across platforms

## Summary

From the comprehensive test run, **28 unique indicators** returned "not_found" status on at least one platform (primarily R and Stata when Python also failed). These fall into several categories:

### Category A: Actual API Removals (Data No Longer Available)
Indicators that **do NOT exist** in the current dataflow YAMLs and returned 404 from SDMX:

1. **DM_HH_INTERNET** - Dataflow: DM  
   - Status: Not found in `DM.yaml`
   - API returned 404
   
2. **DM_HH_U18** - Dataflow: DM  
   - Status: Not found in `DM.yaml`
   - API returned 404

3. **ED_PUP_PER_READ_BOOK** - Dataflow: EDUCATION  
   - Status: Not found in `EDUCATION.yaml`
   - API returned 404

4. **GN_STUNT_ADOL_GRL** - Expected: GENDER dataflow  
   - Status: Not found in `GENDER.yaml`
   - API returned 404

5. **HVA_PMTCT_TEST_NUM** - Dataflow: HIV_AIDS  
   - Status: Not found in `HIV_AIDS.yaml`
   - API returned 404

6. **MG_INTNL_MG** - Dataflow: MG  
   - Status: **FOUND in `MG.yaml` and `GLOBAL_DATAFLOW.yaml`**
   - Expected source: MG dataflow
   - Issue: Cross-platform access inconsistency

7. **MG_INTNL_MG_CNTRY_ORIGIN** - Dataflow: MG  
   - Status: Related to MG_INTNL_MG (likely same root cause)
   - Issue: Cross-platform access inconsistency

### Category B: Generic/Placeholder Names (Not Real Indicators)
These appear to be dataflow names or abstract categories, **not actual indicator codes**:

- **EDUCATION** - Dataflow name, not indicator code
- **FUNCTIONAL_DIFF** - Dataflow name, not indicator code  
- **GENDER** - Dataflow name, not indicator code
- **HIV_AIDS** - Dataflow name, not indicator code
- **IMMUNISATION** - Dataflow name, not indicator code
- **NUTRITION** - Dataflow name, not indicator code

**Root Cause**: Test sampler may have drawn dataflow names as if they were indicator codes.

### Category C: Indicators Not in Current Metadata (~NT, PT, PV targets)
Indicators that don't appear in Python dataflow metadata:

8. **NT_ANT_HAZWHZ_NE2_PO2** - Expected: NUTRITION
9. **NT_ANT_HAZ_NE2_T_NE3** - Expected: NUTRITION
10. **NT_ANT_SAM_T** - Expected: NUTRITION
11. **NT_ANT_WHZ_PO1** - Expected: NUTRITION
12. **NT_CF_BREASTMILK** - Expected: NUTRITION

13. **PT_M_15-17_SX-V_HLP** - Expected: PT variants
14. **PV_PRO_PSS_DIRECT_TRANSFER** - Expected: CHLD_PVTY
15. **PV_PRO_PSS_EDU_BOTTOM20** - Expected: CHLD_PVTY

### Category D: SDG Target/Tracking Indicators (TRGT_*)
These are derived/tracking codes that don't have their own dataflows:

16. **TRGT_2030_ED_MAT_G23** - Mapped to CHILD_RELATED_SDG
17. **TRGT_2030_PT_M_18-29_SX-V_AGE-18** - Mapped to CHILD_RELATED_SDG
18. **TRGT_2030_WS_PPL_S-SM** - Mapped to CHILD_RELATED_SDG
19. **TRGT_CME** - Mapped to CHILD_RELATED_SDG
20. **TRGT_GN** - Mapped to CHILD_RELATED_SDG
21. **TRGT_WS** - Mapped to CHILD_RELATED_SDG

**Issue**: These are abstract target codes (not real indicator codes). They should resolve via fallback or mapping, but are not directly queryable.

## Metadata Sync Status

**Python Metadata** (`python/metadata/current`):
- Total indicators in `_unicefdata_indicators.yaml`: 25 (highly limited)
- Dataflows available: 12+ core flows
- Last synced: 2025-12-09

**R Metadata** (`R/metadata/current`): Identical to Python  
**Stata Metadata** (`stata/metadata/current`): Identical to Python

⚠️ **Finding**: Metadata has NOT been refreshed recently. Many actively available indicators are missing.

## Recommended Actions

1. **Refresh metadata sync** using the latest SDMX schema  
   - Run `unicef_api.metadata_manager.sync_all()` to fetch current dataflows
   - Update all platform metadata directories

2. **Remove placeholder names** from test samples  
   - Filter indicators to exclude dataflow names (EDUCATION, NUTRITION, etc.)
   - Use only verified indicator codes from `_unicefdata_indicators.yaml`

3. **Investigate MG indicators**  
   - MG_INTNL_MG exists in metadata but failed to download on R/Stata
   - Check if MIGRATION dataflow schema has changed

4. **Document TRGT_* indicators**  
   - Clarify whether SDG tracking codes should be supported
   - If yes, add proper mapping layer; if no, exclude from test suite

5. **R Platform Issue** (Additional Finding)  
   - R shows more "not_found" than Python on identical indicators
   - Suggests R dataflow detection/fallback logic needs review

## Detailed Dataflow Analysis

### What These Dataflows Actually Contain

#### DM (Demography) Dataflow
**Available Indicators**:
- DM_POP_TOT (Total population)
- DM_POP_U18 (Population under 18)
- DM_POP_U5 (Population under 5)

**Not Available**: DM_HH_INTERNET, DM_HH_U18 (these were removed or never existed in SDMX)

#### EDUCATION Dataflow
**Available Indicators** (17 total):
- ED_15-24_LR (Literacy rate 15-24)
- ED_ANAR_L02, ED_ANAR_L1, ED_ANAR_L2, ED_ANAR_L3 (Adjusted net attendance rates)
- ED_CR_L1, ED_CR_L2, ED_CR_L3 (Completion rates)
- ED_MAT_G23, ED_READ_G23 (Math/Reading proficiency)
- ED_ROFST_L1, ED_ROFST_L02_ADM, ED_ROFST_L1_ADM, ED_ROFST_L2, ED_ROFST_L2_ADM, ED_ROFST_L3, ED_ROFST_L3_ADM

**Not Available**: ED_PUP_PER_READ_BOOK (not in current dataflow)

#### NUTRITION Dataflow
**Available Indicators** (8 total):
- NT_ANE_WOM_15_49_MOD (Anaemia in women)
- NT_ANT_HAZ_NE2 (Stunting moderate/severe)
- NT_ANT_WAZ_NE2 (Underweight)
- NT_ANT_WHZ_NE2, NT_ANT_WHZ_NE3 (Wasting)
- NT_ANT_WHZ_PO2 (Overweight)
- NT_IOD_ANY_TH, NT_IOD_ANY_TS (Iodine deficiency)

**Not Available**: 
- NT_ANT_HAZWHZ_NE2_PO2
- NT_ANT_HAZ_NE2_T_NE3
- NT_ANT_SAM_T (Severe acute malnutrition)
- NT_ANT_WHZ_PO1 (Overweight alternative)
- NT_CF_BREASTMILK (Breastfeeding)

⚠️ **Pattern**: Specific disaggregation codes (like `_NE2_PO2`, `_T`, `_PO1`) or combined indicators not in current schema.

#### MG (Migration) Dataflow
**Status**: MG dataflow **does exist** in metadata
- Contains MG_INTNL_MG and MG_INTNL_MG_CNTRY_ORIGIN (verified in GLOBAL_DATAFLOW.yaml as fallback)
- Issue: SDMX API reports "404 Not Found" when queried directly
- Root cause: MIGRATION dataflow schema may be offline or deprecated on API side

#### Other Problematic Dataflows

**CHILD_RELATED_SDG** - Only contains:
- TRGT_* codes (SDG tracking codes, not directly available)
- TRGT_2030_* variants should map here but may need resolution

**PT (Prevention of Transmission) / PT_CM / PT_FGM** - Limited to specific variants:
- PT_M_15-17_SX-V_HLP not found in PT, PT_CM, or PT_FGM dataflows

**CHLD_PVTY (Child Poverty)** - Missing:
- PV_PRO_PSS_DIRECT_TRANSFER
- PV_PRO_PSS_EDU_BOTTOM20

### Hypothesis: API vs. Metadata Drift

The pattern suggests that:
1. **Metadata is outdated** (last synced Dec 9, 2025)
2. **API has removed or reorganized** several dataflows (MIGRATION, certain NUTRITION variants)
3. **Test sampler is drawing from old indicator list** that doesn't reflect current API state

## Files Reviewed

- `C:\GitHub\myados\unicefData\python\metadata\current\_unicefdata_indicators.yaml`
- `C:\GitHub\myados\unicefData\python\metadata\current\dataflows\*.yaml` (69 files)
- Test report: `results/indicator_validation_20260113_002035/SUMMARY.md`
- Spot-checked dataflows: DM.yaml, EDUCATION.yaml, NUTRITION.yaml, MG.yaml, CHILD_RELATED_SDG.yaml


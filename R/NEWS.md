# unicefData R Library - Release Notes

## Version 1.6.0 (2026-01-12)

### Dataflow Enhancements

**Intelligent Fallback Sequences**
- Implemented prefix-specific fallback chains for improved indicator discovery
- PT indicators: PT → PT_CM → PT_FGM → CHILD_PROTECTION → GLOBAL_DATAFLOW
- COD indicators: CAUSE_OF_DEATH → GLOBAL_DATAFLOW
- TRGT indicators: CHILD_RELATED_SDG → GLOBAL_DATAFLOW
- SPP indicators: SOC_PROTECTION → GLOBAL_DATAFLOW
- WT indicators: PT → CHILD_PROTECTION → GLOBAL_DATAFLOW

**New Prefix Mappings**
- COD: Maps to CAUSE_OF_DEATH dataflow (health indicators)
- TRGT: Maps to CHILD_RELATED_SDG dataflow (SDG targets)
- SPP: Maps to SOC_PROTECTION dataflow (social protection programs)
- WT: Maps to PT dataflow (child labor indicators)

**PT Subdataflow Support**
- Extended PT fallback to include child marriage (PT_CM) and female genital mutilation (PT_FGM) subdataflows
- Enables indicators like `PT_F_20-24_MRD_U18_TND` (child marriage) and `PT_F_15-49_FGM` (FGM prevalence)

**Cross-Language Parity**
- Feature alignment with Python and Stata implementations
- Consistent fallback behavior across all three languages
- Seed-42 validation confirms cross-platform consistency

### Technical Improvements

- Updated `get_fallback_dataflows()` to accept `indicator_code` parameter for intelligent prefix detection
- Improved error handling and fallback logic in `unicefData_raw()`
- Enhanced documentation with version headers and changelog

### Bug Fixes

- Fixed fallback sequence to avoid duplicate dataflow attempts
- Improved prefix extraction for edge cases

---

## Version 1.5.2 and earlier

See main repository [NEWS.md](../NEWS.md) for earlier versions.

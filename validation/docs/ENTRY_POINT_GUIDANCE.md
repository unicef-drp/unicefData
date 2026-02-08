# Validation Framework Entry Point - Guidance Added

**Date:** January 20, 2026  
**File Updated:** `validation/run_validation.py`  
**Purpose:** Guide users on proper result interpretation using tier classification

## What Was Added

The entry point script now includes comprehensive guidance on:

1. **Tier Classification Context** (lines 5-10)
   - Explains what Tier 1, 2, and 3 mean
   - Emphasizes the common error: treating Tier 2 as failures

2. **Quick Start** (lines 12-13)
   - Simple command to run validation

3. **Understanding Results - Guided Reading Path** (lines 15-32)
   - Step 1: Tier Classification Reference (mandatory first read)
   - Step 2: Your Specific Results README
   - Step 3: Detailed Analysis
   - Step 4: Complete Documentation Index

4. **Common Questions Answered** (lines 34-43)
   - Q: Why did my indicator fail?
   - Q: Is "no data" a failure? (No! It's Tier 2 - explained)
   - Q: How do I know what tier my indicator is?

5. **Quick Reference** (lines 45-52)
   - Framework file locations
   - How to reproduce validation
   - How to debug issues

6. **Debugging Tips** (lines 54-59)
   - Verbose mode
   - Run specific indicator
   - UTF-8 encoding for Windows

## Why This Matters

The original validation exercise had this problem:
- ED_LN_R_L2 and NT_ANT_BAZ_NE2 were "failing" 
- But they're TIER 2 indicators with no data (that's correct!)
- Result: Users misinterpreted success as failure

Now, when users run `python run_validation.py`:
1. They see the guidance immediately
2. They're directed to reference documents in the right order
3. They understand Tier 2 indicators before reading results
4. They can't misinterpret outcomes

## ASCII-Safe Design

The guidance uses only ASCII characters for Windows PowerShell compatibility:
- No unicode box-drawing characters (═, └, │)
- Clean, readable formatting with hyphens and spaces
- Prints correctly on Windows (UTF-8 enforced in code)

## Files Referenced

When users follow the guidance, they'll read in this order:

| Step | File | Purpose |
|------|------|---------|
| 1 | `validation/docs/INDICATOR_TIER_CLASSIFICATION.md` | Define tiers and interpretation rules |
| 2 | `validation/results/[TIMESTAMP]/README.md` | Navigate their specific results |
| 3 | `validation/results/[TIMESTAMP]/TIER_CLASSIFICATION_ANALYSIS.md` | Deep analysis with examples |
| 4 | `validation/DOCUMENTATION_INDEX.md` | Complete reference (optional) |

## How to Test

```powershell
cd C:\GitHub\myados\unicefData-dev\validation
python run_validation.py
```

Output should display guidance with no errors.

## Integration Points

This guidance integrates with:
- ✅ Metadata in `stata/src/_/_unicefdata_indicators_metadata.yaml`
- ✅ Validation results in `validation/results/*/`
- ✅ Documentation in `validation/docs/`
- ✅ Analysis files in `validation/results/*/TIER_CLASSIFICATION_ANALYSIS.md`

## Success Criteria

- [x] Script runs without encoding errors
- [x] Guidance displays correctly
- [x] All referenced files exist and are properly documented
- [x] Links in guidance point to correct files
- [x] Tier classification context front-and-center
- [x] Users cannot misinterpret Tier 2 indicators as failures

---

**Created by**: GitHub Copilot  
**Context**: UNICEF Data Validation Framework - Tier Classification Project  
**Related Issues**: ED_LN_R_L2 and NT_ANT_BAZ_NE2 misclassification as failures

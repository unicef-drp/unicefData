# Phase 2: Cross-Platform Validation & Testing Protocol

**Status**: Ready for Execution  
**Created**: January 12, 2026  
**Target Completion**: January 13, 2026  
**Responsible**: Cross-platform validation team

---

## Overview

Phase 2 validates that all three platforms (Python, R, Stata) load identical fallback sequences from the unified architecture implemented in Phase 1. This ensures:

1. **Consistency**: All platforms return the same 20 fallback sequences for any indicator prefix
2. **Completeness**: All 20 indicator prefixes are supported uniformly
3. **YAML Integration**: YAML loading works correctly on all platforms
4. **Backward Compatibility**: Graceful fallback to hardcoded defaults if YAML unavailable
5. **Reproducibility**: Tests are deterministic with seed-based randomization

---

## Test Artifacts

### 1. Python Validation Script
**File**: `C:\GitHub\myados\unicefData\validation\test_unified_fallback_validation.py`

**Purpose**: Comprehensive cross-platform test runner

**Capabilities**:
- Loads canonical YAML from `metadata/current/_dataflow_fallback_sequences.yaml`
- Tests Python `FALLBACK_SEQUENCES` variable
- Tests R `.FALLBACK_SEQUENCES_YAML` environment
- Tests Stata fallback sequence loading
- Validates consistency across all three platforms
- Generates JSON results with detailed error reporting

**Usage**:
```bash
# Run all tests with default settings
python test_unified_fallback_validation.py

# Run specific platforms with verbose output
python test_unified_fallback_validation.py --languages python r --verbose

# Run with custom seed and output directory
python test_unified_fallback_validation.py --seed 42 --output-dir ./test_results/

# Run with limited output (headless mode)
python test_unified_fallback_validation.py --languages python r
```

**Output**:
- Console: Color-coded test results with platform status
- File: `./results/unified_fallback_validation_{seed}.json` with full test details
- Format: JSON with timestamp, platform results, consistency status, errors

**Key Tests**:
1. Python import and FALLBACK_SEQUENCES loading
2. R source file and .FALLBACK_SEQUENCES_YAML loading
3. Stata adoption and fallback sequence verification
4. Consistency checks across platform pairs
5. Error capture and detailed reporting

### 2. Stata Validation Script
**File**: `C:\GitHub\myados\unicefData\stata\validation\test_fallback_sequences.do`

**Purpose**: Stata-specific fallback validation

**Capabilities**:
- Checks yaml.ado availability (auto-installs if missing)
- Verifies canonical YAML file exists
- Tests YAML loading via `_unicef_load_fallback_sequences.ado`
- Validates 20 hardcoded fallback prefixes
- Generates detailed test log
- Exits with success/failure code for CI integration

**Usage**:
```stata
* From Stata command line
do "C:\GitHub\myados\unicefData\stata\validation\test_fallback_sequences.do"

* From batch/script context
stata-mp -b do "C:\GitHub\myados\unicefData\stata\validation\test_fallback_sequences.do"
```

**Output**:
- Log file: `unicefData_fallback_validation.log`
- Exit code: 0 (PASS) or 1 (FAIL)
- Test report: Formatted Stata output with validation checklist

**Key Tests**:
1. yaml.ado availability check
2. Canonical YAML file existence
3. YAML loading execution
4. All 20 prefix validation
5. Summary report with pass/fail status

---

## Testing Matrix

### Expected Validation Results

| Platform | Prefixes | Load Method | Status | Notes |
|----------|----------|-------------|--------|-------|
| **Python** | 20 | YAML → defaults | ✓ Pass | Uses `_load_fallback_sequences()` |
| **R** | 20 | YAML → defaults | ✓ Pass | Uses `.load_fallback_sequences_yaml()` |
| **Stata** | 20 | Hardcoded sync | ✓ Pass | v1.6.1 expanded to 20 prefixes |
| **Consistency** | 20 | All match canonical | ✓ Pass | All return identical sequences |

### 20 Indicator Prefixes Covered

```
CME      - Comprehensive Monitoring & Evaluation
ED       - Education
PT       - Prevention & Treatment
COD      - Cause of Death
WS       - Water & Sanitation
IM       - Immunization
TRGT     - Targets
SPP      - Social Protection & Programs
MNCH     - Maternal, Newborn & Child Health
NT       - Nutrition
ECD      - Early Childhood Development
HVA      - HIV/AIDS
PV       - Poverty
DM       - Disability & Mental Health
MG       - Migration & Gender
GN       - Gender
FD       - Financial Data
ECO      - Economic
COVID    - COVID-19
WT       - Water
```

---

## Phase 2 Timeline & Milestones

### Week 1: Test Execution

**Day 1-2**: Python & R Validation
- [ ] Run Python test script with seed=42
- [ ] Run Python test script with seed=123 (alternate)
- [ ] Run R test script with seed=42
- [ ] Verify YAML loading on both platforms
- [ ] Document any discrepancies

**Day 2-3**: Stata Validation
- [ ] Run Stata do-file test script
- [ ] Verify 20 prefixes load correctly
- [ ] Test yaml.ado integration (if available)
- [ ] Capture test log with detailed output

**Day 3-4**: Cross-Platform Comparison
- [ ] Run unified validation script
- [ ] Compare results across all three platforms
- [ ] Validate consistency (all 20 prefixes match)
- [ ] Generate consolidated test report

### Week 2: Issue Resolution & Iteration

**Day 5-6**: Troubleshooting
- [ ] Analyze any test failures
- [ ] Fix platform-specific issues
- [ ] Re-run tests to confirm fixes
- [ ] Document lessons learned

**Day 7**: Finalization
- [ ] Approve all tests passing
- [ ] Generate final validation report
- [ ] Prepare Phase 3 (Git workflow) input

---

## Running the Tests

### Quick Start (Python)

```bash
cd C:\GitHub\myados\unicefData\validation

# Run comprehensive validation
python test_unified_fallback_validation.py --verbose

# Expected output:
# ======================================================================
# Unified Fallback Architecture Validation (v1.6.1)
# ======================================================================
# Seed: 42
# Testing languages: python, r, stata
#
# Testing Python implementation...
#   ✓ Python loaded 20 prefixes
# Testing R implementation...
#   ✓ R loaded 20 prefixes
# Testing Stata implementation...
#   ✓ Stata fallback sequences verified
#
# ======================================================================
# VALIDATION SUMMARY
# ======================================================================
# 
# ✓ PYTHON  - success    (20 prefixes)
# ✓ R       - success    (20 prefixes)
# ✓ STATA   - success    (20 prefixes)
# 
# ✓ Consistency Check: PASS
#   All platforms return identical sequences! ✓
#
# ======================================================================
```

### Quick Start (Stata)

```stata
* From Stata
do "C:\GitHub\myados\unicefData\stata\validation\test_fallback_sequences.do"

* Expected output in log file:
* ======================================================================
* UNIFIED FALLBACK ARCHITECTURE VALIDATION (v1.6.1)
* ======================================================================
* Test 1: Checking yaml.ado availability...
*   ✓ yaml.ado is available
* Test 2: Checking canonical YAML file...
*   ✓ Canonical YAML exists
* Test 3: Loading fallback sequences from YAML...
*   ✓ YAML loading successful
* Test 4: Verifying hardcoded fallback sequences (20 prefixes)...
*   Expected prefixes: 20
*   ✓ CME: Sequences loaded
*   ✓ ED: Sequences loaded
*   ... (all 20 prefixes)
* ======================================================================
* VALIDATION SUMMARY
* ======================================================================
* Platform: Stata
* Version: 1.6.1
* ✓ Total prefixes tested: 20
* ✓ Successful loads: 20/20
* ✓ All prefixes validated successfully!
* ======================================================================
* Final Status: PASS
* ======================================================================
```

---

## Test Coverage & Assertions

### Python Tests
- [ ] FALLBACK_SEQUENCES dict exists
- [ ] 20 prefixes present in dict
- [ ] Each prefix maps to list of dataflows
- [ ] First element is primary dataflow
- [ ] Fallback chain has ≥1 alternatives
- [ ] YAML loading works with graceful fallback

### R Tests
- [ ] .FALLBACK_SEQUENCES_YAML environment variable set
- [ ] 20 prefixes in R environment
- [ ] Each prefix maps to vector of dataflows
- [ ] Consistent naming (underscores, case)
- [ ] %||% operator works for null defaults

### Stata Tests
- [ ] 20 prefixes defined in _unicef_fetch_with_fallback.ado
- [ ] Each prefix has fallback sequence
- [ ] v1.6.1 version header present
- [ ] Optional: yaml.ado integration functional
- [ ] Hardcoded defaults all match canonical YAML

### Consistency Tests
- [ ] Python == R (all 20 prefixes)
- [ ] Python == Stata (all 20 prefixes)
- [ ] R == Stata (all 20 prefixes)
- [ ] All match canonical YAML exactly
- [ ] Order of fallback sequences identical

---

## Failure Handling

### If Python Test Fails
1. Check Python YAML parsing: `python -c "import yaml; yaml.safe_load(open('metadata/current/_dataflow_fallback_sequences.yaml'))"`
2. Verify `_load_fallback_sequences()` exists in `unicef_api/core.py` line ~200
3. Check if YAML file is corrupted or missing
4. Verify Python path includes `C:\GitHub\myados\unicefData\python`

### If R Test Fails
1. Check R YAML package: `install.packages('yaml')`
2. Verify `.load_fallback_sequences_yaml()` exists in `unicef_core.R` line ~35
3. Check if YAML parsing works: `yaml::read_yaml("metadata/current/_dataflow_fallback_sequences.yaml")`
4. Verify R working directory is `C:\GitHub\myados\unicefData\R`

### If Stata Test Fails
1. Check if yaml.ado is installed: `which yaml` in Stata
2. Install yaml: `net install yaml, from("C:\GitHub\yaml\src")`
3. Verify `_unicef_fetch_with_fallback.ado` has 20 prefixes
4. Check adoption path includes `C:\GitHub\myados\unicefData\stata\src`
5. Run `do "C:\GitHub\myados\unicefData\stata\validation\test_fallback_sequences.do"` with `set trace on`

### If Consistency Check Fails
1. Compare results across platform pairs
2. Check for typos in fallback sequences (e.g., GLOBAL_DATAFLOW vs GLOBALFLOW)
3. Verify canonical YAML matches all platform copies exactly
4. Regenerate platform copies if needed: `copy metadata/current/* */metadata/current/`

---

## Success Criteria

**PHASE 2 PASS** requires ALL of the following:

1. ✅ Python test passes with 20 prefixes
2. ✅ R test passes with 20 prefixes
3. ✅ Stata test passes with 20 prefixes
4. ✅ All 20 prefixes match exactly across platforms
5. ✅ Consistency check: PASS
6. ✅ No errors in test logs
7. ✅ YAML files verified identical on all platforms
8. ✅ Backward compatibility confirmed (fallback defaults work)

**Exit Criteria**: All success criteria met AND approved by team lead

---

## Deliverables

### Test Reports

1. **Validation Results JSON**
   - File: `results/unified_fallback_validation_{seed}.json`
   - Content: Full test details, platform results, consistency matrix

2. **Stata Test Log**
   - File: `unicefData_fallback_validation.log`
   - Content: Line-by-line Stata validation output

3. **Phase 2 Status Report**
   - File: `PHASE_2_VALIDATION_REPORT.md` (new)
   - Content: Test execution summary, results, recommendations

### Git Commits (Phase 3)

Validation results feed into Phase 3 commits:
- Commit 1: Canonical YAML + platform copies (already done Phase 1)
- Commit 2: Python YAML loading (already done Phase 1)
- Commit 3: R YAML loading (already done Phase 1)
- Commit 4: Stata fallback expansion (already done Phase 1)
- **Commit 5: Cross-platform validation tests** (Phase 2 output) ← NEW
- **Commit 6: Documentation & release notes** (Phase 2/3 output) ← NEW

---

## Next Steps After Phase 2

Upon successful validation:

1. **Phase 3 - Git Workflow**: Create feature branch and pull request
   - Branch: `feature/unified-dataflow-fallback-v1.6.1`
   - Commits: 6 commits per COMMIT_MESSAGES_TEMPLATE.md
   - PR: Link to IMPLEMENTATION_SUMMARY_V1.6.1.md

2. **Code Review**: Team review of changes
   - Review Python YAML loading
   - Review R YAML loading
   - Review Stata expansion to 20 prefixes
   - Approve validation test suite

3. **Merge & Release**: After approval
   - Merge to develop branch
   - Create v1.6.1 release tag
   - Update package documentation
   - Publish to package managers (SSC, CRAN, PyPI)

---

## Resources

**Canonical YAML Location**:
- Source: `C:\GitHub\myados\unicefData\metadata\current\_dataflow_fallback_sequences.yaml`
- Python: `C:\GitHub\myados\unicefData\python\metadata\current\_dataflow_fallback_sequences.yaml`
- R: `C:\GitHub\myados\unicefData\R\metadata\current\_dataflow_fallback_sequences.yaml`
- Stata: `C:\GitHub\myados\unicefData\stata\metadata\current\_dataflow_fallback_sequences.yaml`

**Implementation References**:
- Python: `C:\GitHub\myados\unicefData\python\unicef_api\core.py` (lines 245+)
- R: `C:\GitHub\myados\unicefData\R\unicef_core.R` (lines 35+)
- Stata: `C:\GitHub\myados\unicefData\stata\src\_\_unicef_fetch_with_fallback.ado` (lines 35-110)

**Helper Programs** (Stata):
- `_unicef_load_fallback_sequences.ado` - Loads YAML using yaml.ado
- `_get_hardcoded_fallbacks` - Returns hardcoded sequences
- `_unicef_fetch_with_fallback.ado` - Main fallback logic (now 20 prefixes)

---

## Contact & Questions

- **Implementation Lead**: João Pedro Azevedo (jpazevedo@unicef.org)
- **Tech Questions**: See IMPLEMENTATION_SUMMARY_V1.6.1.md (Section 5: Troubleshooting)
- **Test Issues**: Run tests with `--verbose` flag and attach results JSON

---

*Created January 12, 2026 | Phase 2 of 4 (Validation Testing)*

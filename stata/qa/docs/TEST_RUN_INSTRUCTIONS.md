# Instructions for Running unicefdata Tests with SYNC

**Date**: 2026-01-24
**Status**: SYNC tests added, ready for manual execution

---

## What Was Done

### 1. ✅ SYNC Tests Added

Three new metadata synchronization tests were added to [run_tests.do](run_tests.do):

- **SYNC-01**: Sync dataflow index to YAML
- **SYNC-02**: Sync indicator metadata with enrichment
- **SYNC-03**: Full metadata sync (all YAML files)

**Location**: Lines 2254-2523 (CATEGORY 3: METADATA SYNC)

**Backup**: `run_tests.do.bak` contains the previous version

### 2. ✅ Helper Scripts Created

- `regenerate_yaml.do` - Regenerate all YAML metadata files using Stata
- `regenerate_yaml.bat` - Windows batch launcher for YAML regeneration
- `run_tests_with_sync.do` - Run full test suite with SYNC enabled

### 3. ✅ Documentation Created

- `SYNC_TESTS_ADDED.md` - Comprehensive SYNC test documentation
- `TEST_RUN_INSTRUCTIONS.md` - This file (execution instructions)
- `UNICEFDATA_SYNC_REVIEW.md` (in stata/) - Full sync workflow review
- `TEST_PLAN_unicefdata_sync.md` (in stata/) - Sync test plan

---

## How to Run Tests

### Option A: Run All Tests (Recommended)

**Steps**:

1. Open Stata (preferably StataMP-64)

2. Change to the QA directory:
   ```stata
   cd "C:\GitHub\myados\unicefData-dev\stata\qa"
   ```

3. Run the full test suite:
   ```stata
   do run_tests.do
   ```

**Expected Result**:
- 34 tests run (SYNC tests disabled by default)
- All tests should pass
- Duration: ~45-60 seconds
- Log: `run_tests.log`

### Option B: Run Tests WITH SYNC (Full Validation)

**Steps**:

1. Open Stata

2. Change to the QA directory:
   ```stata
   cd "C:\GitHub\myados\unicefData-dev\stata\qa"
   ```

3. Run tests with SYNC enabled:
   ```stata
   do run_tests_with_sync.do
   ```

**Expected Result**:
- **37 tests** run (34 existing + 3 SYNC tests)
- All tests should pass
- Duration: ~2-5 minutes (SYNC tests download from API)
- Log: `run_tests.log`

### Option C: Run Individual SYNC Tests

**Test dataflow index sync only**:
```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
do run_tests.do SYNC-01
```

**Test indicator metadata sync only**:
```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
do run_tests.do SYNC-02
```

**Test full metadata sync**:
```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
do run_tests.do SYNC-03
```

### Option D: Regenerate YAML Files Only

**To regenerate all YAML metadata files without running tests**:

**Method 1 - Using Stata**:
```stata
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
do regenerate_yaml.do
```

**Method 2 - Using Batch File** (Windows):
```batch
cd C:\GitHub\myados\unicefData-dev\stata\qa
regenerate_yaml.bat
```

**Method 3 - Direct Command**:
```stata
cd "C:\GitHub\myados\unicefData-dev\stata"
unicefdata_sync, all verbose
```

---

## What to Expect

### Normal Test Run (WITHOUT SYNC)

```
================================================================================
                 unicefdata AUTOMATED TEST SUITE
================================================================================
  Test Suite:   1.5.2
  Ado Version:  1.12.5
  Date:         24jan2026 15:30:00
  Stata:        17
  OS:           Windows
================================================================================

Running 34 tests...

CATEGORY 0: ENVIRONMENT CHECKS
✓ PASS: ENV-01 Version 1.12.5 found
✓ PASS: ENV-02 Ado files synchronized
✓ PASS: ENV-03 Package structure valid
✓ PASS: ENV-04 All files exist

CATEGORY 1: BASIC DOWNLOADS
✓ PASS: DL-01 Single indicator download
✓ PASS: DL-02 Multiple countries download
...

CATEGORY 3: METADATA SYNC
○ SKIP: SYNC-01 (sync tests disabled by default)
○ SKIP: SYNC-02 (sync tests disabled by default)
○ SKIP: SYNC-03 (sync tests disabled by default)

...

================================================================================
TEST SUMMARY
================================================================================
  Tests run:    34
  Passed:       34
  Failed:       0
  Skipped:      3
  Duration:     0m 45s
  Result:       ALL TESTS PASSED
================================================================================
```

### Test Run WITH SYNC

```
================================================================================
                 unicefdata AUTOMATED TEST SUITE
================================================================================

Running 37 tests...

CATEGORY 3: METADATA SYNC
================================================================================
TEST SYNC-01: Sync dataflow index to YAML
================================================================================

Running unicefdata_sync...
  Auto-detected metadata directory: C:/GitHub/myados/unicefData-dev/stata/src/_/
  Syncing dataflow schemas...
    Using Python schema sync (stata_schema_sync.py)
    Fetching dataflow list...
    Found 70 dataflows
    Processing dataflows: CME, GLOBAL_DATAFLOW, ...
    Success: Synced 70 dataflow schemas
    ✓ Wrote _dataflow_index.yaml

✓ PASS: SYNC-01 Dataflow index synced successfully

================================================================================
TEST SYNC-02: Sync indicator metadata with enrichment
================================================================================

Running unicefdata_sync with force...
  Syncing full indicator metadata...
    URL: https://sdmx.data.unicef.org/.../CL_UNICEF_INDICATOR
    Using Python parser for enrichment...
    Parsing 733 indicators from XML...
    Enriching with dataflow mappings...
    Classifying tiers...
      Tier 1: 480 indicators
      Tier 3: 253 indicators
    ✓ Synced 733 indicators

✓ PASS: SYNC-02 Indicator metadata with enrichment synced

================================================================================
TEST SYNC-03: Full metadata sync (all YAML files)
================================================================================

Running unicefdata_sync with 'all' option...
  Syncing dataflows... ✓ 70 synced
  Syncing codelists... ✓ 5 synced
  Syncing countries... ✓ 249 synced
  Syncing regions... ✓ 52 synced
  Syncing indicators... ✓ 733 synced
  Creating vintage snapshot... ✓ Done
  Updating sync history... ✓ Done

✓ PASS: SYNC-03 All metadata files synced successfully

...

================================================================================
TEST SUMMARY
================================================================================
  Tests run:    37
  Passed:       37
  Failed:       0
  Skipped:      0
  Duration:     2m 15s
  Result:       ALL TESTS PASSED
================================================================================
```

---

## Troubleshooting

### Issue: "unicefdata not found"

**Solution**: Install unicefdata from repository
```stata
net install unicefdata, from("C:\GitHub\myados\unicefData-dev\stata") replace
```

### Issue: "SYNC tests not running"

**Check**: SYNC tests are disabled by default

**Solution 1**: Use `run_tests_with_sync.do`
```stata
do run_tests_with_sync.do
```

**Solution 2**: Enable manually
```stata
global run_sync = 1
do run_tests.do
```

### Issue: "Python parser not found"

**Symptoms**: SYNC tests fail with "Python script not found"

**Check**: Python availability
```bash
python --version
```

**Solution**: Ensure Python 3.6+ is installed and in PATH

**Fallback**: Use Stata parser (limited to ~730 indicators)
```stata
unicefdata_sync, all forcestata verbose
```

### Issue: "API connection failed"

**Symptoms**: "Failed to download from API"

**Check**: Network connectivity
```bash
curl https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF
```

**Solution**:
- Check firewall settings
- Verify internet connection
- Try again later (API may be temporarily unavailable)

### Issue: "File already exists" or "Permission denied"

**Solution**: Close any programs with YAML files open
```stata
cap file close _all
```

---

## Analyzing Test Results

### Check Test Log

After running tests, review the log file:

**Location**: `C:\GitHub\myados\unicefData-dev\stata\qa\run_tests.log`

**Key sections**:
- Test summary (end of file)
- Failed test details (if any)
- SYNC test verbose output

### Check Test History

Review all past test runs:

**Location**: `C:\GitHub\myados\unicefData-dev\stata\qa\test_history.txt`

**Format**:
```
======================================================================
Test Run: 24 Jan 2026
Started:  15:30:00
Ended:    15:32:15
Duration: 2m 15s
Version:  1.12.5
Stata:    17
Tests:    37 run, 37 passed, 0 failed
Result:   ALL TESTS PASSED
Log:      run_tests.log
======================================================================
```

### Verify YAML Files Were Regenerated

Check file timestamps:

**Windows**:
```batch
dir /O-D C:\GitHub\myados\unicefData-dev\stata\src\_\*.yaml
```

**Stata**:
```stata
! dir /O-D "C:\GitHub\myados\unicefData-dev\stata\src\_\*.yaml"
```

**Expected**: Files should have today's timestamp (2026-01-24)

---

## Next Steps After Testing

### If All Tests Pass ✅

1. **Review metadata files**:
   ```stata
   type "C:\GitHub\myados\unicefData-dev\stata\src\_\_unicefdata_dataflows.yaml" in 1/20
   ```

2. **Check for Stata watermark**:
   - Open `_unicefdata_dataflows.yaml`
   - Verify line 2: `platform: Stata`
   - Verify line 4: `synced_at: '2026-01-24T...'`

3. **Commit changes** (if approved):
   ```stata
   ! cd C:\GitHub\myados\unicefData-dev && git status
   ```

4. **Update test history**:
   - Results are automatically appended to `test_history.txt`

### If Tests Fail ❌

1. **Identify failing test**:
   - Check `run_tests.log` for first failure
   - Review error message and return code

2. **Run failing test individually**:
   ```stata
   do run_tests.do SYNC-01 verbose
   ```

3. **Debug with trace**:
   ```stata
   set trace on
   set tracedepth 4
   do run_tests.do SYNC-01
   ```

4. **Check related documentation**:
   - `SYNC_TESTS_ADDED.md` - Debugging checklist
   - `UNICEFDATA_SYNC_REVIEW.md` - Sync workflow details

---

## Test Coverage Summary

### Total Tests: 37

**CATEGORY 0: Environment** (4 tests)
- ENV-01: unicefdata version check
- ENV-02: Ado files sync status
- ENV-03: Package structure validation
- ENV-04: All pkg files exist

**CATEGORY 1: Basic Downloads** (9 tests)
- DL-01 to DL-09: Download functionality tests

**CATEGORY 1B: Data Integrity** (1 test)
- DATA-01: Data type validation

**CATEGORY 2: Discovery** (5 tests)
- DISC-01 to DISC-05: Discovery commands

**CATEGORY 2B: Tier Filtering** (3 tests)
- TIER-01 to TIER-03: Tier classification

**CATEGORY 3: Metadata Sync** (3 tests) ← **NEW**
- **SYNC-01: Dataflow index sync**
- **SYNC-02: Indicator metadata sync**
- **SYNC-03: Full metadata sync**

**CATEGORY 4: Transformations** (6 tests)
- TRANS, META, MULTI, FMT tests

**CATEGORY 5: Robustness** (3 tests)
- EDGE, PERF, REGR tests

**CATEGORY 6: Cross-Platform** (5 tests)
- XPLAT-01 to XPLAT-05: Consistency checks

**YAML Integration** (2 tests)
- YAML-01, YAML-02: YAML processing

---

## Files Reference

### Test Scripts
- [run_tests.do](run_tests.do) - Main test suite (37 tests)
- [run_tests_with_sync.do](run_tests_with_sync.do) - Helper to enable SYNC
- [regenerate_yaml.do](regenerate_yaml.do) - YAML regeneration script

### Documentation
- [SYNC_TESTS_ADDED.md](SYNC_TESTS_ADDED.md) - SYNC test documentation
- [TEST_RUN_INSTRUCTIONS.md](TEST_RUN_INSTRUCTIONS.md) - This file
- [../UNICEFDATA_SYNC_REVIEW.md](../UNICEFDATA_SYNC_REVIEW.md) - Sync workflow review
- [../TEST_PLAN_unicefdata_sync.md](../TEST_PLAN_unicefdata_sync.md) - Sync test plan

### Logs
- [run_tests.log](run_tests.log) - Latest test run log
- [test_history.txt](test_history.txt) - All test run history

### Code Being Tested
- [../src/u/unicefdata_sync.ado](../src/u/unicefdata_sync.ado) - Main sync program
- [../src/py/enrich_stata_metadata_complete.py](../src/py/enrich_stata_metadata_complete.py) - Enrichment script
- [../src/py/stata_schema_sync.py](../src/py/stata_schema_sync.py) - Dataflow schema sync

---

**Instructions Created**: 2026-01-24
**Status**: Ready for execution
**Recommended**: Run `do run_tests_with_sync.do` in Stata to execute all 37 tests including SYNC

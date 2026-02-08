# SYNC Tests Added to Test Suite

**Date**: 2026-01-24
**Purpose**: Add metadata synchronization tests to unicefdata test suite
**Location**: `stata/qa/run_tests.do`

---

## Summary

Added CATEGORY 3: METADATA SYNC tests to fill the gap between TIER tests (Category 2B) and TRANSFORMATIONS (Category 4).

### Tests Added

#### SYNC-01: Sync dataflow index
- **Purpose**: Test dataflow schema synchronization
- **Output**: `_dataflow_index.yaml` + individual schema files in `__dataflows/`
- **Validates**:
  - API connectivity to UNICEF SDMX dataflow endpoint
  - XML parsing of Data Structure Definitions (DSD)
  - YAML file generation with proper formatting
  - Schema file creation in subdirectory

**Code tested**: `_unicefdata_sync_dataflow_index` subroutine ([unicefdata_sync.ado:1284-1586](../src/u/unicefdata_sync.ado))

#### SYNC-02: Sync indicator metadata
- **Purpose**: Test full indicator metadata sync with enrichment
- **Output**: `_unicefdata_indicators_metadata.yaml` (enriched)
- **Validates**:
  - CL_UNICEF_INDICATOR codelist download
  - Dataflow mapping enrichment
  - Tier classification (1-4 based on availability)
  - Disaggregation dimension extraction
  - YAML metadata watermark

**Code tested**: `_unicefdata_sync_ind_meta` subroutine ([unicefdata_sync.ado:1730-1879](../src/u/unicefdata_sync.ado))

**Related**: Uses [enrich_stata_metadata_complete.py](../src/py/enrich_stata_metadata_complete.py) for enrichment

#### SYNC-03: Full metadata sync
- **Purpose**: Test complete metadata synchronization (all files)
- **Output**: All 7+ YAML files
  - `_unicefdata_dataflows.yaml`
  - `_unicefdata_indicators.yaml`
  - `_unicefdata_codelists.yaml`
  - `_unicefdata_countries.yaml`
  - `_unicefdata_regions.yaml`
  - `_unicefdata_sync_history.yaml`
  - `_unicefdata_indicators_metadata.yaml` (optional enriched version)
- **Validates**:
  - All sync subroutines execute without error
  - All expected files are generated
  - Vintage snapshot creation
  - Sync history update
  - Proper Stata platform watermark in files

**Code tested**: Main `unicefdata_sync` program with 'all' option ([unicefdata_sync.ado:70-680](../src/u/unicefdata_sync.ado))

---

## Implementation Details

### File Modified
- **Location**: [stata/qa/run_tests.do](run_tests.do)
- **Insertion point**: After TIER-03 test (line 2252), before CATEGORY 4 (line 2254)
- **Backup created**: `run_tests.do.bak`

### Test Execution Control

SYNC tests are **disabled by default** to avoid modifying metadata files during routine testing.

**Enable SYNC tests**:
```stata
* In run_tests.do (line 185)
global run_sync = 1  // Change from 0 to 1
```

**Or run individually**:
```stata
do run_tests.do SYNC-01
do run_tests.do SYNC-02
do run_tests.do SYNC-03
```

**Or run all with SYNC**:
```stata
do run_tests_with_sync.do  // Helper script created
```

---

## Test Design Philosophy

### Why SYNC Tests Were Disabled by Default

```stata
global run_sync = 0  // Skip sync tests by default (may modify files)
```

**Rationale**:
1. **File modification**: SYNC tests regenerate YAML files, changing timestamps
2. **API dependency**: Require network access to UNICEF SDMX API
3. **Execution time**: Sync operations take longer than other tests
4. **Development workflow**: Most developers don't need to resync metadata

**When to run SYNC tests**:
- After modifying `unicefdata_sync.ado` or sync subroutines
- After updating Python enrichment scripts
- When UNICEF releases new indicators or dataflows
- During release testing (CI/CD should enable)
- When troubleshooting metadata consistency issues

### Test Validation Strategy

Each SYNC test follows this pattern:

1. **Pre-execution**: Determine metadata directory path
2. **Execute**: Run `unicefdata_sync` with appropriate options
3. **Verify existence**: Confirm output files were created
4. **Verify structure**: Check YAML files contain expected keys
5. **Verify watermark**: Ensure files have Stata platform identifier
6. **Report**: Pass/fail with informative messages

**Example validation** (SYNC-01):
```stata
* Verify index file exists
local index_file "`metadir'/_dataflow_index.yaml"
cap confirm file "`index_file'"

* Verify structure
file open `fh' using "`index_file'", read text
* Look for: metadata_version:, dataflows:
* Check count of dataflows (expect ~70)

* Report
test_pass, id("SYNC-01") msg("Dataflow index synced successfully")
```

---

## Related Test Categories

### Tests That Depend on SYNC Outputs

| Test ID | Dependency | File Required |
|---------|-----------|---------------|
| TIER-01, TIER-02 | Tier classification | `_unicefdata_indicators_metadata.yaml` |
| META-02 | Metadata sanity | `_unicefdata_dataflows.yaml` |
| XPLAT-01 | Cross-platform | All metadata YAML files |
| DISC-02 | List dataflows | `_unicefdata_dataflows.yaml` |
| DISC-03 | Search indicators | `_unicefdata_indicators.yaml` |

### CI/CD Integration

**GitHub Actions Workflow**: [.github/workflows/metadata-sync.yml](../../.github/workflows/metadata-sync.yml)

**Current workflow** (runs weekly):
```yaml
- python build_dataflow_metadata.py --outdir ../_/ --verbose
- python enrich_indicators_metadata.py --verbose
```

**Recommendation**: Add Stata sync verification
```yaml
- name: Verify Stata YAML generation
  run: |
    cd stata/qa
    stata-mp /e do run_tests.do SYNC-03
    # Check exit code and log for failures
```

---

## Debugging SYNC Test Failures

### SYNC-01 Failures

**Symptoms**: Index file not created or has invalid structure

**Checklist**:
1. **API connectivity**: Test endpoint accessibility
   ```bash
   curl https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF
   ```

2. **Python availability**: Check for Python 3.6+
   ```bash
   python --version
   python -c "import xml.etree.ElementTree"
   ```

3. **Permissions**: Verify write access to `stata/src/_/`
   ```stata
   cap mkdir "`metadir'/test_write"
   if _rc != 0 {
       di as err "No write permission in metadata directory"
   }
   ```

4. **Verbose output**: Re-run with verbose option
   ```stata
   unicefdata_sync, path("`metadir'") verbose
   ```

### SYNC-02 Failures

**Symptoms**: Metadata file created but lacks enrichment fields

**Checklist**:
1. **30-day cache**: File may be cached (use `force` option)
   ```stata
   unicefdata_sync, path("`metadir'") force
   ```

2. **Dataflow mapping**: Verify prerequisite file exists
   ```stata
   cap confirm file "`metadir'/_indicator_dataflow_map.yaml"
   ```

3. **Python enrichment script**: Check script location
   ```stata
   cap confirm file "stata/src/py/enrich_stata_metadata_complete.py"
   ```

4. **Enrichment execution**: Check for Python errors in log

### SYNC-03 Failures

**Symptoms**: Some but not all files created

**Checklist**:
1. **Partial sync**: Identify which file failed
   - Check test output for `Missing files:` list
   - Re-run individual sync for missing file

2. **API rate limiting**: UNICEF may throttle requests
   - Wait 5 minutes and retry
   - Check for 429 HTTP status codes in verbose output

3. **Disk space**: Verify sufficient space (~5MB needed)
   ```bash
   df -h stata/src/_
   ```

4. **File locks**: Another process may have files open
   ```stata
   cap file close _all
   ```

---

## Test Output Example

**Expected SYNC-03 output** (all passing):

```
================================================================================
TEST SYNC-03: Full metadata sync (all YAML files)
================================================================================

Running unicefdata_sync with 'all' option...

Syncing UNICEF metadata...
  Auto-detected metadata directory: C:/GitHub/myados/unicefData-dev/stata/src/_/

  Syncing dataflows...
    ✓ Synced 70 dataflows

  Syncing codelists...
    ✓ Synced 5 codelists

  Syncing countries...
    ✓ Synced 249 countries

  Syncing regions...
    ✓ Synced 52 regions

  Syncing indicators...
    ✓ Synced 733 indicators

  Creating vintage snapshot...
    ✓ Copied 5 files to vintages/20260124/

  Updating sync history...
    ✓ Updated _unicefdata_sync_history.yaml

✓ PASS: SYNC-03 All metadata files synced successfully
```

---

## Files Created/Modified

### Modified
- [x] `stata/qa/run_tests.do` - Added CATEGORY 3: METADATA SYNC (3 tests)
- [x] Backup created: `stata/qa/run_tests.do.bak`

### Created
- [x] `stata/qa/add_sync_tests.txt` - SYNC test code (for reference)
- [x] `stata/qa/run_tests_with_sync.do` - Helper script to run tests with SYNC enabled
- [x] `stata/qa/regenerate_yaml.do` - Script to regenerate YAML files
- [x] `stata/qa/regenerate_yaml.bat` - Windows batch file for YAML regeneration
- [x] `stata/qa/SYNC_TESTS_ADDED.md` - This documentation

---

## Next Steps

1. **Verify test execution**: Check `run_tests.log` for SYNC test results
2. **Update CI/CD**: Add SYNC tests to GitHub Actions workflow
3. **Document in README**: Update test suite documentation
4. **Add to release checklist**: Run SYNC tests before each release

---

## Test Count Update

**Before**: 34 tests
**After**: 37 tests

**New total breakdown**:
- CATEGORY 0 (ENV): 4 tests
- CATEGORY 1 (DL): 9 tests
- CATEGORY 1B (DATA): 1 test
- CATEGORY 2 (DISC): 5 tests
- CATEGORY 2B (TIER): 3 tests
- **CATEGORY 3 (SYNC): 3 tests** ← NEW
- CATEGORY 4 (TRANS/META/MULTI/FMT): 6 tests
- CATEGORY 5 (EDGE/PERF/REGR): 3 tests
- CATEGORY 6 (XPLAT): 5 tests
- YAML: 2 tests

**Priority Distribution**:
- P0 (Critical): 14 tests
- P1 (Important): 12 tests
- P2 (Robustness): 8 tests
- P3 (Infrastructure): 3 tests (SYNC tests)

---

**Document Created**: 2026-01-24
**Author**: Claude Sonnet 4.5
**Status**: SYNC tests added and ready for testing
**Test run**: In progress (see run_tests.log for results)

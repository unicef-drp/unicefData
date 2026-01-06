# unicefdata Testing Guide & Protocol

**Version**: 1.5.1  
**Last Updated**: January 6, 2026  
**Status**: Active  
**Current Pass Rate**: 83.3% (15/18 tests)

[← Back to README](../README.md)

---

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Quick Start](#quick-start)
3. [Test Suite Overview](#test-suite-overview)
4. [Running Tests](#running-tests)
5. [Test Categories & Details](#test-categories--details)
6. [Best Practices](#best-practices)
7. [Known Issues & Workarounds](#known-issues--workarounds)
8. [Pre-Release Checklist](#pre-release-checklist)
9. [Test History](#test-history)
10. [Troubleshooting](#troubleshooting)

---

## Testing Philosophy

### The Two Paradigms: CRAN/PyPI vs. unicefdata

Software testing in the statistical ecosystem follows two fundamentally different paradigms:

| Aspect | CRAN / PyPI (Release Gates) | unicefdata (Operational Validation) |
|--------|----------------------------|-------------------------------------|
| **Primary Goal** | Certify software correctness | Validate real-world operations |
| **Network Access** | Prohibited | Required (UNICEF SDMX API) |
| **Environment** | Sandboxed, offline | Interactive, trusted |
| **Determinism** | Fully reproducible | Depends on live data |
| **Failure Meaning** | Software bug | Could be API outage, data change, or bug |

### Software Certification (CRAN/PyPI Approach)

Automated test suites for CRAN/PyPI releases are designed to **certify intrinsic software correctness and safety** independent of external conditions. These tests:

- **Are deterministic and fully reproducible** — same inputs always produce same outputs
- **Are isolated from the network** — no external API calls
- **Are platform-agnostic** — pass on Windows, macOS, Linux
- **Focus on public-API behavior** — output structure and enforced invariants

### Operational Validation (unicefdata Approach)

`unicefdata` adopts **integration-style tests** that deliberately exercise:

- **Live APIs** — actual UNICEF SDMX API calls
- **Real data downloads** — end-to-end verification
- **Environment configuration** — package versions, file sync status
- **Network behavior** — timeout handling, error recovery

**Example:**
```stata
* Actually downloads live data from UNICEF SDMX API
unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) clear
assert _N > 0  // Verify we got real data
```

### Why Live Tests for unicefdata

1. **Stata's Ecosystem Context**
   - No CRAN-equivalent automated submission system
   - Packages installed via `ssc install` or `net install` without pre-checks
   - Users run in trusted, interactive environments with network access

2. **Core Function IS Network-Dependent**
   - Primary purpose: fetch data from UNICEF SDMX API
   - Mocking the API would test the mock, not actual functionality
   - Live tests catch real issues: API changes, endpoint deprecations, format changes

3. **Failure Diagnosis**
   - Live tests help distinguish:
     - Package bugs (multiple unrelated tests fail)
     - API issues (download tests fail, discovery tests pass)
     - Network issues (all network tests fail, ENV tests pass)

---

## Quick Start

### Run All Tests

```stata
cd "C:/GitHub/myados/unicefData/stata/qa"
do run_tests.do
```

**Expected output**: Test summary showing pass/fail status for all 18 tests.  
**Expected result**: 15+ tests passing (83%+), failures logged in FAILING_TESTS_ACTION_PLAN.md.

### Run Specific Test

```stata
do run_tests.do DL-01     # Run DL-01 only
do run_tests.do XPLAT-05  # Run XPLAT-05 only
```

### Run with Verbose Output

```stata
do run_tests.do verbose
```

Enables `set trace on` for detailed execution trace.

### List Available Tests

```stata
do run_tests.do list
```

---

## Test Suite Overview

### Current Status

**Last Run**: January 6, 2026 15:22:45  
**Total Tests**: 18  
**Passed**: 15 (83.3%)  
**Failed**: 3 (documented)

### Test History Tracking

Each test run automatically appends to `test_history.txt`:

```
Test Run:  6 Jan 2026
Started:  15:22:44
Ended:    15:23:08
Duration: 0m 24s
Version:  1.5.1
Tests:    18 run, 15 passed, 3 failed
Failed:   DL-05, XPLAT-01, XPLAT-04
```

View test history:
```powershell
Get-Content "C:\GitHub\myados\unicefData\stata\qa\test_history.txt" | Select-Object -Last 20
```

---

## Running Tests

### Automated Testing (Recommended)

```stata
* From Stata:
cd "C:/GitHub/myados/unicefData/stata/qa"
do run_tests.do
```

### Batch Mode (PowerShell)

```powershell
# From PowerShell (Windows)
Push-Location "C:\GitHub\myados\unicefData\stata\qa"
& "C:\Program Files\Stata17\StataMP-64.exe" /e do "run_tests.do"
Pop-Location
```

### Test Execution Control

The following globals control which test categories run:

```stata
global run_env       = 1  // Environment checks (ENV-01, ENV-02)
global run_downloads = 1  // Download tests (DL-01 through DL-07)
global run_discovery = 1  // Discovery tests (DISC-01 through DISC-03)
global run_sync      = 0  // Sync tests (skip by default - modifies files)
global run_format    = 1  // Format tests (deprecated)
global run_yaml      = 1  // YAML tests (deprecated)
global run_xplat     = 1  // Cross-platform tests (XPLAT-01 through XPLAT-05)
```

Override for single test:

```stata
do run_tests.do DL-01    # Only DL-01 runs
do run_tests.do XPLAT-02 # Only XPLAT-02 runs
```

### Manual Sync Testing

Sync tests modify local YAML files and should be run manually:

```stata
* Test dataflow synchronization
unicefdata_sync, dataflows

* Test indicator metadata synchronization
unicefdata_sync, indicators

* Test full synchronization
unicefdata_sync, full
```

**Verify after sync**:
- YAML files updated in `C:\GitHub\myados\unicefData\stata\src\_\`
- No data loss from existing files
- Valid YAML syntax (`yaml.ado` can parse without errors)

---

## Test Categories & Details

### Category 0: ENV - Environment Checks

**Purpose**: Validate package installation and dependencies.

| Test ID | Description | Critical | Time |
|---------|-------------|----------|------|
| ENV-01 | Verify unicefdata.ado exists and version matches | Yes | < 1s |
| ENV-02 | Confirm yaml.ado dependency is installed | Yes | < 1s |

**Failure Handling**:
- If ENV-01 fails: Package not installed or version mismatch
  - Run: `which unicefdata` to locate ado file
  - Fix: Copy `unicefdata.ado` to `C:\Users\<user>\ado\plus\u\`

- If ENV-02 fails: yaml package missing
  - Fix: `ssc install yaml, replace`

---

### Category 1: DL - Basic Downloads

**Purpose**: Validate data downloads from UNICEF SDMX API.

| Test ID | Description | Critical | Time | Status |
|---------|-------------|----------|------|--------|
| DL-01 | Single indicator, multiple countries | P0 | 2-3s | ✓ PASS |
| DL-02 | Multiple countries filter | P0 | 1-2s | ✓ PASS |
| DL-03 | Year range expansion (e.g., 2010:2020) | P0 | 2-3s | ✓ PASS |
| DL-04 | Schema validation (required columns) | P0 | 1-2s | ✓ PASS |
| DL-05 | Disaggregation filters (sex, wealth) | P0 | 2-3s | ✗ FAIL* |
| DL-06 | Duplicate detection on key dimensions | P0 | 1-2s | ✓ PASS |
| DL-07 | Error handling (invalid indicators) | P0 | 8-9s | ✓ PASS |

**\* DL-05 Known Issue**: UNICEF SDMX API ignores wealth filter (server-side bug, not package bug).  
See: [FAILING_TESTS_ACTION_PLAN.md](FAILING_TESTS_ACTION_PLAN.md#test-1-dl-05---disaggregation-filters-p0---critical)

---

### Category 1B: DATA - Data Integrity (P0)

**Purpose**: Validate downloaded data types and structure.

| Test ID | Description | Critical | Time | Status |
|---------|-------------|----------|------|--------|
| DATA-01 | Numeric types (value float, period int) | P0 | 1-2s | ✓ PASS |

---

### Category 2: DISC - Discovery Commands

**Purpose**: Validate metadata and discovery functionality.

| Test ID | Description | Time | Status |
|---------|-------------|------|--------|
| DISC-01 | List dataflows from API | 1s | ✓ PASS |
| DISC-02 | Search indicators by keyword | 1-2s | ✓ PASS |
| DISC-03 | Display dataflow schema | < 1s | ✓ PASS |

---

### Category 6: XPLAT - Cross-Platform Consistency

**Purpose**: Verify Python/R/Stata packages have consistent behavior and metadata.

| Test ID | Description | Time | Status |
|---------|-------------|------|--------|
| XPLAT-01 | Metadata YAML file consistency | < 1s | ✗ FAIL* |
| XPLAT-02 | Variable naming convention (lowercase) | < 1s | ✓ PASS |
| XPLAT-03 | Numeric formatting consistency | 1-2s | ✓ PASS |
| XPLAT-04 | Country code consistency (ISO3) | < 1s | ✗ FAIL* |
| XPLAT-05 | Data structure alignment | 1-2s | ✓ PASS |

**\* XPLAT-01, XPLAT-04 Known Issue**: `yaml query` command with dot notation not working.  
See: [FAILING_TESTS_ACTION_PLAN.md](FAILING_TESTS_ACTION_PLAN.md#test-2-xplat-01---metadata-yaml-consistency)

---

## Best Practices

### 1. NO Empty Capture Blocks

```stata
* WRONG ❌
capture {
    // Empty block doesn't set _rc meaningfully
}

* CORRECT ✅
capture noisily unicefdata, indicator(CME_MRY0T4) clear
if _rc != 0 {
    di as err "Download failed with error code `=_rc'"
}
```

### 2. Check _rc Immediately

```stata
* CORRECT ✅
cap noi unicefdata, indicator(CME_MRY0T4) clear
local rc = _rc
if `rc' != 0 {
    test_fail, id("DL-01") rc(`rc')
}
```

### 3. Explicit Variable Checks

```stata
* WRONG ❌
assert !missing(countrycode)  // Fails if variable doesn't exist

* CORRECT ✅
cap confirm variable countrycode
if _rc == 0 {
    // Variable exists, proceed
}
else {
    test_fail, id("TEST-ID") msg("countrycode variable missing")
}
```

### 4. Use Compound Quotes for Display with Dynamic Content

```stata
* WRONG ❌
noi di "{p 4 4 4}Note: `note'"  // Breaks if note contains special chars

* CORRECT ✅
noi di `"{p 4 4 4}Note: `note'"'  // Preserves special chars and braces
```

### 5. Store _N Before Clearing

```stata
* Capture row count before clearing
local obs_count = _N
clear
di "Previous dataset had `obs_count' observations"
```

### 6. Test Data Sources

Use these indicators for reliable, consistent testing:

| Indicator | Name | Category | Countries | Years |
|-----------|------|----------|-----------|-------|
| CME_MRY0T4 | Under-5 mortality rate | Child Mortality | Most countries | 1990+ |
| NT_ANT_WHZ_NE2 | Wasting prevalence | Nutrition | Limited | Sparse |
| ED_CR_L2OR3_PPP | Learning poverty | Education | Growing | 2010+ |

**Recommended countries for testing**:
- USA (reliable data, all disaggregations)
- BRA (good coverage, consistent reporting)
- IND (populous, diverse data)
- BGD (Bangladesh - nutrition focus)

---

## Known Issues & Workarounds

### Issue 1: DL-05 - API Ignores Wealth Filter

**Symptom**: Requesting `wealth(Q1 Q5)` returns ALL quintiles (Q1-Q5, B20, B40, etc.)

**Root Cause**: UNICEF SDMX server bug, not a package bug.

**Evidence**:
- Sex filter WORKS: `sex(F)` returns only F observations
- Wealth filter BROKEN: Server ignores wealth_quintile dimension filter

**Impact**: Test DL-05 correctly identifies API limitation.

**Workaround for users**:
```stata
unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) clear
keep if inlist(wealth, "Q1", "Q5")  // Manual post-download filtering
```

**See also**: [FAILING_TESTS_ACTION_PLAN.md](FAILING_TESTS_ACTION_PLAN.md#test-1-dl-05---disaggregation-filters-p0---critical)

---

### Issue 2: XPLAT-01 & XPLAT-04 - YAML Query Syntax

**Symptom**: Tests fail with "Could not parse country counts" or "Countries not found".

**Root Cause**: `yaml query` command with dot notation may not work as expected.

```stata
* This doesn't work as expected:
yaml query _metadata.total_countries using "file.yaml", flatten
yaml query countries.USA using "file.yaml", flatten
```

**Current Status**: Investigating yaml.ado package capabilities.

**Workaround**: Simplify tests to file-based checks (size, line counts) without yaml parsing.

**See also**: [FAILING_TESTS_ACTION_PLAN.md](FAILING_TESTS_ACTION_PLAN.md#recommended-follow-up-actions) (Action 2)

---

### Issue 3: Network Proxy in Corporate Environments

**Symptom**: All download tests fail with timeout or connection errors.

**Root Cause**: Corporate firewall blocking direct access to UNICEF SDMX API.

**Workaround**: Configure Stata proxy settings:

```stata
set httpproxy on
set httpproxyhost proxy.yourcompany.com
set httpproxyport 8080
set httpproxyauth user:password  // If authentication required
```

Then run tests again.

---

### Issue 4: API Rate Limiting

**Symptom**: Tests fail intermittently with timeout (especially when running multiple times in succession).

**Root Cause**: UNICEF SDMX API may rate-limit rapid requests.

**Workaround**: Add delays between sequential test runs:

```powershell
# PowerShell: Wait 60 seconds between test runs
do { 
    & "C:\Program Files\Stata17\StataMP-64.exe" /e do "run_tests.do"
    Start-Sleep -Seconds 60
} while ($true)
```

---

### Issue 5: Non-ASCII Characters in YAML

**Symptom**: YAML parsing fails with encoding errors on indicator names containing accented characters.

**Root Cause**: yaml.ado may not handle UTF-8 encoding in YAML files.

**Workaround**: Use `filefilter` to sanitize YAML before parsing (future enhancement).

---

## Pre-Release Checklist

Before tagging a release, run through all phases:

### Phase 1: Environment Validation ✓

- [ ] **ENV-01**: Verify version number in `.ado` file matches release tag
- [ ] **ENV-02**: Confirm all dependencies installed (`yaml.ado`)

**Command**: `do run_tests.do ENV-01` and `do run_tests.do ENV-02`

### Phase 2: Core Functionality ✓

- [ ] **DL-01**: Single indicator (multiple countries) passes
- [ ] **DL-02**: Multiple countries filter works
- [ ] **DL-03**: Year range expansion (2010:2020) works
- [ ] **DL-04**: Schema validation (required columns) passes
- [ ] **DL-05**: Disaggregation filters documented as known issue
- [ ] **DL-06**: No duplicates detected
- [ ] **DL-07**: Error handling for invalid indicators

**Command**: `do run_tests.do`

### Phase 3: Discovery Features ✓

- [ ] **DISC-01**: `unicefdata, flows` lists 69+ dataflows
- [ ] **DISC-02**: `unicefdata, search(mortality)` returns 20+ results
- [ ] **DISC-03**: `unicefdata, dataflow(CME)` displays schema

**Command**: Individual tests DISC-01, DISC-02, DISC-03

### Phase 4: Data Integrity ✓

- [ ] **DATA-01**: Downloaded values are numeric (float/double)
- [ ] **DATA-01**: Periods are numeric integers

**Command**: `do run_tests.do DATA-01`

### Phase 5: Cross-Platform Consistency ✓

- [ ] **XPLAT-02**: Variable names follow lowercase convention
- [ ] **XPLAT-03**: Numeric formatting matches across platforms
- [ ] **XPLAT-05**: Data structure alignment (rows/columns)
- [ ] **XPLAT-01, XPLAT-04**: Known YAML query issues documented

**Command**: `do run_tests.do XPLAT-02`, `do run_tests.do XPLAT-03`, etc.

### Phase 6: Manual Verification

- [ ] Run manual sync tests (no automated version)
  ```stata
  unicefdata_sync, dataflows
  unicefdata_sync, indicators
  ```
- [ ] Verify YAML files updated without data loss
- [ ] Check performance benchmarks:
  - Single indicator (4 countries, 6 years): < 5 seconds
  - Discovery commands: < 2 seconds
  - Metadata sync: < 10 seconds per dataflow

### Phase 7: Documentation & Versioning

- [ ] Version updated in `unicefdata.ado` header
- [ ] CHANGELOG.md updated with new features/fixes
- [ ] README.md reflects current status
- [ ] test_history.txt shows all tests passing (except known issues)

### Phase 8: Release Sign-Off

**Name**: ___________________  
**Date**: ___________________  
**Version**: ___________________  
**Test Result**: [ ] PASS [ ] FAIL  
**Notes**: 
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Test History

### v1.5.1 (January 6, 2026)

- **Total Tests**: 18
- **Passing**: 15 (83.3%)
- **Failing**: 3 (documented and analyzed)
- **Added**: 5 new cross-platform consistency tests (XPLAT-01 through XPLAT-05)
- **Added**: Comprehensive test documentation (600+ lines)
- **Added**: FAILING_TESTS_ACTION_PLAN.md with root cause analysis
- **Added**: CROSS_PLATFORM_TESTING.md guide

**Key improvements**:
- Each test now has 100-200 line documentation header explaining purpose, criticality, failure scenarios, and debug steps
- Operational validation philosophy clearly documented
- Test history auto-maintained in test_history.txt

### v1.5.0 (December 2025)

- Initial comprehensive test suite (13 tests)
- Environment, download, and discovery tests
- Data integrity validation
- 12/13 tests passing

### Earlier versions

- Progressive development of test framework
- Initial setup with basic ENV checks

---

## Troubleshooting

### Test Fails: "unicefdata not found"

**Diagnosis**:
```stata
which unicefdata
```

**Solution**:
1. Install/copy unicefdata.ado to user ado path:
   ```stata
   cd "C:/GitHub/myados/unicefData/stata/src"
   copy unicefdata.ado "C:\Users\<username>\ado\plus\u\unicefdata.ado"
   ```

2. Discard Stata's file cache:
   ```stata
   discard
   ```

3. Retry test:
   ```stata
   do run_tests.do ENV-01
   ```

---

### Test Fails: "yaml not found"

**Diagnosis**:
```stata
which yaml
```

**Solution**:
1. Install yaml package:
   ```stata
   ssc install yaml, replace
   ```

2. Or copy from local repo:
   ```stata
   cd "C:/GitHub/yaml/src"
   copy yaml.ado "C:\Users\<username>\ado\plus\y\yaml.ado"
   ```

3. Discard cache and retry:
   ```stata
   discard
   do run_tests.do ENV-02
   ```

---

### Download Test Fails: "Could not download data"

**Possible causes**:

1. **Internet connectivity**
   - Test: Open https://sdmx.data.unicef.org in browser
   - If fails: Check internet connection, corporate proxy, firewall

2. **API server down**
   - Check: https://status.data.unicef.org (if available)
   - Workaround: Retry in 1-2 hours

3. **Invalid indicator code**
   - Test different indicator: `unicefdata, search(mortality)` to find valid codes
   - DL-07 test specifically handles invalid indicators

4. **Proxy/firewall blocking UNICEF API**
   - See: [Issue 3: Network Proxy](#issue-3-network-proxy-in-corporate-environments)

---

### Performance: Tests Take Too Long

**Typical duration**: 20-25 seconds total

**Breakdown**:
- ENV tests: < 1 second
- DL tests: 15-20 seconds (mostly API calls)
- DISC tests: 2-3 seconds
- XPLAT tests: < 2 seconds

**If taking > 60 seconds**:
- Check internet speed (test with DISC-01 first)
- Look for API rate limiting (wait before retrying)
- Check for other Stata processes competing for resources

---

### Test Log Not Generated

**Issue**: No log file created after running `do run_tests.do`

**Solution**:
1. Check current directory:
   ```stata
   pwd  // Should show C:/GitHub/myados/unicefData/stata/qa
   ```

2. Change to correct directory:
   ```stata
   cd "C:/GitHub/myados/unicefData/stata/qa"
   do run_tests.do
   ```

3. Check for log files:
   ```powershell
   Get-ChildItem "C:\GitHub\myados\unicefData\stata\qa\run_tests*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
   ```

---

## Support & Contact

**For questions about testing**:
- Check FAILING_TESTS_ACTION_PLAN.md for known issues
- Check CROSS_PLATFORM_TESTING.md for cross-platform details
- Review test documentation in run_tests.do (700+ lines)

**To report issues**:
- Review existing issues in GitHub
- Include: test name, error message, Stata version, OS
- Attach: log file (run_tests_TIMESTAMP.log)

**Repository**: https://github.com/[org]/unicefData  
**Maintainer**: João Pedro Azevedo (jpazevedo@unicef.org)

---

*Last Updated: January 6, 2026*  
*Next Review: After implementing XPLAT test fixes*

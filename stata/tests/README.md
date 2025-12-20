# unicefdata Stata Package - Test Suite

## Overview

This directory contains test scripts for the `unicefdata` Stata package. Tests verify the functionality of UNICEF SDMX API data retrieval, metadata parsing, and discovery commands.

## ⚠️ Test Workflow Requirements

### All Tests Must Generate Log Files

Every test run **must** produce a corresponding `.log` file for review:

```stata
* Always run tests in batch mode to generate logs
* From PowerShell:
& "C:\Program Files\Stata17\StataMP-64.exe" /e do test_unicefdata.do

* This creates test_unicefdata.log automatically
```

### Copilot Log Review

After running tests, **always ask GitHub Copilot to review the log file**:

1. Run the test in batch mode (generates `.log` file)
2. Share the log with Copilot: "Review test_unicefdata.log for errors"
3. Copilot will automatically:
   - Identify `r(XXX)` error codes and their meaning
   - Spot failed assertions or unexpected output
   - Detect performance issues (slow commands)
   - Suggest fixes for any problems found

**Example prompt to Copilot:**
> "I ran `test_quick.do`. Please review `test_quick.log` and tell me if all tests passed or if there are any issues."

### Why This Matters

- Stata batch mode captures **all output** including errors that may scroll by
- Log files provide **reproducible evidence** of test results  
- Copilot can parse Stata output and **interpret error codes** (r(199), r(111), etc.)
- Enables **automated debugging** without manual log inspection

## Running Tests

```stata
* From Stata, navigate to tests directory
cd "path/to/unicefData/stata/tests"

* Run a specific test
do test_unicefdata.do

* Or run the quick validation
do test_quick.do
```

## Test Files

| File | Purpose |
|------|---------|
| `test_unicefdata.do` | Comprehensive test suite with multiple scenarios |
| `test_quick.do` | Quick validation of core functionality |
| `test_sync_modes.do` | Tests for metadata synchronization |

## Lessons Learned from Development

### 1. YAML Parsing Challenges

**Problem:** Stata doesn't have native YAML support, requiring custom parsing.

**Solutions:**
- Use `yaml.ado` package for structured parsing
- For simple lookups, direct file reading with regex can be faster
- YAML files use different formats:
  - Nested keys: `DATAFLOW:\n  name: value`
  - List format: `- id: DIMENSION_NAME`

**Example fix:** When parsing list-format YAML (dimensions/attributes):
```stata
* Match "- id: NAME" pattern, not "NAME:" pattern
if regexm("`trimline'", "^- id: *([A-Z_][A-Z0-9_]*)") {
    local entryname = regexs(1)
}
```

### 2. File Path and Location Issues

**Problem:** `findfile` returns full path; need to extract directory.

**Solution:**
```stata
qui findfile _unicefdata_dataflows.yaml
local metapath = subinstr("`r(fn)'", "_unicefdata_dataflows.yaml", "", 1)
```

**Problem:** Schema files named differently than expected.

**Lesson:** Always verify actual filenames vs. what code expects:
- Expected: `EDUCATION_schema.yaml`
- Actual: `EDUCATION.yaml`

### 3. SMCL Hyperlinks

**Problem:** Making clickable elements that execute Stata commands.

**Solution:** Use `{stata command:display_text}` syntax:
```stata
* Hyperlink that shows indicator info when clicked
noi di "{stata unicefdata, info(CME_MRM0):CME_MRM0}"

* With different display text
noi di "{stata unicefdata, dataflow(CME):Click for schema}"
```

### 4. String Matching with Indentation

**Problem:** YAML entries have leading whitespace; direct matching fails.

**Solution:** Use `strtrim()` before comparing:
```stata
local trimline = strtrim("`line'")
if "`trimline'" == "`df_upper':" {
    * Found the dataflow entry
}
```

### 5. Frame Isolation (Stata 16+)

**Problem:** Dataset operations can interfere with user's data.

**Solution:** Use frames for isolated processing:
```stata
if (c(stata_version) >= 16) {
    frame create temp_frame
    frame temp_frame {
        * All operations here don't affect main data
    }
    frame drop temp_frame
}
```

### 6. Return Values Through Wrapper Programs

**Problem:** Sub-program returns don't propagate to caller.

**Solution:** Use `return add` in the wrapper:
```stata
program define wrapper, rclass
    _helper_program, options
    return add  // Passes through r() values from helper
end
```

### 7. Batch Mode vs. Interactive Differences

**Problem:** Some commands behave differently in batch mode.

**Testing tip:** Always test both:
```powershell
# Batch mode
& "C:\Program Files\Stata17\StataMP-64.exe" /e do test.do

# Then verify the .log file
Get-Content test.log
```

### 8. Option Parsing Flexibility

**Problem:** Users may type `dataflow(X)` or `dataflows(X)`.

**Solution:** Accept both variants:
```stata
if (strpos("`0'", "dataflow(") > 0 | strpos("`0'", "dataflows(") > 0) {
    * Handle the parameterized version
}
```

## Test Design Guidelines

### 1. Structure Tests Clearly
```stata
*******************************************************************************
* TEST: [Description]
*******************************************************************************
di as text "Testing: [what you're testing]"
[command]
assert [expected condition]
di as result "✓ PASSED"
```

### 2. Use Assertions for Verification
```stata
* Verify data was loaded
assert _N > 0

* Verify specific variables exist
confirm variable indicator
confirm variable value

* Verify return values
assert r(n_matches) > 0
```

### 3. Test Edge Cases
- Empty results (no matches)
- Invalid inputs (non-existent dataflow)
- Case sensitivity (EDUCATION vs education)
- Special characters in search terms

### 4. Include Timing for Performance Tests
```stata
timer clear 1
timer on 1
[command to time]
timer off 1
timer list 1
```

### 5. Clean Up After Tests
```stata
* Restore original state
clear all
cap frame drop test_frame
cap log close
```

## Common Test Scenarios

### Discovery Commands
```stata
* List all dataflows
unicefdata, flows

* Show dataflow schema
unicefdata, dataflow(EDUCATION)

* List indicators in a dataflow
unicefdata, indicators(CME)

* Search indicators
unicefdata, search(mortality) limit(10)

* Show indicator metadata
unicefdata, info(CME_MRM0)
```

### Data Retrieval
```stata
* Basic data fetch
unicefdata, indicator(CME_MRM0) countries(AFG BGD) clear

* With time range
unicefdata, indicator(CME_MRM0) countries(AFG) start(2010) end(2020) clear

* Multiple indicators
unicefdata, indicator(CME_MRM0 CME_MRY0T4) countries(AFG) clear
```

### Metadata Sync
```stata
* Full sync
unicefdata_sync, all replace

* Indicators only
unicefdata_sync, indicators replace

* Check sync status
unicefdata_sync, status
```

## Debugging Tips

1. **Enable verbose mode:** Add `verbose` option to see detailed output
2. **Check log files:** Batch mode creates `.log` files with full output
3. **Use `set trace on`:** Shows command execution flow
4. **Verify file locations:** Use `findfile` to confirm ado files are found
5. **Check return values:** `return list` shows what a command returned

## File Cleanup

Log files (`*.log`) are generated during test runs and can be safely deleted:
```powershell
Remove-Item "*.log" -Force
```

Keep `.do` files as test scripts can be re-run as needed.

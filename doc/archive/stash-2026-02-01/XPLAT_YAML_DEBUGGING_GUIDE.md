# XPLAT YAML Parsing - Debugging Guide

**Issue:** XPLAT-01 and XPLAT-04 tests fail with `r(198) "invalid name"` when using nested YAML paths

**Affected Tests:**
- XPLAT-01: Compare metadata YAML files (Python/R/Stata)
- XPLAT-04: Validate country code consistency

**Root Cause:** `yaml get` command in Stata yaml package may not support nested dot-notation paths like `_metadata.total_countries` or `countries.USA`

---

## Quick Diagnosis

### Test Command
```stata
clear all
local yaml_file "C:/GitHub/myados/unicefData/python/metadata/current/_unicefdata_countries.yaml"

* Attempt 1: Try nested path (current - fails)
yaml read "`yaml_file'"
capture noisily yaml get _metadata.total_countries
if _rc != 0 {
    di as error "Nested path failed with rc = " _rc
}

* Attempt 2: Try flat access
capture noisily yaml get "_metadata.total_countries"
if _rc != 0 {
    di as error "String path failed with rc = " _rc
}

* Attempt 3: Get top-level key
capture noisily yaml get _metadata
if _rc != 0 {
    di as error "Top-level key failed with rc = " _rc
}

* Attempt 4: List all keys
capture noisily yaml list
```

### Expected YAML File Structure
```yaml
_metadata:
  platform: python
  version: 2.0.0
  synced_at: '2025-12-09T01:11:54.735997Z'
  source: https://sdmx.data.unicef.org/...
  agency: UNICEF
  content_type: countries
  total_countries: 453
  codelist_id: CL_COUNTRY
  codelist_name: Statistical Reference Areas
countries:
  ABW: Aruba
  AFG: Afghanistan
  ...
  USA: United States
  DEU: Germany
```

---

## Solution Options

### Option 1: Use Top-Level Keys (Most Likely to Work)

**For XPLAT-01 (get country count):**
```stata
* Read YAML
yaml read "`yaml_file'"

* Get top-level _metadata object
yaml get _metadata
local metadata_obj = r(value)

* Parse manually to extract total_countries
* This may require string parsing or frame conversion
```

**For XPLAT-04 (get country code):**
```stata
* Read YAML
yaml read "`yaml_file'"

* Get top-level countries object
yaml get countries
local countries_obj = r(value)

* Check if USA/DEU exist in countries object
if strmatch("`countries_obj'", "*USA*") {
    di "USA found"
}
```

### Option 2: Use yaml frames (Alternative Method)

```stata
* Read YAML and convert to frames
yaml read "`yaml_file'"
yaml frames

* List available frames
frame list

* Query data from frames
frame change _yaml_1  // Main frame
summarize  // Check structure
list, limit(10)  // Preview data
count if index(name, "USA") > 0  // Search for USA
```

### Option 3: Use yaml describe (Inspection)

```stata
yaml read "`yaml_file'"
yaml describe  // Show structure without accessing values
* Output may reveal nested structure format
```

### Option 4: Flatten YAML Before Access

**Modify test to use Python/R to flatten:**
```stata
* First, generate flattened YAML version using Python
local py_code = "import yaml; " + ///
    "d = yaml.safe_load(open(r'C:/GitHub/myados/unicefData/python/metadata/current/_unicefdata_countries.yaml')); " + ///
    "print(f'total_countries: {d.get(\"_metadata\", {}).get(\"total_countries\", 0)}')"

* Run Python to extract value
shell python -c "`py_code'"
```

---

## Recommended Fix Strategy

### For XPLAT-01: Country Count Comparison

**Current (failing):**
```stata
* Python: _metadata.total_countries
cap {
    yaml read "`py_yaml'"
    yaml get _metadata.total_countries
    scalar `py_count' = real(r(value))
}
```

**Suggested Fix:**
```stata
* Python: Get _metadata, then parse
cap {
    yaml read "`py_yaml'"
    yaml list  // Debug: see all keys
    
    * Try alternative: parse Python script output
    tempfile py_extract
    tempname fh
    shell python -c "import yaml; d=yaml.safe_load(open(r'`py_yaml'')); print(d.get('_metadata',{}).get('total_countries',0))" > "`py_extract'"
    file open `fh' using "`py_extract'", read
    file read `fh' py_count_str
    file close `fh'
    scalar `py_count' = real("`py_count_str'")
}
```

### For XPLAT-04: Country Code Lookup

**Current (failing):**
```stata
* Check countries.USA exists
cap {
    yaml read "`yaml_file'"
    yaml get countries.USA
}
```

**Suggested Fix:**
```stata
* Check if USA exists in countries section
cap {
    yaml read "`yaml_file'"
    yaml get countries
    local countries_str = r(value)
    
    if strmatch("`countries_str'", "*USA*") {
        local found = 1
    }
    else {
        local found = 0
    }
}
```

---

## Testing Implementation

### Quick Test Script

Save as `test_yaml_access.do`:

```stata
clear all
set more off

local yaml_file "C:/GitHub/myados/unicefData/python/metadata/current/_unicefdata_countries.yaml"

noi di as text "=== YAML Access Testing ==="
noi di as text ""

* Test 1: Basic read
noi di as text "Test 1: Basic read"
yaml read "`yaml_file'"
noi di as result "Γ£ô yaml read succeeded"

* Test 2: List keys
noi di as text ""
noi di as text "Test 2: List keys"
capture noisily yaml list
if _rc == 0 {
    noi di as result "Γ£ô yaml list succeeded"
}
else {
    noi di as error "Γ£ù yaml list failed (rc=" _rc ")"
}

* Test 3: Get top-level _metadata
noi di as text ""
noi di as text "Test 3: Get _metadata"
capture noisily yaml get _metadata
if _rc == 0 {
    noi di as result "Γ£ô yaml get _metadata succeeded"
    noi di "  Value:" r(value)
}
else {
    noi di as error "Γ£ù yaml get _metadata failed (rc=" _rc ")"
}

* Test 4: Get countries
noi di as text ""
noi di as text "Test 4: Get countries"
capture noisily yaml get countries
if _rc == 0 {
    noi di as result "Γ£ô yaml get countries succeeded"
    noi di "  Value (first 100 chars):" substr(r(value), 1, 100)
}
else {
    noi di as error "Γ£ù yaml get countries failed (rc=" _rc ")"
}

* Test 5: Frames method
noi di as text ""
noi di as text "Test 5: Frames method"
yaml read "`yaml_file'"
capture noisily yaml frames
if _rc == 0 {
    noi di as result "Γ£ô yaml frames succeeded"
    frame list
}
else {
    noi di as error "Γ£ù yaml frames failed (rc=" _rc ")"
}

noi di as text ""
noi di as text "=== Testing Complete ==="
```

### Run Test
```powershell
cd C:\GitHub\myados\unicefData-dev\stata\tests
& "C:\Program Files\Stata17\StataMP-64.exe" /e do test_yaml_access.do
Get-Content test_yaml_access.log | Select-Object -Last 100
```

---

## Resolution Steps (Execute in Order)

1. **Run diagnostic test** (test_yaml_access.do)
   - Identify which yaml commands work
   - Determine if nested paths are supported

2. **Based on results, choose fix:**
   - If `yaml get` supports top-level keys ΓåÆ Use Option 1
   - If `yaml frames` works ΓåÆ Use Option 2
   - If nothing works ΓåÆ Use Python/R extraction

3. **Update run_tests.do** with working syntax
   - Replace failing commands in XPLAT-01 (line ~2315)
   - Replace failing commands in XPLAT-04 (line ~2630)

4. **Re-run QA tests**
   ```powershell
   cd C:\GitHub\myados\unicefData-dev\stata\qa
   & "C:\Program Files\Stata17\StataMP-64.exe" /e do run_tests.do XPLAT-01
   & "C:\Program Files\Stata17\StataMP-64.exe" /e do run_tests.do XPLAT-04
   ```

5. **Verify fixes** (should now pass or show different error)

---

## If All Else Fails

### Fallback: Use Python to Extract Values

```stata
* Instead of yaml commands, use Python subprocess
tempfile py_output
shell python -c "
import yaml
with open(r'`yaml_file'') as f:
    data = yaml.safe_load(f)
    count = data.get('_metadata', {}).get('total_countries', 0)
    print(f'{count}')
" > "`py_output'"

tempname fh
file open `fh' using "`py_output'", read
file read `fh' result_line
file close `fh'

noi di "Result: `result_line'"
```

---

## Contact / Escalation

If XPLAT issues persist after trying all options:
1. Export test YAML files to plaintext for inspection
2. Check yaml package version: `which yaml` (in Stata)
3. Consider alternative: use Python/R for YAML parsing (less pure, but works)

**Expected outcome:** XPLAT-01/04 should pass or show clearer error message after fix


# Issue Validity Checker - Documentation

## Purpose

The `check_issues_validity.py` script validates which issues documented in `CROSS_PLATFORM_DATASET_SCHEMA_ISSUES.md` are still active, fixed, or changed.

## Issues Checked

### Issue 1: Stata Duplicate Columns
**File**: `check_issue_1_stata_duplicates()`

Tests whether Stata creates duplicate columns with different naming patterns (e.g., `cause_group` + `causegroup`).

**Expected**: Only code columns (lowercase, no duplicate variants)  
**Current (Broken)**: Both code AND label columns created separately  
**Test Indicator**: `COD_SELF_HARM`

**What It Checks**:
- Scans all columns for lowercase variants of the same name
- Identifies duplicate column pairs (e.g., `cause_group` vs `causegroup`)
- Verifies if they contain different data

**Possible Results**:
- ✅ **FIXED**: No duplicate columns found
- 🔴 **STILL_VALID**: Duplicates detected (issue active)
- ⚠️ **UNABLE_TO_TEST**: Cannot fetch data from Stata

---

### Issue 2: Missing Dimensions in Python/R
**File**: `check_issue_2_missing_dimensions_ws_hcf()`

Tests whether Python/R implementations retrieve all dimensions that Stata correctly gets.

**Expected**: Same row counts across platforms; `service_type` and `hcf_type` dimensions present  
**Current (Broken)**: Python/R only return 269 rows; Stata returns 1,017 rows  
**Test Indicator**: `WS_HCF_H-L`

**What It Checks**:
- Fetches same indicator from Python and Stata
- Compares row counts (ratio should be 1:1)
- Looks for missing dimensions: `service_type`, `hcf_type`
- Calculates row count ratio

**Possible Results**:
- ✅ **FIXED**: Ratio ~1.0x, no missing dimensions
- ⚠️ **PARTIALLY_FIXED**: Ratio 1.5-2.0x or some dimensions missing
- 🔴 **STILL_VALID**: Ratio > 2.0x and dimensions missing (issue active)
- ⚠️ **UNABLE_TO_TEST**: Cannot fetch from one or both platforms

---

### Issue 3: Row Count Discrepancies
**File**: `check_issue_3_row_discrepancies()`

Tests row count consistency across platforms for all problematic indicators.

**Indicators Tested**:
1. `WS_HCF_H-L` - Expected: Stata >> Py/R
2. `ECD_CHLD_U5_BKS-HM` - Expected: Stata > Py/R (small)
3. `ED_MAT_G23` - Expected: Py/R > Stata (reverse!)
4. `FD_FOUNDATIONAL_LEARNING` - Expected: Py/R >> Stata (reverse!)
5. `NT_CF_ISSSF_FL` - Expected: Py < R/Stata
6. `NT_CF_MMF` - Expected: Py < R/Stata

**What It Checks**:
- Fetches all 6 indicators from Python and Stata
- Compares row counts for each
- Marks each as "MATCH" or "MISMATCH"
- Calculates overall pass/fail rate

**Possible Results**:
- ✅ **FIXED**: All 6 indicators match exactly
- ⚠️ **PARTIALLY_FIXED**: 4-5 indicators match
- 🔴 **STILL_VALID**: Multiple mismatches detected (3+ indicators)
- ⚠️ **UNABLE_TO_TEST**: Cannot fetch most indicators

---

### Issue 4: UTF-8 Encoding Fallback
**File**: `check_issue_4_encoding_fallback()`

Tests whether UTF-8 encoding issues are handled gracefully with fallback.

**Expected**: Python fetches indicators successfully with UTF-8 → latin-1 fallback  
**Affected Indicators**: `ECD_CHLD_U5_BKS-HM`, `NT_CF_ISSSF_FL`

**What It Checks**:
- Fetches both indicators from Python
- Looks for encoding errors in fetch process
- Verifies data is returned despite encoding issues

**Possible Results**:
- ✅ **NO_ENCODING_ISSUES**: Both indicators fetch successfully
- ⚠️ **ENCODING_ISSUES_DETECTED**: Errors occur but may be handled
- 🔴 **ERROR**: Fetch fails due to encoding (issue not fixed)

---

## Running the Script

### Basic Usage

```bash
# Activate virtual environment
cd C:\GitHub\myados\unicefData-dev
.\..\\.venv\Scripts\Activate.ps1

# Run the validity checker
python validation/scripts/check_issues_validity.py
```

### Output

The script produces two output files in `validation/results/issue_validity/TIMESTAMP/`:

1. **issue_validity_report.txt** - Human-readable report with:
   - Status summary table
   - Overall statistics
   - Detailed findings for each issue
   - JSON-formatted data

2. **issue_validity_results.json** - Machine-readable JSON with:
   - Complete results for each issue
   - Row counts and comparisons
   - Error details if applicable
   - Test metadata

### Console Output Example

```
[15:45:23 INFO] Checking Issue 1: Stata duplicate columns (using COD_SELF_HARM)...
[15:45:45 ✓] No duplicate columns found - ISSUE APPEARS FIXED

[15:45:46 INFO] Checking Issue 2: Missing dimensions in Python/R (WS_HCF_H-L)...
[15:46:22 ✗] ISSUE CONFIRMED: Python 269 rows, Stata 1,017 rows (ratio: 3.78x)
[15:46:22 ✗] Missing dimensions: ['service_type', 'hcf_type']

[15:46:23 INFO] Checking Issue 3: Row count discrepancies across platforms...
[15:46:25 INFO]   Testing WS_HCF_H-L (expected pattern: Stata >> Py/R)...
[15:47:12 !]   WS_HCF_H-L: Py=269, Stata=1017, ratio=3.78x

[15:47:13 INFO] Checking Issue 4: UTF-8 encoding fallback behavior...
[15:47:13 INFO]   Testing ECD_CHLD_U5_BKS-HM...
[15:47:45 ✓]   ECD_CHLD_U5_BKS-HM: Fetched 118 rows successfully
```

---

## Interpreting Results

### Status Legend

| Status | Meaning | Action |
|--------|---------|--------|
| ✅ **FIXED** | Issue no longer detected | No action needed; can consider resolved |
| 🟡 **PARTIALLY_FIXED** | Issue partially resolved | Some work remains; document progress |
| 🔴 **STILL_VALID** | Issue confirmed active | Requires continued investigation/fixing |
| ⚠️ **UNABLE_TO_TEST** | Cannot evaluate issue | Check fetch errors; may be environment issue |
| ❌ **ERROR** | Unexpected failure | Review error details; may indicate new problems |

### Example Interpretation

**Scenario 1 - All Issues FIXED**
```
Issue 1 (Stata Duplicates): [FIXED]
Issue 2 (Missing Dimensions): [FIXED]
Issue 3 (Row Discrepancies): [FIXED]
Issue 4 (Encoding): [NO_ENCODING_ISSUES]

→ All documented issues have been resolved! Update progress report.
```

**Scenario 2 - Partial Progress**
```
Issue 1 (Stata Duplicates): [FIXED]         ✓ Fixed in this sprint
Issue 2 (Missing Dimensions): [PARTIALLY_FIXED]  ⚠️ Partially fixed; 2/6 indicators match
Issue 3 (Row Discrepancies): [STILL_VALID]  🔴 Still 4 mismatches
Issue 4 (Encoding): [NO_ENCODING_ISSUES]    ✓ No encoding issues

→ Document fixes; continue work on Issues 2-3
```

**Scenario 3 - Regression Detected**
```
Issue 1 (Stata Duplicates): [STILL_VALID]   🔴 Was FIXED before; now broken again!

→ URGENT: Investigate regression; may be due to recent code changes
```

---

## Integration with Progress Tracking

After running, update `CROSS_PLATFORM_DATASET_SCHEMA_ISSUES.md`:

1. **Add new section**: "Part 9: Issue Validity Check - [DATE]"
2. **Copy results table** from report into markdown
3. **Update status tracking table** with current progress
4. **Document findings** for each issue

Example update:
```markdown
## Part 9: Issue Validity Check (January 22, 2026)

**Execution Date**: 2026-01-22 15:45:33 UTC  
**Result**: 2 Fixed, 1 Partially Fixed, 1 Still Valid

| Issue | Previous Status | Current Status | Progress |
|-------|-----------------|----------------|----------|
| Issue 1: Stata Duplicates | STILL_VALID | FIXED | ✓ Fixed in sprint 47 |
| Issue 2: Missing Dimensions | STILL_VALID | PARTIALLY_FIXED | ⚠️ 4/6 indicators now match |
| Issue 3: Row Discrepancies | STILL_VALID | STILL_VALID | 🔴 3 mismatches remain |
| Issue 4: Encoding | ENCODING_ISSUES | NO_ENCODING_ISSUES | ✓ Fallback working |

→ Continue focus on Issue 2-3; Issue 1 resolved; Issue 4 stable.
```

---

## Troubleshooting

### Script Fails: "Could not import UNICEFSDMXClient"

**Cause**: Python path not set up correctly  
**Fix**:
```bash
cd C:\GitHub\myados\unicefData-dev
.\..\\.venv\Scripts\Activate.ps1
python -c "import sys; sys.path.insert(0, 'python'); from unicef_api.sdmx_client import UNICEFSDMXClient; print('OK')"
```

### Script Fails: "Stata not found"

**Cause**: Stata executable path incorrect  
**Fix**:
1. Update `STATA_EXE` path in script to match your installation:
   ```bash
   "C:\Program Files\Stata17\StataMP-64.exe"  # Default
   "C:\Program Files\Stata18\StataMP-64.exe"  # If using Stata 18
   ```
2. Or check installed path:
   ```powershell
   Get-ChildItem "C:\Program Files" -Filter "Stata*"
   ```

### Indicators fail to fetch: "No such file or directory"

**Cause**: ADO files not in Stata path  
**Fix**:
```stata
adopath
* Should show C:\Users\jpazevedo\ado\plus in the path
* If not, copy files:
copy "C:\GitHub\myados\unicefData-dev\stata\src\u\unicefdata.ado" "C:\Users\jpazevedo\ado\plus\u\unicefdata.ado"
```

### Python fetch timeout

**Cause**: Network issue or API unavailable  
**Fix**:
1. Test API availability:
   ```powershell
   curl "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,WASH_HEALTHCARE_FACILITY,1.0/.WS_HCF_H-L?format=csv&lastNObservations=1"
   ```
2. If API is down, note in results file
3. Try again after API recovery

---

## Advanced Usage

### Testing Specific Indicators

Edit the script to change test indicators:

```python
# Line ~280: Change test indicator for Issue 1
def check_issue_1_stata_duplicates(indicator: str = "YOUR_INDICATOR") -> Dict[str, Any]:

# Line ~250: Add/remove indicators from Issue 3 test list
indicators_to_test = [
    ("YOUR_INDICATOR_1", "Expected pattern"),
    ("YOUR_INDICATOR_2", "Expected pattern"),
]
```

### Adding Custom Checks

Add new functions following the pattern:

```python
def check_issue_5_custom(indicator: str = "TEST") -> Dict[str, Any]:
    """Check Issue 5: Your custom check.
    
    Returns:
        Dict with status and details
    """
    result = {
        "issue": "Your Issue Name",
        "status": "UNKNOWN",
        "details": {}
    }
    
    # Your check logic here
    
    return result

# Then add to main():
all_results.append(check_issue_5_custom())
```

---

## Performance Notes

- **Runtime**: ~10-15 minutes (depending on network/Stata startup)
- **Network**: Makes ~10-15 API calls (to UNICEF SDMX endpoint)
- **Disk**: ~50MB for results (CSV exports + logs)
- **Memory**: ~500MB (Python + R + Stata processes)

---

## References

- Full issue documentation: `CROSS_PLATFORM_DATASET_SCHEMA_ISSUES.md`
- Related validation scripts:
  - `check_phase2_cases.py` - Phase 2 validation (different scope)
  - `test_all_indicators_comprehensive.py` - Comprehensive test suite
  - `validate_cross_language.py` - Cross-language validation

---

**Version**: 1.0  
**Created**: January 19, 2026  
**Last Updated**: January 19, 2026

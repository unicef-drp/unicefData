# Issue Validity Checker - Quick Reference

## TL;DR - One Command to Check All Issues

```powershell
# From repo root
cd C:\GitHub\myados\unicefData-dev\validation\scripts
.\run_issue_validity_check.ps1
```

**That's it!** The script will:
1. ✅ Activate Python venv automatically
2. ✅ Fetch test indicators from Python/Stata/R
3. ✅ Compare across platforms
4. ✅ Generate reports
5. ✅ Show results location

---

## What Gets Checked

| Check | Tests | Time | Status Key |
|-------|-------|------|-----------|
| **Issue 1** | Stata duplicate columns | 2-3 min | ✅ FIXED or 🔴 STILL_VALID |
| **Issue 2** | Missing dimensions (Python/R) | 3-4 min | ✅ FIXED or 🔴 STILL_VALID |
| **Issue 3** | Row count mismatches | 5-7 min | ✅ FIXED or 🔴 STILL_VALID |
| **Issue 4** | UTF-8 encoding issues | 2-3 min | ✅ NO_ENCODING_ISSUES or 🔴 DETECTED |

---

## Reports Generated

```
validation/results/issue_validity/TIMESTAMP/
├── issue_validity_report.txt        ← Read this for summary
├── issue_validity_results.json      ← Machine-readable results
└── tmp/                              ← Logs and CSV exports
```

### Reading the Report

Look for this section:
```
ISSUES STATUS SUMMARY
================================================================================
Issue                                Status               Details
================================================================================
Stata Duplicate Columns              [FIXED]              ✅ No duplicates found
Missing Dimensions in Python/R       [STILL_VALID]        🔴 Ratio 3.78x
Row Count Discrepancies              [PARTIALLY_FIXED]    ⚠️ 5/6 indicators match
UTF-8 Encoding Fallback              [NO_ENCODING_ISSUES] ✅ Both handled OK
```

---

## Interpreting Results

### All Fixed ✅
```
All statuses = [FIXED] or [NO_ENCODING_ISSUES]
→ All issues resolved! Update progress tracker.
```

### Partial Progress 🟡
```
Some = [FIXED], others = [STILL_VALID]
→ Document fixes; continue work on remaining.
```

### Still Broken 🔴
```
One or more = [STILL_VALID]
→ Continue investigation; no progress since last check.
```

### Can't Evaluate ⚠️
```
Any = [UNABLE_TO_TEST] or [ERROR]
→ Check environment; may be network/setup issue.
```

---

## Key Indicators Tested

### Issue 1: Stata Duplicates
- **Indicator**: `COD_SELF_HARM`
- **Check**: Are there `cause_group` + `causegroup` columns?

### Issue 2: Missing Dimensions
- **Indicator**: `WS_HCF_H-L`
- **Check**: Python 269 rows vs Stata 1,017 rows? Missing `service_type`, `hcf_type`?

### Issue 3: Row Discrepancies
- **Indicators**: WS_HCF_H-L, ECD_CHLD_U5_BKS-HM, ED_MAT_G23, FD_FOUNDATIONAL_LEARNING, NT_CF_ISSSF_FL, NT_CF_MMF
- **Check**: Row counts match across Python/Stata?

### Issue 4: Encoding
- **Indicators**: ECD_CHLD_U5_BKS-HM, NT_CF_ISSSF_FL
- **Check**: Does Python handle UTF-8 errors gracefully?

---

## Common Issues & Fixes

### "Could not import UNICEFSDMXClient"
```powershell
# Manually activate and verify
cd C:\GitHub\myados\unicefData-dev
.\..\\.venv\Scripts\Activate.ps1
python -c "from unicef_api.sdmx_client import UNICEFSDMXClient; print('OK')"
```

### "Stata not found"
```powershell
# Verify Stata is installed
Get-ChildItem "C:\Program Files" -Filter "Stata*"
# Or test directly
& "C:\Program Files\Stata17\StataMP-64.exe" --version
```

### "Indicator fetch failed"
```powershell
# Check if ADO files are installed
ls C:\Users\$env:USERNAME\ado\plus\u\unicefdata.ado
# If not found, copy them:
Copy-Item "C:\GitHub\myados\unicefData-dev\stata\src\u\*.ado" `
  -Destination "C:\Users\$env:USERNAME\ado\plus\u\" -Force
```

### "Network timeout"
```powershell
# Check API availability
$url = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,WASH_HEALTHCARE_FACILITY,1.0/.WS_HCF_H-L?format=csv&lastNObservations=1"
Invoke-WebRequest $url -TimeoutSec 30
```

---

## Integration with Workflow

### After Each Sprint
1. Run the validity checker
2. Review results
3. Update progress report if issues fixed
4. Commit changes

### Before Release
1. Run full validation
2. Verify all critical issues fixed
3. Archive old issue docs
4. Update release notes

### Weekly Health Check
1. Run script (even if no code changes)
2. Compare with previous week's results
3. Alert if regression detected

---

## Files Included

| File | Purpose | Size |
|------|---------|------|
| `check_issues_validity.py` | Main validation script | 17.9 KB |
| `CHECK_ISSUES_VALIDITY_README.md` | Full documentation | 10.8 KB |
| `run_issue_validity_check.ps1` | PowerShell launcher | 2.2 KB |
| `ISSUE_VALIDITY_CHECKER_SUMMARY.md` | Implementation guide | 11.0 KB |
| `ISSUES_VALIDITY_QUICK_REFERENCE.md` | This file | - |

---

## Next Steps

1. **Run the script**: `.\run_issue_validity_check.ps1`
2. **Review results**: Check `issue_validity_report.txt`
3. **Update progress**: Add findings to `CROSS_PLATFORM_DATASET_SCHEMA_ISSUES.md` Part 9
4. **Track status**: Update issue tracker with current progress

---

## Questions?

See full documentation:
- **Detailed Docs**: `CHECK_ISSUES_VALIDITY_README.md`
- **Architecture**: `ISSUE_VALIDITY_CHECKER_SUMMARY.md`
- **Issues Tracked**: `CROSS_PLATFORM_DATASET_SCHEMA_ISSUES.md`

---

**Version**: 1.0  
**Created**: January 19, 2026  
**Branch**: feat/cross-platform-dataset-schema

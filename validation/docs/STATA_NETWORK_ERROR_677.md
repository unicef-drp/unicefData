# Stata Network Error Investigation (r677)

**Date**: January 21, 2026  
**Issue**: Stata validation tests failing with network error r(677)  
**Component**: unicefData package - SDMX API data downloads

## Root Cause

Stata's `copy` command is failing to connect to the UNICEF SDMX API endpoint:
```stata
capture copy "<https://sdmx.data.unicef.org/...>" "<tempfile>", replace public
```

**Error Code**: `r(677)` = "could not connect to server"

## Code Location

- **File**: `unicefData-dev/stata/src/u/unicefdata.ado`
- **Line**: 721
- **Function**: Network download with retry logic (max 3 attempts, 1-second delays)

## Why This Happens

Stata's built-in `copy` command for HTTPS downloads can fail due to:

1. **Windows Firewall**: Stata executable blocked from making outbound HTTPS connections
2. **SSL/TLS Certificate Issues**: Certificate validation failures on Windows systems
3. **Proxy Configuration**: Corporate proxy settings not recognized by Stata
4. **Network Timeout**: Connection timing out before establishment
5. **Antivirus Software**: Real-time protection blocking network access

## Current Error Handling

The code already implements:
- ✅ Retry logic (3 attempts with 1-second delays)
- ✅ Fallback mechanism (tries alternative dataflows via `get_sdmx`)
- ✅ Error detection and reporting in validation framework

## Improvements Made

### 1. Enhanced Verbose Error Reporting

Added detailed error messages when `verbose` option is used:
```stata
if (`ind_success' == 0 & "`verbose'" != "") {
    noi di as error "  ✗ Network error after `max_retries' attempts (r=`last_rc')"
    if (`last_rc' == 677) {
        noi di as text "    Error 677 = 'could not connect to server'"
        noi di as text "    Possible causes: Firewall, SSL/TLS, proxy, or network timeout"
        noi di as text "    Run: do test_stata_network.do for diagnostics"
    }
    noi di as text "    URL: `ind_url'"
}
```

### 2. Network Diagnostic Script

Created `validation/test_stata_network.do` to diagnose network issues:
- Tests HTTP connection (non-SSL)
- Tests HTTPS connection to UNICEF API
- Displays Stata network settings
- Tests PowerShell alternative download method

## Recommended Solutions

### Solution 1: Windows Firewall Exception (Most Common)

```powershell
# Allow Stata through Windows Firewall
New-NetFirewallRule -DisplayName "Stata HTTPS" -Direction Outbound `
    -Program "C:\Program Files\Stata17\StataMP-64.exe" -Action Allow
```

Or via GUI:
1. Windows Security → Firewall & network protection
2. Advanced settings → Outbound Rules → New Rule
3. Program: `C:\Program Files\Stata17\StataMP-64.exe`
4. Action: Allow connection
5. Apply to all profiles

### Solution 2: Configure Stata Proxy Settings

If behind corporate proxy:
```stata
set httpproxy on
set httpproxyhost "proxy.company.com"
set httpproxyport 8080
set httpproxyauth off  // or on if authentication required
```

### Solution 3: Use Alternative Download Method

Modify code to use PowerShell for downloads (if Test 4 in diagnostic passes):
```stata
* Alternative: Use PowerShell for HTTPS downloads
shell powershell -Command "Invoke-WebRequest -Uri '`url'' -OutFile '`tempfile''"
```

### Solution 4: Update Stata's SSL Configuration

For older Stata versions, update SSL certificates:
```stata
* Update certificates (requires Stata 15+)
ssc install st0599  // SSL certificate bundle update
```

## Validation Framework Impact

The validation framework correctly detects and categorizes this error:

**Test Status Classification**:
- Network error (r677) + NODATA in log → `TestStatus.NOT_FOUND` (indicator doesn't exist)
- Network error (r677) alone → `TestStatus.NETWORK_ERROR` (genuine network issue)

**Error File Location**:
- Validation run creates: `validation/results/<timestamp>/stata/failed/<INDICATOR>.error`
- Contains: Status, error message, log file reference

## Testing the Fix

### Step 1: Run Diagnostic
```bash
cd C:\GitHub\myados\unicefData-dev\validation
& "C:\Program Files\Stata17\StataMP-64.exe" /e do test_stata_network.do
```

### Step 2: Apply Firewall Exception
Use Solution 1 above

### Step 3: Test Single Indicator
```stata
clear all
net install unicefdata, from("C:/GitHub/myados/unicefData-dev/stata") all replace force
unicefdata, indicator(CME_MRM0) clear verbose
```

### Step 4: Rerun Validation
```bash
cd C:\GitHub\myados\unicefData-dev\validation
python run_validation.py --limit 10 --seed 42 --random-stratified --valid-only --languages python r stata
```

## Expected Outcomes

After fixing:
- ✅ Stata tests show `SUCCESS` or `CACHED` status
- ✅ Network errors (r677) eliminated or reduced to genuine API issues
- ✅ CSV files appear in `validation/cache/stata/`
- ✅ Cross-platform consistency improves

## Monitoring

Check validation results for:
```json
{
  "language": "stata",
  "status": "success",  // Changed from "network_error"
  "execution_time_sec": 12.5,  // Reasonable download time
  "error_message": null
}
```

## References

- Stata error codes: `help error codes` (r677 = "could not connect to server")
- Stata network settings: `help netio`
- Stata proxy configuration: `help set httpproxy`
- UNICEF SDMX API: https://sdmx.data.unicef.org/

## Next Steps

1. ✅ Run diagnostic script to identify specific issue
2. ⏳ Apply appropriate solution (likely firewall exception)
3. ⏳ Verify with single indicator test
4. ⏳ Rerun full validation to confirm fix
5. ⏳ Monitor cache directory for Stata CSV files
6. ⏳ Document system-specific configuration for future reference

# Quick Fix Guide: R 404 Issue on COD_DENGUE and MG_NEW_INTERNAL_DISP

## The Problem

R validator gets HTTP 404 errors for two indicators that work fine in Python and Stata:
- **COD_DENGUE**: Python gets 70 rows ✅, R gets 404 ❌
- **MG_NEW_INTERNAL_DISP**: Python gets 3,616 rows ✅, R gets 404 ❌

## Why This Happens

The UNICEF SDMX API is rejecting the request from R's `httr` client while accepting the same request from Python's `requests` client and Stata's HTTP client.

**Most likely cause**: The API (or an API gateway/proxy) is filtering requests based on User-Agent header:
- R sends: `User-Agent: libcurl/7.87.0 r-curl/5.0.1 (Windows) R/4.5.1`
- Python sends: `User-Agent: python-requests/2.31.0`
- Stata sends: [Different Stata-specific UA]

The API may have:
1. Whitelist of allowed User-Agents
2. Rate-limiting based on UA
3. Bot detection that flags libcurl/R
4. Proxy rules that treat R traffic differently

## Proposed Solutions

### Solution 1: Modify R User-Agent (Best for Quick Fix)

**File**: `R/unicef_core.R`  
**Location**: Lines 85-115 in `fetch_sdmx_text()` function

**Current code**:
```r
fetch_sdmx_text <- function(url, ua = .unicefData_ua, retry) {
  resp <- httr::RETRY("GET", url, ua, times = retry, pause_base = 1)
  ...
}
```

**Fix**: Override the User-Agent header to match Python's requests library:

```r
fetch_sdmx_text <- function(url, ua = NULL, retry) {
  # Use a neutral User-Agent that works with UNICEF API
  if (is.null(ua)) {
    ua <- httr::user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
  }
  
  resp <- httr::RETRY("GET", url, ua, times = retry, pause_base = 1)
  
  status <- httr::status_code(resp)
  if (identical(status, 404L)) {
    # For debugging: log the URL and UA being used
    message(sprintf("DEBUG 404 - URL: %s", url))
    message(sprintf("DEBUG UA: %s", as.character(ua)))
    
    stop(
      structure(
        list(message = sprintf("Not Found (404): %s", url), url = url, status = status),
        class = c("sdmx_404", "error", "condition")
      )
    )
  }
  httr::stop_for_status(resp)
  httr::content(resp, as = "text", encoding = "UTF-8")
}
```

### Solution 2: Use curl directly (Most Reliable)

**File**: `R/unicef_core.R`

Replace `httr::RETRY()` with explicit curl call:

```r
fetch_sdmx_text <- function(url, ua = NULL, retry) {
  h <- new_handle()
  
  # Set headers that match Python requests
  handle_setheaders(h,
    "User-Agent" = "python-requests/2.31.0",
    "Accept" = "application/xml",
    "Accept-Encoding" = "gzip, deflate, br",
    "Connection" = "keep-alive"
  )
  
  resp <- curl::curl_fetch_memory(url, h)
  
  if (resp$status_code == 404L) {
    stop(
      structure(
        list(message = sprintf("Not Found (404): %s", url), url = url, status = resp$status_code),
        class = c("sdmx_404", "error", "condition")
      )
    )
  }
  
  rawToChar(resp$content)
}
```

### Solution 3: Add Explicit Timeout/Retry (Safest)

**File**: `R/unicef_core.R`

Modify retry strategy with longer delays between attempts:

```r
fetch_sdmx_text <- function(url, ua = .unicefData_ua, retry = 5) {
  # Use increased retry with longer backoff for potentially problematic endpoints
  resp <- httr::RETRY(
    "GET", 
    url, 
    ua, 
    times = retry, 
    pause_base = 2,  # Start with 2 second pause
    pause_cap = 60,  # Cap at 60 seconds
    pause_min = 1
  )
  
  status <- httr::status_code(resp)
  if (identical(status, 404L)) {
    stop(...)
  }
  ...
}
```

## Testing the Fix

After implementing a solution, test with:

```r
Rscript validation/scripts/diagnose_r_failures.R
```

Should show:
```
TEST 1: COD_DENGUE
  Result: 70 rows  ✅ SUCCESS
  
TEST 2: MG_NEW_INTERNAL_DISP  
  Result: 3616 rows  ✅ SUCCESS
```

## Why COD_DENGUE and MG_NEW_INTERNAL_DISP Specifically?

These two indicators might be:
1. Served from a different API server/region
2. Subject to stricter bot detection rules
3. In dataflows with special access restrictions
4. More commonly accessed by bots (hence stricter filtering)

This would explain why 3 other indicators work fine but only these 2 fail.

## Validation After Fix

Run the full 34-indicator validation again:

```powershell
python validation/scripts/test_all_indicators_comprehensive.py `
  --languages r --seed 50 --force-fresh
```

Should show all 34 indicators with status: ✅ success (not not_found)

## Long-Term Recommendations

1. **Contact UNICEF API team** - Report that R client is being rejected
2. **Add UA override option** - Allow users to specify custom User-Agent
3. **Add error logging** - Log 404 URLs for debugging
4. **Add fallback dataflows** - Try alternate dataflow if primary fails
5. **Cache metadata** - Pre-fetch all available indicators/dataflows on startup

## Reference Files

- `diagnose_r_failures.R` - Run this to verify the fix
- `R_DATAFLOW_ISSUE_ANALYSIS.md` - Detailed analysis
- `R/unicef_core.R` - File to modify for fix

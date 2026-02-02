# R Validator Issue Analysis: COD_DENGUE and MG_NEW_INTERNAL_DISP

**Date**: 2026-01-13  
**Status**: Investigation Complete  
**Impact**: 2 of 34 validated indicators return 404 errors in R validator

## Summary

Two indicators fail in the R validator but succeed in Python and Stata:
- **COD_DENGUE** (Dengue deaths) - Returns 0 rows (empty result)
- **MG_NEW_INTERNAL_DISP** (New internal displacements) - Returns 0 rows (empty result)

Both indicators:
1. ✅ Succeed in Python validator (70 and 3,616 rows respectively)
2. ✅ Succeed in Stata validator (70 and 3,616 rows respectively)
3. ❌ Fail in R validator with HTTP 404 errors (but silently return empty tibble)
4. Are confirmed in metadata with correct dataflow mappings

## Root Cause Analysis

### What We Know

**From R Diagnostic Output:**
```
Auto-detected dataflow 'GLOBAL_DATAFLOW' for COD_DENGUE
Fetching page 1...
Request failed [404]. Retrying in 1.9 seconds...
Request failed [404]. Retrying in 1.5 seconds...
Result received (empty tibble with 0 rows, 0 cols)
```

**Same for MG_NEW_INTERNAL_DISP:**
```
Auto-detected dataflow 'MIGRATION'
Fetching page 1...
Request failed [404]. Retrying in 1.3 seconds...
Request failed [404]. Retrying in 1.5 seconds...
Result received (empty tibble with 0 rows, 0 cols)
```

### Key Differences Between R and Python Implementations

| Aspect | R (unicefData pkg) | Python (unicef_api) | Result |
|--------|------------------|-------------------|---------|
| **HTTP Client** | `httr::RETRY()` | `requests` library | Different retry/timeout behavior |
| **User-Agent** | Set via `.unicefData_ua` | Set in headers | May affect API response |
| **Encoding** | UTF-8 (specified) | Default | Different handling of response |
| **Error Handling** | Converts 404→empty tibble | Raises exception | R silently masks the error |
| **Request Format** | SDMX-specific query params | SDMX REST API | May differ in URL encoding |
| **Retry Strategy** | `httr::RETRY()` with exp backoff | Custom retry logic | Different retry patterns |

### Why R is Silently Failing

**In R/unicef_core.R fetch_sdmx_text():**

```r
resp <- httr::RETRY("GET", url, ua, times = retry, pause_base = 1)
status <- httr::status_code(resp)

if (identical(status, 404L)) {
    stop(structure(..., class = c("sdmx_404", "error", "condition")))
}
```

When a 404 is detected, R raises an `sdmx_404` error, which is:
1. **Caught silently** by the calling code (tryCatch with empty return)
2. **Not logged** (no error message reaches the user)
3. **Returns empty tibble** (consistent with "no data found")

**However**, the real question is: **Why is R getting 404 when Python isn't?**

This suggests:
- Different URL being constructed
- Different request headers (User-Agent, Accept)
- Different retry/timeout that causes API to reject
- R-specific issue with API session handling

## Possible Root Causes

### 1. **User-Agent Detection** (Most Likely)
Some APIs (including UNICEF's) may filter requests by User-Agent. R's `httr` sends:
```
User-Agent: libcurl/7.x R/4.5.1
```

Python's `requests` sends:
```
User-Agent: python-requests/2.x
```

UNICEF API might be configured to reject or rate-limit specific user-agents.

### 2. **Query Parameter Encoding**
The SDMX REST API is sensitive to query parameter formatting. R and Python may encode:
- Spaces differently (`%20` vs `+`)
- Special characters differently
- Dimension order differently

### 3. **Request Headers**
R's `httr::RETRY()` may not be sending the same headers as Python's `requests`:
- `Accept: application/xml` vs `Accept: */*`
- `Accept-Encoding` differences
- Cache headers

### 4. **Session/Cookie Handling**
Python may maintain session state that allows successful retry, while R's RETRY mechanism resets per request.

### 5. **Data Availability in SDMX Structure**
Possible but unlikely: COD_DENGUE and MG_NEW_INTERNAL_DISP might:
- Be in a restricted dataflow that R package doesn't have access to
- Require authentication that only Python has
- Be filtered by region (USA might not have data in these specific dataflows)

## Multi-Language Test Results

```
Test Results (5 indicators × 3 languages):

CME_MRY20T24:           Python ✅ 8,466 | R ✅ 8,466 | Stata ✅ 8,466
COD_DENGUE:             Python ✅ 70    | R ❌ 404   | Stata ✅ 70
ED_ROFST_L2_UIS_MOD:    Python ✅ 4,779 | R ✅ 4,779 | Stata ✅ 4,779
MG_NEW_INTERNAL_DISP:   Python ✅ 3,616 | R ❌ 404   | Stata ✅ 3,616
NT_ANT_WHZ_NE3:         Python ✅ 2,904 | R ✅ 2,904 | Stata ✅ 16,969
```

**Pattern**: Only R fails, only on COD_DENGUE and MG_NEW_INTERNAL_DISP

## Recommended Next Steps

### Immediate Investigation
1. **Check R package version** - Upgrade to latest unicefData if available
2. **Add detailed logging** - Modify R script to log exact URL being requested
3. **Test with different User-Agents** - See if UA is the issue
4. **Check UNICEF API documentation** - Look for API-level restrictions on these indicators

### Code-Level Fixes
1. **Add User-Agent override** in unicef_core.R fetch_sdmx_text():
   ```r
   ua_override <- user_agent("R-unicefData/1.0.0")
   ```

2. **Add detailed error logging** to capture the 404 URL:
   ```r
   if (identical(status, 404L)) {
       message(sprintf("DEBUG: 404 from URL: %s", url))
       # ... continue with fallback logic
   }
   ```

3. **Implement explicit dataflow fallback**:
   ```r
   if (is_404_response) {
       try_alternate_dataflow()
   }
   ```

### Data Workaround
Until R package issue is fixed, could:
1. Fetch COD_DENGUE and MG_NEW_INTERNAL_DISP via Python or Stata
2. Cache results for R validator
3. Mark as "R-unavailable" in validation reports

## Files for Reference

- **Diagnostic script**: `validation/scripts/diagnose_r_failures.R`
- **Validation results**: `logs/validation/indicator_validation_20260113_114637/`
  - Python results: `python/success/COD_DENGUE.csv` (70 rows)
  - R results: Empty tibble (0 rows)
  - Stata results: Both indicators successful

## Conclusion

The R validator is experiencing an **HTTP 404 error** specifically on these two indicators. While Python and Stata successfully retrieve the data, R's `httr` client is not able to construct the proper API request, or UNICEF's API is rejecting the R client for these specific indicators.

**This is NOT a data availability issue** (Python proves the data exists), but rather a **client-specific API communication issue** with the R implementation.

**Severity**: Low - Only affects 2 of 34 indicators (94% success rate), and Python/Stata alternatives exist.

**Next Step**: Add detailed URL logging to see what R is actually requesting when it gets 404.

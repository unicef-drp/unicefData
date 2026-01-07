# unicefdata QA — Critical Failures Summary

This document tracks current critical test failures from the automated suite. It summarizes symptoms, impact, likely causes, and suggested fixes.

## Ado Version and Suite
- Ado Version: 1.5.2 (extracted from unicefdata.ado)
- Test Suite: 1.5.1

## DL-05 — Disaggregation Filters (P0)
- Symptom: "Unexpected quintiles (Q2/Q3/Q4) found."
- Impact: Incorrect attribute filtering undermines disaggregated analyses, potentially contaminating totals with subgroup values.
- Likely Causes:
  - YAML schema/codelist mismatch (DL-04 must pass for DL-05 to validate).
  - `attributes()` filtering not applied consistently across sex/age/wealth/residence/matedu.
- Suggested Fixes:
  - Validate codelists from YAML; ensure codes match expected tokens (`_T`, `_Q1.._Q5`, etc.).
  - Apply attribute filters before reshape; default `_T` when attributes unspecified; re-test.

## MULTI-01 — wide_indicators (P1)
- Symptom: "Missing indicator columns after wide_indicators."
- Impact: Multi-indicator pivot fails; workflows requiring indicator columns break.
- Likely Causes:
  - Duplicate rows blocking `reshape wide`.
  - Default attributes not constrained to `_T` totals.
  - Post-reshape rename not executed when reshape fails.
- Suggested Fixes:
  - Drop duplicates on `iso3 country period indicator` before reshape.
  - When `attributes` is empty, filter `_T` across available disaggregations.
  - Ensure `reshape wide value, i(iso3 country period) j(indicator) string` followed by removing `value` prefix.

## EDGE-03 — Special-character Country Names (P2)
- Symptom: "Country name lost special characters."
- Impact: Label integrity issues; cross-platform parity affected.
- Likely Causes:
  - Encoding/Unicode handling in import or display; lossy conversions.
- Suggested Fixes:
  - Preserve Unicode across import; avoid lossy case conversion and SMCL paths altering literal text.

## PERF-01 — Medium Batch Performance (P2)
- Symptom: "Runtime exceeds 60s."
- Impact: Performance regression affects batch runs and CI stability.
- Likely Causes:
  - Network latency; large `page_size`; repeated metadata lookups; verbose overhead.
- Suggested Fixes:
  - Tune `page_size`; reduce `verbose`; cache YAML reads; minimize retries; narrow year ranges for performance checks.

## XPLAT-01 — Cross-Platform YAML Counts (CRITICAL)
- Symptom: "Could not parse country counts from YAML files."
- Impact: Cross-platform consistency cannot be verified.
- Likely Causes:
  - Missing/incorrect YAML paths; parse errors; inconsistent YAML formatting.
- Suggested Fixes:
  - Verify YAML files exist; run metadata sync; normalize Windows paths; align parsers.

## XPLAT-04 — Country Code Consistency (CRITICAL)
- Symptom: "Some countries missing from metadata YAML files."
- Impact: Inconsistent codelists; joins and filters may fail.
- Likely Causes:
  - Out-of-date or partial YAML; mismatched code keys across stacks.
- Suggested Fixes:
  - Regenerate/sync metadata YAML; ensure test countries are present across Python/R/Stata.

## Network Implementation: curl & User-Agent (v1.5.2)

All HTTP requests now use **curl with proper User-Agent identification**:

```stata
* All copy operations now use curl for robust network handling
* User-Agent header: "unicefdata/1.5.2 (Stata)"
* Fallback: Stata's import delimited if curl not available
* Benefits:
*   - Better SSL/TLS and proxy support
*   - Reduced API rate-limiting
*   - Automatic retries on transient failures
*   - Cross-platform (Windows/Mac/Linux) consistency
```

**Implementation:**
- `copy "URL" "file", replace public curl user_agent("unicefdata/1.5.2 (Stata)")`
- Transparent to users—no syntax changes
- YAML metadata fetches also use curl

## Notes
- TRANS-01 (Wide reshape) previously blocked by ado load error; ado structure fixed and wide logic kept (alias_id + `yr####`). TRANS-01 now **PASSES**.
- MULTI-01 (wide_indicators) fixed in v1.5.2: missing indicator columns now created automatically. **NOW PASSES**.

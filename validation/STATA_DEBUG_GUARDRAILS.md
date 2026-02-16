# Stata Validation Debug Guardrails (Seed-42 Baseline)

Purpose: Provide a reproducible, drift-resistant checklist for debugging Stata runs in the UNICEF indicator validation pipeline, using the Python validator as the benchmark for expected behavior.

## Goals
- Ensure every Stata test produces a definitive artifact (success CSV or error marker) — no silent failures.
- Eliminate encoding issues and broken SMCL/quoting that interrupt runs.
- Align Stata outputs with Python expectations for counts, file locations, and naming.
- Maintain reproducibility via seeds and stable sampling.

## Benchmark: Python Validator Contract
- Loads indicators and performs stratified sampling (`--limit`, `--random-stratified`, `--seed`).
- For each language, writes to results/`indicator_validation_YYYYMMDD_HHMMSS` with:
  - SUMMARY.md
  - detailed_results.csv/json
  - `python/|r/|stata/` folders with `success/` and `failed/` artifacts.
- Expected Stata behavior: mirror Python contract (artifact per test, consistent paths).

## Runner Contract (Stata)
- Batch path (Windows): `C:\Program Files\Stata17\StataMP-64.exe`
- Invoke: `/e do path\to\script.do`
- Do-file requirements:
  - `clear all`
  - `set more off`
  - `discard`
  - Configure ado paths (add project `src/` if needed)
  - Open **text** logs: `log using path, text replace`
  - On success: `export delimited using path_to_csv, replace`
  - On failure: write an `.error` file (e.g., `file write` or `capture` + `postfile`), then `exit` with non-zero code is optional (collector reads artifact).

## Logging & Encoding
- Use text logs: `log using ..., text replace`
- Avoid non-ASCII characters in logs and delimited outputs; prefer plain ASCII.
- If metadata includes SMCL/URLs, guard display:
  - Display with compound quotes: `noi di in smcl `"{p 4 4}{opt Note}: `note'{p_end}"'`
- Python harness must read Stata artifacts with UTF‑8; if Windows locale conflicts, enforce UTF‑8 in the reader.

## Quoting Guardrails (Critical)
- Compound quotes for any displayed text that may contain SMCL or embedded quotes.
- Simple quotes for extended macro functions (tokenization):
  - Correct: `local w : word `i' of `text'`
  - Incorrect: `: word `i' of `"text"'` (treats entire string as one word)
- Store original tokens before transforming text (URLs → `{browse}`), then iterate.

## Graceful Error Artifacts
- If API returns 404 or a domain placeholder (e.g., EDUCATION, NUTRITION), generate a failure artifact:
  - `file open f using path_to_error, write replace`
  - `file write f "status=failed reason=not_found" _n`
  - `file close f`
- Never leave runs without an output file; collectors depend on presence of success/failed artifacts.

## Sampling Hygiene
- Maintain stratified sampling across dataflow prefixes.
- For Stata invocation, skip known non-indicator domain stubs (EDUCATION, NUTRITION, FUNCTIONAL_DIFF, GENDER, HIV_AIDS, IMMUNISATION, TRGT) or ensure wrapper handles them with failure artifacts.
- Use `--seed` for reproducibility (e.g., `42`).

## Procedures

### 1) Smoke Test (Runner Integrity)
- Create a minimal do-file that writes a 1-row CSV and a text log into `results/stata/success/`.
- Run via StataMP batch and confirm the Python validator records a success.

### 2) Per‑Indicator Debug (Failing Cases)
- Focus examples: `ED_SE_LPV_PRIM`, `EDUCATION`, `TRGT_2030_ED_READ_L1`.
- In do-file:
  - `clear all`
  - `set more off`
  - `set trace on`
  - `discard`
  - Configure `adopath` to include project `src/`
  - Open text log
  - Run indicator retrieval
  - On exception, write `.error` artifact

### 3) Encoding Fix
- For cases like `NT_BF_EIBF` (charmap decode), ensure Stata outputs are ASCII-friendly and Python readers use UTF‑8.
- Avoid writing SMCL in delimited outputs; keep SMCL only in display logs.

### 4) Quoting Audit
- Review helper ado files (e.g., `_query_metadata.ado`, `_website.ado`) for correct quoting per guardrails.
- Validate with `set trace on` that tokens and displays are correct.

### 5) Re-run & Compare
- Execute seed‑42 stratified validation again.
- Compare new `SUMMARY.md` to baseline at `indicator_validation_20260112_164439`:
  - Fewer "No output file created"
  - No encoding errors
  - Clear failure reasons for 404s/domain stubs.

## Command Snippets

Monitor a running test:
```powershell
cd C:\GitHub\myados\unicefData\validation
Get-Content test_30_stratified_seed42.log -Tail 50 -Wait
```

Run a reproducible stratified test:
```powershell
python test_all_indicators_comprehensive.py --limit 30 --random-stratified --seed 42 2>&1 | Tee-Object -FilePath test_30_stratified_seed42.log
```

Batch-run a Stata do-file:
```powershell
& "C:\Program Files\Stata17\StataMP-64.exe" /e do C:\GitHub\myados\unicefData\validation\debug_indicator.do
```

## Success Criteria
- Each indicator test yields either a success CSV or a failure artifact.
- Zero encoding (`charmap`) errors during collection.
- Stata failures are traceable (logs) and categorized (404, domain stub, ado error).
- Python, R, and Stata summaries align on counts and statuses for valid indicators.

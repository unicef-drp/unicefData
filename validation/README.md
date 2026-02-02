# UNICEF Data Validation Framework

Cross-platform validation suite for the `unicefData` package (R, Python, Stata).

## Quick Start

```bash
# Run validation with 60 random indicators, all platforms
cd validation/scripts
python test_all_indicators_comprehensive.py --limit 60 --random-stratified --seed 42 --valid-only
```

## Directory Structure

```
validation/
├── run_validation.py            # Single entry point for full validation
├── scripts/
│   ├── core_validation/         # Comprehensive validation + runners
│   ├── metadata_sync/           # Metadata/sdmx schema sync + checks
│   ├── issue_validity/          # Issue validity checker + docs
│   ├── orchestration/           # Orchestrators that fan out to suites
│   ├── platform_tests/          # Per-language suites + smoke tests
│   └── _archive/                # Deprecated/one-off scripts
├── cache/                       # Cached API responses (Python, R, Stata)
├── docs/                        # Additional documentation
├── metadata/                    # Indicator metadata utilities
└── _archive/                    # Archived debug/investigation scripts
```

## Core Scripts (by folder)

### Entry points

| Location | Purpose |
|----------|---------|
| `run_validation.py` | Preferred launcher; delegates to `scripts/core_validation/test_all_indicators_comprehensive.py` |
| `scripts/orchestration/orchestrator_indicator_tests.py` | Alternate orchestrator wrapper |

### Core validation (`scripts/core_validation/`)

| Script | Purpose |
|--------|---------|
| `test_all_indicators_comprehensive.py` | **PRIMARY** - Cross-platform validation with caching, stratified sampling, reproducibility |
| `valid_indicators_sampler.py` | Stratified random sampling of indicators |
| `cache_manager.py` | Manages API response cache |
| `cached_test_runners.py` | Platform-specific test runners with caching |
| `validate_cross_language.py` | Cross-language result comparison |

### Metadata sync (`scripts/metadata_sync/`)

| Script | Purpose |
|--------|---------|
| `orchestrator_metadata.py` | Orchestrates metadata sync across platforms |
| `sync_metadata_python.py` | Sync indicator metadata for Python |
| `sync_metadata_r.R` | Sync indicator metadata for R |
| `sync_metadata_stata.do` | Sync indicator metadata for Stata |
| `sync_metadata_stataonly.do` | Sync for Stata-only indicators |
| `check_dataflows.py` | Dataflow coverage checks |
| `check_sdmx_structure.py` | SDMX structure validation |
| `check_tier_preservation.py` | Tier preservation checks |

### Issue validity checker (`scripts/issue_validity/`)

| Script | Purpose |
|--------|---------|
| `check_issues_validity.py` | Validates CROSS_PLATFORM_DATASET_SCHEMA_ISSUES.md items |
| `run_issue_validity_check.ps1` | PowerShell launcher |
| `IMPLEMENTATION_COMPLETE_REPORT.md` | Full technical doc |
| `ISSUE_VALIDITY_CHECKER_SUMMARY.md` | User guide |
| `ISSUES_VALIDITY_QUICK_REFERENCE.md` | Quick reference |
| `CHECK_ISSUES_VALIDITY_README.md` | Additional notes |

### Platform suites (`scripts/platform_tests/`)

| Script | Purpose |
|--------|---------|
| `test_indicator_suite.R` | R-specific indicator test suite |
| `test_indicator_suite.do` | Stata-specific indicator test suite |
| `stata_smoke_test.do` | Quick Stata connectivity test |
| `stata_diagnostic.do` | Stata diagnostic utilities |

## Usage Examples

### Full Validation Run

```bash
# 60 indicators, all platforms, reproducible with seed
python test_all_indicators_comprehensive.py \
    --limit 60 \
    --random-stratified \
    --seed 42 \
    --valid-only

# Results saved to: logs/validation/indicator_validation_YYYYMMDD_HHMMSS/
```

### Platform-Specific Testing

```bash
# Python only
python test_all_indicators_comprehensive.py --limit 30 --languages python

# R only
python test_all_indicators_comprehensive.py --limit 30 --languages r

# Stata only
python test_all_indicators_comprehensive.py --limit 30 --languages stata
```

### Metadata Sync

```bash
# Sync all platforms
python orchestrator_metadata.py

# Individual platforms
python sync_metadata_python.py
Rscript sync_metadata_r.R
stata-mp -b do sync_metadata_stata.do
```

## Archived Scripts (_archive/)

These scripts were used during development/debugging and are preserved for reference.
They are **not required** for normal validation operations.

### Debug/Diagnostic Tools

| Script | Original Purpose | Why Archived |
|--------|------------------|--------------|
| `debug_python_urls.py` | Debug Python URL construction | Issue resolved |
| `diagnose_r_failures.R` | Diagnose R-specific failures | Issue resolved |
| `python_verbose_http_trace.py` | Trace HTTP requests (Python) | Debugging complete |
| `r_verbose_http_trace.R` | Trace HTTP requests (R) | Debugging complete |
| `stata_verbose_http_trace.do` | Trace HTTP requests (Stata) | Debugging complete |
| `compare_http_requests.R` | Compare R vs Python requests | Debugging complete |
| `r_vs_python_diagnostic.R` | R/Python comparison diagnostic | Debugging complete |
| `analyze_dataflows.py` | Analyze dataflow patterns | Analysis complete |
| `analyze_stata_failures.py` | Analyze Stata failures | Issue resolved |

### Issue-Specific Tests

| Script | Original Purpose | Why Archived |
|--------|------------------|--------------|
| `test_3_failing.py` | Test 3 specific failing indicators | Issue resolved |
| `test_cod_fix.R` | Test COD indicator fix | Fix verified |
| `test_python_cod.py` | Test Python COD handling | Fix verified |
| `test_stata_404.py` | Test Stata 404 handling | Issue resolved |
| `test_api_directly.R` | Direct API testing | Replaced by comprehensive suite |
| `test_single_indicator.do` | Single indicator test | Replaced by comprehensive suite |
| `test_single_stata.py` | Single Stata test | Replaced by comprehensive suite |
| `_test_stata_fallback.do` | Test fallback mechanism | Feature complete |
| `test_pt_cm_manual.do` | Manual PT_CM test | One-time test |

### Example/Demo Scripts

| Script | Original Purpose | Why Archived |
|--------|------------------|--------------|
| `example_caching_workflow.py` | Demonstrate caching | Documentation purpose only |
| `orchestrator_examples.py` | Orchestrator examples | Documentation purpose only |
| `quick_start_indicator_validation.py` | Quick start guide | Superseded by comprehensive |
| `sync_examples_*.{py,R,do}` | Sync examples | Documentation purpose only |
| `validate_outputs.py` | Output validation | Integrated into main suite |

### Superseded Scripts

| Script | Replaced By |
|--------|-------------|
| `test_all_indicators_with_cache.py` | `test_all_indicators_comprehensive.py` |
| `orchestrator_*.ps1` | Python orchestrators |
| `run_validation.ps1` | `test_all_indicators_comprehensive.py` |

### Investigation Reports

Located in `_archive/investigation_reports/`:

| Document | Content |
|----------|---------|
| `INVESTIGATION_REPORT.md` | Root cause analysis of validation failures |
| `QUICK_FIX_GUIDE.md` | Quick fixes for common issues |
| `R_DATAFLOW_ISSUE_ANALYSIS.md` | Analysis of R dataflow handling |

## Cache Structure

```
cache/
├── python/           # Python API response cache (.json)
├── r/                # R API response cache (.rds, .json)
├── stata/            # Stata API response cache (.dta, .json)
├── python_metadata.json
├── r_metadata.json
└── stata_metadata.json
```

## Output Structure

Validation runs create timestamped output directories:

```
logs/validation/indicator_validation_YYYYMMDD_HHMMSS/
├── SUMMARY.md              # Human-readable summary
├── detailed_results.csv    # Full results table
└── detailed_results.json   # Machine-readable results
```

## Requirements

- Python 3.8+ with `pandas`, `requests`, `pyyaml`
- R 4.0+ with `unicefData` package installed
- Stata 14+ with `unicefdata` command installed

## Understanding Indicator Tier Classification

**Important**: Validation results must be interpreted with **indicator tier classification** in mind.

### Tier 1: Data Available ✅
- Officially defined indicators with data available
- **Expected validation result**: Query returns data, output file created
- **Failed validation**: Query succeeds but returns no data (investigate)

### Tier 2: Officially Defined, No Data ⚠️
- Indicators with metadata but no current data (e.g., future planned indicators)
- **Expected validation result**: Query returns 0 rows, NO output file created
- **This is NOT a failure** - it's expected behavior

### Tier 3: Under Development 🔍
- Proposed indicators still in development
- Behavior may vary; check metadata for status

**Example**: 
- `ED_LN_R_L2` (Reading proficiency, lower secondary) = **TIER 2**
- `NT_ANT_BAZ_NE2` (BMI-for-age <-2 SD) = **TIER 2**
- Both have `dataflows: [nodata]` → No data to query

### See Also
- [INDICATOR_TIER_CLASSIFICATION.md](./docs/INDICATOR_TIER_CLASSIFICATION.md) - Detailed tier reference
- [TIER_CLASSIFICATION_ANALYSIS.md](./results/20260120/TIER_CLASSIFICATION_ANALYSIS.md) - January 20 validation analysis with tier context
- Source metadata: `../stata/src/_/_unicefdata_indicators_metadata.yaml`

## Troubleshooting

1. **Cache issues**: Delete `cache/` folder and re-run
2. **R not found**: Ensure `Rscript` is in PATH
3. **Stata not found**: Set `STATA_PATH` environment variable
4. **API timeout**: Increase timeout in `cached_test_runners.py`
5. **Indicator marked as "failed" but has no data**: Check if it's a TIER 2 indicator in `_unicefdata_indicators_metadata.yaml`

---

*Last updated: January 20, 2026*

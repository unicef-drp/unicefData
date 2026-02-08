# Validation Scripts Structure Map

**Last Updated:** January 20, 2026  
**Purpose:** Document all scripts in `validation/scripts/` after reorganization into subfolders.

---

## Directory Structure Overview

```
validation/
├── run_validation.py                ← ENTRY POINT (wrapper script)
├── SCRIPTS_STRUCTURE_MAP.md         ← This file
└── scripts/
    ├── core_validation/             ← Main validation engine
    ├── orchestration/               ← Orchestrators & runners
    ├── metadata_sync/               ← Metadata fetching & syncing
    ├── issue_validity/              ← Issue tracking & validation
    ├── platform_tests/              ← Platform-specific smoke tests
    ├── diagnostics/                 ← Diagnostic tools (empty)
    ├── _archive/                    ← Legacy & debug scripts (40+ files)
    └── __pycache__/
```

---

## 1. CORE VALIDATION (`scripts/core_validation/`)

**Purpose:** Main validation engine - tests indicators across platforms with intelligent caching.

| File | Type | Description | Key Features |
|------|------|-------------|--------------|
| **test_all_indicators_comprehensive.py** | Python | Main test orchestrator - loads indicators, validates across Python/R/Stata | • Intelligent caching system<br/>• Cross-platform validation<br/>• Stratified sampling by dataflow<br/>• Detailed per-indicator logging<br/>• ~1854 lines |
| **valid_indicators_sampler.py** | Python | Indicator sampling utility with stratified selection | • Groups by dataflow prefix (18 prefixes)<br/>• Proportional allocation with min 1/prefix<br/>• Verbose logging of allocation<br/>• Random seed support |
| **cached_test_runners.py** | Python | Test execution runners with caching support | • Python/R/Stata test execution<br/>• Cache integration<br/>• Error handling per platform |
| **cache_manager.py** | Python | Cache management and persistence | • Manages validation/cache/{platform}/ folders<br/>• TTL & staleness tracking<br/>• Cache hit/miss statistics |
| **validate_cross_language.py** | Python | Cross-language output comparison | • Compares Python vs R vs Stata outputs<br/>• Dimension matching<br/>• Row count validation |

**How It Works:**
```
test_all_indicators_comprehensive.py (main loop)
├── Load indicators from metadata (645 valid indicators)
├── Apply sampling (stratified or sequential)
├── For each sampled indicator:
│   ├── Check cache (Python/R/Stata)
│   ├── If not in cache:
│   │   ├── Execute Python test
│   │   ├── Execute R test
│   │   └── Execute Stata test
│   ├── Save results to cache
│   └── Log output (per-indicator + summary)
└── Generate reports (CSV, JSON, MD)
```

---

## 2. ORCHESTRATION (`scripts/orchestration/`)

**Purpose:** Thin wrappers and orchestrators for test execution.

| File | Type | Description |
|------|------|-------------|
| **orchestrator_indicator_tests.py** | Python | Main orchestrator - passes args to test_all_indicators_comprehensive.py |

**Key Relationship:**
```
run_validation.py (wrapper in validation/ root)
    ↓
orchestrator_indicator_tests.py (thin pass-through)
    ↓
test_all_indicators_comprehensive.py (actual logic)
```

---

## 3. METADATA SYNC (`scripts/metadata_sync/`)

**Purpose:** Fetch and synchronize metadata (dataflows, indicators, codelists).

| File | Type | Description | Purpose |
|------|------|-------------|---------|
| **sync_metadata_python.py** | Python | Fetch metadata via Python/SDMX | • Dataflows from UNICEF.SDMX<br/>• Indicator codelists<br/>• Countries/regions<br/>• Outputs: `_unicefdata_*.yaml` |
| **sync_metadata_r.R** | R | Fetch metadata via R API | • R bindings to metadata fetching<br/>• Cache control<br/>• Cross-platform consistency |
| **sync_metadata_stata.do** | Stata | Fetch metadata via Stata API | • Stata bindings<br/>• YAML parsing<br/>• Cache integration |
| **sync_metadata_stataonly.do** | Stata | Stata-only metadata refresh | • Standalone Stata metadata update |
| **orchestrator_metadata.py** | Python | Orchestrator for metadata syncing | • Coordinates Python/R/Stata metadata updates<br/>• Validation/comparison |
| **check_dataflows.py** | Python | Validate dataflow structure | • Checks DSDs (Data Structure Definitions)<br/>• Validates dimensions/attributes |
| **check_sdmx_structure.py** | Python | SDMX structure validation | • Validates SDMX API responses<br/>• Checks for breaking changes |
| **check_tier_preservation.py** | Python | Validates Tier 1 classification | • Ensures tier 1 indicators preserved<br/>• Tracks tier changes across versions |

---

## 4. ISSUE VALIDITY (`scripts/issue_validity/`)

**Purpose:** Track and validate known issues in indicator validation.

| File | Type | Description |
|------|------|-------------|
| **check_issues_validity.py** | Python | Main issue checker - compares across platforms to validate if issues are fixed |
| **run_issue_validity_check.ps1** | PowerShell | Windows wrapper for issue validity checks |
| **ISSUES_VALIDITY_QUICK_REFERENCE.md** | Markdown | Quick reference guide for issue validity checker |
| **CHECK_ISSUES_VALIDITY_README.md** | Markdown | Detailed documentation of issue checking framework |
| **ISSUE_VALIDITY_CHECKER_SUMMARY.md** | Markdown | Summary of what gets checked |
| **IMPLEMENTATION_COMPLETE_REPORT.md** | Markdown | Report on implementation status |

**Tracks Issues:**
- Stata duplicate columns
- Missing dimensions (Python/R)
- Row count mismatches across platforms
- UTF-8 encoding problems

**Quick Usage:**
```powershell
cd C:\GitHub\myados\unicefData-dev\validation\scripts\issue_validity
.\run_issue_validity_check.ps1
```

---

## 5. PLATFORM TESTS (`scripts/platform_tests/`)

**Purpose:** Platform-specific smoke tests and diagnostics.

| File | Type | Description |
|------|------|-------------|
| **stata_diagnostic.do** | Stata | Diagnostics for Stata environment setup |
| **stata_smoke_test.do** | Stata | Quick smoke test in Stata |
| **test_indicator_suite.do** | Stata | Suite of indicator tests for Stata |
| **test_indicator_suite.R** | R | Suite of indicator tests for R |

---

## 6. DIAGNOSTICS (`scripts/diagnostics/`)

**Purpose:** Reserved for diagnostic tools (currently empty).

**Planned Use:** Analysis tools, debugging scripts, performance profiling.

---

## 7. ARCHIVE (`scripts/_archive/`)

**Purpose:** Legacy, debug, and experimental scripts (40+ files).

### Key Groups:

**Fetch/Sync Examples:**
- `fetch_*.log` (10 files) - Log files from API fetch operations
- `sync_examples_*.{py,R,do}` - Example sync operations per platform
- `orchestrator_examples.py` - Example orchestrator calls

**Testing & Debugging:**
- `test_*.py` / `test_*.R` / `test_*.do` (25+ files) - Various single-indicator tests
- `quick_*.py` - Quick validation scripts
- `debug_*.py` - Debugging helpers
- `analyze_*.py` / `diagnose_*.R` - Analysis scripts
- `compare_*.{py,R,do}` - Cross-platform comparisons
- `*_verbose_*.{py,R,do}` - HTTP trace and verbose output scripts

**HTTP/URL Tracing:**
- `python_verbose_http_trace.py`
- `r_verbose_http_trace.R`
- `stata_verbose_http_trace.do`

**Validation Scripts:**
- `test_unified_fallback_validation.py`
- `validate_outputs.py`
- `URL_CONSTRUCTION_NOTES.R`

**Investigation Reports:**
- `investigation_reports/` - Subfolder with detailed investigation logs

**Status:** These are kept for reference but should NOT be used for current validation runs. Use the organized scripts in other folders instead.

---

## Call Graph: How Scripts Connect

```
ENTRY POINT
============
validation/run_validation.py
    │
    └──→ ArgumentParser (accepts flags like --limit, --random-stratified, --seed)
         │
         └──→ orchestration/orchestrator_indicator_tests.py
              │
              └──→ core_validation/test_all_indicators_comprehensive.py
                   │
                   ├──→ valid_indicators_sampler.py (sample selection)
                   │
                   ├──→ cache_manager.py (cache lookups)
                   │
                   ├──→ cached_test_runners.py (execution)
                   │
                   └──→ validate_cross_language.py (result comparison)

ISSUE VALIDITY CHECKS
=====================
issue_validity/run_issue_validity_check.ps1
    │
    └──→ issue_validity/check_issues_validity.py
         │
         └──→ core_validation/cached_test_runners.py (fetch test data)

METADATA UPDATES
================
metadata_sync/orchestrator_metadata.py
    │
    ├──→ metadata_sync/sync_metadata_python.py
    ├──→ metadata_sync/sync_metadata_r.R
    └──→ metadata_sync/sync_metadata_stata.do
```

---

## Common Operations

### Run Basic Validation (10 indicators, all platforms)
```bash
cd C:\GitHub\myados\unicefData-dev\validation
python run_validation.py --limit 10
```

### Run Stratified Sampling (proportional across dataflows)
```bash
python run_validation.py --limit 30 --random-stratified --seed 42
```

### Run Specific Languages
```bash
python run_validation.py --limit 20 --languages python r
```

### Use Cache (skip if data already fetched)
```bash
python run_validation.py --limit 50
```

### Force Fresh Data (re-fetch all)
```bash
python run_validation.py --limit 10 --force-fresh
```

### Check Known Issues
```bash
cd scripts/issue_validity
.\run_issue_validity_check.ps1
```

### Update Metadata
```bash
cd scripts/metadata_sync
python orchestrator_metadata.py
```

---

## File Organization Best Practices

| Category | Location | Use |
|----------|----------|-----|
| **Main Tests** | `core_validation/` | Active validation runs |
| **Orchestration** | `orchestration/` | Entry points & coordination |
| **Metadata** | `metadata_sync/` | Data freshness & syncing |
| **Issue Tracking** | `issue_validity/` | Regression detection |
| **Platform Smoke Tests** | `platform_tests/` | Quick environment checks |
| **Legacy/Debug** | `_archive/` | Reference only (DO NOT USE) |
| **Empty/Reserved** | `diagnostics/` | Future expansion |

---

## Maintenance Notes

### Adding New Validation Scripts
1. Place in appropriate subfolder (typically `core_validation/`)
2. Use consistent naming: `validate_*.py`, `test_*.py`, etc.
3. Update this map with description
4. Ensure integration with cache_manager.py
5. Add to core orchestrator if needed

### Cleanup Candidates (in _archive/)
- Old test files that have been superseded
- Debug scripts older than 3 months
- Experimental features that won't be used
- Duplicate implementations

**Note:** Check timestamps before deleting from _archive/.

### Performance Considerations
- **Stratified sampling**: ~18-45 samples depending on target (all prefixes guaranteed minimum 1)
- **Cache hits**: First run ~10-30 min (all downloads), subsequent ~2-5 min
- **Cross-language comparison**: Adds ~20% overhead to validation time
- **Issue validity checks**: ~10-15 min for full check

---

## Summary Table: All Folders

| Folder | Files | Status | Use |
|--------|-------|--------|-----|
| **core_validation/** | 5 | ✅ Active | Main validation engine |
| **orchestration/** | 1 | ✅ Active | Entry point orchestration |
| **metadata_sync/** | 8 | ✅ Active | Data freshness |
| **issue_validity/** | 6 | ✅ Active | Regression detection |
| **platform_tests/** | 4 | ⚠️ Occasional | Platform-specific checks |
| **diagnostics/** | 0 | 📋 Reserved | Future diagnostic tools |
| **_archive/** | 40+ | ❌ Legacy | Reference only |
| **__pycache__/** | ? | 🔧 Auto | Python cache |

**Total Active Production Scripts:** ~28  
**Total Reference/Legacy Scripts:** ~45  
**Total Organized:** ~73


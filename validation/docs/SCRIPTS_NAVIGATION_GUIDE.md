# Validation Scripts - Navigation Guide

**TL;DR:** All validation scripts organized into 5 folders. See the three maps for complete documentation.

---

## 📚 Three Key Documentation Files

| File | Purpose | Use When |
|------|---------|----------|
| **[SCRIPTS_STRUCTURE_MAP.md](SCRIPTS_STRUCTURE_MAP.md)** | Complete inventory of all scripts with descriptions | You need to know what a script does or where to find it |
| **[DIRECTORY_TREE.md](DIRECTORY_TREE.md)** | Visual tree structure with quick reference | You want a visual overview or quick command reference |
| **[FUNCTIONAL_DEPENDENCIES.md](FUNCTIONAL_DEPENDENCIES.md)** | How scripts connect and data flows | You need to understand how components interact |

---

## 🎯 Quick Navigation by Task

### Running Validation
```bash
cd C:\GitHub\myados\unicefData-dev\validation
python run_validation.py --limit 10
```
**Learn More:** [SCRIPTS_STRUCTURE_MAP.md#call-graph](SCRIPTS_STRUCTURE_MAP.md#call-graph-how-scripts-connect) → Core Validation section

### Checking Known Issues
```bash
cd scripts/issue_validity
.\run_issue_validity_check.ps1
```
**Learn More:** [SCRIPTS_STRUCTURE_MAP.md#issue-validity](SCRIPTS_STRUCTURE_MAP.md#4-issue-validity-scriptsissue_validity) → Issue Validity section

### Updating Metadata
```bash
cd scripts/metadata_sync
python orchestrator_metadata.py
```
**Learn More:** [SCRIPTS_STRUCTURE_MAP.md#metadata-sync](SCRIPTS_STRUCTURE_MAP.md#3-metadata-sync-scriptsjsmetadata_sync)

### Understanding How Scripts Connect
**Read:** [FUNCTIONAL_DEPENDENCIES.md#execution-flow](FUNCTIONAL_DEPENDENCIES.md#1-execution-flow-when-user-runs-python-run_validationpy---limit-30---random-stratified)

### Finding a Specific Script
**See:** [DIRECTORY_TREE.md](DIRECTORY_TREE.md) or [SCRIPTS_STRUCTURE_MAP.md#summary-table](SCRIPTS_STRUCTURE_MAP.md#summary-table-all-folders)

---

## 📁 Folder Organization

### Production Folders (Use These)

**`core_validation/`** - Main validation engine
- `test_all_indicators_comprehensive.py` - Core orchestrator
- `valid_indicators_sampler.py` - Stratified sampling
- `cache_manager.py` - Caching system
- `cached_test_runners.py` - Test execution
- `validate_cross_language.py` - Cross-platform comparison

**`orchestration/`** - Entry points
- `orchestrator_indicator_tests.py` - Wrapper

**`metadata_sync/`** - Data freshness
- `sync_metadata_python.py` - Fetch via Python
- `sync_metadata_r.R` - Fetch via R
- `sync_metadata_stata.do` - Fetch via Stata
- `orchestrator_metadata.py` - Orchestrator
- Various `check_*.py` - Validation checks

**`issue_validity/`** - Regression detection
- `check_issues_validity.py` - Issue checker
- `run_issue_validity_check.ps1` - Windows wrapper
- Various `.md` - Documentation

**`platform_tests/`** - Quick checks
- `stata_smoke_test.do` - Stata quick test
- `test_indicator_suite.do` - Stata full suite
- `test_indicator_suite.R` - R full suite

### Reference Folders (Don't Use)

**`_archive/`** - Legacy scripts (40+ files)
- Old tests, debug scripts, examples
- Keep for reference, don't run in production

**`diagnostics/`** - Reserved (empty)
- For future diagnostic tools

---

## 🚀 Common Operations

### 1. Basic Validation
```bash
python run_validation.py --limit 10
```
Tests 10 indicators sequentially across Python/R/Stata.

### 2. Stratified Sampling
```bash
python run_validation.py --limit 30 --random-stratified --seed 42
```
Samples ~36-45 indicators (min 1 per dataflow prefix) across 18 dataflow groups.

**Learn More:** [FUNCTIONAL_DEPENDENCIES.md#2-sampling-system](FUNCTIONAL_DEPENDENCIES.md#2-sampling-system-stratified-vs-sequential)

### 3. Test Specific Languages
```bash
python run_validation.py --limit 20 --languages python r
```
Tests only Python and R (skip Stata).

### 4. Use Cache
```bash
python run_validation.py --limit 50
```
Automatically uses cached results if < 7 days old.

### 5. Force Fresh Data
```bash
python run_validation.py --limit 10 --force-fresh
```
Ignores cache, re-fetches from API.

### 6. Check Issues
```bash
cd scripts/issue_validity
.\run_issue_validity_check.ps1
```
Validates that known issues are fixed or still present.

**Learn More:** [SCRIPTS_STRUCTURE_MAP.md#4-issue-validity](SCRIPTS_STRUCTURE_MAP.md#4-issue-validity-scriptsissue_validity)

### 7. Update Metadata
```bash
cd scripts/metadata_sync
python orchestrator_metadata.py
```
Fetches latest dataflows, indicators, countries from SDMX API.

### 8. Platform Diagnostics
```bash
cd scripts/platform_tests
# For Stata:
do stata_diagnostic.do
# For R:
Rscript test_indicator_suite.R
```

---

## 🔍 Understanding the System

### Key Concepts

**Stratified Sampling:** Ensures all 18 dataflow prefixes are represented in tests
- CME, COD, DM, ECD, ECON, ED, FD, GN, HVA, IM, MG, MNCH, NT, PT, PV, SPP, WS, WT
- Proportional allocation: larger dataflows get more samples
- Minimum 1 per prefix guarantee

**Intelligent Caching:** Avoids redundant API calls
- Caches in: `validation/cache/{python,r,stata}/`
- TTL: 7 days per cache item
- Tracks: timestamp, row count, SHA256

**Cross-Language Validation:** Compares outputs across platforms
- Checks dimensions match
- Verifies row counts align
- Detects platform-specific issues

### Data Flow

```
run_validation.py (entry point)
    ↓
orchestrator_indicator_tests.py (wrapper)
    ↓
test_all_indicators_comprehensive.py (core logic)
    ├─ Load indicators from metadata
    ├─ Sample (stratified or sequential)
    ├─ For each indicator:
    │  ├─ Check cache
    │  ├─ Test Python/R/Stata
    │  ├─ Compare results
    │  └─ Log output
    └─ Generate reports
```

**Learn More:** [FUNCTIONAL_DEPENDENCIES.md#1-execution-flow](FUNCTIONAL_DEPENDENCIES.md#1-execution-flow-when-user-runs-python-run_validationpy---limit-30---random-stratified)

---

## 📊 File Statistics

| Category | Count | Status |
|----------|-------|--------|
| Production Scripts | 28 | ✅ Active |
| Production Folders | 5 | ✅ Organized |
| Reference Scripts | 40+ | ⚠️ Archive only |
| Configuration Docs | 3 | 📋 This folder |
| Reserved Folders | 1 | 🔮 Future use |

---

## ✅ Verification Checklist

After reviewing these docs, you should be able to:

- [ ] Explain the purpose of each folder (5 folders)
- [ ] Run basic validation with `run_validation.py`
- [ ] Understand stratified sampling (18 dataflow prefixes)
- [ ] Find where outputs are saved (validation/results/)
- [ ] Know where cached data is stored (validation/cache/)
- [ ] Check issue validity status
- [ ] Update metadata when needed
- [ ] Identify which scripts are production vs. reference

---

## 🎓 Learning Path

**If you're new to the validation system:**

1. Start: [DIRECTORY_TREE.md](DIRECTORY_TREE.md) - Get visual overview
2. Then: [SCRIPTS_STRUCTURE_MAP.md](SCRIPTS_STRUCTURE_MAP.md#1-core-validation-scriptscorevalidation) - Understand core components
3. Next: [FUNCTIONAL_DEPENDENCIES.md#1-execution-flow](FUNCTIONAL_DEPENDENCIES.md#1-execution-flow-when-user-runs-python-run_validationpy---limit-30---random-stratified) - See execution flow
4. Finally: Run `python run_validation.py --limit 10` and watch the output

**If you need to modify validation logic:**

1. Start: [SCRIPTS_STRUCTURE_MAP.md#1-core-validation](SCRIPTS_STRUCTURE_MAP.md#1-core-validation-scriptscorevalidation) - Understand core logic
2. Then: [FUNCTIONAL_DEPENDENCIES.md#6-class-dependencies](FUNCTIONAL_DEPENDENCIES.md#6-class-dependencies) - See class architecture
3. Reference: [FUNCTIONAL_DEPENDENCIES.md#7-data-flows](FUNCTIONAL_DEPENDENCIES.md#7-data-flows-what-data-moves-where) - Understand data flow

**If you need to add new scripts:**

1. Choose folder based on purpose
2. Follow naming convention from [SCRIPTS_STRUCTURE_MAP.md#summary-table](SCRIPTS_STRUCTURE_MAP.md#summary-table-all-folders)
3. Update documentation with new script details

---

## 📞 Quick Reference

| Question | Answer | Location |
|----------|--------|----------|
| What's in folder X? | See summary table | [SCRIPTS_STRUCTURE_MAP.md#summary-table](SCRIPTS_STRUCTURE_MAP.md#summary-table-all-folders) |
| How do I run validation? | Use run_validation.py | [SCRIPTS_STRUCTURE_MAP.md#common-operations](SCRIPTS_STRUCTURE_MAP.md#common-operations) |
| What's stratified sampling? | Proportional across 18 prefixes | [FUNCTIONAL_DEPENDENCIES.md#2-sampling](FUNCTIONAL_DEPENDENCIES.md#2-sampling-system-stratified-vs-sequential) |
| Where's the cache? | validation/cache/{python,r,stata}/ | [FUNCTIONAL_DEPENDENCIES.md#3-cache](FUNCTIONAL_DEPENDENCIES.md#3-cache-system) |
| How do I find script X? | Use DIRECTORY_TREE.md | [DIRECTORY_TREE.md](DIRECTORY_TREE.md) |
| What scripts are active? | See status column | [SCRIPTS_STRUCTURE_MAP.md#summary-table](SCRIPTS_STRUCTURE_MAP.md#summary-table-all-folders) |
| Where are outputs? | validation/results/{TIMESTAMP}/ | [FUNCTIONAL_DEPENDENCIES.md#7-data-flows](FUNCTIONAL_DEPENDENCIES.md#7-data-flows-what-data-moves-where) |
| Can I use _archive/ scripts? | No, reference only | [SCRIPTS_STRUCTURE_MAP.md#7-archive](SCRIPTS_STRUCTURE_MAP.md#7-archive-scriptsx_archive) |

---

## 🔗 Related Documentation

In the validation/ folder:
- `validation/VALIDATION_QUICK_START.md` - Quick start guide
- `validation/SCRIPTS_STRUCTURE_MAP.md` - Full inventory (in scripts/)
- `validation/scripts/DIRECTORY_TREE.md` - Visual tree (this folder)
- `validation/scripts/FUNCTIONAL_DEPENDENCIES.md` - Dependencies & flow (this folder)

At repo root:
- `unicefData-dev/.github/copilot/unicefdata-python-context.md` - Python context
- `unicefData-dev/.github/copilot/unicefdata-r-context.md` - R context
- `unicefData-dev/.github/copilot/unicefdata-stata-context.md` - Stata context

---

**Last Updated:** January 20, 2026  
**Status:** ✅ Complete mapping of all 28 production scripts across 5 organized folders


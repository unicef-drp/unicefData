# Validation Scripts - One-Page Reference Card

**Quick lookup for the validation scripts reorganization**

---

## Folder Summary (5 Active + 3 Reference)

### Active Production Folders
| Folder | Scripts | Purpose | Key Files |
|--------|---------|---------|-----------|
| **core_validation/** | 5 | Main validation engine | test_all_indicators_comprehensive.py |
| **orchestration/** | 1 | Entry point wrapper | orchestrator_indicator_tests.py |
| **metadata_sync/** | 8 | Data freshness & sync | sync_metadata_*.{py,R,do} |
| **issue_validity/** | 6 | Known issues tracking | check_issues_validity.py |
| **platform_tests/** | 4 | Platform-specific tests | *.do, *.R |
| | | | |
| **TOTAL ACTIVE** | **28** | **Production use** | |

### Reference Folders
| Folder | Scripts | Status | Use |
|--------|---------|--------|-----|
| **_archive/** | 40+ | Legacy/debug | Reference only, DO NOT USE |
| **diagnostics/** | 0 | Reserved | Future use |
| **__pycache__/** | ? | Auto | Python cache, ignore |

---

## Scripts at a Glance

### Core Validation (5 scripts)
```
test_all_indicators_comprehensive.py  ⭐ MAIN ORCHESTRATOR (1854 lines)
valid_indicators_sampler.py           📊 STRATIFIED SAMPLING (18 prefixes)
cache_manager.py                      💾 CACHE PERSISTENCE
cached_test_runners.py                🏃 EXECUTION RUNNERS
validate_cross_language.py            🔀 COMPARISON ENGINE
```

### Orchestration (1 script)
```
orchestrator_indicator_tests.py       🎯 WRAPPER (passes args through)
```

### Metadata Sync (8 scripts)
```
sync_metadata_python.py               🐍 PYTHON API
sync_metadata_r.R                     📈 R API
sync_metadata_stata.do                📊 STATA API
sync_metadata_stataonly.do            📋 STATA-ONLY
orchestrator_metadata.py              🎯 ORCHESTRATOR
check_dataflows.py                    ✓ VALIDATION
check_sdmx_structure.py               ✓ VALIDATION
check_tier_preservation.py            ✓ VALIDATION
```

### Issue Validity (6 scripts)
```
check_issues_validity.py              🔍 ISSUE CHECKER (Python)
run_issue_validity_check.ps1          🎯 WRAPPER (PowerShell)
+ 4 documentation files               📖 GUIDES
```

### Platform Tests (4 scripts)
```
stata_smoke_test.do                   ✓ QUICK TEST
stata_diagnostic.do                   🔧 DIAGNOSTICS
test_indicator_suite.do               📊 FULL SUITE
test_indicator_suite.R                📊 FULL SUITE
```

---

## Quick Commands

| Task | Command |
|------|---------|
| **Basic validation** | `python run_validation.py --limit 10` |
| **Stratified sampling** | `python run_validation.py --limit 30 --random-stratified --seed 42` |
| **Specific languages** | `python run_validation.py --languages python r` |
| **Force fresh** | `python run_validation.py --force-fresh` |
| **Check issues** | `cd scripts/issue_validity && .\run_issue_validity_check.ps1` |
| **Update metadata** | `cd scripts/metadata_sync && python orchestrator_metadata.py` |
| **Stata diagnostic** | `cd scripts/platform_tests && do stata_diagnostic.do` |

---

## Key Features

| Feature | Details |
|---------|---------|
| **Stratified Sampling** | 645 indicators → 18 dataflow prefixes, min 1 per prefix |
| **Caching** | Location: `validation/cache/{python,r,stata}/`, TTL: 7 days |
| **Cross-Language** | Tests Python/R/Stata simultaneously, compares outputs |
| **Issue Tracking** | Monitors 4 known issues, validates fixes, tracks status |
| **Metadata** | Auto-syncs from UNICEF SDMX API, validates structure |

---

## Output Locations

| Output | Location |
|--------|----------|
| **Validation results** | `validation/results/{TIMESTAMP}/` |
| **Cache** | `validation/cache/{python,r,stata}/` |
| **Metadata** | `validation/scripts/metadata/current/` |
| **Logs** | Per-platform in `results/{TIMESTAMP}/{platform}/` |

---

## Documentation Files (Read These)

| File | Purpose | When to Read |
|------|---------|--------------|
| **README_SCRIPTS_OVERVIEW.md** | Index of all docs | First |
| **SCRIPTS_NAVIGATION_GUIDE.md** | Quick reference | For common tasks |
| **scripts/DIRECTORY_TREE.md** | Visual structure | For overview |
| **SCRIPTS_STRUCTURE_MAP.md** | Complete inventory | For details |
| **scripts/FUNCTIONAL_DEPENDENCIES.md** | Data flow | For understanding |

---

## Numbers

| Metric | Value |
|--------|-------|
| Total Production Scripts | 28 |
| Total Archive Scripts | 40+ |
| Total Scripts | 78+ |
| Valid Indicators | 645 |
| Dataflow Prefixes | 18 |
| Active Folders | 5 |
| Total Folders | 8 |
| Documentation Files | 9 |
| Cache TTL Days | 7 |

---

## Stratified Sampling Example

```
Input: --limit 30 --random-stratified --seed 42
Process: Group 645 indicators by 18 dataflow prefixes
Output:
  CME:   1 sample (from 38)
  COD:   1 sample (from 83)
  DM:    1 sample (from 30)
  ...
  WT:    1 sample (from 6)
Result: ~36-45 total samples (18 × 1 minimum + proportional)
```

---

## Execution Flow

```
run_validation.py (entry)
    ↓
orchestrator_indicator_tests.py (wrapper)
    ↓
test_all_indicators_comprehensive.py (core)
    ├─ Load indicators (645)
    ├─ Sample (stratified or sequential)
    ├─ For each: Test Python → Test R → Test Stata
    ├─ Check cache, fetch if needed
    ├─ Compare results
    └─ Generate reports
```

---

## File Organization Best Practices

✅ **DO**
- Put validation scripts in organized folders
- Update documentation when adding scripts
- Use cache for repeated runs
- Run stratified sampling for comprehensive testing
- Check results in `validation/results/`

❌ **DON'T**
- Add new scripts to root or _archive
- Use scripts from _archive in production
- Ignore the 5 organized folders
- Skip documentation updates
- Mix old and new validation approaches

---

## Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| Can't find script X? | See SCRIPTS_STRUCTURE_MAP.md |
| How do I run validation? | See SCRIPTS_NAVIGATION_GUIDE.md |
| How does sampling work? | See FUNCTIONAL_DEPENDENCIES.md #2 |
| Where's my output? | Check `validation/results/{TIMESTAMP}/` |
| Cache not working? | Check `validation/cache/{python,r,stata}/` |
| Script not found error? | Ensure you're in `validation/` folder |

---

## Get Started in 30 Seconds

```bash
# 1. Navigate to validation folder
cd C:\GitHub\myados\unicefData-dev\validation

# 2. Run basic validation
python run_validation.py --limit 10

# 3. Check results
ls results/  # Look for latest {TIMESTAMP}/ folder

# 4. View summary
cat results/{TIMESTAMP}/SUMMARY.md
```

---

## Next: Pick Your Learning Path

**I want to get started quickly:**  
→ Read: SCRIPTS_NAVIGATION_GUIDE.md (5 min)

**I want a visual overview:**  
→ Read: scripts/DIRECTORY_TREE.md (5 min)

**I want complete details:**  
→ Read: SCRIPTS_STRUCTURE_MAP.md (15 min)

**I want to understand data flow:**  
→ Read: scripts/FUNCTIONAL_DEPENDENCIES.md (20 min)

---

## Summary

✅ **28 production scripts** organized into **5 folders**  
✅ **Clear separation** between production and legacy  
✅ **Comprehensive documentation** with 9 guides  
✅ **Ready for use** - all mapped and documented  

**Status: COMPLETE** ✅


# Validation Scripts - Directory Tree

```
validation/
├── run_validation.py                           ← MAIN ENTRY POINT (wrapper)
├── SCRIPTS_STRUCTURE_MAP.md                    ← FULL DOCUMENTATION (see this first)
├── VALIDATION_QUICK_START.md
├── cache/                                      ← Results cache
│   ├── python/                                 ✓ Indicators cached here
│   ├── r/                                      ✓ Indicators cached here
│   └── stata/                                  ✓ Indicators cached here
├── results/                                    ← Output reports
│   ├── 2026_01_10_indicator_validation_*.../
│   ├── issue_validity/
│   └── ...
│
└── scripts/                                    ← ALL VALIDATION SCRIPTS
    │
    ├─────────────────────────────────────────────────────────────
    │  CORE VALIDATION (Main Engine)
    ├─────────────────────────────────────────────────────────────
    ├── core_validation/
    │   ├── test_all_indicators_comprehensive.py      ⭐ MAIN TEST ORCHESTRATOR
    │   │   └── ~1854 lines: core validation logic, cache integration, sampling
    │   ├── valid_indicators_sampler.py               📊 STRATIFIED SAMPLING
    │   │   └── Groups by 18 dataflow prefixes, proportional allocation
    │   ├── cached_test_runners.py                    🏃 EXECUTION RUNNERS
    │   │   └── Python/R/Stata test execution with cache
    │   ├── cache_manager.py                          💾 CACHE LOGIC
    │   │   └── Manages validation/cache/{platform}/ folders
    │   ├── validate_cross_language.py                🔀 COMPARISON
    │   │   └── Compares outputs across Python/R/Stata
    │   └── __pycache__/
    │
    ├─────────────────────────────────────────────────────────────
    │  ORCHESTRATION (Entry Points)
    ├─────────────────────────────────────────────────────────────
    ├── orchestration/
    │   └── orchestrator_indicator_tests.py           🎯 ORCHESTRATOR
    │       └── Thin wrapper, passes args to test_all_indicators_comprehensive.py
    │
    ├─────────────────────────────────────────────────────────────
    │  METADATA SYNCING (Data Freshness)
    ├─────────────────────────────────────────────────────────────
    ├── metadata_sync/
    │   ├── sync_metadata_python.py                   🐍 PYTHON METADATA
    │   │   └── Fetches via SDMX API
    │   ├── sync_metadata_r.R                         📈 R METADATA
    │   ├── sync_metadata_stata.do                    📊 STATA METADATA
    │   ├── sync_metadata_stataonly.do                📋 STATA-ONLY REFRESH
    │   ├── orchestrator_metadata.py                  🎯 METADATA ORCHESTRATOR
    │   ├── check_dataflows.py                        ✓ DATAFLOW VALIDATION
    │   ├── check_sdmx_structure.py                   ✓ SDMX VALIDATION
    │   └── check_tier_preservation.py                ✓ TIER PRESERVATION
    │
    ├─────────────────────────────────────────────────────────────
    │  ISSUE VALIDITY (Known Issues Tracking)
    ├─────────────────────────────────────────────────────────────
    ├── issue_validity/
    │   ├── check_issues_validity.py                  🔍 ISSUE CHECKER
    │   │   └── Validates: duplicates, dimensions, rows, UTF-8
    │   ├── run_issue_validity_check.ps1              🎯 WINDOWS WRAPPER
    │   ├── ISSUES_VALIDITY_QUICK_REFERENCE.md        📖 QUICK START
    │   ├── CHECK_ISSUES_VALIDITY_README.md           📖 FULL DOCS
    │   ├── ISSUE_VALIDITY_CHECKER_SUMMARY.md         📋 SUMMARY
    │   └── IMPLEMENTATION_COMPLETE_REPORT.md         ✓ STATUS
    │
    ├─────────────────────────────────────────────────────────────
    │  PLATFORM SMOKE TESTS (Quick Platform Checks)
    ├─────────────────────────────────────────────────────────────
    ├── platform_tests/
    │   ├── stata_diagnostic.do                       🔧 STATA DIAGNOSTICS
    │   ├── stata_smoke_test.do                       ✓ STATA SMOKE TEST
    │   ├── test_indicator_suite.do                   📊 STATA SUITE
    │   └── test_indicator_suite.R                    📊 R SUITE
    │
    ├─────────────────────────────────────────────────────────────
    │  DIAGNOSTICS (Reserved, Currently Empty)
    ├─────────────────────────────────────────────────────────────
    ├── diagnostics/
    │   └── (empty - reserved for future diagnostic tools)
    │
    ├─────────────────────────────────────────────────────────────
    │  ARCHIVE (Legacy & Debug - DO NOT USE IN PRODUCTION)
    ├─────────────────────────────────────────────────────────────
    └── _archive/                                    ⚠️ LEGACY (40+ files)
        ├── Fetch/Sync Examples:
        │   ├── fetch_*.log (10 files)                - Old fetch logs
        │   ├── sync_examples_*.{py,R,do}             - Example syncs
        │   └── orchestrator_examples.py
        │
        ├── Testing & Debugging:
        │   ├── test_*.py / test_*.R / test_*.do      - Single indicator tests
        │   ├── quick_*.py                            - Quick validation
        │   ├── debug_*.py                            - Debugging
        │   ├── analyze_*.py / diagnose_*.R           - Analysis
        │   ├── compare_*.{py,R,do}                   - Comparisons
        │   └── *_verbose_*.{py,R,do}                 - HTTP tracing
        │
        ├── Specialized:
        │   ├── python_verbose_http_trace.py
        │   ├── r_verbose_http_trace.R
        │   ├── stata_verbose_http_trace.do
        │   ├── test_unified_fallback_validation.py
        │   ├── validate_outputs.py
        │   └── URL_CONSTRUCTION_NOTES.R
        │
        └── investigation_reports/                   - Old investigation logs
```

---

## Quick Reference by Task

| Task | Script | Location |
|------|--------|----------|
| **Run validation (10 indicators)** | `run_validation.py --limit 10` | Root |
| **Run with stratified sampling** | `run_validation.py --limit 30 --random-stratified` | Root |
| **Check specific languages** | `run_validation.py --languages python r` | Root |
| **Use cache** | `run_validation.py --limit 50` | Root (automatic) |
| **Force fresh data** | `run_validation.py --limit 10 --force-fresh` | Root |
| **Check known issues** | `.\run_issue_validity_check.ps1` | `issue_validity/` |
| **Update metadata** | `python orchestrator_metadata.py` | `metadata_sync/` |
| **Stata smoke test** | `do stata_smoke_test.do` | `platform_tests/` |
| **Platform diagnostics** | `do stata_diagnostic.do` | `platform_tests/` |

---

## File Counts

- **Production Active:** 28 scripts (core_validation, orchestration, metadata_sync, issue_validity, platform_tests)
- **Reference/Legacy:** 45+ scripts (_archive)
- **Configuration:** 3 (READMEs + this map)
- **Reserved/Empty:** 1 (diagnostics/)
- **Total:** ~77 files

---

## Key Improvements After Reorganization

✅ **Clear Structure:** Each folder has single responsibility  
✅ **Easy Navigation:** Find scripts by function, not by scrolling 40+ files  
✅ **Active vs Legacy:** Production scripts separate from debug artifacts  
✅ **Metadata Management:** Centralized in metadata_sync/  
✅ **Issue Tracking:** Dedicated folder for regression detection  
✅ **Platform Tests:** Smoke tests organized by language  

---

## Next Steps if Cleaning Up

1. **Review _archive/:** Determine what can be safely deleted (>6 months old, superseded)
2. **Create README:** Add scripts/README.md with quick start guide
3. **Automate Cleanup:** Consider .gitignore rules for old logs in _archive/
4. **Monitor Growth:** Prevent new test files accumulating without organization


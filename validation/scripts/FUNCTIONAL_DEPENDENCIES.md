# Validation Scripts - Functional Dependencies & Data Flow

## Overview

This document shows how validation scripts depend on each other and how data flows through the system.

---

## 1. Execution Flow (When User Runs: `python run_validation.py --limit 30 --random-stratified`)

```
┌─────────────────────────────────────────────────────────────────┐
│ Execution Entry Point                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   validation/run_validation.py                                  │
│   ├─ Parse args: --limit 30 --random-stratified --seed 42      │
│   ├─ Build command: python orchestrator_indicator_tests.py ... │
│   └─ Execute subprocess                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ Orchestration Layer                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   scripts/orchestration/orchestrator_indicator_tests.py         │
│   ├─ Validates TEST_SCRIPT exists                              │
│   ├─ Passes all args to test_all_indicators_comprehensive.py   │
│   └─ Forwards returncode                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ Main Validation Logic                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   scripts/core_validation/test_all_indicators_comprehensive.py  │
│   ├─ Parse args: limit=30, random_stratified=True, seed=42    │
│   ├─ Load indicators from metadata (645 valid indicators)       │
│   │                                                             │
│   ├─► SAMPLING DECISION                                        │
│   │   ├─ If --random-stratified:                               │
│   │   │  └─ Call valid_indicators_sampler.stratified_sample()  │
│   │   │     ├─ Groups 645 indicators into 18 dataflow prefixes │
│   │   │     ├─ Allocates: (count_in_prefix / 645) * 30         │
│   │   │     ├─ Enforces: minimum 1 per prefix                  │
│   │   │     └─ Returns: ~30+ samples (actual depends on rule)  │
│   │   └─ Else: sequential selection (first 30)                 │
│   │                                                             │
│   └─ For each sampled indicator (e.g., 30-45 indicators):      │
│       │                                                         │
│       ├─► TEST EXECUTION FOR EACH INDICATOR                    │
│       │   │                                                    │
│       │   ├─ Check cache (Python)                              │
│       │   │  ├─ If hit: skip, load from validation/cache/python/
│       │   │  └─ If miss: execute test_python_indicator()       │
│       │   │             └─ Save to cache                       │
│       │   │                                                    │
│       │   ├─ Check cache (R)                                   │
│       │   │  ├─ If hit: skip, load from validation/cache/r/    │
│       │   │  └─ If miss: execute test_r_indicator()            │
│       │   │             └─ Save to cache                       │
│       │   │                                                    │
│       │   └─ Check cache (Stata)                               │
│       │      ├─ If hit: skip, load from validation/cache/stata/
│       │      └─ If miss: execute test_stata_indicator()        │
│       │                  └─ Save to cache                      │
│       │                                                        │
│       ├─► CROSS-LANGUAGE VALIDATION                            │
│       │   └─ validate_cross_language.py                        │
│       │      ├─ Compare dimensions across Python/R/Stata       │
│       │      ├─ Compare row counts                             │
│       │      └─ Flag discrepancies                             │
│       │                                                        │
│       └─► LOG RESULTS                                          │
│           ├─ Per-indicator logs (in results/{TIMESTAMP}/)      │
│           ├─ Platform-specific logs (python/, r/, stata/)      │
│           └─ Success/failed tracking                           │
│                                                                 │
│   Final: Generate reports                                      │
│   ├─ SUMMARY.md (executive summary)                            │
│   ├─ detailed_results.csv (full table)                         │
│   ├─ error_log.txt (all errors)                                │
│   └─ Per-platform results                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Sampling System (Stratified vs Sequential)

### WITHOUT --random-stratified
```
SEQUENTIAL SAMPLING
═══════════════════════════════════════════════════════════════

645 Valid Indicators
    ↓
    ├─ CME_MRY0T4
    ├─ CME_DPTM_PC
    ├─ CME_PTMR1
    ├─ COD_DIAR_TREAT
    ├─ COD_MORT_NEONAT
    └─ ... (first 30)

Sample Size: exactly 30
```

### WITH --random-stratified
```
STRATIFIED SAMPLING
═══════════════════════════════════════════════════════════════

645 Valid Indicators
    ↓
    └─→ valid_indicators_sampler.py :: stratified_sample()
        ├─ Group by prefix (first part before underscore):
        │
        │   CME: 38 indicators  ┐
        │   COD: 83 indicators  │
        │   DM:  30 indicators  │
        │   ECD:  8 indicators  │
        │   ... (14 more)       │ Total: 645
        │   WT:   6 indicators  ┘
        │
        ├─ Allocate proportionally with minimum 1:
        │   CME: (38/645)*30 = 1 sample   (min 1)
        │   COD: (83/645)*30 = 3 samples  (rounded)
        │   DM:  (30/645)*30 = 1 sample   (min 1)
        │   ECD:  (8/645)*30 = 1 sample   (min 1)
        │   ...
        │   WT:   (6/645)*30 = 1 sample   (min 1)
        │
        └─ Randomly select within each group (using seed=42)

Total Sample Size: ~36-45 (exceeds limit=30 due to min 1/prefix rule)
Guarantee: All 18 dataflow prefixes represented
```

---

## 3. Cache System

```
CACHE ARCHITECTURE
═══════════════════════════════════════════════════════════════

validation/cache/
├── python/
│   ├── CME_MRY0T4.csv                 ← Cached result
│   ├── CME_MRY0T4.metadata.json       ← Metadata (timestamp, rows)
│   ├── COD_DIAR_TREAT.csv
│   └── ...
│
├── r/
│   ├── CME_MRY0T4.csv
│   ├── CME_MRY0T4.metadata.json
│   └── ...
│
└── stata/
    ├── CME_MRY0T4.csv
    ├── CME_MRY0T4.metadata.json
    └── ...

CACHE MANAGER LOGIC (cache_manager.py)
─────────────────────────────────────

For each indicator & platform:
    1. Check if file exists
    2. Read metadata.json (timestamp, row count)
    3. Check TTL (staleness):
       ├─ If < 7 days old: USE (cache hit)
       └─ If > 7 days old: SKIP (cache miss, re-fetch)
    4. Return: (cache_hit: bool, data: DataFrame)

When cache_hit = False:
    ├─ Execute Python/R/Stata test
    ├─ Save result to cache/{platform}/INDICATOR.csv
    ├─ Save metadata: {timestamp, row_count, sha256}
    └─ Log: "Cached new result for INDICATOR"

When cache_hit = True:
    ├─ Load from cache
    └─ Log: "Used cached result for INDICATOR"
```

---

## 4. Issue Validity Checking Flow

```
ISSUE VALIDITY SYSTEM
═══════════════════════════════════════════════════════════════

User: .\run_issue_validity_check.ps1
    ↓
Activate Python venv
    ↓
scripts/issue_validity/check_issues_validity.py
    │
    ├─ Load test indicators (small set, ~6-8 indicators)
    │
    ├─ For each test indicator:
    │   │
    │   ├─ Fetch from Python
    │   ├─ Fetch from R
    │   └─ Fetch from Stata
    │
    └─ Run Issue Checks:
        │
        ├─ ISSUE 1: Stata Duplicate Columns
        │   └─ Count columns in Stata output
        │       ├─ If unique: ✅ FIXED
        │       └─ If duplicates: 🔴 STILL_VALID
        │
        ├─ ISSUE 2: Missing Dimensions (Python/R)
        │   └─ Compare column count across platforms
        │       ├─ If ratio ~1.0: ✅ FIXED
        │       └─ If ratio > 2.0: 🔴 STILL_VALID
        │
        ├─ ISSUE 3: Row Count Discrepancies
        │   └─ Compare row counts
        │       ├─ If all match: ✅ FIXED
        │       └─ If some differ: 🔴 STILL_VALID
        │
        └─ ISSUE 4: UTF-8 Encoding
            └─ Check for encoding errors
                ├─ If none: ✅ NO_ENCODING_ISSUES
                └─ If detected: 🔴 DETECTED

Generate Report:
├── validation/results/issue_validity/{TIMESTAMP}/
├── ├── issue_validity_report.txt        ← Human readable
├── ├── issue_validity_results.json      ← Machine readable
└── └── tmp/                              ← Debug files
```

---

## 5. Metadata Sync Flow

```
METADATA SYNCHRONIZATION
═══════════════════════════════════════════════════════════════

User: python scripts/metadata_sync/orchestrator_metadata.py
    ↓
orchestrator_metadata.py
    │
    ├─ Python Sync
    │   └─ sync_metadata_python.py
    │       ├─ Fetch from UNICEF SDMX API
    │       │   ├─ Dataflows
    │       │   ├─ Indicator codelist
    │       │   ├─ Countries
    │       │   └─ Regions
    │       └─ Output: validation/scripts/metadata/current/_unicefdata_*.yaml
    │
    ├─ R Sync
    │   └─ sync_metadata_r.R
    │       ├─ R package: unicefData
    │       └─ Output: validation/scripts/metadata/current/r_metadata.yaml
    │
    ├─ Stata Sync
    │   └─ sync_metadata_stata.do
    │       ├─ via Stata package
    │       └─ Output: validation/scripts/metadata/current/stata_metadata.yaml
    │
    ├─ Validation
    │   ├─ check_dataflows.py
    │   │   └─ Validate DSDs (Data Structure Definitions)
    │   ├─ check_sdmx_structure.py
    │   │   └─ Validate SDMX format
    │   └─ check_tier_preservation.py
    │       └─ Ensure Tier 1 indicators preserved
    │
    └─ Final Metadata State
        └─ validation/scripts/metadata/current/
            ├── _unicefdata_dataflows.yaml      (18 prefixes, 645 indicators)
            ├── _unicefdata_indicators.yaml     (full indicator registry)
            ├── _unicefdata_countries.yaml      (296 countries)
            ├── _unicefdata_regions.yaml        (regions)
            └── _unicefdata_codelists.yaml      (dimensions)
```

---

## 6. Class Dependencies

```
CORE VALIDATION CLASSES
═══════════════════════════════════════════════════════════════

test_all_indicators_comprehensive.py
├── class TestAllIndicatorsComprehensive
│   ├── __init__(args, config)
│   ├── load_indicators()
│   │   └─ Uses: metadata_sync/_unicefdata_indicators.yaml
│   │
│   ├── sample_indicators()
│   │   ├─ If args.random_stratified:
│   │   │  └─ Uses: ValidIndicatorSampler.stratified_sample()
│   │   └─ Else: sequential selection
│   │
│   ├── test_indicator(indicator_code)
│   │   ├─ Uses: cache_manager.check_cache()
│   │   ├─ Uses: cached_test_runners.test_python()
│   │   ├─ Uses: cached_test_runners.test_r()
│   │   ├─ Uses: cached_test_runners.test_stata()
│   │   └─ Uses: validate_cross_language.compare()
│   │
│   └── generate_reports()
│       └─ Outputs: SUMMARY.md, detailed_results.csv, error_log.txt
│
├── class ValidIndicatorSampler (valid_indicators_sampler.py)
│   ├── __init__(allow_unknown_prefixes, verbose, use_cache_validation)
│   └── stratified_sample(indicators, n, seed)
│       └─ Returns: {prefix: [indicator1, indicator2, ...], ...}
│
├── class CacheManager (cache_manager.py)
│   ├── __init__(cache_root)
│   ├── check_cache(platform, indicator)
│   │   └─ Returns: (hit: bool, data: DataFrame)
│   └── save_to_cache(platform, indicator, data)
│
├── class CachedTestRunners (cached_test_runners.py)
│   ├── test_python_indicator(indicator_code)
│   ├── test_r_indicator(indicator_code)
│   └── test_stata_indicator(indicator_code)
│
└── class ValidateCrossLanguage (validate_cross_language.py)
    ├── compare_dimensions(python_df, r_df, stata_df)
    ├── compare_rows(python_df, r_df, stata_df)
    └── flag_discrepancies()
```

---

## 7. Data Flows (What Data Moves Where)

```
┌─────────────────────────────────────────────────────────────────┐
│ DATA FLOW DURING VALIDATION RUN                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Inputs:                                                         │
│ ├─ Metadata: validation/scripts/metadata/current/*.yaml         │
│ └─ Cache:    validation/cache/{python,r,stata}/                │
│                                                                 │
│ Processing:                                                     │
│ 1. Read metadata (645 indicators)                               │
│ 2. Sample indicators (stratified or sequential)                 │
│ 3. For each sampled indicator:                                  │
│    ├─ Check cache (hit? use : fetch from API)                  │
│    └─ Execute test (Python/R/Stata)                            │
│ 4. Compare results across platforms                             │
│ 5. Generate reports                                             │
│                                                                 │
│ Outputs:                                                        │
│ ├─ Cache:   validation/cache/{python,r,stata}/                 │
│ │           └─ INDICATOR.csv + .metadata.json                  │
│ ├─ Reports: validation/results/{TIMESTAMP}/                    │
│ │           ├─ SUMMARY.md                                      │
│ │           ├─ detailed_results.csv                            │
│ │           ├─ error_log.txt                                   │
│ │           ├─ python/test_log.txt (+ success/failed/)          │
│ │           ├─ r/test_log.txt (+ success/failed/)               │
│ │           └─ stata/test_log.txt (+ success/failed/)           │
│ └─ Logs:    validation/logs/ (per-language, per-indicator)      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. File Dependencies (Which files depend on which)

```
DEPENDENCY GRAPH
════════════════════════════════════════════════════════════════

run_validation.py (entry point)
    └─→ orchestrator_indicator_tests.py
        └─→ test_all_indicators_comprehensive.py
            ├─→ valid_indicators_sampler.py
            │   └─ Metadata: _unicefdata_indicators.yaml
            ├─→ cache_manager.py
            │   └─ Cache dirs: validation/cache/{python,r,stata}/
            ├─→ cached_test_runners.py
            │   ├─→ Python API client
            │   ├─→ R unicefData package
            │   └─→ Stata unicefdata.ado
            └─→ validate_cross_language.py
                └─ Compares Python/R/Stata outputs

Metadata Sync:
    orchestrator_metadata.py
    ├─→ sync_metadata_python.py (SDMX API)
    ├─→ sync_metadata_r.R (R package)
    ├─→ sync_metadata_stata.do (Stata package)
    ├─→ check_dataflows.py
    ├─→ check_sdmx_structure.py
    └─→ check_tier_preservation.py

Issue Validity:
    run_issue_validity_check.ps1
    └─→ check_issues_validity.py
        └─→ cached_test_runners.py

Platform Tests:
    platform_tests/*.do
    platform_tests/*.R
    (standalone tests, no cross-dependencies)
```

---

## Summary

**Total Scripts in Production:** 28  
**Total Logical Modules:** 5 (core_validation, orchestration, metadata_sync, issue_validity, platform_tests)  
**Main Entry Point:** `validation/run_validation.py`  
**Core Logic:** `scripts/core_validation/test_all_indicators_comprehensive.py`  
**Key Innovation:** Stratified sampling by dataflow prefix + intelligent caching  


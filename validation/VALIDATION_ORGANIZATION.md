# Validation Folder Organization

**Date:** January 24, 2026  
**Status:** ✅ Organized per workspace standards

## Purpose

The `validation/` folder contains multi-platform consistency validation infrastructure for the unicefData package. It validates that Stata, R, and Python implementations return consistent results.

## Folder Structure

```
validation/
├── README.md                          # Entry point documentation
├── START_HERE.md                      # Quick start guide
├── run_validation.py                  # Main validation entry point (CRITICAL)
├── data/                              # Test data and validation inputs
├── metadata/                          # Configuration and metadata
├── cache/                             # Execution cache (PRIVATE, .gitignored)
├── logs/                              # Execution logs (PRIVATE)
├── docs/                              # Validation documentation (PUBLIC)
├── scripts/                           # Validation scripts (PUBLIC)
├── legacy/                            # Old/test scripts (ARCHIVED)
├── internal/                          # Internal notes (PRIVATE)
├── docs_archive/                      # Archived documentation (PRIVATE)
├── results/                           # Summary reports (PUBLIC)
├── reports/                           # Generated reports (PUBLIC)
├── consistency_reports/               # Consistency findings (PUBLIC)
├── results/                           # Validation run results (mixed public/private)
└── _archive/                          # Archive of old validation runs
```

## File Organization Details

### ✅ Root Level (Entry Points & Critical)

| File | Purpose | Status |
|------|---------|--------|
| **README.md** | Main validation folder documentation | Entry point |
| **START_HERE.md** | Quick start guide | Entry point |
| **run_validation.py** | Main validation orchestration script | CRITICAL |

### 📁 docs/ (Validation Documentation - PUBLIC)

**Content:** Guides, analysis, findings documentation  
**Rationale:** Methodology and findings should be publicly documented

Files organized:
- 00_START_HERE.md - Quick start
- CONSISTENCY_EXECUTIVE_SUMMARY.md - High-level findings
- CONSISTENCY_ASSESSMENT.md - Detailed analysis
- PARITY_VERIFICATION_REPORT.md - Platform parity results
- VALIDATION_CHECKS_DESIGN.md - Methodology
- DOCUMENTATION_INDEX.md - Guide to docs
- ROW_MISMATCH_ANALYSIS.md - Data consistency
- STRATIFIED_SAMPLING_ANALYSIS.md - Sampling validation
- STATA_NETWORK_ERROR_677.md - Issue documentation
- And 10+ other analysis documents

### 📁 scripts/ (Validation Scripts - PUBLIC)

**Content:** Analysis and validation scripts (methodology)

Files:
- run_validation.py - Main orchestration (moved to root, symlink here)
- compare_platform_consistency.py - Comparison logic
- Additional validation utilities

### 📁 data/ (Test Data - Already Organized)

**Content:** Test datasets for validation  
**Status:** Pre-organized, unchanged

### 📁 metadata/ (Configuration - Already Organized)

**Content:** Validation configuration and metadata  
**Status:** Pre-organized, unchanged

### 📁 results/ (Summary Results - PUBLIC)

**Content:** Validation result summaries  
**Status:** Pre-organized, unchanged

### 📁 reports/ (Generated Reports - PUBLIC)

**Content:** Analysis reports and findings  
**Status:** Pre-organized, unchanged

### 📁 consistency_reports/ (Consistency Findings - PUBLIC)

**Content:** Platform consistency validation reports  
**Status:** Pre-organized, unchanged

### 📁 results/ (Run Results - PUBLIC/PRIVATE)

**Content:** Validation run results and reports  
**Structure:**
- Timestamped folders (YYYYMMDD/ or YYYYMMDD_HHMMSS/)
- Query comparison reports
- Verbose test logs
- Summary results

**Rationale:** Timestamped results for archival and comparison. Summary files can be shared; tmp/ contents are private.

### 📁 logs/ (Execution Logs - PRIVATE)

**Content:** Validation run logs  
**Rationale:** Generated during execution, .gitignored

### 📁 legacy/ (Old Test Scripts - ARCHIVED)

**Content:** Deprecated test and debug files

Files moved:
- test_curl_direct.do - Old curl testing
- test_curl_direct.log - Old log
- test_fallback_run.log - Fallback testing log
- test_stata_direct.do - Direct Stata test
- test_stata_direct.log - Log
- test_stata_network.do - Network test
- test_verbose.do - Verbose test mode
- simple_test.do - Simple test
- verify_pagination.log - Pagination test log
- validation_full_run.log - Old full run log
- validation_test_10ind_seed42.log - Old test log

**Rationale:** These are older test iterations, preserved for reference

### 📁 internal/ (Internal Notes - PRIVATE)

**Content:** Created for future internal documentation  
**Status:** Empty, ready for use

### 📁 docs_archive/ (Archived Documentation - PRIVATE)

**Content:** Created for archiving old documentation  
**Status:** Empty, ready for future archiving

### 📁 _archive/ (Legacy Archives - Already Organized)

**Content:** Old validation run archives  
**Status:** Pre-organized, unchanged

## Organization Principles

### Why This Structure?

1. **Public/Private Separation** → Docs, scripts, reports are public; logs, cache, execution artifacts are private
2. **Entry points at root** → README.md, START_HERE.md, run_validation.py easy to find
3. **Results organized** → Separate folders for results vs reports vs consistency findings
4. **Legacy preserved** → Old test scripts kept for reference
5. **Metadata centralized** → data/, metadata/, config files grouped

### Critical Files (DO NOT MOVE)

- `run_validation.py` - Main orchestration script
- `README.md` - Entry documentation
- `START_HERE.md` - Quick start guide

**Rationale:** These are referenced by CI/CD pipelines and documentation.

## Git Status

### .gitignore entries (should be in root or validation/.gitignore)

```
validation/cache/
validation/logs/
validation/results/**/tmp/
validation/**/*.log
.cache/
*.tmp
```

### .gitkeep files

Use `.gitkeep` in empty folders to preserve directory structure:
- internal/.gitkeep
- docs_archive/.gitkeep

## Maintenance Guidelines

### Adding New Files

- **New documentation** → Add to docs/
- **New validation scripts** → Add to scripts/
- **Test/debug code** → Add to legacy/
- **Old docs** → Move to docs_archive/
- **Old runs** → Move to _archive/

### Regular Cleanup

Archive old validation runs quarterly:

```bash
# Move runs older than 90 days to archive
mv results/202512* _archive/
mv results/202511* _archive/
```

## Standards Compliance

This folder organization follows:
- ✅ Workspace FILE-ORGANIZATION-GUIDELINES.md (Section 7: Validation Files)
- ✅ Validation scripts in scripts/ (PUBLIC methodology)
- ✅ Validation docs in docs/ (PUBLIC)
- ✅ Results in results/, consistency_reports/ (PUBLIC)
- ✅ Execution artifacts in validation/, logs/, cache/ (PRIVATE)
- ✅ Legacy preserved in legacy/ and _archive/
- ✅ Temporary files .gitignored

**Reference:**
- Guidelines: `.github/FILE-ORGANIZATION-GUIDELINES.md`
- Validation results: `validation/validation/ORGANIZATION.md`
- QA organization: `stata/qa/QA_ORGANIZATION.md`

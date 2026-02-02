# Stata Package: unicefData

![Stata 14+](https://img.shields.io/badge/Stata-14%2B-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Version](https://img.shields.io/badge/version-2.0.4-green)
![Tests](https://img.shields.io/badge/tests-38%2F38%20passing-brightgreen)

---

## 🆕 What's New in v2.0.4 (Stata)

**Bug Fix & Documentation Update** - February 1, 2026

* **False warning fix**: Resolved issue where valid disaggregation filters (e.g., `wealth`) showed "NOT supported" warnings despite working correctly
  - Fixed metadata_path reset logic at line 707
  - Now uses conditional fallback instead of unconditional reset
  - Eliminates false warnings while preserving correct error detection for truly unsupported filters
  - All 32/32 cross-platform indicators validated (100% consistency)

* **Examples documentation**: Refreshed examples to match unicefdata v2.0.4 API and workflows
  - Updated syntax documentation
  - Improved clarity on disaggregation handling
  - Aligned with latest metadata system

---

## 🆕 What's New in v2.0.0

**Major Quality Milestone** - All QA tests passing (38/38, 100% success rate)

* **SYNC-02 Enrichment Fix**: Resolved critical path extraction bug
  - Fixed directory path extraction logic in metadata enrichment pipeline
  - Phase 2-3 enrichment now working: tier classification + disaggregations
  - Previously: 37/38 tests passing (SYNC-02 failed)
  - Now: 38/38 tests passing in 10m 17s

* **Enhanced Reliability**: Metadata synchronization pipeline fully operational
  - All enrichment phases complete successfully
  - Improved YAML file path resolution
  - Better error handling and diagnostics

---

## Overview

The **Stata** implementation of unicefData provides seamless access to UNICEF's SDMX API, allowing researchers to download and analyze demographic, health, education, and protection indicators for 196+ countries.

**Repository:** [github.com/unicef-drp/unicefData](https://github.com/unicef-drp/unicefData)  
**Documentation:** See [main README](../README.md) for complete package comparison across Stata, R, and Python.

---

## Library Structure

```
stata/
├── src/                        # Source code
│   ├── u/                      # User commands (public)
│   │   ├── unicefdata.ado      # Main command
│   │   └── unicefdata.sthlp    # Help documentation
│   ├── _/                      # Helper programs (internal)
│   │   ├── _unicef_*.ado       # YAML processing, metadata handling
│   │   └── __unicef_*.ado      # Private utilities (double underscore)
│   └── py/                     # Python metadata generators
│       └── build_*.py          # Metadata sync scripts
│
├── metadata/                   # YAML metadata cache
│   └── current/                # Latest metadata files
│       ├── _unicefdata_*.yaml  # Core metadata (dataflows, indicators, etc.)
│       └── dataflows/          # Individual dataflow schemas
│
├── qa/                         # Quality assurance test suite
│   ├── run_tests.do            # Main test runner
│   ├── fixtures/               # Test baselines
│   └── README.md               # Test documentation (38/38 passing)
│
├── examples/                   # Usage examples
│   └── basic_usage.do          # Quick start examples
│
├── doc/                        # User documentation
│   └── images/                 # Screenshots and diagrams
│
└── ssc/                        # SSC distribution package
    ├── unicefdata.ado          # Packaged command
    ├── unicefdata.sthlp        # Packaged help
    └── stata.toc               # Package catalog
```

---

## Core Components

### 1. Main Command: `unicefdata.ado`
**Location:** `src/u/unicefdata.ado`  
**Purpose:** Primary user-facing command for downloading UNICEF data  
**Version:** 2.0.4 (February 1, 2026)

**Key Features:**
- Downloads data from UNICEF SDMX API
- Supports disaggregation by sex, wealth, residence, age, education
- Wide/long format reshaping
- Latest value queries
- Built-in metadata discovery

**Syntax:**
```stata
unicefdata, indicator(code) [options]
```

### 2. Helper Programs: `src/_/`

| File | Purpose |
|------|---------|
| `_unicef_load_fallback_sequences.ado` | Loads dataflow fallback sequences from YAML |
| `_unicef_parse_yaml.ado` | Parses YAML metadata files |
| `_unicef_validate_dimensions.ado` | Validates dimension combinations |
| `__unicef_api_request.ado` | Internal API request handler |
| `__unicef_parse_response.ado` | Internal XML response parser |

**Naming Convention:**
- **Single underscore** (`_unicef_`): Public helpers, documented
- **Double underscore** (`__unicef_`): Private utilities, internal use only

### 3. Metadata System

**Location:** `metadata/current/`

**Core Metadata Files:**

| File | Content | Updated By |
|------|---------|------------|
| `_unicefdata_dataflows.yaml` | Dataflow catalog | Python sync script |
| `_unicefdata_indicators.yaml` | Indicator codelist | Manual updates |
| `_unicefdata_countries.yaml` | Country reference table | Python sync script |
| `_unicefdata_regions.yaml` | Regional groupings | Python sync script |
| `dataflows/*.yaml` | Individual dataflow schemas | Python sync script |

**Metadata Sync:**
```bash
# Regenerate metadata from UNICEF SDMX API
cd src/py
python build_dataflow_metadata.py --agency UNICEF --outdir ../../metadata/current
```

### 4. Help Documentation

**Main Help:**
- `src/u/unicefdata.sthlp` - Complete command reference
- Includes syntax, options, examples, stored results

**Supplementary Help:**
- `unicefdata_whatsnew.sthlp` - Release notes and version history

**Viewing Help:**
```stata
help unicefdata
help unicefdata_whatsnew
```

### 5. Quality Assurance Suite

**Location:** `qa/`

- **38 tests** across 7 families (ENV, DL, DIS, FILT, META, EDGE, REGR, SYNC, XPLAT)
- **100% coverage** as of v1.10.0
- **Regression testing** with baseline snapshots
- **Documentation:** See [qa/README.md](qa/README.md)

**Run Tests:**
```stata
cd qa
do run_tests.do
```

---

## Installation

### From GitHub
```stata
net install unicefdata, from("https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/ssc") replace
```

### Manual Installation
1. Copy `src/u/unicefdata.ado` to your ado path
2. Copy `src/u/unicefdata.sthlp` to your ado path
3. Copy `metadata/current/` folder to `ado/plus/_/` (metadata cache)

**Verify Installation:**
```stata
which unicefdata
help unicefdata
```

---

## Quick Start

### Example 1: Download Mortality Data
```stata
unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2015:2023) clear
describe
list in 1/10
```

### Example 2: Disaggregate by Sex and Wealth
```stata
unicefdata, indicator(NT_ANT_HAZ_NE2) sex(_T M F) wealth(Q1 Q5 _T) clear
tabulate sex wealth_quintile
```

### Example 3: Get Latest Values
```stata
unicefdata, indicator(IM_DTP3) countries(all) latest clear
summarize value
```

### Example 4: Search for Indicators
```stata
unicefdata, search("malaria") info
```

---

## Development Workflow

### Testing Changes
1. Edit `src/u/unicefdata.ado`
2. Copy to user ado path:
   ```powershell
   Copy-Item src\u\unicefdata.ado $env:USERPROFILE\ado\plus\u\ -Force
   ```
3. In Stata: `discard` (clear cached programs)
4. Test: `unicefdata, indicator(CME_MRY0T4) clear`

### Running QA Suite
```stata
cd qa
do run_tests.do
```

### Updating Help Files
1. Edit `src/u/unicefdata.sthlp`
2. Rebuild help index: `discard`
3. Verify: `help unicefdata`

---

## Dependencies

- **Stata:** Version 14+
- **Internet:** Required for API access
- **yaml package:** For metadata parsing (auto-installed if missing)

**Check Dependencies:**
```stata
which yaml
```

---

## Architecture Notes

### Metadata Caching Strategy
- YAML files are cached locally to reduce API calls
- Fallback sequences allow graceful handling of missing dataflows
- Refresh metadata by re-running Python sync scripts

### API Integration
- Uses UNICEF SDMX REST API: https://sdmx.data.unicef.org
- Parses SDMX-ML 2.1 Generic format
- Handles HTTP errors gracefully with informative messages

### Platform Compatibility
- **Windows:** Tested on Windows 10/11 with Stata 17 MP
- **macOS:** Compatible (forward slashes in paths)
- **Linux:** Compatible (forward slashes in paths)

---

## Version Information

**Current Version:** 2.0.4 (February 1, 2026)

**Recent Changes:**
- ✅ 100% QA test coverage (38/38 passing)
- ✅ Regression testing framework (REGR-01)
- ✅ Comprehensive disaggregation support
- ✅ Enhanced error messages

**See:** [unicefdata_whatsnew.sthlp](src/u/unicefdata_whatsnew.sthlp) for complete version history.

---

## Support

- **GitHub Issues:** [github.com/unicef-drp/unicefData/issues](https://github.com/unicef-drp/unicefData/issues)
- **Documentation:** See [main README](../README.md)
- **Test Suite:** See [qa/README.md](qa/README.md)

---

## License

MIT License - See [LICENSE](../LICENSE) file.

**Author:** João Pedro Azevedo ([UNICEF](https://www.unicef.org))  
**Contact:** jpazevedo@unicef.org

# unicefData

[![R-CMD-check](https://github.com/unicef-drp/unicefData/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions)
[![Python Tests](https://github.com/unicef-drp/unicefData/actions/workflows/python-tests.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Stata 14+](https://img.shields.io/badge/Stata-14+-1a5276.svg)](https://www.stata.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Trilingual R, Python, and Stata library for downloading UNICEF child welfare indicators via SDMX API**

The **unicefData** package provides lightweight, consistent interfaces to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) in **R**, **Python**, and **Stata**. Fetch any indicator series by specifying its SDMX key, date range, and optional filters.

---

## Platform Documentation

| Platform | README | Version |
|----------|--------|---------|
| **R** | [R/README.md](R/README.md) | 2.1.0 |
| **Python** | [python/README.md](python/README.md) | 2.1.0 |
| **Stata** | [stata/README.md](stata/README.md) | 2.1.0 |

| Document | Purpose |
|----------|---------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [CHANGELOG.md](CHANGELOG.md) | Recent version history |
| [NEWS.md](NEWS.md) | Complete changelog |
| [CITATION.cff](CITATION.cff) | Citation metadata for academic use |
| [docs/](docs/INDEX.md) | Technical documentation index |

---

## Quick Start

All three platforms use **the same functions** with nearly identical parameters.

### Python

```python
from unicef_api import unicefData, search_indicators, list_categories

# Search for indicators
search_indicators("mortality")
list_categories()

# Fetch data (dataflow auto-detected)
df = unicefData(
    indicator="CME_MRY0T4",
    countries=["ALB", "USA", "BRA"],
    year="2015:2023"
)
```

### R

```r
library(unicefData)

# Search for indicators
search_indicators("mortality")
list_categories()

# Fetch data (dataflow auto-detected)
df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA", "BRA"),
  year = "2015:2023"
)
```

### Stata

```stata
* Search for indicators
unicefdata, search(mortality)
unicefdata, flows

* Fetch data (dataflow auto-detected)
unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) year(2015:2023) clear
```

---

## Installation

### R

```r
devtools::install_github("unicef-drp/unicefData")
library(unicefData)
```

### Python

```bash
git clone https://github.com/unicef-drp/unicefData.git
cd unicefData/python
pip install -e .
```

### Stata

```stata
* Using github package (recommended)
net install github, from("https://haghish.github.io/github/")
github install unicef-drp/unicefData, package(stata)
```

See platform-specific READMEs for detailed installation options.

---

## Features

| Feature | R | Python | Stata |
|---------|:-:|:------:|:-----:|
| Unified API | `unicefData()` | `unicefData()` | `unicefdata` |
| Search indicators | `search_indicators()` | `search_indicators()` | `unicefdata, search()` |
| List categories | `list_categories()` | `list_categories()` | `unicefdata, categories` |
| Auto dataflow detection | ✅ | ✅ | ✅ |
| Filter by country, year, sex | ✅ | ✅ | ✅ |
| Wide/long formats | ✅ | ✅ | ✅ |
| Latest value per country | ✅ | ✅ | ✅ |
| MRV (most recent values) | ✅ | ✅ | ✅ |
| Circa (nearest year) | ✅ | ✅ | ✅ |
| Add metadata (region, income) | ✅ | ✅ | 🔜 |
| 700+ indicators | ✅ | ✅ | ✅ |
| Automatic retries | ✅ | ✅ | ✅ |
| Cache management | `clear_unicef_cache()` | `clear_cache()` | `unicefdata, clearcache` |
| Timeout exceptions | ✅ | `SDMXTimeoutError` | ✅ |

---

## Core Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `indicator` | string/vector | Indicator code(s), e.g., `"CME_MRY0T4"` |
| `countries` | vector | ISO3 codes, e.g., `["ALB", "USA"]` |
| `year` | int/string | Single (`2020`), range (`"2015:2023"`), or list |
| `sex` | string | `"_T"` (total), `"F"`, `"M"`, or `"ALL"` |
| `format` | string | `"long"`, `"wide"`, or `"wide_indicators"` |
| `latest` | boolean | Keep only most recent value per country |
| `mrv` | integer | Keep N most recent values per country |
| `circa` | boolean | Find closest available year |

See platform READMEs for complete parameter documentation.

---

## Available Categories

| Category | Count | Description |
|----------|------:|-------------|
| NUTRITION | 112 | Stunting, wasting, etc. |
| CAUSE_OF_DEATH | 83 | Causes of death |
| CHILD_RELATED_SDG | 77 | SDG targets |
| WASH_HOUSEHOLDS | 57 | Water & Sanitation |
| PT | 43 | Child Protection |
| CHLD_PVTY | 43 | Child Poverty |
| CME | 39 | Child Mortality |
| EDUCATION | 38 | Education |
| HIV_AIDS | 38 | HIV/AIDS |
| MNCH | 38 | Maternal & Child Health |
| IMMUNISATION | 18 | Immunization |

Use `list_categories()` for the complete list (733 indicators across 22 categories).

---

## Common Indicators

| Indicator | Dataflow | Description |
|-----------|----------|-------------|
| `CME_MRY0T4` | CME | Under-5 mortality rate |
| `CME_MRM0` | CME | Neonatal mortality rate |
| `NT_ANT_HAZ_NE2_MOD` | NUTRITION | Stunting prevalence |
| `IM_DTP3` | IMMUNISATION | DTP3 coverage |
| `IM_MCV1` | IMMUNISATION | Measles coverage |
| `WS_PPL_W-SM` | WASH | Safely managed water |
| `PT_CHLD_Y0T4_REG` | PT | Birth registration |

---

## Project Structure

```
unicefData/
├── R/                      # R package
│   ├── *.R                 # R source files
│   ├── metadata/current/   # R metadata cache
│   └── README.md           # R documentation
├── python/                 # Python package
│   ├── unicef_api/         # Python module
│   ├── metadata/current/   # Python metadata cache
│   └── README.md           # Python documentation
├── stata/                  # Stata package
│   ├── src/                # Stata source files
│   ├── metadata/current/   # Stata metadata cache
│   ├── qa/                 # QA test suite
│   └── README.md           # Stata documentation
├── config/                 # Shared configuration
├── tests/                  # Cross-platform tests
├── validation/             # Cross-platform validation
├── DESCRIPTION             # R package metadata
├── NEWS.md                 # Changelog
└── README.md               # This file
```

---

## Version History

### v2.1.0 (2026-02-07)

**Cross-Language Quality & Testing**

- **Cache management APIs**: `clear_cache()` (Python), `clear_unicef_cache()` (R), `clearcache` (Stata)
- **Error handling improvements**: Configurable timeouts with `SDMXTimeoutError` (Python), fixed `apply_circa()` NA handling (R)
- **Portability**: Removed all hardcoded paths; R uses `system.file()`, Stata uses 3-tier resolution
- **Error context**: All 404 errors now show which dataflows were tried
- **Cross-language test suite**: 39 shared fixture tests (Python 14, R 13, Stata 12)
- **YAML schema documentation**: Comprehensive format reference for all 7 YAML file types

### v2.0.0 (2026-01-31)

**Major Quality Milestone**

- **SYNC-02 fix**: Resolved critical metadata enrichment bug
- **100% test coverage**: R (26), Python (28), Stata (38/38)
- **Cross-platform parity**: All platforms aligned

### v1.5.2 (2026-01-07)

- Fixed 404 fallback behavior
- Added dynamic User-Agent strings
- Added comprehensive test coverage

See [NEWS.md](NEWS.md) for complete changelog.

---

## Metadata Synchronization

The package automatically downloads and caches indicator metadata on first use. Cache refreshes every 30 days.

### Manual Refresh

**Stata:**
```stata
unicefdata_refresh_all, verbose
```

**Python:**
```python
from unicef_api import refresh_indicator_cache
refresh_indicator_cache()
```

**R:**
```r
refresh_indicator_cache()
```

### Clear Cache

**Python:**
```python
from unicefdata import clear_cache
clear_cache()  # Clears all 5 cache layers, reloads YAML
```

**R:**
```r
clear_unicef_cache()  # Clears all 6 cache layers, reloads YAML
```

**Stata:**
```stata
unicefdata, clearcache
```

### Cross-Language Sync

```powershell
# Sync metadata across all platforms
.\scripts\sync_metadata_cross_language.ps1
```

See [docs/METADATA_GENERATION_GUIDE.md](docs/METADATA_GENERATION_GUIDE.md) for detailed metadata sync documentation.

---

## Testing & Validation

### Run Tests

**R:**
```r
devtools::test()
```

**Python:**
```bash
cd python && pytest
```

**Stata:**
```stata
cd stata/qa
do run_tests.do
```

### Cross-Language Fixture Tests

Shared test fixtures validate structural consistency across all three languages:

```bash
# Python
python tests/test_cross_language_output.py

# R
Rscript tests/test_cross_language_output.R

# Stata
do tests/test_cross_language_output.do
```

### Cross-Platform Validation

```bash
cd validation
python run_validation.py --limit 10 --languages python r stata
```

See [validation/](validation/) for validation documentation, including the [Quick Start](validation/docs/00_START_HERE.md), [Indicator Testing Guide](validation/docs/INDICATOR_TESTING_GUIDE.md), and [Documentation Index](validation/docs/DOCUMENTATION_INDEX.md).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

1. **Report bugs** — Open an [issue](https://github.com/unicef-drp/unicefData/issues)
2. **Request features** — Suggest new indicators or functionality
3. **Submit code** — Fork, create branch, open pull request

### Development Setup

```bash
git clone https://github.com/unicef-drp/unicefData.git
cd unicefData

# Python
cd python && pip install -e .

# R (in RStudio)
devtools::load_all()

# Stata
cd stata && do install_local.do
```

---

## Links

- **UNICEF Data Portal:** https://data.unicef.org/
- **SDMX API Docs:** https://data.unicef.org/sdmx-api-documentation/
- **GitHub:** https://github.com/unicef-drp/unicefData
- **Issues:** https://github.com/unicef-drp/unicefData/issues

---

## Author

**Joao Pedro Azevedo** ([@jpazvd](https://github.com/jpazvd))
Chief Statistician, UNICEF Data and Analytics Section

---

## License

MIT License — See [LICENSE](LICENSE)

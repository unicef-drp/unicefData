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
├── R/                      # R package source
├── python/                 # Python package source
├── stata/                  # Stata package source
│   └── qa/                 # Stata QA test suite (63 tests)
├── tests/
│   ├── fixtures.zip        # Authoritative test fixtures (single source)
│   ├── fixtures/           # Unpacked fixtures (auto-extracted)
│   └── testthat/           # R unit tests (105 tests)
├── scripts/
│   ├── generate_fixtures.py  # Download + pack fixtures from API
│   └── unpack_fixtures.py    # Extract ZIP to all platform dirs
├── .githooks/              # Auto-unpack on clone/pull
├── validation/             # Cross-platform validation
├── internal/docs/          # Dev-only documentation
│   ├── TEST_REFERENCE.md   # Full cross-platform test map
│   ├── QA_SETUP.md         # Environment setup guide
│   └── FIXTURE_INFRASTRUCTURE.md  # ZIP fixture system
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

443 automated tests across all three platforms (63 Stata, 160 Python, 220 R).
All tests run offline using frozen fixtures from `tests/fixtures.zip`.
Full suite executes in under 14 minutes (12m 13s Stata, 34s Python, 7s R).

### Run Tests

**Python** (160 tests):
```bash
cd python && pytest tests/ -v
```

**R** (220 expectations):
```r
testthat::test_dir("tests/testthat/")
```

**Stata** (63 tests):
```stata
cd stata/qa
do run_tests.do
```

### Test Families

Tests are organized into 16 families aligned across platforms:

| Family | Stata | Python | R | Description |
| ------ | ----: | -----: | -: | ----------- |
| DET | 11 | 37 | 32 | Deterministic / offline (frozen CSV) |
| SYNC | 4 | 12 | 12 | Metadata sync (XML → YAML) |
| DISC | 3 | 24 | 24 | Discovery (YAML → output) |
| DL | 9 | 15 | 8 | Download / API fetch |
| ERR | 8 | 18 | 6 | Error handling / input validation |
| TRANS | 2 | 23 | 14 | Transformations (wide, latest, MRV) |
| REGR | 1 | 4 | 2 | Regression baselines (value pinning) |
| Other | 25 | 27 | 122 | DATA, TIER, META, MULTI, EDGE, EXT, PERF, ENV, XPLAT |

See [internal/docs/TEST_REFERENCE.md](internal/docs/TEST_REFERENCE.md) for the
complete cross-platform test map.

### Fixture Infrastructure

Test fixtures are stored in a single ZIP file (`tests/fixtures.zip`) and
auto-extracted by git hooks on clone and pull:

```bash
git config core.hooksPath .githooks    # one-time setup
python scripts/unpack_fixtures.py      # manual alternative
```

See [internal/docs/FIXTURE_INFRASTRUCTURE.md](internal/docs/FIXTURE_INFRASTRUCTURE.md)
for the full extraction map and regeneration workflow.

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
git config core.hooksPath .githooks    # enable auto-unpack fixtures

# Python
cd python && pip install -e ".[dev]"

# R (in RStudio)
devtools::load_all()

# Stata
cd stata && do install_local.do
```

See [internal/docs/QA_SETUP.md](internal/docs/QA_SETUP.md) for detailed
setup instructions across all three platforms.

---

## Links

- **UNICEF Data Portal:** https://data.unicef.org/
- **SDMX API Docs:** https://data.unicef.org/sdmx-api-documentation/
- **GitHub:** https://github.com/unicef-drp/unicefData
- **Issues:** https://github.com/unicef-drp/unicefData/issues

---

## Acknowledgments

This trilingual package ecosystem was developed at the UNICEF Data and Analytics Section. The author gratefully acknowledges the collaboration of **Lucas Rodrigues**, **Yang Liu**, and **Karen Avanesian**, whose technical contributions and feedback were instrumental in the development of this comprehensive data access library.

Special thanks to **Yves Jaques**, **Alberto Sibileau**, and **Daniele Olivotti** for designing and maintaining the UNICEF SDMX data warehouse infrastructure that makes this package possible.

The author also acknowledges the **UNICEF database managers** and technical teams who ensure data quality, as well as the country office staff and National Statistical Offices whose data collection efforts make this work possible.

Development of this package was supported by UNICEF institutional funding for data infrastructure and statistical capacity building. The author also acknowledges UNICEF colleagues who provided testing and feedback during development, as well as the broader open-source communities across R, Python, and Stata.

---

## Disclaimer

**This package is provided for research and analytical purposes.**

The `unicefData` package provides programmatic access to UNICEF's public data warehouse. While the author is affiliated with UNICEF, **this package is not an official UNICEF product and the statements in this documentation are the views of the author and do not necessarily reflect the policies or views of UNICEF**.

Data accessed through this package comes from the [UNICEF Data Warehouse](https://sdmx.data.unicef.org/). Users should verify critical data points against official UNICEF publications at [data.unicef.org](https://data.unicef.org/).

This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or UNICEF be liable for any claim, damages or other liability arising from the use of this software.

The designations employed and the presentation of material in this package do not imply the expression of any opinion whatsoever on the part of UNICEF concerning the legal status of any country, territory, city or area or of its authorities, or concerning the delimitation of its frontiers or boundaries.

---

## Data Citation and Provenance

**Important Note on Data Vintages**

Official statistics are subject to revisions as new information becomes available and estimation methodologies improve. UNICEF indicators are regularly updated based on new surveys, censuses, and improved modeling techniques. Historical values may be revised retroactively to reflect better information or methodological improvements.

**For reproducible research and proper data attribution, users should:**

1. **Document the indicator code** - Specify the exact SDMX indicator code(s) used (e.g., `CME_MRY0T4`)
2. **Record the download date** - Note when data was accessed (e.g., "Data downloaded: 2026-02-09")
3. **Cite the data source** - Reference both the package and the UNICEF Data Warehouse
4. **Archive your dataset** - Save a copy of the exact data used in your analysis

**Example citations for data used in research:**

- **R**: `Under-5 mortality data (indicator: CME_MRY0T4) accessed from UNICEF Data Warehouse via unicefData R package (v2.1.0) on 2026-02-09. Data available at: https://sdmx.data.unicef.org/`
- **Python**: `Under-5 mortality data (indicator: CME_MRY0T4) accessed from UNICEF Data Warehouse via unicefData Python package (v2.1.0) on 2026-02-09. Data available at: https://sdmx.data.unicef.org/`
- **Stata**: `Under-5 mortality data (indicator: CME_MRY0T4) accessed from UNICEF Data Warehouse via unicefData Stata package (v2.1.0) on 2026-02-09. Data available at: https://sdmx.data.unicef.org/`

This practice ensures that others can verify your results and understand any differences that may arise from data updates. For official UNICEF statistics in publications, always cross-reference with the current version at [data.unicef.org](https://data.unicef.org/).

---

## Citation

If you use this package in published work, please cite:

> Azevedo, J.P. (2026). "unicefdata: Unified access to UNICEF indicators
> across R, Python, and Stata." *Working paper*.
> URL: https://github.com/unicef-drp/unicefData

```bibtex
@article{azevedo2026unicefdata,
  title     = {unicefdata: Unified access to {UNICEF} indicators across {R}, {Python}, and {Stata}},
  author    = {Azevedo, Joao Pedro},
  year      = {2026},
  note      = {Working paper},
  url       = {https://github.com/unicef-drp/unicefData}
}
```

---

## Development

Development assisted by AI coding tools (GitHub Copilot, Claude). All code reviewed and validated by maintainers.

---

## Author

**Joao Pedro Azevedo** ([@jpazvd](https://github.com/jpazvd))
Chief Statistician, UNICEF Data and Analytics Section

---

## License

MIT License — See [LICENSE](LICENSE)

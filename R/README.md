# unicefData - R Package

[![R >= 3.5](https://img.shields.io/badge/R-%E2%89%A5%203.5-blue)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.3.0-green)](https://github.com/unicef-drp/unicefData)
[![Tests](https://img.shields.io/badge/tests-328%2B%20passing-brightgreen)](tests/)

**R component of the trilingual unicefData library for downloading UNICEF SDG indicators via SDMX API**

This is the R implementation of the **unicefData** package. For other implementations, see the links below.

> **Other languages:** [Python](../python/README.md) | [Stata](../stata/README.md) | [Main README](../README.md)

---

## Installation

### From GitHub (Recommended)

```r
# Install devtools if needed
install.packages("devtools")

# Install unicefData
devtools::install_github("unicef-drp/unicefData", subdir = "R")
```

### From Source

```r
# Clone the repo, then:
install.packages("R/", repos = NULL, type = "source")
```

**Verify Installation:**

```r
library(unicefData)
?unicefData
```

---

## Quick Start

### Search for Indicators

```r
library(unicefData)

# Search by keyword
search_indicators("mortality")
search_indicators("stunting")

# List all dataflows
list_dataflows()

# List categories
list_categories()

# View dataflow schema
dataflow_schema("CME")
```

### Download Data

```r
# Fetch under-5 mortality (dataflow auto-detected)
df <- unicefData("CME_MRY0T4", countries = c("ALB", "USA", "BRA"), year = "2015:2023")
head(df)
```

### Get Indicator Info

```r
# Check what disaggregations are supported
get_indicator_info("CME_MRY0T4")
```

---

## Post-Production Options

### Output Formats

```r
# Long format (default)
df <- unicefData("CME_MRY0T4")

# Wide format - years as columns
df <- unicefData("CME_MRY0T4", output_format = "wide")

# Wide indicators - indicators as columns
df <- unicefData(c("CME_MRY0T4", "CME_MRM0"), output_format = "wide_indicators")
```

### Latest Value Per Country

```r
df <- unicefData("CME_MRY0T4", latest = TRUE)
```

### Most Recent Values (MRV)

```r
df <- unicefData("CME_MRY0T4", mrv = 3)
```

### Circa (Nearest Year)

```r
df <- unicefData("NT_ANT_HAZ_NE2", year = 2015, circa = TRUE)
```

### Disaggregation Filters

```r
# By sex
df <- unicefData("NT_ANT_HAZ_NE2", sex = c("_T", "M", "F"))

# By wealth quintile
df <- unicefData("NT_ANT_HAZ_NE2", wealth = c("Q1", "Q5", "_T"))

# Combined
df <- unicefData("NT_ANT_HAZ_NE2", sex = c("_T", "M", "F"), wealth = c("Q1", "Q5"))
```

---

## Function Reference

### Main Functions

| Function | Description |
|----------|-------------|
| `unicefData()` | Download indicator data with filtering and formatting |
| `unicefData_raw()` | Raw SDMX data without post-processing |
| `get_sdmx()` | Low-level generic SDMX fetcher |

### Discovery Functions

| Function | Description |
|----------|-------------|
| `search_indicators()` | Search indicators by keyword |
| `list_dataflows()` | List all available dataflows |
| `list_categories()` | List indicator categories |
| `list_indicators()` | List indicators in a dataflow |
| `get_indicator_info()` | Show indicator metadata |
| `dataflow_schema()` | Show dataflow dimensions and attributes |
| `detect_dataflow()` | Auto-detect dataflow for an indicator |

### Metadata Functions

| Function | Description |
|----------|-------------|
| `sync_metadata()` | Sync all metadata from UNICEF API |
| `sync_all_metadata()` | Full metadata refresh |
| `clear_unicef_cache()` | Clear all 6 cache layers |
| `get_cache_info()` | Display cache status |
| `load_indicators()` | Load indicator metadata |
| `load_dataflows()` | Load dataflow metadata |
| `load_codelists()` | Load codelist metadata |

### Data Utilities

| Function | Description |
|----------|-------------|
| `clean_unicef_data()` | Clean and standardize column names |
| `filter_unicef_data()` | Apply disaggregation filters |
| `validate_data()` | Validate data against expected schema |
| `parse_year()` | Parse year range/list strings |

---

## Main Function Parameters

### `unicefData()`

| Parameter | Description |
|-----------|-------------|
| `indicator` | Indicator code(s), e.g., `"CME_MRY0T4"` or `c("CME_MRY0T4", "CME_MRM0")` |
| `dataflow` | SDMX dataflow (auto-detected if omitted) |
| `countries` | ISO3 codes, e.g., `c("ALB", "USA")` or `"all"` |
| `year` | Years: single `2020`, range `"2015:2023"`, or list `c(2015, 2018, 2020)` |
| `sex` | Sex filter: `"_T"` (total), `"F"`, `"M"` |
| `wealth` | Wealth quintiles: `"Q1"` to `"Q5"`, `"_T"` |
| `residence` | Urban/rural: `"U"`, `"R"`, `"_T"` |
| `age` | Age groups |
| `output_format` | `"long"`, `"wide"`, `"wide_indicators"` |
| `latest` | Keep only most recent value per country (`TRUE`/`FALSE`) |
| `mrv` | Keep N most recent values |
| `circa` | Find closest available year (`TRUE`/`FALSE`) |
| `add_metadata` | Add metadata columns, e.g., `c("region", "income_group")` |

---

## Common Indicators

### Child Mortality (SDG 3.2)

- `CME_MRM0` - Neonatal mortality rate
- `CME_MRY0T4` - Under-5 mortality rate

### Nutrition (SDG 2.2)

- `NT_ANT_HAZ_NE2_MOD` - Stunting prevalence
- `NT_ANT_WHZ_NE2` - Wasting prevalence

### Immunization (SDG 3.b)

- `IM_DTP3` - DTP3 coverage
- `IM_MCV1` - Measles coverage

### WASH (SDG 6)

- `WS_PPL_W-SM` - Safely managed water
- `WS_PPL_S-SM` - Safely managed sanitation

### Child Protection

- `PT_CHLD_Y0T4_REG` - Birth registration
- `PT_F_20-24_MRD_U18_TND` - Child marriage

---

## Library Structure

```
R/
├── R/                          # Source code
│   ├── unicefData.R            # Main function: unicefData()
│   ├── unicef_core.R           # Raw fetch, fallback, filtering
│   ├── get_sdmx.R              # Generic SDMX fetcher with memoisation
│   ├── get_unicef.R            # High-level wrapper
│   ├── flows.R                 # Dataflow schema loading
│   ├── indicator_registry.R    # Indicator lookup and caching
│   ├── metadata.R              # Metadata loading and versioning
│   ├── metadata_sync.R         # Sync pipeline
│   ├── schema_sync.R           # Schema synchronization
│   ├── schema_cache.R          # Schema caching
│   ├── config_loader.R         # Config path discovery
│   ├── codelist.R              # Codelist utilities
│   ├── data_utilities.R        # Safe CSV read/write
│   ├── utils.R                 # Country/year validation
│   ├── globals.R               # Package globals
│   └── zzz_aliases.R           # Function aliases
├── man/                        # Roxygen2 documentation
├── tests/                      # Test suite
│   ├── testthat/               # testthat tests (328+)
│   └── run_tests.R             # Test runner
├── vignettes/                  # Package vignettes
│   ├── unicefData-introduction.Rmd
│   └── unicefData-advanced.Rmd
├── inst/                       # Installed files
├── examples/                   # Usage examples (7 scripts)
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Exported functions
└── NEWS.md                     # Changelog
```

---

## Metadata Synchronization

### Refresh Metadata

```r
# Full metadata sync
sync_all_metadata()

# Sync specific components
sync_dataflows()
sync_indicators()
sync_codelists()

# Check cache status
get_cache_info()
```

### Cache Management

```r
# Clear all caches (6 layers)
clear_unicef_cache()

# Clear specific caches
clear_config_cache()
clear_schema_cache()
```

---

## Quality Assurance

The R package includes a comprehensive test suite:

- **328+ tests** across 11 families
- **0 errors, 0 warnings** on R CMD check
- Tested on R-hub: Windows, Linux, macOS
- Test families include: unit tests, discovery, transformations, deterministic fixtures, sync pipeline, error conditions, cross-platform validation

### Run Tests

```r
# Full test suite
devtools::test()

# R CMD check
devtools::check()
```

See [tests/README.md](tests/README.md) for test documentation.

---

## Troubleshooting

### Package Not Found

```r
# Reinstall
devtools::install_github("unicef-drp/unicefData", subdir = "R", force = TRUE)

# Check
library(unicefData)
packageVersion("unicefData")
```

### Connection Errors

```r
# Test connectivity
httr::GET("https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow/UNICEF/CME/latest")
```

### Indicator Not Found

```r
# Search for valid indicators
search_indicators("mortality")

# Check indicator info
get_indicator_info("YOUR_INDICATOR")
```

### Cache Issues

```r
# Clear all caches and reload
clear_unicef_cache()
```

---

## Dependencies

- **R:** >= 3.5.0
- **Required packages:** httr, readr, dplyr, tibble, xml2, memoise, countrycode, yaml, tools, jsonlite, magrittr, purrr, rlang, digest, tidyr
- **Suggested packages:** testthat (>= 3.0.0), devtools, knitr, rmarkdown
- **Internet:** Required for API access

---

## Version History

### v2.3.0 (2026-02-19)

- CRAN compliance: cache moved from `.unicef_cache/` to `tempdir()`
- DESCRIPTION updated per CRAN reviewer feedback
- 328+ automated tests, 0 errors / 0 warnings / 2 notes on R CMD check

### v2.2.0 (2026-02-17)

- 5 new testthat test files (transformations, deterministic, discovery, sync, errors)
- Deterministic fixture system with automated extraction
- Fixed category resolution fallback in `list_categories()`
- Input validation for `unicefData()` with helpful hints

### v2.1.0 (2026-02-07)

- `clear_unicef_cache()` — clears 6 cache layers with optional reload
- Fixed `apply_circa()` NA handling
- Cross-language validation tests (13/13 passing)

### v2.0.0 (2026-01-31)

- Fixed critical path extraction bug in metadata sync
- Roxygen2 documentation regenerated for all functions
- 26 tests passing, all R CMD check tests clean

See [NEWS.md](NEWS.md) for complete version history.

---

## Data Citation and Provenance

**Important Note on Data Vintages**

Official statistics are subject to revisions. UNICEF indicators are regularly updated based on new surveys, censuses, and improved modeling. Historical values may be revised retroactively.

**For reproducible research:**

1. **Document the indicator code** - e.g., `CME_MRY0T4`
2. **Record the download date** - e.g., "Data downloaded: 2026-02-19"
3. **Cite the data source** - Reference both the package and the UNICEF Data Warehouse
4. **Archive your dataset** - Save a copy of the exact data used

**Example citation:**

> Under-5 mortality data (indicator: CME_MRY0T4) accessed from UNICEF Data Warehouse via unicefData R package (v2.3.0) on 2026-02-19. Data available at: https://sdmx.data.unicef.org/

## Citation

If you use this package, please cite:

> Azevedo, Joao Pedro (2026). "unicefData: Unified access to UNICEF indicators across R, Python, and Stata." Mimeo, UNICEF Chief Statistician Office.

---

## Acknowledgments

This package was developed at the UNICEF Data and Analytics Section. The author gratefully acknowledges the collaboration of **Lucas Rodrigues**, **Yang Liu**, and **Karen Avanesian**, whose technical contributions and feedback were instrumental in the development of this package.

Special thanks to **Yves Jaques**, **Alberto Sibileau**, and **Daniele Olivotti** for designing and maintaining the UNICEF SDMX data warehouse infrastructure that makes this package possible.

Development was assisted by AI coding tools (GitHub Copilot, Claude). All code has been reviewed, tested, and validated by the package maintainers.

## Disclaimer

**This package is provided for research and analytical purposes.**

The `unicefData` package provides programmatic access to UNICEF's public data warehouse. While the author is affiliated with UNICEF, **this package is not an official UNICEF product and the statements in this documentation are the views of the author and do not necessarily reflect the policies or views of UNICEF**.

Data accessed through this package comes from the [UNICEF Data Warehouse](https://sdmx.data.unicef.org/). Users should verify critical data points against official UNICEF publications at [data.unicef.org](https://data.unicef.org/).

The designations employed and the presentation of material in this package do not imply the expression of any opinion whatsoever on the part of UNICEF concerning the legal status of any country, territory, city or area or of its authorities, or concerning the delimitation of its frontiers or boundaries.

---

## Author

**Joao Pedro Azevedo** ([@jpazvd](https://github.com/jpazvd))
Chief Statistician, UNICEF Data and Analytics Section
Email: jpazevedo@unicef.org
Website: [jpazvd.github.io](https://jpazvd.github.io/)

---

## License

MIT License - See [LICENSE](LICENSE)

## Support

- **GitHub Issues:** [github.com/unicef-drp/unicefData/issues](https://github.com/unicef-drp/unicefData/issues)
- **Help:** `?unicefData`
- **Vignettes:** `vignette("unicefData-introduction")`

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

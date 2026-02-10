# unicefData - R Package

[![R-CMD-check](https://github.com/unicef-drp/unicefData/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**R component of the trilingual unicefData library for downloading UNICEF SDG indicators via SDMX API**

This is the R implementation of the **unicefData** package. For other implementations, see the links below.

> **Other languages:** [Python](../python/README.md) | [Stata](../stata/README.md) | [Main README](../README.md)

---

## Installation

```r
# Install from GitHub (recommended)
devtools::install_github("unicef-drp/unicefData")

# Load the package
library(unicefData)
```

### Development Installation

```r
# Clone repository first
# git clone https://github.com/unicef-drp/unicefData.git

# Install from local source
devtools::install("path/to/unicefData")

# Or load without installing (for development)
devtools::load_all("path/to/unicefData")
```

---

## Quick Start

### Search for Indicators

```r
library(unicefData)

# Search by keyword
search_indicators("mortality")
search_indicators("stunting")
search_indicators("immunization")

# List all categories
list_categories()

# Search within a category
search_indicators(category = "CME")
search_indicators("rate", category = "CME")
```

### Download Data

```r
# Fetch under-5 mortality for specific countries
# Dataflow is auto-detected from indicator code!
df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA", "BRA"),
  year = "2015:2023"  # Range, single year, or c(2015, 2018, 2020)
)

print(head(df))
```

### View Dataflow Schema

```r
# Get schema for a dataflow
schema <- dataflow_schema("CME")
print(schema)

# Access components
schema$dimensions  # Available dimensions
schema$attributes  # Available attributes
```

---

## Post-Production Options

### Output Formats

```r
# Long format (default) - one row per observation
df <- unicefData(indicator = "CME_MRY0T4", format = "long")

# Wide format - years as columns
df <- unicefData(indicator = "CME_MRY0T4", format = "wide")
# Result: iso3 | country | y2015 | y2016 | y2017 | ...

# Wide indicators - indicators as columns (multiple indicators)
df <- unicefData(
  indicator = c("CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"),
  format = "wide_indicators"
)
# Result: iso3 | country | period | CME_MRY0T4 | NT_ANT_HAZ_NE2_MOD
```

### Latest Value Per Country

```r
# Get only the most recent value per country
df <- unicefData(indicator = "CME_MRY0T4", latest = TRUE)
```

### Most Recent Values (MRV)

```r
# Keep the N most recent years per country
df <- unicefData(indicator = "CME_MRY0T4", mrv = 3)
```

### Circa (Nearest Year Matching)

```r
# Find closest available year when exact year unavailable
df <- unicefData(indicator = "NT_ANT_HAZ_NE2", year = 2015, circa = TRUE)
```

### Add Metadata

```r
# Enrich data with region, income group, etc.
df <- unicefData(
  indicator = "CME_MRY0T4",
  add_metadata = c("region", "income_group", "continent")
)
```

### Combining Options

```r
# Cross-sectional analysis with metadata
df <- unicefData(
  indicator = c("CME_MRY0T4", "NT_ANT_HAZ_NE2_MOD"),
  format = "wide_indicators",
  latest = TRUE,
  add_metadata = c("region", "income_group"),
  dropna = TRUE
)
```

---

## API Reference

### unicefData()

Main function for fetching UNICEF indicator data.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `indicator` | character | required | Indicator code(s), e.g., `"CME_MRY0T4"` |
| `dataflow` | character | auto-detect | SDMX dataflow ID (optional) |
| `countries` | character | NULL (all) | ISO3 country codes |
| `year` | int/char | NULL (all) | Year(s): single, range `"2015:2023"`, or vector |
| `circa` | logical | FALSE | Find closest available year |
| `sex` | character | `"_T"` | Sex filter: `"_T"`, `"F"`, `"M"`, `"ALL"` |
| `tidy` | logical | TRUE | Return cleaned data |
| `country_names` | logical | TRUE | Add country name column |
| `max_retries` | integer | 3 | Retry attempts on failure |

#### Post-Production Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `format` | character | `"long"` | `"long"`, `"wide"`, or `"wide_indicators"` |
| `latest` | logical | FALSE | Keep only latest value per country |
| `mrv` | integer | NULL | Keep N most recent values |
| `add_metadata` | character | NULL | Metadata to add |
| `dropna` | logical | FALSE | Remove rows with missing values |
| `simplify` | logical | FALSE | Keep only essential columns |

### search_indicators()

Search for indicators by keyword or category.

```r
search_indicators(query = "mortality")
search_indicators(category = "CME")
search_indicators(query = "rate", category = "CME", limit = 20)
```

### list_categories()

List all available indicator categories with counts.

```r
list_categories()
```

### list_dataflows()

List available SDMX dataflows.

```r
list_dataflows()
```

### dataflow_schema()

Get schema (dimensions, attributes) for a dataflow.

```r
schema <- dataflow_schema("CME")
```

### clear_unicef_cache()

Clear all 6 cache layers and optionally reload YAML metadata.

```r
clear_unicef_cache()          # Clear all caches
clear_unicef_cache(reload = TRUE)  # Clear and reload
```

### refresh_indicator_cache()

Force refresh of the indicator metadata cache.

```r
n <- refresh_indicator_cache()
```

### get_cache_info()

Get information about the metadata cache.

```r
info <- get_cache_info()
```

---

## Time Period Handling

The UNICEF SDMX API returns TIME_PERIOD in various formats. This library converts them to decimal years:

| Original | Decimal | Calculation |
|----------|---------|-------------|
| `2020` | `2020.0` | Integer year |
| `2020-01` | `2020.0833` | 2020 + 1/12 |
| `2020-06` | `2020.5000` | 2020 + 6/12 |

```r
df <- unicefData(indicator = "NT_ANT_HAZ_NE2", countries = "BGD")
head(df[, c("iso3", "period", "value")])
#   iso3       period  value
# 1  BGD  2011.583333   40.0  # July 2011
# 2  BGD  2011.750000   41.3  # September 2011
```

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
- `WS_PPL_W-SM` - Safely managed drinking water
- `WS_PPL_S-SM` - Safely managed sanitation

### Child Protection (SDG 5.3, 16.2)
- `PT_CHLD_Y0T4_REG` - Birth registration
- `PT_F_20-24_MRD_U18_TND` - Child marriage

---

## Backward Compatibility

Legacy parameter names are supported:

| Legacy | Current |
|--------|---------|
| `flow` | `dataflow` |
| `key` | `indicator` |
| `start_year` | `year` (use `"2015:2023"`) |
| `end_year` | `year` |
| `retry` | `max_retries` |

---

## Cache Locations

| Environment | Path |
|-------------|------|
| Standard | `tools::R_user_dir("unicefdata", "cache")/metadata/current/` |
| Fallback | `~/.unicef_data/r/metadata/current/` |
| Override | Set `UNICEF_DATA_HOME_R` or `UNICEF_DATA_HOME` |
| Development | `R/metadata/current/` |

---

## Metadata Synchronization

### Refresh Metadata

```r
# Sync all metadata from UNICEF SDMX API
source("R/metadata_sync.R")
sync_all_metadata(verbose = TRUE)

# Refresh indicator cache
source("R/indicator_registry.R")
refresh_indicator_cache()

# Sync dataflow schemas
source("R/schema_sync.R")
sync_dataflow_schemas()
```

### Check Cache Status

```r
info <- get_cache_info()
print(info$age_days)
print(info$indicator_count)
```

---

## Troubleshooting

### Package Not Found

```r
# Ensure devtools is installed
install.packages("devtools")

# Reinstall from GitHub
devtools::install_github("unicef-drp/unicefData", force = TRUE)
```

### Connection Errors

```r
# Increase retry attempts
df <- unicefData(indicator = "CME_MRY0T4", max_retries = 5)
```

### Invalid Indicator

```r
# Search for valid indicators
search_indicators("mortality")

# Check if indicator exists
get_indicator_info("CME_MRY0T4")
```

### Stale Cache

```r
# Clear all caches and reload
clear_unicef_cache(reload = TRUE)

# Or just refresh indicator cache
refresh_indicator_cache()
```

---

## Examples

See the `R/examples/` directory:

- `00_quick_start.R` - Basic usage
- `01_indicator_discovery.R` - Finding indicators
- `02_sdg_indicators.R` - SDG-specific queries
- `03_data_formats.R` - Wide/long formats
- `04_metadata_options.R` - Adding metadata
- `05_advanced_features.R` - Circa, MRV, etc.

---

## Dependencies

- **httr** - HTTP requests
- **readr** - CSV parsing
- **dplyr** - Data manipulation
- **tibble** - Data frames
- **xml2** - XML parsing
- **memoise** - Caching
- **countrycode** - Country name lookup
- **yaml** - YAML parsing
- **jsonlite** - JSON parsing

---

## Version History

### v2.1.0 (2026-02-07)
- Added `clear_unicef_cache()` — clears 6 cache layers with optional reload
- Fixed `apply_circa()` NA handling — countries with all-NA values no longer dropped
- Replaced hardcoded paths with `system.file()` resolution
- Cross-language fixture tests (13/13 passing)

### v2.0.0 (2026-01-31)
- Fixed SYNC-02 enrichment bug
- All QA tests passing (R: 26, Python: 28, Stata: 38)
- Version alignment across platforms

### v1.5.2 (2026-01-07)
- Fixed 404 fallback behavior
- Added dynamic User-Agent strings
- Added comprehensive test coverage

### v1.5.0 (2025-12-19)
- Cross-platform release
- Unified defaults for disaggregation filters
- Metadata cache improvements

See [NEWS.md](../NEWS.md) for complete changelog.

---

## Citation

If you use this package, please cite:

> Azevedo, Joao Pedro (2026). "unicefdata: Unified access to UNICEF indicators across R, Python, and Stata." Mimeo, UNICEF Chief Statistician Office.

---

## Development

Development assisted by AI coding tools (GitHub Copilot, Claude). All code reviewed and validated by maintainers.

---

## Author

**Joao Pedro Azevedo** ([@jpazvd](https://github.com/jpazvd))
Chief Statistician, UNICEF Data and Analytics Section
Email: jpazevedo@unicef.org
Website: [jpazvd.github.io](https://jpazvd.github.io/)

---

## License

MIT License - See [LICENSE](../LICENSE)

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

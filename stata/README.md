# unicefData for Stata

[![Stata 14+](https://img.shields.io/badge/Stata-14+-1a5276.svg)](https://www.stata.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.5.0-blue.svg)]()

**Stata package for downloading UNICEF child welfare indicators via SDMX API**

This Stata implementation is part of the trilingual [unicefData](https://github.com/unicef-drp/unicefData) package, providing access to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) with the same functionality as the R and Python versions.

> 📦 **Other languages:** [R](../R/README.md) | [Python](../python/README.md) | [Main README](../README.md)

---

## 🌐 Trilingual Package

The **unicefData** repository provides consistent APIs in R, Python, and Stata:

| Feature | R | Python | Stata |
|---------|---|--------|-------|
| Fetch data | `get_unicef()` | `get_unicef()` | `unicefdata` |
| **Search indicators** | `search_indicators()` | `search_indicators()` | `unicefdata, search()` |
| **List categories** | `list_categories()` | `list_categories()` | `unicefdata, categories` |
| **List dataflows** | `list_sdmx_flows()` | `list_dataflows()` | `unicefdata, flows` |
| **Dataflow schema** | `dataflow_schema()` | `dataflow_schema()` | `unicefdata, dataflow()` |
| **Indicator info** | `get_indicator_info()` | `get_indicator_info()` | `unicefdata, info()` |
| Auto dataflow detection | ✅ | ✅ | ✅ |
| 700+ indicators | ✅ | ✅ | ✅ |
| Frames support (v16+) | N/A | N/A | ✅ |

---

## Installation

### From GitHub (recommended)

```stata
* Install from GitHub
net install unicefdata, from("https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata") replace

* Also install the yaml dependency (required for metadata)
net install yaml, from("https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/src/y") replace

* Verify installation
which unicefdata
help unicefdata
```

### Manual Installation

Copy all `.ado`, `.sthlp`, and `.yaml` files from `stata/src/` to your personal ado directory:

```stata
* Find your personal ado directory
sysdir

* Copy files to PLUS or PERSONAL directory
* - src/u/*.ado, *.sthlp → u/
* - src/_/*.ado, *.yaml → _/
* - src/y/*.ado, *.sthlp → y/
```

---

## 🎯 Quick Start

### Find Indicators (Discovery Commands)

Don't know the indicator code? Use the discovery commands!

```stata
* List all available categories with indicator counts
unicefdata, categories

* Search for mortality-related indicators
unicefdata, search(mortality)

* Search within a specific category/dataflow
unicefdata, search(rate) dataflow(CME)

* List all indicators in a dataflow
unicefdata, indicators(CME)

* Get detailed info about an indicator
unicefdata, info(CME_MRY0T4)

* View dataflow schema (dimensions and attributes)
unicefdata, dataflow(CME)

* List all available dataflows
unicefdata, flows
unicefdata, flows detail    // with names
```

### Fetch Data

```stata
* Download under-5 mortality rate for selected countries
* (dataflow is auto-detected from indicator code!)
unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear

* View the data
list iso3 country indicator period value in 1/10

* Download nutrition indicators with filters
unicefdata, indicator(NT_ANT_HAZ_NE2) sex(F) residence(RURAL) clear

* Download all indicators from a dataflow
unicefdata, dataflow(CME) countries(BGD NPL PAK) clear
```

---

## Syntax

### Discovery Commands

```stata
unicefdata, categories                     // List all categories with counts
unicefdata, flows [detail]                 // List available dataflows
unicefdata, dataflow(name)                 // View dataflow schema (dimensions/attributes)
unicefdata, search(keyword) [dataflow()] [limit(#)]  // Search indicators
unicefdata, indicators(dataflow)           // List indicators in dataflow
unicefdata, info(indicator_code)           // Get indicator details + disaggregations
```

#### Example: Dataflow Schema

```stata
. unicefdata, dataflow(CME)

----------------------------------------------------------------------
Dataflow Schema: CME
----------------------------------------------------------------------

Name: Child Mortality
Version: 1.0
Agency: UNICEF

Dimensions (4):
  REF_AREA
  INDICATOR
  SEX
  WEALTH_QUINTILE

Attributes (8):
  DATA_SOURCE
  COUNTRY_NOTES
  REF_PERIOD
  UNIT_MEASURE
  LOWER_BOUND
  UPPER_BOUND
  OBS_STATUS

----------------------------------------------------------------------
```

#### Example: Indicator Info with Supported Disaggregations

```stata
. unicefdata, info(CME_MRY0T4)

----------------------------------------------------------------------
Indicator Information: CME_MRY0T4
----------------------------------------------------------------------

 Code:        CME_MRY0T4
 Name:        Under-five mortality rate
 Category:    CME

 Description:
   Probability of dying between birth and exactly 5 years of age, 
   expressed per 1,000 live births

 Supported Disaggregations:
   sex:          Yes (SEX)
   age:          No
   wealth:       Yes (WEALTH_QUINTILE)
   residence:    No
   maternal_edu: No

----------------------------------------------------------------------
Usage: unicefdata, indicator(CME_MRY0T4) countries(AFG BGD) year(2020:2022)
----------------------------------------------------------------------
```

### Data Retrieval

```stata
unicefdata, indicator(string) [options]
unicefdata, dataflow(string) [options]
```

### Main Options

| Option | Description |
|--------|-------------|
| `indicator(string)` | Indicator code(s) to download (e.g., CME_MRY0T4) |
| `dataflow(string)` | Dataflow ID (e.g., CME, NUTRITION) |
| `countries(string)` | ISO3 country codes, space or comma separated |
| `year(string)` | Year filter: single (2020), range (2015:2023), or list (2015,2018,2020) |

### Disaggregation Filters

| Option | Description |
|--------|-------------|
| `sex(string)` | Sex filter: `_T` (total), `F` (female), `M` (male) |
| `age(string)` | Age group filter |
| `wealth(string)` | Wealth quintile: `Q1`-`Q5` |
| `residence(string)` | Residence filter: `URBAN`, `RURAL` |
| `maternal_edu(string)` | Maternal education level |

### Output Options

| Option | Description |
|--------|-------------|
| `long` | Keep data in long format (default) |
| `wide` | Reshape data to wide format |
| `wide_indicators` | Reshape with indicators as columns |
| `dropna` | Drop observations with missing values |
| `simplify` | Keep only essential columns |
| `latest` | Keep only most recent value per country |
| `mrv(#)` | Keep N most recent values per country |
| `addmeta(string)` | Add metadata: `region`, `income_group`, `continent` |
| `clear` | Replace data in memory |
| `verbose` | Display progress messages |

---

## 📅 Time Period Handling

The UNICEF SDMX API returns TIME_PERIOD values in various formats. This package preserves the original format and creates a numeric `year` variable:

| Original Format | Year Variable | Description |
|----------------|---------------|-------------|
| `2020` | `2020` | Annual data |
| `2020-01` | `2020` | Monthly data (January) |
| `2020-Q2` | `2020` | Quarterly data |

---

## Metadata Sync

Keep your local metadata (indicators, countries, dataflows) up to date:

```stata
* Sync all metadata from UNICEF API
unicefdata_sync, all

* Sync specific metadata types
unicefdata_sync, indicators
unicefdata_sync, countries
unicefdata_sync, dataflows

* View sync history
unicefdata_sync, history

* View help
help unicefdata_sync
```

---

## File Structure

```
stata/
├── src/
│   ├── u/                              # Main user-facing commands
│   │   ├── unicefdata.ado              # Main command (v1.5.0)
│   │   ├── unicefdata.sthlp            # Help file
│   │   ├── unicefdata_sync.ado         # Metadata sync command
│   │   └── unicefdata_sync.sthlp       # Sync help file
│   ├── _/                              # Internal helpers + YAML metadata
│   │   ├── _unicef_list_categories.ado # Discovery: list categories
│   │   ├── _unicef_list_dataflows.ado  # Discovery: list dataflows
│   │   ├── _unicef_search_indicators.ado # Discovery: search indicators
│   │   ├── _unicef_list_indicators.ado # Discovery: list indicators
│   │   ├── _unicef_indicator_info.ado  # Discovery: indicator info
│   │   ├── _unicefdata_dataflows.yaml  # Metadata: 69 dataflows
│   │   ├── _unicefdata_indicators.yaml # Metadata: full indicator catalog
│   │   ├── _unicefdata_codelists.yaml  # Metadata: valid codes
│   │   ├── _unicefdata_countries.yaml  # Metadata: country codes
│   │   ├── _unicefdata_regions.yaml    # Metadata: regional codes
│   │   └── _dataflows/                 # Per-dataflow schemas (69 files)
│   │       ├── CME.yaml                # Child mortality disaggregations
│   │       ├── EDUCATION.yaml          # Education disaggregations
│   │       └── ...                     # All 69 dataflow schemas
│   ├── y/                              # YAML parser dependency
│   │   ├── yaml.ado
│   │   └── yaml.sthlp
│   └── py/                             # Python helpers (optional)
│       ├── python_xml_helper.py
│       ├── stata_schema_sync.py
│       └── unicefdata_xml2yaml.py
├── examples/                           # Example do-files
├── tests/                              # Test suite
├── unicefdata.pkg                      # Stata package file
└── stata.toc                           # Table of contents
```

---

## Examples

### Discovery Workflow

```stata
* Step 1: See what categories are available
unicefdata, categories
/*
  Category                    Count
  --------------------------------------------------
  CME                           45
  NUTRITION                     32
  EDUCATION                     28
  ...
*/

* Step 2: Search for indicators in a category
unicefdata, search(mortality) dataflow(CME) limit(50)

* Step 3: Get details about a specific indicator
unicefdata, info(CME_MRY0T4)

* Step 4: Fetch the data
unicefdata, indicator(CME_MRY0T4) countries(BGD IND PAK) clear
```

### Basic Usage

```stata
* Download under-5 mortality for all countries
unicefdata, indicator(CME_MRY0T4) clear

* Filter by year range
unicefdata, indicator(CME_MRY0T4) year(2010:2020) clear

* Filter by specific countries
unicefdata, indicator(CME_MRY0T4) countries(AFG BGD IND PAK) clear

* Get latest value only per country
unicefdata, indicator(CME_MRY0T4) latest clear

* Add regional metadata
unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) clear
```

### Multiple Indicators

```stata
* Download multiple indicators
unicefdata, indicator(CME_MRY0T4 CME_MRM0) countries(BGD IND) clear

* Wide format with indicators as columns
unicefdata, indicator(CME_MRY0T4 CME_MRM0) wide_indicators clear
```

### Working with Disaggregations

```stata
* Female-only stunting data
unicefdata, indicator(NT_ANT_HAZ_NE2) sex(F) clear

* Rural residence only
unicefdata, indicator(NT_ANT_HAZ_NE2) residence(RURAL) clear

* Combine filters
unicefdata, indicator(NT_ANT_HAZ_NE2) sex(F) residence(RURAL) wealth(Q1) clear
```

### Data Export

```stata
* Download and export to Excel
unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear
export excel using "mortality_data.xlsx", firstrow(variables) replace

* Export to CSV
export delimited using "mortality_data.csv", replace
```

---

## Comparison with wbopendata

If you're familiar with `wbopendata` (World Bank data), the syntax is very similar:

| wbopendata | unicefdata | Description |
|------------|------------|-------------|
| `wbopendata, indicator(SP.DYN.LE00.IN)` | `unicefdata, indicator(CME_MRY0T4)` | Download indicator |
| `country(USA BRA)` | `countries(USA BRA)` | Filter countries |
| `long` | `long` | Long format |
| `clear` | `clear` | Clear data in memory |

**unicefdata extras:**
- `unicefdata, categories` - List all indicator categories
- `unicefdata, search(keyword)` - Search indicators by keyword
- `unicefdata, flows` - List available dataflows
- `unicefdata, dataflow(CME)` - View dataflow schema (dimensions/attributes)
- Auto-detect dataflow from indicator code

---

## Troubleshooting

### Common Issues

1. **"command not found"**: Make sure ado files are in your adopath
   ```stata
   adopath
   which unicefdata
   ```

2. **"yaml command not found"**: Install the yaml dependency
   ```stata
   net install yaml, from("https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/src/y") replace
   ```

3. **"Metadata not found"**: Sync metadata from UNICEF API
   ```stata
   unicefdata_sync, all
   ```

4. **Network errors**: Check internet connection, try increasing retries
   ```stata
   unicefdata, indicator(CME_MRY0T4) max_retries(5) clear
   ```

5. **Invalid indicator**: Search for correct indicator code
   ```stata
   unicefdata, search(mortality)
   ```

---

## Requirements

- **Stata 14.0** or higher (Stata 16+ recommended for frames support)
- **yaml.ado** - YAML parser (included in distribution)
- Internet connection
- (Optional) Python 3.8+ for enhanced XML parsing during sync

---

## Version History

| Version | Date | Changes |
|---------|------|---------|| 1.5.0 | Dec 2025 | Added `dataflow()` schema display, `dataflows` alias, improved search hyperlinks || 1.3.1 | Dec 2025 | Added `categories` command, `dataflow()` filter in search |
| 1.3.0 | Dec 2025 | Discovery commands (flows, search, indicators, info), frames support |
| 1.2.0 | Dec 2025 | YAML-based metadata, validation |
| 1.1.0 | Dec 2025 | API alignment with R/Python |
| 1.0.0 | Dec 2025 | Initial release |

---

## Author

**Joao Pedro Azevedo** ([@jpazvd](https://github.com/jpazvd))  
Chief Statistician, UNICEF Data and Analytics Section

## License

MIT License

## Links

- Main repository: https://github.com/unicef-drp/unicefData
- UNICEF Data Portal: https://data.unicef.org/
- SDMX API Docs: https://data.unicef.org/sdmx-api-documentation/

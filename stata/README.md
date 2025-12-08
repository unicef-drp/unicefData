# unicefData for Stata

[![Stata 14+](https://img.shields.io/badge/Stata-14+-1a5276.svg)](https://www.stata.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Stata package for downloading UNICEF child welfare indicators via SDMX API**

This Stata implementation is part of the trilingual [unicefData](https://github.com/unicef-drp/unicefData) package, providing access to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) with the same functionality as the R and Python versions.

---

## Installation

### From GitHub (recommended)

```stata
* Install from GitHub
net install unicefdata, from("https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata") replace

* Verify installation
which unicefdata
help unicefdata
```

### Manual Installation

Copy all `.ado` and `.sthlp` files from `stata/src/u/` and `stata/src/_/` to your personal ado directory:

```stata
* Find your personal ado directory
sysdir

* Copy files to PERSONAL directory (e.g., c:\ado\personal\)
```

---

## Quick Start

```stata
* Download under-5 mortality rate for selected countries
unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) ///
    start_year(2015) end_year(2023) clear

* View the data
list iso3 country indicator period value in 1/10

* Download nutrition indicators with filters
unicefdata, indicator(NT_ANT_HAZ_NE2) sex(F) residence(RURAL) clear

* Download all indicators from a dataflow
unicefdata, dataflow(CME) countries(BGD NPL PAK) clear
```

---

## Syntax

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
| `start_year(#)` | Start year for data range |
| `end_year(#)` | End year for data range |

### Disaggregation Filters

| Option | Description |
|--------|-------------|
| `sex(string)` | Sex filter: `_T` (total), `F` (female), `M` (male) |
| `age(string)` | Age group filter |
| `wealth(string)` | Wealth quintile filter |
| `residence(string)` | Residence filter: `URBAN`, `RURAL` |

### Output Options

| Option | Description |
|--------|-------------|
| `long` | Keep data in long format (default) |
| `wide` | Reshape data to wide format |
| `dropna` | Drop observations with missing values |
| `simplify` | Keep only essential columns |
| `latest` | Keep only most recent value per country |
| `mrv(#)` | Keep N most recent values per country |
| `clear` | Replace data in memory |
| `verbose` | Display progress messages |

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

* View help
help unicefdata_sync
```

---

## File Structure

```
stata/
├── src/
│   ├── u/                          # Main user-facing commands
│   │   ├── unicefdata.ado          # Main data download command
│   │   ├── unicefdata.sthlp        # Help file
│   │   ├── unicefdata_sync.ado     # Metadata sync command
│   │   ├── unicefdata_sync.sthlp   # Sync help file
│   │   ├── unicefdata_xmltoyaml.ado # XML to YAML converter
│   │   └── unicefdata_xml2yaml.py  # Python XML parser (optional)
│   └── _/                          # Internal subroutines
│       ├── _xmltoyaml_parse.ado    # Parser router
│       ├── _xmltoyaml_parse_python.ado
│       ├── _xmltoyaml_parse_stata.ado
│       └── ...
├── metadata/
│   └── current/                    # Current YAML metadata files
│       ├── _unicefdata_indicators.yaml
│       ├── _unicefdata_countries.yaml
│       ├── _unicefdata_regions.yaml
│       └── _unicefdata_dataflows.yaml
├── examples/                       # Example do-files
├── tests/                          # Test suite
├── unicefdata.pkg                  # Stata package file
└── stata.toc                       # Table of contents
```

---

## Examples

### Basic Usage

```stata
* Download under-5 mortality for all countries
unicefdata, indicator(CME_MRY0T4) clear

* Filter by year range
unicefdata, indicator(CME_MRY0T4) start_year(2010) end_year(2020) clear

* Filter by specific countries
unicefdata, indicator(CME_MRY0T4) countries(AFG BGD IND PAK) clear

* Get latest value only per country
unicefdata, indicator(CME_MRY0T4) latest clear
```

### Multiple Indicators

```stata
* Download multiple indicators
unicefdata, indicator(CME_MRY0T4 CME_MRM0) countries(BGD IND) clear

* Wide format (indicators as columns)
unicefdata, indicator(CME_MRY0T4 CME_MRM0) wide clear
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

---

## Troubleshooting

### Common Issues

1. **"command not found"**: Make sure ado files are in your adopath
   ```stata
   adopath
   which unicefdata
   ```

2. **Network errors**: Check internet connection, try increasing retries
   ```stata
   unicefdata, indicator(CME_MRY0T4) max_retries(5) clear
   ```

3. **Invalid indicator**: Check spelling against metadata
   ```stata
   * Sync metadata first
   unicefdata_sync, indicators
   ```

---

## Requirements

- **Stata 14.0** or higher
- Internet connection
- (Optional) Python 3.8+ for enhanced XML parsing

---

## Author

Joao Pedro Azevedo (UNICEF)

## License

MIT License

## Links

- Main repository: https://github.com/unicef-drp/unicefData
- UNICEF Data Portal: https://data.unicef.org/
- SDMX API Docs: https://data.unicef.org/sdmx-api-documentation/

# unicefData - Stata Package

[![Stata 14+](https://img.shields.io/badge/Stata-14%2B-blue)](https://www.stata.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.1.0-green)](https://github.com/unicef-drp/unicefData)
[![Tests](https://img.shields.io/badge/tests-38%2F38%20passing-brightgreen)](stata/qa/)

**Stata component of the trilingual unicefData library for downloading UNICEF SDG indicators via SDMX API**

This is the Stata implementation of the **unicefData** package. For other implementations, see the links below.

> **Other languages:** [R](../R/README.md) | [Python](../python/README.md) | [Main README](../README.md)

---

## Installation

### From GitHub (Recommended)

```stata
* First install github package (one-time)
net install github, from("https://haghish.github.io/github/")

* Install unicefData
github install unicef-drp/unicefData, package(stata)
```

### From URL

```stata
net install unicefdata, from("https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/ssc") replace
```

### Manual Installation

1. Copy `src/u/unicefdata.ado` to your ado path
2. Copy `src/u/unicefdata.sthlp` to your ado path
3. Copy `metadata/current/` folder to `ado/plus/_/`

**Verify Installation:**

```stata
which unicefdata
help unicefdata
```

---

## Quick Start

### Search for Indicators

```stata
* Search by keyword
unicefdata, search(mortality)
unicefdata, search(stunting)

* List all dataflows
unicefdata, flows

* List categories
unicefdata, categories

* View dataflow schema
unicefdata, dataflow(CME)
```

### Download Data

```stata
* Fetch under-5 mortality (dataflow auto-detected)
unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) year(2015:2023) clear

* View the data
list iso3 country indicator period value in 1/10
describe
```

### Get Indicator Info

```stata
* Check what disaggregations are supported
unicefdata, info(CME_MRY0T4)
```

---

## Post-Production Options

### Output Formats

```stata
* Long format (default)
unicefdata, indicator(CME_MRY0T4) clear

* Wide format - years as columns
unicefdata, indicator(CME_MRY0T4) format(wide) clear

* Wide indicators - indicators as columns
unicefdata, indicator(CME_MRY0T4 NT_ANT_HAZ_NE2_MOD) format(wide_indicators) clear
```

### Latest Value Per Country

```stata
unicefdata, indicator(CME_MRY0T4) latest clear
```

### Most Recent Values (MRV)

```stata
unicefdata, indicator(CME_MRY0T4) mrv(3) clear
```

### Circa (Nearest Year)

```stata
unicefdata, indicator(NT_ANT_HAZ_NE2) year(2015) circa clear
```

### Disaggregation Filters

```stata
* By sex
unicefdata, indicator(NT_ANT_HAZ_NE2) sex(_T M F) clear

* By wealth quintile
unicefdata, indicator(NT_ANT_HAZ_NE2) wealth(Q1 Q5 _T) clear

* Combined
unicefdata, indicator(NT_ANT_HAZ_NE2) sex(_T M F) wealth(Q1 Q5) clear
```

---

## Command Reference

### Syntax

```stata
unicefdata, indicator(code) [options]
```

### Main Options

| Option | Description |
|--------|-------------|
| `indicator(code)` | Indicator code(s), e.g., `CME_MRY0T4` |
| `dataflow(name)` | SDMX dataflow (auto-detected if omitted) |
| `countries(list)` | ISO3 codes, e.g., `ALB USA BRA` or `all` |
| `year(range)` | Years: single `2020`, range `2015:2023`, or list |

### Disaggregation Options

| Option | Description |
|--------|-------------|
| `sex(list)` | Sex filter: `_T` (total), `F`, `M` |
| `wealth(list)` | Wealth quintiles: `Q1` to `Q5`, `_T` |
| `residence(list)` | Urban/rural: `U`, `R`, `_T` |
| `age(list)` | Age groups |

### Post-Production Options

| Option | Description |
|--------|-------------|
| `format(type)` | `long`, `wide`, `wide_indicators` |
| `latest` | Keep only most recent value per country |
| `mrv(n)` | Keep N most recent values |
| `circa` | Find closest available year |

### Discovery Options

| Option | Description |
|--------|-------------|
| `search(term)` | Search indicators by keyword |
| `flows` | List all dataflows |
| `categories` | List indicator categories |
| `dataflow(name)` | Show dataflow schema |
| `info(code)` | Show indicator info |

### Other Options

| Option | Description |
|--------|-------------|
| `clear` | Replace data in memory |
| `clearcache` | Drop cached frames and reload metadata |
| `noerror` | Return empty dataset instead of error on failure |
| `fromfile(path)` | Load data from CSV fixture instead of API |
| `tofile(path)` | Save API response to CSV for offline testing |
| `verbose` | Show detailed progress |
| `debug` | Show debug information |

---

## Tiered Discovery

Discovery commands include tier filters to control which indicators appear:

```stata
* Default: Tier 1 only (verified and downloadable)
unicefdata, search(stunting) limit(10)

* Include Tier 2 (officially defined, may have no data)
unicefdata, search(stunting) limit(10) showtier2

* Include Tier 3 (legacy/undocumented)
unicefdata, search(stunting) limit(10) showtier3

* Include all tiers
unicefdata, search(stunting) limit(20) showall

* Include orphan indicators
unicefdata, search(stunting) showorphans
```

### Tier Classification

| Tier | Count | Description |
|------|------:|-------------|
| **Tier 1** | 480 | Verified and downloadable |
| **Tier 2** | 0 | Limited/deprecated |
| **Tier 3** | 0 | No data available |
| **Tier 4** | 258 | No dataflow mapping (orphans) |

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
stata/
├── src/                        # Source code
│   ├── u/                      # User commands (public)
│   │   ├── unicefdata.ado      # Main command
│   │   └── unicefdata.sthlp    # Help documentation
│   ├── _/                      # Helper programs (internal)
│   │   ├── _unicef_*.ado       # YAML processing, metadata
│   │   └── __unicef_*.ado      # Private utilities
│   └── py/                     # Python metadata generators
├── metadata/                   # YAML metadata cache
│   └── current/                # Latest metadata files
├── qa/                         # Quality assurance (38/38 tests)
├── examples/                   # Usage examples
└── ssc/                        # SSC distribution package
```

---

## Metadata Synchronization

### Refresh Metadata

```stata
* Full metadata refresh (recommended)
unicefdata_refresh_all, verbose

* Check metadata age
unicefdata_sync, verbose

* Force manual sync
unicefdata_sync, force verbose
```

### Staleness Warning

If metadata is >30 days old, you'll see a warning:

```
⚠ WARNING: Metadata is 45 days old (last sync: 2025-11-15)
```

---

## Quality Assurance

The Stata package includes a comprehensive test suite:

- **38 tests** across 7 families
- **100% pass rate** as of v2.0.0
- Test families: ENV, DL, DIS, FILT, META, EDGE, REGR, SYNC

### Run Tests

```stata
cd qa
do run_tests.do
```

See [qa/README.md](qa/README.md) for test documentation.

---

## Troubleshooting

### Command Not Found

```stata
* Reinstall
github install unicef-drp/unicefData, package(stata) replace

* Or check ado path
adopath
which unicefdata
```

### Connection Errors

```stata
* Check internet
!ping sdmx.data.unicef.org

* Increase timeout
set timeout1 30
```

### Indicator Not Found

```stata
* Search for valid indicators
unicefdata, search(mortality)

* Check indicator tier
unicefdata, info(YOUR_INDICATOR)
```

### Metadata Issues

```stata
* Force refresh
unicefdata_refresh_all, verbose
```

---

## Dependencies

- **Stata:** Version 14+
- **Internet:** Required for API access
- **yaml package:** Auto-installed if missing

Check dependencies:

```stata
which yaml
```

---

## Version History

### v2.1.0 (2026-02-07)

- Added `clearcache` subcommand — drops cached frames and reloads metadata
- 3-tier path resolution (PLUS -> findfile/adopath -> cwd) replaces hardcoded paths
- 404 errors now include tried dataflows in messages
- Cross-language fixture tests (12/12 passing)

### v2.0.4 (2026-02-01)

- Fixed false warning for valid disaggregation filters
- Updated examples documentation

### v2.0.0 (2026-01-31)

- Fixed SYNC-02 enrichment bug
- All 38/38 QA tests passing
- Cross-platform alignment

### v1.10.0 (2026-01-19)

- Regression snapshot testing
- Country name generation
- Enhanced UTF-8 support

See `help unicefdata_whatsnew` for complete version history.

---

## License

MIT License - See [LICENSE](../LICENSE)

## Author

**Joao Pedro Azevedo**
Chief Statistician, UNICEF Data and Analytics Section
Email: jpazevedo@unicef.org
Website: [jpazvd.github.io](https://jpazvd.github.io/)

## Support

- **GitHub Issues:** [github.com/unicef-drp/unicefData/issues](https://github.com/unicef-drp/unicefData/issues)
- **Help:** `help unicefdata`
- **Test Suite:** [qa/README.md](qa/README.md)

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

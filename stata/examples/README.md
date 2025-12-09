# UNICEF Data Examples (Stata)

This folder contains example scripts demonstrating how to use the `unicefdata` command.
Each example has identical counterparts in `R/examples/` and `python/examples/`.

## Example Files

| File | Description |
|------|-------------|
| `00_quick_start.do` | Basic usage - fetching data for single/multiple indicators |
| `01_indicator_discovery.do` | Exploring available dataflows and indicators |
| `02_sdg_indicators.do` | SDG-related indicators across domains |
| `03_data_formats.do` | Output format options (long, wide, latest, MRV) |
| `04_metadata_options.do` | Working with metadata and variable labels |
| `05_advanced_features.do` | Disaggregation, time series, combining filters |
| `06_test_fallback.do` | Testing the dataflow fallback mechanism |

## Running Examples

```stata
cd "stata/examples"
do 00_quick_start.do
```

Or run individual commands:

```stata
* Ensure unicefdata is installed
which unicefdata

* Run example
do "path/to/stata/examples/00_quick_start.do"
```

## Quick Reference

```stata
* Basic fetch
unicefdata, indicator(CME_MRY0T4) countries(ALB USA) clear

* Multiple indicators
unicefdata, indicator(CME_MRY0T4 CME_MRM0) countries(ALB) clear

* Year range
unicefdata, indicator(CME_MRY0T4) countries(ALB) start_year(2015) end_year(2023) clear

* Latest values only
unicefdata, indicator(CME_MRY0T4) countries(ALB) latest clear

* Wide format (indicators as columns)
unicefdata, indicator(CME_MRY0T4 CME_MRM0) countries(ALB) wide clear

* Simplified output
unicefdata, indicator(CME_MRY0T4) countries(ALB) simplify clear

* Disaggregation by sex
unicefdata, indicator(CME_MRY0T4) countries(ALB) sex(M F) clear

* Most recent N values
unicefdata, indicator(CME_MRY0T4) countries(ALB) mrv(3) clear

* Verbose output
unicefdata, indicator(CME_MRY0T4) countries(ALB) verbose clear
```

## Output

CSV files are saved to `validation/data/stata/` for cross-language comparison.

## Cross-Language Alignment

These examples are designed to produce equivalent results across all three languages:
- **R**: `R/examples/*.R`
- **Python**: `python/examples/*.py`  
- **Stata**: `stata/examples/*.do`

Use `validation/validate_outputs.py` to compare outputs across languages.

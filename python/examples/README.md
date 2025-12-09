# UNICEF Data Examples (Python)

This folder contains example scripts demonstrating how to use the `unicef_api` package.
Each example has identical counterparts in `R/examples/` and `stata/examples/`.

## Example Files

| File | Description |
|------|-------------|
| `00_quick_start.py` | Basic usage - fetching data for single/multiple indicators |
| `01_indicator_discovery.py` | Searching and exploring available indicators |
| `02_sdg_indicators.py` | SDG-related indicators across domains |
| `03_data_formats.py` | Output format options (long, wide, latest, MRV) |
| `04_metadata_options.py` | Adding metadata (region, income group, indicator name) |
| `05_advanced_features.py` | Disaggregation, time series, combining filters |
| `06_test_fallback.py` | Testing the dataflow fallback mechanism |

## Running Examples

```bash
cd python/examples
python 00_quick_start.py
```

## Output

CSV files are saved to `validation/data/python/` for cross-language comparison.

## Cross-Language Validation

All examples produce equivalent output across R, Python, and Stata:
- Python: `validation/data/python/*.csv`
- R: `validation/data/r/*.csv`
- Stata: `validation/data/stata/*.csv`

Use `python validation/validate_outputs.py --all` to compare outputs.

## Quick Reference

```python
from unicef_api import get_unicef

# Basic fetch
df = get_unicef("CME_MRY0T4", countries=["ALB", "USA"])

# Multiple indicators
df = get_unicef(["CME_MRY0T4", "CME_MRM0"], countries=["ALB"])

# Latest values only
df = get_unicef("CME_MRY0T4", countries=["ALB"], latest=True)

# Wide format
df = get_unicef("CME_MRY0T4", countries=["ALB"], output_format="wide")

# With metadata
df = get_unicef("CME_MRY0T4", countries=["ALB"], add_metadata=["region", "income_group"])
```

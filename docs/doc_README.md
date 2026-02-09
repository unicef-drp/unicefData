# unicefData - Access UNICEF Data via SDMX API

**Status**: Production Ready | **Languages**: Python, R, Stata  
**Purpose**: Simplified access to UNICEF's Statistical Data and Metadata eXchange (SDMX) API

---

## Quick Start

### Python
```python
from unicef_api import get_sdmx

# Fetch child mortality data
df = get_sdmx(indicator="CME_MRY0T4", cache=True)
```

### R
```r
library(unicefData)

# Fetch child mortality data
df <- get_sdmx(indicator = "CME_MRY0T4", cache = TRUE)
```

### Stata
```stata
* Fetch child mortality data
get_sdmx, indicator(CME_MRY0T4) cache noisily
```

---

## Installation

### Python
```bash
pip install unicef-api
```

### R
```r
# Install from GitHub
devtools::install_github("unicef-drp/unicefData/R")
```

### Stata
```stata
* Install from SSC
ssc install unicefdata

* Or install development version
net install unicefdata, from("https://github.com/unicef-drp/unicefData/stata") replace
```

---

## Key Features

✅ **Fast**: Schema caching provides 6-17x performance improvement for batch operations  
✅ **Simple**: Single command interface across all three languages  
✅ **Reliable**: Production-tested with 69 UNICEF dataflows  
✅ **Flexible**: Supports all SDMX agencies (UNICEF, World Bank, WHO, etc.)

---

## Documentation

| Topic | Document | Description |
|-------|----------|-------------|
| **Command Reference** | [get_sdmx_stata.md](get_sdmx_stata.md) | Complete Stata command syntax and options |
| **Metadata Guide** | [METADATA_GENERATION_GUIDE.md](METADATA_GENERATION_GUIDE.md) | How metadata files are generated and synchronized |
| **Governance Overview** | [governance_overview.md](governance_overview.md) | Data governance in SDG monitoring (academic reference) |
| **Examples** | [examples/](examples/) | Sample code and usage patterns |

---

## Common Use Cases

### Fetch Single Indicator
```stata
get_sdmx, indicator(CME_MRY0T4) cache noisily
```

### Fetch with Date Range
```stata
get_sdmx, indicator(SP.POP.TOTL) start_period(2015) end_period(2020) cache
```

### Fetch from Different Agency
```stata
get_sdmx, indicator(SP.POP.TOTL) agency(WB) cache
```

### Batch Processing (with caching)
```stata
foreach ind in CME_MRY0T4 CME_MRY5T9 CME_MRY10T14 {
    get_sdmx, indicator(`ind') cache
    save "data_`ind'.dta", replace
}
```

**Performance**: First indicator ~2.2s, subsequent indicators ~0.13s each (17x faster!)

---

## Available Indicators

UNICEF maintains 69 dataflows covering:
- **Child Mortality** (CME): Under-five, infant, neonatal mortality
- **Nutrition** (NUTRITION): Malnutrition, breastfeeding, micronutrients
- **Immunization** (WUENIC): Vaccine coverage by antigen
- **WASH** (JMP): Water, sanitation, hygiene access
- **Child Protection**: Child marriage, FGM, child labor, birth registration
- **Education**: Early childhood development, out-of-school children
- **HIV/AIDS**: Pediatric and adolescent indicators
- **And many more...**

Use `unicefdata_indicators` command in Stata to browse available indicators.

---

## API Structure

The package uses UNICEF's SDMX REST API:
- **Endpoint**: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest
- **Format**: CSV (default), SDMX-JSON, SDMX-XML
- **Protocol**: SDMX 2.1 compliant

---

## Performance

**Schema Caching Optimization**:
```
Scenario: Fetching 10 indicators from same dataflow

Without caching: 2.2s × 10 = 22 seconds
With caching:    2.2s + 0.13s × 9 = 3.4 seconds
Result:          6.5x faster!
```

For batch processing of 100 indicators:
- **Before**: 3-4 minutes
- **After**: 25-30 seconds
- **Improvement**: 87% faster

---

## Support

### Issues and Questions
- **GitHub Issues**: https://github.com/unicef-drp/unicefData/issues
- **Email**: [Your contact email]

### Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## Citation

If you use unicefData in your research, please cite:

```
Azevedo, João Pedro (2026). unicefData: Access UNICEF Data via SDMX API.
R package/Stata package/Python package version X.X.X.
https://github.com/unicef-drp/unicefData
```

---

## License

MIT License - See LICENSE file for details

---

## About UNICEF Data

UNICEF is the lead or co-lead agency for 22 SDG indicators related to children's health, nutrition, education, protection, and WASH. This package provides programmatic access to UNICEF's official statistics through the SDMX API.

**Data Quality**: All data disseminated through this API undergoes:
- Rigorous inter-agency consultation processes
- Technical Advisory Group review (for mortality, nutrition, etc.)
- Country validation windows
- Peer-reviewed methodology

For more details on data governance, see [governance_overview.md](governance_overview.md).

---

*Last updated: January 2026*

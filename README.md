# unicefData# unicefdata# unicefdata# unicefdata



[![R-CMD-check](https://github.com/unicef-drp/unicefData/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefData/actions)

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)[![R-CMD-check](https://github.com/unicef-drp/unicefdata/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefdata/actions)



**Bilingual R and Python library for downloading UNICEF SDG indicators via SDMX API**[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)



The **unicefData** package provides lightweight, consistent interfaces to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) in both **R** and **Python**. Inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank), you can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)[![R-CMD-check](https://github.com/unicef-drp/unicefdata/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefdata/actions)[![R-CMD-check](https://github.com/your-org/unicefdata/actions/workflows/check.yaml/badge.svg)](https://github.com/your-org/unicefdata/actions)  



---



## 📂 Repository Structure**Multi-language library for downloading UNICEF child welfare indicators via SDMX API**[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/unicefdata)](https://cran.r-project.org/package=unicefdata)  



```

unicefData/

├── R/                        # R package source codeThe **unicefdata** package provides lightweight, consistent interfaces to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) in both **R** and **Python**. Inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank), you can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)[![Codecov test coverage](https://codecov.io/gh/your-org/unicefdata/branch/main/graph/badge.svg)](https://codecov.io/gh/your-org/unicefdata)  

│   ├── codelist.R            # Codelist browsing functions

│   ├── data_utilities.R      # Safe I/O utilities

│   ├── flows.R               # Dataflow listing

│   ├── get_sdmx.R            # Main SDMX fetching function---

│   ├── get_unicef.R          # Alternative API interface

│   ├── utils.R               # Helper functions

│   └── examples/             # R usage examples

│       ├── 01_batch_fetch_sdg.R## 📂 Repository Structure**Multi-language library for downloading UNICEF child welfare indicators via SDMX API**The **unicefdata** package provides a lightweight, consistent R interface to the UNICEF SDMX “Data Warehouse” API, inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank). You can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.

│       ├── 02_sdmx_client_demo.R

│       └── test_api.R

├── python/                   # Python package

│   ├── unicef_api/           # Python module```

│   ├── examples/             # Python usage examples

│   └── tests/                # Unit testsunicefdata/

├── DESCRIPTION               # R package metadata

├── NAMESPACE                 # R exports├── R/                        # R package source codeThe **unicefdata** package provides lightweight, consistent interfaces to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) in both **R** and **Python**. Inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank), you can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.---

├── LICENSE                   # MIT License

└── README.md                 # This file│   ├── codelist.R            # Codelist browsing functions

```

│   ├── data_utilities.R      # Safe I/O utilities

---

│   ├── flows.R               # Dataflow listing

## ⚡ Features

│   ├── get_sdmx.R            # Main SDMX fetching function---## ⚡️ Features

| Feature | R | Python |

|---------|---|--------|│   ├── utils.R               # Helper functions

| Download SDMX series as tidy data | ✅ `get_sdmx()` | ✅ `UNICEFSDMXClient()` |

| Browse available dataflows | ✅ `list_sdmx_flows()` | ✅ `list_dataflows()` |│   └── examples/             # R usage examples

| Browse dimension codelists | ✅ `list_sdmx_codelist()` | ✅ via config.py |

| Filter by country, year, sex | ✅ | ✅ |│       ├── 01_batch_fetch_sdg.R

| Automatic retries & error handling | ✅ | ✅ |

| Disk-based caching (memoise) | ✅ | ⬚ |│       └── 02_sdmx_client_demo.R## 📂 Repository Structure- **`get_unicef()`** — download one or more SDMX series as a tidy `data.frame`  

| Pagination for large datasets | ✅ | ⬚ |

| 40+ pre-configured SDG indicators | ✅ | ✅ |├── python/                   # Python package

| Batch download multiple indicators | ✅ | ✅ |

| Country name lookup | ✅ | ✅ |│   ├── unicef_api/           # Python module- **`list_series()`** — browse available series codes and descriptions  

| Data cleaning utilities | ✅ | ✅ |

│   ├── examples/             # Python usage examples

---

│   └── tests/                # Unit tests```- **Flexible parameters** for date range, geography, frequency, and output format  

## 🚀 Installation

├── DESCRIPTION               # R package metadata

### R Package

├── NAMESPACE                 # R exportsunicefdata/- **Automatic caching** and retries  

```r

# Install from GitHub└── README.md

devtools::install_github("unicef-drp/unicefData")

```├── R/                    # R package source code- **Built‐in error handling** for missing series, malformed URLs, empty results  

# Load the package

library(unicefData)

```

---├── python/               # Python package source code- **`sanity_check()`** integration to track changes in raw CSVs  

### Python Package



```bash

# Install from source## ⚡ Features│   ├── unicef_api/       # Python module

cd python/

pip install -e .



# Or install dependencies directly| Feature | R | Python |│   ├── examples/         # Usage examples---

pip install -r requirements.txt

```|---------|---|--------|



---| Download SDMX series as tidy data | ✅ | ✅ |│   └── tests/            # Unit tests



## 📖 Quick Start| Browse available dataflows | ✅ | ✅ |



### R Usage| Browse dimension codelists | ✅ | ✅ |├── testthat/             # R unit tests## 🚀 Installation



```r| Filter by country, year, sex | ✅ | ✅ |

library(unicefData)

| Automatic retries & error handling | ✅ | ✅ |├── DESCRIPTION           # R package metadata

# List available dataflows

flows <- list_sdmx_flows()| Disk-based caching | ✅ | ⬚ |

print(flows)

| Pagination for large datasets | ✅ | ⬚ |└── README.md             # This fileFrom CRAN:

# Fetch under-5 mortality data

mortality <- get_sdmx(| 40+ pre-configured SDG indicators | ⬚ | ✅ |

  flow = "CME",

  key = "CME_MRY0T4",| Batch download multiple indicators | ✅ | ✅ |```

  start_period = 2015,

  end_period = 2023,| Data cleaning utilities | ✅ | ✅ |

  tidy = TRUE,

  country_names = TRUE```r

)

---

print(head(mortality))

```---install.packages("unicefdata")



### Python Usage## 🚀 Installation



```python

from unicef_api import UNICEFSDMXClient

### R Package

# Initialize client

client = UNICEFSDMXClient()## ⚡ Features



# Fetch under-5 mortality for specific countries```r

df = client.fetch_indicator(

    'CME_MRY0T4',# From GitHub:# getUnicef

    countries=['ALB', 'USA', 'BRA'],

    start_year=2015,# install.packages("devtools")

    end_year=2023

)devtools::install_github("unicef-drp/unicefdata")| Feature | R | Python |



print(df.head())```

```

|---------|---|--------|**Client for the UNICEF SDMX Data Warehouse**

---

### Python Package

## 📊 Common Indicators

| Download SDMX series as tidy data | ✅ | ✅ |

### Child Mortality (SDG 3.2)

```bash

- `CME_MRM0` - Neonatal mortality rate

- `CME_MRY0T4` - Under-5 mortality ratecd python| Browse available series/dataflows | ✅ | ✅ |- **list_unicef_flows()**  



### Nutrition (SDG 2.2)pip install -e .



- `NT_ANT_HAZ_NE2_MOD` - Stunting prevalence| Filter by country, year, sex | ✅ | ✅ |  Returns all available “flows” (tables) you can download.

- `NT_ANT_WHZ_NE2` - Wasting prevalence

- `NT_ANT_WHZ_PO2_MOD` - Overweight prevalence# Or install dependencies directly:



### Education (SDG 4.1)pip install -r requirements.txt| Automatic retries & error handling | ✅ | ✅ |



- `ED_CR_L1_UIS_MOD` - Primary completion rate```

- `ED_CR_L2_UIS_MOD` - Lower secondary completion rate

| 40+ pre-configured SDG indicators | ✅ | ✅ |- **list_unicef_codelist(flow, dimension)**  

### Immunization (SDG 3.b)

---

- `IM_DTP3` - DTP3 immunization coverage

- `IM_MCV1` - Measles immunization coverage| Batch download multiple indicators | ✅ | ✅ |  Returns the codelist (allowed codes + human‐readable descriptions) for a given flow + dimension.



### WASH (SDG 6.1, 6.2)## 🎯 Quick Start



- `WS_PPL_W-SM` - Safely managed drinking water| Data cleaning & transformation utilities | ✅ | ✅ |

- `WS_PPL_S-SM` - Safely managed sanitation

### R - Basic Usage

### Child Protection (SDG 5.3, 16.2, 16.9)

- **get_unicef(flow, key = NULL, …)**  

- `PT_CHLD_Y0T4_REG` - Birth registration

- `PT_F_20-24_MRD_U18_TND` - Child marriage```r



---# Load the package---  Download one or more flows, with optional filters, automatic paging, retry, and tidy output.



## 📚 Documentationsource("R/utils.R")



### R Functionssource("R/flows.R")



| Function | Description |source("R/codelist.R")

|----------|-------------|

| `get_sdmx()` | Download SDMX data series with optional filtering |source("R/get_sdmx.R")## 🚀 Installation## Installation

| `get_unicef()` | Alternative interface with pagination support |

| `list_sdmx_flows()` | List all available UNICEF dataflows |

| `list_sdmx_codelist()` | Browse dimension codelists |

# 1. List all available UNICEF dataflows

### Python Classes

flows <- list_sdmx_flows(agency = "UNICEF")

| Class/Function | Description |

|----------------|-------------|print(flows)### R Package```r

| `UNICEFSDMXClient` | Main client for fetching indicator data |

| `fetch_indicator()` | Fetch single indicator with filters |

| `fetch_multiple_indicators()` | Batch download multiple indicators |

# 2. Fetch under-5 mortality data# From CRAN (once published)

See `R/examples/` and `python/examples/` for complete usage examples.

mortality <- get_sdmx(

---

  agency       = "UNICEF",```rinstall.packages("getUnicef")

## 🔗 Data Sources

  flow         = "CME",

All data is sourced from the UNICEF SDMX Data Warehouse:

  key          = "CME_MRY0T4",# From GitHub:

- **SDMX API**: [https://sdmx.data.unicef.org/](https://sdmx.data.unicef.org/)

- **Data Portal**: [https://data.unicef.org/](https://data.unicef.org/)  start_period = 2015,

- **API Documentation**: [https://data.unicef.org/sdmx-api-documentation/](https://data.unicef.org/sdmx-api-documentation/)

  end_period   = 2023,# install.packages("devtools")# Or from GitHub:

---

  tidy         = TRUE

## 📄 License

)devtools::install_github("unicef-drp/unicefdata")# install.packages("devtools")

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

print(head(mortality))

---

``````devtools::install_github("yourusername/getUnicef")

## 👤 Authors



**Joao Pedro Azevedo**  

Senior Advisor, Data and Analytics  ### R - Batch Fetch Multiple Indicators

UNICEF  

### Python Package

**Garen Avanesian**  

Data Specialist  ```r

UNICEF

# See: R/examples/01_batch_fetch_sdg.R```bash

---

cd python

## 🙏 Acknowledgments

library(purrr)pip install -e .

This library was developed as part of UNICEF's SDG reporting efforts, with code adapted from:

source("R/get_sdmx.R")

- `PROD-SDG-REP-2025` production pipeline

- `unicef-sdg-llm-benchmark` repositorysource("R/data_utilities.R")# Or install dependencies directly:



---pip install -r requirements.txt



## 📝 Changelog# Define flows to fetch```



See [NEWS.md](NEWS.md) for version history and changes.flows_to_fetch <- list(


  mort  = list(flow = "CME", key = c("CME_MRM0", "CME_MRY0T4")),---

  nutr  = list(flow = "NUTRITION", key = c("NT_ANT_HAZ_NE2_MOD", "NT_ANT_WHZ_NE2")),

  edu   = list(flow = "EDUCATION_UIS_SDG", key = c("ED_CR_L1_UIS_MOD", "ED_CR_L2_UIS_MOD")),## 🎯 Quick Start

  immun = list(flow = "IMMUNISATION", key = c("IM_DTP3", "IM_MCV1")),

  wash  = list(flow = "WASH_HOUSEHOLDS", key = c("WS_PPL_W-SM", "WS_PPL_S-SM"))### R

)

```r

# Fetch and save eachlibrary(unicefdata)

results <- imap(flows_to_fetch, function(cfg, name) {

  df <- get_sdmx(# List available dataflows

    agency        = "UNICEF",flows <- list_unicef_flows()

    flow          = cfg$flow,

    key           = cfg$key,# Download under-5 mortality rate

    tidy          = TRUE,df <- get_unicef(

    country_names = TRUE  flow = "CME",

  )  key = "CME_MRY0T4",

  safe_write_csv(df, paste0("data/raw/api_", name, ".csv"), label = name)  countries = c("ALB", "USA", "BRA"),

  df  start_year = 2015,

})  end_year = 2023

```)

```

### R - Explore Codelists

### Python

```r

# See: R/examples/02_sdmx_client_demo.R```python

from unicef_api import UNICEFSDMXClient

# List available indicators in NUTRITION dataflow

nutrition_codes <- list_sdmx_codelist(# Initialize client

  agency    = "UNICEF",client = UNICEFSDMXClient()

  codelist_id = "CL_UNICEF_INDICATOR"

)# Download under-5 mortality rate

print(head(nutrition_codes))df = client.fetch_indicator(

    'CME_MRY0T4',

# Fetch structure metadata (XML)    countries=['ALB', 'USA', 'BRA'],

dsd <- get_sdmx(    start_year=2015,

  agency = "UNICEF",    end_year=2023

  flow   = "NUTRITION",)

  detail = "structure"

)print(df.head())

``````



### Python - Basic Usage---



```python## 📊 Common Indicators

from unicef_api import UNICEFSDMXClient

### Child Mortality (SDG 3.2)

# Initialize client| Indicator | Description |

client = UNICEFSDMXClient()|-----------|-------------|

| `CME_MRM0` | Neonatal mortality rate |

# Fetch under-5 mortality for specific countries| `CME_MRY0T4` | Under-5 mortality rate |

df = client.fetch_indicator(| `CME_MRY0` | Infant mortality rate |

    'CME_MRY0T4',

    countries=['ALB', 'USA', 'BRA'],### Nutrition (SDG 2.2)

    start_year=2015,| Indicator | Description |

    end_year=2023|-----------|-------------|

)| `NT_ANT_HAZ_NE2_MOD` | Stunting prevalence (height-for-age) |

| `NT_ANT_WHZ_NE2` | Wasting prevalence (weight-for-height) |

print(df.head())| `NT_ANT_WHZ_PO2_MOD` | Overweight prevalence |

```| `NT_BF_EXBF` | Exclusive breastfeeding rate |



### Python - Batch Fetch Multiple Indicators### Education (SDG 4.1)

| Indicator | Description |

```python|-----------|-------------|

# Fetch multiple indicators at once| `ED_CR_L1_UIS_MOD` | Primary completion rate |

indicators = ['CME_MRY0T4', 'NT_ANT_HAZ_NE2_MOD', 'IM_DTP3']| `ED_CR_L2_UIS_MOD` | Lower secondary completion rate |

| `ED_ANAR_L1` | Out-of-school rate (primary) |

df = client.fetch_multiple_indicators(

    indicators,### Immunization

    countries=['ALB', 'USA'],| Indicator | Description |

    start_year=2015,|-----------|-------------|

    combine=True  # Combine into single DataFrame| `IM_DTP3` | DTP3 immunization coverage |

)| `IM_MCV1` | Measles immunization coverage |

| `IM_BCG` | BCG immunization coverage |

print(f"Total observations: {len(df)}")

```### Water & Sanitation (SDG 6)

| Indicator | Description |

---|-----------|-------------|

| `WS_PPL_W-SM` | Population with safe drinking water |

## 📊 Common Indicators| `WS_PPL_S-SM` | Population with basic sanitation |



### Child Mortality (SDG 3.2)---



| Indicator | Description |## 📖 Documentation

|-----------|-------------|

| `CME_MRM0` | Neonatal mortality rate |- **Python**: See [`python/README.md`](python/README.md) for detailed Python documentation

| `CME_MRY0T4` | Under-5 mortality rate |- **Python Getting Started**: See [`python/GETTING_STARTED.md`](python/GETTING_STARTED.md)

| `CME_MRY0` | Infant mortality rate |- **R**: Function documentation via `?get_unicef` in R



### Nutrition (SDG 2.2)---



| Indicator | Description |## 🌐 UNICEF SDMX API

|-----------|-------------|

| `NT_ANT_HAZ_NE2_MOD` | Stunting prevalence (height-for-age) |This package interfaces with UNICEF's SDMX Data Warehouse:

| `NT_ANT_WHZ_NE2` | Wasting prevalence (weight-for-height) |- **API Endpoint**: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest

| `NT_ANT_WHZ_PO2_MOD` | Overweight prevalence |- **Query Builder**: https://sdmx.data.unicef.org/webservice/data.html

| `NT_BF_EXBF` | Exclusive breastfeeding rate |- **Data Explorer**: https://data.unicef.org/



### Education (SDG 4.1)---



| Indicator | Description |## 🤝 Contributing

|-----------|-------------|

| `ED_CR_L1_UIS_MOD` | Primary completion rate |Contributions are welcome! Please feel free to submit a Pull Request.

| `ED_CR_L2_UIS_MOD` | Lower secondary completion rate |

| `ED_ANAR_L02` | Adjusted net attendance rate |1. Fork the repository

2. Create your feature branch (`git checkout -b feature/AmazingFeature`)

### Immunization (SDG 3.b)3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)

4. Push to the branch (`git push origin feature/AmazingFeature`)

| Indicator | Description |5. Open a Pull Request

|-----------|-------------|

| `IM_DTP3` | DTP3 immunization coverage |---

| `IM_MCV1` | Measles immunization coverage |

| `IM_BCG` | BCG immunization coverage |## 📝 License



### Water & Sanitation (SDG 6)This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.



| Indicator | Description |---

|-----------|-------------|

| `WS_PPL_W-SM` | Population with safely managed drinking water |## 👥 Authors

| `WS_PPL_S-SM` | Population with safely managed sanitation |

- **Joao Pedro Azevedo** - *Lead Developer* - [azevedo.joaopedro@gmail.com](mailto:azevedo.joaopedro@gmail.com)

### Child Protection- **Garen Avanesian** - *Contributor*



| Indicator | Description |---

|-----------|-------------|

| `PT_CHLD_Y0T4_REG` | Birth registration (under 5) |## 🔗 Related Projects

| `PT_F_20-24_MRD_U18_TND` | Child marriage prevalence |

| `PT_F_15-49_FGM` | FGM prevalence |- [wbdata](https://github.com/worldbank/wbdata) - World Bank Data API client

- [ilostat](https://github.com/ilostat/Rilostat) - ILO Statistics API client

---- [rsdmx](https://github.com/opensdmx/rsdmx) - Generic SDMX client for R

- [pandaSDMX](https://pypi.org/project/pandaSDMX/) - Generic SDMX client for Python

## 📁 R Examples

The `R/examples/` folder contains complete working examples:

| File | Description |
|------|-------------|
| `01_batch_fetch_sdg.R` | Batch-fetch 13 SDG indicator groups from UNICEF API |
| `02_sdmx_client_demo.R` | Demonstrate SDMX client functions (flows, codelists, JSON) |

Run examples:

```r
# From repository root
source("R/examples/01_batch_fetch_sdg.R")
source("R/examples/02_sdmx_client_demo.R")
```

---

## 📁 Python Examples

The `python/examples/` folder contains complete working examples:

| File | Description |
|------|-------------|
| `01_basic_usage.py` | Basic single-indicator fetching |
| `02_multiple_indicators.py` | Batch download multiple indicators |
| `03_sdg_indicators.py` | SDG-focused data retrieval |
| `04_data_analysis.py` | Data transformation and analysis |

Run examples:

```bash
cd python/examples
python 01_basic_usage.py
```

---

## 📖 API Reference

### R Functions

| Function | Description |
|----------|-------------|
| `list_sdmx_flows(agency)` | List all available dataflows |
| `list_sdmx_codelist(agency, codelist_id)` | Get codes for a dimension |
| `get_sdmx(agency, flow, key, ...)` | Fetch data with filtering |
| `safe_read_csv(path)` | Read CSV with error handling |
| `safe_write_csv(df, path)` | Write CSV with validation |

### Python Classes

| Class/Function | Description |
|----------------|-------------|
| `UNICEFSDMXClient` | Main API client class |
| `client.fetch_indicator()` | Fetch single indicator |
| `client.fetch_multiple_indicators()` | Fetch multiple indicators |
| `get_dataflow_for_indicator()` | Auto-detect correct dataflow |
| `list_indicators_by_sdg()` | Get indicators by SDG target |

---

## 🌐 UNICEF SDMX API

This package interfaces with UNICEF's SDMX Data Warehouse:

- **API Endpoint**: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest
- **Query Builder**: https://sdmx.data.unicef.org/webservice/data.html
- **Data Explorer**: https://data.unicef.org/

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

- **Joao Pedro Azevedo** - *Lead Developer* - [azevedo.joaopedro@gmail.com](mailto:azevedo.joaopedro@gmail.com)
- **Garen Avanesian** - *Contributor*

---

## 🔗 Related Projects

- [wbdata](https://github.com/worldbank/wbdata) - World Bank Data API client
- [ilostat](https://github.com/ilostat/Rilostat) - ILO Statistics API client
- [rsdmx](https://github.com/opensdmx/rsdmx) - Generic SDMX client for R
- [pandaSDMX](https://pypi.org/project/pandaSDMX/) - Generic SDMX client for Python

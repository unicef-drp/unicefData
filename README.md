# unicefdata# unicefdata# unicefdata



[![R-CMD-check](https://github.com/unicef-drp/unicefdata/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefdata/actions)

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)[![R-CMD-check](https://github.com/unicef-drp/unicefdata/actions/workflows/check.yaml/badge.svg)](https://github.com/unicef-drp/unicefdata/actions)[![R-CMD-check](https://github.com/your-org/unicefdata/actions/workflows/check.yaml/badge.svg)](https://github.com/your-org/unicefdata/actions)  



**Multi-language library for downloading UNICEF child welfare indicators via SDMX API**[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/unicefdata)](https://cran.r-project.org/package=unicefdata)  



The **unicefdata** package provides lightweight, consistent interfaces to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) in both **R** and **Python**. Inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank), you can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)[![Codecov test coverage](https://codecov.io/gh/your-org/unicefdata/branch/main/graph/badge.svg)](https://codecov.io/gh/your-org/unicefdata)  



---



## 📂 Repository Structure**Multi-language library for downloading UNICEF child welfare indicators via SDMX API**The **unicefdata** package provides a lightweight, consistent R interface to the UNICEF SDMX “Data Warehouse” API, inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank). You can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.



```

unicefdata/

├── R/                        # R package source codeThe **unicefdata** package provides lightweight, consistent interfaces to the [UNICEF SDMX Data Warehouse](https://sdmx.data.unicef.org/) in both **R** and **Python**. Inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank), you can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.---

│   ├── codelist.R            # Codelist browsing functions

│   ├── data_utilities.R      # Safe I/O utilities

│   ├── flows.R               # Dataflow listing

│   ├── get_sdmx.R            # Main SDMX fetching function---## ⚡️ Features

│   ├── utils.R               # Helper functions

│   └── examples/             # R usage examples

│       ├── 01_batch_fetch_sdg.R

│       └── 02_sdmx_client_demo.R## 📂 Repository Structure- **`get_unicef()`** — download one or more SDMX series as a tidy `data.frame`  

├── python/                   # Python package

│   ├── unicef_api/           # Python module- **`list_series()`** — browse available series codes and descriptions  

│   ├── examples/             # Python usage examples

│   └── tests/                # Unit tests```- **Flexible parameters** for date range, geography, frequency, and output format  

├── DESCRIPTION               # R package metadata

├── NAMESPACE                 # R exportsunicefdata/- **Automatic caching** and retries  

└── README.md

```├── R/                    # R package source code- **Built‐in error handling** for missing series, malformed URLs, empty results  



---├── python/               # Python package source code- **`sanity_check()`** integration to track changes in raw CSVs  



## ⚡ Features│   ├── unicef_api/       # Python module



| Feature | R | Python |│   ├── examples/         # Usage examples---

|---------|---|--------|

| Download SDMX series as tidy data | ✅ | ✅ |│   └── tests/            # Unit tests

| Browse available dataflows | ✅ | ✅ |

| Browse dimension codelists | ✅ | ✅ |├── testthat/             # R unit tests## 🚀 Installation

| Filter by country, year, sex | ✅ | ✅ |

| Automatic retries & error handling | ✅ | ✅ |├── DESCRIPTION           # R package metadata

| Disk-based caching | ✅ | ⬚ |

| Pagination for large datasets | ✅ | ⬚ |└── README.md             # This fileFrom CRAN:

| 40+ pre-configured SDG indicators | ⬚ | ✅ |

| Batch download multiple indicators | ✅ | ✅ |```

| Data cleaning utilities | ✅ | ✅ |

```r

---

---install.packages("unicefdata")

## 🚀 Installation



### R Package

## ⚡ Features

```r

# From GitHub:# getUnicef

# install.packages("devtools")

devtools::install_github("unicef-drp/unicefdata")| Feature | R | Python |

```

|---------|---|--------|**Client for the UNICEF SDMX Data Warehouse**

### Python Package

| Download SDMX series as tidy data | ✅ | ✅ |

```bash

cd python| Browse available series/dataflows | ✅ | ✅ |- **list_unicef_flows()**  

pip install -e .

| Filter by country, year, sex | ✅ | ✅ |  Returns all available “flows” (tables) you can download.

# Or install dependencies directly:

pip install -r requirements.txt| Automatic retries & error handling | ✅ | ✅ |

```

| 40+ pre-configured SDG indicators | ✅ | ✅ |- **list_unicef_codelist(flow, dimension)**  

---

| Batch download multiple indicators | ✅ | ✅ |  Returns the codelist (allowed codes + human‐readable descriptions) for a given flow + dimension.

## 🎯 Quick Start

| Data cleaning & transformation utilities | ✅ | ✅ |

### R - Basic Usage

- **get_unicef(flow, key = NULL, …)**  

```r

# Load the package---  Download one or more flows, with optional filters, automatic paging, retry, and tidy output.

source("R/utils.R")

source("R/flows.R")

source("R/codelist.R")

source("R/get_sdmx.R")## 🚀 Installation## Installation



# 1. List all available UNICEF dataflows

flows <- list_sdmx_flows(agency = "UNICEF")

print(flows)### R Package```r



# 2. Fetch under-5 mortality data# From CRAN (once published)

mortality <- get_sdmx(

  agency       = "UNICEF",```rinstall.packages("getUnicef")

  flow         = "CME",

  key          = "CME_MRY0T4",# From GitHub:

  start_period = 2015,

  end_period   = 2023,# install.packages("devtools")# Or from GitHub:

  tidy         = TRUE

)devtools::install_github("unicef-drp/unicefdata")# install.packages("devtools")

print(head(mortality))

``````devtools::install_github("yourusername/getUnicef")



### R - Batch Fetch Multiple Indicators

### Python Package

```r

# See: R/examples/01_batch_fetch_sdg.R```bash

cd python

library(purrr)pip install -e .

source("R/get_sdmx.R")

source("R/data_utilities.R")# Or install dependencies directly:

pip install -r requirements.txt

# Define flows to fetch```

flows_to_fetch <- list(

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

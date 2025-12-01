# unicefdata

[![R-CMD-check](https://github.com/your-org/unicefdata/actions/workflows/check.yaml/badge.svg)](https://github.com/your-org/unicefdata/actions)  
[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/unicefdata)](https://cran.r-project.org/package=unicefdata)  
[![Codecov test coverage](https://codecov.io/gh/your-org/unicefdata/branch/main/graph/badge.svg)](https://codecov.io/gh/your-org/unicefdata)  

The **unicefdata** package provides a lightweight, consistent R interface to the UNICEF SDMX “Data Warehouse” API, inspired by `get_ilostat()` (ILO) and `wb_data()` (World Bank). You can fetch any indicator series simply by specifying its SDMX key, date range, and optional filters.

---

## ⚡️ Features

- **`get_unicef()`** — download one or more SDMX series as a tidy `data.frame`  
- **`list_series()`** — browse available series codes and descriptions  
- **Flexible parameters** for date range, geography, frequency, and output format  
- **Automatic caching** and retries  
- **Built‐in error handling** for missing series, malformed URLs, empty results  
- **`sanity_check()`** integration to track changes in raw CSVs  

---

## 🚀 Installation

From CRAN:

```r
install.packages("unicefdata")


# getUnicef

**Client for the UNICEF SDMX Data Warehouse**

- **list_unicef_flows()**  
  Returns all available “flows” (tables) you can download.

- **list_unicef_codelist(flow, dimension)**  
  Returns the codelist (allowed codes + human‐readable descriptions) for a given flow + dimension.

- **get_unicef(flow, key = NULL, …)**  
  Download one or more flows, with optional filters, automatic paging, retry, and tidy output.

## Installation

```r
# From CRAN (once published)
install.packages("getUnicef")

# Or from GitHub:
# install.packages("devtools")
devtools::install_github("yourusername/getUnicef")

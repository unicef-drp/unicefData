# R/query_sdmx.R
# Purpose: Demonstrate usage of the generalized SDMX client functions

# Load dependencies
library(purrr)
library(dplyr)
library(tidyr)

# Source the core SDMX client scripts (adjust path as needed)
source("R/utils.R")          # %||%, .get_unicef_ua, .fetch_sdmx
source("R/flows.R")          # list_sdmx_flows()
source("R/codelist.R")       # list_sdmx_codelist()
source("R/get_sdmx.R")     # get_sdmx()
source("R/data_utilities.R") # safe_write_csv()

# 1. List all available flows for UNICEF
flows_meta <- list_sdmx_flows(agency = "UNICEF", retry = 3)
print(flows_meta)

# 2. Inspect the version of a particular flow (e.g., CME)
cme_info <- flows_meta %>% filter(id == "CME")
print(cme_info)

# 3. List the codelist for the 'INDICATOR' dimension of the NUTRITION flow
nutrition_codes <- list_sdmx_codelist(
  agency = "UNICEF", 
  flow = "NUTRITION", 
  dimension = "INDICATOR",
  retry = 3
)
print(head(nutrition_codes))

# 4. Fetch data for selected flows using get_sdmx()
#    Here we pull under-5 mortality (CME_MRM0) and malnutrition indicators
results <- list(
  mortality = get_sdmx(
    agency = "UNICEF",
    flow = "CME",
    key = c("CME_MRM0"),
    start_period = 2000,
    end_period   = 2020,
    format = "csv",
    labels = "both",
    tidy = TRUE,
    retry = 3
  ),
  stunting = get_sdmx(
    agency = "UNICEF",
    flow = "NUTRITION",
    key = c("NT_ANT_HAZ_NE2_MOD"),
    start_period = 2000,
    end_period   = 2020,
    format = "csv",
    labels = "both",
    tidy = TRUE,
    retry = 3
  )
)

# 5. Save fetched datasets to CSV
raw_dir <- "data/raw"
if (!dir.exists(raw_dir)) dir.create(raw_dir, recursive = TRUE)

imap(results, ~ safe_write_csv(.x, file.path(raw_dir, paste0("sdmx_", .y, ".csv")), label = .y))

# 6. Example: Fetch structure metadata for a flow
dsd <- get_sdmx(
  agency = "UNICEF",
  flow = "NUTRITION",
  detail = "structure",
  format = "sdmx-xml"
)
# dsd is an xml_document; inspect its top nodes
print(xml2::xml_name(xml2::xml_children(dsd)[[1]]))

# 7. (Optional) Demonstrate JSON format
json_df <- get_sdmx(
  agency = "UNICEF",
  flow = "CME",
  key = "CME_MRM0",
  format = "sdmx-json",
  labels = "id",
  tidy = FALSE
)
print(head(json_df))

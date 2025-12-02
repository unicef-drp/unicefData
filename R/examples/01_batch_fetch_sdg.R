# R/query_unicef.R
# Purpose: Batch-fetch SDG indicator flows from UNICEF SDMX API and save to CSV

# Dependencies
library(purrr)
library(dplyr)
# Ensure your package scripts are loaded (adjust paths as needed)
source("R/utils.R")    # Defines %||%, .get_unicef_ua, .fetch_sdmx
source("R/flows.R")    # Defines list_unicef_flows()
source("R/codelist.R") # Defines list_unicef_codelist()
source("R/get_unicef.R")
source("R/data_utilities.R") # Defines safe_write_csv()

# Directory for raw data outputs (adjust accordingly)
rawData <- "data/raw"
if (!dir.exists(rawData)) dir.create(rawData, recursive = TRUE)

# Define flows and keys to fetch
flows_to_fetch <- list(
  mort = list(flow = "CME", key = c("CME_MRM0", "CME_MRY0T4")),
  nutr = list(flow = "NUTRITION", key = c("NT_ANT_HAZ_NE2_MOD", "NT_ANT_WHZ_NE2", "NT_ANT_WHZ_PO2_MOD")),
  wast = list(flow = "NUTRITION", key = "NT_ANT_WHZ_NE2"),
  edu  = list(flow = "EDUCATION_UIS_SDG", key = c(
    "ED_ANAR_L02", "ED_CR_L1_UIS_MOD", "ED_CR_L2_UIS_MOD", "ED_CR_L3_UIS_MOD",
    "ED_MAT_G23", "ED_MAT_L1", "ED_MAT_L2", "ED_READ_G23", "ED_READ_L1", "ED_READ_L2",
    "ED_ROFST_L1_UIS_MOD", "ED_ROFST_L2_UIS_MOD", "ED_ROFST_L3_UIS_MOD"
  )),
  immun = list(flow = "IMMUNISATION", key = c("IM_DTP3", "IM_MCV1")),
  hiv   = list(flow = "HIV_AIDS", key = c("HVA_EPI_INF_RT.Y0T14", "HVA_EPI_INF_RT.Y15T19")),
  wash  = list(flow = "WASH_HOUSEHOLDS", key = c(
    "WS_PPL_H-B", "WS_PPL_S-ALB", "WS_PPL_S-OD", "WS_PPL_S-SM",
    "WS_PPL_W-ALB", "WS_PPL_W-SM"
  )),
  mnch  = list(flow = "MNCH", key = c("MNCH_ABR", "MNCH_INFDEC", "MNCH_MMR", "MNCH_SAB", "MNCH_UHC")),
  cp    = list(flow = "PT", key = c(
    "PT_CHLD_1-14_PS-PSY-V_CGVR", "PT_CHLD_Y0T4_REG",
    "PT_F_18-29_SX-V_AGE-18", "PT_M_18-29_SX-V_AGE-18"
  )),
  ecd   = list(flow = "ECD", key = "ECD_CHLD_LMPSL"),
  chmrg = list(flow = "PT_CM", key = "PT_F_20-24_MRD_U18_TND"),
  fgm   = list(flow = "PT_FGM", key = "PT_F_15-49_FGM"),
  pov   = list(flow = "CHLD_PVTY", key = "PV_CHLD_DPRV-S-L1-HS")
)

# Fetch and save for each
results <- imap(flows_to_fetch, function(cfg, name) {
  df <- get_unicef(
    flow         = cfg$flow,
    key          = cfg$key,
    tidy         = TRUE,
    country_names= TRUE,
    retry        = 3L,
    cache        = FALSE
  )
  # Post-process birth registration in CP flow
  if (name == "cp") {
    df <- df %>%
      filter(!(INDICATOR == "PT_CHLD_Y0T4_REG" & AGE != "Y0T4"))
  }
  # Write out
  out_path <- file.path(rawData, paste0("api_unf_", name, ".csv"))
  safe_write_csv(df, out_path, label = name)
  df
})

# Optional: view summary of fetched data
imap(results, ~ message(sprintf("%s: %s rows fetched", .y, nrow(.x))))

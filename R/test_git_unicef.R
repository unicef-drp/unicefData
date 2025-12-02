# test_get_unicef.R
# Script to test get_unicef() for key UNICEF SDMX flows and produce debug log

#–––––––––––––––––––––––––––––––––––––––
# Setup logging
#–––––––––––––––––––––––––––––––––––––––
log_file <- file.path(getwd(), "test_get_unicef.log")
# start and ensure sink is closed on exit
sink(log_file, split = TRUE)
on.exit(sink(), add = TRUE)
message("*** Starting get_unicef tests: ", Sys.time(), " ***")
message("Working directory: ", getwd())

#–––––––––––––––––––––––––––––––––––––––
# Load dependencies and functions
#–––––––––––––––––––––––––––––––––––––––
# Path to your get_unicef implementation:
impl_file <- file.path(getwd(), "R", "get_unicef.R")  # adjust if needed
if (!file.exists(impl_file)) {
  stop("Implementation file not found: ", impl_file)
}
message("Sourcing implementation from: ", impl_file)
source(impl_file)

#–––––––––––––––––––––––––––––––––––––––
# Define rawData directory
#–––––––––––––––––––––––––––––––––––––––
rawData <- file.path(getwd(), "01_input_data", "02_api_data_raw")
if (!dir.exists(rawData)) {
  message("Creating rawData directory: ", rawData)
  dir.create(rawData, recursive = TRUE)
}

#–––––––––––––––––––––––––––––––––––––––
# Define test specifications
#–––––––––––––––––––––––––––––––––––––––
specs <- list(
  mort   = list(flow="CME",        key=c("CME_MRM0","CME_MRY0T4"),    fname="api_unf_mort.csv"),
  nutr   = list(flow="NUTRITION",  key=c("NT_ANT_HAZ_NE2_MOD","NT_ANT_WHZ_NE2","NT_ANT_WHZ_PO2_MOD"), fname="api_unf_nutr.csv"),
  wast   = list(flow="NUTRITION",  key="NT_ANT_WHZ_NE2",              fname="api_unf_nutr_wast.csv"),
  edu    = list(flow="EDUCATION_UIS_SDG",
                key=c("ED_ANAR_L02","ED_CR_L1_UIS_MOD","ED_CR_L2_UIS_MOD","ED_CR_L3_UIS_MOD",
                      "ED_MAT_G23","ED_MAT_L1","ED_MAT_L2","ED_READ_G23","ED_READ_L1",
                      "ED_READ_L2","ED_ROFST_L1_UIS_MOD","ED_ROFST_L2_UIS_MOD","ED_ROFST_L3_UIS_MOD"),
                fname="api_unf_edu.csv"),
  immun  = list(flow="IMMUNISATION", key=c("IM_DTP3","IM_MCV1"),             fname="api_unf_immun.csv"),
  hiv    = list(flow="HIV_AIDS",     key=c("HVA_EPI_INF_RT_0-14","HVA_EPI_INF_RT_15-19"), fname="api_unf_hiv.csv"),
  wash   = list(flow="WASH_HOUSEHOLDS",
                key=c("WS_PPL_H-B","WS_PPL_S-ALB","WS_PPL_S-OD","WS_PPL_S-SM","WS_PPL_W-ALB","WS_PPL_W-SM"),
                fname="api_unf_wash.csv"),
  mnch   = list(flow="MNCH",        key=c("MNCH_ABR","MNCH_INFDEC","MNCH_MMR","MNCH_SAB","MNCH_UHC"), fname="api_unf_mnch.csv"),
  cp     = list(flow="PT",
                key=c("PT_CHLD_1-14_PS-PSY-V_CGVR","PT_CHLD_Y0T4_REG","PT_F_18-29_SX-V_AGE-18","PT_M_18-29_SX-V_AGE-18"),
                fname="api_unf_cp.csv")
)

#–––––––––––––––––––––––––––––––––––––––
# Run tests
#–––––––––––––––––––––––––––––––––––––––
for (spec in specs) {
  message("[", Sys.time(), "] Fetching flow=", spec$flow,
          " keys=", paste(spec$key, collapse=','))
  df <- tryCatch(
    get_unicef(
      flow         = spec$flow,
      key          = spec$key,
      start_period = 2000,
      end_period   = as.character(format(Sys.Date(), "%Y")),
      detail       = "data",
      tidy         = FALSE,
      country_names= FALSE,
      retry        = 3,
      cache        = FALSE
    ),
    error = function(e) {
      message("ERROR fetching ", spec$flow, ": ", e$message)
      NULL
    }
  )
  if (!is.null(df)) {
    out_path <- file.path(rawData, spec$fname)
    write.csv(df, out_path, row.names = FALSE, na = "")
    message("Wrote ", spec$fname, " [", nrow(df), " obs]")
  } else {
    message("Skipped writing ", spec$fname, " (NULL)")
  }
}

message("*** Completed get_unicef tests: ", Sys.time(), " ***")

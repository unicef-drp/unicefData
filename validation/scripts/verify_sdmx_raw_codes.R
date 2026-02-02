# verification: demonstrate SDMX labels vs codes-only in R
# Requires the unicefData package functions loaded in this workspace

# Example indicator: CME_MRY0T4 (Child mortality)
# Flow assumption: 'CME' dataflow contains CME_MRY0T4

suppressPackageStartupMessages({
  # Prefer local sources over installed package to ensure latest code
  if (file.exists("C:/GitHub/myados/unicefData-dev/R/unicef_core.R")) {
    source("C:/GitHub/myados/unicefData-dev/R/unicef_core.R")
  }
  if (file.exists("C:/GitHub/myados/unicefData-dev/R/utils.R")) {
    source("C:/GitHub/myados/unicefData-dev/R/utils.R")
  }
  if (file.exists("C:/GitHub/myados/unicefData-dev/R/flows.R")) {
    source("C:/GitHub/myados/unicefData-dev/R/flows.R")
  }
  if (file.exists("C:/GitHub/myados/unicefData-dev/R/get_sdmx.R")) {
    source("C:/GitHub/myados/unicefData-dev/R/get_sdmx.R")
  }
  if (file.exists("C:/GitHub/myados/unicefData-dev/R/unicefData.R")) {
    source("C:/GitHub/myados/unicefData-dev/R/unicefData.R")
  } else {
    library(unicefData)
  }
  library(dplyr)
})

indicator_code <- "CME_MRY0T4"
flow_id <- "CME"

message("Fetching with labels='id' (codes-only)...")
df_id <- get_sdmx(
  agency = "UNICEF",
  flow = flow_id,
  key = indicator_code,
  labels = "id",
  tidy = TRUE,
  country_names = TRUE
)

message("Fetching with labels='both' (codes + human-readable labels)...")
df_both <- get_sdmx(
  agency = "UNICEF",
  flow = flow_id,
  key = indicator_code,
  labels = "both",
  tidy = TRUE,
  country_names = TRUE
)

message(sprintf("Rows: id=%d, both=%d", nrow(df_id), nrow(df_both)))

extra_cols <- setdiff(names(df_both), names(df_id))
message(sprintf("Extra label columns present only when labels='both': %s",
                paste(extra_cols, collapse = ", ")))

# Optional: show how include_label_columns=FALSE in unicefData() drops label columns
message("\nUsing unicefData() with include_label_columns=FALSE (code-only schema)...")
df_tidy_codes <- unicefData(
  indicator = indicator_code,
  dataflow = flow_id,
  tidy = TRUE,
  include_label_columns = FALSE,
  country_names = TRUE
)

message(sprintf("unicefData tidy (codes-only): cols=%d", ncol(df_tidy_codes)))
print(head(df_tidy_codes))

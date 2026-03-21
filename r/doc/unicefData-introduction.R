## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----install------------------------------------------------------------------
# # install.packages("devtools")
# devtools::install_github("unicef-drp/unicefData")

## ----library------------------------------------------------------------------
# library(unicefData)

## ----discovery----------------------------------------------------------------
# # Browse indicator categories (thematic dataflows)
# list_categories()
# 
# # Search for indicators by keyword
# search_indicators("mortality")
# 
# # List all indicators in the Child Mortality Estimates dataflow
# list_indicators("CME")
# 
# # Get detailed information about a specific indicator
# get_indicator_info("CME_MRY0T4")

## ----basic-retrieval----------------------------------------------------------
# # Example 5 (paper): Basic data retrieval
# df <- unicefData(
#   indicator = "CME_MRY0T4",
#   countries = c("BRA", "IND", "CHN"),
#   year = "2015:2023"
# )
# head(df)

## ----geographic---------------------------------------------------------------
# # Example 6 (paper): Geographic filtering
# df <- unicefData(
#   indicator = "CME_MRY0T4",
#   countries = c("KEN", "TZA", "UGA", "ETH", "RWA"),
#   year = 2020
# )

## ----latest-mrv---------------------------------------------------------------
# # Example 7 (paper): Get the latest available value per country
# df_latest <- unicefData(
#   indicator = "CME_MRY0T4",
#   countries = c("BGD", "IND", "PAK"),
#   latest = TRUE
# )
# 
# # Get the 3 most recent values per country
# df_mrv <- unicefData(
#   indicator = "CME_MRY0T4",
#   countries = c("BGD", "IND", "PAK"),
#   mrv = 3
# )

## ----year-formats-------------------------------------------------------------
# # Single year
# df <- unicefData(indicator = "CME_MRY0T4", year = 2020)
# 
# # Year range
# df <- unicefData(indicator = "CME_MRY0T4", year = "2015:2023")
# 
# # Non-contiguous years
# df <- unicefData(indicator = "CME_MRY0T4", year = "2015,2018,2020")
# 
# # Circa mode: find closest available year
# df <- unicefData(indicator = "CME_MRY0T4", year = 2015, circa = TRUE)

## ----sex----------------------------------------------------------------------
# # Total only (default)
# df <- unicefData(indicator = "CME_MRY0T4", sex = "_T")
# 
# # Female only
# df <- unicefData(indicator = "CME_MRY0T4", sex = "F")
# 
# # All sex categories (total, male, female)
# df <- unicefData(indicator = "CME_MRY0T4", sex = "ALL")

## ----wealth-------------------------------------------------------------------
# # Example 8 (paper): Stunting by wealth and sex
# df <- unicefData(
#   indicator = "NT_ANT_WHZ_NE2",
#   countries = "IND",
#   sex = "ALL",
#   wealth = "ALL"
# )

## ----residence----------------------------------------------------------------
# # Urban only
# df <- unicefData(indicator = "NT_ANT_HAZ_NE2", residence = "U")
# 
# # Rural only
# df <- unicefData(indicator = "NT_ANT_HAZ_NE2", residence = "R")

## ----wide---------------------------------------------------------------------
# # Example 9 (paper): Wide format
# df_wide <- unicefData(
#   indicator = "CME_MRY0T4",
#   countries = c("USA", "GBR", "DEU", "FRA"),
#   year = "2000,2010,2020,2023",
#   format = "wide"
# )

## ----multi-indicator----------------------------------------------------------
# # Example 10 (paper): Multiple indicators
# df <- unicefData(
#   indicator = c("CME_MRM0", "CME_MRY0T4"),
#   countries = c("KEN", "TZA", "UGA"),
#   year = 2020
# )
# 
# # Wide indicators format: one column per indicator
# df_wide <- unicefData(
#   indicator = c("CME_MRY0T4", "CME_MRY0", "IM_DTP3", "IM_MCV1"),
#   countries = c("AFG", "ETH", "PAK", "NGA"),
#   latest = TRUE,
#   format = "wide_indicators"
# )

## ----metadata-----------------------------------------------------------------
# # Example 12 (paper): Regional classifications
# df <- unicefData(
#   indicator = "CME_MRY0T4",
#   add_metadata = c("region", "income_group"),
#   latest = TRUE
# )

## ----clean-filter-------------------------------------------------------------
# # Clean raw SDMX column names to user-friendly names
# df_raw <- unicefData_raw(indicator = "CME_MRY0T4", countries = "BRA")
# df_clean <- clean_unicef_data(df_raw)
# 
# # Filter to specific disaggregations
# df_filtered <- filter_unicef_data(df_clean, sex = "F", wealth = "Q1")

## ----cache--------------------------------------------------------------------
# # Clear all caches and reload metadata
# clear_unicef_cache()
# 
# # Clear without reloading (lazy reload on next use)
# clear_unicef_cache(reload = FALSE)
# 
# # View cache status
# get_cache_info()

## ----schema-------------------------------------------------------------------
# # View the dimensions and attributes of a dataflow
# schema <- dataflow_schema("CME")
# print(schema)


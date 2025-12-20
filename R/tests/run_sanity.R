# Minimal sanity check for unicefData R functions
source("c:/GitHub/others/unicefData/R/unicefData.R")

df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "BRA"),
  year = "2015:2020"
)

print(head(df))

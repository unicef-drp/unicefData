knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

library(unicefData)
library(dplyr)

# Fetch under-5 mortality for South Asian countries
df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("AFG", "BGD", "BTN", "IND", "MDV", "NPL", "PAK", "LKA")
)

# Filter to total (both sexes)
df_total <- df %>% filter(sex == "_T" | is.na(sex))

# Plot trends
plot(
  value ~ period,
  data = df_total[df_total$iso3 == "AFG", ],
  type = "l", col = "red", lwd = 2,
  ylim = range(df_total$value, na.rm = TRUE),
  xlab = "Year", ylab = "Under-5 mortality rate (per 1,000)",
  main = "U5MR Trends in South Asia"
)
lines(value ~ period, data = df_total[df_total$iso3 == "BGD", ], col = "blue", lwd = 2)
lines(value ~ period, data = df_total[df_total$iso3 == "IND", ], col = "green", lwd = 2)
lines(value ~ period, data = df_total[df_total$iso3 == "PAK", ], col = "orange", lwd = 2)
legend("topright",
  legend = c("Afghanistan", "Bangladesh", "India", "Pakistan"),
  col = c("red", "blue", "green", "orange"), lwd = 2
)

# Fetch stunting data with all wealth quintiles
df <- unicefData(
  indicator = "NT_ANT_HAZ_NE2",
  sex = "ALL",
  wealth = "ALL",
  latest = TRUE
)

# Filter to wealth quintiles only
df_wealth <- df %>%
  filter(wealth_quintile %in% c("Q1", "Q2", "Q3", "Q4", "Q5"))

# Average stunting by wealth quintile (global)
summary_wealth <- df_wealth %>%
  group_by(wealth_quintile) %>%
  summarise(mean_stunting = mean(value, na.rm = TRUE), .groups = "drop") %>%
  arrange(wealth_quintile)

print(summary_wealth)

# Visualize the wealth gradient
barplot(
  summary_wealth$mean_stunting,
  names.arg = summary_wealth$wealth_quintile,
  ylab = "Stunting prevalence (%)",
  main = "Child Stunting by Wealth Quintile",
  col = c("#d73027", "#fc8d59", "#fee090", "#91bfdb", "#4575b4")
)

# Fetch stunting for specific countries with Q1 and Q5
df <- unicefData(
  indicator = "NT_ANT_HAZ_NE2",
  countries = c("IND", "PAK", "BGD", "ETH"),
  wealth = "ALL",
  latest = TRUE
)

# Compute wealth gap (Q1 - Q5 = poorest minus richest)
df_gap <- df %>%
  filter(wealth_quintile %in% c("Q1", "Q5")) %>%
  tidyr::pivot_wider(
    id_cols = c(iso3, country),
    names_from = wealth_quintile,
    values_from = value
  ) %>%
  mutate(wealth_gap = Q1 - Q5) %>%
  arrange(desc(wealth_gap))

print(df_gap)

# Fetch multiple mortality indicators
df <- unicefData(
  indicator = c("CME_MRM0", "CME_MRY0T4"),
  countries = c("BRA", "MEX", "ARG", "COL", "PER", "CHL"),
  year = "2020:2023"
)

# Keep latest year per country-indicator
df_latest <- df %>%
  filter(sex == "_T" | is.na(sex)) %>%
  group_by(iso3, indicator) %>%
  slice_max(period, n = 1) %>%
  ungroup()

# Reshape wide for comparison
df_wide <- df_latest %>%
  select(iso3, country, indicator, value) %>%
  tidyr::pivot_wider(names_from = indicator, values_from = value)

print(df_wide)

# Fetch immunization indicators
df <- unicefData(
  indicator = c("IM_DTP3", "IM_MCV1"),
  year = "2000:2023"
)

# Global average by year and indicator
trends <- df %>%
  group_by(period, indicator) %>%
  summarise(coverage = mean(value, na.rm = TRUE), .groups = "drop")

# Plot
dtp3 <- trends[trends$indicator == "IM_DTP3", ]
mcv1 <- trends[trends$indicator == "IM_MCV1", ]

plot(coverage ~ period, data = dtp3, type = "l", col = "blue", lwd = 2,
     ylim = c(60, 95), xlab = "Year", ylab = "Coverage (%)",
     main = "Global Immunization Coverage Trends")
lines(coverage ~ period, data = mcv1, col = "red", lwd = 2)
legend("bottomright", legend = c("DTP3", "MCV1"),
       col = c("blue", "red"), lwd = 2)

# Fetch with regional classifications
df <- unicefData(
  indicator = "CME_MRY0T4",
  add_metadata = c("region", "income_group"),
  latest = TRUE
)

# Filter to countries only (exclude regional aggregates)
df_countries <- df %>%
  filter(geo_type == 0, sex == "_T" | is.na(sex))

# Average U5MR by region
by_region <- df_countries %>%
  group_by(region) %>%
  summarise(avg_u5mr = mean(value, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(avg_u5mr))

print(by_region)

# Average U5MR by income group
by_income <- df_countries %>%
  group_by(income_group) %>%
  summarise(avg_u5mr = mean(value, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(avg_u5mr))

print(by_income)

# Wide format: years as columns
df_wide <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("USA", "BRA", "IND", "CHN"),
  year = "2015:2023",
  format = "wide"
)

# Compute change over time
# Columns will be named yr2015, yr2016, ..., yr2023
# (exact names depend on available data)
print(df_wide)

# One column per indicator
df_cross <- unicefData(
  indicator = c("CME_MRY0T4", "CME_MRY0", "IM_DTP3", "IM_MCV1"),
  countries = c("AFG", "ETH", "PAK", "NGA"),
  latest = TRUE,
  format = "wide_indicators"
)

print(df_cross)

# Correlation between mortality and immunization
if (all(c("CME_MRY0T4", "IM_DTP3") %in% names(df_cross))) {
  cor_val <- cor(df_cross$CME_MRY0T4, df_cross$IM_DTP3, use = "complete.obs")
  message("Correlation between U5MR and DTP3: ", round(cor_val, 3))
}

# Fetch all sex categories
df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("IND", "PAK", "BGD"),
  year = 2020,
  sex = "ALL"
)

# Compute male-female gap (biological pattern: male > female)
df_gap <- df %>%
  filter(sex %in% c("M", "F")) %>%
  tidyr::pivot_wider(
    id_cols = c(iso3, country, period),
    names_from = sex,
    values_from = value
  ) %>%
  mutate(mf_gap = M - F)

print(df_gap)

# Stunting prevalence
df_stunting <- unicefData(indicator = "NT_ANT_HAZ_NE2", latest = TRUE)

# Stunting by wealth (poorest quintile only)
df_q1 <- unicefData(
  indicator = "NT_ANT_HAZ_NE2",
  wealth = "Q1",
  latest = TRUE
)

# Stunting by residence (rural only)
df_rural <- unicefData(
  indicator = "NT_ANT_HAZ_NE2",
  residence = "R",
  latest = TRUE
)

# Basic drinking water services
df_water <- unicefData(indicator = "WS_PPL_W-B", latest = TRUE)

# Basic sanitation services
df_sanitation <- unicefData(indicator = "WS_PPL_S-B", latest = TRUE)

# Out-of-school rate (primary)
df_oos <- unicefData(indicator = "ED_ROFST_L1", latest = TRUE)

# Net attendance rate (primary)
df_nar <- unicefData(indicator = "ED_ANAR_L1", latest = TRUE)

# Process multiple indicators, some of which may not exist
indicators <- c("CME_MRY0T4", "IM_DTP3", "INVALID_CODE_XYZ")

results <- list()
for (ind in indicators) {
  tryCatch({
    results[[ind]] <- unicefData(indicator = ind, countries = "BRA", latest = TRUE)
    message("OK: ", ind, " (", nrow(results[[ind]]), " rows)")
  }, error = function(e) {
    message("FAIL: ", ind, " - ", conditionMessage(e))
  })
}

# Fetch and export to CSV
df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "USA", "BRA", "IND", "CHN", "NGA"),
  year = "2015:2023",
  add_metadata = c("region", "income_group")
)

# Export
write.csv(df, "unicef_mortality_data.csv", row.names = FALSE)

# Sync all metadata
sync_metadata()

# Or sync specific components
sync_dataflows()
sync_indicators()
sync_codelists()

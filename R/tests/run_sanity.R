# Minimal sanity check for unicefData R functions
# Load the package (works both in dev and installed mode)
if (!requireNamespace("unicefData", quietly = TRUE)) {
  # For dev mode, load from source
  devtools::load_all()
}

df <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "BRA"),
  year = "2015:2020"
)

print(head(df))

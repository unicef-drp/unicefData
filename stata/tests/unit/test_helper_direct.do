clear all
set more off
discard

// Test the helper directly with in-memory test data
di ""
di "=== Testing helper directly ==="

// Create test data that mimics the csv-ts format
clear
input str10 v1 str20 v2 str5 v3 float(v8 v9 v10 v11 v12)
"REF_AREA" "INDICATOR" "SEX" 1932 1933 1934 1935 1936
"AFG" "CME_MRY0T4" "F" 100.5 99.2 98.1 97.0 96.5
"AGO" "CME_MRY0T4" "F" 200.1 198.5 196.2 194.0 192.3
end

di ""
di "Before helper - list in 1/3:"
list in 1/3

di ""
di "Calling helper..."

* Save to tempfile for helper to process
tempfile testcsv
export delimited using "`testcsv'", replace

_get_sdmx_rename_year_columns, csvfile("`testcsv'")

di ""
di "After helper - list in 1/2:"
list in 1/2

di ""
di "Year variables:"
ds yr*

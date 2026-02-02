// Test script: Manually download and import csv-ts data
clear all
set more off

display as text "{hline 70}"
display as text "Testing manual csv-ts download and import"
display as text "{hline 70}"

// The URL that should work (from trace)
local url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/.CME_MRY0T4..?format=csv-ts&labels=id"

display as text _newline "Step 1: Download file..."
tempfile testfile
capture copy "`url'" "`testfile'", replace public

if _rc != 0 {
    display as error "Download failed with rc = " _rc
    exit _rc
}
else {
    display as result "✓ Download successful"
}

// Check file size
display as text _newline "Step 2: Check file size..."
quietly checksum "`testfile'"
local fsize = r(filelen)
display as result "✓ File size: " `fsize' " bytes"

// Read first line to check format
display as text _newline "Step 3: Read first line..."
tempname fh
file open `fh' using "`testfile'", read text
file read `fh' first_line
file close `fh'

display as text "First 200 characters:"
display as result substr("`first_line'", 1, 200)

// Try importing with insheet
display as text _newline "Step 4: Import with insheet..."
capture insheet using "`testfile'", clear

if _rc != 0 {
    display as error "insheet failed with rc = " _rc
    exit _rc
}
else {
    display as result "✓ insheet successful"
    display as result "✓ Observations loaded: " _N
}

// Show column names
display as text _newline "Step 5: Column names before renaming..."
describe, simple

// Apply year column renaming
display as text _newline "Step 6: Rename year columns..."
_get_sdmx_rename_year_columns

// Show column names after
display as text _newline "Step 7: Column names after renaming..."
describe, simple

// Show first few rows
display as text _newline "Step 8: First 3 observations..."
list in 1/3, abbrev(10)

display as text _newline "{hline 70}"
display as result "✓ TEST COMPLETE"
display as text "{hline 70}"

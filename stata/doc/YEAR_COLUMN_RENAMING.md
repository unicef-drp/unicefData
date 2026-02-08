# Column Name Extraction and Year Renaming for CSV-TS Format

## Overview

When importing SDMX csv-ts format data, year columns come in as numeric names (1932, 1933, 2020, etc.). Stata requires column names that don't start with numbers, so we need to rename them to yr1932, yr1933, yr2020, etc.

## Solution 1: Helper Program (Recommended)

**File**: `_get_sdmx_rename_year_columns.ado`  
**Location**: `c:\GitHub\myados\unicefData-dev\stata\src\_\_get_sdmx_rename_year_columns.ado`

This helper program automatically renames all year columns in the current dataset:

```stata
*! version 1.0.0  19Jan2026
program define _get_sdmx_rename_year_columns
    version 11
    
    // Get all variable names
    quietly ds
    local allvars `r(varlist)'
    
    // Loop through and rename year columns
    foreach var of local allvars {
        // Check if 4-digit year (1900-2099)
        if regexm("`var'", "^[0-9][0-9][0-9][0-9]$") {
            local year = "`var'"
            capture rename `var' yr`year'
        }
        // Also handle v#### pattern (insheet creates these sometimes)
        else if regexm("`var'", "^v([0-9][0-9][0-9][0-9])$") {
            local year = regexs(1)
            capture rename `var' yr`year'
        }
    }
end
```

**Usage**:
```stata
insheet using "data.csv", clear
_get_sdmx_rename_year_columns
describe
```

## Solution 2: Standalone Script

**File**: `extract_and_rename_year_columns.do`  
**Location**: `c:\GitHub\myados\unicefData-dev\stata\src\extract_and_rename_year_columns.do`

This standalone script provides verbose output showing which columns were renamed:

**Usage**:
```stata
insheet using "data.csv", clear
do extract_and_rename_year_columns.do
```

**Output**:
```
Examining column names...
----------------------------------------------------------------------
  ✓ Renamed: 2020 → yr2020
  ✓ Renamed: 2021 → yr2021
  ✓ Renamed: 2022 → yr2022
----------------------------------------------------------------------
✓ Renamed 3 year column(s)
```

## Integration with unicefdata

The helper program is automatically called when using the `wide` option:

```stata
unicefdata, indicator(CME_MRY0T4) clear wide
```

This will:
1. Fetch data in csv-ts format (years as columns)
2. Import with `insheet`
3. Automatically rename year columns to yr####
4. Return data ready for analysis

## Technical Details

### Year Column Patterns Handled

| Pattern | Example | Renamed To | Source |
|---------|---------|------------|--------|
| `####` | `2020` | `yr2020` | Direct numeric column name |
| `v####` | `v2020` | `yr2020` | insheet auto-naming |
| `value####` | `value2020` | `yr2020` | reshape/wide operations |

### Regex Pattern

```stata
// Main pattern: 4-digit year
regexm("`var'", "^[0-9][0-9][0-9][0-9]$")

// Alternative: v + 4 digits  
regexm("`var'", "^v([0-9][0-9][0-9][0-9])$")
```

### Error Handling

The program uses `capture rename` to gracefully handle:
- Duplicate column names
- Invalid variable names
- Already-renamed columns

If a column can't be renamed, it's silently skipped.

## Testing

Test manual import and renaming:

```stata
clear all

* Download csv-ts data
local url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/.CME_MRY0T4..?format=csv-ts&labels=id"
tempfile testdata
copy "`url'" "`testdata'", replace public

* Import
insheet using "`testdata'", clear

* Show columns before renaming
describe, simple

* Rename year columns
_get_sdmx_rename_year_columns

* Show columns after renaming
describe, simple

* Check year columns exist
capture confirm variable yr2020 yr2021 yr2022
if _rc == 0 {
    display as result "✓ Year columns successfully renamed"
}
```

## Files Created

1. **`_get_sdmx_rename_year_columns.ado`** - Helper program (deployed to user ado directory)
2. **`extract_and_rename_year_columns.do`** - Standalone script with verbose output
3. **`test_manual_csvts_import.do`** - Complete test workflow

All files are in: `c:\GitHub\myados\unicefData-dev\stata\src\`


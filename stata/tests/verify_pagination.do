*
* Verify SDMX pagination and row limits by direct CSV import
* Adjust `dataflow` and `indicator` to match the target indicator.
*
clear all
set more off

local base "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
local dataflow "CME"          // Example flow; change as needed
local version  "1.0"
local indicator "CME_MRY0T4"   // Example indicator; change as needed
local page_size = 100000

local url "`base'/data/UNICEF,`dataflow',`version'/.`indicator'./?format=csv&labels=id&count=`page_size'&startIndex=0"

noi di "Requesting: `url'"

preserve
import delimited using "`url'", varnames(1) clear stringcols( _all )

noi di "Imported rows: " _N

/*
If you see only ~100 rows, the server default count or client-side limitation is active.
This script uses explicit count=100000 and startIndex=0 to fetch the first page.
To fetch subsequent pages (if needed), loop with startIndex = page * page_size
and append the results.
*/

restore


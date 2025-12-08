* Test Stata native import xml with SDMX
clear all
set more off

tempfile xmlfile
copy "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_WORLD_REGIONS/latest" "`xmlfile'", public replace

di as text "Attempting import xml..."
capture import xml "`xmlfile'", firstrow
if (_rc != 0) {
    di as err "import xml failed with rc = " _rc
    di as text "This confirms SDMX XML is not compatible with Stata's import xml"
}
else {
    di as result "Surprisingly, import xml worked!"
    describe
}
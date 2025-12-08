* Comprehensive test of unicefdata_xmltoyaml_py for all types
clear all
set more off

cd "D:\jazevedo\GitHub\unicefData"
adopath + "stata/src/u"
do "stata/src/u/unicefdata_xmltoyaml_py.ado"

di as text "{hline 70}"
di as text "{bf:COMPREHENSIVE TEST: Stata Python XML Parser}"
di as text "{hline 70}"

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
local outdir "stata/tests/output"
tempfile xml_data

* Test 1: Dataflows
di _n as text "{bf:1. Dataflows}"
copy "`base_url'/dataflow/UNICEF" "`xml_data'", public replace
unicefdata_xmltoyaml_py, type(dataflows) xmlfile("`xml_data'") ///
    outfile("`outdir'/dataflows_final.yaml") agency(UNICEF)
local df_count = r(count)

* Test 2: Countries
di _n as text "{bf:2. Countries}"
copy "`base_url'/codelist/UNICEF/CL_COUNTRY/latest" "`xml_data'", public replace
unicefdata_xmltoyaml_py, type(countries) xmlfile("`xml_data'") ///
    outfile("`outdir'/countries_final.yaml") agency(UNICEF)
local co_count = r(count)

* Test 3: Regions
di _n as text "{bf:3. Regions}"
copy "`base_url'/codelist/UNICEF/CL_REF_AREA_SDG/latest" "`xml_data'", public replace
unicefdata_xmltoyaml_py, type(regions) xmlfile("`xml_data'") ///
    outfile("`outdir'/regions_final.yaml") agency(UNICEF)
local rg_count = r(count)

* Test 4: Indicators (large file)
di _n as text "{bf:4. Indicators (large file)}"
copy "`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest" "`xml_data'", public replace
unicefdata_xmltoyaml_py, type(indicators) xmlfile("`xml_data'") ///
    outfile("`outdir'/indicators_final.yaml") agency(UNICEF)
local in_count = r(count)

* Test 5: Codelists (generic)
di _n as text "{bf:5. Codelists (CL_AGE)}"
copy "`base_url'/codelist/UNICEF/CL_AGE/latest" "`xml_data'", public replace
unicefdata_xmltoyaml_py, type(codelists) xmlfile("`xml_data'") ///
    outfile("`outdir'/age_final.yaml") agency(UNICEF)
local cl_count = r(count)

* Summary
di _n as text "{hline 70}"
di as text "{bf:SUMMARY}"
di as text "{hline 70}"
di as text "  Dataflows:  " as result "`df_count'"
di as text "  Countries:  " as result "`co_count'"
di as text "  Regions:    " as result "`rg_count'"
di as text "  Indicators: " as result "`in_count'"
di as text "  Codelists:  " as result "`cl_count'"
di as text "{hline 70}"
di as result "{bf:All tests completed successfully!}"
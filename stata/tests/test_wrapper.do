* Test unicefdata_xmltoyaml_py wrapper
clear all
set more off

cd "D:\jazevedo\GitHub\unicefData"
adopath + "stata/src/u"
do "stata/src/u/unicefdata_xmltoyaml_py.ado"

di as text "{hline 70}"
di as text "{bf:Testing Stata Python Wrapper}"
di as text "{hline 70}"

* Test with indicators (large file)
tempfile xml_data
local url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/latest"

di as text "Downloading indicators..."
copy "`url'" "`xml_data'", public replace

di as text "Parsing with Python wrapper..."
unicefdata_xmltoyaml_py, type(indicators) xmlfile("`xml_data'") ///
    outfile("stata/tests/output/indicators_wrapper.yaml") agency(UNICEF)

di as result "Result: `r(count)' indicators parsed"
di as text "{hline 70}"
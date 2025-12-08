*******************************************************************************
* Simple test for unicefdata_xmltoyaml - just dataflows
*******************************************************************************

clear all
set more off

cd "D:\jazevedo\GitHub\unicefData"

* Clear any cached program definitions
capture program drop _unicefdata_xml_to_yaml
capture program drop _xmltoyaml_get_schema
capture program drop _xmltoyaml_parse
capture program drop _xmltoyaml_parse_chunked
capture program drop _xmltoyaml_process_chunk
capture program drop _xmltoyaml_parse_lines

* Load the ado file
adopath + "stata/src/u"
do "stata/src/u/unicefdata_xmltoyaml.ado"

di _n as text "{bf:Testing Dataflows Parser}"
di as text "{hline 50}"

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
tempfile xml_file

* Test dataflows
di as text "  Downloading dataflows..."
capture copy "`base_url'/dataflow/UNICEF?references=none&detail=full" "`xml_file'", public replace

if (_rc == 0) {
    di as text "  Calling parser..."
    capture noisily _unicefdata_xml_to_yaml, ///
        type(dataflows) ///
        xmlfile("`xml_file'") ///
        outfile("stata/tests/output/simple_dataflows.yaml") ///
        agency(UNICEF)
    
    if (_rc == 0) {
        di as result "  SUCCESS! Parsed `r(count)' dataflows"
    }
    else {
        di as err "  FAILED with error code: " _rc
    }
}
else {
    di as err "  Download failed"
}

di _n as text "Test complete."

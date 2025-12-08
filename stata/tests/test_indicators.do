*******************************************************************************
* Test indicators parsing specifically
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

di _n as text "{bf:Testing Indicators Parser (Large File - 550KB)}"
di as text "{hline 60}"

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
tempfile xml_file

* Test indicators
di as text "  Downloading indicators (CL_UNICEF_INDICATOR)..."
capture copy "`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest" "`xml_file'", public replace

if (_rc == 0) {
    * Check file size
    quietly checksum "`xml_file'"
    local fsize = r(filelen)
    di as text "  File size: `fsize' bytes"
    
    di as text "  Calling parser..."
    capture noisily _unicefdata_xml_to_yaml, ///
        type(indicators) ///
        xmlfile("`xml_file'") ///
        outfile("stata/tests/output/test_indicators2.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest")
    
    if (_rc == 0) {
        di as result "  SUCCESS! Parsed `r(count)' indicators"
    }
    else {
        di as err "  FAILED with error code: " _rc
    }
}
else {
    di as err "  Download failed"
}

di _n as text "Test complete."

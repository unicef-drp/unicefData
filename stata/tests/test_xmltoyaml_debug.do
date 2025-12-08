*******************************************************************************
* Debug test script for unicefdata_xmltoyaml
*******************************************************************************

clear all
set more off
set trace on
set tracedepth 3

cd "D:\jazevedo\GitHub\unicefData"

* Add ado paths
adopath + "stata/src/u"
do "stata/src/u/unicefdata_xmltoyaml.ado"

* Test dataflows
di _n as text "Testing dataflows..."

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
tempfile dataflows_xml

* Download dataflows XML
di as text "  Downloading dataflows..."
capture copy "`base_url'/dataflow/UNICEF?references=none&detail=full" "`dataflows_xml'", public replace

if (_rc == 0) {
    di as text "  File downloaded, calling parser..."
    
    * Call with explicit capture to see error details
    capture noisily _unicefdata_xml_to_yaml, ///
        type(dataflows) ///
        xmlfile("`dataflows_xml'") ///
        outfile("stata/tests/output/debug_dataflows.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/dataflow/UNICEF")
    
    di as text "  Return code: " _rc
    if (_rc == 0) {
        di as result "  Success! Count: `r(count)'"
    }
}
else {
    di as err "  Download failed"
}

set trace off

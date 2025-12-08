*******************************************************************************
* Test XML to YAML Parser with Python Support
* Tests both small files (Stata processing) and large files (Python processing)
*******************************************************************************

clear all
set more off

cd "D:\jazevedo\GitHub\unicefData"

di as text "{hline 70}"
di as text "{bf:TESTING XML TO YAML PARSER WITH PYTHON SUPPORT}"
di as text "{hline 70}"

* Load the parser
adopath + "stata/src/u"
do "stata/src/u/unicefdata_xmltoyaml.ado"

* Create output directory
capture mkdir "stata/tests/output"

*---------------------------------------------------------------------------
* Test 1: Dataflows (small file - should use Stata)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 1: Dataflows (small file - Stata processing)}"
di as text "{hline 50}"

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
tempfile xml_data

di as text "  Downloading dataflows XML..."
capture copy "`base_url'/dataflow/UNICEF" "`xml_data'", public replace

if (_rc == 0) {
    * Check file size
    quietly checksum "`xml_data'"
    local fsize = r(filelen)
    di as text "  File size: `fsize' bytes"
    
    di as text "  Parsing dataflows..."
    _unicefdata_xml_to_yaml, type(dataflows) xmlfile("`xml_data'") ///
        outfile("stata/tests/output/test_dataflows2.yaml") agency(UNICEF)
    
    di as result "  ✓ Dataflows: `r(count)' parsed"
}
else {
    di as err "  ✗ Failed to download dataflows"
}

*---------------------------------------------------------------------------
* Test 2: Countries (medium file - might use Python)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 2: Countries (medium file)}"
di as text "{hline 50}"

di as text "  Downloading countries XML..."
capture copy "`base_url'/codelist/UNICEF/CL_COUNTRY/latest" "`xml_data'", public replace

if (_rc == 0) {
    quietly checksum "`xml_data'"
    local fsize = r(filelen)
    di as text "  File size: `fsize' bytes"
    
    di as text "  Parsing countries..."
    _unicefdata_xml_to_yaml, type(countries) xmlfile("`xml_data'") ///
        outfile("stata/tests/output/test_countries2.yaml") agency(UNICEF)
    
    di as result "  ✓ Countries: `r(count)' parsed"
}
else {
    di as err "  ✗ Failed to download countries"
}

*---------------------------------------------------------------------------
* Test 3: Indicators (large file - should use Python)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 3: Indicators (large file - Python processing)}"
di as text "{hline 50}"

di as text "  Downloading indicators XML (~551KB)..."
capture copy "`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest" "`xml_data'", public replace

if (_rc == 0) {
    quietly checksum "`xml_data'"
    local fsize = r(filelen)
    di as text "  File size: `fsize' bytes"
    
    if (`fsize' > 100000) {
        di as text "  File > 100KB, will use Python..."
    }
    
    di as text "  Parsing indicators..."
    _unicefdata_xml_to_yaml, type(indicators) xmlfile("`xml_data'") ///
        outfile("stata/tests/output/test_indicators2.yaml") agency(UNICEF)
    
    di as result "  ✓ Indicators: `r(count)' parsed"
}
else {
    di as err "  ✗ Failed to download indicators"
}

*---------------------------------------------------------------------------
* Test 4: DSD Dimensions (very large file - needs Python)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 4: DSD Dimensions (very large file)}"
di as text "{hline 50}"

di as text "  Downloading DSD XML (may be very large)..."
capture copy "`base_url'/datastructure/UNICEF/TRANSMONEE/latest?references=children" "`xml_data'", public replace

if (_rc == 0) {
    quietly checksum "`xml_data'"
    local fsize = r(filelen)
    di as text "  File size: `fsize' bytes"
    
    di as text "  Parsing dimensions..."
    _unicefdata_xml_to_yaml, type(dimensions) xmlfile("`xml_data'") ///
        outfile("stata/tests/output/test_dimensions2.yaml") agency(UNICEF)
    
    di as result "  ✓ Dimensions: `r(count)' parsed"
}
else {
    di as err "  ✗ Failed to download DSD"
}

*---------------------------------------------------------------------------
* Summary
*---------------------------------------------------------------------------

di _n as text "{hline 70}"
di as text "{bf:SUMMARY}"
di as text "{hline 70}"

* List output files
local output_dir "stata/tests/output"
local files : dir "`output_dir'" files "*2.yaml"

foreach f of local files {
    quietly checksum "`output_dir'/`f'"
    local fsize = r(filelen)
    
    * Count items
    tempname fh
    local count = 0
    capture file open `fh' using "`output_dir'/`f'", read text
    if (_rc == 0) {
        file read `fh' line
        while (!r(eof)) {
            if (strpos(`"`line'"', "- id:") == 1) {
                local count = `count' + 1
            }
            file read `fh' line
        }
        file close `fh'
    }
    
    di as text "  `f': " as result "`count' items" as text " (`fsize' bytes)"
}

di _n as text "{hline 70}"
di as text "{bf:Test complete}"
di as text "{hline 70}"

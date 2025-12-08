*******************************************************************************
* Test script for Python-based XML to YAML parser
* Tests the unicefdata_xmltoyaml_py command
*******************************************************************************

clear all
set more off

cd "D:\jazevedo\GitHub\unicefData"

* Load the ado files
adopath + "stata/src/u"
do "stata/src/u/unicefdata_xmltoyaml_py.ado"

di _n as text "{hline 70}"
di as text "{bf:TESTING PYTHON-BASED XML TO YAML PARSER}"
di as text "{hline 70}"

* Create output directory
capture mkdir "stata/tests/output"

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"

*---------------------------------------------------------------------------
* Test 1: Parse Dataflows (small file, ~28KB)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 1: Parsing Dataflows (using Python)}"
di as text "{hline 50}"

tempfile xml_file

di as text "  Downloading dataflows..."
capture copy "`base_url'/dataflow/UNICEF?references=none&detail=full" "`xml_file'", public replace

if (_rc == 0) {
    quietly checksum "`xml_file'"
    di as text "  File size: `r(filelen)' bytes"
    
    di as text "  Calling Python parser..."
    capture noisily unicefdata_xmltoyaml_py, ///
        type(dataflows) ///
        xmlfile("`xml_file'") ///
        outfile("stata/tests/output/py_dataflows.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/dataflow/UNICEF")
    
    if (_rc == 0) {
        di as result "  ✓ SUCCESS! Parsed `r(count)' dataflows"
    }
    else {
        di as err "  ✗ FAILED with error code: " _rc
    }
}
else {
    di as err "  ✗ Download failed"
}

*---------------------------------------------------------------------------
* Test 2: Parse Countries (medium file, ~100KB)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 2: Parsing Countries (using Python)}"
di as text "{hline 50}"

tempfile xml_file

di as text "  Downloading countries..."
capture copy "`base_url'/codelist/UNICEF/CL_COUNTRY/latest" "`xml_file'", public replace

if (_rc == 0) {
    quietly checksum "`xml_file'"
    di as text "  File size: `r(filelen)' bytes"
    
    di as text "  Calling Python parser..."
    capture noisily unicefdata_xmltoyaml_py, ///
        type(countries) ///
        xmlfile("`xml_file'") ///
        outfile("stata/tests/output/py_countries.yaml") ///
        agency(UNICEF) ///
        codelistid(CL_COUNTRY) ///
        codelistname("Countries") ///
        source("`base_url'/codelist/UNICEF/CL_COUNTRY/latest")
    
    if (_rc == 0) {
        di as result "  ✓ SUCCESS! Parsed `r(count)' countries"
    }
    else {
        di as err "  ✗ FAILED with error code: " _rc
    }
}
else {
    di as err "  ✗ Download failed"
}

*---------------------------------------------------------------------------
* Test 3: Parse Indicators (large file, ~550KB) - THE KEY TEST
*---------------------------------------------------------------------------

di _n as text "{bf:Test 3: Parsing Indicators (LARGE FILE - using Python)}"
di as text "{hline 50}"

tempfile xml_file

di as text "  Downloading indicators (CL_UNICEF_INDICATOR)..."
capture copy "`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest" "`xml_file'", public replace

if (_rc == 0) {
    quietly checksum "`xml_file'"
    di as text "  File size: `r(filelen)' bytes (should be >500KB)"
    
    di as text "  Calling Python parser..."
    capture noisily unicefdata_xmltoyaml_py, ///
        type(indicators) ///
        xmlfile("`xml_file'") ///
        outfile("stata/tests/output/py_indicators.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest")
    
    if (_rc == 0) {
        di as result "  ✓ SUCCESS! Parsed `r(count)' indicators"
    }
    else {
        di as err "  ✗ FAILED with error code: " _rc
    }
}
else {
    di as err "  ✗ Download failed"
}

*---------------------------------------------------------------------------
* Test 4: Parse DSD Dimensions (large file with complex structure)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 4: Parsing DSD Dimensions (using Python)}"
di as text "{hline 50}"

tempfile xml_file

di as text "  Downloading DSD for CME..."
capture copy "`base_url'/dataflow/UNICEF/CME/1.0?references=all" "`xml_file'", public replace

if (_rc == 0) {
    quietly checksum "`xml_file'"
    di as text "  File size: `r(filelen)' bytes"
    
    di as text "  Calling Python parser for dimensions..."
    capture noisily unicefdata_xmltoyaml_py, ///
        type(dimensions) ///
        xmlfile("`xml_file'") ///
        outfile("stata/tests/output/py_dimensions.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/dataflow/UNICEF/CME/1.0?references=all")
    
    if (_rc == 0) {
        di as result "  ✓ SUCCESS! Parsed `r(count)' dimensions"
    }
    else {
        di as err "  ✗ FAILED with error code: " _rc
    }
    
    di as text "  Calling Python parser for attributes..."
    capture noisily unicefdata_xmltoyaml_py, ///
        type(attributes) ///
        xmlfile("`xml_file'") ///
        outfile("stata/tests/output/py_attributes.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/dataflow/UNICEF/CME/1.0?references=all")
    
    if (_rc == 0) {
        di as result "  ✓ SUCCESS! Parsed `r(count)' attributes"
    }
    else {
        di as err "  ✗ FAILED with error code: " _rc
    }
}
else {
    di as err "  ✗ Download failed"
}

*---------------------------------------------------------------------------
* Summary
*---------------------------------------------------------------------------

di _n as text "{hline 70}"
di as text "{bf:TEST SUMMARY}"
di as text "{hline 70}"

* List output files
di as text "Output files created:"
shell dir /b "stata\tests\output\py_*.yaml"

di _n as text "Tests complete."

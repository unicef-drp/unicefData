*******************************************************************************
* Test script for unicefdata_xmltoyaml generic parser
* Run from unicefData root directory
*******************************************************************************

clear all
set more off

* Change to project directory
cd "D:\jazevedo\GitHub\unicefData"

* Start log
capture log close
log using "stata/log/test_xmltoyaml.txt", replace text

di as text "{hline 70}"
di as text "{bf:TESTING unicefdata_xmltoyaml GENERIC PARSER}"
di as text "{hline 70}"

* Add ado paths
adopath + "stata/src/u"

* Clear any cached program definitions
capture program drop _unicefdata_xml_to_yaml
capture program drop _xmltoyaml_get_schema
capture program drop _xmltoyaml_parse
capture program drop _xmltoyaml_parse_chunked
capture program drop _xmltoyaml_process_chunk
capture program drop _xmltoyaml_parse_lines

* Source the ado file
do "stata/src/u/unicefdata_xmltoyaml.ado"

* Create test output directory
capture mkdir "stata/tests/output"

*---------------------------------------------------------------------------
* Test 1: Parse Dataflows
*---------------------------------------------------------------------------

di _n as text "{bf:Test 1: Parsing Dataflows}"
di as text "{hline 50}"

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
tempfile dataflows_xml

* Download dataflows XML
di as text "  Downloading dataflows..."
capture copy "`base_url'/dataflow/UNICEF?references=none&detail=full" "`dataflows_xml'", public replace

if (_rc == 0) {
    di as text "  Parsing with generic parser..."
    _unicefdata_xml_to_yaml, ///
        type(dataflows) ///
        xmlfile("`dataflows_xml'") ///
        outfile("stata/tests/output/test_dataflows.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/dataflow/UNICEF")
    
    di as result "  ✓ Parsed `r(count)' dataflows"
}
else {
    di as err "  ✗ Failed to download dataflows"
}

*---------------------------------------------------------------------------
* Test 2: Parse Countries (CL_COUNTRY)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 2: Parsing Countries}"
di as text "{hline 50}"

tempfile countries_xml

* Download countries XML
di as text "  Downloading countries..."
capture copy "`base_url'/codelist/UNICEF/CL_COUNTRY/latest" "`countries_xml'", public replace

if (_rc == 0) {
    di as text "  Parsing with generic parser..."
    _unicefdata_xml_to_yaml, ///
        type(countries) ///
        xmlfile("`countries_xml'") ///
        outfile("stata/tests/output/test_countries.yaml") ///
        agency(UNICEF) ///
        codelistid(CL_COUNTRY) ///
        codelistname("Statistical Reference Areas") ///
        source("`base_url'/codelist/UNICEF/CL_COUNTRY/latest")
    
    di as result "  ✓ Parsed `r(count)' countries"
}
else {
    di as err "  ✗ Failed to download countries"
}

*---------------------------------------------------------------------------
* Test 3: Parse Regions (CL_WORLD_REGIONS)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 3: Parsing Regions}"
di as text "{hline 50}"

tempfile regions_xml

* Download regions XML
di as text "  Downloading regions..."
capture copy "`base_url'/codelist/UNICEF/CL_WORLD_REGIONS/latest" "`regions_xml'", public replace

if (_rc == 0) {
    di as text "  Parsing with generic parser..."
    _unicefdata_xml_to_yaml, ///
        type(regions) ///
        xmlfile("`regions_xml'") ///
        outfile("stata/tests/output/test_regions.yaml") ///
        agency(UNICEF) ///
        codelistid(CL_WORLD_REGIONS) ///
        codelistname("World Geographic Regions") ///
        source("`base_url'/codelist/UNICEF/CL_WORLD_REGIONS/latest")
    
    di as result "  ✓ Parsed `r(count)' regions"
}
else {
    di as err "  ✗ Failed to download regions"
}

*---------------------------------------------------------------------------
* Test 4: Parse Indicators (CL_UNICEF_INDICATOR)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 4: Parsing Indicators}"
di as text "{hline 50}"

tempfile indicators_xml

* Download indicators XML
di as text "  Downloading indicators..."
capture copy "`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest" "`indicators_xml'", public replace

if (_rc == 0) {
    di as text "  Parsing with generic parser..."
    _unicefdata_xml_to_yaml, ///
        type(indicators) ///
        xmlfile("`indicators_xml'") ///
        outfile("stata/tests/output/test_indicators.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest")
    
    di as result "  ✓ Parsed `r(count)' indicators"
}
else {
    di as err "  ✗ Failed to download indicators"
}

*---------------------------------------------------------------------------
* Test 5: Parse Dimensions from a DSD (tests chunked processing)
*---------------------------------------------------------------------------

di _n as text "{bf:Test 5: Parsing Dimensions (from CME dataflow - chunked)}"
di as text "{hline 50}"

tempfile dsd_xml

* Download DSD XML for CME dataflow
di as text "  Downloading DSD for CME..."
capture copy "`base_url'/dataflow/UNICEF/CME/1.0?references=all" "`dsd_xml'", public replace

if (_rc == 0) {
    * Check file size
    di as text "  DSD file downloaded, testing chunked parser..."
    
    di as text "  Parsing dimensions with generic parser..."
    capture noisily {
        _unicefdata_xml_to_yaml, ///
            type(dimensions) ///
            xmlfile("`dsd_xml'") ///
            outfile("stata/tests/output/test_dimensions.yaml") ///
            agency(UNICEF) ///
            contenttype("dimensions") ///
            source("`base_url'/dataflow/UNICEF/CME/1.0?references=all")
    }
    
    if (_rc == 0) {
        di as result "  ✓ Parsed `r(count)' dimensions"
    }
    else {
        di as err "  ✗ Dimensions parsing failed with error: " _rc
    }
    
    * Also parse attributes
    di as text "  Parsing attributes with generic parser..."
    capture noisily {
        _unicefdata_xml_to_yaml, ///
            type(attributes) ///
            xmlfile("`dsd_xml'") ///
            outfile("stata/tests/output/test_attributes.yaml") ///
            agency(UNICEF) ///
            contenttype("attributes") ///
            source("`base_url'/dataflow/UNICEF/CME/1.0?references=all")
    }
    
    if (_rc == 0) {
        di as result "  ✓ Parsed `r(count)' attributes"
    }
    else {
        di as err "  ✗ Attributes parsing failed with error: " _rc
    }
}
else {
    di as err "  ✗ Failed to download DSD"
}

*---------------------------------------------------------------------------
* Summary
*---------------------------------------------------------------------------

di _n as text "{hline 70}"
di as text "{bf:Test Complete - Check output files in stata/tests/output/}"
di as text "{hline 70}"

* List created files
dir "stata/tests/output/*.yaml"

log close


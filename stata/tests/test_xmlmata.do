*******************************************************************************
* Test Mata XML Functions
* Explores whether Mata's undocumented XML parsing functions are available
*******************************************************************************

clear all
set more off

cd "D:\jazevedo\GitHub\unicefData"

di as text "{hline 70}"
di as text "{bf:TESTING MATA XML FUNCTIONS}"
di as text "{hline 70}"

* Load the mata XML parser
adopath + "stata/src/u"
do "stata/src/u/unicefdata_xmlmata.ado"

*---------------------------------------------------------------------------
* Test 1: Check if Mata XML functions exist
*---------------------------------------------------------------------------

di _n as text "{bf:Test 1: Checking Mata XML function availability}"
di as text "{hline 50}"

mata:
    // Try to check if _xml_new exists
    printf("Testing _xml_new()...\n")
    
    // Create XML parser
    xml = _xml_new()
    
    if (xml == 0) {
        printf("{err}  _xml_new() returned 0 - function may not exist or failed\n")
    }
    else {
        printf("{res}  _xml_new() returned handle: %g\n", xml)
        printf("{res}  Mata XML functions appear to be available!\n")
        
        // Clean up
        _xml_free(xml)
        printf("{txt}  Cleaned up XML parser\n")
    }
end

*---------------------------------------------------------------------------
* Test 2: Try to load a small XML file
*---------------------------------------------------------------------------

di _n as text "{bf:Test 2: Loading a small XML file}"
di as text "{hline 50}"

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
tempfile small_xml

* Download a small XML (regions - about 6KB)
di as text "  Downloading regions XML (small file ~6KB)..."
capture copy "`base_url'/codelist/UNICEF/CL_WORLD_REGIONS/latest" "`small_xml'", public replace

if (_rc == 0) {
    di as text "  Downloaded successfully"
    
    * Check file size
    quietly checksum "`small_xml'"
    di as text "  File size: " r(filelen) " bytes"
    
    * Try to explore the XML structure
    di as text "  Attempting to explore XML structure..."
    capture noisily _unicefdata_xmlmata_explore, xmlfile("`small_xml'") maxdepth(4) maxnodes(30)
    
    if (_rc == 0) {
        di as result "  ✓ XML exploration succeeded!"
    }
    else {
        di as err "  ✗ XML exploration failed with error: " _rc
    }
}
else {
    di as err "  ✗ Download failed"
}

*---------------------------------------------------------------------------
* Test 3: Try to parse regions using Mata
*---------------------------------------------------------------------------

di _n as text "{bf:Test 3: Parsing regions with Mata XML parser}"
di as text "{hline 50}"

if (_rc == 0) {
    di as text "  Attempting to parse regions..."
    capture noisily _unicefdata_xmlmata_parse, ///
        xmlfile("`small_xml'") ///
        type(regions) ///
        outfile("stata/tests/output/mata_regions.yaml") ///
        agency(UNICEF) ///
        codelistid(CL_WORLD_REGIONS) ///
        codelistname("World Regions") ///
        source("`base_url'/codelist/UNICEF/CL_WORLD_REGIONS/latest")
    
    if (_rc == 0) {
        di as result "  ✓ Parsed `r(count)' regions using Mata!"
    }
    else {
        di as err "  ✗ Parsing failed with error: " _rc
    }
}

*---------------------------------------------------------------------------
* Test 4: Try to parse dataflows using Mata
*---------------------------------------------------------------------------

di _n as text "{bf:Test 4: Parsing dataflows with Mata XML parser}"
di as text "{hline 50}"

tempfile df_xml
di as text "  Downloading dataflows XML (~28KB)..."
capture copy "`base_url'/dataflow/UNICEF?references=none&detail=full" "`df_xml'", public replace

if (_rc == 0) {
    quietly checksum "`df_xml'"
    di as text "  File size: " r(filelen) " bytes"
    
    di as text "  Attempting to parse dataflows..."
    capture noisily _unicefdata_xmlmata_parse, ///
        xmlfile("`df_xml'") ///
        type(dataflows) ///
        outfile("stata/tests/output/mata_dataflows.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/dataflow/UNICEF")
    
    if (_rc == 0) {
        di as result "  ✓ Parsed `r(count)' dataflows using Mata!"
    }
    else {
        di as err "  ✗ Parsing failed with error: " _rc
    }
}
else {
    di as err "  ✗ Download failed"
}

*---------------------------------------------------------------------------
* Test 5: Try to parse large indicator file using Mata
*---------------------------------------------------------------------------

di _n as text "{bf:Test 5: Parsing indicators with Mata XML parser (large file)}"
di as text "{hline 50}"

tempfile ind_xml
di as text "  Downloading indicators XML (~550KB)..."
capture copy "`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest" "`ind_xml'", public replace

if (_rc == 0) {
    quietly checksum "`ind_xml'"
    di as text "  File size: " r(filelen) " bytes"
    
    di as text "  Attempting to parse indicators..."
    capture noisily _unicefdata_xmlmata_parse, ///
        xmlfile("`ind_xml'") ///
        type(indicators) ///
        outfile("stata/tests/output/mata_indicators.yaml") ///
        agency(UNICEF) ///
        source("`base_url'/codelist/UNICEF/CL_UNICEF_INDICATOR/latest")
    
    if (_rc == 0) {
        di as result "  ✓ Parsed `r(count)' indicators using Mata!"
    }
    else {
        di as err "  ✗ Parsing failed with error: " _rc
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
di as text "If Mata XML functions are available, they could be used to:"
di as text "  - Parse large XML files without line-length limitations"
di as text "  - Navigate XML tree structure more naturally"
di as text "  - Handle complex SDMX structures (DSD files)"
di as text "{hline 70}"

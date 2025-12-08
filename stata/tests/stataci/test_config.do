*******************************************************************************
* test_config.do
* Test configuration and environment setup
* Validates that unicefdata package is properly installed and configured
*
* Author: Joao Pedro Azevedo
* Date: December 2025
*******************************************************************************

version 15.0
clear all
set more off

* Get the directory where this file is located
local thisdir "`c(pwd)'"
di as txt "Working directory: `thisdir'"

* Setup paths if not already set by run_tests.do
capture which unicefdata
if _rc {
    adopath ++ "`thisdir'/../../src/u"
    adopath ++ "`thisdir'/../../src/y"
    adopath ++ "`thisdir'"
}

* Load assertion utilities
run "`thisdir'/assert_utils.ado"

di as txt ""
di as txt "TEST: Configuration and Environment"
di as txt "===================================="
di as txt ""

* ----------------------------------------------------------------------------
* Test 1: Check unicefdata command exists
* ----------------------------------------------------------------------------
di as txt "1. Checking unicefdata command availability..."

capture which unicefdata
if _rc {
    di as error "   unicefdata command not found"
    exit 9
}
di as result "   [OK] unicefdata found"

* ----------------------------------------------------------------------------
* Test 2: Check required helper commands
* ----------------------------------------------------------------------------
di as txt "2. Checking helper commands..."

local helpers "_unicefdata_fetch _unicefdata_parse"
foreach h of local helpers {
    capture which `h'
    if _rc == 0 {
        di as result "   [OK] `h' found"
    }
    else {
        di as txt "   [WARN] `h' not found (may be internal)"
    }
}

* ----------------------------------------------------------------------------
* Test 3: Check network connectivity
* ----------------------------------------------------------------------------
di as txt "3. Checking network connectivity to UNICEF SDMX API..."

local test_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/dataflow"
tempfile test_response

capture copy "`test_url'" "`test_response'", replace
if _rc {
    di as error "   Cannot reach UNICEF SDMX API"
    di as error "   URL: `test_url'"
    di as txt "   Note: Network tests will be skipped"
    * Don't fail - allow offline testing
}
else {
    di as result "   [OK] UNICEF SDMX API reachable"
}

* ----------------------------------------------------------------------------
* Test 4: Check output directory
* ----------------------------------------------------------------------------
di as txt "4. Checking output directory..."

* Create output directory if needed
capture mkdir "output"

* Check if directory exists using simple method
local direxists = 0
capture confirm file "output/."
if _rc == 0 {
    local direxists = 1
}
capture confirm file "output\."
if _rc == 0 {
    local direxists = 1
}
* Try with nul file (Windows)
capture confirm file "output\nul"
if _rc == 0 {
    local direxists = 1
}

if `direxists' == 1 {
    di as result "   [OK] output/ directory exists"
}
else {
    * Try alternative - list files in directory
    capture local files : dir "output" files "*"
    if _rc == 0 {
        di as result "   [OK] output/ directory exists"
    }
    else {
        di as error "   [WARN] Could not verify output directory - continuing anyway"
    }
}

* ----------------------------------------------------------------------------
* Test 5: Check logs directory
* ----------------------------------------------------------------------------
di as txt "5. Checking logs directory..."

* Create logs directory if needed
capture mkdir "logs"

* Check if directory exists
local direxists = 0
capture confirm file "logs/."
if _rc == 0 {
    local direxists = 1
}
capture confirm file "logs\."
if _rc == 0 {
    local direxists = 1
}

if `direxists' == 1 {
    di as result "   [OK] logs/ directory exists"
}
else {
    capture local files : dir "logs" files "*"
    if _rc == 0 {
        di as result "   [OK] logs/ directory exists"
    }
    else {
        di as error "   [WARN] Could not verify logs directory - continuing anyway"
    }
}

* ----------------------------------------------------------------------------
* Summary
* ----------------------------------------------------------------------------
di as txt ""
di as result "Configuration tests completed successfully"
di as txt ""

exit 0

/*==============================================================================
    Test New Features in unicefdata v1.3.0
    
    Tests:
    1. Discovery functions (flows, search, indicators, info)
    2. Enhanced output (wide_indicators, addmeta, geo_type)
==============================================================================*/

clear all
set more off

// Set path to the ado files
adopath ++ "C:\GitHub\others\unicefData\stata\src\_"
adopath ++ "C:\GitHub\others\unicefData\stata\src\u"
adopath ++ "C:\GitHub\others\unicefData\stata\src\y"

// Define metadata path for testing
global UNICEF_METAPATH "C:\GitHub\others\unicefData\stata\metadata\vintages\"

di as txt _n "======================================================================"
di as txt "Testing unicefdata v1.3.0 New Features"
di as txt "======================================================================"

/*------------------------------------------------------------------------------
    Test 1: List Dataflows
------------------------------------------------------------------------------*/
di as txt _n "TEST 1: List Dataflows"
di as txt "----------------------------------------"

capture noisily _unicef_list_dataflows, metapath("$UNICEF_METAPATH") verbose detail

di as txt _n "Return values:"
return list

/*------------------------------------------------------------------------------
    Test 2: Search Indicators
------------------------------------------------------------------------------*/
di as txt _n "TEST 2: Search Indicators for 'mortality'"
di as txt "----------------------------------------"

capture noisily _unicef_search_indicators, keyword("mortality") metapath("$UNICEF_METAPATH") limit(10)

di as txt _n "Return values:"
return list

/*------------------------------------------------------------------------------
    Test 3: Search Indicators - nutrition
------------------------------------------------------------------------------*/
di as txt _n "TEST 3: Search Indicators for 'stunting'"
di as txt "----------------------------------------"

capture noisily _unicef_search_indicators, keyword("stunting") metapath("$UNICEF_METAPATH") limit(5)

/*------------------------------------------------------------------------------
    Test 4: List Indicators by Dataflow
------------------------------------------------------------------------------*/
di as txt _n "TEST 4: List Indicators in CME dataflow"
di as txt "----------------------------------------"

capture noisily _unicef_list_indicators, dataflow(CME) metapath("$UNICEF_METAPATH")

di as txt _n "Return values:"
return list

/*------------------------------------------------------------------------------
    Test 5: Indicator Info
------------------------------------------------------------------------------*/
di as txt _n "TEST 5: Indicator Info for CME_MRY0T4"
di as txt "----------------------------------------"

capture noisily _unicef_indicator_info, indicator(CME_MRY0T4) metapath("$UNICEF_METAPATH")

di as txt _n "Return values:"
return list

/*------------------------------------------------------------------------------
    Test 6: Basic Data Fetch (baseline test)
------------------------------------------------------------------------------*/
di as txt _n "TEST 6: Basic Data Fetch"
di as txt "----------------------------------------"

capture noisily unicefdata, indicator(CME_MRY0T4) geo(AFG BGD) year(2020/2022) clear

if _rc == 0 {
    di as txt "Observations: " _N
    describe, short
    list in 1/5, abbrev(12)
}

/*------------------------------------------------------------------------------
    Test 7: Geo Type Classification
------------------------------------------------------------------------------*/
di as txt _n "TEST 7: Geo Type Classification"
di as txt "----------------------------------------"

// Get data for both countries and aggregates
capture noisily unicefdata, indicator(CME_MRY0T4) geo(AFG WLD) year(2022) clear

if _rc == 0 {
    di as txt "Checking geo_type variable:"
    capture confirm variable geo_type
    if _rc == 0 {
        di as txt "geo_type values:"
        tab geo_type
        di _n as txt "Sample by geo_type:"
        list iso3 country geo_type in 1/10, abbrev(15)
    }
    else {
        di as err "geo_type variable not found"
    }
}

/*------------------------------------------------------------------------------
    Summary
------------------------------------------------------------------------------*/
di as txt _n "======================================================================"
di as txt "Test Complete"
di as txt "======================================================================""


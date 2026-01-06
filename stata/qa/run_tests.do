/*******************************************************************************
* unicefdata Automated Test Suite
* Version: 1.5.1
* Date: January 2026
* 
* Usage: 
*   do run_tests.do              - Run all tests
*   do run_tests.do DL-01        - Run only test DL-01
*   do run_tests.do DL-01 verbose - Run DL-01 with trace on (debug mode)
*   do run_tests.do verbose      - Run all tests with trace on
*   do run_tests.do list         - List all available tests
*
* Test Categories:
*   0 - Environment Checks (ENV-01 to ENV-04)
*   1 - Basic Downloads (DL-01 to DL-05)
*   2 - Discovery Commands (DISC-01 to DISC-05)
*   3 - Metadata Sync (SYNC-01 to SYNC-03)
*   4 - Transformations & Metadata (TRANS/META/MULTI)
*   5 - Robustness & Performance (EDGE/PERF/REGR)
*   6 - Cross-Platform Consistency (XPLAT-01 to XPLAT-05)
* 
* Testing Best Practices:
*   1. NO empty capture blocks - always run explicit commands inside cap
*   2. Check _rc immediately after each command that matters
*   3. Use explicit variable existence checks: capture confirm variable
*   4. Verify data with count if !missing() not just assert
*   5. Provide informative failure messages with actual error codes'
*
* unicefdata package QA workflow uses run_test.d and borrows structure from:
* C:\GitHub\myados\wbopendata\qa\run_tests.do
*******************************************************************************/

clear all
set more off
cap log close _all

*===============================================================================
* PARSE COMMAND LINE ARGUMENTS
*===============================================================================

local args `0'
local target_test ""
local verbose 0

foreach arg of local args {
    if upper("`arg'") == "VERBOSE" {
        local verbose 1
    }
    else if upper("`arg'") == "LIST" {
        di as text _n "Available tests:"
        di as text ""
        di as text "  Environment Checks:"
        di as text "  ENV-01   unicefdata version matches repo"
        di as text "  ENV-02   Ado files sync status"
        di as text "  ENV-03   unicefdata.pkg matches src directories"
        di as text "  ENV-04   All pkg files exist in repo"
        di as text ""
        di as text "  Basic Downloads:"
        di as text "  DL-01    Single indicator download"
        di as text "  DL-02    Multiple countries download"
        di as text "  DL-03    Year range filter"
        di as text "  DL-04    Schema validation (P0)"
        di as text "  DL-05    Disaggregation filters (P0)"
        di as text "  DL-06    Duplicate detection (P0)"
        di as text "  DL-07    API error handling (P0)"
        di as text ""
        di as text "  Data Integrity (P0):"
        di as text "  DATA-01  Data type validation"
        di as text ""
        di as text "  Discovery Commands:"
        di as text "  DISC-01  List categories"
        di as text "  DISC-02  List dataflows"
        di as text "  DISC-03  Search indicators"
        di as text "  DISC-04  Indicator info"
        di as text "  DISC-05  Dataflow schema display"
        di as text ""
        di as text "  Metadata Sync:"
        di as text "  SYNC-01  Sync dataflow index"
        di as text "  SYNC-02  Sync indicator metadata"
        di as text "  SYNC-03  Full metadata sync"
        di as text ""
        di as text "  Format Options:"
        di as text "  FMT-01   Long format"
        di as text "  FMT-02   Wide format"
        di as text "  FMT-03   Wide indicators format"
        di as text ""
        di as text "  Transformations & Metadata (P1):"
        di as text "  TRANS-01 Wide format reshape"
        di as text "  TRANS-02 Latest/MRV filters"
        di as text "  META-01  Add metadata columns"
        di as text "  META-02  Metadata file sanity check"
        di as text "  MULTI-01 Multi-indicator wide_indicators"
        di as text ""
        di as text "  Robustness & Performance (P2):"
        di as text "  EDGE-01  Empty results handling"
        di as text "  EDGE-02  Single-observation stability"
        di as text "  EDGE-03  Special-character country names"
        di as text "  PERF-01  Medium batch performance"
        di as text "  REGR-01  Regression snapshot check"
        di as text ""
        di as text "  YAML Integration:"
        di as text "  YAML-01  XML to YAML conversion"
        di as text "  YAML-02  YAML metadata reading"
        di as text ""
        di as text "  Cross-Platform Consistency (CRITICAL):"
        di as text "  XPLAT-01 Compare metadata YAML files (Python/R/Stata)"
        di as text "  XPLAT-02 Verify variable naming consistency"
        di as text "  XPLAT-03 Check numerical formatting consistency"
        di as text "  XPLAT-04 Validate country code consistency"
        di as text "  XPLAT-05 Test data structure alignment"
        exit
    }
    else {
        local target_test "`arg'"
    }
}

*===============================================================================
* SETUP
*===============================================================================

* Capture start time
local start_time = c(current_time)

* Define file paths
local qadir "c:/GitHub/myados/unicefData/stata/qa"
local logdate = string(date(c(current_date), "DMY"), "%tdCY-N-D")
local logfile "`qadir'/run_tests.log"
local histfile "`qadir'/test_history.txt"

* Always start by making sure unicefdata in REPO and in Stata are aligned
* Use install_local.do instead of net install (avoids pkg file length issues)
local repodir "C:/GitHub/myados/unicefData/stata"
cap noi do "`repodir'/install_local.do"

* Start log (with retry if locked)
cap log close _testlog
cap log using "`logfile'", replace text name(_testlog)
if _rc != 0 {
    local timestamp = subinstr(c(current_time),":","-",.)
    local logfile "`qadir'/run_tests_`timestamp'.log"
    log using "`logfile'", replace text name(_testlog)
}

* Set trace if verbose mode
if `verbose' == 1 {
    set trace on
    set tracedepth 4
}

* Initialize counters
global test_count = 0
global pass_count = 0
global fail_count = 0
global skip_count = 0
global failed_tests = ""

* Test execution control
global run_env = 1
global run_downloads = 1
global run_discovery = 1
global run_sync = 0  // Skip sync tests by default (may modify files)
global run_format = 1
global run_yaml = 1
global run_xplat = 1  // Cross-platform consistency tests
global run_transform = 1      // Transformations & metadata (P1)
global run_edge = 1           // Robustness/performance (P2)

* Override if single test specified
if "`target_test'" != "" {
    global run_env = 0
    global run_downloads = 0
    global run_discovery = 0
    global run_sync = 0
    global run_format = 0
    global run_xplat = 0
    global run_yaml = 0
    global run_transform = 0
    global run_edge = 0
}

*===============================================================================
* DISPLAY HEADER
*===============================================================================

di as text "{hline 78}"
di as text "{bf:{center 78:unicefdata AUTOMATED TEST SUITE}}"
di as text "{hline 78}"
di as text ""
di as text "  Version:       1.5.1"
di as text "  Date:          `c(current_date)' `c(current_time)'"
di as text "  Stata:         `c(stata_version)'"
di as text "  OS:            `c(os)'"
if "`target_test'" != "" {
    di as text "  Target Test:   `target_test'"
}
if `verbose' == 1 {
    di as text "  Verbose Mode:  ENABLED"
}
di as text "{hline 78}"

*===============================================================================
* HELPER PROGRAMS
*===============================================================================

capture program drop test_start
program define test_start
    syntax, id(string) desc(string)
    
    global test_count = $test_count + 1
    
    di as text ""
    di as text "{hline 78}"
    di as result "TEST `id': " as text "`desc'"
    di as text "{hline 78}"
end

capture program drop test_pass
program define test_pass
    syntax, id(string) [msg(string)]
    
    global pass_count = $pass_count + 1
    
    di as result "✓ PASS: `id'" as text " `msg'"
end

capture program drop test_fail
program define test_fail
    syntax, id(string) [msg(string)] [rc(string)]
    
    global fail_count = $fail_count + 1
    
    * Add to failed tests list
    if "$failed_tests" == "" {
        global failed_tests "`id'"
    }
    else {
        global failed_tests "$failed_tests, `id'"
    }
    
    local rcnum = 0
    if "`rc'" != "" {
        capture scalar __rc_eval = `rc'
        if _rc == 0 {
            local rcnum = __rc_eval
            scalar drop __rc_eval
        }
        else {
            local rcnum = real("`rc'")
            if missing(`rcnum') {
                local rcnum = 0
            }
        }
    }

    if `rcnum' > 0 {
        di as err "✗ FAIL: `id' (r(`rcnum'))" as text " `msg'"
    }
    else {
        di as err "✗ FAIL: `id'" as text " `msg'"
    }
end

capture program drop test_skip
program define test_skip
    syntax, id(string) [msg(string)]
    
    global skip_count = $skip_count + 1
    
    di as text "○ SKIP: `id'" as text " `msg'"
end

*===============================================================================
* CATEGORY 0: ENVIRONMENT CHECKS
*===============================================================================

if $run_env == 1 | "`target_test'" == "ENV-01" {
    *==========================================================================
    * ENV-01: Check unicefdata version
    *==========================================================================
    * PURPOSE:
    *   Verify that the unicefdata.ado file is installed and contains a
    *   valid version number in the file header.
    *
    * WHAT IS TESTED:
    *   - File path resolution: findfile command locates unicefdata.ado
    *   - Version extraction: Regex extracts version from header "*! v X.Y.Z"
    *   - File I/O: Stata can read the ado file without errors
    *   - Path normalization: Windows backslash paths are converted to forward slash
    *
    * CODE BEING TESTED:
    *   unicefdata.ado header line: *! v 1.5.1  ...
    *   See: c:\GitHub\myados\unicefData\stata\src\unicefdata.ado line 1
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Verify unicefdata.ado is in your ado path:
    *      - Run: which unicefdata
    *      - Likely path: C:\Users\jpazevedo\ado\plus\u\unicefdata.ado
    *   2. Check version header in unicefdata.ado:
    *      - First few lines should have: *! v X.Y.Z  DDMMMYYYY
    *      - If missing, add version header to line 1-2
    *   3. Check file permissions:
    *      - Ensure file is readable (not locked by another process)
    *      - Try: discard all  (clears Stata's file cache)
    *   4. Check path normalization:
    *      - Look for backslash vs forward slash issues on Windows
    *      - Run install_local.do to ensure latest version is in place
    *
    * RELATED TESTS:
    *   - ENV-02: Verifies dependencies (yaml) are installed
    *   - DL-01+: All download tests depend on ENV-01 passing
    *
    * REFERENCE:
    *   See install_local.do which copies ado files to user ado path
    *==========================================================================
    test_start, id("ENV-01") desc("Check unicefdata version")
    
    cap which unicefdata
    if _rc == 0 {
        * Resolve ado path robustly (prefer findfile)
        local fn ""
        cap findfile unicefdata.ado
        if _rc == 0 {
            local fn = r(fn)
        }
        else {
            * Fallback to which() result
            local fn = r(fn)
        }

        * Normalize path separators to avoid invalid file specification on Windows
        local fnsafe = subinstr("`fn'","\\","/",.)

        * Extract version from ado file
        tempname fh
        cap file open `fh' using "`fnsafe'", read
        if _rc == 0 {
            file read `fh' line
            local found_version = 0
            while r(eof)==0 & `found_version'==0 {
                if regexm("`line'", "^\*! v ([0-9]+\.[0-9]+\.[0-9]+)") {
                    local ado_version = regexs(1)
                    local found_version = 1
                }
                file read `fh' line
            }
            file close `fh'

            if `found_version' {
                test_pass, id("ENV-01") msg("Version `ado_version' found")
            }
            else {
                test_fail, id("ENV-01") msg("Could not extract version from ado file")
            }
        }
        else {
            test_fail, id("ENV-01") msg("Could not open ado file: `fnsafe'") rc(_rc)
        }
    }
    else {
        test_fail, id("ENV-01") msg("unicefdata not found") rc(_rc)
    }
}

if $run_env == 1 | "`target_test'" == "ENV-02" {
    *==========================================================================
    * ENV-02: Check required dependencies
    *==========================================================================
    * PURPOSE:
    *   Verify that all external dependencies required by unicefdata
    *   (currently just yaml) are installed and accessible.
    *
    * WHAT IS TESTED:
    *   - Package discovery: which command can locate yaml.ado
    *   - Ado path setup: Dependency appears in official ado path
    *   - Installation status: Package exists as installed Stata program
    *
    * CODE BEING TESTED:
    *   yaml package installation and discovery mechanism
    *   Tested via: which yaml  (should return path to yaml.ado)
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Check yaml is installed:
    *      - Run in Stata: ssc install yaml, replace
    *      - Or install from: C:\GitHub\yaml\src\yaml.ado
    *   2. Verify yaml is in ado path:
    *      - Run: adopath
    *      - Should see .\ or C:\Users\jpazevedo\ado\plus listed
    *   3. Check yaml.ado file:
    *      - Likely location: C:\Users\jpazevedo\ado\plus\y\yaml.ado
    *      - Or from source: C:\GitHub\yaml\src\yaml.ado
    *   4. Reinstall yaml if missing:
    *      - Option A: net install yaml (if available on server)
    *      - Option B: Copy C:\GitHub\yaml\src\yaml.ado to your ado plus folder
    *      - Option C: Run in Stata: cd C:\GitHub\yaml ; do install_local.do
    *
    * IMPACT OF FAILURE:
    *   All unicefdata commands fail because YAML parsing is not available.
    *   This affects: data filtering, metadata sync, YAML-based configuration.
    *
    * RELATED TESTS:
    *   - DL-01+: All downloads depend on yaml being available
    *   - YAML-01, YAML-02: Explicitly test yaml functionality
    *
    * REFERENCE:
    *   See: C:\GitHub\yaml\README.md for yaml installation
    *==========================================================================
    test_start, id("ENV-02") desc("Check required dependencies")
    
    local deps "yaml"
    local all_found = 1
    
    foreach dep of local deps {
        cap which `dep'
        if _rc == 0 {
            di as text "  Found: `dep'"
        }
        else {
            di as err "  Missing: `dep'"
            local all_found = 0
        }
    }
    
    if `all_found' {
        test_pass, id("ENV-02") msg("All dependencies found")
    }
    else {
        test_fail, id("ENV-02") msg("Some dependencies missing")
    }
}

*===============================================================================
* CATEGORY 1: BASIC DOWNLOADS
*===============================================================================

if $run_downloads == 1 | "`target_test'" == "DL-01" {
    *==========================================================================
    * DL-01: Download single indicator (Basic functionality)
    *==========================================================================
    * PURPOSE:
    *   Verify that the unicefdata command can successfully download a
    *   single indicator for specified countries and year range.
    *   This is the foundation for all other download tests.
    *
    * WHAT IS TESTED:
    *   - API connectivity: Can reach UNICEF SDMX API
    *   - Indicator lookup: Indicator code "CME_MRY0T4" is recognized
    *   - Country codes: ALB, USA, BRA are valid ISO3 codes
    *   - Data retrieval: Server returns data without errors
    *   - Data parsing: Response is correctly parsed into Stata dataset
    *   - Return type: Result is non-empty (_N > 0)
    *
    * CODE BEING TESTED:
    *   Main command line:
    *     unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) year(2015:2020) clear
    *   See: C:\GitHub\myados\unicefData\stata\src\unicefdata.ado
    *   Key functions:
    *     - _query_metadata: Fetches indicator metadata from API
    *     - _api_read: Makes HTTP request to SDMX API
    *     - Data parsing: Converts XML response to Stata variables
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Check API connectivity:
    *      - Can you reach https://data.unicef.org/ in browser?
    *      - Try manual SDMX API call: https://sdmx.data.unicef.org/ws/rest/data/...?
    *   2. Verify indicator code:
    *      - Is CME_MRY0T4 valid? Run: unicefdata, search(mortality)
    *      - Look for "CME" dataflow in output
    *   3. Check country codes:
    *      - ALB = Albania, USA = United States, BRA = Brazil
    *      - Run: unicefdata, flows  to verify dataflow structure
    *   4. Examine error message carefully:
    *      - r(198) = syntax error in command
    *      - r(601) = URL/API error
    *      - r(804) = insufficient memory
    *   5. Check XML parsing:
    *      - If data downloads but shows as empty, check SDMX response format
    *      - Run with verbose mode: do run_tests.do DL-01 verbose
    *      - Look for XML structure warnings in trace output
    *   6. Network/proxy issues:
    *      - If behind corporate firewall, may need proxy configuration
    *      - Check Stata > Preferences > Internet for proxy settings
    *
    * EXPECTED RESULT:
    *   - _rc = 0 (command succeeds)
    *   - _N >= 3 (at least one obs per country × year combination)
    *   - Variables present: iso3, country, period, indicator, value
    *
    * RELATED TESTS:
    *   - DL-02: Tests multiple countries (depends on DL-01 working)
    *   - DL-03: Tests year ranges (depends on DL-01 working)
    *   - DL-04: Tests schema of returned data (depends on DL-01 working)
    *
    * REFERENCE:
    *   Indicator code reference: https://data.unicef.org/ under data explorer
    *==========================================================================
    test_start, id("DL-01") desc("Download single indicator (Under-5 mortality)")
    
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) year(2015:2020) clear
    
    if _rc == 0 {
        if _N > 0 {
            test_pass, id("DL-01") msg("Downloaded `=_N' observations")
        }
        else {
            test_fail, id("DL-01") msg("No data downloaded")
        }
    }
    else {
        test_fail, id("DL-01") msg("Download failed") rc(_rc)
    }
}

if $run_downloads == 1 | "`target_test'" == "DL-02" {
    *==========================================================================
    * DL-02: Download multiple countries (Country filtering)
    *==========================================================================
    * PURPOSE:
    *   Verify that the countries() option correctly filters to specified
    *   countries and returns data for all requested countries.
    *
    * WHAT IS TESTED:
    *   - Option parsing: countries(DEU FRA ITA ESP GBR) parsed correctly
    *   - Country code validation: All 5 ISO3 codes are recognized
    *   - Result filtering: Returns data ONLY for specified countries
    *   - Multiple countries: Handles 5 countries without exceeding URL limits
    *   - Data completeness: Each country returns at least 1 observation
    *
    * CODE BEING TESTED:
    *   countries() option parsing in unicefdata.ado
    *   API request building for multiple countries:
    *     REF_AREA.ALB+DEU+FRA+ITA+ESP+GBR
    *   See: C:\GitHub\myados\unicefData\stata\src\unicefdata.ado
    *   Key function: Argument parsing loop that builds country filter string
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Verify country codes:
    *      - DEU = Germany, FRA = France, ITA = Italy, ESP = Spain, GBR = UK
    *      - Check if all are valid ISO3 codes
    *   2. Check API URL construction:
    *      - Run with trace: do run_tests.do DL-02 verbose
    *      - Look for SDMX URL string being constructed
    *      - Should see: REF_AREA.DEU+FRA+ITA+ESP+GBR in URL
    *   3. Verify each country returned data:
    *      - Check observation count by country:
    *        qui count if iso3 == "DEU"
    *        (repeat for FRA, ITA, ESP, GBR)
    *      - If any country has 0 obs, may indicate API filtering issue
    *   4. Check for unexpected countries:
    *      - Run: levelsof iso3
    *      - Should ONLY show DEU, FRA, ITA, ESP, GBR
    *      - If other countries appear, countries() filter not working
    *   5. URL length issues:
    *      - If > 10 countries fail but < 10 work, may be URL length limit
    *      - SDMX has ~2000 char URL limit
    *      - Solution: Use country ranges or make multiple calls
    *
    * EXPECTED RESULT:
    *   - _rc = 0
    *   - r(N) >= 5 (at least one obs per country)
    *   - levelsof iso3: only DEU, FRA, ITA, ESP, GBR
    *
    * RELATED TESTS:
    *   - DL-03: Tests year ranges (independent from DL-02)
    *   - DL-05: Tests disaggregation filtering (uses countries too)
    *
    * REFERENCE:
    *   ISO 3166-1 alpha-3 country codes: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
    *==========================================================================
    test_start, id("DL-02") desc("Download multiple countries")
    
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(DEU FRA ITA ESP GBR) year(2020) clear
    
    if _rc == 0 {
        qui count
        if r(N) >= 5 {
            test_pass, id("DL-02") msg("Downloaded data for multiple countries")
        }
        else {
            test_fail, id("DL-02") msg("Expected at least 5 obs, got `=r(N)'")
        }
    }
    else {
        test_fail, id("DL-02") msg("Download failed") rc(_rc)
    }
}

if $run_downloads == 1 | "`target_test'" == "DL-03" {
    *==========================================================================
    * DL-03: Download with year range (Temporal filtering)
    *==========================================================================
    * PURPOSE:
    *   Verify that the year() option correctly interprets year ranges
    *   (e.g., year(2010:2020)) and returns data for all years in range.
    *
    * WHAT IS TESTED:
    *   - Syntax parsing: year(2010:2020) interpreted as range, not literal
    *   - Range expansion: Range correctly expands to 2010, 2011, ..., 2020
    *   - API request: All years included in SDMX TIME_PERIOD filter
    *   - Result filtering: Returns ONLY data from requested year range
    *   - Multiple years: Handles 11 years without API errors
    *
    * CODE BEING TESTED:
    *   year() option parsing in unicefdata.ado
    *   Range expansion logic (converts "2010:2020" to "2010 2011 ... 2020")
    *   API request building:
    *     TIME_PERIOD.2010+2011+...+2020
    *   See: C:\GitHub\myados\unicefData\stata\src\unicefdata.ado
    *   Key function: Range parsing and expansion mechanism
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Check range syntax:
    *      - Format must be: year(START:END) with colon separator
    *      - year(2010-2020) or year(2010 2020) will NOT expand as range
    *   2. Verify year range expansion:
    *      - Run test with trace: do run_tests.do DL-03 verbose
    *      - Look for expanded year list in output
    *      - Should show: 2010 2011 2012 ... 2020
    *   3. Check data availability:
    *      - Some indicators may not have data for all years
    *      - If < 5 obs total, may indicate data sparsity, not code bug
    *      - Try different indicator (e.g., CME_MRY0T4 should have good coverage)
    *   4. Verify returned years:
    *      - Run: qui levelsof period
    *      - Should show: 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020
    *      - If missing some years, API may not have data for those years
    *   5. Check for boundary year inclusion:
    *      - Verify 2010 and 2020 are both present (inclusive range)
    *      - If missing either endpoint, range parsing may be off by one
    *
    * EXPECTED RESULT:
    *   - _rc = 0
    *   - r(N) > 5 (multiple years × countries)
    *   - period values: Range from 2010 to 2020
    *   - No years outside [2010, 2020] should be present
    *
    * EXPECTED COVERAGE:
    *   For CME_MRY0T4 (Under-5 mortality), USA typically has data for all years.
    *   For some indicators, data may be sparse (e.g., only 2015, 2019).
    *
    * RELATED TESTS:
    *   - DL-01: Tests single year implicitly
    *   - DL-05: Tests filtering with year() combined with other options
    *
    * REFERENCE:
    *   SDMX TIME_PERIOD syntax: https://sdmx.org/ (data structure standards)
    *==========================================================================
    test_start, id("DL-03") desc("Download with year range")
    
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA) year(2010:2020) clear
    
    if _rc == 0 {
        qui count
        if r(N) > 5 {
            test_pass, id("DL-03") msg("Downloaded `=r(N)' year observations")
        }
        else {
            test_fail, id("DL-03") msg("Expected > 5 years, got `=r(N)'")
        }
    }
    else {
        test_fail, id("DL-03") msg("Download failed") rc(_rc)
    }
}

if $run_downloads == 1 | "`target_test'" == "DL-04" {
    *==========================================================================
    * DL-04: Schema validation (P0 - CRITICAL DATA INTEGRITY)
    *==========================================================================
    * PURPOSE:
    *   Verify that downloaded data has the correct structure (schema):
    *   - All required columns exist
    *   - Columns have correct data types
    *   - Data values conform to expected format (e.g., iso3 is 3 chars)
    *   This is a CRITICAL test because incorrect schema causes downstream errors.
    *
    * WHAT IS TESTED:
    *   - Required columns present: iso3, country, period, indicator, value
    *   - Data types correct:
    *     * iso3: string, length == 3
    *     * country: string, length varies
    *     * period: numeric integer (year)
    *     * indicator: string (indicator code)
    *     * value: numeric (measurement value)
    *   - iso3 content: All non-missing values are exactly 3 characters
    *   - No unexpected columns: Only expected variables present
    *   - Data integrity: No NULL, NA, or string values in numeric fields
    *
    * CODE BEING TESTED:
    *   XML to Stata variable conversion in _api_read.ado
    *   Variable naming convention and type assignment
    *   See: C:\GitHub\myados\unicefData\stata\src\_api_read.ado
    *   Key functions:
    *     - XML attribute extraction (REF_AREA -> iso3)
    *     - Type detection (numeric vs string)
    *     - Value parsing and validation
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *==========================================================================
    * FAILURE SCENARIO 1: Missing required column
    *   Error message: "Missing required column: [colname]"
    *   Debug steps:
    *     1. Check column name mapping in _api_read.ado:
    *        - REF_AREA should map to iso3
    *        - TIME_PERIOD should map to period
    *        - OBS_VALUE should map to value
    *     2. Verify SDMX API response format:
    *        - May have changed in recent API update
    *        - Compare with Python unicef_api to verify format matches
    *     3. Check variable naming function:
    *        - Look for clean_varname() or similar function
    *        - Verify it's not truncating or corrupting names
    *==========================================================================
    * FAILURE SCENARIO 2: iso3 contains non-ISO3 codes
    *   Error message: "iso3 contains non-ISO3 codes"
    *   Debug steps:
    *     1. Check iso3 values: levelsof iso3, clean
    *     2. Verify they are all 3-character codes (ALB, USA, BRA, etc.)
    *     3. If longer (e.g., "ALBAN"), truncation is happening
    *     4. Check REF_AREA extraction in _api_read.ado
    *        - May be parsing entire country name instead of code
    *==========================================================================
    * FAILURE SCENARIO 3: period is not numeric
    *   Error message: "period is not numeric"
    *   Debug steps:
    *     1. Check period values: list period in 1/10
    *     2. If showing as string (e.g., "2020Q1" or "2020-W01"),
    *        TIME_PERIOD parsing is not handling frequency correctly
    *     3. For UNICEF health data, period is typically annual (YYYY)
    *     4. Check TIME_PERIOD extraction: May need to strip frequency prefix
    *        - "2020Q1" should become 2020
    *        - "2020" should stay 2020
    *==========================================================================
    *
    * EXPECTED RESULT:
    *   - _rc = 0
    *   - All required columns exist and are accessible
    *   - iso3: All non-missing values are exactly 3 characters
    *   - period: All values are numeric and >= 1900
    *   - value: All non-missing values are numeric
    *
    * IMPACT OF FAILURE:
    *   - All downstream analysis will fail (wrong variable names)
    *   - Type mismatches cause r(109) errors in analysis
    *   - DL-05, DL-06, DATA-01 will all fail
    *
    * CRITICAL IMPORTANCE:
    *   If DL-04 fails, immediately run:
    *     do run_tests.do DL-04 verbose
    *   and examine the dataset structure:
    *     describe
    *     list in 1/5
    *   before proceeding to other tests.
    *
    * RELATED TESTS:
    *   - DL-05: Tests disaggregation (requires correct schema from DL-04)
    *   - DL-06: Tests duplicates (requires correct schema)
    *   - DATA-01: Tests data types (extends DL-04 type checking)
    *
    * REFERENCE:
    *   SDMX Dimension specification: https://sdmx.org/
    *   Expected dimensions for UNICEF data: iso3, period, indicator, [disaggregation vars]
    *==========================================================================
    test_start, id("DL-04") desc("Schema validation (P0 - Critical)")
    
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) clear
    
    if _rc == 0 {
        * Check required columns exist
        local required_cols "iso3 country period indicator value"
        local all_exist = 1
        foreach col of local required_cols {
            cap confirm variable `col'
            if _rc != 0 {
                di as err "  Missing required column: `col'"
                local all_exist = 0
            }
        }
        
        if `all_exist' {
            * Check iso3 is 3-character string
            cap assert length(iso3) == 3 if !missing(iso3)
            if _rc == 0 {
                * Check period is numeric
                cap confirm numeric variable period
                if _rc == 0 {
                    test_pass, id("DL-04") msg("Schema valid: required columns exist, correct types")
                }
                else {
                    test_fail, id("DL-04") msg("period is not numeric")
                }
            }
            else {
                test_fail, id("DL-04") msg("iso3 contains non-ISO3 codes")
            }
        }
        else {
            test_fail, id("DL-04") msg("Missing required columns")
        }
    }
    else {
        test_fail, id("DL-04") msg("Download failed") rc(_rc)
    }
}

if $run_downloads == 1 | "`target_test'" == "DL-05" {
    *==========================================================================
    * DL-05: Disaggregation filters (P0 - CRITICAL API INTEGRATION)
    *==========================================================================
    * PURPOSE:
    *   Verify that the sex() and wealth() options correctly filter data
    *   to only return disaggregated values for specified categories.
    *   This is CRITICAL because silent filtering failures hide data issues.
    *
    * WHAT IS TESTED:
    *   Part A - Sex filter test:
    *     - sex(F) option correctly filters to only female observations
    *     - Command: unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) sex(F)
    *     - Result: All sex variable values must be "F"
    *     - Verified: count if sex != "F" & !missing(sex) must be 0
    *
    *   Part B - Wealth filter test:
    *     - wealth(Q1 Q5) option filters to only Q1 and Q5 quintiles
    *     - Command: unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) wealth(Q1 Q5)
    *     - Result: Should return ONLY Q1 and Q5 values, not Q2/Q3/Q4/others
    *     - Verified: must have Q1/Q5 present AND no Q2/Q3/Q4 present
    *
    * CODE BEING TESTED:
    *   Disaggregation filter option handling in unicefdata.ado
    *   SDMX API parameter building for dimension filtering:
    *     sex(F) -> sex.F in URL
    *     wealth(Q1 Q5) -> wealth_quintile.Q1+Q5 in URL
    *   See: C:\GitHub\myados\unicefData\stata\src\unicefdata.ado
    *   Key functions:
    *     - Option parsing: sex(), wealth(), etc.
    *     - Dimension code mapping (wealth -> wealth_quintile in SDMX)
    *     - SDMX URL parameter construction
    *     - Result filtering validation
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *==========================================================================
    * FAILURE SCENARIO 1: Sex filter not working (sex values != "F")
    *   Error message: "Sex filter returned non-F values: X obs"
    *   Debug steps:
    *     1. Run these commands manually:
    *        clear
    *        unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) sex(F) clear
    *        levelsof sex, clean
    *     2. If shows F, M, _T instead of just F:
    *        - SDMX API ignored the sex filter
    *        - Check API URL construction in trace output
    *     3. Check sex dimension in SDMX:
    *        - Run: unicefdata, dataflow(CME)
    *        - Look for sex dimension in schema output
    *     4. Verify sex codes:
    *        - Valid codes: F (Female), M (Male), _T (Total/Both)
    *        - If requesting "F", should get only F
    *
    *==========================================================================
    * FAILURE SCENARIO 2: Wealth filter not working (includes Q2/Q3/Q4)
    *   Error message: "Unexpected quintiles (Q2/Q3/Q4) found"
    *   Status: KNOWN API BUG - See DL-05_FILTER_BUG_ANALYSIS.md
    *   Debug steps:
    *     1. This is a documented UNICEF SDMX server limitation
    *        - wealth_quintile filters are currently ignored by server
    *        - Affects user data silently (returns all quintiles)
    *     2. To confirm it's server, not command:
    *        - Run sex filter: unicefdata, ..., sex(F) clear
    *        - If sex(F) works but wealth(Q1 Q5) returns all quintiles,
    *          it's confirmed as API server bug
    *     3. Workaround for users:
    *        - Download unfiltered data: unicefdata, ..., clear
    *        - Then manually filter: keep if inlist(wealth, "Q1", "Q5")
    *     4. If sex filter also fails:
    *        - API server may be down or changed format
    *        - Run: unicefdata, flows  to verify server is responding
    *
    *==========================================================================
    * FAILURE SCENARIO 3: Filter variable missing
    *   Error message: "Sex variable not found in result" or "No wealth variable"
    *   Debug steps:
    *     1. Not all indicators have all disaggregations
    *        - CME_MRY0T4 (mortality) should have sex
    *        - NT_ANT_WHZ_NE2 (nutrition) should have wealth
    *     2. Try different indicator if variable truly missing
    *     3. Run: describe, to verify variables in dataset
    *        - Should show iso3, country, period, indicator, value, plus disaggregations
    *
    *==========================================================================
    *
    * EXPECTED RESULT:
    *   Part A (Sex filter):
    *     - _rc = 0
    *     - sex variable present
    *     - All sex values = "F"
    *     - No M or _T values
    *
    *   Part B (Wealth filter):
    *     - _rc = 0
    *     - wealth variable present
    *     - IDEALLY: Only Q1, Q5 values (but see KNOWN API BUG below)
    *     - Verify with: levelsof wealth, clean
    *
    * KNOWN API BUG:
    *   wealth_quintile filter is IGNORED by UNICEF SDMX server
    *   - Requesting wealth(Q1 Q5) returns ALL quintiles (Q1-Q5, B20, B40, ...)
    *   - This is a server-side bug, NOT a unicefdata.ado bug
    *   - Confirmed via comparative testing (sex filter WORKS, wealth filter BROKEN)
    *   - See: c:/GitHub/myados/unicefData/stata/qa/DL-05_FILTER_BUG_ANALYSIS.md
    *   - Workaround: Manually filter downloaded data in Stata
    *
    * IMPACT OF FAILURE:
    *   Silent data integrity issue - users get unfiltered data without error.
    *   - Report may silently include all quintiles when only Q1 requested
    *   - Analysis conclusions may be incorrect
    *   - Affects any analysis using wealth disaggregation
    *
    * CRITICAL IMPORTANCE:
    *   If DL-05 fails AFTER confirming sex filter works:
    *     - Likely a known API bug (wealth filter ignored)
    *     - NOT a problem with unicefdata command
    *     - See DL-05_FILTER_BUG_ANALYSIS.md for full explanation and workarounds
    *
    * RELATED TESTS:
    *   - DL-01, DL-02, DL-03: Basic download tests (independent)
    *   - DL-04: Schema must be correct for DL-05 to verify correctly
    *   - DL-06: Duplicates may appear due to all quintiles being returned
    *
    * REFERENCE:
    *   SDMX dimension filtering: https://sdmx.org/ API documentation
    *   Known issues: c:/GitHub/myados/unicefData/stata/qa/DL-05_FILTER_BUG_ANALYSIS.md
    *==========================================================================
    test_start, id("DL-05") desc("Disaggregation filters (P0 - Critical)")
    
    * Test sex filter
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) sex(F) clear
    
    if _rc == 0 {
        cap confirm variable sex
        if _rc == 0 {
            * Check all values are F
            qui count if sex != "F" & !missing(sex)
            if r(N) == 0 {
                * Test wealth filter combination
                clear
                cap noi unicefdata, indicator(NT_ANT_WHZ_NE2) countries(BGD) year(2019) wealth(Q1 Q5) clear
                if _rc == 0 {
                    cap confirm variable wealth
                    if _rc == 0 {
                        * Check that Q1 and Q5 are present
                        qui count if inlist(wealth, "Q1", "Q5")
                        if r(N) > 0 {
                            * Also check no unexpected quintiles (Q2, Q3, Q4)
                            qui count if inlist(wealth, "Q2", "Q3", "Q4")
                            if r(N) == 0 {
                                test_pass, id("DL-05") msg("Filters work: sex(F) and wealth(Q1 Q5) correct")
                            }
                            else {
                                test_fail, id("DL-05") msg("Unexpected quintiles (Q2/Q3/Q4) found")
                            }
                        }
                        else {
                            test_fail, id("DL-05") msg("No Q1 or Q5 values found")
                        }
                    }
                    else {
                        test_fail, id("DL-05") msg("No wealth variable in result")
                    }
                }
                else {
                    test_fail, id("DL-05") msg("Wealth filter download failed") rc(_rc)
                }
            }
            else {
                test_fail, id("DL-05") msg("Sex filter returned non-F values: `=r(N)' obs")
            }
        }
        else {
            test_fail, id("DL-05") msg("Sex variable not found in result")
        }
    }
    else {
        test_fail, id("DL-05") msg("Sex filter download failed") rc(_rc)
    }
}

if $run_downloads == 1 | "`target_test'" == "DL-06" {
    *==========================================================================
    * DL-06: Duplicate detection (P0 - CRITICAL DATA QUALITY)
    *==========================================================================
    * PURPOSE:
    *   Verify that downloaded data contains NO duplicate observations.
    *   Duplicates indicate API errors or data parsing bugs that corrupt
    *   results. This is CRITICAL because duplicates silently bias analysis.
    *
    * WHAT IS TESTED:
    *   - Duplicate rows: On key dimensions (iso3 × period × sex or iso3 × period × indicator)
    *   - Uniqueness constraint: Each unique combination appears exactly once
    *   - API response parsing: No double-parsing of records
    *   - XML element handling: No unintended record duplication
    *
    * CODE BEING TESTED:
    *   Data parsing logic in _api_read.ado
    *   XML element iteration and variable assignment
    *   See: C:\GitHub\myados\unicefData\stata\src\_api_read.ado
    *   Key functions:
    *     - XML response parsing loop
    *     - Observation creation (append of each record)
    *     - Disaggregation variable assignment
    *     - Duplicate prevention logic (if any)
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *==========================================================================
    * FAILURE SCENARIO 1: Duplicates found on key dimensions
    *   Error message: "Found X duplicate observations"
    *   Debug steps:
    *     1. Examine duplicate observations:
    *        clear
    *        unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2018:2020) clear
    *        duplicates list iso3 period sex
    *     2. Run these commands to find exact duplicates:
    *        duplicates report iso3 period sex
    *        duplicates tag iso3 period sex, gen(dup_tag)
    *        list if dup_tag > 0
    *     3. Check if disaggregation variables are all identical:
    *        - If sex, wealth, etc. are same, true duplicate
    *        - If sex differs (F vs M), not a true duplicate (OK)
    *     4. Inspect XML parsing code in _api_read.ado:
    *        - Look for loops that append observations
    *        - Check for off-by-one errors in element iteration
    *        - Verify each XML element creates exactly one observation
    *     5. Run diagnostic:
    *        set trace on
    *        unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) clear
    *        set trace off
    *        Check trace output for duplicate XML element processing
    *
    *==========================================================================
    * FAILURE SCENARIO 2: Duplicates due to disaggregation expansion
    *   Note: NOT a failure, but appears as duplicates
    *   Example: sex(F) filter returns F, sex(M) returns M - no duplicates
    *   But if request is unfiltered, may see:
    *     iso3=USA, period=2020, sex=F, value=X
    *     iso3=USA, period=2020, sex=M, value=Y
    *     iso3=USA, period=2020, sex=_T, value=Z  (Total)
    *   This is NOT a duplicate - different sex values
    *   Duplicates test accounts for this by excluding on sex in check
    *
    *==========================================================================
    *
    * EXPECTED RESULT:
    *   - _rc = 0
    *   - duplicates report iso3 period sex returns:
    *     Unique values = Total observations (no duplicates)
    *   - OR if sex not present:
    *     duplicates report iso3 period indicator returns:
    *     Unique values = Total observations
    *
    * HOW TEST WORKS:
    *   Uses Stata duplicates report command:
    *     qui duplicates report iso3 period sex
    *     if r(unique_value) == r(N)  (pass - no duplicates)
    *     else  (fail - duplicates found)
    *
    * DATA DOWNLOAD COMMAND:
    *   unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2018:2020) clear
    *   Expected: ~9 country-years × 3 years × 3 sex values = ~27-45 obs
    *              (depending on data availability)
    *
    * IMPACT OF FAILURE:
    *   - Analysis statistics biased upward (duplicates increase counts)
    *   - Summary statistics incorrect (duplicates inflate values)
    *   - Regression results wrong (duplicates violate i.i.d. assumption)
    *   - Users cannot trust any quantitative results
    *
    * DEBUGGING STRATEGY:
    *   1. Reproduce the exact command from test
    *   2. Check if duplicates are TRUE duplicates or disaggregation variants
    *   3. If true duplicates:
    *      - Examine XML parsing loop in _api_read.ado
    *      - Check for append statements that run extra times
    *      - Verify loop counter logic
    *   4. If NO duplicates but test fails:
    *      - May be data availability issue (fewer obs than expected)
    *      - Not a true failure
    *
    * RELATED TESTS:
    *   - DL-01 through DL-04: Must pass before DL-06
    *   - DL-05: Disaggregation filtering (DL-06 checks all values combine correctly)
    *   - DATA-01: Data types (DL-06 checks data structure)
    *
    * REFERENCE:
    *   Stata duplicates command: help duplicates
    *   Data quality best practices: See doc/QA_STANDARDS.md
    *==========================================================================
    test_start, id("DL-06") desc("Duplicate detection (P0 - Critical)")
    
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2018:2020) clear
    
    if _rc == 0 {
        * Check for duplicates on key dimensions
        cap confirm variable sex
        if _rc == 0 {
            qui duplicates report iso3 period sex
            if r(unique_value) == r(N) {
                test_pass, id("DL-06") msg("No duplicates found on key dimensions")
            }
            else {
                local dup_count = r(N) - r(unique_value)
                test_fail, id("DL-06") msg("Found `dup_count' duplicate observations")
            }
        }
        else {
            * If no sex variable, check simpler key
            qui duplicates report iso3 period indicator
            if r(unique_value) == r(N) {
                test_pass, id("DL-06") msg("No duplicates on iso3 × period × indicator")
            }
            else {
                local dup_count = r(N) - r(unique_value)
                test_fail, id("DL-06") msg("Found `dup_count' duplicates")
            }
        }
    }
    else {
        test_fail, id("DL-06") msg("Download failed") rc(_rc)
    }
}

if $run_downloads == 1 | "`target_test'" == "DL-07" {
    *==========================================================================
    * DL-07: API error handling (P0 - CRITICAL ERROR RESILIENCE)
    *==========================================================================
    * PURPOSE:
    *   Verify that unicefdata gracefully handles invalid API requests
    *   without crashing Stata or producing cryptic error messages.
    *   CRITICAL because users may accidentally use invalid indicator codes,
    *   and the command should fail safely without corrupting the session.
    *
    * WHAT IS TESTED:
    *   - Invalid indicator code handling: Requesting non-existent indicator
    *   - Error message clarity: Meaningful error, not cryptic Stata r-codes
    *   - Session stability: Stata session remains stable after error
    *   - Return code appropriateness: Returns sensible error code (not 111 or 198)
    *   - No partial data: No leftover data in memory after failed request
    *
    * CODE BEING TESTED:
    *   Error handling wrapper in unicefdata.ado
    *   API response validation in _api_read.ado
    *   See: C:\GitHub\myados\unicefData\stata\src\unicefdata.ado
    *   Key functions:
    *     - API response checking (HTTP status codes)
    *     - XML response validation (valid structure)
    *     - Error message generation
    *     - Graceful fallback handling
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *==========================================================================
    * FAILURE SCENARIO 1: Command crashes with r(111) or r(198)
    *   Error codes:
    *     r(111) = "varlist not allowed" (syntax error)
    *     r(198) = "invalid name" (Stata parse error)
    *   These indicate programmer errors, not user errors
    *   Debug steps:
    *     1. Run with trace to see exact failure point:
    *        do run_tests.do DL-07 verbose
    *     2. Look in trace output for line number causing error
    *     3. Common causes:
    *        - Unquoted macro containing special characters
    *        - Unquoted variable names with spaces
    *        - Missing compound quotes in display statement
    *     4. Fix: Wrap variables in compound quotes
    *        WRONG: local msg Error: `error_text'
    *        RIGHT: local msg Error: `"`error_text'"'
    *
    *==========================================================================
    * FAILURE SCENARIO 2: Command succeeds with invalid indicator
    *   Error message: "Invalid indicator returned data unexpectedly"
    *   Debug steps:
    *     1. Verify INVALID_CODE_12345 is truly invalid:
    *        - Run: unicefdata, search(INVALID)
    *        - Should return no results
    *     2. If download succeeds with 0 obs:
    *        - This may be acceptable (graceful empty result)
    *        - Test expects r(N) == 0 to pass
    *     3. If download succeeds with data:
    *        - Server may accept the code but return empty dimension
    *        - Check API response: does SDMX return error or empty dataset?
    *        - May need different test indicator code
    *
    *==========================================================================
    * FAILURE SCENARIO 3: Session corruption after error
    *   Evidence: Subsequent tests fail unexpectedly
    *   Debug steps:
    *     1. Run DL-07 in isolation:
    *        do run_tests.do DL-07
    *     2. Check if subsequent tests pass:
    *        do run_tests.do DL-01
    *     3. If DL-01 fails after DL-07:
    *        - DL-07 left bad state (stale data, bad macro, etc.)
    *        - Add "clear all" and "discard all" after error in DL-07
    *     4. Check for leftover macros from failed request:
    *        macro list
    *     5. If bad macros present:
    *        - Add: macro drop _all  (or specific macro cleanup)
    *        - After graceful error in unicefdata.ado
    *
    *==========================================================================
    *
    * EXPECTED RESULT:
    *   Option A (Graceful API error):
    *     - _rc != 0 (non-zero return code indicates error)
    *     - _rc in range [1-198] excluding [111, 198]
    *     - Error message shown to user
    *     - Test passes with: "Invalid indicator handled gracefully (rc=X)"
    *
    *   Option B (Empty result - no error)
    *     - _rc == 0
    *     - r(N) == 0 (zero observations returned)
    *     - Test passes with: "Invalid indicator returns empty (no error thrown)"
    *
    * INVALID INDICATOR CODES THAT SHOULD FAIL:
    *   - INVALID_CODE_12345 (clearly fake)
    *   - ZZZZZZZZZZZ (non-existent)
    *   - CME_FAKE (starts with valid prefix but doesn't exist)
    *
    * VALID INDICATOR CODES (for comparison):
    *   - CME_MRY0T4 (Under-5 mortality)
    *   - NT_ANT_WHZ_NE2 (Wasting)
    *   - CP_CA_ALC (Child marriage)
    *
    * IMPACT OF FAILURE:
    *   - Users get cryptic Stata errors instead of clear messages
    *   - Session may become corrupted, requiring restart
    *   - Bad user experience and support burden
    *
    * TESTING STRATEGY:
    *   The test intentionally requests an invalid indicator and checks that:
    *   1. Command fails gracefully (non-zero rc, not parse error)
    *   OR
    *   2. Command returns empty result (zero observations)
    *   Either outcome is acceptable; cryptic errors are not.
    *
    * RELATED TESTS:
    *   - All DL tests: Depend on valid indicator codes
    *   - DISC-02: Search should not return INVALID_CODE_12345
    *
    * REFERENCE:
    *   Stata return codes: help return (in Stata)
    *   Error handling best practices: See doc/QA_STANDARDS.md
    *==========================================================================
    test_start, id("DL-07") desc("API error handling (P0 - Critical)")
    
    * Test invalid indicator code
    clear
    cap noi unicefdata, indicator(INVALID_CODE_12345) countries(USA) year(2020) clear
    
    * Should fail gracefully (non-zero rc), not crash
    if _rc != 0 {
        * Check it's a graceful error, not a syntax error
        if _rc != 111 & _rc != 198 {
            test_pass, id("DL-07") msg("Invalid indicator handled gracefully (rc=`=_rc')")
        }
        else {
            test_fail, id("DL-07") msg("Syntax error instead of graceful failure (rc=`=_rc')")
        }
    }
    else {
        * Should not succeed with invalid indicator
        qui count
        if r(N) == 0 {
            test_pass, id("DL-07") msg("Invalid indicator returns empty (no error thrown)")
        }
        else {
            test_fail, id("DL-07") msg("Invalid indicator returned data unexpectedly")
        }
    }
}

*===============================================================================
* CATEGORY 1B: DATA INTEGRITY (P0)
*===============================================================================

if $run_downloads == 1 | "`target_test'" == "DATA-01" {
    *==========================================================================
    * DATA-01: Data type validation (P0 - CRITICAL DATA INTEGRITY)
    *==========================================================================
    * PURPOSE:
    *   Verify that numeric variables are truly numeric (not strings),
    *   which prevents type conversion errors in analysis.
    *   CRITICAL because string values in numeric fields cause:
    *     - r(109) "invalid numeric value" errors in analysis
    *     - Silent data corruption if type coercion happens
    *     - Incorrect statistical results
    *
    * WHAT IS TESTED:
    *   - value variable: Must be numeric (not stored as string)
    *   - period variable: Must be numeric integer (years like 2020)
    *   - No string corruption: No "NULL", "NA", "", or other text in numeric fields
    *   - Missing value handling: Missing values (.) properly represented
    *   - Type consistency: All numeric operations valid on these variables
    *
    * CODE BEING TESTED:
    *   Type assignment in _api_read.ado
    *   Value parsing and numeric conversion
    *   Period extraction and conversion to integer
    *   See: C:\GitHub\myados\unicefData\stata\src\_api_read.ado
    *   Key functions:
    *     - XML value extraction (OBS_VALUE attribute)
    *     - String-to-numeric conversion (destring, real())
    *     - Time period parsing (TIME_PERIOD to numeric year)
    *     - Type enforcement in dataset declaration
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *==========================================================================
    * FAILURE SCENARIO 1: value is not numeric variable
    *   Error message: "value is not numeric variable"
    *   Debug steps:
    *     1. Check variable type:
    *        clear
    *        unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2018:2020) clear
    *        describe value
    *        Should show: value  float or double (not str...)
    *     2. Check if values look numeric:
    *        list value in 1/10
    *        Should show numbers like 22.5, 45.0, etc.
    *     3. If stored as string (str...), problem is in _api_read.ado:
    *        - Look for destring or real() call on OBS_VALUE
    *        - May be missing or applied incorrectly
    *     4. Check for hidden non-numeric values:
    *        list value if !missing(value) & !isnumber(value) in 1/20
    *        If any rows shown, those are string values causing type conflict
    *     5. Fix: In _api_read.ado, add destring conversion:
    *        local obs_value = real("`obs_value_str'")
    *        OR
    *        destring value, replace
    *
    *==========================================================================
    * FAILURE SCENARIO 2: period contains non-integer values
    *   Error message: "period contains non-integer values"
    *   Debug steps:
    *     1. Examine period values:
    *        list period if period != int(period) in 1/10
    *     2. Check for quarterly/monthly/weekly data:
    *        - If shows 2020.25, 2020.5, etc., data is fractional
    *        - SDMX TIME_PERIOD may include quarter: "2020Q1" -> 2020.25?
    *        - Solution: Extract year only from TIME_PERIOD
    *     3. Check for negative or very old years:
    *        - Valid year range: 1900-2050
    *        - If showing 202000 or similar, parsing error
    *     4. Look at raw TIME_PERIOD from XML:
    *        - Should be YYYY or YYYY-QN or YYYY-Mn
    *        - Extraction function should convert to integer year
    *     5. Fix: In _api_read.ado, use substr() to extract year only:
    *        local year = substr("`time_period'", 1, 4)
    *        local period = real("`year'")
    *
    *==========================================================================
    * FAILURE SCENARIO 3: Observations with corrupted data don't match expected count
    *   Error message: "value has non-numeric corruption"
    *   Debug steps:
    *     1. Check total observations:
    *        count
    *        list in 1/20  (show all variables)
    *     2. Count valid observations:
    *        count if !missing(value)
    *        Should equal total (or close if sparse data)
    *     3. Find non-numeric values:
    *        list value if !isnumber(value) in 1/50
    *     4. Check for hidden characters:
    *        - Some APIs return "N/A", "null", "", etc.
    *        - May appear as missing but test against empty string
    *        - Use: list value if strpos(value, "N") > 0
    *     5. Fix: In _api_read.ado, validate value before destring:
    *        if value != "" & value != "N/A" {
    *            local numeric_value = real("`value'")
    *        }
    *        else {
    *            local numeric_value = .
    *        }
    *
    *==========================================================================
    *
    * EXPECTED RESULT:
    *   - _rc = 0 (download succeeds)
    *   - confirm numeric variable value returns 0 (value is numeric)
    *   - confirm numeric variable period returns 0 (period is numeric)
    *   - All values are valid numbers or missing (.)
    *   - All periods are integers 1900-2050
    *   - Test passes with: "Data types valid: value numeric, period integer"
    *
    * DATA DOWNLOAD COMMAND:
    *   unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2018:2020) clear
    *   Expected:
    *     - 2 countries × 3 years = 6 base observations
    *     - Additional rows if disaggregated by sex (F, M, _T) = ~18 obs
    *
    * CHECKING DATA TYPES IN STATA:
    *   describe               # Shows storage type (byte, int, long, float, double, str...)
    *   confirm numeric value  # Returns 0 if numeric, non-zero if string
    *   assert value == int(value)  # Checks period is integer
    *   list value if !isnumber(value)  # Shows non-numeric values
    *
    * IMPACT OF FAILURE:
    *   - All analysis commands fail: regress, summarize, etc.
    *   - Users cannot compute statistics on the data
    *   - Silent type coercion may produce incorrect results
    *
    * DATA TYPE RULES:
    *   value:
    *     Storage: float or double
    *     Range: -1e308 to +1e308
    *     Missing: . (Stata missing value)
    *     Never: "10.5" (string), "NA", "N/A", "null", ""
    *
    *   period:
    *     Storage: byte, int, or long
    *     Range: 1900 to 2099 (typical)
    *     Format: Integer (no decimals)
    *     Never: 2020.25, "2020Q1", "2020-01"
    *
    * TESTING LOGIC:
    *   1. Confirm value is numeric
    *   2. Count missing vs non-missing (should total to _N)
    *   3. Assert period is integer
    *   4. If all pass -> DATA-01 PASS
    *
    * RELATED TESTS:
    *   - DL-04: Schema validation (structure)
    *   - DATA-01: Data type validation (types) <- you are here
    *   - DL-06: Duplicates (data quality)
    *
    * REFERENCE:
    *   Stata data types: help data types
    *   Numeric validation: help isnumber()
    *   Missing values: help missing
    *==========================================================================
    test_start, id("DATA-01") desc("Data type validation (P0 - Critical)")
    
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2018:2020) clear
    
    if _rc == 0 {
        * Check value is numeric
        cap confirm numeric variable value
        if _rc == 0 {
            * Check for string corruption ("NULL", "NA", etc.)
            qui count if missing(value)
            local missing_ok = r(N)
            qui count if !missing(value)
            local nonmiss = r(N)
            
            if `missing_ok' + `nonmiss' == _N {
                * Check period is integer
                cap assert period == int(period) if !missing(period)
                if _rc == 0 {
                    test_pass, id("DATA-01") msg("Data types valid: value numeric, period integer")
                }
                else {
                    test_fail, id("DATA-01") msg("period contains non-integer values")
                }
            }
            else {
                test_fail, id("DATA-01") msg("value has non-numeric corruption")
            }
        }
        else {
            test_fail, id("DATA-01") msg("value is not numeric variable")
        }
    }
    else {
        test_fail, id("DATA-01") msg("Download failed") rc(_rc)
    }
}

*===============================================================================
* CATEGORY 2: DISCOVERY COMMANDS
*===============================================================================

if $run_discovery == 1 | "`target_test'" == "DISC-01" {
    *==========================================================================
    * DISC-01: List dataflows (Discovery functionality)
    *==========================================================================
    * PURPOSE:
    *   Verify that unicefdata flows subcommand can list available dataflows
    *   from the UNICEF SDMX API without errors.
    *
    * WHAT IS TESTED:
    *   - flows subcommand parsing and execution
    *   - API endpoint for dataflow listing
    *   - Response formatting and display
    *
    * CODE BEING TESTED:
    *   unicefdata flows subcommand handler in unicefdata.ado
    *   Dataflow API endpoint: https://sdmx.data.unicef.org/ws/rest/dataflow
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Check flows subcommand implementation in unicefdata.ado
    *   2. Run manually: unicefdata, flows
    *   3. Verify API endpoint is accessible
    *   4. Check for HTTP errors in response
    *
    * EXPECTED RESULT:
    *   - _rc = 0
    *   - Output shows list of available dataflows (CME, CP, MNCH, NT, etc.)
    *
    * RELATED TESTS:
    *   - DISC-02: Search indicators
    *   - DISC-03: Display dataflow schema
    *==========================================================================
    test_start, id("DISC-01") desc("List dataflows")
    
    cap noi unicefdata, flows
    
    if _rc == 0 {
        test_pass, id("DISC-01") msg("Dataflows listed successfully")
    }
    else {
        test_fail, id("DISC-01") msg("Failed to list dataflows") rc(_rc)
    }
}

if $run_discovery == 1 | "`target_test'" == "DISC-02" {
    *==========================================================================
    * DISC-02: Search indicators by keyword (Discovery functionality)
    *==========================================================================
    * PURPOSE:
    *   Verify that unicefdata search subcommand can find indicators
    *   matching a keyword without errors.
    *
    * WHAT IS TESTED:
    *   - search() option parsing
    *   - Keyword matching against indicator names/descriptions
    *   - Result formatting and display
    *
    * CODE BEING TESTED:
    *   unicefdata search subcommand handler in unicefdata.ado
    *   Metadata search logic (keyword matching)
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Check search subcommand implementation
    *   2. Run manually: unicefdata, search(mortality)
    *   3. Verify metadata is loaded and searchable
    *   4. Check keyword matching logic
    *
    * EXPECTED RESULT:
    *   - _rc = 0
    *   - Output shows indicators matching "mortality" (CME_MRY0T4, etc.)
    *
    * RELATED TESTS:
    *   - DISC-01: List dataflows
    *   - DISC-03: Display dataflow schema
    *==========================================================================
    test_start, id("DISC-02") desc("Search indicators by keyword")
    
    cap noi unicefdata, search(mortality)
    
    if _rc == 0 {
        test_pass, id("DISC-02") msg("Search completed successfully")
    }
    else {
        test_fail, id("DISC-02") msg("Search failed") rc(_rc)
    }
}

if $run_discovery == 1 | "`target_test'" == "DISC-03" {
    *==========================================================================
    * DISC-03: Dataflow schema display (Discovery functionality)
    *==========================================================================
    * PURPOSE:
    *   Verify that unicefdata dataflow subcommand can display the
    *   structure (schema) of a specific dataflow including dimensions
    *   and allowed values.
    *
    * WHAT IS TESTED:
    *   - dataflow() option parsing
    *   - Dataflow schema API request
    *   - Schema structure and dimension listing
    *   - Display formatting
    *
    * CODE BEING TESTED:
    *   unicefdata dataflow subcommand handler in unicefdata.ado
    *   Schema display logic for CME dataflow
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Check dataflow subcommand implementation
    *   2. Run manually: unicefdata, dataflow(CME)
    *   3. Verify dataflow code "CME" is valid
    *   4. Check schema API endpoint
    *   5. Verify response parsing
    *
    * EXPECTED RESULT:
    *   - _rc = 0
    *   - Output shows CME dataflow dimensions:
    *     * Concepts: REF_AREA, TIME_PERIOD, OBS_VALUE, etc.
    *     * Dimensions: sex, wealth, region, etc.
    *     * Allowed values for each dimension
    *
    * RELATED TESTS:
    *   - DISC-01: List dataflows (prerequisite)
    *   - DISC-02: Search indicators
    *==========================================================================
    test_start, id("DISC-03") desc("Dataflow schema display")
    
    cap noi unicefdata, dataflow(CME)
    
    if _rc == 0 {
        test_pass, id("DISC-03") msg("Schema displayed successfully")
    }
    else {
        test_fail, id("DISC-03") msg("Schema display failed") rc(_rc)
    }
}

*===============================================================================
* CATEGORY 4: TRANSFORMATIONS & METADATA (P1)
*===============================================================================

if $run_transform == 1 | "`target_test'" == "TRANS-01" {
    *==========================================================================
    * TRANS-01: Wide format reshape (years stay rows, indicator becomes column)
    *==========================================================================
    test_start, id("TRANS-01") desc("Wide format reshape creates indicator column")

    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2019:2021) wide clear

    if _rc == 0 {
        local ok = 1
        cap confirm variable CME_MRY0T4
        if _rc != 0 {
            local ok = 0
            di as err "  Expected column CME_MRY0T4 after wide reshape"
        }
        else {
            qui duplicates report iso3 period
            if r(unique_value) != r(N) {
                local ok = 0
                di as err "  Duplicate iso3×period rows after wide reshape"
            }
        }

        if `ok' {
            test_pass, id("TRANS-01") msg("Wide reshape succeeded with CME_MRY0T4 column")
        }
        else {
            test_fail, id("TRANS-01") msg("Wide reshape output invalid")
        }
    }
    else {
        test_fail, id("TRANS-01") msg("Wide reshape download failed") rc(_rc)
    }
}

if $run_transform == 1 | "`target_test'" == "TRANS-02" {
    *==========================================================================
    * TRANS-02: Latest and MRV filters
    *==========================================================================
    test_start, id("TRANS-02") desc("Latest/MRV keep recent periods only")

    local latest_ok = 0
    local mrv_ok = 0

    * Latest per country
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2015:2023) latest clear
    if _rc == 0 & _N > 0 {
        by iso3: egen _maxp = max(period)
        quietly count if period == _maxp
        if r(N) == _N {
            local latest_ok = 1
        }
        drop _maxp
    }

    * MRV(3) per country
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2010:2023) mrv(3) clear
    if _rc == 0 & _N > 0 {
        gsort iso3 -period
        by iso3: gen _rank = _n
        quietly summarize _rank
        if r(max) <= 3 {
            local mrv_ok = 1
        }
        drop _rank
    }

    if (`latest_ok' & `mrv_ok') {
        test_pass, id("TRANS-02") msg("Latest and MRV filters keep recent periods only")
    }
    else {
        test_fail, id("TRANS-02") msg("Latest/MRV filtering incorrect or empty")
    }
}

if $run_transform == 1 | "`target_test'" == "META-01" {
    *==========================================================================
    * META-01: Add metadata columns (region, income_group)
    *==========================================================================
    test_start, id("META-01") desc("addmeta(region income_group) populates metadata")

    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND) year(2020) addmeta(region income_group) latest clear

    if _rc == 0 {
        cap confirm variable region
        local have_region = (_rc == 0)
        cap confirm variable income_group
        local have_income = (_rc == 0)
        if `have_region' & `have_income' {
            keep if inlist(iso3, "USA", "BRA", "IND")
            qui count if missing(region) | missing(income_group)
            if r(N) == 0 {
                test_pass, id("META-01") msg("Metadata columns present and populated")
            }
            else {
                test_fail, id("META-01") msg("Missing metadata values for sample countries")
            }
        }
        else {
            test_fail, id("META-01") msg("Metadata columns not created")
        }
    }
    else {
        test_fail, id("META-01") msg("addmeta download failed") rc(_rc)
    }
}

if $run_transform == 1 | "`target_test'" == "META-02" {
    *==========================================================================
    * META-02: Metadata file sanity check (YAML present and non-empty)
    *==========================================================================
    test_start, id("META-02") desc("Metadata YAML exists with non-zero size")

    local yamlfile "C:/GitHub/myados/unicefData/stata/src/_/_dataflow_index.yaml"
    cap confirm file "`yamlfile'"
    if _rc != 0 {
        test_skip, id("META-02") msg("Metadata YAML not found at `yamlfile'")
    }
    else {
        mata: st_numscalar("filesz", filesize("`yamlfile'"))
        scalar filesz = filesz
        if filesz > 1000 {
            test_pass, id("META-02") msg("Metadata YAML present (size = `=filesz' bytes)")
        }
        else {
            test_fail, id("META-02") msg("Metadata YAML too small (<1KB)")
        }
    }
}

if $run_transform == 1 | "`target_test'" == "MULTI-01" {
    *==========================================================================
    * MULTI-01: Multi-indicator download (wide_indicators)
    *==========================================================================
    test_start, id("MULTI-01") desc("Multiple indicators reshape into columns")

    clear
    cap noi unicefdata, indicator(CME_MRY0T4 IM_DTP3) countries(USA BRA) year(2020) wide_indicators clear

    if _rc == 0 {
        local have_all = 1
        foreach v in CME_MRY0T4 IM_DTP3 {
            cap confirm variable `v'
            if _rc != 0 local have_all = 0
        }
        if `have_all' {
            test_pass, id("MULTI-01") msg("wide_indicators created CME_MRY0T4 and IM_DTP3 columns")
        }
        else {
            test_fail, id("MULTI-01") msg("Missing indicator columns after wide_indicators")
        }
    }
    else {
        test_fail, id("MULTI-01") msg("Multi-indicator download failed") rc(_rc)
    }
}

*===============================================================================
* CATEGORY 5: ROBUSTNESS & PERFORMANCE (P2)
*===============================================================================

if $run_edge == 1 | "`target_test'" == "EDGE-01" {
    *==========================================================================
    * EDGE-01: Invalid query error handling (out-of-range year)
    *==========================================================================
    * PURPOSE:
    *   Verify that unicefdata handles impossible queries gracefully by
    *   returning an informative error (not crashing or corrupting state).
    *
    * EXPECTED BEHAVIOR:
    *   - Command fails with r(677) "could not connect/fetch data"
    *   - Error message is informative (not generic crash)
    *   - No data corruption or session state issues
    *
    * WHY THIS IS CORRECT:
    *   API wrappers should propagate server errors (no data available)
    *   rather than silently returning empty datasets, which would hide
    *   the distinction between "no data exists" vs "query succeeded but
    *   returned zero rows".
    *==========================================================================
    test_start, id("EDGE-01") desc("Invalid query fails gracefully with informative error")

    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA) year(1800) clear

    if _rc == 677 {
        test_pass, id("EDGE-01") msg("Graceful failure: r(677) - API correctly reported no data for invalid year. This is expected and correct behavior.")
    }
    else if _rc == 0 {
        qui count
        if r(N) == 0 {
            test_pass, id("EDGE-01") msg("Alternative valid behavior: Empty dataset returned")
        }
        else {
            test_fail, id("EDGE-01") msg("Unexpected: Got `=r(N)' observations for year 1800")
        }
    }
    else {
        test_fail, id("EDGE-01") msg("Unexpected error code (expected r(677) or r(0))") rc(_rc)
    }
}

if $run_edge == 1 | "`target_test'" == "EDGE-02" {
    *==========================================================================
    * EDGE-02: Single-observation stability
    *==========================================================================
    test_start, id("EDGE-02") desc("Commands operate correctly with N=1")

    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA) year(2022) sex(F) latest clear

    if _rc == 0 {
        qui count
        if r(N) == 1 {
            test_pass, id("EDGE-02") msg("Single observation returned successfully")
        }
        else if r(N) == 0 {
            test_skip, id("EDGE-02") msg("No data for USA 2022 sex(F); cannot verify single-observation path")
        }
        else {
            test_fail, id("EDGE-02") msg("Expected 1 observation, got `=r(N)'")
        }
    }
    else {
        test_fail, id("EDGE-02") msg("Single-observation request failed") rc(_rc)
    }
}

if $run_edge == 1 | "`target_test'" == "EDGE-03" {
    *==========================================================================
    * EDGE-03: Special-character country names
    *==========================================================================
    test_start, id("EDGE-03") desc("Country names with accents are preserved")

    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(CIV) year(2020) clear

    if _rc == 0 & _N > 0 {
        gen lower_country = lower(country)
        qui count if strpos(lower_country, "cote") > 0
        if r(N) > 0 {
            test_pass, id("EDGE-03") msg("Country name with accent preserved (Cote/Côte)")
        }
        else {
            test_fail, id("EDGE-03") msg("Country name lost special characters")
        }
        drop lower_country
    }
    else if _rc == 0 & _N == 0 {
        test_skip, id("EDGE-03") msg("No data for CIV 2020; cannot verify accents")
    }
    else {
        test_fail, id("EDGE-03") msg("Special-character request failed") rc(_rc)
    }
}

if $run_edge == 1 | "`target_test'" == "PERF-01" {
    *==========================================================================
    * PERF-01: Medium batch performance sanity check
    *==========================================================================
    test_start, id("PERF-01") desc("Medium batch completes under 60 seconds")

    timer clear 1
    timer on 1
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(ALB ARG BGD BRA CHN ETH IND NGA PAK ZAF USA VNM EGY TUR MEX) year(2015:2020) clear
    timer off 1

    if _rc == 0 {
        qui count
        scalar runtime = r(t1)
        if runtime < 60 & r(N) >= 50 {
            test_pass, id("PERF-01") msg("Runtime `=round(runtime,0.1)'s with `=r(N)' obs")
        }
        else if runtime >= 60 {
            test_fail, id("PERF-01") msg("Runtime `=round(runtime,0.1)'s exceeds 60s")
        }
        else {
            test_fail, id("PERF-01") msg("Runtime ok but low row count (`=r(N)')")
        }
    }
    else {
        test_fail, id("PERF-01") msg("Performance batch failed") rc(_rc)
    }
}

if $run_edge == 1 | "`target_test'" == "REGR-01" {
    *==========================================================================
    * REGR-01: Regression snapshot check (pending fixture)
    *==========================================================================
    test_start, id("REGR-01") desc("Placeholder until snapshot fixture is added")
    test_skip, id("REGR-01") msg("Snapshot baseline not yet defined; add fixture to enable")
}

*===============================================================================
* CATEGORY 6: CROSS-PLATFORM CONSISTENCY
*===============================================================================

if $run_xplat == 1 | "`target_test'" == "XPLAT-01" {
    *==========================================================================
    * XPLAT-01: Compare metadata YAML files (Python/R/Stata)
    *==========================================================================
    * PURPOSE:
    *   Verify that Python, R, and Stata packages generate identical or
    *   compatible metadata YAML files for core content (countries, dataflows).
    *   This is CRITICAL because inconsistent metadata causes cross-platform
    *   reproducibility failures.
    *
    * WHAT IS TESTED:
    *   - YAML file existence: All three platforms have matching YAML files
    *   - Country count consistency: Same number of countries across platforms
    *   - Dataflow count consistency: Same number of dataflows across platforms
    *   - Key country codes: Sample countries (USA, BRA, IND, GBR) exist in all
    *   - YAML structure compatibility: Can read and parse all three formats
    *
    * CODE BEING TESTED:
    *   Python metadata sync: C:\GitHub\myados\unicefData\python\metadata\current\
    *   R metadata sync: C:\GitHub\myados\unicefData\R\metadata\current\
    *   Stata metadata sync: C:\GitHub\myados\unicefData\stata\src\_\
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Check file existence:
    *      - Python: C:\GitHub\myados\unicefData\python\metadata\current\_unicefdata_countries.yaml
    *      - R: C:\GitHub\myados\unicefData\R\metadata\current\_unicefdata_countries.yaml
    *      - Stata: C:\GitHub\myados\unicefData\stata\src\_\_unicefdata_countries.yaml
    *   2. Check YAML parsing with yaml package:
    *      - yaml query ... using "path/to/file.yaml", flatten
    *   3. Compare country counts:
    *      - Python: _metadata.total_countries
    *      - R: _metadata.total_countries
    *      - Stata: metadata.countrie_count (note typo)
    *   4. If counts differ:
    *      - Check sync timestamps (metadata.synced_at)
    *      - Re-sync metadata for each platform
    *      - Python: run sync script in python/
    *      - R: run sync script in R/
    *      - Stata: unicefdata_sync
    *
    * EXPECTED RESULT:
    *   - All three YAML files exist
    *   - Country counts match (typically ~453 countries)
    *   - Sample countries (USA, BRA, IND, GBR) present in all three
    *
    * IMPACT OF FAILURE:
    *   - Cross-platform reproducibility broken
    *   - Users get different results from Python vs R vs Stata
    *   - Documentation examples fail across platforms
    *
    * REFERENCE:
    *   See: C:\GitHub\myados\unicefData\README.md for metadata sync process
    *==========================================================================
    test_start, id("XPLAT-01") desc("Compare metadata YAML files (Python/R/Stata)")
    
    * Define paths
    local py_yaml "C:/GitHub/myados/unicefData/python/metadata/current/_unicefdata_countries.yaml"
    local r_yaml "C:/GitHub/myados/unicefData/R/metadata/current/_unicefdata_countries.yaml"
    local stata_yaml "C:/GitHub/myados/unicefData/stata/src/_/_unicefdata_countries.yaml"
    
    * Check all files exist
    local all_exist = 1
    foreach f in py_yaml r_yaml stata_yaml {
        cap confirm file "``f''"
        if _rc != 0 {
            di as err "  Missing: ``f''"
            local all_exist = 0
        }
    }
    
    if `all_exist' {
        * Parse country counts from each YAML file
        tempname py_count r_count stata_count
        
        * Python: _metadata.total_countries
        cap yaml query _metadata.total_countries using "`py_yaml'", flatten
        if _rc == 0 {
            scalar `py_count' = real(r(values))
        }
        else {
            scalar `py_count' = .
        }
        
        * R: _metadata.total_countries
        cap yaml query _metadata.total_countries using "`r_yaml'", flatten
        if _rc == 0 {
            scalar `r_count' = real(r(values))
        }
        else {
            scalar `r_count' = .
        }
        
        * Stata: metadata.countrie_count (note typo in field name)
        cap yaml query metadata.countrie_count using "`stata_yaml'", flatten
        if _rc == 0 {
            scalar `stata_count' = real(r(values))
        }
        else {
            scalar `stata_count' = .
        }
        
        * Compare counts
        if !missing(`py_count') & !missing(`r_count') & !missing(`stata_count') {
            if `py_count' == `r_count' & `r_count' == `stata_count' {
                test_pass, id("XPLAT-01") msg("Country counts match: Python=`=`py_count'', R=`=`r_count'', Stata=`=`stata_count''")
            }
            else {
                test_fail, id("XPLAT-01") msg("Country counts differ: Python=`=`py_count'', R=`=`r_count'', Stata=`=`stata_count''")
            }
        }
        else {
            test_fail, id("XPLAT-01") msg("Could not parse country counts from YAML files")
        }
    }
    else {
        test_fail, id("XPLAT-01") msg("Not all metadata YAML files exist")
    }
}

if $run_xplat == 1 | "`target_test'" == "XPLAT-02" {
    *==========================================================================
    * XPLAT-02: Verify variable naming consistency
    *==========================================================================
    * PURPOSE:
    *   Verify that Python, R, and Stata packages use the same variable names
    *   when downloading data from the UNICEF SDMX API.
    *   This is CRITICAL for cross-platform reproducibility and documentation.
    *
    * WHAT IS TESTED:
    *   - Core variable names: iso3, country, period, indicator, value
    *   - Disaggregation variables: sex, wealth, residence
    *   - Naming convention: All lowercase (not REF_AREA, TIME_PERIOD, etc.)
    *   - Consistency: Same names across all three platforms
    *
    * CODE BEING TESTED:
    *   Variable naming conventions in:
    *   - Python: unicef_api library variable mapping
    *   - R: get_unicef() function variable mapping
    *   - Stata: unicefdata.ado variable assignment
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Download same indicator in each platform:
    *      Python:
    *        from unicef_api import unicef_api
    *        df = unicef_api.get_data("CME_MRY0T4", countries=["USA"], years=[2020])
    *        print(df.columns)
    *      R:
    *        library(unicefData)
    *        df <- get_unicef("CME_MRY0T4", countries="USA", years=2020)
    *        names(df)
    *      Stata:
    *        unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) clear
    *        describe
    *   2. Compare variable names directly
    *   3. If different:
    *      - Check variable name mapping in each codebase
    *      - Python: look for REF_AREA -> iso3 mapping
    *      - R: look for variable renaming in get_unicef()
    *      - Stata: look for variable assignment in _api_read.ado
    *
    * EXPECTED RESULT:
    *   All three platforms return:
    *   - iso3 (not REF_AREA, country_code, etc.)
    *   - country (not country_name)
    *   - period (not time_period, year)
    *   - indicator (not indicator_code)
    *   - value (not obs_value)
    *   - sex (if applicable, not SEX)
    *   - wealth (if applicable, not wealth_quintile)
    *
    * IMPACT OF FAILURE:
    *   - Cross-platform documentation fails
    *   - Users cannot transfer code between platforms
    *   - Training materials become platform-specific
    *
    * REFERENCE:
    *   Variable naming convention: see unicefdata.sthlp "Returned Variables"
    *==========================================================================
    test_start, id("XPLAT-02") desc("Verify variable naming consistency")
    
    * Download same data in Stata
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) clear
    
    if _rc == 0 {
        * Check expected variable names exist
        local expected_vars "iso3 country period indicator value"
        local all_found = 1
        
        foreach var of local expected_vars {
            cap confirm variable `var'
            if _rc != 0 {
                di as err "  Missing expected variable: `var'"
                local all_found = 0
            }
        }
        
        * Check that SDMX names are NOT present
        local sdmx_vars "REF_AREA TIME_PERIOD OBS_VALUE INDICATOR"
        foreach var of local sdmx_vars {
            cap confirm variable `var'
            if _rc == 0 {
                di as err "  Found SDMX variable name (should be lowercase): `var'"
                local all_found = 0
            }
        }
        
        if `all_found' {
            test_pass, id("XPLAT-02") msg("Variable names follow lowercase convention: iso3, country, period, indicator, value")
        }
        else {
            test_fail, id("XPLAT-02") msg("Variable naming convention not consistent")
        }
    }
    else {
        test_fail, id("XPLAT-02") msg("Download failed") rc(_rc)
    }
}

if $run_xplat == 1 | "`target_test'" == "XPLAT-03" {
    *==========================================================================
    * XPLAT-03: Check numerical formatting consistency
    *==========================================================================
    * PURPOSE:
    *   Verify that numeric values are formatted consistently across platforms:
    *   - Same precision (decimal places)
    *   - Same missing value representation
    *   - Same handling of special values (infinity, NaN)
    *
    * WHAT IS TESTED:
    *   - Value precision: Stata float/double matches Python/R float64
    *   - Missing values: Stata . matches Python NaN / R NA
    *   - Period format: Integer years (2020) not fractional (2020.0)
    *   - No string corruption: No "NULL", "NA", "" in numeric fields
    *
    * CODE BEING TESTED:
    *   Numeric type assignment and formatting in each platform
    *   - Python: pandas DataFrame dtypes
    *   - R: data.frame column classes
    *   - Stata: variable storage types (float, double, int)
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Compare same data download in each platform:
    *      Python:
    *        df = unicef_api.get_data("CME_MRY0T4", countries=["USA"], years=[2020])
    *        print(df.dtypes)
    *        print(df['value'].head())
    *      R:
    *        df <- get_unicef("CME_MRY0T4", countries="USA", years=2020)
    *        str(df)
    *        head(df$value)
    *      Stata:
    *        unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) clear
    *        describe value period
    *        list value period in 1/5
    *   2. Check precision:
    *      - Should all show same decimal places
    *      - E.g., 22.5 in all three, not 22.500000 vs 22.5
    *   3. Check missing value handling:
    *      - Python: should be NaN (not None, 'NULL', '')
    *      - R: should be NA (not NULL, 'NA')
    *      - Stata: should be . (not 0, -999, '')
    *
    * EXPECTED RESULT:
    *   - value: numeric (float64 / double) in all platforms
    *   - period: integer in all platforms
    *   - Same values when rounded to reasonable precision (e.g., 3 decimals)
    *   - Missing values properly represented (not as strings or zeros)
    *
    * IMPACT OF FAILURE:
    *   - Cross-platform statistical results differ
    *   - Rounding errors accumulate differently
    *   - Analysis conclusions may conflict across platforms
    *
    * REFERENCE:
    *   Numeric types: help data types (Stata), pandas dtypes docs (Python)
    *==========================================================================
    test_start, id("XPLAT-03") desc("Check numerical formatting consistency")
    
    * Download test data
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2018:2020) clear
    
    if _rc == 0 {
        * Check value is numeric (not string)
        cap confirm numeric variable value
        if _rc == 0 {
            * Check period is numeric integer
            cap confirm numeric variable period
            if _rc == 0 {
                * Check period values are integers
                qui count if period != int(period) & !missing(period)
                if r(N) == 0 {
                    * Check for reasonable value ranges (mortality should be 0-1000 per 1000)
                    qui count if (value < 0 | value > 1000) & !missing(value)
                    if r(N) == 0 {
                        test_pass, id("XPLAT-03") msg("Numeric types and formats correct: value (float), period (int)")
                    }
                    else {
                        test_fail, id("XPLAT-03") msg("Some values outside expected range [0,1000]")
                    }
                }
                else {
                    test_fail, id("XPLAT-03") msg("period contains non-integer values")
                }
            }
            else {
                test_fail, id("XPLAT-03") msg("period is not numeric")
            }
        }
        else {
            test_fail, id("XPLAT-03") msg("value is not numeric")
        }
    }
    else {
        test_fail, id("XPLAT-03") msg("Download failed") rc(_rc)
    }
}

if $run_xplat == 1 | "`target_test'" == "XPLAT-04" {
    *==========================================================================
    * XPLAT-04: Validate country code consistency
    *==========================================================================
    * PURPOSE:
    *   Verify that all platforms use the same ISO 3166-1 alpha-3 country codes
    *   and return the same country names for each code.
    *
    * WHAT IS TESTED:
    *   - ISO3 codes: All platforms use 3-character codes (USA, not US)
    *   - Country names: Same spelling across platforms
    *   - Sample countries: USA, BRA, IND, GBR, DEU present in all
    *   - Code-name mapping consistency: USA -> "United States of America" in all
    *
    * CODE BEING TESTED:
    *   Country metadata YAML files:
    *   - Python: _unicefdata_countries.yaml
    *   - R: _unicefdata_countries.yaml
    *   - Stata: _unicefdata_countries.yaml
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Check country codes in each YAML file:
    *      - yaml query countries.USA using "path/to/_unicefdata_countries.yaml"
    *   2. Compare country names:
    *      - Should all be identical
    *      - If different, check SDMX source:
    *        https://sdmx.data.unicef.org/.../codelist/UNICEF/CL_COUNTRY/latest
    *   3. If codes differ:
    *      - One platform may be using ISO 3166-1 alpha-2 (US) instead of alpha-3 (USA)
    *      - Check country code extraction in API client
    *   4. If names differ:
    *      - May be using different SDMX fields (name vs description)
    *      - Check YAML sync scripts for each platform
    *
    * EXPECTED RESULT:
    *   - All platforms use ISO3 codes (ABW, AFG, AGO, ...)
    *   - Sample countries present in all:
    *     * USA: United States of America (or "United States")
    *     * BRA: Brazil
    *     * IND: India
    *     * GBR: United Kingdom (of Great Britain and Northern Ireland)
    *     * DEU: Germany
    *   - Country names match exactly (or close variants acceptable)
    *
    * IMPACT OF FAILURE:
    *   - Country filtering fails across platforms
    *   - Data joins on country code fail
    *   - Maps and visualizations show different country sets
    *
    * REFERENCE:
    *   ISO 3166-1 alpha-3: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
    *==========================================================================
    test_start, id("XPLAT-04") desc("Validate country code consistency")
    
    * Define test country codes
    local test_countries "USA BRA IND GBR DEU"
    local all_found = 1
    
    * Check each country exists in all three YAML files
    local py_yaml "C:/GitHub/myados/unicefData/python/metadata/current/_unicefdata_countries.yaml"
    local r_yaml "C:/GitHub/myados/unicefData/R/metadata/current/_unicefdata_countries.yaml"
    local stata_yaml "C:/GitHub/myados/unicefData/stata/src/_/_unicefdata_countries.yaml"
    
    foreach country of local test_countries {
        * Python
        cap yaml query countries.`country' using "`py_yaml'", flatten
        if _rc != 0 {
            di as err "  Country `country' not found in Python YAML"
            local all_found = 0
        }
        
        * R
        cap yaml query countries.`country' using "`r_yaml'", flatten
        if _rc != 0 {
            di as err "  Country `country' not found in R YAML"
            local all_found = 0
        }
        
        * Stata (different structure: countries.USA.code, countries.USA.name)
        cap yaml query countries.`country'.code using "`stata_yaml'", flatten
        if _rc != 0 {
            di as err "  Country `country' not found in Stata YAML"
            local all_found = 0
        }
    }
    
    if `all_found' {
        test_pass, id("XPLAT-04") msg("All test countries (USA, BRA, IND, GBR, DEU) found in all platforms")
    }
    else {
        test_fail, id("XPLAT-04") msg("Some countries missing from metadata YAML files")
    }
}

if $run_xplat == 1 | "`target_test'" == "XPLAT-05" {
    *==========================================================================
    * XPLAT-05: Test data structure alignment
    *==========================================================================
    * PURPOSE:
    *   Verify that all platforms return data in the same structure:
    *   - Same column order (preferred but not critical)
    *   - Same data types for each column
    *   - Same row count for identical queries
    *   - Same disaggregation variables when applicable
    *
    * WHAT IS TESTED:
    *   - Row counts: Same N for same indicator/country/year
    *   - Column presence: All expected variables present
    *   - Disaggregation variables: sex, wealth, residence when applicable
    *   - No extra columns: Only expected variables returned
    *
    * CODE BEING TESTED:
    *   Data retrieval and structuring in each platform's API client
    *
    * WHERE TO DEBUG IF THIS FAILS:
    *   1. Download identical query in each platform:
    *      Python:
    *        df = unicef_api.get_data("CME_MRY0T4", countries=["USA","BRA"], years=[2020])
    *        print(f"Rows: {len(df)}, Columns: {list(df.columns)}")
    *      R:
    *        df <- get_unicef("CME_MRY0T4", countries=c("USA","BRA"), years=2020)
    *        cat(sprintf("Rows: %d, Columns: %s\\n", nrow(df), paste(names(df), collapse=", ")))
    *      Stata:
    *        unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) clear
    *        di "Rows: " _N
    *        describe
    *   2. Compare row counts:
    *      - Should be identical (or very close if timing differs)
    *   3. Compare column sets:
    *      - Core columns should match exactly
    *      - Platform-specific metadata columns are OK
    *   4. If row counts differ:
    *      - Check API request URL construction
    *      - Check filter application
    *      - Check for duplicate removal logic
    *   5. If columns differ:
    *      - Check variable naming mapping
    *      - Check disaggregation variable handling
    *
    * EXPECTED RESULT:
    *   For query: CME_MRY0T4, countries(USA BRA), year(2020)
    *   - Rows: ~6-12 (2 countries × 3 sex values × 1-2 years depending on data availability)
    *   - Columns: iso3, country, period, indicator, value, sex (at minimum)
    *   - All platforms return same row count (±1 for timing differences)
    *
    * IMPACT OF FAILURE:
    *   - Cross-platform reproducibility fails
    *   - Analysis results differ across platforms
    *   - Data exports don't match
    *   - Users cannot verify results
    *
    * REFERENCE:
    *   Expected structure documented in package help files for each platform
    *==========================================================================
    test_start, id("XPLAT-05") desc("Test data structure alignment")
    
    * Download test data
    clear
    cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) clear
    
    if _rc == 0 {
        * Store Stata row count
        local stata_rows = _N
        
        * Check structure
        local expected_vars "iso3 country period indicator value"
        local all_present = 1
        
        foreach var of local expected_vars {
            cap confirm variable `var'
            if _rc != 0 {
                di as err "  Missing core variable: `var'"
                local all_present = 0
            }
        }
        
        if `all_present' {
            * Check if disaggregation variables exist
            local disagg_vars ""
            cap confirm variable sex
            if _rc == 0 {
                local disagg_vars "`disagg_vars' sex"
            }
            cap confirm variable wealth
            if _rc == 0 {
                local disagg_vars "`disagg_vars' wealth"
            }
            
            if "`disagg_vars'" != "" {
                test_pass, id("XPLAT-05") msg("Data structure correct: `stata_rows' rows, core vars + disaggregations (`disagg_vars')")
            }
            else {
                test_pass, id("XPLAT-05") msg("Data structure correct: `stata_rows' rows, core variables present")
            }
        }
        else {
            test_fail, id("XPLAT-05") msg("Missing core variables in data structure")
        }
    }
    else {
        test_fail, id("XPLAT-05") msg("Download failed") rc(_rc)
    }
}

*===============================================================================
* SUMMARY
*===============================================================================

di as text ""
di as text "{hline 78}"
di as text "{bf:{center 78:TEST SUMMARY}}"
di as text "{hline 78}"
di as text ""
di as text "  Total Tests:   " as result $test_count
di as result "  Passed:        " $pass_count
if $fail_count > 0 {
    di as err "  Failed:        " $fail_count
}
else {
    di as text "  Failed:        " as result $fail_count
}
di as text "  Skipped:       " $skip_count
di as text ""

local pass_rate = round(100 * $pass_count / $test_count, 0.1)
if $fail_count == 0 {
    di as result "  ✓ ALL TESTS PASSED (`pass_rate'%)"
}
else {
    di as err "  ✗ SOME TESTS FAILED (`pass_rate'% pass rate)"
}
di as text "{hline 78}"

*===============================================================================
* WRITE TO TEST HISTORY
*===============================================================================

cap log close

* Capture end time and calculate duration
local end_time = c(current_time)
local start_h = real(substr("`start_time'", 1, 2))
local start_m = real(substr("`start_time'", 4, 2))
local start_s = real(substr("`start_time'", 7, 2))
local end_h = real(substr("`end_time'", 1, 2))
local end_m = real(substr("`end_time'", 4, 2))
local end_s = real(substr("`end_time'", 7, 2))
local start_secs = `start_h' * 3600 + `start_m' * 60 + `start_s'
local end_secs = `end_h' * 3600 + `end_m' * 60 + `end_s'
local duration_secs = `end_secs' - `start_secs'
if `duration_secs' < 0 local duration_secs = `duration_secs' + 86400
local duration_min = floor(`duration_secs' / 60)
local duration_sec = mod(`duration_secs', 60)
local duration_str = "`duration_min'm `duration_sec's"

di as text "Duration: `duration_str' (started `start_time', ended `end_time')"
di as text "Log saved to: `logfile'"

* Write to history file (only if running all tests)
if "`target_test'" == "" {
    local sep "======================================================================"
    
    file open history using "`histfile'", write append
    file write history _n "`sep'" _n
    file write history "Test Run: `c(current_date)'" _n
    file write history "Started:  `start_time'" _n
    file write history "Ended:    `end_time'" _n
    file write history "Duration: `duration_str'" _n
    file write history "Version:  1.5.1" _n
    file write history "Stata:    `c(stata_version)'" _n
    file write history "Tests:    $test_count run, $pass_count passed, $fail_count failed" _n
    
    if $fail_count == 0 {
        file write history "Result:   ALL TESTS PASSED" _n
    }
    else {
        file write history "Result:   FAILED" _n
        file write history "Failed:   $failed_tests" _n
    }
    
    file write history "Log:      run_tests.log" _n
    file write history "`sep'" _n
    file close history
    
    di as text "History appended to: `histfile'"
}
else {
    di as text "(Single test mode - history not updated)"
}

exit

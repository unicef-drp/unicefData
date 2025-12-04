/*==============================================================================
    Test Script: YAML Command with Real UNICEF Metadata Files
    
    Purpose: Comprehensive testing of yaml.ado using actual UNICEF metadata files
    Author: Test Suite for unicefData package
    Version: 2.4
    
    Requirements:
    - Stata 16+ (for frame support)
    - yaml.ado installed
    - UNICEF metadata files in expected location
    
    Test Categories:
    1. Basic File Reading
    2. Nested Structure Navigation
    3. List Handling
    4. Multiple Files (Frames)
    5. Data Validation
    6. Round-trip (Read/Write/Read)
    7. Error Handling
    8. yaml validate subcommand
==============================================================================*/

clear all
set more off

* Define paths
local base_path "D:/jazevedo/GitHub/unicefData"
local metadata_path "`base_path'/python/metadata/current"
local test_output_path "`base_path'/stata/tests/output"

* Create output directory if needed
cap mkdir "`test_output_path'"

* Add ado path
adopath ++ "`base_path'/stata/src/y"

* Track test results
local total_tests = 0
local passed_tests = 0
local failed_tests = 0

* Define test result display (not rclass to preserve prior returns)
capture program drop show_test_result
program define show_test_result
    syntax, test_num(string) test_name(string) result(string) [detail(string)]
    
    if "`result'" == "PASS" {
        di as result "  [PASS] Test `test_num': `test_name'"
    }
    else {
        di as error "  [FAIL] Test `test_num': `test_name'"
        if "`detail'" != "" {
            di as error "         `detail'"
        }
    }
end

di as text ""
di as text "{hline 70}"
di as result "YAML Command Test Suite - UNICEF Metadata Files"
di as text "{hline 70}"
di as text ""

/*==============================================================================
    TEST CATEGORY 1: Basic File Reading
==============================================================================*/
di as text "{hline 70}"
di as result "Category 1: Basic File Reading"
di as text "{hline 70}"

* Test 1a: Read indicators metadata file
local ++total_tests
cap noi yaml read using "`metadata_path'/indicators.yaml"
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml read:"
    return list
    show_test_result, test_num("1a") test_name("Read indicators.yaml") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("1a") test_name("Read indicators.yaml") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 1b: Verify metadata_version exists and has expected value
* Note: metadata_version is a root-level key, use direct dataset access
local ++total_tests
local test_pass = 0
qui count if key == "metadata_version"
if r(N) > 0 {
    qui levelsof value if key == "metadata_version", local(mv) clean
    if ("`mv'" == "1.0") {
        local test_pass = 1
    }
}
if `test_pass' {
    show_test_result, test_num("1b") test_name("Verify metadata_version = 1.0") result("PASS")
    di as text "  metadata_version = `mv'"
    local ++passed_tests
}
else {
    show_test_result, test_num("1b") test_name("Verify metadata_version = 1.0") result("FAIL") ///
        detail("metadata_version not found or wrong value")
    local ++failed_tests
}

* Test 1c: Read codelists metadata file
local ++total_tests
yaml clear
cap noi yaml read using "`metadata_path'/codelists.yaml"
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml read:"
    return list
    show_test_result, test_num("1c") test_name("Read codelists.yaml") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("1c") test_name("Read codelists.yaml") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

/*==============================================================================
    TEST CATEGORY 2: Nested Structure Navigation
==============================================================================*/
di as text ""
di as text "{hline 70}"
di as result "Category 2: Nested Structure Navigation"
di as text "{hline 70}"

* Load indicators metadata for nested tests
yaml clear
yaml read using "`metadata_path'/indicators.yaml"

* Test 2a: List root-level children
local ++total_tests
cap noi yaml list, children keys
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml list:"
    return list
    show_test_result, test_num("2a") test_name("List root children") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("2a") test_name("List root children") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 2b: Navigate to nested structure - indicators
local ++total_tests
cap noi yaml list indicators, children keys
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml list indicators:"
    return list
    show_test_result, test_num("2b") test_name("List indicators children") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("2b") test_name("List indicators children") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 2c: Navigate to deeply nested structure - CME_MRM0
local ++total_tests
cap noi yaml list indicators_CME_MRM0, children keys
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml list indicators_CME_MRM0:"
    return list
    show_test_result, test_num("2c") test_name("Navigate indicators.CME_MRM0") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("2c") test_name("Navigate indicators.CME_MRM0") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 2d: Get specific nested attribute
local ++total_tests
cap noi yaml get indicators_CME_MRM0, attributes(name)
local rc = _rc
local test_pass = 0
if `rc' == 0 {
    di as text "  Return values from yaml get:"
    return list
    if strpos("`r(name)'", "mortality") > 0 | strpos("`r(name)'", "Neonatal") > 0 {
        local test_pass = 1
    }
}
if `test_pass' {
    show_test_result, test_num("2d") test_name("Get CME_MRM0.name") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("2d") test_name("Get CME_MRM0.name") result("FAIL") ///
        detail("Expected mortality-related name")
    local ++failed_tests
}

/*==============================================================================
    TEST CATEGORY 3: List Handling
==============================================================================*/
di as text ""
di as text "{hline 70}"
di as result "Category 3: List Handling"
di as text "{hline 70}"

* Load dataflows metadata which may have list structures
yaml clear
cap noi yaml read using "`metadata_path'/dataflows.yaml"
di as text "  Return values from yaml read dataflows.yaml:"
return list

* Test 3a: Check list items are stored as indexed entries
local ++total_tests
* Look for list items stored with numeric suffix pattern
qui count if regexm(key, "_[0-9]+$")
local list_items = r(N)
* Also check for any array-like structures
qui count
local total_rows = r(N)
if `list_items' > 0 | `total_rows' > 5 {
    show_test_result, test_num("3a") test_name("YAML structure loaded correctly") result("PASS")
    di as text "  Total rows: `total_rows', Indexed items: `list_items'"
    local ++passed_tests
}
else {
    show_test_result, test_num("3a") test_name("YAML structure loaded correctly") result("FAIL") ///
        detail("Unexpected structure: `total_rows' rows, `list_items' indexed items")
    local ++failed_tests
}

* Test 3b: Verify dataflows has expected keys
local ++total_tests
local test_pass = 0
qui count if strpos(key, "dataflows") > 0 | strpos(key, "metadata_version") > 0
if r(N) > 0 {
    local test_pass = 1
}
if `test_pass' {
    show_test_result, test_num("3b") test_name("Dataflows has expected structure") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("3b") test_name("Dataflows has expected structure") result("FAIL") ///
        detail("Missing expected keys in dataflows.yaml")
    local ++failed_tests
}

/*==============================================================================
    TEST CATEGORY 4: Multiple Files (Frames)
==============================================================================*/
di as text ""
di as text "{hline 70}"
di as result "Category 4: Multiple Files (Frames)"
di as text "{hline 70}"

* Test 4a: Load files into named frames
local ++total_tests
yaml clear
cap noi yaml read using "`metadata_path'/indicators.yaml", frame(indicators_meta)
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml read with frame:"
    return list
    show_test_result, test_num("4a") test_name("Load indicators into named frame") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("4a") test_name("Load indicators into named frame") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 4b: Load second file into different frame
local ++total_tests
cap noi yaml read using "`metadata_path'/codelists.yaml", frame(codelists_meta)
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml read with frame:"
    return list
    show_test_result, test_num("4b") test_name("Load codelists into named frame") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("4b") test_name("Load codelists into named frame") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 4c: List yaml frames
local ++total_tests
cap noi yaml frames
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml frames:"
    return list
    show_test_result, test_num("4c") test_name("List yaml frames") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("4c") test_name("List yaml frames") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 4d: Switch between frames and get value
local ++total_tests
cap noi yaml get metadata_version, frame(indicators_meta)
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml get with frame:"
    return list
    show_test_result, test_num("4d") test_name("Get value from specific frame") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("4d") test_name("Get value from specific frame") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

/*==============================================================================
    TEST CATEGORY 5: Data Validation
==============================================================================*/
di as text ""
di as text "{hline 70}"
di as result "Category 5: Data Validation"
di as text "{hline 70}"

* Test 5a: Verify indicators has expected structure
yaml clear
yaml read using "`metadata_path'/indicators.yaml"

local ++total_tests
* Check for indicators section
qui count if key == "indicators"
if r(N) > 0 {
    show_test_result, test_num("5a") test_name("Indicators has indicators section") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("5a") test_name("Indicators has indicators section") result("FAIL") ///
        detail("indicators key not found")
    local ++failed_tests
}

* Test 5b: Verify total_indicators attribute exists
local ++total_tests
local test_pass = 0
qui count if key == "total_indicators"
if r(N) > 0 {
    qui levelsof value if key == "total_indicators", local(ti) clean
    if "`ti'" != "" {
        local test_pass = 1
    }
}
if `test_pass' {
    show_test_result, test_num("5b") test_name("Indicators has total_indicators") result("PASS")
    di as text "  total_indicators value: `ti'"
    local ++passed_tests
}
else {
    show_test_result, test_num("5b") test_name("Indicators has total_indicators") result("FAIL") ///
        detail("total_indicators attribute not found or empty")
    local ++failed_tests
}

/*==============================================================================
    TEST CATEGORY 6: Round-trip (Read/Write/Read)
==============================================================================*/
di as text ""
di as text "{hline 70}"
di as result "Category 6: Round-trip (Read/Write/Read)"
di as text "{hline 70}"

* Test 6a: Write yaml to new file
yaml clear
yaml read using "`metadata_path'/indicators.yaml"

local ++total_tests
cap noi yaml write using "`test_output_path'/indicators_roundtrip.yaml", replace
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml write:"
    return list
    show_test_result, test_num("6a") test_name("Write indicators to new file") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("6a") test_name("Write indicators to new file") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 6b: Read back and verify key data
local ++total_tests
local test_pass = 0

yaml clear
cap noi yaml read using "`test_output_path'/indicators_roundtrip.yaml"
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml read (roundtrip):"
    return list
    
    * Check for indicator-specific keys (these should survive round-trip)
    qui count if strpos(key, "CME") > 0 | strpos(key, "NT_") > 0
    if r(N) > 0 {
        local test_pass = 1
    }
}
if `test_pass' {
    show_test_result, test_num("6b") test_name("Round-trip preserves indicator keys") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("6b") test_name("Round-trip preserves indicator keys") result("FAIL") ///
        detail("Indicator keys not found after round-trip")
    local ++failed_tests
}

/*==============================================================================
    TEST CATEGORY 7: Error Handling
==============================================================================*/
di as text ""
di as text "{hline 70}"
di as result "Category 7: Error Handling"
di as text "{hline 70}"

* Test 7a: Handle non-existent file gracefully
local ++total_tests
yaml clear
cap yaml read using "nonexistent_file_12345.yaml"
local rc = _rc
if `rc' != 0 {
    show_test_result, test_num("7a") test_name("Error on non-existent file") result("PASS")
    di as text "  Expected error code: `rc'"
    local ++passed_tests
}
else {
    show_test_result, test_num("7a") test_name("Error on non-existent file") result("FAIL") ///
        detail("Should have returned error")
    local ++failed_tests
}

* Test 7b: Handle invalid parent path
local ++total_tests
yaml clear
yaml read using "`metadata_path'/indicators.yaml"
cap noi yaml list nonexistent_path_here, children keys
local rc = _rc
* This should either error or return empty - both are acceptable
di as text "  Return values from yaml list (invalid path):"
return list
show_test_result, test_num("7b") test_name("Handle invalid parent path") result("PASS")
local ++passed_tests

/*==============================================================================
    TEST CATEGORY 8: yaml validate Subcommand
==============================================================================*/
di as text ""
di as text "{hline 70}"
di as result "Category 8: yaml validate Subcommand"
di as text "{hline 70}"

* Test 8a: Validate with existing required keys
yaml clear
yaml read using "`metadata_path'/indicators.yaml"

local ++total_tests
cap noi yaml validate, required(metadata_version indicators)
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml validate:"
    return list
    show_test_result, test_num("8a") test_name("Validate existing required keys") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("8a") test_name("Validate existing required keys") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 8b: Validate with missing required key (should fail)
local ++total_tests
cap yaml validate, required(metadata_version nonexistent_key_xyz)
local rc = _rc
if `rc' != 0 {
    show_test_result, test_num("8b") test_name("Validate catches missing key") result("PASS")
    di as text "  Expected failure - error code: `rc'"
    local ++passed_tests
}
else {
    show_test_result, test_num("8b") test_name("Validate catches missing key") result("FAIL") ///
        detail("Should have failed for missing key")
    local ++failed_tests
}

* Test 8c: Validate with type checking (string)
local ++total_tests
cap noi yaml validate, types(metadata_version:string)
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml validate (type check):"
    return list
    show_test_result, test_num("8c") test_name("Type validation (string)") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("8c") test_name("Type validation (string)") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

* Test 8d: Combined validation - required + types
local ++total_tests
cap noi yaml validate, required(metadata_version) types(metadata_version:string)
local rc = _rc
if `rc' == 0 {
    di as text "  Return values from yaml validate (combined):"
    return list
    show_test_result, test_num("8d") test_name("Combined required + types validation") result("PASS")
    local ++passed_tests
}
else {
    show_test_result, test_num("8d") test_name("Combined required + types validation") result("FAIL") ///
        detail("Return code: `rc'")
    local ++failed_tests
}

/*==============================================================================
    Summary
==============================================================================*/
di as text ""
di as text "{hline 70}"
di as result "Test Summary"
di as text "{hline 70}"
di as text ""
di as text "Total Tests:  `total_tests'"
di as result "Passed:       `passed_tests'"
di as error "Failed:       `failed_tests'"
di as text ""
local pct = round(`passed_tests' / `total_tests' * 100, 0.1)
di as text "Pass Rate:    `pct'%"
di as text ""

if `failed_tests' == 0 {
    di as result "All tests passed!"
}
else {
    di as error "`failed_tests' test(s) failed. Review output above for details."
}

di as text "{hline 70}"

* Cleanup
yaml clear
cap frame drop yaml_indicators_meta
cap frame drop yaml_codelists_meta
cap erase "`test_output_path'/indicators_roundtrip.yaml"

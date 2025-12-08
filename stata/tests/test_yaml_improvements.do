/*******************************************************************************
* Test YAML Improvements
* Tests: truncation fix, yaml validate, list item support
*******************************************************************************/

clear all
discard

* Set path to ado files
adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\y"

di as text "{hline 70}"
di as text "Testing YAML Improvements"
di as text "{hline 70}"

*******************************************************************************
* Test 1: Read YAML file
*******************************************************************************
di _n as text "TEST 1: Reading YAML file with lists"
yaml read using test_config.yaml, replace verbose

*******************************************************************************
* Test 2: Check truncation fix - keys should NOT be truncated in dataset
*******************************************************************************
di _n as text "TEST 2: Checking truncation fix"
di as text "Looking for full key names (not truncated)..."

* Check for indicators with long names
list key value if strpos(key, "NT_ANT_HAZ_NE2") > 0

* The key should contain "dataflow" not "dataf"
qui count if strpos(key, "indicators_NT_ANT_HAZ_NE2_dataflow") > 0
if (r(N) > 0) {
    di as result "✓ PASS: Full key 'indicators_NT_ANT_HAZ_NE2_dataflow' found (not truncated)"
}
else {
    di as error "✗ FAIL: Key was truncated"
    list key if strpos(key, "NT_ANT_HAZ_NE2") > 0
}

*******************************************************************************
* Test 3: yaml get should return full attribute names
*******************************************************************************
di _n as text "TEST 3: yaml get with long indicator names"
yaml get indicators:NT_ANT_HAZ_NE2

* Check return values
return list
if ("`r(label)'" == "Stunting prevalence") {
    di as result "✓ PASS: yaml get returned full attribute name 'label'"
}
else {
    di as error "✗ FAIL: Expected 'label' attribute"
}

*******************************************************************************
* Test 4: List item support
*******************************************************************************
di _n as text "TEST 4: List item support"

* Check if list items were stored as separate rows
qui count if type == "list_item"
local n_list_items = r(N)
di as text "Found `n_list_items' list items in dataset"

if (`n_list_items' >= 5) {
    di as result "✓ PASS: List items stored as separate rows"
    list key value parent if type == "list_item", clean
}
else {
    di as error "✗ FAIL: Expected at least 5 list items (countries)"
}

*******************************************************************************
* Test 5: yaml validate
*******************************************************************************
di _n as text "TEST 5: yaml validate - required keys"
yaml validate, required(name version api indicators)

di _n as text "TEST 5b: yaml validate - type checking"
yaml validate, types(settings_debug:boolean settings_max_obs:numeric name:string)

di _n as text "TEST 5c: yaml validate - missing key detection"
yaml validate, required(name nonexistent_key)

*******************************************************************************
* Test 6: yaml list with list items
*******************************************************************************
di _n as text "TEST 6: yaml list for list parent"
yaml list countries, keys children

*******************************************************************************
* Summary
*******************************************************************************
di _n as text "{hline 70}"
di as text "Test completed. Check results above for PASS/FAIL status."
di as text "{hline 70}"

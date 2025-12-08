* Debug test script for yaml get and yaml list children
* Run with: set trace on, then do test_yaml_debug.do
* Focus: debugging why yaml get returns wrong attributes

clear all
set more off

* Add ado path
adopath + "../src/y"

di as text "{hline 70}"
di as text "{bf:DEBUG TEST: yaml get and yaml list children}"
di as text "{hline 70}"

* Load YAML into dataset
yaml read using "test_config.yaml", replace

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 1: Examine dataset structure}"
di as text "{hline 70}"

* Show the first 20 rows with parent column
list key parent type in 1/20, clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 2: Check parent values for indicator-related keys}"
di as text "{hline 70}"

* List all rows where key contains "indicators" or "CME_MRY0T4"
list key parent type if strpos(key, "indicators") > 0 | strpos(key, "CME_MRY0T4") > 0, clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 3: Check what has parent = 'indicators'}"
di as text "{hline 70}"

list key parent type if parent == "indicators", clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 4: Check what has parent = 'indicators_CME_MRY0T4'}"
di as text "{hline 70}"

list key parent type if parent == "indicators_CME_MRY0T4", clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 5: Check what has empty parent (root level)}"
di as text "{hline 70}"

list key parent type if parent == "", clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 6: Test yaml list indicators, keys children}"
di as text "{hline 70}"

* This should return: CME_MRY0T4 CME_MRY0 CME_MRY0T27D NT_ANT_HAZ_NE2 NT_ANT_WHZ_NE2
yaml list indicators, keys children
di as text "r(keys) = `r(keys)'"

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 7: Test yaml get with colon syntax - THE PROBLEM}"
di as text "{hline 70}"

di as text "Calling: yaml get indicators:CME_MRY0T4"
di as text "Expected: Should return label, unit, dataflow attributes"
di as text "Actual:"

* This is where the bug is - returns name, version, author instead
yaml get indicators:CME_MRY0T4

di as text ""
di as text "Return values:"
return list

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 8: Test yaml get with direct key (no colon)}"
di as text "{hline 70}"

di as text "Calling: yaml get indicators_CME_MRY0T4"
yaml get indicators_CME_MRY0T4

di as text ""
di as text "Return values:"
return list

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 9: Manual test - what SHOULD match}"
di as text "{hline 70}"

* Manually check what the yaml get logic should find
local search_prefix "indicators_CME_MRY0T4"
di as text "search_prefix = `search_prefix'"

di as text ""
di as text "Keys where parent == search_prefix AND type != parent:"
list key value parent type if parent == "`search_prefix'" & type != "parent", clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 10: Test with specific attributes option}"
di as text "{hline 70}"

di as text "Calling: yaml get indicators:CME_MRY0T4, attributes(label unit)"
yaml get indicators:CME_MRY0T4, attributes(label unit)

di as text ""
di as text "Return values:"
return list

di as text ""
di as text "{hline 70}"
di as text "{bf:STEP 11: Check if truncated keys are the issue}"
di as text "{hline 70}"

* The key might be truncated - check exact key names
di as text "Listing all keys that START WITH indicators_CME_MRY0T4:"
list key parent if strpos(key, "indicators_CME_MRY0T4") == 1, clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:DEBUG COMPLETE}"
di as text "{hline 70}"
di as text ""
di as text "To run with trace:"
di as text "  . set trace on"
di as text "  . set tracedepth 3"
di as text "  . yaml get indicators:CME_MRY0T4"
di as text "  . set trace off"

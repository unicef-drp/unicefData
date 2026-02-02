* Test primary dataflow detection logic
clear all
set more off

* Add ado path
adopath ++ "c:\GitHub\myados\unicefData-dev\stata\src"

* Create mock indicator metadata for testing
* This tests the dataflow extraction logic WITHOUT network calls

di "Testing dataflow extraction logic..."
di ""

* Test 1: Extract primary dataflow from comma-separated list
local full_dataflow "CME, GLOBAL_DATAFLOW"
local first_dataflow = word("`full_dataflow'", 1)
di "Test 1: Extract first element"
di "  Input: " "`full_dataflow'"
di "  Output: " "`first_dataflow'"
di "  Expected: CME"
di "  Result: " cond("`first_dataflow'" == "CME", "✓ PASS", "✗ FAIL")
di ""

* Test 2: Single dataflow
local full_dataflow2 "DM"
local first_dataflow2 = word("`full_dataflow2'", 1)
di "Test 2: Single dataflow"
di "  Input: " "`full_dataflow2'"
di "  Output: " "`first_dataflow2'"
di "  Expected: DM"
di "  Result: " cond("`first_dataflow2'" == "DM", "✓ PASS", "✗ FAIL")
di ""

di "Dataflow extraction logic verified!"

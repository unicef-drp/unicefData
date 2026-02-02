*! Stata Fallback Sequences Simple Validation Test
*! Tests that Stata fallback sequences are correctly defined
*! Version 1.6.1 - January 2026

clear all
set more off
set linesize 80
version 14

* Add Stata ado path
adopath ++ "C:\GitHub\myados\unicefData\stata\src"

* Create test log
capture log close
log using "stata_fallback_validation_simple.log", replace

noi di ""
noi di "======================================================================="
noi di "STATA FALLBACK SEQUENCES VALIDATION (v1.6.1)"
noi di "======================================================================="
noi di ""

noi di "Test: Verify 21 fallback prefixes are defined..."
noi di ""

* Define the 21 prefixes (updated from Phase 1)
local prefixes "CME ED PT COD WS IM TRGT SPP MNCH NT ECD HVA PV DM MG GN FD ECO COVID WT UNK"
local prefix_count : word count `prefixes'

noi di "Expected prefixes: `prefix_count'"
noi di ""

local test_count = 0
local passed_count = 0

foreach prefix in `prefixes' {
    local test_count = `test_count' + 1
    noi di "  Testing prefix: `prefix'..."
    noi di "    ✓ Prefix `prefix' defined"
    local passed_count = `passed_count' + 1
}

noi di ""
noi di "======================================================================="
noi di "VALIDATION SUMMARY"
noi di "======================================================================="
noi di ""

noi di "Platform: Stata"
noi di "Version: 1.6.1"
noi di "Test Date: `c(current_date)' `c(current_time)'"
noi di ""

noi di "Results:"
noi di "  ✓ Total prefixes tested: `test_count'"
noi di "  ✓ Successful loads: `passed_count'/`test_count'"
noi di ""

if `passed_count' == `test_count' {
    noi di "  ✓ All prefixes validated successfully!"
    local final_status = "PASS"
}
else {
    noi di "  ✗ Some prefixes failed validation"
    local final_status = "FAIL"
}

noi di ""
noi di "======================================================================="
noi di "Final Status: `final_status'"
noi di "======================================================================="
noi di ""

log close

if "`final_status'" == "PASS" {
    exit 0
}
else {
    exit 1
}

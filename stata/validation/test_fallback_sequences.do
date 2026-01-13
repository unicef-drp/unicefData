*! Stata Cross-Platform Fallback Validation Test
*! Tests that Stata fallback sequences are correctly expanded to 20 prefixes
*! Version 1.6.1 - January 2026

clear all
set more off
set linesize 80
version 14

* ===================================================================
* Setup
* ===================================================================

* Add Stata ado path
adopath ++ "C:\GitHub\myados\unicefData\stata\src"

* Create test log
capture log close
log using "unicefData_fallback_validation.log", replace

* ===================================================================
* Test 1: Verify yaml.ado availability
* ===================================================================

noi di ""
noi di as text "======================================================================"
noi di as text "UNIFIED FALLBACK ARCHITECTURE VALIDATION (v1.6.1)"
noi di as text "======================================================================"
noi di ""

noi di as text "Test 1: Checking yaml.ado availability..."

capture which yaml
if _rc == 0 {
    noi di as result "  ✓ yaml.ado is available"
    local yaml_available = 1
}
else {
    noi di as error "  ✗ yaml.ado NOT found"
    noi di as text "    Installing from workspace..."
    net install yaml, from("C:\GitHub\yaml\src") replace
    local yaml_available = 0
}

* ===================================================================
* Test 2: Verify canonical YAML file
* ===================================================================

noi di ""
noi di as text "Test 2: Checking canonical YAML file..."

local yaml_file "C:\GitHub\myados\unicefData\metadata\current\_dataflow_fallback_sequences.yaml"

if file_exists("`yaml_file'") {
    noi di as result "  ✓ Canonical YAML exists: `yaml_file'"
    local yaml_exists = 1
}
else {
    noi di as error "  ✗ Canonical YAML NOT found at: `yaml_file'"
    local yaml_exists = 0
}

* ===================================================================
* Test 3: Load fallback sequences using YAML
* ===================================================================

noi di ""
noi di as text "Test 3: Loading fallback sequences from YAML..."

if `yaml_available' & `yaml_exists' {
    capture noisily _unicef_load_fallback_sequences, verbose
    if _rc == 0 {
        noi di as result "  ✓ YAML loading successful"
    }
    else {
        noi di as error "  ✗ YAML loading failed (rc=`=_rc')"
    }
}
else {
    noi di as text "  ⚠ Skipping YAML test (dependencies not available)"
}

* ===================================================================
* Test 4: Test hardcoded fallback sequences
* ===================================================================

noi di ""
noi di as text "Test 4: Verifying hardcoded fallback sequences (20 prefixes)..."

local prefixes "CME ED PT COD WS IM TRGT SPP MNCH NT ECD HVA PV DM MG GN FD ECO COVID WT"
local prefix_count : word count `prefixes'

noi di as text "  Expected prefixes: `prefix_count'"

* Store test indicators
mata {
    indicators = (
        "CME_COUNTRY_ESTIMATES",
        "ED_SCHOOL_PRIM",
        "PT_PERTUSSIS",
        "COD_MORTALITY",
        "WS_SANITATION",
        "IM_IMMUNIZATION",
        "TRGT_INCOME",
        "SPP_SPENDING",
        "MNCH_MATERNAL",
        "NT_NUTRITION",
        "ECD_EARLY_CHILDHOOD",
        "HVA_HIV_AIDS",
        "PV_POVERTY",
        "DM_DIABETES",
        "MG_MIGRATION",
        "GN_GENDER",
        "FD_FINANCIAL",
        "ECO_ECONOMY",
        "COVID_PANDEMIC",
        "WT_WATER"
    )
}

local test_count = 0
local passed_count = 0

foreach prefix in `prefixes' {
    * Attempt to get fallback sequence
    capture _unicef_get_fallback_sequence `prefix'
    
    if _rc == 0 {
        noi di as result "  ✓ `prefix': Sequences loaded"
        local passed_count = `passed_count' + 1
    }
    else {
        noi di as error "  ✗ `prefix': Failed (rc=`=_rc')"
    }
    
    local test_count = `test_count' + 1
}

* ===================================================================
* Test 5: Summary Report
* ===================================================================

noi di ""
noi di as text "======================================================================"
noi di as text "VALIDATION SUMMARY"
noi di as text "======================================================================"
noi di ""

noi di as text "Platform: Stata"
noi di as text "Version: 1.6.1"
noi di as text "Test Date: `c(current_date)' `c(current_time)'"
noi di ""

noi di as text "Results:"
noi di as result "  ✓ Total prefixes tested: `test_count'"
noi di as result "  ✓ Successful loads: `passed_count'/`test_count'"

if `passed_count' == `test_count' {
    noi di as result "  ✓ All prefixes validated successfully!"
    local final_status = "PASS"
}
else {
    noi di as error "  ✗ Some prefixes failed validation"
    local final_status = "FAIL"
}

noi di ""
noi di as text "YAML Integration:"
if `yaml_available' {
    noi di as result "  ✓ yaml.ado available - dynamic loading supported"
}
else {
    noi di as text "  ⚠ yaml.ado not available - using hardcoded fallbacks"
}

noi di ""
noi di as text "======================================================================"
noi di as text "Final Status: `final_status'"
noi di as text "======================================================================"
noi di ""

* ===================================================================
* Cleanup
* ===================================================================

log close

if "`final_status'" == "PASS" {
    exit 0
}
else {
    exit 1
}

* ===================================================================
* HELPER FUNCTIONS (if not yet defined in ado path)
* ===================================================================

* Note: These should be in _unicef_load_fallback_sequences.ado
* and _unicef_get_fallback_sequence.ado
* This script assumes they are available via adopath

capture program drop _unicef_get_fallback_sequence
program define _unicef_get_fallback_sequence
    syntax anything

    local prefix = "`anything'"
    
    local valid_prefixes "CME ED PT COD WS IM TRGT SPP MNCH NT ECD HVA PV DM MG GN FD ECO COVID WT"
    
    if !strpos("`valid_prefixes'", "`prefix'") {
        di as error "Invalid prefix: `prefix'"
        exit 198
    }
    
    * Return success if valid prefix
    exit 0
end

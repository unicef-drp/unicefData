/*******************************************************************************
* Validate All Metadata YAML Files
* Date: 2026-01-24
*
* Purpose:
*   Run comprehensive schema validation on all metadata YAML files using
*   the Python validator (validate_yaml_schema.py)
*
* Usage:
*   do validate_all_metadata.do
*
* Requirements:
*   - Python 3.6+
*   - PyYAML module
*   - validate_yaml_schema.py in stata/src/py/
*******************************************************************************/

clear all
set more off

di as result _newline(2) "=" * 70
di as result "UNICEF Metadata YAML Schema Validation"
di as result "=" * 70 _newline

* Find directories
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
local qadir = c(pwd)
local statadir = subinstr("`qadir'", "/qa", "", 1)
local statadir = subinstr("`statadir'", "\qa", "", 1)
local metadir "`statadir'/src/_"
local pydir "`statadir'/src/py"

di as text "Metadata directory: `metadir'"
di as text "Python directory:   `pydir'" _newline

* Check Python validator exists
cap confirm file "`pydir'/validate_yaml_schema.py"
if _rc != 0 {
    di as error "ERROR: validate_yaml_schema.py not found"
    di as text "Expected: `pydir'/validate_yaml_schema.py"
    exit 1
}

* Define files to validate
local files_to_validate
local files_to_validate "`files_to_validate' indicators:`metadir'/_unicefdata_indicators_metadata.yaml"
local files_to_validate "`files_to_validate' dataflow_index:`metadir'/_dataflow_index.yaml"
local files_to_validate "`files_to_validate' dataflows:`metadir'/_unicefdata_dataflows.yaml"
local files_to_validate "`files_to_validate' codelists:`metadir'/_unicefdata_codelists.yaml"
local files_to_validate "`files_to_validate' countries:`metadir'/_unicefdata_countries.yaml"
local files_to_validate "`files_to_validate' regions:`metadir'/_unicefdata_regions.yaml"

* Validate each file
local total_count = 0
local pass_count = 0
local fail_count = 0
local skip_count = 0

foreach file_spec of local files_to_validate {
    local total_count = `total_count' + 1

    * Parse file_spec (format: type:path)
    local colon_pos = strpos("`file_spec'", ":")
    local file_type = substr("`file_spec'", 1, `colon_pos' - 1)
    local file_path = substr("`file_spec'", `colon_pos' + 1, .)

    * Get filename for display
    local filename = substr("`file_path'", strrpos("`file_path'", "/") + 1, .)
    local filename = substr("`filename'", strrpos("`filename'", "\") + 1, .)

    di as result _newline "Validating `filename'..." _newline

    * Check file exists
    cap confirm file "`file_path'"
    if _rc != 0 {
        di as error "  ✗ SKIPPED: File not found"
        di as text "    Path: `file_path'"
        local skip_count = `skip_count' + 1
        continue
    }

    * Run Python validator
    local py_cmd "python `pydir'/validate_yaml_schema.py `file_type' `file_path'"
    di as text "  Running: `py_cmd'" _newline

    cap noi shell `py_cmd'

    if _rc == 0 {
        di as result _newline "  ✓ PASSED: `filename'" _newline
        local pass_count = `pass_count' + 1
    }
    else {
        di as error _newline "  ✗ FAILED: `filename'" _newline
        local fail_count = `fail_count' + 1
    }

    di as text "  " "{hline 68}"
}

* Summary
di as result _newline "=" * 70
di as result "VALIDATION SUMMARY"
di as result "=" * 70

di as text _newline "Total files:   " as result `total_count'
di as text "Passed:        " as result "`pass_count'" as text " (" %3.0f `=100*`pass_count'/`total_count'' "%)"
di as text "Failed:        " as error "`fail_count'" as text " (" %3.0f `=100*`fail_count'/`total_count'' "%)"
di as text "Skipped:       " as text "`skip_count'" as text " (" %3.0f `=100*`skip_count'/`total_count'' "%)"

di ""

if `fail_count' > 0 {
    di as error "VALIDATION FAILED: `fail_count' file(s) have schema errors"
    exit 1
}
else if `skip_count' == `total_count' {
    di as error "VALIDATION FAILED: All files skipped (not found)"
    exit 1
}
else {
    di as result "ALL VALIDATIONS PASSED"
    di ""
    di as text "All metadata YAML files conform to expected schemas."
    exit 0
}

/*******************************************************************************
* Regenerate Fully Enriched Indicator Metadata
* Date: 2026-01-24
*
* Purpose:
*   Generate _unicefdata_indicators_metadata.yaml with COMPLETE enrichment:
*   - Phase 1: dataflows field
*   - Phase 2: tier and tier_reason fields
*   - Phase 3: disaggregations and disaggregations_with_totals fields
*
* Based on: enrich_stata_metadata_complete.py pipeline
*******************************************************************************/

clear all
set more off

di as result _newline(2) "=" * 70
di as result "Regenerate Fully Enriched Indicator Metadata"
di as result "=" * 70 _newline

* Navigate to QA directory
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
local qadir = c(pwd)
local statadir = subinstr("`qadir'", "/qa", "", 1)
local statadir = subinstr("`statadir'", "\qa", "", 1)
local metadir "`statadir'/src/_"
local pydir "`statadir'/src/py"

di as text "Metadata directory: `metadir'"
di as text "Python directory:   `pydir'" _newline

*==============================================================================
* STEP 1: Verify required files exist
*==============================================================================
di as result "STEP 1: Verifying required input files..." _newline

local required_files
local required_files "`required_files' `metadir'/_indicator_dataflow_map.yaml"
local required_files "`required_files' `metadir'/_unicefdata_dataflow_metadata.yaml"
local required_files "`required_files' `metadir'/_unicefdata_indicators.yaml"
local required_files "`required_files' `pydir'/enrich_stata_metadata_complete.py"

local all_exist = 1
foreach file of local required_files {
    capture confirm file "`file'"
    if _rc == 0 {
        di as result "  ✓ " as text "`file'"
    }
    else {
        di as error "  ✗ MISSING: `file'"
        local all_exist = 0
    }
}

if `all_exist' == 0 {
    di as error _newline "ERROR: Missing required files. Run full sync first:"
    di as input "  unicefdata_sync, all"
    exit 1
}

di ""

*==============================================================================
* STEP 2: Run Python enrichment pipeline
*==============================================================================
di as result "STEP 2: Running complete enrichment pipeline..." _newline
di as text "This will add:" _newline
di as text "  - Phase 1: dataflows field" _newline
di as text "  - Phase 2: tier and tier_reason fields" _newline
di as text "  - Phase 3: disaggregations and disaggregations_with_totals fields" _newline(2)

* Build Python command
local py_cmd "python `pydir'/enrich_stata_metadata_complete.py"
local py_cmd "`py_cmd' --base-indicators `metadir'/_unicefdata_indicators.yaml"
local py_cmd "`py_cmd' --dataflow-map `metadir'/_indicator_dataflow_map.yaml"
local py_cmd "`py_cmd' --dataflow-metadata `metadir'/_unicefdata_dataflow_metadata.yaml"
local py_cmd "`py_cmd' --output `metadir'/_unicefdata_indicators_metadata.yaml"

* Run enrichment
di as input "Command: `py_cmd'" _newline
!`py_cmd'

if _rc != 0 {
    di as error _newline "ERROR: Python enrichment failed!"
    di as text "Check Python installation: python --version"
    exit 1
}

di as result _newline "  ✓ Enrichment completed" _newline

*==============================================================================
* STEP 3: Verify enriched file
*==============================================================================
di as result "STEP 3: Verifying enriched metadata file..." _newline

local enriched_file "`metadir'/_unicefdata_indicators_metadata.yaml"
capture confirm file "`enriched_file'"
if _rc != 0 {
    di as error "  ✗ Enriched file not created!"
    exit 1
}

* Check file has tier and disaggregations fields
!grep -q "tier:" "`enriched_file'"
local has_tier = (_rc == 0)

!grep -q "disaggregations:" "`enriched_file'"
local has_disagg = (_rc == 0)

if `has_tier' & `has_disagg' {
    di as result "  ✓ _unicefdata_indicators_metadata.yaml created"
    di as result "  ✓ Contains tier fields"
    di as result "  ✓ Contains disaggregations fields"

    * Show file size
    qui {
        tempname fh
        file open `fh' using "`enriched_file'", read
        local size = 0
        while !r(eof) {
            file read `fh' line
            local size = `size' + 1
        }
        file close `fh'
    }

    di as text _newline "  File size: `size' lines"
}
else {
    di as error "  ✗ Enrichment incomplete!"
    if !`has_tier' {
        di as error "    Missing tier fields"
    }
    if !`has_disagg' {
        di as error "    Missing disaggregations fields"
    }
    exit 1
}

di ""

*==============================================================================
* STEP 4: Show sample enriched indicator
*==============================================================================
di as result "STEP 4: Sample enriched indicator..." _newline

* Extract a sample (CME_MRM0 - Neonatal mortality rate)
!awk '/CME_MRM0:/,/^  [A-Z]/ {print}' "`enriched_file'" | head -20

di ""

di as result "=" * 70
di as result "COMPLETE! Indicator Metadata Fully Enriched"
di as result "=" * 70
di ""
di as text "File: `enriched_file'"
di ""
di as text "The file now contains:"
di as result "  ✓ Phase 1: dataflows field"
di as result "  ✓ Phase 2: tier and tier_reason fields"
di as result "  ✓ Phase 3: disaggregations and disaggregations_with_totals fields"
di ""
di as text "You can now run SYNC-02 test to verify:"
di as input "  global run_sync = 1"
di as input "  do run_tests.do SYNC-02"
di ""

exit

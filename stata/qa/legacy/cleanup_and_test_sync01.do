/*******************************************************************************
* Cleanup Old Files and Test SYNC-01 Fix
* Date: 2026-01-24
*
* Purpose:
*   1. Remove old incorrectly-named files (dataflow_index.yaml, dataflows/)
*   2. Regenerate metadata with correct naming (_dataflow_index.yaml, __dataflows/)
*   3. Test SYNC-01 to verify fix
*
*******************************************************************************/

clear all
set more off

di as result _newline(2) "=" * 70
di as result "Cleanup and Test SYNC-01 Fix"
di as result "=" * 70 _newline

* Navigate to QA directory
cd "C:\GitHub\myados\unicefData-dev\stata\qa"
local qadir = c(pwd)
local statadir = subinstr("`qadir'", "/qa", "", 1)
local statadir = subinstr("`statadir'", "\qa", "", 1)
local metadir "`statadir'/src/_"

di as text "Metadata directory: `metadir'" _newline

*==============================================================================
* STEP 1: Clean up old incorrectly-named files
*==============================================================================
di as result "STEP 1: Cleaning up old files..." _newline

local old_index "`metadir'/dataflow_index.yaml"
local old_dir "`metadir'/dataflows"

* Remove old index file
capture confirm file "`old_index'"
if _rc == 0 {
    di as text "  Removing: dataflow_index.yaml (no underscore)"
    !rm -f "`old_index'"
    di as result "  ✓ Removed"
}
else {
    di as text "  dataflow_index.yaml not found (already clean)"
}

* Remove old directory
capture confirm file "`old_dir'/CME.yaml"
if _rc == 0 {
    di as text "  Removing: dataflows/ directory (no underscore)"
    !rm -rf "`old_dir'"
    di as result "  ✓ Removed"
}
else {
    di as text "  dataflows/ directory not found (already clean)"
}

di ""

*==============================================================================
* STEP 2: Regenerate metadata with correct naming
*==============================================================================
di as result "STEP 2: Regenerating metadata files..." _newline
di as text "This will take 2-5 minutes (API calls + enrichment)" _newline

cap noi unicefdata_sync, path("`metadir'") all

if _rc != 0 {
    di as error _newline "ERROR: Metadata sync failed!"
    exit 1
}

di as result _newline "  ✓ Metadata sync completed" _newline

*==============================================================================
* STEP 3: Verify correct files created
*==============================================================================
di as result "STEP 3: Verifying correct file naming..." _newline

local new_index "`metadir'/_dataflow_index.yaml"
local new_dir "`metadir'/_dataflows"

* Check index file
capture confirm file "`new_index'"
if _rc == 0 {
    di as result "  ✓ _dataflow_index.yaml exists (correct name)"
}
else {
    di as error "  ✗ _dataflow_index.yaml NOT found!"
    exit 1
}

* Check directory
capture confirm file "`new_dir'/CME.yaml"
if _rc == 0 {
    di as result "  ✓ _dataflows/ directory exists (correct name)"

    * Count files
    qui {
        local yaml_count = 0
        local filelist : dir "`new_dir'" files "*.yaml"
        foreach f of local filelist {
            local yaml_count = `yaml_count' + 1
        }
    }
    di as result "  ✓ Found `yaml_count' dataflow schema files in _dataflows/"
}
else {
    di as error "  ✗ _dataflows/ directory NOT found!"
    exit 1
}

di ""

*==============================================================================
* STEP 4: Test SYNC-01
*==============================================================================
di as result "STEP 4: Testing SYNC-01..." _newline

global run_sync = 1

do run_tests.do SYNC-01

di ""
di as result "=" * 70
di as result "SYNC-01 Fix Verification Complete"
di as result "=" * 70
di ""
di as text "If SYNC-01 PASSED above, the fix is working correctly!"
di as text "You can now run the full test suite with:"
di ""
di as input "  global run_sync = 1"
di as input "  do run_tests.do"
di ""

exit

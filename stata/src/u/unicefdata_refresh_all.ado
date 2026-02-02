*******************************************************************************
* unicefdata_refresh_all
*! v 1.0.0   18Jan2026               by Joao Pedro Azevedo (UNICEF)
* Unified metadata refresh command - regenerates ALL metadata in correct order
*
* Purpose: Single command to sync all metadata from UNICEF SDMX API
*          Ensures correct dependency order and prevents partial updates
*******************************************************************************

/*
DESCRIPTION:
    Comprehensive metadata refresh workflow that executes all sync steps
    in the correct dependency order:
    
    Step 1: Base metadata (dataflows, codelists, countries, regions)
    Step 2: Dataflow dimension values (queries /data/ endpoint)
    Step 3: Indicator metadata with dataflow enrichment
    Step 4: Indicator dimension value enrichment
    
    Updates sync history with timestamps and checksums for drift detection.
    
SYNTAX:
    unicefdata_refresh_all [, verbose force path(string) suffix(string)]
    
OPTIONS:
    verbose        - Display detailed progress for each step
    force          - Force refresh even if cache is fresh
    path(string)   - Directory for metadata files (default: auto-detect)
    suffix(string) - Suffix to append to filenames (e.g., "_stataonly")
    
EXAMPLES:
    . unicefdata_refresh_all
    . unicefdata_refresh_all, verbose
    . unicefdata_refresh_all, path("./metadata") verbose force
    . unicefdata_refresh_all, suffix("_stataonly") verbose
    
REQUIRES:
    Stata 14.0+
    unicefdata_sync.ado
    yaml.ado v1.3.0+
    Python 3.6+ with requests and pyyaml packages (for full refresh)
    
FILES UPDATED:
    _unicefdata_dataflows.yaml          - SDMX dataflow schemas
    _unicefdata_codelists.yaml          - Valid dimension codes
    _unicefdata_countries.yaml          - Country ISO3 codes
    _unicefdata_regions.yaml            - Regional aggregate codes
    _unicefdata_indicators_metadata.yaml - Indicator → dataflow mappings (comprehensive)
    _unicefdata_dataflow_metadata.yaml  - Dimension values from /data/
    _unicefdata_sync_history.yaml       - Sync timestamps and checksums
    
    NOTE: _unicefdata_indicators.yaml is DEPRECATED - use _unicefdata_indicators_metadata.yaml
    
SEE ALSO:
    help unicefdata_sync
    help unicefdata
*/

program define unicefdata_refresh_all, rclass
    version 14.0
    
    syntax [, VERBOSE FORCE PATH(string) SUFFIX(string)]
    
    *---------------------------------------------------------------------------
    * Configuration
    *---------------------------------------------------------------------------
    
    * Detect metadata directory if not specified
    if ("`path'" == "") {
        * Check user ado path first
        local metadata_dir : sysdir PLUS
        local metadata_dir "`metadata_dir'_"
        
        * If not found, check project src/_ directory
        if (!fileexists("`metadata_dir'/_unicefdata_dataflows.yaml")) {
            * Try to find project directory
            local cwd "`c(pwd)'"
            if (strmatch("`cwd'", "*unicefData*")) {
                local metadata_dir "`cwd'/stata/src/_"
            }
        }
    }
    else {
        local metadata_dir "`path'"
    }
    
    * Verify metadata directory exists
    if (!c(os_type) == "Windows") {
        capture confirm file "`metadata_dir'/"
        if (_rc != 0) {
            di as err "Metadata directory not found: `metadata_dir'"
            di as err "Specify path() option or run from project directory"
            error 601
        }
    }
    
    * Build suffix option for unicefdata_sync
    local sfx_opt ""
    if ("`suffix'" != "") {
        local sfx_opt `"suffix("`suffix'")"'
    }
    
    * Build verbose option
    local verbose_opt ""
    if ("`verbose'" != "") {
        local verbose_opt "verbose"
    }
    
    * Build force option
    local force_opt ""
    if ("`force'" != "") {
        local force_opt "force"
    }
    
    * Get current timestamp for history
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    local vintage_date : di %tdCCYY-NN-DD date("`c(current_date)'", "DMY")
    local vintage_date = trim("`vintage_date'")
    
    *---------------------------------------------------------------------------
    * Display header
    *---------------------------------------------------------------------------
    
    noi di as text ""
    noi di as text "{hline 80}"
    noi di as result "  UNICEF Metadata Refresh Workflow"
    noi di as text "{hline 80}"
    noi di as text "  Directory: " as result "`metadata_dir'"
    noi di as text "  Timestamp: " as result "`synced_at'"
    if ("`suffix'" != "") {
        noi di as text "  Suffix:    " as result "`suffix'"
    }
    noi di as text "{hline 80}"
    
    *---------------------------------------------------------------------------
    * STEP 1: Sync base metadata (dataflows, codelists, countries, regions)
    *---------------------------------------------------------------------------
    
    noi di as text ""
    noi di as text "{hline 80}"
    noi di as result "  STEP 1/4: Syncing base metadata"
    noi di as text "{hline 80}"
    noi di as text "  Components: dataflows, codelists, countries, regions"
    noi di as text ""
    
    capture noisily {
        unicefdata_sync, ///
            dataflows codelists countries regions ///
            path("`metadata_dir'") ///
            `sfx_opt' `verbose_opt' `force_opt'
    }
    
    if (_rc != 0) {
        noi di as err ""
        noi di as err "Step 1 failed with error code: " _rc
        noi di as err "Cannot proceed with remaining steps"
        error _rc
    }
    
    noi di as result "  ✓ Step 1 complete"
    
    *---------------------------------------------------------------------------
    * STEP 2: Build dataflow dimension values
    *---------------------------------------------------------------------------
    
    noi di as text ""
    noi di as text "{hline 80}"
    noi di as result "  STEP 2/4: Building dataflow dimension values"
    noi di as text "{hline 80}"
    noi di as text "  Querying /data/ endpoint for actual dimension values..."
    noi di as text "  This may take 2-5 minutes depending on network speed"
    noi di as text ""
    
    * Locate Python script
    local py_script ""
    local search_paths `"`metadata_dir'/../py" "`metadata_dir'/py" "`:sysdir PLUS'py""'
    
    foreach search_dir of local search_paths {
        if fileexists("`search_dir'/build_dataflow_metadata.py") {
            local py_script "`search_dir'/build_dataflow_metadata.py"
            continue, break
        }
    }
    
    if ("`py_script'" == "") {
        noi di as err "Python script not found: build_dataflow_metadata.py"
        noi di as err "Searched in: `search_paths'"
        noi di as err "Skipping Step 2 - dataflow values will not be updated"
        local step2_skipped 1
    }
    else {
        local verbose_flag ""
        if ("`verbose'" != "") {
            local verbose_flag "--verbose"
        }
        
        capture noisily {
            quietly {
                shell python "`py_script'" --outdir "`metadata_dir'" --agency UNICEF `verbose_flag'
            }
        }
        
        if (_rc != 0) {
            noi di as err ""
            noi di as err "Step 2 failed with error code: " _rc
            noi di as err "Check Python installation and requests/pyyaml packages"
            noi di as err "Continuing with remaining steps..."
            local step2_skipped 1
        }
        else {
            noi di as result "  ✓ Step 2 complete"
            local step2_skipped 0
        }
    }
    
    *---------------------------------------------------------------------------
    * STEP 3: Sync indicators with dataflow enrichment
    *---------------------------------------------------------------------------
    
    noi di as text ""
    noi di as text "{hline 80}"
    noi di as result "  STEP 3/4: Syncing indicators with dataflow enrichment"
    noi di as text "{hline 80}"
    noi di as text "  Fetching indicator codelist and mapping to dataflows..."
    noi di as text ""
    
    capture noisily {
        unicefdata_sync, ///
            indicators enrichdataflows ///
            path("`metadata_dir'") ///
            `sfx_opt' `verbose_opt' `force_opt'
    }
    
    if (_rc != 0) {
        noi di as err ""
        noi di as err "Step 3 failed with error code: " _rc
        noi di as err "Indicator metadata may be incomplete"
        local step3_skipped 1
    }
    else {
        noi di as result "  ✓ Step 3 complete"
        local step3_skipped 0
    }
    
    *---------------------------------------------------------------------------
    * STEP 4: Enrich indicators with dimension values
    *---------------------------------------------------------------------------
    
    noi di as text ""
    noi di as text "{hline 80}"
    noi di as result "  STEP 4/4: Enriching indicators with dimension values"
    noi di as text "{hline 80}"
    noi di as text "  Adding filterable dimension values to each indicator..."
    noi di as text ""
    
    * Locate Python enrichment script
    local enrich_script ""
    foreach search_dir of local search_paths {
        if fileexists("`search_dir'/enrich_indicators_metadata.py") {
            local enrich_script "`search_dir'/enrich_indicators_metadata.py"
            continue, break
        }
    }
    
    if ("`enrich_script'" == "") {
        noi di as err "Python script not found: enrich_indicators_metadata.py"
        noi di as err "Skipping Step 4 - indicator dimension values will not be updated"
        local step4_skipped 1
    }
    else if (`step2_skipped' == 1) {
        noi di as err "Step 2 was skipped - cannot enrich without dataflow metadata"
        noi di as err "Skipping Step 4"
        local step4_skipped 1
    }
    else {
        * Construct file paths with suffix
        local sfx "`suffix'"
        local df_meta_file "_unicefdata_dataflow_metadata`sfx'.yaml"
        local ind_meta_file "_unicefdata_indicators_metadata`sfx'.yaml"
        
        capture noisily {
            quietly {
                shell python "`enrich_script'" ///
                    --dataflow-metadata "`metadata_dir'/`df_meta_file'" ///
                    --indicator-metadata "`metadata_dir'/`ind_meta_file'" ///
                    --output "`metadata_dir'/`ind_meta_file'"
            }
        }
        
        if (_rc != 0) {
            noi di as err ""
            noi di as err "Step 4 failed with error code: " _rc
            noi di as err "Indicator dimension values were not added"
            local step4_skipped 1
        }
        else {
            noi di as result "  ✓ Step 4 complete"
            local step4_skipped 0
        }
    }
    
    *---------------------------------------------------------------------------
    * Summary
    *---------------------------------------------------------------------------
    
    noi di as text ""
    noi di as text "{hline 80}"
    noi di as result "  Metadata Refresh Summary"
    noi di as text "{hline 80}"
    noi di as text "  Step 1 (Base metadata):          " as result "✓ Complete"
    noi di as text "  Step 2 (Dataflow values):        " as result "`=cond(`step2_skipped', "⚠ Skipped", "✓ Complete")'"
    noi di as text "  Step 3 (Indicator enrichment):   " as result "`=cond(`step3_skipped', "⚠ Skipped", "✓ Complete")'"
    noi di as text "  Step 4 (Dimension enrichment):   " as result "`=cond(`step4_skipped', "⚠ Skipped", "✓ Complete")'"
    noi di as text "{hline 80}"
    
    if (`step2_skipped' | `step3_skipped' | `step4_skipped') {
        noi di as err ""
        noi di as err "⚠ Some steps were skipped - metadata may be incomplete"
        noi di as err "  Check error messages above for details"
        noi di as err ""
    }
    else {
        noi di as result ""
        noi di as result "✓ All metadata refreshed successfully"
        noi di as result ""
    }
    
    * Return summary
    return scalar step1_success = 1
    return scalar step2_success = !`step2_skipped'
    return scalar step3_success = !`step3_skipped'
    return scalar step4_success = !`step4_skipped'
    return local synced_at "`synced_at'"
    return local metadata_dir "`metadata_dir'"
    
end

*! v 1.0.0   18Jan2026               by Joao Pedro Azevedo (UNICEF)
* Part of Phase 7.1: Metadata Drift Prevention Infrastructure

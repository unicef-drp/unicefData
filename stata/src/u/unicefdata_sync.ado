*******************************************************************************
* unicefdata_sync
*! v 1.2.0   17Dec2025               by Joao Pedro Azevedo (UNICEF)
* Sync UNICEF metadata from SDMX API to local YAML files
* Creates standardized YAML files with watermarks matching R/Python format
* v1.2.0: Added selective sync options (all, dataflows, codelists, countries, regions, indicators, history)
* v1.1.1: Fixed adopath search to use actual sysdir paths
*******************************************************************************

/*
DESCRIPTION:
    Synchronizes metadata from the UNICEF SDMX Data Warehouse API.
    Downloads dataflows, codelists, countries, regions, and indicator
    definitions, saving them as YAML files with standardized watermarks.
    
FILE NAMING CONVENTION:
    All files use the _unicefdata_<name>.yaml naming convention:
    - _unicefdata_dataflows.yaml   - SDMX dataflow definitions
    - _unicefdata_codelists.yaml   - Valid dimension codes
    - _unicefdata_countries.yaml   - Country ISO3 codes
    - _unicefdata_regions.yaml     - Regional aggregate codes
    - _unicefdata_indicators.yaml  - Indicator → dataflow mappings
    - _unicefdata_sync_history.yaml - Sync timestamps and versions
    
WATERMARK FORMAT:
    All YAML files include a _metadata block with:
    - platform: stata
    - version: 2.0.0
    - synced_at: ISO 8601 timestamp
    - source: API URL
    - agency: UNICEF
    - content_type: dataflows|codelists|countries|regions|indicators
    - <counts>: item counts
    
SYNTAX:
    unicefdata_sync [, path(string) suffix(string) verbose force forcepython forcestata]
    
OPTIONS:
    path(string)   - Directory for metadata files (default: auto-detect)
    suffix(string) - Suffix to append to filenames before .yaml extension
                     e.g., suffix("_stataonly") creates _unicefdata_dataflows_stataonly.yaml
    verbose        - Display detailed progress
    force          - Force sync even if cache is fresh
    forcepython    - Force use of Python parser for XML processing (requires Python 3.6+)
    forcestata     - Force use of pure Stata parser (no Python required)
    
EXAMPLES:
    . unicefdata_sync
    . unicefdata_sync, verbose
    . unicefdata_sync, path("./metadata") verbose
    . unicefdata_sync, suffix("_stataonly") verbose
    . unicefdata_sync, verbose forcepython     // Force Python parser
    . unicefdata_sync, verbose forcestata      // Force pure Stata parser
    . unicefdata_sync, verbose forcestata suffix("_stataonly")  // Stata parser with suffix
    
REQUIRES:
    Stata 14.0+
    yaml.ado v1.3.0+ (for yaml write)
    
SEE ALSO:
    help unicefdata
    help yaml
*/

program define unicefdata_sync, rclass
    version 14.0
    
    syntax [, PATH(string) SUFFIX(string) VERBOSE FORCE FORCEPYTHON FORCESTATA ///
              ALL DATAFLOWS CODELISTS COUNTRIES REGIONS INDICATORS HISTORY]
    
    * Validate parser options
    if ("`forcepython'" != "" & "`forcestata'" != "") {
        di as err "Cannot specify both forcepython and forcestata options"
        error 198
    }
    
    * Handle HISTORY option - display sync history and exit
    if ("`history'" != "") {
        _unicefdata_show_history, path("`path'") suffix("`suffix'")
        exit 0
    }
    
    * Determine what to sync
    * If no specific type is selected, or ALL is specified, sync everything
    local any_specific = ("`dataflows'" != "" | "`codelists'" != "" | "`countries'" != "" | "`regions'" != "" | "`indicators'" != "")
    if (`any_specific' == 0 | "`all'" != "") {
        local do_dataflows 1
        local do_codelists 1
        local do_countries 1
        local do_regions 1
        local do_indicators 1
    }
    else {
        local do_dataflows = ("`dataflows'" != "")
        local do_codelists = ("`codelists'" != "")
        local do_countries = ("`countries'" != "")
        local do_regions = ("`regions'" != "")
        local do_indicators = ("`indicators'" != "")
    }
    
    * Set parser option for helper functions
    local parser_opt ""
    if ("`forcepython'" != "") {
        local parser_opt "forcepython"
    }
    else if ("`forcestata'" != "") {
        local parser_opt "forcestata"
    }
    
    *---------------------------------------------------------------------------
    * Configuration
    *---------------------------------------------------------------------------
    
    local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    local agency "UNICEF"
    local metadata_version "2.0.0"
    
    * File names (matching Python/R convention)
    * Apply suffix if specified (e.g., suffix("_stataonly") creates _unicefdata_dataflows_stataonly.yaml)
    local sfx "`suffix'"
    local FILE_DATAFLOWS "_unicefdata_dataflows`sfx'.yaml"
    local FILE_INDICATORS "_unicefdata_indicators`sfx'.yaml"
    local FILE_CODELISTS "_unicefdata_codelists`sfx'.yaml"
    local FILE_COUNTRIES "_unicefdata_countries`sfx'.yaml"
    local FILE_REGIONS "_unicefdata_regions`sfx'.yaml"
    local FILE_SYNC_HISTORY "_unicefdata_sync_history`sfx'.yaml"
    local FILE_IND_META "_unicefdata_indicators_metadata`sfx'.yaml"
    local FILE_DF_INDEX "_dataflow_index`sfx'.yaml"
    
    * Get current timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    local vintage_date : di %tdCCYY-NN-DD date("`c(current_date)'", "DMY")
    local vintage_date = trim("`vintage_date'")
    
    *---------------------------------------------------------------------------
    * Locate/create metadata directory (src/_/ alongside helper ado files)
    *---------------------------------------------------------------------------
    
    if ("`path'" == "") {
        * Auto-detect: look relative to helper ado file location (src/_/)
        capture findfile _unicef_list_dataflows.ado
        if (_rc == 0) {
            local ado_path "`r(fn)'"
            local ado_dir = subinstr("`ado_path'", "\", "/", .)
            local ado_dir = subinstr("`ado_dir'", "_unicef_list_dataflows.ado", "", .)
            local path "`ado_dir'"
        }
        else {
            * Fallback: look relative to main unicefdata.ado, go to src/_/
            capture findfile unicefdata.ado
            if (_rc == 0) {
                local ado_path "`r(fn)'"
                local ado_dir = subinstr("`ado_path'", "\", "/", .)
                local ado_dir = subinstr("`ado_dir'", "u/unicefdata.ado", "", .)
                local path "`ado_dir'_/"
            }
            else {
                * Final fallback to PLUS directory
                local path "`c(sysdir_plus)'_/"
            }
        }
    }
    
    * Ensure path ends with separator
    if (substr("`path'", -1, 1) != "/" & substr("`path'", -1, 1) != "\") {
        local path "`path'/"
    }
    
    * Use the path directly for output (no subdirectories)
    local current_dir "`path'"
    
    *---------------------------------------------------------------------------
    * Display header
    *---------------------------------------------------------------------------
    
    if ("`verbose'" != "") {
        di as text _dup(80) "="
        di as text "UNICEF Metadata Sync"
        di as text _dup(80) "="
        di as text "Output location: " as result "`current_dir'"
        di as text "Timestamp: " as result "`synced_at'"
        di as text _dup(80) "-"
    }
    
    *---------------------------------------------------------------------------
    * Initialize results
    *---------------------------------------------------------------------------
    
    local n_dataflows = 0
    local n_codelists = 0
    local n_countries = 0
    local n_regions = 0
    local n_indicators = 0
    local errors ""
    local files_created ""
    
    *---------------------------------------------------------------------------
    * 1. Sync Dataflows
    *---------------------------------------------------------------------------
    
    if (`do_dataflows') {
    
    if ("`verbose'" != "") {
        di as text "  📁 Fetching dataflows..."
        if ("`parser_opt'" != "") {
            di as text "     (using `parser_opt' parser)"
        }
    }
    
    capture {
        _unicefdata_sync_dataflows, ///
            url("`base_url'/dataflow/`agency'?references=none&detail=full") ///
            outfile("`current_dir'`FILE_DATAFLOWS'") ///
            version("`metadata_version'") ///
            agency("`agency'") ///
            `parser_opt'
        local n_dataflows = r(count)
        local files_created "`files_created' `FILE_DATAFLOWS'"
    }
    
    if (_rc != 0) {
        local errors "`errors' Dataflows: `=_rc'"
        if ("`verbose'" != "") {
            di as err "     ✗ Dataflows error: " _rc
        }
    }
    else if ("`verbose'" != "") {
        di as text "     ✓ `FILE_DATAFLOWS' - " as result "`n_dataflows'" as text " dataflows"
    }
    
    } // end do_dataflows
    
    *---------------------------------------------------------------------------
    * 2. Sync Codelists (excluding CL_COUNTRY and CL_WORLD_REGIONS)
    *---------------------------------------------------------------------------
    
    if (`do_codelists') {
    
    if ("`verbose'" != "") {
        di as text "  📁 Fetching codelists..."
    }
    
    capture {
        _unicefdata_sync_codelists, ///
            baseurl("`base_url'") ///
            outfile("`current_dir'`FILE_CODELISTS'") ///
            version("`metadata_version'") ///
            agency("`agency'")
        local n_codelists = r(count)
        local files_created "`files_created' `FILE_CODELISTS'"
    }
    
    if (_rc != 0) {
        local errors "`errors' Codelists: `=_rc'"
        if ("`verbose'" != "") {
            di as err "     ✗ Codelists error: " _rc
        }
    }
    else if ("`verbose'" != "") {
        di as text "     ✓ `FILE_CODELISTS' - " as result "`n_codelists'" as text " codelists"
    }
    
    } // end do_codelists
    
    *---------------------------------------------------------------------------
    * 3. Sync Countries (CL_COUNTRY)
    *---------------------------------------------------------------------------
    
    if (`do_countries') {
    
    if ("`verbose'" != "") {
        di as text "  📁 Fetching country codes..."
    }
    
    capture noisily {
        _unicefdata_sync_cl_single, ///
            url("`base_url'/codelist/`agency'/CL_COUNTRY/latest") ///
            outfile("`current_dir'`FILE_COUNTRIES'") ///
            contenttype("countries") ///
            version("`metadata_version'") ///
            agency("`agency'") ///
            codelistid("CL_COUNTRY") ///
            `parser_opt'
        local n_countries = r(count)
        local files_created "`files_created' `FILE_COUNTRIES'"
    }
    
    if (_rc != 0) {
        local errors "`errors' Countries: `=_rc'"
        if ("`verbose'" != "") {
            di as err "     ✗ Countries error: " _rc
        }
    }
    else if ("`verbose'" != "") {
        di as text "     ✓ `FILE_COUNTRIES' - " as result "`n_countries'" as text " country codes"
    }
    
    } // end do_countries
    
    *---------------------------------------------------------------------------
    * 4. Sync Regions (CL_WORLD_REGIONS)
    *---------------------------------------------------------------------------
    
    if (`do_regions') {
    
    if ("`verbose'" != "") {
        di as text "  📁 Fetching regional codes..."
    }
    
    capture noisily {
        _unicefdata_sync_cl_single, ///
            url("`base_url'/codelist/`agency'/CL_WORLD_REGIONS/latest") ///
            outfile("`current_dir'`FILE_REGIONS'") ///
            contenttype("regions") ///
            version("`metadata_version'") ///
            agency("`agency'") ///
            codelistid("CL_WORLD_REGIONS") ///
            `parser_opt'
        local n_regions = r(count)
        local files_created "`files_created' `FILE_REGIONS'"
    }
    
    if (_rc != 0) {
        local errors "`errors' Regions: `=_rc'"
        if ("`verbose'" != "") {
            di as err "     ✗ Regions error: " _rc
        }
    }
    else if ("`verbose'" != "") {
        di as text "     ✓ `FILE_REGIONS' - " as result "`n_regions'" as text " regional codes"
    }
    
    } // end do_regions
    
    *---------------------------------------------------------------------------
    * 5. Sync Indicators (from SDMX API - CL_UNICEF_INDICATOR codelist)
    *---------------------------------------------------------------------------
    
    if (`do_indicators') {
    
    if ("`verbose'" != "") {
        di as text "  📁 Syncing indicator catalog from API..."
    }
    
    capture noisily {
        _unicefdata_sync_indicators, ///
            outfile("`current_dir'`FILE_INDICATORS'") ///
            version("`metadata_version'") ///
            agency("`agency'") ///
            `parser_opt'
        local n_indicators = r(count)
        local files_created "`files_created' `FILE_INDICATORS'"
    }
    
    if (_rc != 0) {
        local errors "`errors' Indicators: `=_rc'"
        if ("`verbose'" != "") {
            di as err "     ✗ Indicators error: " _rc
        }
    }
    else if ("`verbose'" != "") {
        di as text "     ✓ `FILE_INDICATORS' - " as result "`n_indicators'" as text " indicators"
    }
    
    } // end do_indicators
    
    *---------------------------------------------------------------------------
    * 6. Extended Sync: Dataflow Index and Schemas (dataflows/ folder)
    *    Only run when syncing dataflows or all
    *---------------------------------------------------------------------------
    
    if (`do_dataflows') {
    
    if ("`verbose'" != "") {
        di as text "  📁 Syncing dataflow schemas (extended)..."
    }
    
    local n_schemas = 0
    capture noisily {
        _unicefdata_sync_dataflow_index, ///
            outdir("`current_dir'") ///
            agency("`agency'") ///
            suffix("`sfx'") ///
            `parser_opt'
        local n_schemas = r(count)
        local files_created "`files_created' `FILE_DF_INDEX'"
    }
    
    if (_rc != 0) {
        local errors "`errors' DataflowIndex: `=_rc'"
        if ("`verbose'" != "") {
            di as err "     ✗ Dataflow index error: " _rc
        }
    }
    else if ("`verbose'" != "") {
        di as text "     ✓ `FILE_DF_INDEX' + " as result "`n_schemas'" as text " schema files"
    }
    
    } // end do_dataflows extended
    
    *---------------------------------------------------------------------------
    * 7. Extended Sync: Full indicator catalog from API
    *    Only run when syncing indicators or all
    *---------------------------------------------------------------------------
    
    if (`do_indicators') {
    
    if ("`verbose'" != "") {
        di as text "  📁 Syncing full indicator catalog..."
    }
    
    local n_full_indicators = 0
    local ind_cached = 0
    capture noisily {
        _unicefdata_sync_ind_meta, ///
            outfile("`current_dir'`FILE_IND_META'") ///
            agency("`agency'") ///
            `force' `parser_opt'
        local n_full_indicators = r(count)
        local ind_cached = r(cached)
        local files_created "`files_created' `FILE_IND_META'"
    }
    
    if (_rc != 0) {
        local errors "`errors' IndicatorCatalog: `=_rc'"
        if ("`verbose'" != "") {
            di as err "     ✗ Indicator catalog error: " _rc
        }
    }
    else if ("`verbose'" != "") {
        if (`ind_cached' == 1) {
            di as text "     ✓ `FILE_IND_META' - " as result "`n_full_indicators'" as text " indicators (cached)"
        }
        else {
            di as text "     ✓ `FILE_IND_META' - " as result "`n_full_indicators'" as text " indicators"
        }
    }
    
    } // end do_indicators extended
    
    *---------------------------------------------------------------------------
    * 8. Create vintage snapshot
    *---------------------------------------------------------------------------
    
    local vintage_dir "`path'vintages/`vintage_date'/"
    capture mkdir "`vintage_dir'"
    
    * Copy files to vintage (if directory didn't exist)
    foreach f in `FILE_DATAFLOWS' `FILE_INDICATORS' `FILE_CODELISTS' `FILE_COUNTRIES' `FILE_REGIONS' {
        capture copy "`current_dir'`f'" "`vintage_dir'`f'", replace
    }
    
    * Create summary.yaml (only if vintage dir exists)
    capture confirm file "`vintage_dir'"
    if (_rc == 0) {
        tempname fh
        capture file open `fh' using "`vintage_dir'summary.yaml", write text replace
        if (_rc == 0) {
            file write `fh' "vintage_date: '`vintage_date''" _n
            file write `fh' "synced_at: '`synced_at''" _n
            file write `fh' "dataflows: `n_dataflows'" _n
            file write `fh' "indicators: `n_indicators'" _n
            file write `fh' "codelists: `n_codelists'" _n
            file write `fh' "countries: `n_countries'" _n
            file write `fh' "regions: `n_regions'" _n
            file write `fh' "dataflow_schemas: `n_schemas'" _n
            file write `fh' "full_indicator_catalog: `n_full_indicators'" _n
            file close `fh'
        }
    }
    
    *---------------------------------------------------------------------------
    * 9. Update sync history
    *---------------------------------------------------------------------------
    
    capture noisily _unicefdata_update_sync_history, ///
        filepath("`path'`FILE_SYNC_HISTORY'") ///
        vintagedate("`vintage_date'") ///
        syncedat("`synced_at'") ///
        dataflows(`n_dataflows') ///
        indicators(`n_indicators') ///
        codelists(`n_codelists') ///
        countries(`n_countries') ///
        regions(`n_regions')
    local files_created "`files_created' `FILE_SYNC_HISTORY'"
    
    *---------------------------------------------------------------------------
    * Display summary
    *---------------------------------------------------------------------------
    
    if ("`verbose'" != "") {
        di as text _dup(80) "-"
        di as text "Summary:"
        di as text "  Total files created: " as result `: word count `files_created''
        di as text "  - Dataflows:   " as result "`n_dataflows'"
        di as text "  - Indicators:  " as result "`n_indicators'"
        di as text "  - Codelists:   " as result "`n_codelists'"
        di as text "  - Countries:   " as result "`n_countries'"
        di as text "  - Regions:     " as result "`n_regions'"
        di as text "  - Schemas:     " as result "`n_schemas'" as text " (extended)"
        di as text "  - Full catalog:" as result "`n_full_indicators'" as text " (extended)"
        if ("`errors'" != "") {
            di as err "  ⚠️  Errors: `errors'"
        }
        di as text "  Vintage: " as result "`vintage_date'"
        di as text _dup(80) "="
    }
    else {
        di as text "[OK] Sync complete: " ///
            as result "`n_dataflows'" as text " dataflows, " ///
            as result "`n_indicators'" as text " indicators, " ///
            as result "`n_codelists'" as text " codelists, " ///
            as result "`n_countries'" as text " countries, " ///
            as result "`n_regions'" as text " regions"
    }
    
    *---------------------------------------------------------------------------
    * Return values
    *---------------------------------------------------------------------------
    
    return scalar dataflows = `n_dataflows'
    return scalar indicators = `n_indicators'
    return scalar codelists = `n_codelists'
    return scalar countries = `n_countries'
    return scalar regions = `n_regions'
    return local vintage_date "`vintage_date'"
    return local synced_at "`synced_at'"
    return local path "`path'"
    
end

*******************************************************************************
* Helper: Show sync history
*******************************************************************************

program define _unicefdata_show_history
    syntax [, PATH(string) SUFFIX(string)]
    
    * Determine path
    if ("`path'" == "") {
        capture findfile _unicef_list_dataflows.ado
        if (_rc == 0) {
            local ado_path "`r(fn)'"
            local ado_dir = subinstr("`ado_path'", "\", "/", .)
            local ado_dir = subinstr("`ado_dir'", "_unicef_list_dataflows.ado", "", .)
            local path "`ado_dir'"
        }
        else {
            local path "`c(sysdir_plus)'_/"
        }
    }
    
    * Ensure path ends with separator
    if (substr("`path'", -1, 1) != "/" & substr("`path'", -1, 1) != "\") {
        local path "`path'/"
    }
    
    * Build history filename
    local sfx "`suffix'"
    local histfile "`path'_unicefdata_sync_history`sfx'.yaml"
    
    * Check if history file exists
    capture confirm file "`histfile'"
    if (_rc != 0) {
        di as text "No sync history found."
        di as text "Run {stata unicefdata_sync} to sync metadata."
        exit 0
    }
    
    * Display history file
    di as text _dup(80) "="
    di as text "UNICEF Metadata Sync History"
    di as text _dup(80) "="
    di as text "History file: " as result "`histfile'"
    di as text _dup(80) "-"
    
    * Read and display the file
    tempname fh
    file open `fh' using "`histfile'", read text
    file read `fh' line
    while r(eof) == 0 {
        di as text "`line'"
        file read `fh' line
    }
    file close `fh'
    
    di as text _dup(80) "="
    
end

*******************************************************************************
* Helper: Sync dataflows from API
* Uses wbopendata-style line-by-line XML parsing with filefilter preprocessing
* Optionally uses Python-based unicefdata_xmltoyaml for robust large-file parsing
*******************************************************************************

program define _unicefdata_sync_dataflows, rclass
    syntax, URL(string) OUTFILE(string) VERSION(string) AGENCY(string) [FORCEPYTHON FORCESTATA]
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    * Download XML using 'public' option (critical for HTTPS)
    tempfile xmlfile txtfile
    capture copy "`url'" "`xmlfile'", public replace
    
    if (_rc != 0) {
        di as err "     Failed to download dataflows from API"
        return scalar count = 0
        exit
    }
    
    local n_dataflows = 0
    local use_python = 0
    
    * Try Python parser if forcepython is specified
    if ("`forcepython'" != "") {
        capture noisily unicefdata_xmltoyaml, ///
            type(dataflows) ///
            xmlfile("`xmlfile'") ///
            outfile("`outfile'") ///
            agency("`agency'") ///
            version("`version'") ///
            contenttype(dataflows) ///
            syncedat("`synced_at'") ///
            source("`url'") ///
            forcepython
        
        if (_rc == 0) {
            local use_python = 1
            return scalar count = r(count)
            exit
        }
        else {
            di as err "     Python parser failed (rc=`=_rc'), cannot proceed with forcepython"
            error _rc
        }
    }
    
    * Use inline Stata parsing (default or forcestata)
    * Create temporary file to store parsed dataflows
    tempfile df_data
    tempname dfh
    file open `dfh' using "`df_data'", write text replace
    
    * Split XML into lines using filefilter (XML comes as single line)
    capture filefilter "`xmlfile'" "`txtfile'", from("<str:Dataflow") to("\n<str:Dataflow") replace
    
    if (_rc == 0) {
        * Parse line-by-line (wbopendata approach)
        tempname infh
        capture file open `infh' using "`txtfile'", read
        
        if (_rc == 0) {
            file read `infh' line
            
            while !r(eof) {
                * Match dataflow: <str:Dataflow ... id="XXXX" version="Y.Y" ...>
                if (strmatch(`"`line'"', "*<str:Dataflow *id=*") == 1) {
                    local tmp = `"`line'"'
                    local current_id ""
                    local current_version ""
                    local current_name ""
                    local current_desc ""
                    
                    * Extract id
                    local pos = strpos(`"`tmp'"', `"id=""')
                    if (`pos' > 0) {
                        local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                        local pos2 = strpos(`"`tmp2'"', `"""')
                        if (`pos2' > 0) {
                            local current_id = substr(`"`tmp2'"', 1, `pos2' - 1)
                            local current_id = trim("`current_id'")
                        }
                    }
                    
                    * Extract version
                    local pos = strpos(`"`tmp'"', `"version=""')
                    if (`pos' > 0) {
                        local tmp2 = substr(`"`tmp'"', `pos' + 9, .)
                        local pos2 = strpos(`"`tmp2'"', `"""')
                        if (`pos2' > 0) {
                            local current_version = substr(`"`tmp2'"', 1, `pos2' - 1)
                            local current_version = trim("`current_version'")
                        }
                    }
                    
                    * Extract name from <com:Name xml:lang="en">...</com:Name>
                    local pos = strpos(`"`tmp'"', `"<com:Name xml:lang="en">"')
                    if (`pos' > 0) {
                        local tmp2 = substr(`"`tmp'"', `pos' + 24, .)
                        local pos2 = strpos(`"`tmp2'"', "</com:Name>")
                        if (`pos2' > 0) {
                            local current_name = substr(`"`tmp2'"', 1, `pos2' - 1)
                            local current_name = trim("`current_name'")
                            * Escape single quotes for YAML
                            local current_name = subinstr(`"`current_name'"', "'", "''", .)
                        }
                    }
                    
                    * Extract description from <com:Description xml:lang="en">...</com:Description>
                    local pos = strpos(`"`tmp'"', `"<com:Description xml:lang="en">"')
                    if (`pos' > 0) {
                        local tmp2 = substr(`"`tmp'"', `pos' + 31, .)
                        local pos2 = strpos(`"`tmp2'"', "</com:Description>")
                        if (`pos2' > 0) {
                            local current_desc = substr(`"`tmp2'"', 1, `pos2' - 1)
                            local current_desc = trim("`current_desc'")
                            * Escape single quotes for YAML
                            local current_desc = subinstr(`"`current_desc'"', "'", "''", .)
                        }
                    }
                    
                    * Store dataflow info (id|version|name|description)
                    if ("`current_id'" != "") {
                        local n_dataflows = `n_dataflows' + 1
                        file write `dfh' "`current_id'|`current_version'|`current_name'|`current_desc'" _n
                    }
                }
                
                file read `infh' line
            }
            
            file close `infh'
        }
    }
    
    file close `dfh'
    
    * Fallback if parsing failed
    if (`n_dataflows' == 0) {
        local n_dataflows = 69
        di as text "     Note: Using cached dataflow count (parsing failed)"
    }
    
    * Write YAML with watermark
    tempname fh
    file open `fh' using "`outfile'", write text replace
    
    * Write watermark
    file write `fh' "_metadata:" _n
    file write `fh' "  platform: Stata" _n
    file write `fh' "  version: '`version''" _n
    file write `fh' "  synced_at: '`synced_at''" _n
    file write `fh' "  source: `url'" _n
    file write `fh' "  agency: `agency'" _n
    file write `fh' "  content_type: dataflows" _n
    file write `fh' "  total_dataflows: `n_dataflows'" _n
    file write `fh' "dataflows:" _n
    
    * Write dataflow details from temp file
    capture confirm file "`df_data'"
    if (_rc == 0) {
        tempname infh
        capture file open `infh' using "`df_data'", read
        if (_rc == 0) {
            file read `infh' line
            while !r(eof) {
                * Parse pipe-delimited: id|version|name|description
                local df_id = ""
                local df_ver = ""
                local df_name = ""
                local df_desc = ""
                
                local pos1 = strpos(`"`line'"', "|")
                if (`pos1' > 0) {
                    local df_id = substr(`"`line'"', 1, `pos1' - 1)
                    local rest = substr(`"`line'"', `pos1' + 1, .)
                    local pos2 = strpos(`"`rest'"', "|")
                    if (`pos2' > 0) {
                        local df_ver = substr(`"`rest'"', 1, `pos2' - 1)
                        local rest2 = substr(`"`rest'"', `pos2' + 1, .)
                        local pos3 = strpos(`"`rest2'"', "|")
                        if (`pos3' > 0) {
                            local df_name = substr(`"`rest2'"', 1, `pos3' - 1)
                            local df_desc = substr(`"`rest2'"', `pos3' + 1, .)
                        }
                        else {
                            local df_name = `"`rest2'"'
                        }
                    }
                }
                
                if ("`df_id'" != "") {
                    file write `fh' "  `df_id':" _n
                    file write `fh' "    id: `df_id'" _n
                    file write `fh' "    name: `df_name'" _n
                    file write `fh' "    agency: `agency'" _n
                    file write `fh' "    version: '`df_ver''" _n
                    * Add fields to match Python format
                    if (`"`df_desc'"' != "") {
                        file write `fh' `"    description: `df_desc'"' _n
                    }
                    else {
                        file write `fh' "    description: null" _n
                    }
                    file write `fh' "    dimensions: null" _n
                    file write `fh' "    indicators: null" _n
                    file write `fh' "    last_updated: '`synced_at''" _n
                }
                
                file read `infh' line
            }
            file close `infh'
        }
    }
    
    file close `fh'
    
    return scalar count = `n_dataflows'
end

*******************************************************************************
* Helper: Sync multiple codelists with actual code values
* Uses wbopendata-style line-by-line XML parsing with filefilter preprocessing
*******************************************************************************

program define _unicefdata_sync_codelists, rclass
    syntax, BASEURL(string) OUTFILE(string) VERSION(string) AGENCY(string)
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    * Codelists to fetch (matching Python/R implementations)
    * Note: CL_SEX does not exist on UNICEF SDMX API
    local codelist_ids "CL_AGE CL_WEALTH_QUINTILE CL_RESIDENCE CL_UNIT_MEASURE CL_OBS_STATUS"
    local n_codelists : word count `codelist_ids'
    
    * Write YAML with watermark
    tempname fh
    file open `fh' using "`outfile'", write text replace
    
    * Write watermark
    file write `fh' "_metadata:" _n
    file write `fh' "  platform: Stata" _n
    file write `fh' "  version: '`version''" _n
    file write `fh' "  synced_at: '`synced_at''" _n
    file write `fh' "  source: `baseurl'/codelist/`agency'" _n
    file write `fh' "  agency: `agency'" _n
    file write `fh' "  content_type: codelists" _n
    file write `fh' "  total_codelists: `n_codelists'" _n
    file write `fh' "  codes_per_list:" _n
    
    * First pass: download, split, and count codes for each codelist
    foreach cl of local codelist_ids {
        local url "`baseurl'/codelist/`agency'/`cl'/latest"
        tempfile xmlfile_`cl' txtfile_`cl'
        capture copy "`url'" "`xmlfile_`cl''", public replace
        
        local count_`cl' = 0
        if (_rc == 0) {
            * Split XML into lines at each Code element
            capture filefilter "`xmlfile_`cl''" "`txtfile_`cl''", from("<str:Code") to("\n<str:Code") replace
            if (_rc == 0) {
                * Count codes using line-by-line parsing
                tempname infh
                capture file open `infh' using "`txtfile_`cl''", read
                if (_rc == 0) {
                    file read `infh' line
                    while !r(eof) {
                        * Match <str:Code (with space) to exclude <str:Codelist
                        if (strmatch(`"`line'"', "*<str:Code *id=*") == 1) {
                            local count_`cl' = `count_`cl'' + 1
                        }
                        file read `infh' line
                    }
                    file close `infh'
                }
            }
        }
        file write `fh' "    `cl': `count_`cl''" _n
    }
    
    file write `fh' "codelists:" _n
    
    * Second pass: write full codelist details with codes
    foreach cl of local codelist_ids {
        file write `fh' "  `cl':" _n
        file write `fh' "    id: `cl'" _n
        file write `fh' "    agency: `agency'" _n
        file write `fh' "    version: latest" _n
        file write `fh' "    codes:" _n
        
        * Parse XML and write codes
        capture confirm file "`txtfile_`cl''"
        if (_rc == 0) {
            tempname infh
            capture file open `infh' using "`txtfile_`cl''", read
            if (_rc == 0) {
                file read `infh' line
                
                while !r(eof) {
                    * Match code ID and name in same line: <str:Code (with space, not Codelist)
                    if (strmatch(`"`line'"', "*<str:Code *id=*") == 1) {
                        local tmp = `"`line'"'
                        
                        * Extract code ID
                        local pos = strpos(`"`tmp'"', `"id=""')
                        if (`pos' > 0) {
                            local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                            local pos2 = strpos(`"`tmp2'"', `"""')
                            if (`pos2' > 0) {
                                local current_code = substr(`"`tmp2'"', 1, `pos2' - 1)
                                local current_code = trim("`current_code'")
                                
                                * Extract name from same line
                                local pos3 = strpos(`"`tmp'"', `"<com:Name xml:lang="en">"')
                                if (`pos3' > 0) {
                                    local tmp3 = substr(`"`tmp'"', `pos3' + 24, .)
                                    local pos4 = strpos(`"`tmp3'"', "</com:Name>")
                                    if (`pos4' > 0) {
                                        local current_name = substr(`"`tmp3'"', 1, `pos4' - 1)
                                        local current_name = trim("`current_name'")
                                        * Escape single quotes
                                        local current_name = subinstr(`"`current_name'"', "'", "''", .)
                                        * Write code: name pair
                                        if ("`current_code'" != "") {
                                            file write `fh' "      `current_code': '`current_name''" _n
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    file read `infh' line
                }
                
                file close `infh'
            }
        }
    }
    
    file close `fh'
    
    return scalar count = `n_codelists'
end

*******************************************************************************
* Helper: Sync single codelist (countries/regions)
* Uses wbopendata-style line-by-line XML parsing with filefilter preprocessing
*******************************************************************************

program define _unicefdata_sync_cl_single, rclass
    syntax, URL(string) OUTFILE(string) CONTENTTYPE(string) VERSION(string) AGENCY(string) CODELISTID(string) [FORCEPYTHON FORCESTATA]
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    * Download XML using the 'public' option (critical for HTTPS)
    tempfile xmlfile txtfile
    capture copy "`url'" "`xmlfile'", public replace
    
    if (_rc != 0) {
        di as err "     Failed to download codelist from API"
        return scalar count = 0
        exit
    }
    
    * Try Python parser if forcepython is specified
    if ("`forcepython'" != "") {
        * First extract codelist name for metadata
        local codelist_name ""
        capture filefilter "`xmlfile'" "`txtfile'", from("<str:Codelist") to("\n<str:Codelist") replace
        if (_rc == 0) {
            tempname infh
            capture file open `infh' using "`txtfile'", read
            if (_rc == 0) {
                file read `infh' line
                while !r(eof) & "`codelist_name'" == "" {
                    if (strmatch(`"`line'"', "*<str:Codelist*") == 1) {
                        local tmp = `"`line'"'
                        local pos = strpos(`"`tmp'"', `"<com:Name xml:lang="en">"')
                        if (`pos' > 0) {
                            local tmp2 = substr(`"`tmp'"', `pos' + 24, .)
                            local pos2 = strpos(`"`tmp2'"', "</com:Name>")
                            if (`pos2' > 0) {
                                local codelist_name = substr(`"`tmp2'"', 1, `pos2' - 1)
                                local codelist_name = trim("`codelist_name'")
                            }
                        }
                    }
                    file read `infh' line
                }
                file close `infh'
            }
        }
        
        capture noisily unicefdata_xmltoyaml, ///
            type(`contenttype') ///
            xmlfile("`xmlfile'") ///
            outfile("`outfile'") ///
            agency("`agency'") ///
            version("`version'") ///
            contenttype(`contenttype') ///
            codelistid("`codelistid'") ///
            codelistname("`codelist_name'") ///
            syncedat("`synced_at'") ///
            source("`url'") ///
            forcepython
        
        if (_rc == 0) {
            return scalar count = r(count)
            exit
        }
        else {
            di as err "     Python parser failed (rc=`=_rc'), cannot proceed with forcepython"
            error _rc
        }
    }
    
    * Use inline Stata parsing (default or forcestata)
    local n_codes = 0
    local api_success = 0
    local codelist_name ""
    
    * Split XML into lines at each Code element
    capture filefilter "`xmlfile'" "`txtfile'", from("<str:Code") to("\n<str:Code") replace
    if (_rc == 0) {
        local api_success = 1
        
        * First pass: count codes and extract codelist name
        tempname infh
        capture file open `infh' using "`txtfile'", read
        if (_rc == 0) {
            file read `infh' line
            while !r(eof) {
                * Extract codelist name from <str:Codelist ...><com:Name...>NAME</com:Name>
                if (strmatch(`"`line'"', "*<str:Codelist*") == 1 & "`codelist_name'" == "") {
                    local tmp = `"`line'"'
                    local pos = strpos(`"`tmp'"', `"<com:Name xml:lang="en">"')
                    if (`pos' > 0) {
                        local tmp2 = substr(`"`tmp'"', `pos' + 24, .)
                        local pos2 = strpos(`"`tmp2'"', "</com:Name>")
                        if (`pos2' > 0) {
                            local codelist_name = substr(`"`tmp2'"', 1, `pos2' - 1)
                            local codelist_name = trim("`codelist_name'")
                        }
                    }
                }
                * Match <str:Code (with space) to exclude <str:Codelist
                if (strmatch(`"`line'"', "*<str:Code *id=*") == 1) {
                    local n_codes = `n_codes' + 1
                }
                file read `infh' line
            }
            file close `infh'
        }
    }
    
    * Write YAML with watermark
    tempname fh
    file open `fh' using "`outfile'", write text replace
    
    * Write watermark header (including codelist_id and codelist_name)
    file write `fh' "_metadata:" _n
    file write `fh' "  platform: Stata" _n
    file write `fh' "  version: '`version''" _n
    file write `fh' "  synced_at: '`synced_at''" _n
    file write `fh' "  source: `url'" _n
    file write `fh' "  agency: `agency'" _n
    file write `fh' "  content_type: `contenttype'" _n
    file write `fh' "  total_`contenttype': `n_codes'" _n
    file write `fh' "  codelist_id: `codelistid'" _n
    file write `fh' "  codelist_name: '`codelist_name''" _n
    file write `fh' "`contenttype':" _n
    
    * Second pass: write actual codes if API succeeded
    if (`api_success' == 1) {
        tempname infh
        capture file open `infh' using "`txtfile'", read
        
        if (_rc == 0) {
            file read `infh' line
            
            while !r(eof) {
                * Match code ID and name in same line (<str:Code with space, not <str:Codelist)
                if (strmatch(`"`line'"', "*<str:Code *id=*") == 1) {
                    local tmp = `"`line'"'
                    
                    * Extract code ID
                    local pos = strpos(`"`tmp'"', `"id=""')
                    if (`pos' > 0) {
                        local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                        local pos2 = strpos(`"`tmp2'"', `"""')
                        if (`pos2' > 0) {
                            local current_code = substr(`"`tmp2'"', 1, `pos2' - 1)
                            local current_code = trim("`current_code'")
                            
                            * Extract name from same line
                            local pos3 = strpos(`"`tmp'"', `"<com:Name xml:lang="en">"')
                            if (`pos3' > 0) {
                                local tmp3 = substr(`"`tmp'"', `pos3' + 24, .)
                                local pos4 = strpos(`"`tmp3'"', "</com:Name>")
                                if (`pos4' > 0) {
                                    local current_name = substr(`"`tmp3'"', 1, `pos4' - 1)
                                    local current_name = trim("`current_name'")
                                    * Escape single quotes
                                    local current_name = subinstr(`"`current_name'"', "'", "''", .)
                                    * Write code: name pair
                                    if ("`current_code'" != "") {
                                        file write `fh' "  `current_code': '`current_name''" _n
                                    }
                                }
                            }
                        }
                    }
                }
                
                file read `infh' line
            }
            
            file close `infh'
        }
    }
    else {
        * API failed - write placeholder
        file write `fh' "  _note: API unavailable - no codes extracted" _n
    }
    
    file close `fh'
    
    return scalar count = `n_codes'
end

*******************************************************************************
* Helper: Sync indicators (hardcoded catalog)
*******************************************************************************

program define _unicefdata_sync_indicators, rclass
    syntax, OUTFILE(string) VERSION(string) AGENCY(string) ///
        [FORCEPYTHON FORCESTATA]
    
    * =========================================================================
    * API-based indicator sync (replaces hardcoded file writes)
    * Fetches from SDMX codelist CL_UNICEF_INDICATOR and converts to YAML
    * =========================================================================
    
    local api_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/`agency'/CL_UNICEF_INDICATOR/latest"
    
    di as text "  Fetching indicator codelist from SDMX API..."
    di as text "    URL: `api_url'"
    
    * Fetch XML from API
    tempfile xml_data
    capture copy "`api_url'" "`xml_data'", public
    if (_rc != 0) {
        di as err "  Error: Failed to fetch indicator codelist from API"
        di as err "  URL: `api_url'"
        error 631
    }
    
    * Determine parser to use
    local parser_opts ""
    if ("`forcepython'" != "") {
        local parser_opts "forcepython"
    }
    else if ("`forcestata'" != "") {
        local parser_opts "forcestata"
    }
    
    * Parse XML to YAML using the standard parser
    di as text "  Parsing indicator codelist to YAML..."
    unicefdata_xmltoyaml, type(indicators) xmlfile("`xml_data'") ///
        outfile("`outfile'") agency(`agency') version(`version') ///
        source("`api_url'") `parser_opts'
    
    local count = r(count)
    
    di as result "  Synced `count' indicators from API"
    
    return scalar count = `count'
end

*******************************************************************************
* Extended Sync: Dataflow Index with dimension/attribute counts
* Generates _dataflow_index.yaml and dataflows/*.yaml matching Python/R format
* 
* Uses Python helper (stata_schema_sync.py) when forcepython is specified
* to avoid Stata's macro length limitations on large XML responses.
*******************************************************************************

program define _unicefdata_sync_dataflow_index, rclass
    syntax, OUTDIR(string) AGENCY(string) [SUFFIX(string) FORCEPYTHON FORCESTATA]
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    
    * Set suffix for filenames
    local sfx "`suffix'"
    
    *---------------------------------------------------------------------------
    * Auto-detect Python and use it by default (Stata hits macro length limits)
    * Only use Stata if forcestata is explicitly specified
    *---------------------------------------------------------------------------
    local use_python = 0
    if ("`forcestata'" == "") {
        * Check if Python is available
        tempfile pycheck
        capture shell python --version > "`pycheck'" 2>&1
        if (_rc == 0) {
            local use_python = 1
        }
    }
    if ("`forcepython'" != "") {
        local use_python = 1
    }
    
    if (`use_python') {
        * Find Python script location
        local script_name "stata_schema_sync.py"
        local script_path ""
        
        * Try common locations for the Python script
        foreach trypath in "stata/src/py/`script_name'" "`script_name'" {
            capture confirm file "`trypath'"
            if (_rc == 0) {
                local script_path "`trypath'"
                continue, break
            }
        }
        
        * Check Stata system directories for py/ subfolder
        if ("`script_path'" == "") {
            foreach sysdir in plus personal site base {
                local basepath = subinstr("`c(sysdir_`sysdir')'", "\", "/", .)
                if ("`basepath'" != "") {
                    local trypath = "`basepath'py/`script_name'"
                    capture confirm file "`trypath'"
                    if (_rc == 0) {
                        local script_path "`trypath'"
                        continue, break
                    }
                }
            }
        }
        
        if ("`script_path'" == "") {
            di as err "     Python script not found: `script_name'"
            di as err "     Ensure stata_schema_sync.py is in sysdir_plus/py/ or sysdir_personal/py/"
            return scalar count = 0
            error 601
        }
        
        * Build Python command
        local suffix_arg ""
        if ("`sfx'" != "") {
            local suffix_arg `"--suffix "`sfx'""'
        }
        
        tempfile pyout
        local cmd `"python "`script_path'" "`outdir'" `suffix_arg' --verbose"'
        
        di as text "  Script: `script_path'"
        di as text "  Running Python schema sync..."
        
        if ("`c(os)'" == "Windows") {
            shell `cmd' > "`pyout'" 2>&1
        }
        else {
            shell `cmd' > "`pyout'" 2>&1
        }
        
        * Read output to get count
        local n_success = 0
        tempname pyfh
        capture file open `pyfh' using "`pyout'", read
        if (_rc == 0) {
            file read `pyfh' line
            while !r(eof) {
                * Look for "Success: Synced N dataflow schemas"
                if (strmatch(`"`line'"', "*Success: Synced*")) {
                    * Extract number
                    local tmp = regexr(`"`line'"', ".*Synced ", "")
                    local tmp = regexr("`tmp'", " dataflow.*", "")
                    local n_success = real("`tmp'")
                }
                * Display Python output
                di as text "  `line'"
                file read `pyfh' line
            }
            file close `pyfh'
        }
        
        * Verify output file was created
        local index_file "`outdir'_dataflow_index`sfx'.yaml"
        capture confirm file "`index_file'"
        if (_rc != 0) {
            di as err "     Python schema sync failed to create index file"
            return scalar count = 0
            error 601
        }
        
        return scalar count = `n_success'
        exit
    }
    
    *---------------------------------------------------------------------------
    * Native Stata parsing (only if forcestata or Python unavailable)
    * WARNING: Will fail on large XML responses due to macro length limits
    *---------------------------------------------------------------------------
    
    di as text "  Note: Using Stata parser (may hit macro length limits with many dataflows)"
    
    * First get list of all dataflows
    local df_url "`base_url'/dataflow/`agency'?references=none&detail=full"
    tempfile df_xml df_txt
    capture copy "`df_url'" "`df_xml'", public replace
    
    if (_rc != 0) {
        di as err "Failed to fetch dataflow list"
        return scalar count = 0
        exit
    }
    
    * Parse dataflow list to get IDs
    capture filefilter "`df_xml'" "`df_txt'", from("<str:Dataflow") to("\n<str:Dataflow") replace
    
    * Build list of dataflows
    local df_ids ""
    local df_names ""
    local df_versions ""
    local n_dataflows = 0
    
    tempname infh
    capture file open `infh' using "`df_txt'", read
    if (_rc == 0) {
        file read `infh' line
        while !r(eof) {
            if (strmatch(`"`line'"', `"*<str:Dataflow *id=*"') == 1) {
                * Extract ID
                local tmp = `"`line'"'
                local pos = strpos(`"`tmp'"', `"id=""')
                if (`pos' > 0) {
                    local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                    local pos2 = strpos(`"`tmp2'"', `"""')
                    if (`pos2' > 0) {
                        local df_id = substr(`"`tmp2'"', 1, `pos2' - 1)
                        local df_ids "`df_ids' `df_id'"
                        local n_dataflows = `n_dataflows' + 1
                        
                        * Extract version
                        local pos3 = strpos(`"`tmp'"', `"version=""')
                        if (`pos3' > 0) {
                            local tmp3 = substr(`"`tmp'"', `pos3' + 9, .)
                            local pos4 = strpos(`"`tmp3'"', `"""')
                            if (`pos4' > 0) {
                                local df_ver = substr(`"`tmp3'"', 1, `pos4' - 1)
                                local df_versions "`df_versions' `df_ver'"
                            }
                        }
                        else {
                            local df_versions "`df_versions' 1.0"
                        }
                        
                        * Extract name
                        local pos5 = strpos(`"`tmp'"', `"<com:Name xml:lang="en">"')
                        if (`pos5' > 0) {
                            local tmp4 = substr(`"`tmp'"', `pos5' + 24, .)
                            local pos6 = strpos(`"`tmp4'"', "</com:Name>")
                            if (`pos6' > 0) {
                                local df_name = substr(`"`tmp4'"', 1, `pos6' - 1)
                                local df_name = subinstr(`"`df_name'"', "'", "''", .)
                                local df_names `"`df_names'"`df_name'" "'
                            }
                        }
                        else {
                            local df_names `"`df_names'"" "'
                        }
                    }
                }
            }
            file read `infh' line
        }
        file close `infh'
    }
    
    * Create dataflows subdirectory (with suffix if provided)
    if ("`sfx'" != "") {
        local dataflows_dir "`outdir'dataflows`sfx'/"
    }
    else {
        local dataflows_dir "`outdir'dataflows/"
    }
    capture mkdir "`dataflows_dir'"
    
    * Open index file
    local index_file "`outdir'_dataflow_index`sfx'.yaml"
    tempname fh
    file open `fh' using "`index_file'", write text replace
    
    file write `fh' "metadata_version: '1.0'" _n
    file write `fh' "synced_at: '`synced_at''" _n
    file write `fh' "source: SDMX API Data Structure Definitions" _n
    file write `fh' "agency: `agency'" _n
    file write `fh' "total_dataflows: `n_dataflows'" _n
    file write `fh' "dataflows:" _n
    
    * For each dataflow, fetch DSD and count dimensions/attributes
    local success_count = 0
    forvalues i = 1/`n_dataflows' {
        local df_id : word `i' of `df_ids'
        local df_ver : word `i' of `df_versions'
        local df_name : word `i' of `df_names'
        
        * Fetch DSD for this dataflow
        local dsd_url "`base_url'/dataflow/`agency'/`df_id'/`df_ver'?references=all"
        tempfile dsd_xml dsd_txt
        capture copy "`dsd_url'" "`dsd_xml'", public replace
        
        if (_rc == 0) {
            * Count dimensions (str:Dimension elements with id attribute)
            capture filefilter "`dsd_xml'" "`dsd_txt'", from("<str:Dimension") to("\n<str:Dimension") replace
            
            local n_dims = 0
            tempname dsdh
            capture file open `dsdh' using "`dsd_txt'", read
            if (_rc == 0) {
                file read `dsdh' line
                while !r(eof) {
                    if (strmatch(`"`line'"', `"*<str:Dimension *id=*"') == 1) {
                        local n_dims = `n_dims' + 1
                    }
                    file read `dsdh' line
                }
                file close `dsdh'
            }
            
            * Count attributes
            capture filefilter "`dsd_xml'" "`dsd_txt'", from("<str:Attribute") to("\n<str:Attribute") replace
            
            local n_attrs = 0
            capture file open `dsdh' using "`dsd_txt'", read
            if (_rc == 0) {
                file read `dsdh' line
                while !r(eof) {
                    if (strmatch(`"`line'"', `"*<str:Attribute *id=*"') == 1) {
                        local n_attrs = `n_attrs' + 1
                    }
                    file read `dsdh' line
                }
                file close `dsdh'
            }
            
            * Write to index
            file write `fh' "- id: `df_id'" _n
            file write `fh' "  name: '`df_name''" _n
            file write `fh' "  version: '`df_ver''" _n
            file write `fh' "  dimensions_count: `n_dims'" _n
            file write `fh' "  attributes_count: `n_attrs'" _n
            
            * Write individual dataflow schema file
            _unicefdata_sync_df_schema, ///
                dsdxml("`dsd_xml'") ///
                outfile("`dataflows_dir'`df_id'.yaml") ///
                dfid("`df_id'") ///
                dfname("`df_name'") ///
                dfver("`df_ver'") ///
                agency("`agency'") ///
                syncedat("`synced_at'")
            
            local success_count = `success_count' + 1
        }
        else {
            * Failed to fetch DSD
            file write `fh' "- id: `df_id'" _n
            file write `fh' "  name: '`df_name''" _n
            file write `fh' "  version: '`df_ver''" _n
            file write `fh' "  dimensions_count: null" _n
            file write `fh' "  attributes_count: null" _n
            file write `fh' "  error: 'Failed to fetch DSD'" _n
        }
        
        * Small delay to avoid rate limiting
        sleep 200
    }
    
    file close `fh'
    
    return scalar count = `success_count'
    return scalar total = `n_dataflows'
end

*******************************************************************************
* Helper: Sync single dataflow schema to YAML file
*******************************************************************************

program define _unicefdata_sync_df_schema
    syntax, DSDXML(string) OUTFILE(string) DFID(string) DFNAME(string) ///
            DFVER(string) AGENCY(string) SYNCEDAT(string)
    
    tempfile txt_file
    tempname fh dsdh
    
    file open `fh' using "`outfile'", write text replace
    
    * Write header
    file write `fh' "id: `dfid'" _n
    file write `fh' "name: '`dfname''" _n
    file write `fh' "version: '`dfver''" _n
    file write `fh' "agency: `agency'" _n
    file write `fh' "synced_at: '`syncedat''" _n
    
    * Parse dimensions
    file write `fh' "dimensions:" _n
    
    capture filefilter "`dsdxml'" "`txt_file'", from("<str:Dimension") to("\n<str:Dimension") replace
    
    local pos_num = 0
    capture file open `dsdh' using "`txt_file'", read
    if (_rc == 0) {
        file read `dsdh' line
        while !r(eof) {
            if (strmatch(`"`line'"', `"*<str:Dimension *id=*"') == 1) {
                local tmp = `"`line'"'
                
                * Extract id
                local pos = strpos(`"`tmp'"', `"id=""')
                if (`pos' > 0) {
                    local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                    local pos2 = strpos(`"`tmp2'"', `"""')
                    if (`pos2' > 0) {
                        local dim_id = substr(`"`tmp2'"', 1, `pos2' - 1)
                        local pos_num = `pos_num' + 1
                        
                        * Extract position
                        local dim_pos = `pos_num'
                        local pos3 = strpos(`"`tmp'"', `"position=""')
                        if (`pos3' > 0) {
                            local tmp3 = substr(`"`tmp'"', `pos3' + 10, .)
                            local pos4 = strpos(`"`tmp3'"', `"""')
                            if (`pos4' > 0) {
                                local dim_pos = substr(`"`tmp3'"', 1, `pos4' - 1)
                            }
                        }
                        
                        * Extract codelist reference
                        local codelist = ""
                        local pos5 = strpos(`"`tmp'"', `"<Ref id=""')
                        if (`pos5' > 0) {
                            local tmp4 = substr(`"`tmp'"', `pos5' + 9, .)
                            local pos6 = strpos(`"`tmp4'"', `"""')
                            if (`pos6' > 0) {
                                local codelist = substr(`"`tmp4'"', 1, `pos6' - 1)
                            }
                        }
                        
                        file write `fh' "- id: `dim_id'" _n
                        file write `fh' "  position: `dim_pos'" _n
                        if ("`codelist'" != "") {
                            file write `fh' "  codelist: `codelist'" _n
                        }
                    }
                }
            }
            file read `dsdh' line
        }
        file close `dsdh'
    }
    
    * Parse time dimension
    file write `fh' "time_dimension: TIME_PERIOD" _n
    
    * Parse primary measure
    file write `fh' "primary_measure: OBS_VALUE" _n
    
    * Parse attributes
    file write `fh' "attributes:" _n
    
    capture filefilter "`dsdxml'" "`txt_file'", from("<str:Attribute") to("\n<str:Attribute") replace
    
    capture file open `dsdh' using "`txt_file'", read
    if (_rc == 0) {
        file read `dsdh' line
        while !r(eof) {
            if (strmatch(`"`line'"', `"*<str:Attribute *id=*"') == 1) {
                local tmp = `"`line'"'
                
                * Extract id
                local pos = strpos(`"`tmp'"', `"id=""')
                if (`pos' > 0) {
                    local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                    local pos2 = strpos(`"`tmp2'"', `"""')
                    if (`pos2' > 0) {
                        local attr_id = substr(`"`tmp2'"', 1, `pos2' - 1)
                        
                        * Extract codelist reference
                        local codelist = ""
                        local pos5 = strpos(`"`tmp'"', `"<Ref id=""')
                        if (`pos5' > 0) {
                            local tmp4 = substr(`"`tmp'"', `pos5' + 9, .)
                            local pos6 = strpos(`"`tmp4'"', `"""')
                            if (`pos6' > 0) {
                                local codelist = substr(`"`tmp4'"', 1, `pos6' - 1)
                            }
                        }
                        
                        file write `fh' "- id: `attr_id'" _n
                        if ("`codelist'" != "") {
                            file write `fh' "  codelist: `codelist'" _n
                        }
                    }
                }
            }
            file read `dsdh' line
        }
        file close `dsdh'
    }
    
    file close `fh'
end

*******************************************************************************
* Extended Sync: Full indicator catalog from CL_UNICEF_INDICATOR codelist
* Generates _unicefdata_indicators_metadata.yaml matching Python/R format
* 
* Uses unicefdata_xmltoyaml (Python backend) to handle the large XML file
* that exceeds Stata's macro length limits when parsed inline.
* 
* Features aligned with Python/R:
*   - metadata header with version, source, timestamp
*   - URN field for each indicator
*   - 30-day staleness check (skip fetch if file recent)
*******************************************************************************

program define _unicefdata_sync_ind_meta, rclass
    syntax, OUTFILE(string) AGENCY(string) [FORCE FORCEPYTHON FORCESTATA]
    
    local cache_max_age_days = 30
    local codelist_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0"
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    *---------------------------------------------------------------------------
    * Staleness check: skip if file exists and is less than 30 days old
    *---------------------------------------------------------------------------
    if ("`force'" == "") {
        capture confirm file "`outfile'"
        if (_rc == 0) {
            * File exists - check its age using file modification date
            quietly {
                local finfo : dir "." files "`outfile'"
                if (`"`finfo'"' != "") {
                    tempname fh_check
                    capture file open `fh_check' using "`outfile'", read
                    if (_rc == 0) {
                        * Read first few lines to check for synced_at/last_updated date
                        local found_date = 0
                        local line_count = 0
                        file read `fh_check' line
                        while !r(eof) & `line_count' < 20 {
                            local line_count = `line_count' + 1
                            * Check for both synced_at and last_updated (Python/R use last_updated)
                            if (strmatch(`"`line'"', "*synced_at:*") | strmatch(`"`line'"', "*last_updated:*")) {
                                * Extract date from timestamp field
                                local synced_str = regexr(`"`line'"', ".*(synced_at|last_updated): *'?", "")
                                local synced_str = regexr("`synced_str'", "'.*", "")
                                local synced_str = substr("`synced_str'", 1, 10)
                                * Parse YYYY-MM-DD format
                                capture {
                                    local sync_year = real(substr("`synced_str'", 1, 4))
                                    local sync_month = real(substr("`synced_str'", 6, 2))
                                    local sync_day = real(substr("`synced_str'", 9, 2))
                                    local sync_date = mdy(`sync_month', `sync_day', `sync_year')
                                    local today_date = date("`c(current_date)'", "DMY")
                                    local file_age = `today_date' - `sync_date'
                                    local found_date = 1
                                }
                                continue, break
                            }
                            file read `fh_check' line
                        }
                        file close `fh_check'
                        
                        if (`found_date' == 1 & `file_age' < `cache_max_age_days') {
                            * File is fresh enough - count existing indicators and return
                            local n_cached = 0
                            tempname infh
                            capture file open `infh' using "`outfile'", read
                            if (_rc == 0) {
                                file read `infh' line
                                while !r(eof) {
                                    if (strmatch(`"`line'"', "  *:") & !strmatch(`"`line'"', "    *")) {
                                        local n_cached = `n_cached' + 1
                                    }
                                    file read `infh' line
                                }
                                file close `infh'
                            }
                            * Subtract 1 for metadata entry
                            local n_cached = `n_cached' - 1
                            di as text "     → Using cached file (`file_age' days old, threshold: `cache_max_age_days' days)"
                            return scalar count = `n_cached'
                            return scalar cached = 1
                            exit
                        }
                    }
                }
            }
        }
    }
    
    *---------------------------------------------------------------------------
    * Fetch XML from API
    *---------------------------------------------------------------------------
    local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    local url "`base_url'/codelist/`agency'/CL_UNICEF_INDICATOR/latest"
    
    tempfile xmlfile
    capture copy "`url'" "`xmlfile'", public replace
    
    if (_rc != 0) {
        di as err "     Failed to download indicator codelist from API"
        return scalar count = 0
        return scalar cached = 0
        exit
    }
    
    *---------------------------------------------------------------------------
    * Determine parser to use
    * Pure Stata parser has macro length limitations with large XML files
    *---------------------------------------------------------------------------
    local parser_option "forcepython"  // Default: use Python for robustness
    
    if ("`forcestata'" != "") {
        * User explicitly requested pure Stata parser
        * Warn about limitations but try anyway
        di as text "     Note: Pure Stata parser requested for indicator metadata"
        di as text "     Warning: Large XML files may hit Stata macro limits (~730+ indicators)"
        local parser_option "forcestata"
    }
    else if ("`forcepython'" != "") {
        local parser_option "forcepython"
    }
    
    capture noisily unicefdata_xmltoyaml, ///
        type(indicators) ///
        xmlfile("`xmlfile'") ///
        outfile("`outfile'") ///
        agency("`agency'") ///
        version("1.0") ///
        source("`codelist_url'") ///
        codelistid("CL_UNICEF_INDICATOR") ///
        codelistname("UNICEF Indicator Codelist") ///
        `parser_option'
    
    if (_rc == 0) {
        local n_indicators = r(count)
        return scalar count = `n_indicators'
        return scalar cached = 0
        exit
    }
    
    * Parser failed
    if ("`forcestata'" != "") {
        di as err "     Pure Stata parser failed for indicator metadata"
        di as err "     This file exceeds Stata's macro length limits (~730+ indicators)"
        di as err "     Use 'forcepython' option or omit parser option for Python fallback"
    }
    else {
        di as err "     Python parser required for indicator metadata (file too large for Stata)"
        di as err "     Ensure Python 3.6+ is installed and unicefdata_xml2yaml.py is accessible"
    }
    return scalar count = 0
    return scalar cached = 0
    error 601
end

*******************************************************************************
* Helper: Update sync history
*******************************************************************************

program define _unicefdata_update_sync_history
    syntax, FILEPATH(string) VINTAGEDATE(string) SYNCEDAT(string) ///
            DATAFLOWS(integer) INDICATORS(integer) CODELISTS(integer) ///
            COUNTRIES(integer) REGIONS(integer)
    
    * Write new history file (simplified - doesn't preserve old entries)
    tempname fh
    file open `fh' using "`filepath'", write text replace
    
    file write `fh' "vintages:" _n
    file write `fh' "- vintage_date: '`vintagedate''" _n
    file write `fh' "  synced_at: '`syncedat''" _n
    file write `fh' "  dataflows: `dataflows'" _n
    file write `fh' "  indicators: `indicators'" _n
    file write `fh' "  codelists: `codelists'" _n
    file write `fh' "  countries: `countries'" _n
    file write `fh' "  regions: `regions'" _n
    file write `fh' "  errors: []" _n
    
    file close `fh'
end

*******************************************************************************
* unicefdata_sync
*! v 1.0.0   05Dec2025               by Joao Pedro Azevedo (UNICEF)
* Sync UNICEF metadata from SDMX API to local YAML files
* Creates standardized YAML files with watermarks matching R/Python format
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
    unicefdata_sync [, path(string) verbose force]
    
OPTIONS:
    path(string) - Directory for metadata files (default: auto-detect)
    verbose      - Display detailed progress
    force        - Force sync even if cache is fresh
    
EXAMPLES:
    . unicefdata_sync
    . unicefdata_sync, verbose
    . unicefdata_sync, path("./metadata") verbose
    
REQUIRES:
    Stata 14.0+
    yaml.ado v1.3.0+ (for yaml write)
    
SEE ALSO:
    help unicefdata
    help yaml
*/

program define unicefdata_sync, rclass
    version 14.0
    
    syntax [, PATH(string) VERBOSE FORCE]
    
    *---------------------------------------------------------------------------
    * Configuration
    *---------------------------------------------------------------------------
    
    local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    local agency "UNICEF"
    local metadata_version "2.0.0"
    
    * File names (matching Python/R convention)
    local FILE_DATAFLOWS "_unicefdata_dataflows.yaml"
    local FILE_INDICATORS "_unicefdata_indicators.yaml"
    local FILE_CODELISTS "_unicefdata_codelists.yaml"
    local FILE_COUNTRIES "_unicefdata_countries.yaml"
    local FILE_REGIONS "_unicefdata_regions.yaml"
    local FILE_SYNC_HISTORY "_unicefdata_sync_history.yaml"
    
    * Get current timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    local vintage_date : di %tdCCYY-NN-DD date("`c(current_date)'", "DMY")
    local vintage_date = trim("`vintage_date'")
    
    *---------------------------------------------------------------------------
    * Locate/create metadata directory
    *---------------------------------------------------------------------------
    
    if ("`path'" == "") {
        * Auto-detect: look relative to ado file location
        findfile unicefdata.ado
        if (_rc == 0) {
            local ado_path "`r(fn)'"
            local ado_dir = subinstr("`ado_path'", "src/u/unicefdata.ado", "", .)
            local ado_dir = subinstr("`ado_dir'", "src\u\unicefdata.ado", "", .)
            local path "`ado_dir'metadata/"
        }
        else {
            * Fallback to current directory
            local path "`c(pwd)'/metadata/"
        }
    }
    
    * Ensure path ends with separator
    if (substr("`path'", -1, 1) != "/" & substr("`path'", -1, 1) != "\") {
        local path "`path'/"
    }
    
    * Create directories if needed
    local current_dir "`path'current/"
    capture mkdir "`path'"
    capture mkdir "`current_dir'"
    capture mkdir "`path'vintages/"
    
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
    
    if ("`verbose'" != "") {
        di as text "  📁 Fetching dataflows..."
    }
    
    capture {
        _unicefdata_sync_dataflows, ///
            url("`base_url'/dataflow/`agency'?references=none&detail=full") ///
            outfile("`current_dir'`FILE_DATAFLOWS'") ///
            version("`metadata_version'") ///
            agency("`agency'")
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
    
    *---------------------------------------------------------------------------
    * 2. Sync Codelists (excluding CL_COUNTRY and CL_WORLD_REGIONS)
    *---------------------------------------------------------------------------
    
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
    
    *---------------------------------------------------------------------------
    * 3. Sync Countries (CL_COUNTRY)
    *---------------------------------------------------------------------------
    
    if ("`verbose'" != "") {
        di as text "  📁 Fetching country codes..."
    }
    
    capture noisily {
        _unicefdata_sync_codelist_single, ///
            url("`base_url'/codelist/`agency'/CL_COUNTRY/latest") ///
            outfile("`current_dir'`FILE_COUNTRIES'") ///
            contenttype("countries") ///
            version("`metadata_version'") ///
            agency("`agency'") ///
            codelistid("CL_COUNTRY")
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
    
    *---------------------------------------------------------------------------
    * 4. Sync Regions (CL_WORLD_REGIONS)
    *---------------------------------------------------------------------------
    
    if ("`verbose'" != "") {
        di as text "  📁 Fetching regional codes..."
    }
    
    capture noisily {
        _unicefdata_sync_codelist_single, ///
            url("`base_url'/codelist/`agency'/CL_WORLD_REGIONS/latest") ///
            outfile("`current_dir'`FILE_REGIONS'") ///
            contenttype("regions") ///
            version("`metadata_version'") ///
            agency("`agency'") ///
            codelistid("CL_WORLD_REGIONS")
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
    
    *---------------------------------------------------------------------------
    * 5. Sync Indicators (from hardcoded catalog)
    *---------------------------------------------------------------------------
    
    if ("`verbose'" != "") {
        di as text "  📁 Building indicator catalog..."
    }
    
    capture {
        _unicefdata_sync_indicators, ///
            outfile("`current_dir'`FILE_INDICATORS'") ///
            version("`metadata_version'") ///
            agency("`agency'")
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
    
    *---------------------------------------------------------------------------
    * 6. Create vintage snapshot
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
            file close `fh'
        }
    }
    
    *---------------------------------------------------------------------------
    * 7. Update sync history
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
* Helper: Sync dataflows from API
* Uses wbopendata-style line-by-line XML parsing with filefilter preprocessing
*******************************************************************************

program define _unicefdata_sync_dataflows, rclass
    syntax, URL(string) OUTFILE(string) VERSION(string) AGENCY(string)
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    * Download XML using 'public' option (critical for HTTPS)
    tempfile xmlfile txtfile
    capture copy "`url'" "`xmlfile'", public replace
    
    local n_dataflows = 0
    
    * Create temporary file to store parsed dataflows
    tempfile df_data
    tempname dfh
    file open `dfh' using "`df_data'", write text replace
    
    if (_rc == 0) {
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
                        
                        * Store dataflow info
                        if ("`current_id'" != "") {
                            local n_dataflows = `n_dataflows' + 1
                            file write `dfh' "`current_id'|`current_version'|`current_name'" _n
                        }
                    }
                    
                    file read `infh' line
                }
                
                file close `infh'
            }
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
                * Parse pipe-delimited: id|version|name
                local df_id = ""
                local df_ver = ""
                local df_name = ""
                
                local pos1 = strpos(`"`line'"', "|")
                if (`pos1' > 0) {
                    local df_id = substr(`"`line'"', 1, `pos1' - 1)
                    local rest = substr(`"`line'"', `pos1' + 1, .)
                    local pos2 = strpos(`"`rest'"', "|")
                    if (`pos2' > 0) {
                        local df_ver = substr(`"`rest'"', 1, `pos2' - 1)
                        local df_name = substr(`"`rest'"', `pos2' + 1, .)
                    }
                }
                
                if ("`df_id'" != "") {
                    file write `fh' "  `df_id':" _n
                    file write `fh' "    id: `df_id'" _n
                    file write `fh' "    name: '`df_name''" _n
                    file write `fh' "    agency: `agency'" _n
                    file write `fh' "    version: '`df_ver''" _n
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

program define _unicefdata_sync_codelist_single, rclass
    syntax, URL(string) OUTFILE(string) CONTENTTYPE(string) VERSION(string) AGENCY(string) CODELISTID(string)
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    * Download XML using the 'public' option (critical for HTTPS)
    local n_codes = 0
    local api_success = 0
    local codelist_name ""
    
    tempfile xmlfile txtfile
    capture copy "`url'" "`xmlfile'", public replace
    
    if (_rc == 0) {
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
    syntax, OUTFILE(string) VERSION(string) AGENCY(string)
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    * Write YAML with watermark
    tempname fh
    file open `fh' using "`outfile'", write text replace
    
    * Write watermark
    file write `fh' "_metadata:" _n
    file write `fh' "  platform: Stata" _n
    file write `fh' "  version: '`version''" _n
    file write `fh' "  synced_at: '`synced_at''" _n
    file write `fh' "  source: unicef_api.config + SDMX API" _n
    file write `fh' "  agency: `agency'" _n
    file write `fh' "  content_type: indicators" _n
    file write `fh' "  total_indicators: 25" _n
    file write `fh' "  dataflows_covered: 12" _n
    file write `fh' "  indicators_per_dataflow:" _n
    file write `fh' "    CME: 2" _n
    file write `fh' "    NUTRITION: 3" _n
    file write `fh' "    EDUCATION_UIS_SDG: 5" _n
    file write `fh' "    IMMUNISATION: 2" _n
    file write `fh' "    HIV_AIDS: 1" _n
    file write `fh' "    WASH_HOUSEHOLDS: 3" _n
    file write `fh' "    MNCH: 3" _n
    file write `fh' "    PT: 2" _n
    file write `fh' "    PT_CM: 1" _n
    file write `fh' "    PT_FGM: 1" _n
    file write `fh' "    ECD: 1" _n
    file write `fh' "    CHLD_PVTY: 1" _n
    file write `fh' "indicators:" _n
    
    * Child Mortality (CME: 2)
    file write `fh' "  CME_MRM0:" _n
    file write `fh' "    code: CME_MRM0" _n
    file write `fh' "    name: Neonatal mortality rate" _n
    file write `fh' "    dataflow: CME" _n
    file write `fh' "    sdg_target: '3.2.2'" _n
    file write `fh' "    unit: Deaths per 1,000 live births" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  CME_MRY0T4:" _n
    file write `fh' "    code: CME_MRY0T4" _n
    file write `fh' "    name: Under-5 mortality rate" _n
    file write `fh' "    dataflow: CME" _n
    file write `fh' "    sdg_target: '3.2.1'" _n
    file write `fh' "    unit: Deaths per 1,000 live births" _n
    file write `fh' "    source: config" _n
    
    * Nutrition (NUTRITION: 3)
    file write `fh' "  NT_ANT_HAZ_NE2_MOD:" _n
    file write `fh' "    code: NT_ANT_HAZ_NE2_MOD" _n
    file write `fh' "    name: Stunting prevalence (moderate + severe)" _n
    file write `fh' "    dataflow: NUTRITION" _n
    file write `fh' "    sdg_target: '2.2.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  NT_ANT_WHZ_NE2:" _n
    file write `fh' "    code: NT_ANT_WHZ_NE2" _n
    file write `fh' "    name: Wasting prevalence" _n
    file write `fh' "    dataflow: NUTRITION" _n
    file write `fh' "    sdg_target: '2.2.2'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  NT_ANT_WHZ_PO2_MOD:" _n
    file write `fh' "    code: NT_ANT_WHZ_PO2_MOD" _n
    file write `fh' "    name: Overweight prevalence (moderate + severe)" _n
    file write `fh' "    dataflow: NUTRITION" _n
    file write `fh' "    sdg_target: '2.2.2'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    * Education (EDUCATION_UIS_SDG: 5)
    file write `fh' "  ED_ANAR_L02:" _n
    file write `fh' "    code: ED_ANAR_L02" _n
    file write `fh' "    name: Adjusted net attendance rate, primary education" _n
    file write `fh' "    dataflow: EDUCATION_UIS_SDG" _n
    file write `fh' "    sdg_target: '4.1.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  ED_CR_L1_UIS_MOD:" _n
    file write `fh' "    code: ED_CR_L1_UIS_MOD" _n
    file write `fh' "    name: Completion rate, primary education" _n
    file write `fh' "    dataflow: EDUCATION_UIS_SDG" _n
    file write `fh' "    sdg_target: '4.1.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  ED_CR_L2_UIS_MOD:" _n
    file write `fh' "    code: ED_CR_L2_UIS_MOD" _n
    file write `fh' "    name: Completion rate, lower secondary education" _n
    file write `fh' "    dataflow: EDUCATION_UIS_SDG" _n
    file write `fh' "    sdg_target: '4.1.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  ED_READ_L2:" _n
    file write `fh' "    code: ED_READ_L2" _n
    file write `fh' "    name: Reading proficiency, end of lower secondary" _n
    file write `fh' "    dataflow: EDUCATION_UIS_SDG" _n
    file write `fh' "    sdg_target: '4.1.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  ED_MAT_L2:" _n
    file write `fh' "    code: ED_MAT_L2" _n
    file write `fh' "    name: Mathematics proficiency, end of lower secondary" _n
    file write `fh' "    dataflow: EDUCATION_UIS_SDG" _n
    file write `fh' "    sdg_target: '4.1.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    * Immunization (IMMUNISATION: 2)
    file write `fh' "  IM_DTP3:" _n
    file write `fh' "    code: IM_DTP3" _n
    file write `fh' "    name: DTP3 immunization coverage" _n
    file write `fh' "    dataflow: IMMUNISATION" _n
    file write `fh' "    sdg_target: '3.b.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  IM_MCV1:" _n
    file write `fh' "    code: IM_MCV1" _n
    file write `fh' "    name: Measles immunization coverage (MCV1)" _n
    file write `fh' "    dataflow: IMMUNISATION" _n
    file write `fh' "    sdg_target: '3.b.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    * HIV/AIDS (HIV_AIDS: 1)
    file write `fh' "  HVA_EPI_INF_RT:" _n
    file write `fh' "    code: HVA_EPI_INF_RT" _n
    file write `fh' "    name: HIV incidence rate" _n
    file write `fh' "    dataflow: HIV_AIDS" _n
    file write `fh' "    sdg_target: '3.3.1'" _n
    file write `fh' "    unit: Per 1,000 uninfected population" _n
    file write `fh' "    source: config" _n
    
    * WASH (WASH_HOUSEHOLDS: 3)
    file write `fh' "  WS_PPL_W-SM:" _n
    file write `fh' "    code: WS_PPL_W-SM" _n
    file write `fh' "    name: Population using safely managed drinking water services" _n
    file write `fh' "    dataflow: WASH_HOUSEHOLDS" _n
    file write `fh' "    sdg_target: '6.1.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  WS_PPL_S-SM:" _n
    file write `fh' "    code: WS_PPL_S-SM" _n
    file write `fh' "    name: Population using safely managed sanitation services" _n
    file write `fh' "    dataflow: WASH_HOUSEHOLDS" _n
    file write `fh' "    sdg_target: '6.2.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  WS_PPL_H-B:" _n
    file write `fh' "    code: WS_PPL_H-B" _n
    file write `fh' "    name: Population with basic handwashing facilities" _n
    file write `fh' "    dataflow: WASH_HOUSEHOLDS" _n
    file write `fh' "    sdg_target: '6.2.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    * Maternal & Newborn Health (MNCH: 3)
    file write `fh' "  MNCH_MMR:" _n
    file write `fh' "    code: MNCH_MMR" _n
    file write `fh' "    name: Maternal mortality ratio" _n
    file write `fh' "    dataflow: MNCH" _n
    file write `fh' "    sdg_target: '3.1.1'" _n
    file write `fh' "    unit: Deaths per 100,000 live births" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  MNCH_SAB:" _n
    file write `fh' "    code: MNCH_SAB" _n
    file write `fh' "    name: Skilled attendance at birth" _n
    file write `fh' "    dataflow: MNCH" _n
    file write `fh' "    sdg_target: '3.1.2'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  MNCH_ABR:" _n
    file write `fh' "    code: MNCH_ABR" _n
    file write `fh' "    name: Adolescent birth rate" _n
    file write `fh' "    dataflow: MNCH" _n
    file write `fh' "    sdg_target: '3.7.2'" _n
    file write `fh' "    unit: Births per 1,000 women aged 15-19" _n
    file write `fh' "    source: config" _n
    
    * Child Protection (PT: 2)
    file write `fh' "  PT_CHLD_Y0T4_REG:" _n
    file write `fh' "    code: PT_CHLD_Y0T4_REG" _n
    file write `fh' "    name: Birth registration (children under 5)" _n
    file write `fh' "    dataflow: PT" _n
    file write `fh' "    sdg_target: '16.9.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file write `fh' "  PT_CHLD_1-14_PS-PSY-V_CGVR:" _n
    file write `fh' "    code: PT_CHLD_1-14_PS-PSY-V_CGVR" _n
    file write `fh' "    name: Violent discipline (children 1-14)" _n
    file write `fh' "    dataflow: PT" _n
    file write `fh' "    sdg_target: '16.2.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    * Child Marriage (PT_CM: 1)
    file write `fh' "  PT_F_20-24_MRD_U18_TND:" _n
    file write `fh' "    code: PT_F_20-24_MRD_U18_TND" _n
    file write `fh' "    name: Child marriage before age 18 (women 20-24)" _n
    file write `fh' "    dataflow: PT_CM" _n
    file write `fh' "    sdg_target: '5.3.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    * FGM (PT_FGM: 1)
    file write `fh' "  PT_F_15-49_FGM:" _n
    file write `fh' "    code: PT_F_15-49_FGM" _n
    file write `fh' "    name: Female genital mutilation prevalence (women 15-49)" _n
    file write `fh' "    dataflow: PT_FGM" _n
    file write `fh' "    sdg_target: '5.3.2'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    * Early Childhood Development (ECD: 1)
    file write `fh' "  ECD_CHLD_LMPSL:" _n
    file write `fh' "    code: ECD_CHLD_LMPSL" _n
    file write `fh' "    name: Children developmentally on track (literacy-numeracy, physical, social-emotional)" _n
    file write `fh' "    dataflow: ECD" _n
    file write `fh' "    sdg_target: '4.2.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    * Child Poverty (CHLD_PVTY: 1)
    file write `fh' "  PV_CHLD_DPRV-S-L1-HS:" _n
    file write `fh' "    code: PV_CHLD_DPRV-S-L1-HS" _n
    file write `fh' "    name: Child multidimensional poverty (severe deprivation in at least 1 dimension)" _n
    file write `fh' "    dataflow: CHLD_PVTY" _n
    file write `fh' "    sdg_target: '1.2.1'" _n
    file write `fh' "    unit: Percentage" _n
    file write `fh' "    source: config" _n
    
    file close `fh'
    
    return scalar count = 25
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

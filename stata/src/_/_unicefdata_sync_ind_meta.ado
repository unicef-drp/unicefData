*******************************************************************************
* _unicefdata_sync_ind_meta
*! v 1.1.0   08Dec2025               by Joao Pedro Azevedo (UNICEF)
* Helper program for unicefdata_sync: Sync full indicator catalog
*
* Uses unicefdata_xmltoyaml (Python backend) to handle the large XML file
* that exceeds Stata's macro length limits when parsed inline.
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
    * Use Python-based unicefdata_xmltoyaml for robust parsing
    * This avoids Stata's macro length limitation with large XML files
    *---------------------------------------------------------------------------
    
    * Determine parser option (default to forcepython for large indicator files)
    local parser_option "forcepython"
    if ("`forcestata'" != "") {
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
    
    * Python failed - report error (cannot fall back to Stata for this large file)
    di as err "     Python parser required for indicator metadata (file too large for Stata)"
    di as err "     Ensure Python 3.6+ is installed and unicefdata_xml2yaml.py is accessible"
    return scalar count = 0
    return scalar cached = 0
    error 601
end

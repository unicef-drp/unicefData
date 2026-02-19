*******************************************************************************
*! _unicef_load_indicators_cache v1.0.0  18Feb2026
*! Load indicators metadata into current dataset from frame cache.
*! Creates/refreshes the _unicef_indicators frame if needed.
*! Requires Stata 16+ (frames). Caller must preserve/restore.
*******************************************************************************

program define _unicef_load_indicators_cache
    version 16.0
    syntax [, METApath(string) NOCACHE VERBOSE]

    quietly {
        local parser_ver "1.0.0"
        local frame_name "_unicef_indicators"

        * -------------------------------------------------------------------
        * Locate YAML file
        * -------------------------------------------------------------------
        if ("`metapath'" == "") {
            capture findfile _unicefdata_indicators_metadata.yaml
            if (_rc == 0) {
                local yaml_file "`r(fn)'"
            }
            else {
                local yaml_file "`c(sysdir_plus)'_/_unicefdata_indicators_metadata.yaml"
            }
        }
        else {
            local yaml_file "`metapath'_unicefdata_indicators_metadata.yaml"
        }

        capture confirm file "`yaml_file'"
        if (_rc != 0) {
            noi di as err "Indicators metadata not found at: `yaml_file'"
            noi di as err "Run {bf:unicefdata_sync} to download metadata."
            exit 601
        }

        if ("`verbose'" != "") {
            noi di as text "(Cache helper: YAML at " as result "`yaml_file'" as text ")"
        }

        * -------------------------------------------------------------------
        * Check if cached frame exists and is valid
        * -------------------------------------------------------------------
        local need_parse = 1

        if ("`nocache'" == "") {
            capture confirm frame `frame_name'
            if (_rc == 0) {
                * Frame exists — verify it has the expected structure
                frame `frame_name' {
                    capture confirm variable ind_code _parser_version
                    if (_rc == 0) {
                        local cached_ver = _parser_version[1]
                        if ("`cached_ver'" == "`parser_ver'") {
                            local need_parse = 0
                        }
                    }
                }
            }
        }

        * -------------------------------------------------------------------
        * Parse YAML if needed
        * -------------------------------------------------------------------
        if (`need_parse') {
            if ("`verbose'" != "") {
                noi di as text "(Parsing indicators metadata YAML...)"
            }
            __unicef_parse_indicators_yaml "`yaml_file'"

            * Store in frame for future calls (unless nocache)
            if ("`nocache'" == "") {
                capture frame drop `frame_name'
                frame put *, into(`frame_name')
                if ("`verbose'" != "") {
                    noi di as text "(Cached " as result _N ///
                        as text " indicators in frame {bf:`frame_name'})"
                }
            }
        }
        else {
            * Load from cache into current dataset
            if ("`verbose'" != "") {
                noi di as text "(Using cached metadata from memory)"
            }
            frame copy `frame_name' default, replace
        }
    }
end

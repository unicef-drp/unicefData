*******************************************************************************
* _unicef_get_disagg_totals.ado
*! v 1.0.0   25Jan2026               by Claude Code
* Get disaggregations_with_totals for an indicator from metadata YAML
*
* Returns: Space-separated list of dimension names that have _T totals
* Example: "SEX AGE WEALTH_QUINTILE" means these dimensions have _T values
*          Dimensions NOT in this list (e.g., DISABILITY_STATUS) do NOT have _T
*
* This enables metadata-driven filtering:
*   - Dimensions IN the list: can default to _T
*   - Dimensions NOT in the list: need special handling (e.g., PD for disability)
*******************************************************************************

program define _unicef_get_disagg_totals, rclass
    version 14.0

    syntax , INDicator(string) [METADATApath(string) VERBOSE]

    local indicator_upper = upper("`indicator'")
    local disagg_totals ""

    quietly {
        *-----------------------------------------------------------------------
        * Find the metadata YAML file
        *-----------------------------------------------------------------------

        local yaml_file ""
        local plus_dir "`c(sysdir_plus)'"

        * Try user-supplied path first
        if ("`metadatapath'" != "") {
            local candidate "`metadatapath'_unicefdata_indicators_metadata.yaml"
            capture confirm file "`candidate'"
            if (_rc == 0) {
                local yaml_file "`candidate'"
            }
        }

        * Try the most common location (plus directory _ subfolder)
        if ("`yaml_file'" == "") {
            capture confirm file "`plus_dir'_/_unicefdata_indicators_metadata.yaml"
            if (_rc == 0) {
                local yaml_file "`plus_dir'_/_unicefdata_indicators_metadata.yaml"
            }
        }

        * If not found, try alternative paths
        if ("`yaml_file'" == "") {
            local candidate_paths ///
                "`plus_dir'_\_unicefdata_indicators_metadata.yaml" ///
                "_unicefdata_indicators_metadata.yaml" ///
                "stata/src/_/_unicefdata_indicators_metadata.yaml" ///
                "src/_/_unicefdata_indicators_metadata.yaml"

            foreach path of local candidate_paths {
                capture confirm file "`path'"
                if (_rc == 0) {
                    local yaml_file "`path'"
                    continue, break
                }
            }
        }

        * If YAML not found, return empty
        if ("`yaml_file'" == "") {
            if ("`verbose'" != "") {
                noi di as text "  _unicef_get_disagg_totals: Metadata file not found"
            }
            return local disagg_totals ""
            return local found 0
            exit 0
        }

        if ("`verbose'" != "") {
            noi di as text "  _unicef_get_disagg_totals: Using metadata from " as result "`yaml_file'"
        }

        *-----------------------------------------------------------------------
        * Parse YAML to find disaggregations_with_totals for the indicator
        *-----------------------------------------------------------------------

        tempname fh
        local in_indicator 0
        local found 0
        local search_pattern "  `indicator_upper':"

        file open `fh' using "`yaml_file'", read text
        file read `fh' line

        while r(eof) == 0 {
            local trimmed = strtrim(`"`line'"')

            * Look for the indicator entry
            if (`in_indicator' == 0) {
                if (substr(`"`line'"', 1, length("`search_pattern'")) == "`search_pattern'") {
                    local in_indicator 1
                    local found 1
                    if ("`verbose'" != "") {
                        noi di as text "    Found indicator: " as result "`indicator_upper'"
                    }
                }
            }
            else {
                * We're inside the indicator block

                * Check if we've moved to another indicator (new top-level key)
                local first_chars = substr(`"`line'"', 1, 4)
                if ("`first_chars'" == "  " & substr(`"`line'"', 3, 1) != " " & strpos(`"`line'"', ":") > 0) {
                    * This is a new indicator entry - stop
                    continue, break
                }

                * Look for disaggregations_with_totals field
                if (strpos("`trimmed'", "disaggregations_with_totals:") > 0) {
                    * Extract the value after the colon
                    local after_colon = subinstr("`trimmed'", "disaggregations_with_totals:", "", 1)
                    local after_colon = strtrim("`after_colon'")

                    * Handle inline list format [A, B, C] or [A,B,C]
                    if (regexm(`"`after_colon'"', "\[([^\]]*)\]")) {
                        local disagg_totals = regexs(1)
                        * Clean up: remove quotes, trim spaces
                        local disagg_totals = subinstr("`disagg_totals'", `"""', "", .)
                        local disagg_totals = subinstr("`disagg_totals'", "'", "", .)
                        local disagg_totals = subinstr("`disagg_totals'", ",", " ", .)
                        local disagg_totals = stritrim(strtrim("`disagg_totals'"))

                        if ("`verbose'" != "") {
                            noi di as text "    disaggregations_with_totals: " as result "`disagg_totals'"
                        }
                        continue, break
                    }
                    else if ("`after_colon'" == "" | "`after_colon'" == "[]") {
                        * Multi-line YAML list format - read subsequent lines
                        * Format:  disaggregations_with_totals:
                        *          - SEX
                        *          - AGE
                        file read `fh' line
                        while r(eof) == 0 {
                            local item = strtrim(`"`line'"')
                            * Check if it's a list item (starts with "- ")
                            if (substr("`item'", 1, 2) == "- ") {
                                local dim_name = strtrim(substr("`item'", 3, .))
                                local disagg_totals "`disagg_totals' `dim_name'"
                            }
                            else if ("`item'" != "") {
                                * Non-empty line that's not a list item = end of list
                                continue, break
                            }
                            file read `fh' line
                        }
                        local disagg_totals = stritrim(strtrim("`disagg_totals'"))

                        if ("`verbose'" != "") {
                            noi di as text "    disaggregations_with_totals: " as result "`disagg_totals'"
                        }
                        continue, break
                    }
                    else {
                        * Scalar value (rare but possible)
                        local disagg_totals "`after_colon'"

                        if ("`verbose'" != "") {
                            noi di as text "    disaggregations_with_totals: " as result "`disagg_totals'"
                        }
                        continue, break
                    }
                }
            }

            file read `fh' line
        }

        capture file close `fh'

    } // end quietly

    * Return results
    return local disagg_totals "`disagg_totals'"
    return local found `found'

end

*! v 1.0.0   25Jan2026               by Claude Code
* Helper function to retrieve disaggregations_with_totals from indicator metadata
* Used for metadata-driven filtering to match Python/R behavior

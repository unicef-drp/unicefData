*******************************************************************************
*! __unicef_parse_indicators_yaml v1.0.0  18Feb2026
*! Parse UNICEF indicators metadata YAML into collapsed dataset
*! (one row per indicator). Called by discovery functions for frame caching.
*! Reference: __wbod_parse_yaml_ind.ado v1.0.10 (wbopendata)
*******************************************************************************

program define __unicef_parse_indicators_yaml
    version 14.0
    args yaml_path

    quietly {
        * Read each line preserving leading whitespace (indentation).
        * Use Mata st_sstore() to bypass macro expansion, which breaks
        * when lines contain embedded double-quotes (r(132)).
        tempname fh
        clear
        gen strL rawline = ""
        local i = 0
        file open `fh' using "`yaml_path'", read
        file read `fh' line
        while (r(eof) == 0) {
            local i = `i' + 1
            set obs `i'
            mata: st_sstore(`i', "rawline", st_local("line"))
            file read `fh' line
        }
        file close `fh'

        gen long linenum = _n
        gen strL raw_trim = strtrim(subinstr(rawline, char(13), "", .))
        gen int indent = length(rawline) - length(strtrim(rawline))

        * -------------------------------------------------------------------
        * Detect indicator header lines (indent == 2, ends with colon,
        * not a known metadata/section field)
        * -------------------------------------------------------------------
        gen byte is_indicator = 0
        replace is_indicator = 1 if indent == 2 & regexm(raw_trim, ":$") & ///
            substr(raw_trim,1,9) != "metadata:" & ///
            substr(raw_trim,1,11) != "indicators:" & ///
            substr(raw_trim,1,9) != "platform:" & ///
            substr(raw_trim,1,8) != "version:" & ///
            substr(raw_trim,1,10) != "synced_at:" & ///
            substr(raw_trim,1,7) != "source:" & ///
            substr(raw_trim,1,7) != "agency:" & ///
            substr(raw_trim,1,13) != "content_type:" & ///
            substr(raw_trim,1,4) != "url:" & ///
            substr(raw_trim,1,13) != "last_updated:" & ///
            substr(raw_trim,1,12) != "description:" & ///
            substr(raw_trim,1,16) != "indicator_count:" & ///
            substr(raw_trim,1,12) != "tier_counts:" & ///
            substr(raw_trim,1,1) != "-" & ///
            substr(raw_trim,1,5) != "code:" & ///
            substr(raw_trim,1,5) != "name:" & ///
            substr(raw_trim,1,4) != "urn:" & ///
            substr(raw_trim,1,7) != "parent:" & ///
            substr(raw_trim,1,5) != "tier:" & ///
            substr(raw_trim,1,12) != "tier_reason:" & ///
            substr(raw_trim,1,10) != "dataflows:"

        * -------------------------------------------------------------------
        * Detect field lines (indent == 4, has colon, not a list item)
        * -------------------------------------------------------------------
        gen byte is_field = 0
        replace is_field = 1 if indent == 4 & strpos(raw_trim, ":") > 0 & ///
            is_indicator == 0 & substr(raw_trim,1,1) != "-"

        * Extract indicator code (everything before the trailing colon)
        gen str100 ind_code = ""
        replace ind_code = strtrim(substr(rawline, 1, length(rawline) - 1)) ///
            if is_indicator
        * Strip surrounding quotes from indicator codes like 'CME':
        replace ind_code = substr(ind_code, 2, length(ind_code) - 2) ///
            if is_indicator & length(ind_code) >= 3 & ///
            substr(ind_code,1,1) == "'" & ///
            substr(ind_code, length(ind_code), 1) == "'"

        * Propagate indicator code down to its fields
        gen long ind_group = sum(is_indicator)
        bysort ind_group: replace ind_code = ind_code[1]

        * -------------------------------------------------------------------
        * Extract field type and value
        * -------------------------------------------------------------------
        gen str30 field_type = ""
        gen int colon_pos = strpos(rawline, ":")
        replace field_type = strtrim(substr(rawline, 1, colon_pos - 1)) ///
            if is_field & colon_pos > 0

        gen strL field_val = ""
        replace field_val = strtrim(substr(rawline, colon_pos + 1, .)) ///
            if is_field & colon_pos > 0
        * Remove surrounding quotes
        replace field_val = substr(field_val, 2, length(field_val) - 2) ///
            if is_field & length(field_val) >= 2 & ///
            ((substr(field_val,1,1) == `"""' & ///
              substr(field_val, length(field_val), 1) == `"""') | ///
             (substr(field_val,1,1) == "'" & ///
              substr(field_val, length(field_val), 1) == "'"))

        * -------------------------------------------------------------------
        * Handle YAML continuation lines (indent >= 6, not a list item,
        * follows a field like name: or description: whose value wraps)
        * -------------------------------------------------------------------
        gen byte is_continuation = 0
        replace is_continuation = 1 if indent >= 6 & !is_field & ///
            !is_indicator & substr(raw_trim,1,1) != "-" & raw_trim != ""

        * Track which field the continuation belongs to
        gen str30 cont_field = ""
        replace cont_field = field_type if is_field & field_val != ""
        * Also mark fields that start a continuation (value on same line)
        replace cont_field = field_type if is_field & field_val == "" & ///
            _n < _N & indent[_n+1] >= 6

        * Forward-fill continuation context
        forvalues iter = 1/5 {
            replace cont_field = cont_field[_n-1] if cont_field == "" & ///
                is_continuation & _n > 1
        }

        * Append continuation text to the field value
        replace field_type = cont_field if is_continuation & cont_field != ""
        replace field_val = raw_trim if is_continuation & cont_field != ""

        * -------------------------------------------------------------------
        * Handle YAML list items (indent == 4, starts with "- ")
        * -------------------------------------------------------------------
        gen byte is_list_item = indent == 4 & regexm(raw_trim, "^- ")
        gen str100 list_item_val = ""
        replace list_item_val = strtrim(substr(raw_trim, 3, .)) if is_list_item
        * Remove surrounding quotes from list values
        replace list_item_val = substr(list_item_val, 2, ///
            length(list_item_val) - 2) if is_list_item & ///
            length(list_item_val) >= 2 & ///
            ((substr(list_item_val,1,1) == "'" & ///
              substr(list_item_val, length(list_item_val), 1) == "'") | ///
             (substr(list_item_val,1,1) == `"""' & ///
              substr(list_item_val, length(list_item_val), 1) == `"""'))

        * Track which field header introduces the current list context
        gen str30 last_list_header = ""
        replace last_list_header = field_type ///
            if inlist(field_type, "dataflows", "disaggregations", ///
                "disaggregations_with_totals")
        * Forward-fill
        replace last_list_header = last_list_header[_n-1] ///
            if last_list_header == "" & _n > 1

        * -------------------------------------------------------------------
        * Assign to typed columns
        * -------------------------------------------------------------------
        gen strL field_name = ""
        gen strL field_desc = ""
        gen strL field_urn = ""
        gen str100 field_parent = ""
        gen str244 field_dataflows = ""
        gen str10 field_tier = ""
        gen str50 field_tier_reason = ""
        gen str244 field_disagg = ""
        gen str244 field_disagg_totals = ""

        replace field_name        = field_val if field_type == "name"
        replace field_desc        = field_val if field_type == "description"
        replace field_urn         = field_val if field_type == "urn"
        replace field_parent      = field_val if field_type == "parent"
        replace field_tier        = field_val if field_type == "tier"
        replace field_tier_reason = field_val if field_type == "tier_reason"

        * Scalar dataflows (e.g. "dataflows: COVID_CASES")
        replace field_dataflows = field_val ///
            if field_type == "dataflows" & field_val != ""

        * List item assignments
        replace field_dataflows    = list_item_val ///
            if is_list_item & last_list_header == "dataflows"
        replace field_disagg       = list_item_val ///
            if is_list_item & last_list_header == "disaggregations"
        replace field_disagg_totals = list_item_val ///
            if is_list_item & last_list_header == "disaggregations_with_totals"

        drop is_list_item list_item_val last_list_header

        * -------------------------------------------------------------------
        * Accumulate multi-row fields within each indicator group
        * -------------------------------------------------------------------
        sort ind_group linenum

        * Accumulate name continuation lines
        gen strL field_name_acc = ""
        by ind_group: replace field_name_acc = field_name if _n == 1
        by ind_group: replace field_name_acc = ///
            cond(field_name != "", ///
                cond(field_name_acc[_n-1] != "", ///
                    field_name_acc[_n-1] + " " + field_name, field_name), ///
                field_name_acc[_n-1]) if _n > 1
        by ind_group: replace field_name = field_name_acc[_N]
        drop field_name_acc

        * Accumulate description continuation lines
        gen strL field_desc_acc = ""
        by ind_group: replace field_desc_acc = field_desc if _n == 1
        by ind_group: replace field_desc_acc = ///
            cond(field_desc != "", ///
                cond(field_desc_acc[_n-1] != "", ///
                    field_desc_acc[_n-1] + " " + field_desc, field_desc), ///
                field_desc_acc[_n-1]) if _n > 1
        by ind_group: replace field_desc = field_desc_acc[_N]
        drop field_desc_acc

        * Accumulate dataflows as semicolon-separated list
        gen str500 all_dataflows = ""
        by ind_group: replace all_dataflows = field_dataflows if _n == 1
        by ind_group: replace all_dataflows = ///
            cond(field_dataflows != "", ///
                cond(all_dataflows[_n-1] != "", ///
                    all_dataflows[_n-1] + ";" + field_dataflows, ///
                    field_dataflows), ///
                all_dataflows[_n-1]) if _n > 1
        by ind_group: replace all_dataflows = all_dataflows[_N]
        replace field_dataflows = all_dataflows
        drop all_dataflows

        * Accumulate disaggregations as semicolon-separated list
        gen str500 all_disagg = ""
        by ind_group: replace all_disagg = field_disagg if _n == 1
        by ind_group: replace all_disagg = ///
            cond(field_disagg != "", ///
                cond(all_disagg[_n-1] != "", ///
                    all_disagg[_n-1] + ";" + field_disagg, field_disagg), ///
                all_disagg[_n-1]) if _n > 1
        by ind_group: replace all_disagg = all_disagg[_N]
        replace field_disagg = all_disagg
        drop all_disagg

        * Accumulate disaggregations_with_totals
        gen str500 all_disagg_t = ""
        by ind_group: replace all_disagg_t = field_disagg_totals if _n == 1
        by ind_group: replace all_disagg_t = ///
            cond(field_disagg_totals != "", ///
                cond(all_disagg_t[_n-1] != "", ///
                    all_disagg_t[_n-1] + ";" + field_disagg_totals, ///
                    field_disagg_totals), ///
                all_disagg_t[_n-1]) if _n > 1
        by ind_group: replace all_disagg_t = all_disagg_t[_N]
        replace field_disagg_totals = all_disagg_t
        drop all_disagg_t

        * -------------------------------------------------------------------
        * Collapse to one row per indicator
        * -------------------------------------------------------------------
        collapse (firstnm) ind_code (firstnm) field_name ///
                 (firstnm) field_desc (firstnm) field_urn ///
                 (firstnm) field_parent (firstnm) field_dataflows ///
                 (firstnm) field_tier (firstnm) field_tier_reason ///
                 (firstnm) field_disagg (firstnm) field_disagg_totals, ///
                 by(ind_group)
        drop if ind_code == ""

        * Keep only necessary columns
        keep ind_code field_name field_desc field_urn field_parent ///
             field_dataflows field_tier field_tier_reason ///
             field_disagg field_disagg_totals

        * Add parser version for cache invalidation
        gen str10 _parser_version = "1.0.0"
    }
end

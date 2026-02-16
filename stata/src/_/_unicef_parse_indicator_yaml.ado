*******************************************************************************
* _unicef_parse_indicator_yaml.ado
*! v 1.0.0   17Jan2026               by Joao Pedro Azevedo (UNICEF)
* Self-contained YAML parsing routine for extracting indicator metadata
*
* Pure function: No globals, no side effects except file I/O
* Accepts: yaml_file path, indicator_upper code
* Returns: indicator metadata via return locals
*
* Purpose: Encapsulate complex YAML parsing logic for reusability and testing
*******************************************************************************

program define __unicef_parse_indicator_yaml, rclass
    version 14.0
    
    syntax , YAMLfile(string) INDicator(string) [VERBOSE]
    
    * Rename locals to match expected names
    local yaml_file "`yamlfile'"
    local indicator_upper "`indicator'"
    
    quietly {
        *-----------------------------------------------------------------------
        * Initialize output variables
        *-----------------------------------------------------------------------
        
        local ind_name ""
        local ind_category ""
        local ind_parent ""
        local ind_dataflow ""
        local ind_desc ""
        local ind_urn ""
        local disagg_raw ""
        local disagg_totals ""
        local tier ""
        local tier_reason ""
        local tier_subcategory ""
        local found 0
        
        *-----------------------------------------------------------------------
        * Build search pattern for indicator header
        *-----------------------------------------------------------------------
        
        local search_pattern "  `indicator_upper':"
        
        *-----------------------------------------------------------------------
        * YAML Parsing: Direct file search with early termination
        * - Open file once, read sequentially
        * - Stop when indicator found and completely parsed
        * - Use state machine to track: in_indicator, in_disaggs, in_dataflows
        *-----------------------------------------------------------------------
        
        * IMPORTANT: Stata macro assignment syntax
        * local x value          CORRECT - direct assignment to macro
        * local x = value        WRONG - invokes expression evaluation
        * Use = ONLY when combining expressions: local x = `y' + 1
        * This matters because = causes Stata to parse the RHS as math/functions,
        * leading to unexpected behavior with string values and slower execution.
        
        tempname fh
        local in_indicator 0
        local lines_checked 0
        
        * OPEN FILE: Open the YAML metadata file once
        file open `fh' using "`yaml_file'", read text
        file read `fh' line
        
        local found_indicator_section 0
        local found_disaggs 0
        local found_dataflows 0
        
        * MAIN LOOP: Read through file sequentially until indicator found
        while r(eof) == 0 {
            local lines_checked = `lines_checked' + 1
            local trimmed_line = strtrim(`"`line'"')
            
            * First pass: Check if we've found our indicator's section
            if (`in_indicator' == 0) {
                * Looking for "  INDICATOR_CODE:" at start of line
                if (substr(`"`line'"', 1, length("`search_pattern'")) == "`search_pattern'") {
                    local in_indicator 1
                    local found 1
                    local found_indicator_section 1
                    if ("`verbose'" != "") {
                        noi di as text "  → ENTER: Line " as result "`lines_checked'" as text " | Key: " as result "`search_pattern'"
                    }
                }
            }
            else if (`in_indicator' == 1) {
                * We're inside the indicator's section
                * Check if we've moved past our indicator
                if (regexm(`"`line'"', "^[^ ]")) {
                    if (regexm("`trimmed_line'", "^[a-zA-Z]") & "`trimmed_line'" != "" & "`trimmed_line'" != "---") {
                        if ("`verbose'" != "") {
                            noi di as text "  ← EXIT: Line " as result "`lines_checked'" as text " | Next key: " as result "`trimmed_line'"
                        }
                        local in_indicator 0
                        local found_indicator_section 0
                        local found_disaggs 0
                        local found_dataflows 0
                    }
                }
                else if (regexm("`trimmed_line'", "^[A-Z0-9_-]+:\s*$") & "`trimmed_line'" != "`search_pattern'") {
                    if ("`verbose'" != "") {
                        noi di as text "  ← EXIT: Line " as result "`lines_checked'" as text " | Next key: " as result "`trimmed_line'"
                    }
                    local in_indicator 0
                    local found_indicator_section 0
                    local found_disaggs 0
                    local found_dataflows 0
                }
                else {
                    * Parse fields and extract disaggregations
                    local trimmed = strtrim(`"`line'"')
                    if ("`trimmed'" != "") {
                        * Check indentation - indicator fields have 4+ spaces
                        local first_char = substr(`"`line'"', 1, 1)
                        local second_char = substr(`"`line'"', 2, 1)
                        
                        * If line starts with "  X" where X is not a space, we've hit next indicator
                        if ("`first_char'" == " " & "`second_char'" == " ") {
                            local third_char = substr(`"`line'"', 3, 1)
                            if ("`third_char'" != " ") {
                                * New top-level key under indicators - we're done
                                local in_indicator 0
                                continue, break
                            }
                        }
                        else if ("`first_char'" != " ") {
                            * No leading space - we've left indicators section entirely
                            local in_indicator 0
                            continue, break
                        }
                        
                        * ===================================================================
                        * FIELD PARSING: "    fieldname: value"
                        * ===================================================================
                        * Handle both scalar values (name: John) and list headers (dataflows:)
                        local colon_pos = strpos("`trimmed'", ":")
                        if (`colon_pos' > 0) {
                            local field_name = strtrim(substr("`trimmed'", 1, `colon_pos' - 1))
                            local field_value = strtrim(substr("`trimmed'", `colon_pos' + 1, .))
                            
                            * Remove surrounding quotes if present
                            if (substr("`field_value'", 1, 1) == "'" | substr("`field_value'", 1, 1) == `"""') {
                                local field_value = substr("`field_value'", 2, length("`field_value'") - 2)
                            }
                            
                            * =========================================================
                            * FIELD TYPE 1: List headers (set flags for list collection)
                            * =========================================================
                            * When we see "disaggregations:" or "dataflows:", set flag
                            * and RESET other list flags (mutually exclusive)
                            if ("`field_name'" == "disaggregations") {
                                * Header for disaggregations list - start collecting items
                                if ("`verbose'" != "") {
                                    noi di as text "    → Capturing: disaggregations" as text " (list header at line " as result "`lines_checked'" as text ")"
                                }
                                local found_disaggs 1
                                local found_dataflows 0
                            }
                            else if ("`field_name'" == "dataflows") {
                                * Header for dataflows list - start collecting items
                                * May have scalar value ("dataflows: MNCH") or be empty ("dataflows:" + list below)
                                local found_dataflows 1
                                local found_disaggs 0
                                
                                * If dataflows has a scalar value, capture it immediately
                                * But exclude empty list notation "[]" which indicates orphan indicator
                                if ("`field_value'" != "" & "`field_value'" != "[]") {
                                    if ("`verbose'" != "") {
                                        noi di as text "    → Captured: dataflows = " as result "`field_value'"
                                    }
                                    local ind_dataflow "`field_value'"
                                    * Don't keep flag active - scalar was already handled
                                    local found_dataflows 0
                                }
                                else if ("`verbose'" != "") {
                                    noi di as text "    → Capturing: dataflows" as text " (list header at line " as result "`lines_checked'" as text ")"
                                }
                            }
                            else if ("`field_name'" == "disaggregations_with_totals") {
                                * Handle inline list format [A,B,C] or scalar value
                                if (regexm(`"`field_value'"', "\[(.*)\]")) {
                                    local disagg_totals regexs(1)
                                }
                                else {
                                    local disagg_totals "`field_value'"
                                }
                                if ("`verbose'" != "") {
                                    noi di as text "    → Captured: disaggregations_with_totals = " as result "`disagg_totals'"
                                }
                                * Reset list collection flags (non-list field)
                                local found_disaggs 0
                                local found_dataflows 0
                            }
                            else {
                                * All other fields: scalars (name, category, parent, etc.)
                                * Reset list collection flags
                                local found_disaggs 0
                                local found_dataflows 0
                            }
                            
                            * =========================================================
                            * FIELD TYPE 2: Scalar fields (extract values directly)
                            * =========================================================
                            if ("`field_name'" == "name") {
                                local ind_name "`field_value'"
                            }
                            else if ("`field_name'" == "category") {
                                local ind_category "`field_value'"
                            }
                            else if ("`field_name'" == "parent") {
                                local ind_parent "`field_value'"
                            }
                            else if ("`field_name'" == "dataflow" | "`field_name'" == "dataflows") {
                                * Handle dataflows that appear as single scalar field
                                * Exclude empty list notation "[]" which indicates orphan indicator
                                if ("`field_value'" != "" & "`field_value'" != "[]") {
                                    local ind_dataflow "`field_value'"
                                }
                            }
                            else if ("`field_name'" == "description") {
                                local ind_desc "`field_value'"
                            }
                            else if ("`field_name'" == "urn") {
                                local ind_urn "`field_value'"
                            }
                            else if ("`field_name'" == "tier") {
                                local tier "`field_value'"
                            }
                            else if ("`field_name'" == "tier_reason") {
                                local tier_reason "`field_value'"
                            }
                            else if ("`field_name'" == "tier_subcategory") {
                                local tier_subcategory "`field_value'"
                            }
                        }
                        
                        * ===================================================================
                        * LIST ITEMS: "^    - ITEM" lines (under active list header)
                        * ===================================================================
                        * Collect items ONLY if we're currently collecting a list
                        * (found_disaggs=1 means we just saw "disaggregations:" header)
                        * (found_dataflows=1 means we just saw "dataflows:" header without scalar)
                        if (regexm("`trimmed'", "^\- ")) {
                            if (regexm("`trimmed'", "^\- +(.+)$")) {
                                local item = regexs(1)
                                local item = strtrim("`item'")
                                
                                * Append to appropriate collection based on active flag
                                if (`found_disaggs' == 1) {
                                    * Append disaggregation item (space-separated list)
                                    if ("`verbose'" != "") {
                                        noi di as text "      + disaggregations item: " as result "`item'"
                                    }
                                    local disagg_raw "`disagg_raw' `item'"
                                }
                                else if (`found_dataflows' == 1) {
                                    * Append dataflow item (comma-separated list)
                                    if ("`verbose'" != "") {
                                        noi di as text "      + dataflows item: " as result "`item'"
                                    }
                                    if ("`ind_dataflow'" == "") {
                                        local ind_dataflow "`item'"
                                    }
                                    else {
                                        local ind_dataflow "`ind_dataflow', `item'"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            * READ NEXT LINE: Advance to next line in the file
            file read `fh' line
        }
        
        * CLOSE FILE: Defensive close using capture to handle edge cases
        capture file close `fh'
        
        if ("`verbose'" != "") {
            noi di as text "Scanned " as result "`lines_checked'" as text " lines"
            noi di as text "  Name: " as result "`ind_name'"
            noi di as text "  Category: " as result "`ind_category'"
            noi di as text "  Dataflow: " as result "`ind_dataflow'"
        }
    } // end quietly
    
    *---------------------------------------------------------------------------
    * Return values via r() macros
    *---------------------------------------------------------------------------
    
    return local ind_name "`ind_name'"
    return local ind_category "`ind_category'"
    return local ind_parent "`ind_parent'"
    return local ind_dataflow "`ind_dataflow'"
    return local ind_desc "`ind_desc'"
    return local ind_urn "`ind_urn'"
    return local tier "`tier'"
    return local tier_reason "`tier_reason'"
    return local tier_subcategory "`tier_subcategory'"
    return local disagg_raw "`disagg_raw'"
    return local disagg_totals "`disagg_totals'"
    return local found `found'
    
end
*! v 1.0.0   17Jan2026               by Joao Pedro Azevedo (UNICEF)
* Extracted from _unicef_indicator_info for reusability and testing
* Handles complex YAML parsing with state machine logic
* Pure function: No globals, no side effects except file I/O

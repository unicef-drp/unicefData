*******************************************************************************
* yaml
*! v 1.1.0   03Dec2025               by Joao Pedro Azevedo (UNICEF)
* Read and write YAML files in Stata
*******************************************************************************

/*
DESCRIPTION:
    Main command for YAML file operations in Stata.
    Supports reading, writing, and displaying YAML data.
    Uses Stata frames (16+) as default storage for YAML data.
    
SYNTAX:
    yaml read using "filename.yaml" [, frame(name) data options]
    yaml write using "filename.yaml" [, frame(name) data options]
    yaml describe [, frame(name) data]
    yaml list [keys] [, frame(name) data options]
    yaml frames [, detail]
    yaml clear [framename] [, all data]
    
SUBCOMMANDS:
    read     - Read YAML file into Stata frame (default) or dataset
    write    - Write Stata data to YAML file
    describe - Display structure of loaded YAML data
    list     - List specific keys or all keys
    frames   - List all YAML frames in memory
    clear    - Clear YAML data from memory (frame or dataset)
    
OPTIONS:
    frame(name) - Specify which YAML frame to use
    data        - Use current dataset instead of frames
    
EXAMPLES:
    yaml read using "config.yaml"             // loads to frame yaml_config
    yaml read using "config.yaml", data       // loads to current dataset
    yaml frames, detail                       // list all yaml frames
    yaml describe                             // describes first yaml frame
    yaml describe, frame(config)              // describes yaml_config frame
    yaml list indicators, values              // list values under indicators
    yaml clear config                         // clears yaml_config frame
    yaml clear, all                           // clears all yaml frames
    
SEE ALSO:
    help yaml
    
REQUIRES:
    Stata 16.0 or later (for frames support)
*/

program define yaml
    version 16.0
    
    gettoken subcmd 0 : 0, parse(" ,")
    
    local subcmd = lower("`subcmd'")
    
    if ("`subcmd'" == "read") {
        yaml_read `0'
    }
    else if ("`subcmd'" == "write") {
        yaml_write `0'
    }
    else if ("`subcmd'" == "describe" | "`subcmd'" == "desc") {
        yaml_describe `0'
    }
    else if ("`subcmd'" == "list") {
        yaml_list `0'
    }
    else if ("`subcmd'" == "frames" | "`subcmd'" == "frame") {
        yaml_frames `0'
    }
    else if ("`subcmd'" == "clear") {
        yaml_clear `0'
    }
    else if ("`subcmd'" == "") {
        di as err "subcommand required"
        di as err "syntax: yaml {read|write|describe|list|frames|clear} ..."
        exit 198
    }
    else {
        di as err "unknown subcommand: `subcmd'"
        di as err "valid subcommands: read, write, describe, list, frames, clear"
        exit 198
    }
end


*******************************************************************************
* yaml read - Read YAML file into Stata
*******************************************************************************

program define yaml_read, rclass
    version 16.0
    
    syntax using/ [, Locals Scalars DATA FRAME(string) Prefix(string) Replace Verbose]
    
    * Set default prefix
    if ("`prefix'" == "") {
        local prefix "yaml_"
    }
    
    * Check file exists
    confirm file "`using'"
    
    * Determine frame name if not specified
    * Default: use filename without path and extension
    if ("`frame'" == "" & "`data'" == "") {
        * Extract filename from path
        local fname "`using'"
        * Remove path (get everything after last / or \)
        while (strpos("`fname'", "/") > 0 | strpos("`fname'", "\") > 0) {
            local pos1 = strpos("`fname'", "/")
            local pos2 = strpos("`fname'", "\")
            local pos = max(`pos1', `pos2')
            local fname = substr("`fname'", `pos' + 1, .)
        }
        * Remove extension
        local dotpos = strpos("`fname'", ".")
        if (`dotpos' > 0) {
            local fname = substr("`fname'", 1, `dotpos' - 1)
        }
        * Clean name for Stata (replace special chars)
        local frame = subinstr("`fname'", "-", "_", .)
        local frame = subinstr("`frame'", " ", "_", .)
        local frame "yaml_`frame'"
    }
    
    * Initialize
    local n_keys = 0
    local max_level = 0
    
    if ("`verbose'" != "") {
        di as text "Reading YAML file: " as result "`using'"
        if ("`data'" == "") {
            di as text "Loading into frame: " as result "`frame'"
        }
        else {
            di as text "Loading into current dataset"
        }
    }
    
    * Prepare storage location
    if ("`data'" != "") {
        * Load into current dataset
        if ("`replace'" == "") {
            if (_N > 0) {
                di as err "Data in memory would be lost. Use 'replace' option."
                exit 4
            }
        }
        clear
        quietly {
            gen str244 key = ""
            gen str2000 value = ""
            gen int level = .
            gen str244 parent = ""
            gen str32 type = ""
        }
        local use_frame = 0
    }
    else {
        * Load into frame (default)
        * Check if frame exists
        capture frame drop `frame'
        if ("`replace'" == "" & _rc == 0) {
            * Frame existed and was dropped - that's ok with replace
        }
        frame create `frame'
        frame `frame' {
            quietly {
                gen str244 key = ""
                gen str2000 value = ""
                gen int level = .
                gen str244 parent = ""
                gen str32 type = ""
            }
        }
        local use_frame = 1
    }
    
    * Read file line by line
    tempname fh
    file open `fh' using "`using'", read text
    
    local linenum = 0
    local current_indent = 0
    local parent_stack ""
    local indent_stack "0"
    
    file read `fh' line
    
    while r(eof) == 0 {
        local linenum = `linenum' + 1
        
        * Skip empty lines and comments
        local trimmed = strtrim("`line'")
        if ("`trimmed'" == "" | substr("`trimmed'", 1, 1) == "#") {
            file read `fh' line
            continue
        }
        
        * Calculate indentation (count leading spaces)
        local indent = 0
        local templine "`line'"
        while (substr("`templine'", 1, 1) == " ") {
            local indent = `indent' + 1
            local templine = substr("`templine'", 2, .)
        }
        
        * Handle indent changes to track parent hierarchy
        if (`indent' > `current_indent') {
            * Going deeper - current key becomes parent
            local indent_stack "`indent_stack' `indent'"
        }
        else if (`indent' < `current_indent') {
            * Going back up - pop parents
            _yaml_pop_parents, indent(`indent') parent_stack(`parent_stack') indent_stack(`indent_stack')
            local parent_stack "`s(parent_stack)'"
            local indent_stack "`s(indent_stack)'"
        }
        local current_indent = `indent'
        
        * Parse the line
        local level = 0
        foreach i of local indent_stack {
            if (`i' <= `indent') local level = `level' + 1
        }
        if (`level' > `max_level') local max_level = `level'
        
        * Check if it's a list item (starts with -)
        local is_list = (substr("`trimmed'", 1, 2) == "- ")
        
        if (`is_list') {
            * List item
            local item_value = strtrim(substr("`trimmed'", 3, .))
            local key = "`last_key'"
            local value "`item_value'"
            local vtype "list_item"
            
            * Append to existing value for this key
            if ("`dataset'" != "") {
                * Find and update the parent key's value
                qui count if key == "`key'"
                if (r(N) > 0) {
                    qui replace value = value + " " + "`item_value'" if key == "`key'"
                }
            }
            else {
                * For locals, append to existing
                local `prefix'`key' "``prefix'`key'' `item_value'"
            }
        }
        else {
            * Key-value pair or nested key
            local colon_pos = strpos("`trimmed'", ":")
            
            if (`colon_pos' > 0) {
                local key = strtrim(substr("`trimmed'", 1, `colon_pos' - 1))
                local value = strtrim(substr("`trimmed'", `colon_pos' + 1, .))
                
                * Remove quotes from value if present
                if (substr("`value'", 1, 1) == `"""' | substr("`value'", 1, 1) == "'") {
                    local value = substr("`value'", 2, length("`value'") - 2)
                }
                
                * Build full key name with parent hierarchy
                local full_key "`key'"
                if ("`parent_stack'" != "") {
                    local full_key "`parent_stack'_`key'"
                }
                
                * Clean key name (replace spaces and special chars with underscore)
                local full_key = subinstr("`full_key'", " ", "_", .)
                local full_key = subinstr("`full_key'", "-", "_", .)
                local full_key = subinstr("`full_key'", ".", "_", .)
                
                * Truncate to ensure prefix + key <= 32 chars (Stata limit)
                local prefixlen = length("`prefix'")
                local maxkeylen = 32 - `prefixlen'
                if (length("`full_key'") > `maxkeylen') {
                    local full_key = substr("`full_key'", 1, `maxkeylen')
                    if ("`verbose'" != "") {
                        di as text "  (key truncated to `maxkeylen' chars)"
                    }
                }
                
                * Determine type
                if ("`value'" == "") {
                    local vtype "parent"
                    * This key becomes a parent for nested items
                    local parent_stack "`full_key'"
                    local last_key "`full_key'"
                }
                else {
                    * Check if numeric
                    capture confirm number `value'
                    if (_rc == 0) {
                        local vtype "numeric"
                    }
                    else if (inlist("`value'", "true", "True", "TRUE", "yes", "Yes", "YES")) {
                        local vtype "boolean"
                        local value "1"
                    }
                    else if (inlist("`value'", "false", "False", "FALSE", "no", "No", "NO")) {
                        local vtype "boolean"
                        local value "0"
                    }
                    else if ("`value'" == "null" | "`value'" == "~") {
                        local vtype "null"
                        local value ""
                    }
                    else {
                        local vtype "string"
                    }
                    local last_key "`full_key'"
                }
                
                local n_keys = `n_keys' + 1
                
                * Store the value in frame or dataset
                if (`use_frame' == 1) {
                    * Add row to frame
                    frame `frame' {
                        local newobs = _N + 1
                        qui set obs `newobs'
                        qui replace key = "`full_key'" in `newobs'
                        qui replace value = `"`value'"' in `newobs'
                        qui replace level = `level' in `newobs'
                        qui replace parent = "`parent_stack'" in `newobs'
                        qui replace type = "`vtype'" in `newobs'
                    }
                }
                else if ("`data'" != "") {
                    * Add row to current dataset
                    local newobs = _N + 1
                    qui set obs `newobs'
                    qui replace key = "`full_key'" in `newobs'
                    qui replace value = `"`value'"' in `newobs'
                    qui replace level = `level' in `newobs'
                    qui replace parent = "`parent_stack'" in `newobs'
                    qui replace type = "`vtype'" in `newobs'
                }
                
                if ("`locals'" != "") {
                    * Store as return local
                    if ("`value'" != "") {
                        return local `prefix'`full_key' `"`value'"'
                        
                        if ("`verbose'" != "") {
                            di as text "  `prefix'`full_key' = " as result `"`value'"'
                        }
                    }
                }
                
                if ("`scalars'" != "" & "`vtype'" == "numeric") {
                    * Store as scalar
                    scalar `prefix'`full_key' = real("`value'")
                    
                    if ("`verbose'" != "") {
                        di as text "  scalar `prefix'`full_key' = " as result `value'
                    }
                }
            }
        }
        
        file read `fh' line
    }
    
    file close `fh'
    
    * Clean up frame or dataset
    if (`use_frame' == 1) {
        frame `frame' {
            qui drop if key == ""
            qui compress
            
            * Add variable labels
            label variable key "YAML key name"
            label variable value "YAML value"
            label variable level "Nesting level (1=root)"
            label variable parent "Parent key"
            label variable type "Value type"
        }
        
        if ("`verbose'" != "") {
            frame `frame' {
                di as text ""
                di as text "Loaded " as result _N as text " key-value pairs into frame " as result "`frame'" as text "."
            }
        }
        
        return local frame "`frame'"
    }
    else if ("`data'" != "") {
        qui drop if key == ""
        qui compress
        
        * Add variable labels
        label variable key "YAML key name"
        label variable value "YAML value"
        label variable level "Nesting level (1=root)"
        label variable parent "Parent key"
        label variable type "Value type"
        
        if ("`verbose'" != "") {
            di as text ""
            di as text "Loaded " as result _N as text " key-value pairs into dataset."
        }
    }
    
    * Return values
    return local filename "`using'"
    return scalar n_keys = `n_keys'
    return scalar max_level = `max_level'
    
    if ("`verbose'" != "") {
        di as text ""
        di as text "Successfully parsed " as result `n_keys' as text " keys from YAML file."
        di as text "Maximum nesting level: " as result `max_level'
    }

end


*******************************************************************************
* yaml write - Write Stata data to YAML file
*******************************************************************************

program define yaml_write
    version 16.0
    
    syntax using/ [, Locals(string) Scalars(string) DATA FRAME(string) Replace Verbose ///
                     INDENT(integer 2) HEADER(string)]
    
    * Check if file exists and handle replace
    capture confirm file "`using'"
    if (_rc == 0 & "`replace'" == "") {
        di as err "file `using' already exists. Use 'replace' option."
        exit 602
    }
    
    * Open file for writing
    tempname fh
    file open `fh' using "`using'", write text replace
    
    * Write header comment if specified
    if ("`header'" != "") {
        file write `fh' "# `header'" _n
    }
    else {
        file write `fh' "# Generated by Stata yaml write" _n
        file write `fh' "# Date: `c(current_date)' `c(current_time)'" _n
    }
    file write `fh' _n
    
    local n_written = 0
    
    * Write from locals
    if ("`locals'" != "") {
        foreach loc of local locals {
            local val "``loc''"
            if ("`val'" != "") {
                file write `fh' "`loc': `val'" _n
                local n_written = `n_written' + 1
                
                if ("`verbose'" != "") {
                    di as text "  `loc': " as result "`val'"
                }
            }
        }
    }
    
    * Write from scalars
    if ("`scalars'" != "") {
        foreach sc of local scalars {
            capture confirm scalar `sc'
            if (_rc == 0) {
                local val = `sc'
                file write `fh' "`sc': `val'" _n
                local n_written = `n_written' + 1
                
                if ("`verbose'" != "") {
                    di as text "  `sc': " as result "`val'"
                }
            }
        }
    }
    
    * Write from frame or dataset
    if ("`frame'" != "" | "`data'" != "") {
        
        * Determine source
        if ("`frame'" != "") {
            * Check frame exists
            capture frame `frame': describe, short
            if (_rc != 0) {
                di as err "frame `frame' not found"
                file close `fh'
                exit 198
            }
            local source_frame "`frame'"
        }
        else {
            local source_frame ""
        }
        
        * Helper to write from a frame or current data
        if ("`source_frame'" != "") {
            frame `source_frame' {
                _yaml_write_data `fh', indent(`indent') verbose(`verbose')
            }
            local n_written = r(n_written)
        }
        else {
            * Write from current dataset
            * Check required variables exist
            capture confirm variable key value
            if (_rc != 0) {
                di as err "dataset must have 'key' and 'value' variables"
                file close `fh'
                exit 198
            }
            
            * Check for level variable for indentation
            capture confirm variable level
            local has_level = (_rc == 0)
            
            local n = _N
            local prev_level = 1
            
            forvalues i = 1/`n' {
                local k = key[`i']
                local v = value[`i']
                
                if (`has_level') {
                    local lev = level[`i']
                }
                else {
                    local lev = 1
                }
                
                * Create indentation
                local spaces ""
                forvalues j = 1/`=(`lev'-1)*`indent'' {
                    local spaces "`spaces' "
                }
                
                * Get type if available
                capture confirm variable type
                if (_rc == 0) {
                    local t = type[`i']
                }
                else {
                    local t "string"
                }
                
                * Write based on type
                if ("`t'" == "parent") {
                    file write `fh' "`spaces'`k':" _n
                }
                else if ("`v'" != "") {
                    file write `fh' "`spaces'`k': `v'" _n
                }
                
                local n_written = `n_written' + 1
            }
        }
    }
    
    file close `fh'
    
    if ("`verbose'" != "") {
        di as text ""
        di as text "Wrote " as result `n_written' as text " entries to " as result "`using'"
    }
    
    di as text "YAML file saved: " as result "`using'"
    
end


*******************************************************************************
* yaml describe - Display structure of loaded YAML data
*******************************************************************************

program define yaml_describe
    version 16.0
    syntax [, LEVEL(integer 99) FRAME(string) DATA]
    
    * Determine source - frame or current data
    if ("`frame'" != "") {
        * Check frame exists
        capture frame `frame': describe, short
        if (_rc != 0) {
            di as err "frame `frame' not found"
            exit 198
        }
        frame `frame' {
            _yaml_describe_impl, level(`level')
        }
    }
    else if ("`data'" != "") {
        * Use current dataset
        capture confirm variable key value level
        if (_rc != 0) {
            di as err "No YAML data in current dataset."
            exit 198
        }
        _yaml_describe_impl, level(`level')
    }
    else {
        * Try to find a yaml frame
        local yaml_frames ""
        qui frames dir
        local all_frames "`r(frames)'"
        foreach f of local all_frames {
            if (substr("`f'", 1, 5) == "yaml_") {
                local yaml_frames "`yaml_frames' `f'"
            }
        }
        if ("`yaml_frames'" == "") {
            di as err "No YAML frames found. Use 'yaml read using file.yaml' first."
            exit 198
        }
        * Use first yaml frame found
        local first_frame : word 1 of `yaml_frames'
        di as text "(using frame: `first_frame')"
        frame `first_frame' {
            _yaml_describe_impl, level(`level')
        }
    }
end

program define _yaml_describe_impl
    syntax [, LEVEL(integer 99)]
    
    capture confirm variable key value level
    if (_rc != 0) {
        di as err "No YAML data found."
        exit 198
    }
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:YAML Structure}"
    di as text "{hline 70}"
    
    local n = _N
    forvalues i = 1/`n' {
        local k = key[`i']
        local v = value[`i']
        local l = level[`i']
        local t = type[`i']
        
        * Skip if beyond requested level
        if (`l' > `level') continue
        
        * Create indentation
        local spaces ""
        forvalues j = 1/`=`l'-1' {
            local spaces "`spaces'  "
        }
        
        if ("`t'" == "parent") {
            di as text "`spaces'" as result "`k'" as text ":"
        }
        else {
            local display_val = substr("`v'", 1, 40)
            if (length("`v'") > 40) local display_val "`display_val'..."
            di as text "`spaces'" as result "`k'" as text ": " as text `"`display_val'"'
        }
    }
    
    di as text "{hline 70}"
    di as text "Total keys: " as result `n'
    di as text "{hline 70}"
end


*******************************************************************************
* yaml list - List specific keys or all keys
*******************************************************************************

program define yaml_list, rclass
    version 16.0
    syntax [anything] [, NOHeader Keys Values SEParator(string) CHILDren STATA FRAME(string) DATA]
    
    * Determine source - frame or current data
    if ("`frame'" != "") {
        * Check frame exists
        capture frame `frame': describe, short
        if (_rc != 0) {
            di as err "frame `frame' not found"
            exit 198
        }
        frame `frame' {
            _yaml_list_impl `anything', `noheader' `keys' `values' separator(`separator') `children' `stata'
        }
        * Copy return values from frame execution
        return add
    }
    else if ("`data'" != "") {
        * Use current dataset
        capture confirm variable key value
        if (_rc != 0) {
            di as err "No YAML data in current dataset."
            exit 198
        }
        _yaml_list_impl `anything', `noheader' `keys' `values' separator(`separator') `children' `stata'
        return add
    }
    else {
        * Try to find a yaml frame
        local yaml_frames ""
        qui frames dir
        local all_frames "`r(frames)'"
        foreach f of local all_frames {
            if (substr("`f'", 1, 5) == "yaml_") {
                local yaml_frames "`yaml_frames' `f'"
            }
        }
        if ("`yaml_frames'" == "") {
            di as err "No YAML frames found. Use 'yaml read using file.yaml' first."
            exit 198
        }
        * Use first yaml frame found
        local first_frame : word 1 of `yaml_frames'
        di as text "(using frame: `first_frame')"
        frame `first_frame' {
            _yaml_list_impl `anything', `noheader' `keys' `values' separator(`separator') `children' `stata'
        }
        return add
    }
end

program define _yaml_list_impl, rclass
    syntax [anything] [, NOHeader Keys Values SEParator(string) CHILDren STATA]
    
    capture confirm variable key value
    if (_rc != 0) {
        di as err "No YAML data found."
        exit 198
    }
    
    * Default separator - if stata format requested, use compound quotes
    if ("`stata'" != "") {
        local sep_start `" `""'
        local sep_end `"""'
    }
    else if ("`separator'" == "") {
        local sep_start " "
        local sep_end ""
    }
    else {
        local sep_start "`separator'"
        local sep_end ""
    }
    
    if ("`anything'" == "") {
        * List all
        if ("`keys'" != "" | "`values'" != "") {
            * Return all keys or values as delimited list
            local result_keys ""
            local result_values ""
            local n = _N
            forvalues i = 1/`n' {
                local k = key[`i']
                local v = value[`i']
                if ("`result_keys'" == "") {
                    if ("`stata'" != "") {
                        local result_keys `"`"`k'"'"'
                        local result_values `"`"`v'"'"'
                    }
                    else {
                        local result_keys "`k'"
                        local result_values `"`v'"'
                    }
                }
                else {
                    if ("`stata'" != "") {
                        local result_keys `"`result_keys' `"`k'"'"'
                        local result_values `"`result_values' `"`v'"'"'
                    }
                    else {
                        local result_keys "`result_keys'`sep_start'`k'`sep_end'"
                        local result_values `"`result_values'`sep_start'`v'`sep_end'"'
                    }
                }
            }
            if ("`keys'" != "") {
                return local keys `"`result_keys'"'
                di as text "Keys: " as result `"`result_keys'"'
            }
            if ("`values'" != "") {
                return local values `"`result_values'"'
                di as text "Values: " as result `"`result_values'"'
            }
        }
        else {
            list key value type, `noheader'
        }
    }
    else {
        * Filter by parent/pattern
        local pattern "`anything'"
        
        * Create match variable
        tempvar match is_child
        qui gen `match' = 0
        qui gen `is_child' = 0
        
        * Match keys that start with the pattern (children of that parent)
        if ("`children'" != "") {
            * Only get immediate children of the parent
            qui replace `is_child' = 1 if strpos(key, "`pattern'_") == 1
            * Exclude grandchildren (keys with more than one underscore after pattern)
            qui replace `is_child' = 0 if regexm(substr(key, length("`pattern'_") + 1, .), "_")
            qui replace `match' = `is_child'
        }
        else {
            * Match any key containing the pattern
            qui replace `match' = 1 if strpos(key, "`pattern'") > 0
        }
        
        if ("`keys'" != "" | "`values'" != "") {
            * Return matching keys/values as delimited list
            local result_keys ""
            local result_values ""
            local n = _N
            forvalues i = 1/`n' {
                if (`match'[`i'] == 1) {
                    local k = key[`i']
                    local v = value[`i']
                    
                    * For children option, extract just the child name
                    if ("`children'" != "") {
                        local k = substr("`k'", length("`pattern'_") + 1, .)
                    }
                    
                    if ("`result_keys'" == "") {
                        if ("`stata'" != "") {
                            local result_keys `"`"`k'"'"'
                            local result_values `"`"`v'"'"'
                        }
                        else {
                            local result_keys "`k'"
                            local result_values `"`v'"'
                        }
                    }
                    else {
                        if ("`stata'" != "") {
                            local result_keys `"`result_keys' `"`k'"'"'
                            local result_values `"`result_values' `"`v'"'"'
                        }
                        else {
                            local result_keys "`result_keys'`sep_start'`k'`sep_end'"
                            local result_values `"`result_values'`sep_start'`v'`sep_end'"'
                        }
                    }
                }
            }
            if ("`keys'" != "") {
                return local keys `"`result_keys'"'
                di as text "Keys under `pattern': " as result `"`result_keys'"'
            }
            if ("`values'" != "") {
                return local values `"`result_values'"'
                di as text "Values under `pattern': " as result `"`result_values'"'
            }
            return local parent "`pattern'"
        }
        else {
            list key value type if `match' == 1, `noheader'
        }
        drop `match' `is_child'
    }
end


*******************************************************************************
* yaml clear - Clear YAML data from memory (frames or data)
*******************************************************************************

program define yaml_clear
    version 16.0
    syntax [anything] [, ALL DATA]
    
    * If data option specified, clear current dataset
    if ("`data'" != "") {
        capture confirm variable key value level parent type
        if (_rc == 0) {
            clear
            di as text "YAML data cleared from current dataset."
        }
        else {
            di as text "No YAML data in current dataset."
        }
        exit
    }
    
    * Otherwise work with frames
    local frame_to_clear = trim("`anything'")
    
    if ("`all'" != "") {
        * Clear all yaml_* frames
        local cleared = 0
        quietly frames dir
        local all_frames `r(frames)'
        foreach fr of local all_frames {
            if (substr("`fr'", 1, 5) == "yaml_") {
                frame drop `fr'
                local cleared = `cleared' + 1
            }
        }
        if (`cleared' > 0) {
            di as text "`cleared' YAML frame(s) cleared from memory."
        }
        else {
            di as text "No YAML frames in memory."
        }
    }
    else if ("`frame_to_clear'" != "") {
        * Clear specific frame
        local target_frame = "`frame_to_clear'"
        if (substr("`target_frame'", 1, 5) != "yaml_") {
            local target_frame "yaml_`target_frame'"
        }
        capture frame drop `target_frame'
        if (_rc == 0) {
            di as text "Frame `target_frame' cleared from memory."
        }
        else {
            di as error "Frame `target_frame' not found."
            exit 198
        }
    }
    else {
        * List available yaml frames and prompt
        di as text "Available YAML frames:"
        quietly frames dir
        local all_frames `r(frames)'
        local count = 0
        foreach fr of local all_frames {
            if (substr("`fr'", 1, 5) == "yaml_") {
                di as text "  `fr'"
                local count = `count' + 1
            }
        }
        if (`count' == 0) {
            di as text "  (none)"
        }
        else {
            di as text ""
            di as text "Use {cmd:yaml clear {it:framename}} to clear a specific frame"
            di as text "Use {cmd:yaml clear, all} to clear all YAML frames"
        }
    }
end


*******************************************************************************
* yaml frames - List all YAML frames in memory
*******************************************************************************

program define yaml_frames
    version 16.0
    syntax [, DETail]
    
    quietly frames dir
    local all_frames `r(frames)'
    local count = 0
    
    di as text ""
    di as text "{hline 60}"
    di as text "YAML Frames in Memory"
    di as text "{hline 60}"
    
    foreach fr of local all_frames {
        if (substr("`fr'", 1, 5) == "yaml_") {
            local count = `count' + 1
            local yaml_name = substr("`fr'", 6, .)
            
            if ("`detail'" != "") {
                * Get observation count
                frame `fr' {
                    quietly count
                    local nobs = r(N)
                }
                di as text "  `count'. {cmd:`yaml_name'} ({result:`nobs'} entries) - frame: `fr'"
            }
            else {
                di as text "  `count'. {cmd:`yaml_name'}"
            }
        }
    }
    
    if (`count' == 0) {
        di as text "  (no YAML frames loaded)"
    }
    
    di as text "{hline 60}"
    di as text "Total: `count' YAML frame(s)"
    di as text ""
end


*******************************************************************************
* Helper program to manage parent stack based on indentation
*******************************************************************************

program define _yaml_pop_parents, sclass
    syntax, indent(integer) parent_stack(string) indent_stack(string)
    
    * Pop indent levels that are >= current indent
    local new_indent_stack ""
    local new_parent_stack ""
    local count = 0
    
    foreach i of local indent_stack {
        if (`i' < `indent') {
            local new_indent_stack "`new_indent_stack' `i'"
            local count = `count' + 1
        }
    }
    
    * Rebuild parent stack (simplified - just keep last parent at lower indent)
    if (`count' <= 1) {
        local new_parent_stack ""
    }
    else {
        * Keep parent stack but trim to match indent level
        local nwords : word count `parent_stack'
        if (`nwords' > 0) {
            local pos = 0
            forvalues j = 1/`=length("`parent_stack'")' {
                if (substr("`parent_stack'", `j', 1) == "_") {
                    local pos = `j'
                }
            }
            if (`pos' > 0 & `count' <= 2) {
                local new_parent_stack = substr("`parent_stack'", 1, `pos' - 1)
            }
            else {
                local new_parent_stack "`parent_stack'"
            }
        }
    }
    
    sreturn local indent_stack "`new_indent_stack'"
    sreturn local parent_stack "`new_parent_stack'"
end

*******************************************************************************
* _xmltoyaml_parse_lines
*! v 1.2.0   06Dec2025               by Joao Pedro Azevedo (UNICEF)
* Line-by-line parser helper (for small files)
* Following wbopendata approach: strip quotes immediately after file read
*******************************************************************************

program define _xmltoyaml_parse_lines, rclass
    version 14.0
    
    syntax, FILEHANDLE(name) INPUTFILE(string) TYPE(string) ///
        IDATTR(string) OPENTAG(string) CLOSETAG(string) ///
        [NAMEELEMENT(string) DESCELEMENT(string) EXTRAATTRS(string)]
    
    * Use the passed file handle
    local fh `filehandle'
    
    local count = 0
    tempname infh
    
    capture file open `infh' using "`inputfile'", read text
    if (_rc != 0) {
        return scalar count = 0
        exit
    }
    
    * Use tags from schema (passed as parameters)
    local open_tag "`opentag'"
    local close_tag "`closetag'"
    
    * For searching id= with quote (before stripping)
    local dq = char(34)
    local id_pattern_quoted `"id=`dq'"'
    * For searching id= after stripping quotes
    local id_pattern "id="
    
    * Multi-line element accumulator
    local in_element = 0
    local element_buffer ""
    
    file read `infh' line
    while !r(eof) {
        * CRITICAL: Strip quotes IMMEDIATELY after file read (wbopendata approach)
        local line = subinstr(`"`line'"', `"""', "", .)
        
        * Now work with quote-free line
        * Check if line contains element opening tag
        local has_open = (strpos("`line'", "`open_tag'") > 0)
        local has_id = (strpos("`line'", "`id_pattern'") > 0)
        
        if (`has_open' & `has_id' & `in_element' == 0) {
            * Start of a new element
            local in_element = 1
            local element_buffer "`line'"
            
            * Check if element closes on same line
            if (strpos("`line'", "`close_tag'") > 0) {
                * Complete element on single line - write directly
                * Element is already quote-free, extract ID and write YAML
                local elem "`element_buffer'"
                
                * Extract ID - find id= and get value until > or space
                local pos = strpos("`elem'", "`idattr'=")
                if (`pos' > 0) {
                    local value_start = `pos' + strlen("`idattr'=")
                    local tmp = substr("`elem'", `value_start', .)
                    local end_pos = strpos("`tmp'", ">")
                    local space_pos = strpos("`tmp'", " ")
                    if (`space_pos' > 0 & (`space_pos' < `end_pos' | `end_pos' == 0)) {
                        local end_pos = `space_pos'
                    }
                    if (`end_pos' > 0) {
                        local id = substr("`tmp'", 1, `end_pos' - 1)
                    }
                    else {
                        local id = "`tmp'"
                    }
                    
                    if ("`id'" != "") {
                        * Extract name if name element specified
                        local name ""
                        if ("`nameelement'" != "") {
                            local name_start = strpos("`elem'", "<`nameelement'")
                            if (`name_start' > 0) {
                                local tmp2 = substr("`elem'", `name_start', .)
                                local content_start = strpos("`tmp2'", ">")
                                if (`content_start' > 0) {
                                    local tmp3 = substr("`tmp2'", `content_start' + 1, .)
                                    local content_end = strpos("`tmp3'", "</")
                                    if (`content_end' > 0) {
                                        local name = substr("`tmp3'", 1, min(`content_end' - 1, 200))
                                        local name = subinstr("`name'", "'", "''", .)
                                        local name = trim(itrim("`name'"))
                                    }
                                }
                            }
                        }
                        
                        * Write YAML entry
                        file write `fh' "  - id: `id'" _n
                        if ("`name'" != "") {
                            file write `fh' `"    name: '`name''"' _n
                        }
                        local count = `count' + 1
                    }
                }
                
                local in_element = 0
                local element_buffer ""
            }
        }
        else if (`in_element' == 1) {
            * Continue accumulating element content
            local buflen = strlen("`element_buffer'")
            if (`buflen' < 32000) {
                local element_buffer "`element_buffer' `line'"
            }
            
            * Check if element closes
            if (strpos("`line'", "`close_tag'") > 0) {
                * Complete element - process it inline
                local elem "`element_buffer'"
                
                * Extract ID
                local pos = strpos("`elem'", "`idattr'=")
                if (`pos' > 0) {
                    local value_start = `pos' + strlen("`idattr'=")
                    local tmp = substr("`elem'", `value_start', .)
                    local end_pos = strpos("`tmp'", ">")
                    local space_pos = strpos("`tmp'", " ")
                    if (`space_pos' > 0 & (`space_pos' < `end_pos' | `end_pos' == 0)) {
                        local end_pos = `space_pos'
                    }
                    if (`end_pos' > 0) {
                        local id = substr("`tmp'", 1, `end_pos' - 1)
                    }
                    else {
                        local id = "`tmp'"
                    }
                    
                    if ("`id'" != "") {
                        * Extract name
                        local name ""
                        if ("`nameelement'" != "") {
                            local name_start = strpos("`elem'", "<`nameelement'")
                            if (`name_start' > 0) {
                                local tmp2 = substr("`elem'", `name_start', .)
                                local content_start = strpos("`tmp2'", ">")
                                if (`content_start' > 0) {
                                    local tmp3 = substr("`tmp2'", `content_start' + 1, .)
                                    local content_end = strpos("`tmp3'", "</")
                                    if (`content_end' > 0) {
                                        local name = substr("`tmp3'", 1, min(`content_end' - 1, 200))
                                        local name = subinstr("`name'", "'", "''", .)
                                        local name = trim(itrim("`name'"))
                                    }
                                }
                            }
                        }
                        
                        * Write YAML entry
                        file write `fh' "  - id: `id'" _n
                        if ("`name'" != "") {
                            file write `fh' `"    name: '`name''"' _n
                        }
                        local count = `count' + 1
                    }
                }
                
                local in_element = 0
                local element_buffer ""
            }
        }
        
        file read `infh' line
    }
    
    file close `infh'
    
    return scalar count = `count'
end

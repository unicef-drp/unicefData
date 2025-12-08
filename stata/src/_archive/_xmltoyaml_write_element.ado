*******************************************************************************
* _xmltoyaml_write_element
*! v 1.1.0   06Dec2025               by Joao Pedro Azevedo (UNICEF)
* Write a single XML element to YAML output
* Uses wbopendata approach: strip quotes first, then parse
*******************************************************************************

program define _xmltoyaml_write_element, rclass
    version 14.0
    
    syntax, FILEHANDLE(name) ELEMENT(string asis) TYPE(string) IDATTR(string) ///
        [NAMEELEMENT(string) DESCELEMENT(string) EXTRAATTRS(string)]
    
    local fh `filehandle'
    local success = 0
    
    * Store original element with quotes for content extraction
    local elem_orig `"`macval(element)'"'
    
    * Strip all double quotes for attribute extraction
    * Use subinstr function with char(34) representing the quote character
    local elem = subinstr(`"`macval(element)'"', char(34), "", .)
    
    * DEBUG: Show what we got
    di "DEBUG: elem_orig length = " strlen(`"`macval(elem_orig)'"')
    di "DEBUG: elem after quote removal:"
    di "`elem'"
    
    * Extract ID attribute (e.g., id=VALUE after quote removal)
    * After removing quotes: id=VALUE> so we find id= and extract until >
    local id ""
    local attr_pattern = "`idattr'="
    di "DEBUG: looking for attr_pattern = [" "`attr_pattern'" "]"
    local pos = strpos("`elem'", "`attr_pattern'")
    di "DEBUG: pos = " `pos'
    if (`pos' > 0) {
        * Skip past "id=" to get the value
        local value_start = `pos' + strlen("`attr_pattern'")
        local tmp = substr("`elem'", `value_start', .)
        di "DEBUG: tmp after id= = [" "`tmp'" "]"
        * Find the end of the value (either > or space)
        local end_pos = strpos("`tmp'", ">")
        local space_pos = strpos("`tmp'", " ")
        di "DEBUG: end_pos (>) = " `end_pos' ", space_pos = " `space_pos'
        if (`space_pos' > 0 & (`space_pos' < `end_pos' | `end_pos' == 0)) {
            local end_pos = `space_pos'
        }
        if (`end_pos' > 0) {
            local id = substr("`tmp'", 1, `end_pos' - 1)
        }
        else {
            local id = "`tmp'"
        }
        di "DEBUG: extracted id = [" "`id'" "]"
    }
    
    if ("`id'" == "") {
        di "DEBUG: ID is empty, returning failure"
        return scalar success = 0
        exit
    }
    
    * Extract name element content (use original with quotes for XML content)
    local name ""
    if ("`nameelement'" != "") {
        * Find opening tag
        local name_start = strpos(`"`macval(elem_orig)'"', "<`nameelement'")
        if (`name_start' > 0) {
            local tmp = substr(`"`macval(elem_orig)'"', `name_start', .)
            * Find end of opening tag (the >)
            local content_start = strpos(`"`macval(tmp)'"', ">")
            if (`content_start' > 0) {
                local tmp2 = substr(`"`macval(tmp)'"', `content_start' + 1, .)
                * Find closing tag
                local content_end = strpos(`"`macval(tmp2)'"', "</")
                if (`content_end' > 0) {
                    local name = substr(`"`macval(tmp2)'"', 1, min(`content_end' - 1, 200))
                    * Escape single quotes for YAML
                    local name = subinstr(`"`macval(name)'"', "'", "''", .)
                    local name = trim(itrim(`"`macval(name)'"'))
                }
            }
        }
    }
    
    * Extract description element content
    local description ""
    if ("`descelement'" != "") {
        local desc_start = strpos(`"`macval(elem_orig)'"', "<`descelement'")
        if (`desc_start' > 0) {
            local tmp = substr(`"`macval(elem_orig)'"', `desc_start', .)
            local content_start = strpos(`"`macval(tmp)'"', ">")
            if (`content_start' > 0) {
                local tmp2 = substr(`"`macval(tmp)'"', `content_start' + 1, .)
                local content_end = strpos(`"`macval(tmp2)'"', "</")
                if (`content_end' > 0) {
                    local description = substr(`"`macval(tmp2)'"', 1, min(`content_end' - 1, 200))
                    local description = subinstr(`"`macval(description)'"', "'", "''", .)
                    local description = trim(itrim(`"`macval(description)'"'))
                }
            }
        }
    }
    
    * Extract extra attributes (version, position, agencyID) from quote-stripped version
    local version ""
    local position ""
    local agencyid ""
    
    foreach attr in `extraattrs' {
        local attr_val ""
        local attr_pattern = "`attr'="
        local pos = strpos("`elem'", "`attr_pattern'")
        if (`pos' > 0) {
            local tmp = substr("`elem'", `pos', .)
            local tmp = word("`tmp'", 1)
            local attr_val = subinstr("`tmp'", "`attr_pattern'", "", .)
        }
        if ("`attr'" == "version") local version "`attr_val'"
        if ("`attr'" == "position") local position "`attr_val'"
        if ("`attr'" == "agencyID") local agencyid "`attr_val'"
    }
    
    * Extract codelist reference (for dimensions/attributes)
    local codelist ""
    if ("`type'" == "dimensions" | "`type'" == "attributes") {
        local ref_pattern = "<Ref id="
        local ref_pos = strpos("`elem'", "`ref_pattern'")
        if (`ref_pos' > 0) {
            local tmp = substr("`elem'", `ref_pos', .)
            * After quote removal, id=VALUE is followed by space or >
            local tmp = subinstr("`tmp'", "`ref_pattern'", "", .)
            * Get just the ID value (first token before space or >)
            local tmp = word("`tmp'", 1)
            * Remove any trailing > or />
            local codelist = subinstr("`tmp'", ">", "", .)
            local codelist = subinstr("`codelist'", "/", "", .)
        }
    }
    
    * Write YAML output based on type
    if ("`type'" == "dataflows") {
        file write `fh' "- id: `id'" _n
        file write `fh' "  name: '`name''" _n
        if ("`version'" != "") {
            file write `fh' "  version: '`version''" _n
        }
        if ("`agencyid'" != "") {
            file write `fh' "  agency_id: `agencyid'" _n
        }
        local success = 1
    }
    else if ("`type'" == "codelists") {
        file write `fh' "- id: `id'" _n
        file write `fh' "  name: '`name''" _n
        if ("`description'" != "") {
            file write `fh' "  description: '`description''" _n
        }
        local success = 1
    }
    else if ("`type'" == "countries" | "`type'" == "regions") {
        file write `fh' "- id: `id'" _n
        file write `fh' "  name: '`name''" _n
        local success = 1
    }
    else if ("`type'" == "dimensions") {
        file write `fh' "- id: `id'" _n
        if ("`position'" != "") {
            file write `fh' "  position: `position'" _n
        }
        if ("`codelist'" != "") {
            file write `fh' "  codelist: `codelist'" _n
        }
        local success = 1
    }
    else if ("`type'" == "attributes") {
        file write `fh' "- id: `id'" _n
        if ("`codelist'" != "") {
            file write `fh' "  codelist: `codelist'" _n
        }
        local success = 1
    }
    else if ("`type'" == "indicators") {
        local category = ""
        local underscore_pos = strpos("`id'", "_")
        if (`underscore_pos' > 0) {
            local category = substr("`id'", 1, `underscore_pos' - 1)
        }
        else {
            local category = "`id'"
        }
        
        file write `fh' "  `id':" _n
        file write `fh' "    category: `category'" _n
        file write `fh' "    code: `id'" _n
        file write `fh' "    description: '`description''" _n
        file write `fh' "    name: '`name''" _n
        local success = 1
    }
    
    return scalar success = `success'
end

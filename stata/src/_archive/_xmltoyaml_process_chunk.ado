*******************************************************************************
* _xmltoyaml_process_chunk
*! v 1.0.1   06Dec2025               by Joao Pedro Azevedo (UNICEF)
* Process a single XML element chunk and write YAML
*******************************************************************************

program define _xmltoyaml_process_chunk, rclass
    version 14.0
    
    syntax, FILEHANDLE(name) ELEMENT(string) TYPE(string) IDATTR(string) ///
        [NAMEELEMENT(string) DESCELEMENT(string) EXTRAATTRS(string)]
    
    local fh `filehandle'
    local success = 0
    
    * Extract ID attribute - find attr= then skip quote
    local id ""
    local attr_prefix = "`idattr'="
    local pos = strpos(`"`element'"', "`attr_prefix'")
    if (`pos' > 0) {
        * Skip past attr= and opening quote
        local tmp = substr(`"`element'"', `pos' + strlen("`attr_prefix'") + 1, .)
        local pos2 = ustrpos(`"`tmp'"', uchar(34))
        if (`pos2' > 0) {
            local id = substr(`"`tmp'"', 1, `pos2' - 1)
        }
    }
    
    if ("`id'" == "") {
        return scalar success = 0
        exit
    }
    
    * Extract name element content (if specified)
    local name ""
    if ("`nameelement'" != "") {
        local name_start = strpos(`"`element'"', "<`nameelement'")
        if (`name_start' > 0) {
            local tmp = substr(`"`element'"', `name_start', .)
            local content_start = strpos(`"`tmp'"', ">")
            if (`content_start' > 0) {
                local tmp2 = substr(`"`tmp'"', `content_start' + 1, .)
                local content_end = strpos(`"`tmp2'"', "</")
                if (`content_end' > 0) {
                    local name = substr(`"`tmp2'"', 1, min(`content_end' - 1, 200))
                    local name = subinstr(`"`name'"', "'", "''", .)
                    local name = trim(itrim(`"`name'"'))
                }
            }
        }
    }
    
    * Extract description (if specified)
    local description ""
    if ("`descelement'" != "") {
        local desc_start = strpos(`"`element'"', "<`descelement'")
        if (`desc_start' > 0) {
            local tmp = substr(`"`element'"', `desc_start', .)
            local content_start = strpos(`"`tmp'"', ">")
            if (`content_start' > 0) {
                local tmp2 = substr(`"`tmp'"', `content_start' + 1, .)
                local content_end = strpos(`"`tmp2'"', "</")
                if (`content_end' > 0) {
                    local description = substr(`"`tmp2'"', 1, min(`content_end' - 1, 200))
                    local description = subinstr(`"`description'"', "'", "''", .)
                    local description = trim(itrim(`"`description'"'))
                }
            }
        }
    }
    
    * Extract extra attributes - find attr= then skip quote
    local version ""
    local position ""
    local agencyid ""
    
    foreach attr in `extraattrs' {
        local attr_val ""
        local attr_prefix = "`attr'="
        local pos = strpos(`"`element'"', "`attr_prefix'")
        if (`pos' > 0) {
            local tmp = substr(`"`element'"', `pos' + strlen("`attr_prefix'") + 1, .)
            local pos2 = ustrpos(`"`tmp'"', uchar(34))
            if (`pos2' > 0) {
                local attr_val = substr(`"`tmp'"', 1, `pos2' - 1)
            }
        }
        if ("`attr'" == "version") local version "`attr_val'"
        if ("`attr'" == "position") local position "`attr_val'"
        if ("`attr'" == "agencyID") local agencyid "`attr_val'"
    }
    
    * Extract codelist reference
    local codelist ""
    if ("`type'" == "dimensions" | "`type'" == "attributes") {
        local ref_prefix = "<Ref id="
        local ref_pos = strpos(`"`element'"', "`ref_prefix'")
        if (`ref_pos' > 0) {
            local tmp = substr(`"`element'"', `ref_pos' + strlen("`ref_prefix'") + 1, .)
            local pos2 = ustrpos(`"`tmp'"', uchar(34))
            if (`pos2' > 0) {
                local codelist = substr(`"`tmp'"', 1, `pos2' - 1)
            }
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

*******************************************************************************
* _unicef_dataflow_info.ado
*! v 1.0.2   20Dec2025               by Joao Pedro Azevedo (UNICEF)
* Display detailed info about a specific UNICEF dataflow using YAML schema
*
* v1.0.2: Fixed schema file path (DATAFLOW.yaml not DATAFLOW_schema.yaml)
* v1.0.1: Fixed program definition issue
* v1.0.0: Initial implementation
*******************************************************************************

program define _unicef_dataflow_info, rclass
    version 14.0
    
    syntax , Dataflow(string) [VERBOSE METApath(string)]
    
    * Locate metadata directory
    if "`metapath'" == "" {
        qui findfile _unicefdata_dataflows.yaml
        local metapath = subinstr("`r(fn)'", "_unicefdata_dataflows.yaml", "", 1)
    }
    
    * Convert dataflow to uppercase for matching
    local df_upper = upper("`dataflow'")
    
    * Check for schema file (format: DATAFLOW.yaml, not DATAFLOW_schema.yaml)
    local schemafile "`metapath'_dataflows/`df_upper'.yaml"
    capture confirm file "`schemafile'"
    
    if _rc {
        * Schema file not found - show basic info from dataflows.yaml
        di as text ""
        di as text "{hline 60}"
        di as result "Dataflow: `df_upper'"
        di as text "{hline 60}"
        di as text ""
        di as text "Note: Detailed schema not available for this dataflow."
        di as text "Schema files can be downloaded from the UNICEF SDMX API."
        di as text ""
        
        * Try to show basic info from dataflows.yaml
        local dfyaml "`metapath'_unicefdata_dataflows.yaml"
        capture confirm file "`dfyaml'"
        if !_rc {
            tempname fh
            file open `fh' using "`dfyaml'", read text
            local found = 0
            file read `fh' line
            while r(eof) == 0 {
                * Trim the line and check if it matches "DATAFLOW:" pattern
                local trimline = strtrim("`line'")
                if "`trimline'" == "`df_upper':" {
                    local found = 1
                    * Read next lines for name and description
                    file read `fh' line
                    while r(eof) == 0 {
                        local trimline = strtrim("`line'")
                        * Stop when we hit another top-level key (no leading space means new section)
                        if substr("`line'", 1, 2) != "  " & strlen("`trimline'") > 0 & substr("`trimline'", 1, 1) != "#" {
                            continue, break
                        }
                        * Also stop if we hit another dataflow entry (indented key with colon at end)
                        if regexm("`trimline'", "^[A-Z][A-Z0-9_]*:$") {
                            continue, break
                        }
                        if strpos("`trimline'", "name:") == 1 {
                            local dfname = substr("`trimline'", 6, .)
                            local dfname = strtrim("`dfname'")
                            * Remove surrounding quotes if present
                            if substr("`dfname'", 1, 1) == "'" {
                                local dfname = substr("`dfname'", 2, strlen("`dfname'") - 2)
                            }
                            di as text "Name: " as result "`dfname'"
                        }
                        if strpos("`trimline'", "description:") == 1 {
                            local dfdesc = substr("`trimline'", 13, .)
                            local dfdesc = strtrim("`dfdesc'")
                            if substr("`dfdesc'", 1, 1) == "'" {
                                local dfdesc = substr("`dfdesc'", 2, strlen("`dfdesc'") - 2)
                            }
                            if "`dfdesc'" != "" & "`dfdesc'" != "''" {
                                di as text "Description: " as result "`dfdesc'"
                            }
                        }
                        file read `fh' line
                    }
                    continue, break
                }
                file read `fh' line
            }
            file close `fh'
            
            if `found' == 0 {
                di as error "Dataflow `df_upper' not found in metadata."
                di as text ""
                di as text "Available dataflows:"
                di as text "  Use {cmd:unicefdata, flows} to see the list."
            }
        }
        
        return local dataflow "`df_upper'"
        exit
    }
    
    * Schema file exists - parse and display it
    tempname fh
    file open `fh' using "`schemafile'", read text
    
    local dfname = ""
    local dfversion = ""
    local dfagency = ""
    local in_dimensions = 0
    local in_attributes = 0
    local dim_count = 0
    local attr_count = 0
    local dim_list = ""
    local attr_list = ""
    
    file read `fh' line
    while r(eof) == 0 {
        local trimline = strtrim("`line'")
        
        * Get top-level fields (start at column 1, no leading whitespace)
        if substr("`line'", 1, 5) == "name:" {
            local dfname = strtrim(substr("`line'", 6, .))
            * Remove surrounding quotes
            if substr("`dfname'", 1, 1) == "'" {
                local dfname = substr("`dfname'", 2, strlen("`dfname'") - 2)
            }
            if substr("`dfname'", 1, 1) == `"""' {
                local dfname = substr("`dfname'", 2, strlen("`dfname'") - 2)
            }
        }
        
        if substr("`line'", 1, 8) == "version:" {
            local dfversion = strtrim(substr("`line'", 9, .))
            if substr("`dfversion'", 1, 1) == "'" {
                local dfversion = substr("`dfversion'", 2, strlen("`dfversion'") - 2)
            }
        }
        
        if substr("`line'", 1, 7) == "agency:" {
            local dfagency = strtrim(substr("`line'", 8, .))
        }
        
        * Check for section headers (at column 1)
        if "`line'" == "dimensions:" {
            local in_dimensions = 1
            local in_attributes = 0
            file read `fh' line
            continue
        }
        if "`line'" == "attributes:" {
            local in_dimensions = 0
            local in_attributes = 1
            file read `fh' line
            continue
        }
        
        * Stop dimensions/attributes when hitting another top-level key
        if substr("`line'", 1, 1) != " " & substr("`line'", 1, 1) != "-" & strlen("`trimline'") > 0 {
            if strpos("`trimline'", ":") > 0 {
                local in_dimensions = 0
                local in_attributes = 0
            }
        }
        
        * Parse dimension/attribute entries (YAML list format: "- id: NAME")
        if `in_dimensions' | `in_attributes' {
            if regexm("`trimline'", "^- id: *([A-Z_][A-Z0-9_]*)") {
                local entryname = regexs(1)
                if `in_dimensions' {
                    local dim_count = `dim_count' + 1
                    local dim_list = "`dim_list' `entryname'"
                }
                else {
                    local attr_count = `attr_count' + 1
                    local attr_list = "`attr_list' `entryname'"
                }
            }
        }
        
        file read `fh' line
    }
    file close `fh'
    
    * Display results
    di as text ""
    di as text "{hline 70}"
    di as result "Dataflow Schema: `df_upper'"
    di as text "{hline 70}"
    di as text ""
    
    if "`dfname'" != "" {
        di as text "Name: " as result "`dfname'"
    }
    if "`dfversion'" != "" {
        di as text "Version: " as result "`dfversion'"
    }
    if "`dfagency'" != "" {
        di as text "Agency: " as result "`dfagency'"
    }
    di as text ""
    
    if `dim_count' > 0 {
        di as text "{ul:Dimensions (`dim_count'):}"
        foreach d of local dim_list {
            di as text "  " as result "`d'"
        }
        di as text ""
    }
    
    if `attr_count' > 0 {
        di as text "{ul:Attributes (`attr_count'):}"
        foreach a of local attr_list {
            di as text "  " as result "`a'"
        }
    }
    
    di as text ""
    di as text "{hline 70}"
    
    * Return values
    return local dataflow "`df_upper'"
    return local name "`dfname'"
    return local version "`dfversion'"
    return local agency "`dfagency'"
    return scalar dimensions = `dim_count'
    return scalar attributes = `attr_count'
    return local dimension_list "`dim_list'"
    return local attribute_list "`attr_list'"
end


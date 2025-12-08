*******************************************************************************
* _xmltoyaml_parse_chunked
*! v 1.0.0   06Dec2025               by Joao Pedro Azevedo (UNICEF)
* Chunked XML Parser - For large DSD files
* Splits file into manageable chunks and processes each
*******************************************************************************

program define _xmltoyaml_parse_chunked, rclass
    version 14.0
    
    syntax, XMLFILE(string) OUTFILE(string) TYPE(string) ///
        XMLROOT(string) IDATTR(string) ///
        [NAMEELEMENT(string) DESCELEMENT(string) EXTRAATTRS(string) ///
         LISTNAME(string) AGENCY(string) VERSION(string) ///
         CONTENTTYPE(string) CODELISTID(string) CODELISTNAME(string) ///
         SYNCEDAT(string) SOURCE(string) APPEND]
    
    * Configuration for chunked processing
    local max_line_len = 50000     // Max chars per accumulated element
    
    * First, preprocess the XML to add newlines for easier parsing
    * This breaks up long lines by inserting newlines before each element
    tempfile processed_xml1 processed_xml2
    
    * Add newline before each opening element tag
    capture filefilter "`xmlfile'" "`processed_xml1'", ///
        from("<`xmlroot'") to("\n<`xmlroot'") replace
    if (_rc != 0) {
        local processed_xml1 "`xmlfile'"
    }
    
    * For certain types, also add newline before closing tags
    if ("`type'" == "indicators" | "`type'" == "codelists" | "`type'" == "countries" | "`type'" == "regions") {
        * Also split on </str:Code> to ensure elements are separated
        capture filefilter "`processed_xml1'" "`processed_xml2'", ///
            from("</str:Code>") to("</str:Code>\n") replace
        if (_rc == 0) {
            local processed_xml1 "`processed_xml2'"
        }
    }
    
    * Open output file and write header
    tempname outfh
    if ("`append'" == "") {
        file open `outfh' using "`outfile'", write text replace
        
        * Write YAML header
        file write `outfh' "_metadata:" _n
        file write `outfh' "  platform: stata" _n
        file write `outfh' "  version: '`version''" _n
        file write `outfh' "  synced_at: '`syncedat''" _n
        if ("`source'" != "") {
            file write `outfh' "  source: '`source''" _n
        }
        file write `outfh' "  agency: `agency'" _n
        file write `outfh' "  content_type: `contenttype'" _n
        if ("`codelistid'" != "") {
            file write `outfh' "  codelist_id: `codelistid'" _n
        }
        if ("`codelistname'" != "") {
            file write `outfh' "  codelist_name: '`codelistname''" _n
        }
        file write `outfh' "`listname':" _n
    }
    else {
        file open `outfh' using "`outfile'", write text append
    }
    
    * Open preprocessed XML file for reading
    tempname infh
    capture file open `infh' using "`processed_xml1'", read text
    if (_rc != 0) {
        di as err "Failed to open XML file for chunked processing"
        file close `outfh'
        return scalar count = 0
        exit
    }
    
    * State variables for element accumulation
    local count = 0
    local in_element = 0
    local element_buffer ""
    local element_depth = 0
    local open_tag "<`xmlroot'"
    local close_tag "</" + substr("`xmlroot'", strpos("`xmlroot'", ":") + 1, .) + ">"
    
    * Also handle self-closing tags
    local self_close "/>"
    
    * Read file line by line
    file read `infh' line
    
    while !r(eof) {
        * Process current line
        local line_pos = 1
        local line_len = strlen(`"`line'"')
        
        while (`line_pos' <= `line_len') {
            * Check for element start
            local remaining = substr(`"`line'"', `line_pos', .)
            
            if (`in_element' == 0) {
                * Look for opening tag
                local start_pos = strpos(`"`remaining'"', "`open_tag'")
                if (`start_pos' > 0) {
                    local in_element = 1
                    local element_buffer = substr(`"`remaining'"', `start_pos', .)
                    local line_pos = `line_pos' + `start_pos' - 1 + strlen(`"`element_buffer'"')
                    
                    * Check if element closes on same line
                    local close_pos = strpos(`"`element_buffer'"', "`close_tag'")
                    local self_pos = strpos(`"`element_buffer'"', "`self_close'")
                    
                    if (`close_pos' > 0 | `self_pos' > 0) {
                        * Complete element found
                        _xmltoyaml_process_chunk, ///
                            filehandle(`outfh') ///
                            element(`"`element_buffer'"') ///
                            type("`type'") ///
                            idattr("`idattr'") ///
                            nameelement("`nameelement'") ///
                            descelement("`descelement'") ///
                            extraattrs("`extraattrs'")
                        
                        if (r(success) == 1) {
                            local count = `count' + 1
                        }
                        
                        local in_element = 0
                        local element_buffer ""
                    }
                }
                else {
                    * No element start found, skip to next line
                    local line_pos = `line_len' + 1
                }
            }
            else {
                * Currently inside an element, accumulate content
                * But limit buffer size to prevent overflow
                if (strlen(`"`element_buffer'"') < `max_line_len') {
                    local element_buffer `"`element_buffer' `remaining'"'
                }
                
                * Check for element end
                local close_pos = strpos(`"`element_buffer'"', "`close_tag'")
                local self_pos = strpos(`"`element_buffer'"', "`self_close'")
                
                if (`close_pos' > 0 | `self_pos' > 0) {
                    * Complete element found - process it
                    _xmltoyaml_process_chunk, ///
                        filehandle(`outfh') ///
                        element(`"`element_buffer'"') ///
                        type("`type'") ///
                        idattr("`idattr'") ///
                        nameelement("`nameelement'") ///
                        descelement("`descelement'") ///
                        extraattrs("`extraattrs'")
                    
                    if (r(success) == 1) {
                        local count = `count' + 1
                    }
                    
                    local in_element = 0
                    local element_buffer ""
                }
                
                local line_pos = `line_len' + 1
            }
        }
        
        file read `infh' line
    }
    
    file close `infh'
    file close `outfh'
    
    return scalar count = `count'
end

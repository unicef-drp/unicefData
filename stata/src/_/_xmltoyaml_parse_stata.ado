*******************************************************************************
* _xmltoyaml_parse_stata
*! v 1.1.0   06Dec2025               by Joao Pedro Azevedo (UNICEF)
* Standard Stata-based XML parser for smaller files
* Now receives open_tag and close_tag from schema
*******************************************************************************

program define _xmltoyaml_parse_stata, rclass
    version 14.0
    
    syntax, XMLFILE(string) OUTFILE(string) TYPE(string) ///
        XMLROOT(string) IDATTR(string) ///
        OPENTAG(string) CLOSETAG(string) ///
        [NAMEELEMENT(string) DESCELEMENT(string) EXTRAATTRS(string) ///
         YAMLFIELDS(string) LISTNAME(string) AGENCY(string) ///
         VERSION(string) CONTENTTYPE(string) CODELISTID(string) ///
         CODELISTNAME(string) SYNCEDAT(string) SOURCE(string) APPEND]
    
    * Standard processing for smaller files
    * Preprocess XML - split on root elements for easier parsing
    tempfile processed_xml
    capture noisily filefilter "`xmlfile'" "`processed_xml'", ///
        from("<`xmlroot'") to("\n<`xmlroot'") replace
    
    if (_rc != 0) {
        * If filefilter fails, use the original file directly
        local processed_xml "`xmlfile'"
    }
    
    * Open output file
    tempname outfh
    if ("`append'" == "") {
        file open `outfh' using "`outfile'", write text replace
        
        * Write YAML header/watermark inline
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
    
    * Parse XML elements using standard line-by-line approach
    local count = 0
    _xmltoyaml_parse_lines, ///
        filehandle(`outfh') ///
        inputfile("`processed_xml'") ///
        type("`type'") ///
        idattr("`idattr'") ///
        opentag("`opentag'") ///
        closetag("`closetag'") ///
        nameelement("`nameelement'") ///
        descelement("`descelement'") ///
        extraattrs("`extraattrs'")
    
    local count = r(count)
    
    file close `outfh'
    
    return scalar count = `count'
end

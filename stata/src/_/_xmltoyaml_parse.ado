*******************************************************************************
* _xmltoyaml_parse
*! v 1.1.0   06Dec2025               by Joao Pedro Azevedo (UNICEF)
* XML Parser - Processes XML file according to schema
* Prefers Python for robust processing, falls back to Stata for compatibility
* Now receives open_tag and close_tag from schema
*******************************************************************************

program define _xmltoyaml_parse, rclass
    version 14.0
    
    syntax, XMLFILE(string) OUTFILE(string) TYPE(string) ///
        XMLROOT(string) IDATTR(string) ///
        OPENTAG(string) CLOSETAG(string) ///
        [NAMEELEMENT(string) DESCELEMENT(string) EXTRAATTRS(string) ///
         YAMLFIELDS(string) LISTNAME(string) AGENCY(string) ///
         VERSION(string) CONTENTTYPE(string) CODELISTID(string) ///
         CODELISTNAME(string) SYNCEDAT(string) SOURCE(string) APPEND ///
         FORCESTATA]
    
    capture confirm file "`xmlfile'"
    if (_rc != 0) {
        di as err "XML file not found: `xmlfile'"
        return scalar count = 0
        exit
    }
    
    * Try Python first (preferred method) unless forcestata is specified
    if ("`forcestata'" == "") {
        capture noisily _xmltoyaml_parse_python, ///
            xmlfile("`xmlfile'") ///
            outfile("`outfile'") ///
            type("`type'") ///
            agency("`agency'") ///
            version("`version'") ///
            contenttype("`contenttype'") ///
            codelistid("`codelistid'") ///
            codelistname("`codelistname'") ///
            syncedat("`syncedat'") ///
            source("`source'") ///
            `append'
        
        local py_rc = _rc
        local py_count = r(count)
        
        if (`py_rc' == 0 & `py_count' > 0) {
            return scalar count = `py_count'
            exit
        }
        * Python failed or not available, fall back to Stata
        di as txt "  Python not available or failed, using Stata parser..."
    }
    
    * Stata processing (fallback for older Stata versions without Python)
    _xmltoyaml_parse_stata, ///
        xmlfile("`xmlfile'") ///
        outfile("`outfile'") ///
        type("`type'") ///
        xmlroot("`xmlroot'") ///
        idattr("`idattr'") ///
        opentag("`opentag'") ///
        closetag("`closetag'") ///
        nameelement("`nameelement'") ///
        descelement("`descelement'") ///
        extraattrs("`extraattrs'") ///
        listname("`listname'") ///
        agency("`agency'") ///
        version("`version'") ///
        contenttype("`contenttype'") ///
        codelistid("`codelistid'") ///
        codelistname("`codelistname'") ///
        syncedat("`syncedat'") ///
        source("`source'") ///
        `append'
    
    return scalar count = r(count)
end

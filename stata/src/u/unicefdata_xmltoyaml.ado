*******************************************************************************
* unicefdata_xmltoyaml
*! v 2.0.0   07Dec2025               by Joao Pedro Azevedo (UNICEF)
* Generic XML to YAML parser for SDMX data structures
* Supports both Python (preferred) and pure Stata (fallback) parsers
*******************************************************************************

/*
DESCRIPTION:
    A generic XML parser that converts SDMX XML structures to YAML files.
    Uses a schema registry to define XML element paths and YAML field mappings
    for different database types (dataflows, codelists, countries, etc.)
    
    By default, uses Python for robust large-file handling, with automatic
    fallback to pure Stata if Python is not available.
    
SUPPORTED TYPES:
    dataflows   - SDMX dataflow definitions
    codelists   - Generic codelist items
    countries   - Country codes (CL_COUNTRY)
    regions     - Regional codes (CL_WORLD_REGIONS)
    dimensions  - DSD dimension definitions
    attributes  - DSD attribute definitions
    indicators  - Indicator codelist (CL_UNICEF_INDICATOR)
    
SYNTAX:
    unicefdata_xmltoyaml, type(string) xmlfile(string) outfile(string)
        [agency(string) version(string) contenttype(string) codelistid(string)
         codelistname(string) syncedat(string) source(string) append
         forcepython forcestata]
    
OPTIONS:
    type(string)        - Database type (see SUPPORTED TYPES)
    xmlfile(string)     - Input XML file path
    outfile(string)     - Output YAML file path
    agency(string)      - Agency name (default: UNICEF)
    version(string)     - Metadata version (default: 2.0.0)
    contenttype(string) - Content type for watermark
    codelistid(string)  - Codelist ID for countries/regions
    codelistname(string)- Codelist name for countries/regions
    syncedat(string)    - Sync timestamp (auto-generated if not provided)
    source(string)      - Source URL for watermark
    append              - Append to existing file (no header)
    forcepython         - Force use of Python parser (requires Python 3.6+)
    forcestata          - Force use of pure Stata parser (no Python required)
    
RETURNS:
    r(count)    - Number of items parsed
    r(type)     - Database type processed
    r(parser)   - Parser used ("python" or "stata")
    
EXAMPLE:
    tempfile xml_data
    copy "https://sdmx.data.unicef.org/.../dataflow/UNICEF" "`xml_data'", public
    
    * Auto-detect best parser
    unicefdata_xmltoyaml, type(dataflows) xmlfile("`xml_data'") ///
        outfile("metadata/dataflows.yaml") agency(UNICEF)
    
    * Force Python parser
    unicefdata_xmltoyaml, type(dataflows) xmlfile("`xml_data'") ///
        outfile("metadata/dataflows.yaml") agency(UNICEF) forcepython
    
    * Force Stata parser (no Python required)
    unicefdata_xmltoyaml, type(dataflows) xmlfile("`xml_data'") ///
        outfile("metadata/dataflows_stataonly.yaml") agency(UNICEF) forcestata
*/

*******************************************************************************
* Main entry point - wrapper with parser selection
*******************************************************************************

program define unicefdata_xmltoyaml, rclass
    version 14.0
    
    syntax, TYPE(string) XMLFILE(string) OUTFILE(string) ///
        [AGENCY(string) VERSION(string) CONTENTTYPE(string) ///
         CODELISTID(string) CODELISTNAME(string) SYNCEDAT(string) ///
         SOURCE(string) APPEND FORCEPYTHON FORCESTATA]
    
    * Set defaults
    if ("`agency'" == "") local agency "UNICEF"
    if ("`version'" == "") local version "2.0.0"
    if ("`contenttype'" == "") local contenttype "`type'"
    
    * Generate timestamp if not provided
    if ("`syncedat'" == "") {
        local syncedat : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
        local syncedat = trim("`syncedat'") + "Z"
    }
    
    * Validate type
    local valid_types "dataflows codelists countries regions dimensions attributes indicators"
    local type = lower("`type'")
    
    if (!strpos(" `valid_types' ", " `type' ")) {
        di as err "Invalid type: `type'"
        di as err "Valid types: `valid_types'"
        error 198
    }
    
    * Check that both force options are not specified
    if ("`forcepython'" != "" & "`forcestata'" != "") {
        di as err "Cannot specify both forcepython and forcestata options"
        error 198
    }
    
    * Determine which parser to use
    local use_python = 0
    local chunk_threshold = 500000  // 500KB - use Python for larger files
    
    if ("`forcepython'" != "") {
        local use_python = 1
    }
    else if ("`forcestata'" != "") {
        local use_python = 0
    }
    else {
        * Auto-detect based on file size
        quietly {
            capture checksum "`xmlfile'"
            if (_rc == 0 & !missing(r(filelen))) {
                if (r(filelen) > `chunk_threshold') {
                    local use_python = 1
                }
            }
        }
    }
    
    * Get schema configuration for this type
    _xmltoyaml_get_schema, type(`type')
    local xml_root     "`r(xml_root)'"
    local open_tag     "`r(open_tag)'"
    local close_tag    "`r(close_tag)'"
    local xml_filter   "`r(xml_filter)'"
    local id_attr      "`r(id_attr)'"
    local name_element "`r(name_element)'"
    local desc_element "`r(desc_element)'"
    local extra_attrs  "`r(extra_attrs)'"
    local yaml_fields  "`r(yaml_fields)'"
    local list_name    "`r(list_name)'"
    
    local parser_used = ""
    local count = 0
    
    if (`use_python') {
        * Use Python parser
        capture noisily unicefdata_xmltoyaml_py, ///
            type("`type'") ///
            xmlfile("`xmlfile'") ///
            outfile("`outfile'") ///
            agency("`agency'") ///
            version("`version'") ///
            source("`source'") ///
            codelistid("`codelistid'") ///
            codelistname("`codelistname'")
        
        local py_rc = _rc
        if (`py_rc' == 0) {
            local count = r(count)
            local parser_used "python"
        }
        else if ("`forcepython'" != "") {
            * Python was forced but failed
            di as err "Python parser failed with error `py_rc'"
            error `py_rc'
        }
        else {
            * Python failed, fall back to Stata
            di as txt "  Python not available, falling back to Stata parser..."
            local use_python = 0
        }
    }
    
    if (`use_python' == 0 & "`parser_used'" == "") {
        * Use native Stata parser
        _xmltoyaml_parse, ///
            xmlfile("`xmlfile'") ///
            outfile("`outfile'") ///
            type("`type'") ///
            xmlroot("`xml_root'") ///
            idattr("`id_attr'") ///
            opentag("`open_tag'") ///
            closetag("`close_tag'") ///
            nameelement("`name_element'") ///
            descelement("`desc_element'") ///
            extraattrs("`extra_attrs'") ///
            yamlfields("`yaml_fields'") ///
            listname("`list_name'") ///
            agency("`agency'") ///
            version("`version'") ///
            contenttype("`contenttype'") ///
            codelistid("`codelistid'") ///
            codelistname("`codelistname'") ///
            syncedat("`syncedat'") ///
            source("`source'") ///
            `append' forcestata
        
        local count = r(count)
        local parser_used "stata"
    }
    
    * Return results
    return scalar count = `count'
    return local type "`type'"
    return local parser "`parser_used'"
end

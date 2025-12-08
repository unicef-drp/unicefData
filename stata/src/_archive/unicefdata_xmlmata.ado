*******************************************************************************
* unicefdata_xmlmata
*! v 1.0.0   05Dec2025               by Joao Pedro Azevedo (UNICEF)
* XML parsing using Mata's XML functions
* Explores Mata's undocumented XML parsing capabilities for SDMX data
*******************************************************************************

/*
DESCRIPTION:
    Explores using Mata's XML parsing functions to handle large SDMX XML files.
    Mata handles strings differently and may avoid the line-length limitations
    of Stata's file I/O commands.
    
MATA XML FUNCTIONS (undocumented):
    _xml_new()              - Create new XML parser instance
    _xml_load()             - Load XML file into parser
    _xml_get_root()         - Get root element
    _xml_get_children()     - Get child nodes of an element
    _xml_get_name()         - Get element/node name
    _xml_get_attr()         - Get attribute value
    _xml_get_text()         - Get text content of element
    _xml_get_nattr()        - Get number of attributes
    _xml_get_nchildren()    - Get number of children
    _xml_free()             - Free XML parser memory
    
SYNTAX:
    _unicefdata_xmlmata_parse, xmlfile(string) type(string) outfile(string)
        [agency(string) version(string)]
        
SUPPORTED TYPES:
    dataflows, codelists, countries, regions, dimensions, attributes, indicators
*/

*******************************************************************************
* Main entry point - Parse XML using Mata
*******************************************************************************

program define _unicefdata_xmlmata_parse, rclass
    version 14.0
    
    syntax, XMLFILE(string) TYPE(string) OUTFILE(string) ///
        [AGENCY(string) VERSION(string) CONTENTTYPE(string) ///
         CODELISTID(string) CODELISTNAME(string) SOURCE(string)]
    
    * Set defaults
    if ("`agency'" == "") local agency "UNICEF"
    if ("`version'" == "") local version "2.0.0"
    if ("`contenttype'" == "") local contenttype "`type'"
    
    * Generate timestamp
    local syncedat : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local syncedat = trim("`syncedat'") + "Z"
    
    * Validate file exists
    capture confirm file "`xmlfile'"
    if (_rc != 0) {
        di as err "XML file not found: `xmlfile'"
        return scalar count = 0
        exit 601
    }
    
    * Get file size
    quietly checksum "`xmlfile'"
    local filesize = r(filelen)
    di as text "  File size: " %12.0fc `filesize' " bytes"
    
    * Call Mata parser
    mata: _unicefdata_mata_xml_parse("`xmlfile'", "`type'", "`outfile'", ///
        "`agency'", "`version'", "`contenttype'", "`syncedat'", ///
        "`codelistid'", "`codelistname'", "`source'")
    
    * Get count from Mata
    local count = r(count)
    
    return scalar count = `count'
    return local type "`type'"
end

*******************************************************************************
* Mata XML Parser Implementation
*******************************************************************************

mata:
mata clear

// Main parsing function
void _unicefdata_mata_xml_parse(string scalar xmlfile, string scalar type,
    string scalar outfile, string scalar agency, string scalar ver,
    string scalar contenttype, string scalar syncedat,
    string scalar codelistid, string scalar codelistname, string scalar source)
{
    real scalar xml, root, count, fh
    string scalar listname, xmlroot
    
    // Determine XML root element and list name based on type
    if (type == "dataflows") {
        xmlroot = "str:Dataflow"
        listname = "dataflows"
    }
    else if (type == "codelists" | type == "countries" | type == "regions" | type == "indicators") {
        xmlroot = "str:Code"
        if (type == "countries") listname = "countries"
        else if (type == "regions") listname = "regions"
        else if (type == "indicators") listname = "indicators"
        else listname = "codes"
    }
    else if (type == "dimensions") {
        xmlroot = "str:Dimension"
        listname = "dimensions"
    }
    else if (type == "attributes") {
        xmlroot = "str:Attribute"
        listname = "attributes"
    }
    else {
        printf("{err}Unknown type: %s\n", type)
        st_numscalar("r(count)", 0)
        return
    }
    
    printf("  Parsing type: %s (looking for <%s> elements)\n", type, xmlroot)
    
    // Try to create XML parser
    xml = _xml_new()
    if (xml == 0) {
        printf("{err}Failed to create XML parser\n")
        st_numscalar("r(count)", 0)
        return
    }
    
    printf("  XML parser created successfully\n")
    
    // Load XML file
    if (_xml_load(xml, xmlfile) != 0) {
        printf("{err}Failed to load XML file: %s\n", xmlfile)
        _xml_free(xml)
        st_numscalar("r(count)", 0)
        return
    }
    
    printf("  XML file loaded successfully\n")
    
    // Get root element
    root = _xml_get_root(xml)
    if (root == 0) {
        printf("{err}Failed to get XML root element\n")
        _xml_free(xml)
        st_numscalar("r(count)", 0)
        return
    }
    
    printf("  Root element obtained\n")
    
    // Open output file
    fh = fopen(outfile, "w")
    if (fh < 0) {
        printf("{err}Failed to open output file: %s\n", outfile)
        _xml_free(xml)
        st_numscalar("r(count)", 0)
        return
    }
    
    // Write YAML header
    _write_yaml_header(fh, ver, syncedat, source, agency, contenttype,
        codelistid, codelistname, listname)
    
    // Parse and write elements
    count = _parse_xml_elements(xml, root, fh, type, xmlroot)
    
    // Cleanup
    fclose(fh)
    _xml_free(xml)
    
    printf("  Parsed %g elements\n", count)
    st_numscalar("r(count)", count)
}

// Write YAML header
void _write_yaml_header(real scalar fh, string scalar ver,
    string scalar syncedat, string scalar source, string scalar agency,
    string scalar contenttype, string scalar codelistid,
    string scalar codelistname, string scalar listname)
{
    fput(fh, "_metadata:")
    fput(fh, "  platform: stata-mata")
    fput(fh, sprintf("  version: '%s'", ver))
    fput(fh, sprintf("  synced_at: '%s'", syncedat))
    if (strlen(source) > 0) {
        fput(fh, sprintf("  source: '%s'", source))
    }
    fput(fh, sprintf("  agency: %s", agency))
    fput(fh, sprintf("  content_type: %s", contenttype))
    if (strlen(codelistid) > 0) {
        fput(fh, sprintf("  codelist_id: %s", codelistid))
    }
    if (strlen(codelistname) > 0) {
        fput(fh, sprintf("  codelist_name: '%s'", codelistname))
    }
    fput(fh, sprintf("%s:", listname))
}

// Recursively parse XML elements and find matching nodes
real scalar _parse_xml_elements(real scalar xml, real scalar node,
    real scalar fh, string scalar type, string scalar xmlroot)
{
    real scalar i, nchildren, child, count
    string scalar nodename
    
    count = 0
    
    // Get node name
    nodename = _xml_get_name(xml, node)
    
    // Check if this node matches what we're looking for
    if (nodename == xmlroot) {
        // Process this element
        count = count + _process_element(xml, node, fh, type)
    }
    
    // Recursively process children
    nchildren = _xml_get_nchildren(xml, node)
    for (i = 1; i <= nchildren; i++) {
        child = _xml_get_child(xml, node, i)
        if (child != 0) {
            count = count + _parse_xml_elements(xml, child, fh, type, xmlroot)
        }
    }
    
    return(count)
}

// Process a single XML element and write YAML output
real scalar _process_element(real scalar xml, real scalar node,
    real scalar fh, string scalar type)
{
    string scalar id, name, desc, xmlver, agencyid, position, codelist, category
    real scalar nchildren, i, child, underscore_pos
    string scalar childname, childtext
    
    // Get ID attribute
    id = _xml_get_attr(xml, node, "id")
    if (strlen(id) == 0) {
        return(0)
    }
    
    // Get other attributes (note: version is reserved in Mata, using xmlver)
    xmlver = _xml_get_attr(xml, node, "version")
    agencyid = _xml_get_attr(xml, node, "agencyID")
    position = _xml_get_attr(xml, node, "position")
    
    // Search children for name and description
    name = ""
    desc = ""
    codelist = ""
    nchildren = _xml_get_nchildren(xml, node)
    
    for (i = 1; i <= nchildren; i++) {
        child = _xml_get_child(xml, node, i)
        if (child != 0) {
            childname = _xml_get_name(xml, child)
            
            // Look for com:Name element
            if (childname == "com:Name" | childname == "Name") {
                childtext = _xml_get_text(xml, child)
                if (strlen(childtext) > 0) {
                    name = _escape_yaml_string(childtext)
                }
            }
            // Look for com:Description element
            else if (childname == "com:Description" | childname == "Description") {
                childtext = _xml_get_text(xml, child)
                if (strlen(childtext) > 0) {
                    desc = _escape_yaml_string(childtext)
                }
            }
            // Look for LocalRepresentation -> Enumeration -> Ref for codelist
            else if (childname == "str:LocalRepresentation" | childname == "LocalRepresentation") {
                codelist = _find_codelist_ref(xml, child)
            }
        }
    }
    
    // Write YAML based on type
    if (type == "dataflows") {
        fput(fh, sprintf("- id: %s", id))
        fput(fh, sprintf("  name: '%s'", name))
        if (strlen(xmlver) > 0) {
            fput(fh, sprintf("  version: '%s'", xmlver))
        }
        if (strlen(agencyid) > 0) {
            fput(fh, sprintf("  agency_id: %s", agencyid))
        }
    }
    else if (type == "codelists") {
        fput(fh, sprintf("- id: %s", id))
        fput(fh, sprintf("  name: '%s'", name))
        if (strlen(desc) > 0) {
            fput(fh, sprintf("  description: '%s'", desc))
        }
    }
    else if (type == "countries" | type == "regions") {
        fput(fh, sprintf("- id: %s", id))
        fput(fh, sprintf("  name: '%s'", name))
    }
    else if (type == "dimensions") {
        fput(fh, sprintf("- id: %s", id))
        if (strlen(position) > 0) {
            fput(fh, sprintf("  position: %s", position))
        }
        if (strlen(codelist) > 0) {
            fput(fh, sprintf("  codelist: %s", codelist))
        }
    }
    else if (type == "attributes") {
        fput(fh, sprintf("- id: %s", id))
        if (strlen(codelist) > 0) {
            fput(fh, sprintf("  codelist: %s", codelist))
        }
    }
    else if (type == "indicators") {
        // Extract category from ID (part before first underscore)
        underscore_pos = strpos(id, "_")
        if (underscore_pos > 0) {
            category = substr(id, 1, underscore_pos - 1)
        }
        else {
            category = id
        }
        
        fput(fh, sprintf("  %s:", id))
        fput(fh, sprintf("    category: %s", category))
        fput(fh, sprintf("    code: %s", id))
        fput(fh, sprintf("    description: '%s'", desc))
        fput(fh, sprintf("    name: '%s'", name))
    }
    
    return(1)
}

// Find codelist reference in LocalRepresentation element
string scalar _find_codelist_ref(real scalar xml, real scalar node)
{
    real scalar nchildren, i, child, refchild, j, nrefchildren
    string scalar childname, refid
    
    nchildren = _xml_get_nchildren(xml, node)
    for (i = 1; i <= nchildren; i++) {
        child = _xml_get_child(xml, node, i)
        if (child != 0) {
            childname = _xml_get_name(xml, child)
            if (childname == "str:Enumeration" | childname == "Enumeration") {
                // Look for Ref element inside
                nrefchildren = _xml_get_nchildren(xml, child)
                for (j = 1; j <= nrefchildren; j++) {
                    refchild = _xml_get_child(xml, child, j)
                    if (refchild != 0) {
                        if (_xml_get_name(xml, refchild) == "Ref") {
                            refid = _xml_get_attr(xml, refchild, "id")
                            if (strlen(refid) > 0) {
                                return(refid)
                            }
                        }
                    }
                }
            }
        }
    }
    return("")
}

// Escape single quotes in YAML strings
string scalar _escape_yaml_string(string scalar s)
{
    return(subinstr(s, "'", "''", .))
}

end

*******************************************************************************
* Test/Debug function to explore XML structure
*******************************************************************************

program define _unicefdata_xmlmata_explore, rclass
    version 14.0
    
    syntax, XMLFILE(string) [MAXDEPTH(integer 3) MAXNODES(integer 50)]
    
    * Validate file exists
    capture confirm file "`xmlfile'"
    if (_rc != 0) {
        di as err "XML file not found: `xmlfile'"
        exit 601
    }
    
    di as text "{hline 70}"
    di as text "{bf:Exploring XML Structure}"
    di as text "{hline 70}"
    di as text "File: `xmlfile'"
    di as text "Max depth: `maxdepth'"
    di as text "Max nodes: `maxnodes'"
    di as text "{hline 70}"
    
    * Call Mata explorer
    mata: _unicefdata_mata_xml_explore("`xmlfile'", `maxdepth', `maxnodes')
end

mata:

// Explore XML structure for debugging
void _unicefdata_mata_xml_explore(string scalar xmlfile,
    real scalar maxdepth, real scalar maxnodes)
{
    real scalar xml, root, nodecount
    
    // Create XML parser
    xml = _xml_new()
    if (xml == 0) {
        printf("{err}Failed to create XML parser\n")
        printf("{err}Mata XML functions may not be available in this Stata version\n")
        return
    }
    
    printf("{txt}XML parser created\n")
    
    // Load XML file
    if (_xml_load(xml, xmlfile) != 0) {
        printf("{err}Failed to load XML file\n")
        _xml_free(xml)
        return
    }
    
    printf("{txt}XML file loaded\n")
    
    // Get root element
    root = _xml_get_root(xml)
    if (root == 0) {
        printf("{err}Failed to get root element\n")
        _xml_free(xml)
        return
    }
    
    printf("{txt}Root element: %s\n", _xml_get_name(xml, root))
    printf("{hline 70}\n")
    
    // Explore tree structure
    nodecount = 0
    _explore_node(xml, root, 0, maxdepth, maxnodes, nodecount)
    
    printf("{hline 70}\n")
    printf("{txt}Total nodes explored: %g\n", nodecount)
    
    // Cleanup
    _xml_free(xml)
}

// Recursively explore XML nodes
void _explore_node(real scalar xml, real scalar node, real scalar depth,
    real scalar maxdepth, real scalar maxnodes, real scalar nodecount)
{
    real scalar nchildren, nattr, i, child
    string scalar nodename, indent, attrname, attrval, text
    
    if (depth > maxdepth | nodecount >= maxnodes) {
        return
    }
    
    nodecount++
    
    // Create indentation
    indent = ""
    for (i = 1; i <= depth; i++) {
        indent = indent + "  "
    }
    
    // Get node info
    nodename = _xml_get_name(xml, node)
    nchildren = _xml_get_nchildren(xml, node)
    nattr = _xml_get_nattr(xml, node)
    
    // Print node info
    printf("%s<%s>", indent, nodename)
    if (nattr > 0) {
        printf(" [%g attrs]", nattr)
    }
    if (nchildren > 0) {
        printf(" [%g children]", nchildren)
    }
    
    // Print text content if any (truncated)
    text = _xml_get_text(xml, node)
    if (strlen(text) > 0) {
        if (strlen(text) > 50) {
            text = substr(text, 1, 47) + "..."
        }
        printf(" = '%s'", text)
    }
    printf("\n")
    
    // Print attributes (first few)
    for (i = 1; i <= min((nattr, 5)); i++) {
        attrname = _xml_get_attr_name(xml, node, i)
        attrval = _xml_get_attr(xml, node, attrname)
        printf("%s  @%s = '%s'\n", indent, attrname, attrval)
    }
    if (nattr > 5) {
        printf("%s  ... and %g more attributes\n", indent, nattr - 5)
    }
    
    // Recurse into children
    for (i = 1; i <= nchildren; i++) {
        child = _xml_get_child(xml, node, i)
        if (child != 0) {
            _explore_node(xml, child, depth + 1, maxdepth, maxnodes, nodecount)
        }
        if (nodecount >= maxnodes) {
            printf("%s  ... (max nodes reached)\n", indent)
            break
        }
    }
}

end

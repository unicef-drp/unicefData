*******************************************************************************
* unicefdata_xmltoyaml_py
*! v 1.2.0   16Jan2026               by Joao Pedro Azevedo (UNICEF)
* SDMX XML to YAML converter using Python backend
* Handles large XML files that Stata cannot process natively
* v1.2.0: Show enrichment progress inline instead of capturing to temp file
* v1.1.0: Added ENRICHDATAFLOWS option to add dataflow info to indicators
* v1.0.1: Fixed adopath search to use actual sysdir paths
*******************************************************************************

/*
DESCRIPTION:
    Converts SDMX XML files to YAML format using a Python helper script.
    This approach handles arbitrarily large XML files without hitting
    Stata's line-length limitations.
    
REQUIREMENTS:
    - Python 3.6+ installed and accessible via 'python' command
    - requests package required for ENRICHDATAFLOWS option (pip install requests)
    - lxml package recommended (pip install lxml) for better performance
    - Falls back to xml.etree.ElementTree if lxml not available
    
SUPPORTED TYPES:
    dataflows   - SDMX dataflow definitions
    codelists   - Generic codelist items
    countries   - Country codes (CL_COUNTRY)
    regions     - Regional codes (CL_WORLD_REGIONS)
    dimensions  - DSD dimension definitions
    attributes  - DSD attribute definitions
    indicators  - Indicator codelist (CL_UNICEF_INDICATOR)
    
SYNTAX:
    unicefdata_xmltoyaml_py, type(string) xmlfile(string) outfile(string)
        [agency(string) version(string) source(string) 
         codelistid(string) codelistname(string) enrichdataflows
         fallbacksequencesout(string)]
    
OPTIONS:
    enrichdataflows  - For indicators: query all dataflows to add 'dataflows'
                       field to each indicator (takes ~1-2 minutes)
    fallbacksequencesout(string) - Also generate fallback sequences YAML
                       to this path (only with enrichdataflows)
    
RETURNS:
    r(count)    - Number of items parsed
    r(type)     - Database type processed
*/

program define unicefdata_xmltoyaml_py, rclass
    version 14.0
    
    syntax, TYPE(string) XMLFILE(string) OUTFILE(string) ///
        [AGENCY(string) VERSION(string) SOURCE(string) ///
         CODELISTID(string) CODELISTNAME(string) PYTHON(string) ///
         ENRICHDATAFLOWS FALLBACKSEQUENCESOUT(string)]
    
    * Set defaults
    if ("`agency'" == "") local agency "UNICEF"
    if ("`version'" == "") local version "2.0.0"
    
    * Validate type
    local valid_types "dataflows codelists countries regions dimensions attributes indicators"
    local type = lower("`type'")
    
    if (!strpos(" `valid_types' ", " `type' ")) {
        di as err "Invalid type: `type'"
        di as err "Valid types: `valid_types'"
        error 198
    }
    
    * Check XML file exists
    capture confirm file "`xmlfile'"
    if (_rc != 0) {
        di as err "XML file not found: `xmlfile'"
        error 601
    }
    
    * Find Python script location
    local script_name "unicefdata_xml2yaml.py"
    local script_path ""
    
    * First try the location relative to the current working directory
    foreach trypath in "stata/src/py/`script_name'" "`script_name'" {
        capture confirm file "`trypath'"
        if (_rc == 0) {
            local script_path "`trypath'"
            continue, break
        }
    }
    
    * Check Stata system directories for py/ subfolder
    * Use actual sysdir paths instead of symbolic adopath names
    if ("`script_path'" == "") {
        foreach sysdir in plus personal site base {
            local basepath = subinstr("`c(sysdir_`sysdir')'", "\", "/", .)
            if ("`basepath'" != "") {
                local trypath = "`basepath'py/`script_name'"
                capture confirm file "`trypath'"
                if (_rc == 0) {
                    local script_path "`trypath'"
                    continue, break
                }
            }
        }
    }
    
    * Also try the u/ directory where this ado lives (same location pattern)
    if ("`script_path'" == "") {
        foreach sysdir in plus personal site {
            local basepath = subinstr("`c(sysdir_`sysdir')'", "\", "/", .)
            if ("`basepath'" != "") {
                local trypath = "`basepath'u/`script_name'"
                capture confirm file "`trypath'"
                if (_rc == 0) {
                    local script_path "`trypath'"
                    continue, break
                }
            }
        }
    }
    
    if ("`script_path'" == "") {
        di as err "Python script not found: `script_name'"
        di as err "Searched in: sysdir_plus/py/, sysdir_personal/py/, sysdir_plus/u/"
        di as err "Please ensure unicefdata_xml2yaml.py is installed with the package"
        error 601
    }
    
    * Determine Python command
    if ("`python'" == "") {
        local python "python"
    }
    
    * Build metadata arguments (matching Python argparse format)
    local meta_args ""
    if ("`source'" != "") {
        local meta_args `"`meta_args' --source "`source'""'
    }
    if ("`codelistid'" != "") {
        local meta_args `"`meta_args' --codelist-id "`codelistid'""'
    }
    if ("`codelistname'" != "") {
        local meta_args `"`meta_args' --codelist-name "`codelistname'""'
    }
    if ("`enrichdataflows'" != "") {
        local meta_args `"`meta_args' --enrich-dataflows"'
    }
    if ("`fallbacksequencesout'" != "") {
        local meta_args `"`meta_args' --fallback-sequences-output "`fallbacksequencesout'""'
    }
    local meta_args `"`meta_args' --agency "`agency'" --version "`version'""'
    
    * Create temporary file for Python output
    tempfile pyout
    
    * Build and execute Python command
    local cmd `""`python'" "`script_path'" `type' "`xmlfile'" "`outfile'" `meta_args'"'
    
    * Debug: show the command
    di as text "  Script: `script_path'"
    di as text "  Running Python XML parser..."
    
    * Debug: show if fallback sequences is being used
    if ("`fallbacksequencesout'" != "") {
        di as text "  Fallback sequences output: `fallbacksequencesout'"
    }
    
    * For enrichment, show progress inline (don't redirect output)
    if ("`enrichdataflows'" != "") {
        di as text "  (Enriching with dataflow info - this takes ~1-2 minutes)"
        if ("`c(os)'" == "Windows") {
            shell `cmd'
        }
        else {
            shell `cmd'
        }
    }
    else {
        * Normal mode: capture output to temp file
        if ("`c(os)'" == "Windows") {
            * Windows: use shell
            shell `cmd' > "`pyout'" 2>&1
        }
        else {
            * Unix/Mac: use shell
            shell `cmd' > "`pyout'" 2>&1
        }
    }
    
    * Verify output file was created
    capture confirm file "`outfile'"
    if (_rc != 0) {
        * Show Python output for debugging
        di as err "Output file was not created: `outfile'"
        di as err "Python output:"
        capture {
            tempname fh
            file open `fh' using "`pyout'", read text
            file read `fh' line
            while !r(eof) {
                di as err "  `line'"
                file read `fh' line
            }
            file close `fh'
        }
        error 603
    }
    
    * Count items by counting "    code: " lines in output file (dict format)
    * The Python script outputs dict format: each item has "    code: XXX" line
    local count = 0
    tempname fh
    file open `fh' using "`outfile'", read text
    file read `fh' line
    while !r(eof) {
        * Match lines that start with "    code: " (4 spaces + code:)
        if (strmatch(`"`line'"', "    code: *") == 1) {
            local count = `count' + 1
        }
        file read `fh' line
    }
    file close `fh'
    
    * Return results
    return scalar count = `count'
    return local type "`type'"
    
    di as result "  Parsed `count' `type'"
end

* Note: The main wrapper unicefdata_xmltoyaml is now defined in unicefdata_xmltoyaml.ado
* This file only contains the Python-specific parser unicefdata_xmltoyaml_py

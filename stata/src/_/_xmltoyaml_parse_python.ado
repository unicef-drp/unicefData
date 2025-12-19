*******************************************************************************
* _xmltoyaml_parse_python
*! v 1.2.0   06Dec2025               by Joao Pedro Azevedo (UNICEF)
* Python-based XML parser - Uses shell Python for robust cross-platform processing
*******************************************************************************

program define _xmltoyaml_parse_python, rclass
    version 14.0
    
    syntax, XMLFILE(string) OUTFILE(string) TYPE(string) ///
        [AGENCY(string) VERSION(string) CONTENTTYPE(string) ///
         CODELISTID(string) CODELISTNAME(string) SYNCEDAT(string) ///
         SOURCE(string) APPEND]
    
    * Find Python helper script - multiple strategies
    local python_script ""
    
    * Strategy 1: findfile in adopath
    capture findfile unicefdata_xml2yaml.py
    if (_rc == 0) {
        local python_script "`r(fn)'"
    }
    
    * Strategy 2: Find relative to unicefdata_xmltoyaml.ado location (look in py/ sibling)
    if ("`python_script'" == "") {
        capture findfile unicefdata_xmltoyaml.ado
        if (_rc == 0) {
            local ado_path "`r(fn)'"
            * Get directory: remove filename to get directory
            local ado_dir = substr("`ado_path'", 1, strlen("`ado_path'") - strlen("unicefdata_xmltoyaml.ado"))
            * Look in sibling py/ folder
            local trypath "`ado_dir'../py/unicefdata_xml2yaml.py"
            capture confirm file "`trypath'"
            if (_rc == 0) {
                local python_script "`trypath'"
            }
        }
    }
    
    * Strategy 3: Hardcoded development path (fallback)
    if ("`python_script'" == "") {
        local dev_paths `""D:/jazevedo/GitHub/unicefData/stata/src/py/unicefdata_xml2yaml.py" "D:\jazevedo\GitHub\unicefData\stata\src\py\unicefdata_xml2yaml.py""'
        foreach path in `dev_paths' {
            capture confirm file `path'
            if (_rc == 0) {
                local python_script `path'
                continue, break
            }
        }
    }
    
    * Strategy 4: Search in common locations relative to pwd
    if ("`python_script'" == "") {
        local rel_paths `""stata/src/py/unicefdata_xml2yaml.py" "src/py/unicefdata_xml2yaml.py" "py/unicefdata_xml2yaml.py" "unicefdata_xml2yaml.py""'
        foreach path in `rel_paths' {
            capture confirm file "`path'"
            if (_rc == 0) {
                local python_script "`path'"
                continue, break
            }
        }
    }
    
    if ("`python_script'" == "") {
        di as txt "  Python XML helper script not found"
        di as txt "  Searched: findfile, relative to ado, dev paths, pwd"
        return scalar count = 0
        exit
    }
    
    di as txt "  Found Python script: `python_script'"
    di as txt "  Using Python for XML processing..."
    
    * Build Python command - use forward slashes for cross-platform compatibility
    local python_script = subinstr("`python_script'", "\", "/", .)
    local xmlfile_clean = subinstr("`xmlfile'", "\", "/", .)
    local outfile_clean = subinstr("`outfile'", "\", "/", .)
    
    * Build command arguments separately to avoid quoting issues
    local dq = char(34)
    local args `type' `dq'`xmlfile_clean'`dq' `dq'`outfile_clean'`dq'
    
    if ("`version'" != "") {
        local args `args' --version `dq'`version'`dq'
    }
    if ("`agency'" != "") {
        local args `args' --agency `dq'`agency'`dq'
    }
    if ("`source'" != "") {
        local args `args' --source `dq'`source'`dq'
    }
    if ("`codelistid'" != "") {
        local args `args' --codelist-id `dq'`codelistid'`dq'
    }
    if ("`codelistname'" != "") {
        local args `args' --codelist-name `dq'`codelistname'`dq'
    }
    
    * Run Python script via shell - use char(34) quotes to protect paths
    capture noisily shell python `dq'`python_script'`dq' `args'
    local shell_rc = _rc
    
    if (`shell_rc' != 0) {
        di as txt "  Shell command returned error code: `shell_rc'"
    }
    
    * Check if output was created
    capture confirm file "`outfile'"
    if (_rc != 0) {
        di as txt "  Python XML processing did not create output file"
        return scalar count = 0
        exit
    }
    
    * Count items in output
    tempname fh
    local count = 0
    file open `fh' using "`outfile'", read text
    file read `fh' line
    while (!r(eof)) {
        * Count entries - look for "  - id:" or "  CODE:" patterns
        if (strpos("`line'", "  - id:") > 0) {
            local count = `count' + 1
        }
        else if (regexm("`line'", "^  [A-Z][A-Z0-9_-]+:$")) {
            local count = `count' + 1
        }
        file read `fh' line
    }
    file close `fh'
    
    if (`count' > 0) {
        di as txt "  Parsed `count' items using Python"
    }
    return scalar count = `count'
end

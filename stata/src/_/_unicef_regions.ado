*! v 1.0.0 07Jul2026 by Joao Pedro Azevedo (UNICEF)
program define _unicef_regions, rclass
    version 14.0
    
    syntax [, METADATA AGENCY(string) TYPE(string) LATEST CLEAR]
    
    * Find Python helper script - multiple strategies
    local py_script ""
    
    * Strategy 1: findfile in adopath
    capture findfile unicefdata_regions.py
    if (_rc == 0) {
        local py_script "`r(fn)'"
    }
    
    * Strategy 2: Find relative to unicefdata.ado location (look in py/ sibling)
    if ("`py_script'" == "") {
        capture findfile unicefdata.ado
        if (_rc == 0) {
            local ado_path "`r(fn)'"
            * Remove filename to get directory
            local ado_dir = substr("`ado_path'", 1, strlen("`ado_path'") - strlen("unicefdata.ado"))
            * Look in sibling py/ folder
            local trypath "`ado_dir'../py/unicefdata_regions.py"
            capture confirm file "`trypath'"
            if (_rc == 0) {
                local py_script "`trypath'"
            }
        }
    }
    
    * Strategy 3: Check in development workspace
    if ("`py_script'" == "") {
        capture confirm file "stata/src/py/unicefdata_regions.py"
        if (_rc == 0) {
            local py_script "stata/src/py/unicefdata_regions.py"
        }
    }
    
    if ("`py_script'" == "") {
        di as error "Error: unicefdata_regions.py not found."
        exit 601
    }
    
    * Create a tempfile for output CSV
    tempfile csv_temp
    local csv_temp = subinstr("`csv_temp'", "\", "/", .)
    
    * Build python arguments
    local py_args ""
    if "`metadata'" != "" {
        local py_args "--action metadata --output \"`csv_temp'\""
    }
    else {
        local py_args "--action regions --output \"`csv_temp'\""
        if "`agency'" != "" {
            local py_args "`py_args' --agency \"`agency'\""
        }
        if "`type'" != "" {
            local py_args "`py_args' --type \"`type'\""
        }
        if "`latest'" != "" {
            local py_args "`py_args' --latest"
        }
    }
    
    * Run Python script via shell
    local py_script = subinstr("`py_script'", "\", "/", .)
    capture noisily shell python "`py_script'" `py_args'
    if _rc != 0 {
        di as error "Error executing python helper script."
        exit _rc
    }
    
    * Verify tempfile was created
    capture confirm file "`csv_temp'"
    if _rc != 0 {
        di as error "Error: Python helper did not create output file."
        exit 601
    }
    
    * Load CSV file into memory
    if "`metadata'" != "" {
        import delimited using "`csv_temp'", `clear' varnames(1) encoding("utf-8")
    }
    else {
        import delimited using "`csv_temp'", `clear' varnames(1) stringcols(country_m49) encoding("utf-8")
    }
    
    * Populate return values
    if "`metadata'" != "" {
        quietly levelsof source_agency, local(agencies)
        quietly levelsof aggregate_type, local(types)
        quietly levelsof aggregate_type_id, local(type_ids)
        
        return local source_agencies "`agencies'"
        return local aggregate_types "`types'"
        return local aggregate_type_ids "`type_ids'"
    }
    else {
        capture confirm variable source_agency
        if _rc == 0 {
            quietly levelsof source_agency, local(agencies)
            return local source_agencies "`agencies'"
        }
        capture confirm variable aggregate_type_id
        if _rc == 0 {
            quietly levelsof aggregate_type_id, local(type_ids)
            return local aggregate_type_ids "`type_ids'"
        }
    }
    
    di as result "Regions data loaded successfully."
end

*******************************************************************************
* _unicefdata_sync_dataflow_index
*! v 1.0.0   08Dec2025               by Joao Pedro Azevedo (UNICEF)
* Helper program for unicefdata_sync: Sync dataflow schemas
*******************************************************************************

program define _unicefdata_sync_dataflow_index, rclass
    syntax, OUTDIR(string) AGENCY(string) [SUFFIX(string) FORCEPYTHON FORCESTATA]
    
    * Get timestamp
    local synced_at : di %tcCCYY-NN-DD!THH:MM:SS clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local synced_at = trim("`synced_at'") + "Z"
    
    local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    
    * Set suffix for filenames
    local sfx "`suffix'"
    
    *---------------------------------------------------------------------------
    * Use Python helper if forcepython is specified
    *---------------------------------------------------------------------------
    if ("`forcepython'" != "") {
        * Find Python script location
        local script_name "stata_schema_sync.py"
        local script_path ""
        
        * Try common locations for the Python script
        foreach trypath in "stata/src/u/`script_name'" "`script_name'" {
            capture confirm file "`trypath'"
            if (_rc == 0) {
                local script_path "`trypath'"
                continue, break
            }
        }
        
        * Check adopath locations if not found yet
        if ("`script_path'" == "") {
            foreach path in `c(adopath)' {
                local trypath = "`path'/`script_name'"
                local trypath = subinstr("`trypath'", "\", "/", .)
                capture confirm file "`trypath'"
                if (_rc == 0) {
                    local script_path "`trypath'"
                    continue, break
                }
            }
        }
        
        if ("`script_path'" == "") {
            di as err "     Python script not found: `script_name'"
            di as err "     Ensure stata_schema_sync.py is in stata/src/u/ or adopath"
            return scalar count = 0
            error 601
        }
        
        * Build Python command
        local suffix_arg ""
        if ("`sfx'" != "") {
            local suffix_arg `"--suffix "`sfx'""'
        }
        
        tempfile pyout
        local cmd `"python "`script_path'" "`outdir'" `suffix_arg' --verbose"'
        
        di as text "  Script: `script_path'"
        di as text "  Running Python schema sync..."
        
        if ("`c(os)'" == "Windows") {
            shell `cmd' > "`pyout'" 2>&1
        }
        else {
            shell `cmd' > "`pyout'" 2>&1
        }
        
        * Read output to get count
        local n_success = 0
        tempname pyfh
        capture file open `pyfh' using "`pyout'", read
        if (_rc == 0) {
            file read `pyfh' line
            while !r(eof) {
                * Look for "Success: Synced N dataflow schemas"
                if (strmatch(`"`line'"', "*Success: Synced*")) {
                    * Extract number
                    local tmp = regexr(`"`line'"', ".*Synced ", "")
                    local tmp = regexr("`tmp'", " dataflow.*", "")
                    local n_success = real("`tmp'")
                }
                * Display Python output
                di as text "  `line'"
                file read `pyfh' line
            }
            file close `pyfh'
        }
        
        * Verify output file was created
        local index_file "`outdir'dataflow_index`sfx'.yaml"
        capture confirm file "`index_file'"
        if (_rc != 0) {
            di as err "     Python schema sync failed to create index file"
            return scalar count = 0
            error 601
        }
        
        return scalar count = `n_success'
        exit
    }
    
    *---------------------------------------------------------------------------
    * Native Stata parsing (default or forcestata)
    * NOTE: This may fail on large XML responses due to macro length limits
    *---------------------------------------------------------------------------
    
    * First get list of all dataflows
    local df_url "`base_url'/dataflow/`agency'?references=none&detail=full"
    tempfile df_xml df_txt
    capture copy "`df_url'" "`df_xml'", public replace
    
    if (_rc != 0) {
        di as err "Failed to fetch dataflow list"
        return scalar count = 0
        exit
    }
    
    * Parse dataflow list to get IDs
    capture filefilter "`df_xml'" "`df_txt'", from("<str:Dataflow") to("\n<str:Dataflow") replace
    
    * Build list of dataflows
    local df_ids ""
    local df_names ""
    local df_versions ""
    local n_dataflows = 0
    
    tempname infh
    capture file open `infh' using "`df_txt'", read
    if (_rc == 0) {
        file read `infh' line
        while !r(eof) {
            if (strmatch(`"`line'"', `"*<str:Dataflow *id=*"') == 1) {
                * Extract ID
                local tmp = `"`line'"'
                local pos = strpos(`"`tmp'"', `"id=""')
                if (`pos' > 0) {
                    local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                    local pos2 = strpos(`"`tmp2'"', `"""')
                    if (`pos2' > 0) {
                        local df_id = substr(`"`tmp2'"', 1, `pos2' - 1)
                        local df_ids "`df_ids' `df_id'"
                        local n_dataflows = `n_dataflows' + 1
                        
                        * Extract version
                        local pos3 = strpos(`"`tmp'"', `"version=""')
                        if (`pos3' > 0) {
                            local tmp3 = substr(`"`tmp'"', `pos3' + 9, .)
                            local pos4 = strpos(`"`tmp3'"', `"""')
                            if (`pos4' > 0) {
                                local df_ver = substr(`"`tmp3'"', 1, `pos4' - 1)
                                local df_versions "`df_versions' `df_ver'"
                            }
                        }
                        else {
                            local df_versions "`df_versions' 1.0"
                        }
                        
                        * Extract name
                        local pos5 = strpos(`"`tmp'"', `"<com:Name xml:lang="en">"')
                        if (`pos5' > 0) {
                            local tmp4 = substr(`"`tmp'"', `pos5' + 24, .)
                            local pos6 = strpos(`"`tmp4'"', "</com:Name>")
                            if (`pos6' > 0) {
                                local df_name = substr(`"`tmp4'"', 1, `pos6' - 1)
                                local df_name = subinstr(`"`df_name'"', "'", "''", .)
                                local df_names `"`df_names'"`df_name'" "'
                            }
                        }
                        else {
                            local df_names `"`df_names'"" "'
                        }
                    }
                }
            }
            file read `infh' line
        }
        file close `infh'
    }
    
    * Create dataflows subdirectory (with suffix if provided)
    if ("`sfx'" != "") {
        local dataflows_dir "`outdir'dataflows`sfx'/"
    }
    else {
        local dataflows_dir "`outdir'dataflows/"
    }
    capture mkdir "`dataflows_dir'"
    
    * Open index file
    local index_file "`outdir'dataflow_index`sfx'.yaml"
    tempname fh
    file open `fh' using "`index_file'", write text replace
    
    file write `fh' "metadata_version: '1.0'" _n
    file write `fh' "synced_at: '`synced_at''" _n
    file write `fh' "source: SDMX API Data Structure Definitions" _n
    file write `fh' "agency: `agency'" _n
    file write `fh' "total_dataflows: `n_dataflows'" _n
    file write `fh' "dataflows:" _n
    
    * For each dataflow, fetch DSD and count dimensions/attributes
    local success_count = 0
    forvalues i = 1/`n_dataflows' {
        local df_id : word `i' of `df_ids'
        local df_ver : word `i' of `df_versions'
        local df_name : word `i' of `df_names'
        
        * Fetch DSD for this dataflow
        local dsd_url "`base_url'/dataflow/`agency'/`df_id'/`df_ver'?references=all"
        tempfile dsd_xml dsd_txt
        capture copy "`dsd_url'" "`dsd_xml'", public replace
        
        if (_rc == 0) {
            * Count dimensions (str:Dimension elements with id attribute)
            capture filefilter "`dsd_xml'" "`dsd_txt'", from("<str:Dimension") to("\n<str:Dimension") replace
            
            local n_dims = 0
            tempname dsdh
            capture file open `dsdh' using "`dsd_txt'", read
            if (_rc == 0) {
                file read `dsdh' line
                while !r(eof) {
                    if (strmatch(`"`line'"', `"*<str:Dimension *id=*"') == 1) {
                        local n_dims = `n_dims' + 1
                    }
                    file read `dsdh' line
                }
                file close `dsdh'
            }
            
            * Count attributes
            capture filefilter "`dsd_xml'" "`dsd_txt'", from("<str:Attribute") to("\n<str:Attribute") replace
            
            local n_attrs = 0
            capture file open `dsdh' using "`dsd_txt'", read
            if (_rc == 0) {
                file read `dsdh' line
                while !r(eof) {
                    if (strmatch(`"`line'"', `"*<str:Attribute *id=*"') == 1) {
                        local n_attrs = `n_attrs' + 1
                    }
                    file read `dsdh' line
                }
                file close `dsdh'
            }
            
            * Write to index
            file write `fh' "- id: `df_id'" _n
            file write `fh' "  name: '`df_name''" _n
            file write `fh' "  version: '`df_ver''" _n
            file write `fh' "  dimensions_count: `n_dims'" _n
            file write `fh' "  attributes_count: `n_attrs'" _n
            
            * Write individual dataflow schema file
            _unicefdata_sync_df_schema, ///
                dsdxml("`dsd_xml'") ///
                outfile("`dataflows_dir'`df_id'.yaml") ///
                dfid("`df_id'") ///
                dfname("`df_name'") ///
                dfver("`df_ver'") ///
                agency("`agency'") ///
                syncedat("`synced_at'")
            
            local success_count = `success_count' + 1
        }
        else {
            * Failed to fetch DSD
            file write `fh' "- id: `df_id'" _n
            file write `fh' "  name: '`df_name''" _n
            file write `fh' "  version: '`df_ver''" _n
            file write `fh' "  dimensions_count: null" _n
            file write `fh' "  attributes_count: null" _n
            file write `fh' "  error: 'Failed to fetch DSD'" _n
        }
        
        * Small delay to avoid rate limiting
        sleep 200
    }
    
    file close `fh'
    
    return scalar count = `success_count'
    return scalar total = `n_dataflows'
end

*******************************************************************************
* _unicefdata_sync_df_schema
*! v 1.0.0   08Dec2025               by Joao Pedro Azevedo (UNICEF)
* Helper program for unicefdata_sync: Write single dataflow schema to YAML
*******************************************************************************

program define _unicefdata_sync_df_schema
    version 14.0
    
    syntax, DSDXML(string) OUTFILE(string) DFID(string) DFNAME(string) ///
            DFVER(string) AGENCY(string) SYNCEDAT(string)
    
    tempfile txt_file
    tempname fh dsdh
    
    file open `fh' using "`outfile'", write text replace
    
    * Write header
    file write `fh' "id: `dfid'" _n
    file write `fh' "name: '`dfname''" _n
    file write `fh' "version: '`dfver''" _n
    file write `fh' "agency: `agency'" _n
    file write `fh' "synced_at: '`syncedat''" _n
    
    * Parse dimensions
    file write `fh' "dimensions:" _n
    
    capture filefilter "`dsdxml'" "`txt_file'", from("<str:Dimension") to("\n<str:Dimension") replace
    
    local pos_num = 0
    capture file open `dsdh' using "`txt_file'", read
    if (_rc == 0) {
        file read `dsdh' line
        while !r(eof) {
            if (strmatch(`"`line'"', `"*<str:Dimension *id=*"') == 1) {
                local tmp = `"`line'"'
                
                * Extract id
                local pos = strpos(`"`tmp'"', `"id=""')
                if (`pos' > 0) {
                    local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                    local pos2 = strpos(`"`tmp2'"', `"""')
                    if (`pos2' > 0) {
                        local dim_id = substr(`"`tmp2'"', 1, `pos2' - 1)
                        local pos_num = `pos_num' + 1
                        
                        * Extract position
                        local dim_pos = `pos_num'
                        local pos3 = strpos(`"`tmp'"', `"position=""')
                        if (`pos3' > 0) {
                            local tmp3 = substr(`"`tmp'"', `pos3' + 10, .)
                            local pos4 = strpos(`"`tmp3'"', `"""')
                            if (`pos4' > 0) {
                                local dim_pos = substr(`"`tmp3'"', 1, `pos4' - 1)
                            }
                        }
                        
                        * Extract codelist reference
                        local codelist = ""
                        local pos5 = strpos(`"`tmp'"', `"<Ref id=""')
                        if (`pos5' > 0) {
                            local tmp4 = substr(`"`tmp'"', `pos5' + 9, .)
                            local pos6 = strpos(`"`tmp4'"', `"""')
                            if (`pos6' > 0) {
                                local codelist = substr(`"`tmp4'"', 1, `pos6' - 1)
                            }
                        }
                        
                        file write `fh' "- id: `dim_id'" _n
                        file write `fh' "  position: `dim_pos'" _n
                        if ("`codelist'" != "") {
                            file write `fh' "  codelist: `codelist'" _n
                        }
                    }
                }
            }
            file read `dsdh' line
        }
        file close `dsdh'
    }
    
    * Parse time dimension
    file write `fh' "time_dimension: TIME_PERIOD" _n
    
    * Parse primary measure
    file write `fh' "primary_measure: OBS_VALUE" _n
    
    * Parse attributes
    file write `fh' "attributes:" _n
    
    capture filefilter "`dsdxml'" "`txt_file'", from("<str:Attribute") to("\n<str:Attribute") replace
    
    capture file open `dsdh' using "`txt_file'", read
    if (_rc == 0) {
        file read `dsdh' line
        while !r(eof) {
            if (strmatch(`"`line'"', `"*<str:Attribute *id=*"') == 1) {
                local tmp = `"`line'"'
                
                * Extract id
                local pos = strpos(`"`tmp'"', `"id=""')
                if (`pos' > 0) {
                    local tmp2 = substr(`"`tmp'"', `pos' + 4, .)
                    local pos2 = strpos(`"`tmp2'"', `"""')
                    if (`pos2' > 0) {
                        local attr_id = substr(`"`tmp2'"', 1, `pos2' - 1)
                        
                        * Extract codelist reference
                        local codelist = ""
                        local pos5 = strpos(`"`tmp'"', `"<Ref id=""')
                        if (`pos5' > 0) {
                            local tmp4 = substr(`"`tmp'"', `pos5' + 9, .)
                            local pos6 = strpos(`"`tmp4'"', `"""')
                            if (`pos6' > 0) {
                                local codelist = substr(`"`tmp4'"', 1, `pos6' - 1)
                            }
                        }
                        
                        file write `fh' "- id: `attr_id'" _n
                        if ("`codelist'" != "") {
                            file write `fh' "  codelist: `codelist'" _n
                        }
                    }
                }
            }
            file read `dsdh' line
        }
        file close `dsdh'
    }
    
    file close `fh'
end

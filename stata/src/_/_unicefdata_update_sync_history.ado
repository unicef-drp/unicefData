*******************************************************************************
* _unicefdata_update_sync_history
*! v 1.0.0   08Dec2025               by Joao Pedro Azevedo (UNICEF)
* Helper program for unicefdata_sync: Update sync history file
*******************************************************************************

program define _unicefdata_update_sync_history
    syntax, FILEPATH(string) VINTAGEDATE(string) SYNCEDAT(string) ///
            DATAFLOWS(integer) INDICATORS(integer) CODELISTS(integer) ///
            COUNTRIES(integer) REGIONS(integer)
    
    * Write new history file (simplified - doesn't preserve old entries)
    tempname fh
    file open `fh' using "`filepath'", write text replace
    
    file write `fh' "vintages:" _n
    file write `fh' "- vintage_date: '`vintagedate''" _n
    file write `fh' "  synced_at: '`syncedat''" _n
    file write `fh' "  dataflows: `dataflows'" _n
    file write `fh' "  indicators: `indicators'" _n
    file write `fh' "  codelists: `codelists'" _n
    file write `fh' "  countries: `countries'" _n
    file write `fh' "  regions: `regions'" _n
    file write `fh' "  errors: []" _n
    
    file close `fh'
end

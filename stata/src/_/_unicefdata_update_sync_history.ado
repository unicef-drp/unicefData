*******************************************************************************
* _unicefdata_update_sync_history
*! v 2.0.0   18Jan2026               by Joao Pedro Azevedo (UNICEF)
* Helper program for unicefdata_sync: Update sync history file
* v2.0.0: Extended schema for dataflow metadata, enrichment, checksums
*******************************************************************************

program define _unicefdata_update_sync_history
    version 14.0
    
    syntax, FILEPATH(string) VINTAGEDATE(string) SYNCEDAT(string) ///
            DATAFLOWS(integer) INDICATORS(integer) CODELISTS(integer) ///
            COUNTRIES(integer) REGIONS(integer) ///
            [DFMETASynced(integer 0) DFMETATimestamp(string) ///
             DFUniqueIndicators(integer 0) ///
             INDENRICHSynced(integer 0) INDENRICHTimestamp(string) ///
             INDWithDataflows(integer 0) INDOrphans(integer 0) ///
             INDWithDimensions(integer 0) ///
             CHECKSUMDataflows(string) CHECKSUMDfmeta(string) ///
             CHECKSUMIndmeta(string) ///
             WARNings(string) NOTE(string)]
    
    * Write enhanced history file
    tempname fh
    file open `fh' using "`filepath'", write text replace
    
    file write `fh' "vintages:" _n
    file write `fh' "- vintage_date: '`vintagedate''" _n
    file write `fh' "  synced_at: '`syncedat''" _n
    file write `fh' "" _n
    
    * Base metadata counts
    file write `fh' "  # Base metadata" _n
    file write `fh' "  dataflows: `dataflows'" _n
    file write `fh' "  indicators: `indicators'" _n
    file write `fh' "  codelists: `codelists'" _n
    file write `fh' "  countries: `countries'" _n
    file write `fh' "  regions: `regions'" _n
    file write `fh' "" _n
    
    * Dataflow dimension values metadata
    if (`dfmetasynced' > 0) {
        file write `fh' "  # Dataflow dimension values" _n
        file write `fh' "  dataflow_metadata_synced: true" _n
        if ("`dfmetatimestamp'" != "") {
            file write `fh' "  dataflow_metadata_timestamp: '`dfmetatimestamp''" _n
        }
        if (`dfuniqueindicators' > 0) {
            file write `fh' "  unique_indicators_in_dataflows: `dfuniqueindicators'" _n
        }
        file write `fh' "" _n
    }
    
    * Indicator enrichment metadata
    if (`indenrichsynced' > 0) {
        file write `fh' "  # Indicator enrichment" _n
        file write `fh' "  indicator_enrichment_synced: true" _n
        if ("`indenrichtimestamp'" != "") {
            file write `fh' "  indicator_enrichment_timestamp: '`indenrichtimestamp''" _n
        }
        if (`indwithdataflows' > 0) {
            file write `fh' "  indicators_with_dataflows: `indwithdataflows'" _n
        }
        if (`indorphans' > 0) {
            file write `fh' "  orphan_indicators: `indorphans'" _n
        }
        if (`indwithdimensions' > 0) {
            file write `fh' "  indicators_with_dimensions: `indwithdimensions'" _n
        }
        file write `fh' "" _n
    }
    
    * File checksums (for drift detection)
    if ("`checksumdataflows'" != "" | "`checksumdfmeta'" != "" | "`checksumindmeta'" != "") {
        file write `fh' "  # File checksums (SHA256)" _n
        file write `fh' "  checksums:" _n
        if ("`checksumdataflows'" != "") {
            file write `fh' "    dataflows: '`checksumdataflows''" _n
        }
        if ("`checksumdfmeta'" != "") {
            file write `fh' "    dataflow_metadata: '`checksumdfmeta''" _n
        }
        if ("`checksumindmeta'" != "") {
            file write `fh' "    indicators_metadata: '`checksumindmeta''" _n
        }
        file write `fh' "" _n
    }
    
    * Errors (always empty for now)
    file write `fh' "  errors: []" _n
    
    * Warnings (optional)
    if ("`warnings'" != "") {
        file write `fh' "  warnings:" _n
        * Split warnings by semicolon and write each as list item
        local warn_list "`warnings'"
        while ("`warn_list'" != "") {
            gettoken warn warn_list : warn_list, parse(";")
            if ("`warn'" != ";") {
                file write `fh' "  - '`warn''" _n
            }
        }
    }
    
    * Note (optional - for rollbacks, manual overrides)
    if ("`note'" != "") {
        file write `fh' "  note: '`note''" _n
    }
    
    file close `fh'
end

*! version 1.0.0  13jan2026
*! _set_default_dataflows: Set hardcoded fallback dataflow sequences
*! Author: João Pedro Azevedo

program define _set_default_dataflows
    version 11
    noisily display as text "Setting hardcoded default dataflow sequences..."    
    * Hardcoded fallback sequences (used if YAML not found)
    global dataflow_COD         "CAUSE_OF_DEATH CME MORTALITY GLOBAL_DATAFLOW"
    global dataflow_ED          "EDUCATION_UIS_SDG EDUCATION GLOBAL_DATAFLOW"
    global dataflow_CME         "CME MORTALITY GLOBAL_DATAFLOW"
    global dataflow_PT          "PT_FGM PROTECTION GLOBAL_DATAFLOW"
    global dataflow_MG          "MIGRATION_ICMPD MIGRATION GLOBAL_DATAFLOW"
    global dataflow_MNCH        "MNCH CME NUTRITION GLOBAL_DATAFLOW"
    global dataflow_DM          "DM_MALARIA GLOBAL_DATAFLOW"
    global dataflow_WSHNUT      "WSHNUT WASH NUTRITION GLOBAL_DATAFLOW"
    global dataflow_WASH        "WASH GLOBAL_DATAFLOW"
    global dataflow_VIOLENCE    "VIOLENCE PROTECTION GLOBAL_DATAFLOW"
    global dataflow_NUTRITION   "NUTRITION GLOBAL_DATAFLOW"
    global dataflow_CP          "PROTECTION GLOBAL_DATAFLOW"
    global dataflow_HH_CHAR     "HOUSEHOLD_CHARACTERISTICS GLOBAL_DATAFLOW"

end

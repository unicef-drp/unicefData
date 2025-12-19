/*==============================================================================
    Test YAML parsing to understand structure
==============================================================================*/

clear all
set more off

adopath ++ "C:\GitHub\others\unicefData\stata\src\y"

di as txt "Testing YAML parsing structure"
di as txt "==============================="

* Read dataflows YAML
yaml read using "C:\GitHub\others\unicefData\stata\metadata\vintages\dataflows.yaml", replace

di _n "Variables after yaml read:"
describe

di _n "First 30 observations:"
list in 1/30, abbrev(20)

di _n "Unique types:"
tab type

di _n "Keys containing 'dataflows':"
list key value type parent if strpos(key, "dataflows") > 0 & strpos(key, "_name") > 0, abbrev(30)

di _n "==============================="
di "Now testing indicators YAML"
di "==============================="

yaml read using "C:\GitHub\others\unicefData\stata\metadata\vintages\indicators.yaml", replace

di _n "First 50 observations:"
list in 1/50, abbrev(20)

di _n "Keys containing 'CME':"
list key value type parent if strpos(key, "CME") > 0, abbrev(30)

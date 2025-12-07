* Test Stata metadata generation with both parsers
* Run from unicefData root directory

clear all
set more off

* Add package to adopath
adopath ++ "stata/src/u"
adopath ++ "stata/src/_"

display _n "=== Testing unicefdata_sync with suffix option ===" _n

* First, generate metadata using default (Python-preferred) method
display _n "--- Generating metadata (standard filenames, Python-preferred) ---" _n
unicefdata_sync, verbose

* Check files
display _n "=== Files generated (standard) ===" _n
local metadir "stata/metadata/current"
local yamlfiles : dir "`metadir'" files "*.yaml"
foreach f of local yamlfiles {
    display "  `f'"
}

display _n "--- Generating metadata with _stataonly suffix (pure Stata parser) ---" _n
* Note: This will use the suffix option to create separate files
unicefdata_sync, suffix("_stataonly") verbose

* Check all files
display _n "=== All files in metadata/current ===" _n
local yamlfiles : dir "`metadir'" files "*.yaml"
foreach f of local yamlfiles {
    display "  `f'"
}

display _n "=== Dataflow folders ===" _n
local dfdir "`metadir'/dataflows"
capture local dffiles : dir "`dfdir'" files "*.yaml"
if (_rc == 0) {
    local dfcount : word count `dffiles'
    display "  dataflows/ : `dfcount' files"
}

local dfdir_stata "`metadir'/dataflows_stataonly"
capture local dffiles_stata : dir "`dfdir_stata'" files "*.yaml"
if (_rc == 0) {
    local dfcount_stata : word count `dffiles_stata'
    display "  dataflows_stataonly/ : `dfcount_stata' files"
}

display _n "=== Test complete ===" _n

exit, clear STATA

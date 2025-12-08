* Generate Stata metadata files
* Run from unicefData root directory

clear all
set more off

* Add package to adopath
adopath ++ "stata/src/u"
adopath ++ "stata/src/_"

* Display current adopath
adopath

* Step 1: Generate all consolidated metadata files
display _n "=== Generating consolidated metadata files ===" _n
unicefdata_sync, verbose

* Step 2: Generate individual dataflow schemas
display _n "=== Generating dataflow schemas ===" _n
unicefdata_xmltoyaml, all verbose

display _n "=== Metadata generation complete ===" _n

* List generated files
display _n "=== Files in stata/metadata/current ===" _n
local metadir "stata/metadata/current"
local yamlfiles : dir "`metadir'" files "*.yaml"
foreach f of local yamlfiles {
    display "  `f'"
}

display _n "=== Files in stata/metadata/current/dataflows ===" _n
local dfdir "stata/metadata/current/dataflows"
local dffiles : dir "`dfdir'" files "*.yaml"
local count = 0
foreach f of local dffiles {
    local ++count
}
display "  Total dataflow files: `count'"

exit, clear STATA

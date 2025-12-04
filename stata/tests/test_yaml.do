* Test script for yaml command
* Tests the unified yaml command with subcommands: read, write, describe, list
clear all
set more off

* Add ado path (parent directory contains src/y/)
adopath + "../src/y"

di as text "{hline 70}"
di as text "{bf:TEST 1: Read YAML into locals with verbose}"
di as text "{hline 70}"

yaml read using "test_config.yaml", locals verbose

di as text ""
di as text "Returned values:"
return list

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 2: Read YAML into dataset}"
di as text "{hline 70}"

yaml read using "test_config.yaml", dataset replace verbose

di as text ""
di as text "Dataset contents:"
list, clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 3: Display YAML structure}"
di as text "{hline 70}"

yaml describe

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 4: List YAML contents}"
di as text "{hline 70}"

yaml list

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 5: Read with scalars}"
di as text "{hline 70}"

yaml read using "test_config.yaml", scalars verbose

di as text ""
di as text "Scalars created:"
scalar list

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 6: Write locals to YAML}"
di as text "{hline 70}"

* Create some locals to write
local project "Test Project"
local version "2.0"
local author "UNICEF"
local year 2025

yaml write using "test_output.yaml", locals(project version author year) replace verbose

di as text ""
di as text "File written. Reading back:"
type "test_output.yaml"

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 7: Write dataset to YAML}"
di as text "{hline 70}"

* Read config first
yaml read using "test_config.yaml", dataset replace

* Write to new file
yaml write using "test_output2.yaml", dataset replace verbose

di as text ""
di as text "File written. Contents:"
type "test_output2.yaml"

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 8: Clear YAML data}"
di as text "{hline 70}"

yaml clear

di as text "Data cleared. N = " _N

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 9: List with keys option (space-delimited)}"
di as text "{hline 70}"

* Reload the dataset
yaml read using "test_config.yaml", dataset replace

* Get all indicator codes as space-delimited list
yaml list indicators, keys children

di as text ""
di as text "Keys returned: `r(keys)'"

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 10: List with stata option (compound quotes)}"
di as text "{hline 70}"

* Get indicator codes in Stata compound quote format
yaml list indicators, keys children stata

di as text ""
di as text "Keys in Stata format:"
di as result `"`r(keys)'"'

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 11: Loop over indicator codes}"
di as text "{hline 70}"

* Get the keys
yaml list indicators, keys children stata
local indicator_list `"`r(keys)'"'

* Loop over them
di as text "Looping over indicators:"
foreach ind in `indicator_list' {
    di as text "  - Processing indicator: " as result "`ind'"
}

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 12: Get dataflow codes}"
di as text "{hline 70}"

yaml list dataflows, keys children stata
di as text "Dataflow codes: " as result `"`r(keys)'"'

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 13: Get values (labels) for dataflows}"
di as text "{hline 70}"

* First, let's see what's under dataflows
yaml list dataflows

di as text ""
di as result "{bf:ALL TESTS COMPLETED}"

* Test script for yaml command
* Tests the unified yaml command with subcommands: read, write, describe, list, frames, clear
* Default behavior: uses current dataset
* Frame option: requires explicit frame(name) - Stata 16+ only
clear all
set more off

* Add ado path (parent directory contains src/y/)
adopath + "../src/y"

di as text "{hline 70}"
di as text "{bf:TEST 1: Read YAML into current dataset (default)}"
di as text "{hline 70}"

yaml read using "test_config.yaml", replace verbose

di as text ""
di as text "Dataset contents:"
list in 1/10, clean noobs

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 2: Read YAML with locals option}"
di as text "{hline 70}"

yaml read using "test_config.yaml", locals replace verbose

di as text ""
di as text "Returned values:"
return list

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 3: Display YAML structure (from dataset)}"
di as text "{hline 70}"

yaml describe

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 4: List YAML contents (from dataset)}"
di as text "{hline 70}"

yaml list

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 5: Read with scalars}"
di as text "{hline 70}"

yaml read using "test_config.yaml", scalars replace verbose

di as text ""
di as text "Scalars created:"
scalar list

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 6: Write scalars to YAML}"
di as text "{hline 70}"

* Create some scalars to write (locals cannot be passed across programs)
scalar project = 1
scalar year = 2025

yaml write using "test_output.yaml", scalars(project year) replace verbose

di as text ""
di as text "File written. Reading back:"
type "test_output.yaml"

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 7: Write dataset to YAML}"
di as text "{hline 70}"

* Read config first
yaml read using "test_config.yaml", replace

* Write to new file
yaml write using "test_output2.yaml", replace verbose

di as text ""
di as text "File written. Contents:"
type "test_output2.yaml"

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 8: List with keys option (space-delimited)}"
di as text "{hline 70}"

* Get all indicator codes as space-delimited list
yaml list indicators, keys children

di as text ""
di as text "Keys returned: `r(keys)'"

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 9: List with stata option (compound quotes)}"
di as text "{hline 70}"

* Get indicator codes in Stata compound quote format
yaml list indicators, keys children stata

di as text ""
di as text "Keys in Stata format:"
di as result `"`r(keys)'"'

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 10: Loop over indicator codes}"
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
di as text "{bf:TEST 11: Get dataflow codes}"
di as text "{hline 70}"

yaml list dataflows, keys children stata
di as text "Dataflow codes: " as result `"`r(keys)'"'

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 12: Get indicator metadata using colon syntax}"
di as text "{hline 70}"

* Reload data
yaml read using "test_config.yaml", replace

* Get all attributes for CME_MRY0T4 using colon syntax
di as text "Getting metadata for indicators:CME_MRY0T4 (colon syntax):"
yaml get indicators:CME_MRY0T4

di as text ""
di as text "Return values:"
return list

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 13: Get specific attributes with colon syntax}"
di as text "{hline 70}"

yaml get indicators:CME_MRY0, attributes(label unit)

di as text ""
di as text "r(key) = `r(key)'"
di as text "r(parent) = `r(parent)'"
di as text "r(label) = `r(label)'"
di as text "r(unit) = `r(unit)'"

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 14: Loop and get metadata using colon syntax}"
di as text "{hline 70}"

yaml list indicators, keys children
di as text ""
di as text "Indicator metadata:"
foreach ind in `r(keys)' {
    yaml get indicators:`ind', quiet
    di as text "  `ind': `r(label)'"
}

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 15: Get without colon (direct key)}"
di as text "{hline 70}"

* Direct key search without colon still works
yaml get indicators_CME_MRY0T4
di as text "Direct search r(label) = `r(label)'"

di as text ""
di as text "{hline 70}"
di as text "{bf:TEST 16: Clear dataset}"
di as text "{hline 70}"

yaml clear
di as text "After clear (N=" _N ")"

* Check if Stata version supports frames
if (`c(stata_version)' >= 16) {
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:TEST 17: Read YAML into frame (Stata 16+)}"
    di as text "{hline 70}"
    
    * First load some other data so we can show frames don't destroy it
    sysuse auto, clear
    di as text "Current dataset: auto (N=" _N ")"
    
    * Load YAML into a frame
    yaml read using "test_config.yaml", frame(cfg) verbose
    
    di as text ""
    di as text "After loading yaml to frame, current dataset still has N=" _N " (auto)"
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:TEST 18: List YAML frames}"
    di as text "{hline 70}"
    
    yaml frames, detail
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:TEST 19: Describe from frame}"
    di as text "{hline 70}"
    
    yaml describe, frame(cfg)
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:TEST 20: List from frame}"
    di as text "{hline 70}"
    
    yaml list indicators, frame(cfg) keys children
    di as text "Keys: `r(keys)'"
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:TEST 21: Get indicator metadata with colon syntax from frame}"
    di as text "{hline 70}"
    
    * Get metadata from frame using colon syntax: parent:key
    yaml get indicators:CME_MRY0T4, frame(cfg)
    di as text ""
    di as text "r(key) = `r(key)'"
    di as text "r(parent) = `r(parent)'"
    di as text "r(label) = `r(label)'"
    di as text "r(unit) = `r(unit)'"
    di as text "r(dataflow) = `r(dataflow)'"
    di as text ""
    di as text "Current dataset still auto with N=" _N
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:TEST 22: Multiple frames}"
    di as text "{hline 70}"
    
    * Create a second test file
    capture file close myfile
    file open myfile using "test_config2.yaml", write replace
    file write myfile "name: Second Config" _n
    file write myfile "settings:" _n
    file write myfile "  debug: true" _n
    file write myfile "  max_obs: 5000" _n
    file close myfile
    
    * Read it into another frame
    yaml read using "test_config2.yaml", frame(cfg2) verbose
    
    di as text ""
    di as text "Now we have multiple YAML frames:"
    yaml frames, detail
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:TEST 23: Clear specific frame}"
    di as text "{hline 70}"
    
    yaml clear cfg2
    
    di as text ""
    di as text "After clearing cfg2:"
    yaml frames
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:TEST 24: Clear all frames}"
    di as text "{hline 70}"
    
    * Reload both
    yaml read using "test_config.yaml", frame(cfg)
    yaml read using "test_config2.yaml", frame(cfg2)
    
    di as text "Before clearing all:"
    yaml frames
    
    yaml clear, all
    
    di as text ""
    di as text "After clearing all:"
    yaml frames

}
else {
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:SKIPPING FRAME TESTS: Stata version < 16}"
    di as text "{hline 70}"
}

di as text ""
di as text "{hline 70}"
di as result "{bf:ALL TESTS COMPLETED}"
di as text "{hline 70}"

* quick_v2_test.do - Test v2 parser

clear all
set more off
discard

* Add source directories
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath ++ "`base_dir'/y"
adopath ++ "`base_dir'/_"

di "=== Testing v2 parser ==="

local yaml_file "`base_dir'/_/_unicefdata_indicators_metadata.yaml"
di "YAML: `yaml_file'"

timer clear 1
timer on 1
capture noisily __unicef_parse_ind_yaml_v2 "`yaml_file'"
local rc = _rc
timer off 1

di ""
di "Return code: `rc'"
if (`rc' == 0) {
    di "Observations: " _N
    quiet timer list 1
    di "Time: " r(t1) " seconds"
    describe, short
}

di "=== DONE ==="

* test_v2_parser.do - Force fresh load of v2 parser

clear all

* Set up paths FIRST
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath ++ "`base_dir'/y"
adopath ++ "`base_dir'/_"

* FORCE clear ALL related programs
capture program drop _all
discard

* Show which version of v2 parser we're using
di "=== v2 parser location ==="
which __unicef_parse_ind_yaml_v2

* Now test the parser
local yaml_file "`base_dir'/_/_unicefdata_indicators_metadata.yaml"
di ""
di "=== Testing v2 parser ==="
di "YAML file: `yaml_file'"
capture noisily __unicef_parse_ind_yaml_v2 "`yaml_file'"
di "Return code: " _rc
if (_rc == 0) {
    describe, short
}

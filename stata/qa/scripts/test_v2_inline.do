* test_v2_inline.do - Include v2 parser directly to force fresh load

clear all

* Set up paths 
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath ++ "`base_dir'/y"
adopath ++ "`base_dir'/_"

* CRITICAL: run/include the ado file directly
do "`base_dir'/_/__unicef_parse_ind_yaml_v2.ado"

* Show that program is now defined
program list __unicef_parse_ind_yaml_v2

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

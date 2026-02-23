* debug_yaml_read.do - Test yaml read directly

clear all

* Add source directories to adopath (BEFORE standard paths for priority)
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath ++ "`base_dir'/y"
adopath ++ "`base_dir'/_"

* Verify yaml version
which yaml

* Test yaml read directly
local yaml_file "`base_dir'/_/_unicefdata_indicators_metadata.yaml"
di "YAML file: `yaml_file'"
confirm file "`yaml_file'"

di ""
di "Testing yaml read with indicators option..."
yaml read using "`yaml_file'", indicators replace

di ""
di "Success! Results:"
describe, short
list key in 1/5

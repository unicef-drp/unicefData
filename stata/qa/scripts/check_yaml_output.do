* check_yaml_output.do - See what yaml read produces

clear all

* Add source directories
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath ++ "`base_dir'/y"

* Check yaml version
which yaml

* Load and describe
local yaml_file "`base_dir'/_/_unicefdata_indicators_metadata.yaml"
yaml read using "`yaml_file'", indicators replace
describe
list in 1/3

* test_yaml_which.do - Check which yaml files are being used

clear all

* Add source directories
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath ++ "`base_dir'/y"
adopath ++ "`base_dir'/_"

di "=== yaml.ado location ==="
which yaml
di ""
di "=== yaml_read.ado location ==="
which yaml_read
di ""
di "=== __unicef_parse_ind_yaml_v2.ado location ==="
which __unicef_parse_ind_yaml_v2
di ""

* Show adopath
adopath

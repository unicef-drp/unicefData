* debug_adopath.do - Debug adopath issue

clear all

local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath + "`base_dir'/y"
adopath + "`base_dir'/_"

di "Adopath contents:"
adopath

di ""
di "Checking for files:"
which __unicef_parse_indicators_yaml
which __unicef_parse_indicators_yaml_v2
which yaml
which _unicefdata_check_yaml

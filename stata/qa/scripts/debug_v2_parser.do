* debug_v2_parser.do - Test v2 parser directly

clear all

* Add paths
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath + "`base_dir'/y"
adopath + "`base_dir'/_"

* List files in the directory
di "Files in src/_:"
local files : dir "`base_dir'/_" files "__unicef_parse_*.ado"
foreach f of local files {
    di "  `f'"
}

* Try to run the v2 ado directly
di ""
di "Running v2 parser ado file directly:"
run "`base_dir'/_/__unicef_parse_indicators_yaml_v2.ado"

di ""
di "Now checking which again:"
which __unicef_parse_indicators_yaml_v2

di ""
di "Now testing the parser:"
local yaml_file "`base_dir'/_/_unicefdata_indicators_metadata.yaml"
__unicef_parse_indicators_yaml_v2 "`yaml_file'"

* test_v2_direct.do - Direct test of v2 parser syntax

clear all

* Add source directories
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath ++ "`base_dir'/y"
adopath ++ "`base_dir'/_"

* Check yaml version
which yaml

* Test yaml read directly with the same options as v2 parser
local yaml_file "`base_dir'/_/_unicefdata_indicators_metadata.yaml"
di "Testing: yaml read using ..., bulk collapse replace colfields(...)"
yaml read using "`yaml_file'", bulk collapse replace ///
    colfields(code;name;description;urn;parent;tier;tier_reason)

describe, short
list ind_code name in 1/3

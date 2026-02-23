*******************************************************************************
* benchmark_parsers.do
* Compare v1 (vectorized) vs v2 (yaml.ado) indicator metadata parsers
* Created: 21Feb2026
*******************************************************************************

clear all
set more off

* Add source directories to adopath (BEFORE standard paths for priority)
local base_dir "C:/GitHub/myados/unicefdata-dev/stata/src"
adopath ++ "`base_dir'/y"
adopath ++ "`base_dir'/_"
adopath ++ "`base_dir'/u"

* Verify v2 parser is accessible
capture which __unicef_parse_ind_yaml_v2
di as text "v2 parser found: " as result cond(_rc == 0, "YES", "NO")

* Locate yaml file
local yaml_file "../src/_/_unicefdata_indicators_metadata.yaml"
capture confirm file "`yaml_file'"
if (_rc != 0) {
    di as error "Indicators metadata not found at: `yaml_file'"
    exit 601
}

di as text _n "======================================================================"
di as text "UNICEFDATA Parser Benchmark"
di as text "======================================================================"
di as text "YAML file: " as result "`yaml_file'"

* Get file size
quietly {
    tempname fh
    file open `fh' using "`yaml_file'", read
    file seek `fh' eof
    local filesize = r(loc)
    file close `fh'
}
di as text "File size: " as result "`filesize'" as text " bytes"
di as text "======================================================================"

*-------------------------------------------------------------------------------
* Test 1: v1 parser (vectorized ado)
*-------------------------------------------------------------------------------
di as text _n "TEST 1: v1 parser (vectorized ado - __unicef_parse_indicators_yaml)"
di as text "----------------------------------------------------------------------"

timer clear 1
timer on 1

capture noisily __unicef_parse_indicators_yaml "`yaml_file'"
local v1_rc = _rc

timer off 1

if (`v1_rc' == 0) {
    local v1_obs = _N
    di as result "  Observations: " _N
    di as text "  Variables: " as result c(k)
    describe, short
}
else {
    di as error "  v1 parser failed with rc = `v1_rc'"
    local v1_obs = 0
}

quietly timer list 1
local v1_time = r(t1)
di as text _n "  Time: " as result %6.2f `v1_time' as text " seconds"

*-------------------------------------------------------------------------------
* Test 2: v2 parser (yaml.ado wrapper)
*-------------------------------------------------------------------------------
di as text _n "TEST 2: v2 parser (yaml.ado wrapper - __unicef_parse_ind_yaml_v2)"
di as text "----------------------------------------------------------------------"

clear

* Clear yaml check flag to force fresh check
capture macro drop _unicef_yaml_checked

* Force reload of ALL related programs from disk (Stata caches ado programs)
capture program drop __unicef_parse_ind_yaml_v2
capture program drop _unicef_collapse_array_fields
capture program drop _unicefdata_check_yaml
capture program drop _unicefdata_parse_yaml_version
capture program drop _unicefdata_compare_versions

timer clear 2
timer on 2

capture noisily __unicef_parse_ind_yaml_v2 "`yaml_file'"
local v2_rc = _rc

timer off 2

if (`v2_rc' == 0) {
    local v2_obs = _N
    di as result "  Observations: " _N
    di as text "  Variables: " as result c(k)
    describe, short
    list ind_code field_name in 1/5, sep(0)
}
else {
    di as error "  v2 parser failed with rc = `v2_rc'"
    local v2_obs = 0
}

quietly timer list 2
local v2_time = r(t2)
di as text _n "  Time: " as result %6.2f `v2_time' as text " seconds"

*-------------------------------------------------------------------------------
* Summary
*-------------------------------------------------------------------------------
di as text _n "======================================================================"
di as text "BENCHMARK RESULTS"
di as text "======================================================================"

di as text _col(5) "Parser" _col(35) "Time (sec)" _col(50) "Rows" _col(60) "Status"
di as text "----------------------------------------------------------------------"

local v1_status = cond(`v1_rc' == 0, "OK", "FAIL")
local v2_status = cond(`v2_rc' == 0, "OK", "FAIL")

di as text _col(5) "v1 (vectorized ado)" _col(35) as result %6.2f `v1_time' _col(50) `v1_obs' _col(60) "`v1_status'"
di as text _col(5) "v2 (yaml.ado)" _col(35) as result %6.2f `v2_time' _col(50) `v2_obs' _col(60) "`v2_status'"

if (`v1_time' > 0 & `v2_time' > 0) {
    local speedup = (`v1_time' - `v2_time') / `v1_time' * 100
    local ratio = `v1_time' / `v2_time'
    di as text "----------------------------------------------------------------------"
    di as text "Improvement: " as result %5.1f `speedup' as text "% faster"
    di as text "Speed ratio: " as result %4.2f `ratio' as text "x"
}

di as text "======================================================================"

* Final status
if (`v1_rc' == 0 & `v2_rc' == 0 & `v1_obs' == `v2_obs') {
    di as result _n "OK: Both parsers produced identical row counts"
    exit 0
}
else if (`v1_obs' != `v2_obs' & `v1_rc' == 0 & `v2_rc' == 0) {
    di as error _n "WARNING: Row count mismatch: v1=`v1_obs', v2=`v2_obs'"
    exit 1
}
else {
    di as error _n "FAIL: One or both parsers failed"
    exit 1
}

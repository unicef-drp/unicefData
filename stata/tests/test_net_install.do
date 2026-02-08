* test_net_install.do - Verify net install + unicefdata_setup distributes all YAML files
* Run from: stata/tests/

clear all
discard

* Locate src/ directory relative to tests/ directory
quietly findfile "test_net_install.do"
local test_dir = subinstr("`r(fn)'", "/test_net_install.do", "", .)
local test_dir = subinstr("`test_dir'", "\test_net_install.do", "", .)
local src_dir = "`test_dir'/../src"

* Step 1: Install from src/ directory (same as user would)
di as text "Step 1: net install unicefdata..."
net install unicefdata, from("`src_dir'") replace force
di as result "net install completed successfully"

* Step 2: Run unicefdata_setup to install dataflow schemas
di ""
di as text "Step 2: unicefdata_setup..."
discard
unicefdata_setup, replace verbose

* Step 3: Verify core YAML files exist in PLUS
di ""
di as text "Step 3: Verification..."
local plus_dir "`c(sysdir_plus)'"
di "PLUS directory: `plus_dir'"

* Core metadata YAML files
local yaml_files "_unicefdata_dataflows.yaml _unicefdata_indicators.yaml _unicefdata_codelists.yaml _unicefdata_countries.yaml _unicefdata_regions.yaml _unicefdata_sync_history.yaml _dataflow_index.yaml _dataflow_fallback_sequences.yaml _unicefdata_indicators_metadata.yaml _indicator_dataflow_map.yaml _unicefdata_dataflow_metadata.yaml"

local ok = 0
local fail = 0
foreach f in `yaml_files' {
    capture confirm file "`plus_dir'_/`f'"
    if _rc == 0 {
        local ok = `ok' + 1
        di as text "  OK: _/`f'"
    }
    else {
        local fail = `fail' + 1
        di as error "  MISSING: _/`f'"
    }
}
di ""
di as text "Core YAML: `ok' found, `fail' missing"

* Check individual dataflow schema files (sample)
local df_ok = 0
local df_fail = 0
foreach df in CME NUTRITION IMMUNISATION EDUCATION HIV_AIDS WASH_HOUSEHOLDS PT PT_CM GENDER DM {
    capture confirm file "`plus_dir'_/_dataflows/`df'.yaml"
    if _rc == 0 {
        local df_ok = `df_ok' + 1
        di as text "  OK: _/_dataflows/`df'.yaml"
    }
    else {
        local df_fail = `df_fail' + 1
        di as error "  MISSING: _/_dataflows/`df'.yaml"
    }
}
di ""
di as text "Dataflow schemas (sample): `df_ok' found, `df_fail' missing"

* Summary
di ""
if (`fail' == 0 & `df_fail' == 0) {
    di as result "ALL YAML FILES DISTRIBUTED SUCCESSFULLY"
}
else {
    di as error "SOME YAML FILES MISSING - check package file"
}

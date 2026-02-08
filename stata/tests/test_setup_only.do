clear all
discard

* Locate src/ directory relative to tests/ directory
quietly findfile "test_setup_only.do"
local test_dir = subinstr("`r(fn)'", "/test_setup_only.do", "", .)
local test_dir = subinstr("`test_dir'", "\test_setup_only.do", "", .)
local src_dir = "`test_dir'/../src"

adopath ++ "`src_dir'"
unicefdata_setup, replace verbose

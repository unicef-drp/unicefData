clear all
discard
cap program drop unicefdata_setup

* Locate the test ado file relative to this script
quietly findfile "test_setup_original.do"
local test_dir = subinstr("`r(fn)'", "/test_setup_original.do", "", .)
local test_dir = subinstr("`test_dir'", "\test_setup_original.do", "", .)

do "`test_dir'/unicefdata_setup_orig.ado"
unicefdata_setup, replace verbose

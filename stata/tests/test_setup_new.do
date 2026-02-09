clear all
discard
cap program drop unicefdata_setup

* Locate the test ado file relative to this script
quietly findfile "test_setup_new.do"
local test_dir = subinstr("`r(fn)'", "/test_setup_new.do", "", .)
local test_dir = subinstr("`test_dir'", "\test_setup_new.do", "", .)

do "`test_dir'/unicefdata_setup_test.ado"
unicefdata_setup, replace verbose

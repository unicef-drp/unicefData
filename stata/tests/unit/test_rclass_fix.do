clear all
set more off

* Add repo's stata/src directories to adopath instead of using net install
* This ensures we test the code in the current checkout
* NOTE: Run from repository root with: do stata/tests/unit/test_rclass_fix.do
* Or with the working directory set to stata/tests/unit/
quietly capture adopath + "../../src/u"
quietly capture adopath + "../../src/_"
quietly capture adopath + "stata/src/u"
quietly capture adopath + "stata/src/_"

discard
unicefdata, indicator(CME_MRM0) clear wide verbose
describe
list in 1/2
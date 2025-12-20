clear all
set more off
capture log close _all
log using "c:\GitHub\others\unicefData\outputs\readme_gen.log", replace text

* Reload ado files
discard

* Generate categories output
noi di "=================================================="
noi di "  Available Indicator Categories"
noi di "=================================================="
unicefdata, categories

* Generate search output for mortality
noi di "================================================================================"
noi di "  UNICEF Indicators matching 'mortality'"
noi di "================================================================================"
unicefdata, search(mortality) limit(10)

* Generate sample data fetch and preview
unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) year(2015:2020) clear
noi list iso3 country indicator period value in 1/10, abbreviate(20)

log close
exit, clear

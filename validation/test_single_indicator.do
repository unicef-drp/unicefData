*! Test single failing indicator: NT_DANT_BMI_L18_MOD
* This indicator succeeded in Python (11,645 rows) and R (11,649 rows) but failed in Stata

clear all
set more off

* Capture to show errors
capture noisily {
    di "========================================="
    di "Testing: NT_DANT_BMI_L18_MOD"
    di "Expected: ~11,645 rows (Python/R success)"
    di "========================================="
    di ""
    
    * Try to load the indicator
    unicefdata, indicator(NT_DANT_BMI_L18_MOD) clear
    
    * Check results
    di ""
    di "SUCCESS! Loaded data:"
    describe
    di ""
    di "Row count: " _N
    di "Variables: " c(k)
    list in 1/5
}

* Check if it failed
if _rc != 0 {
    di ""
    di "========================================="
    di "ERROR! Return code: " _rc
    di "========================================="
}

exit

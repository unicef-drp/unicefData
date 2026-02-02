* Compare URLs across platforms for test indicators
* Date: January 16, 2026

clear all
set more off
discard

* Ensure latest version is loaded
net install unicefdata, from("C:\GitHub\myados\unicefData-dev\stata") replace

* Test each indicator and capture URL (verbose mode will show it)
log using "C:\GitHub\myados\unicefData-dev\validation\results\url_comparison.log", replace text

noi di ""
noi di "=== ED_MAT_G23 ==="
capture noisily unicefdata, indicator(ED_MAT_G23) clear verbose
if (_rc == 0) {
    noi di "Observations: " _N
}

noi di ""
noi di "=== FD_FOUNDATIONAL_LEARNING ==="
capture noisily unicefdata, indicator(FD_FOUNDATIONAL_LEARNING) clear verbose
if (_rc == 0) {
    noi di "Observations: " _N
}

noi di ""
noi di "=== ECD_CHLD_U5_BKS-HM ==="
capture noisily unicefdata, indicator(ECD_CHLD_U5_BKS-HM) clear verbose
if (_rc == 0) {
    noi di "Observations: " _N
}

noi di ""
noi di "=== NT_CF_ISSSF_FL ==="
capture noisily unicefdata, indicator(NT_CF_ISSSF_FL) clear verbose
if (_rc == 0) {
    noi di "Observations: " _N
}

noi di ""
noi di "=== NT_CF_MMF ==="
capture noisily unicefdata, indicator(NT_CF_MMF) clear verbose
if (_rc == 0) {
    noi di "Observations: " _N
}

log close
exit

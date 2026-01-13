
set trace off
set more off
capture log close
log using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/stata/test_log.txt", append

capture {
    unicefdata, indicator(CME_MRM1T11)   clear
    
    qui describe
    local nobs = r(N)
    
    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/stata/success/CME_MRM1T11.csv", replace
        display "OK: `nobs' rows"
    } else {
        display "NO_DATA"
    }
}

if _rc {
    display "ERROR: " _error(706)
}

log close
exit, clear

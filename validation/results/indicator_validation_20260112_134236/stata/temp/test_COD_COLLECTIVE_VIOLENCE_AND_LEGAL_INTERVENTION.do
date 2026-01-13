
set trace off
set more off
capture log close
log using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/stata/test_log.txt", append

capture {
    unicefdata, indicator(COD_COLLECTIVE_VIOLENCE_AND_LEGAL_INTERVENTION)   clear
    
    qui describe
    local nobs = r(N)
    
    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/stata/success/COD_COLLECTIVE_VIOLENCE_AND_LEGAL_INTERVENTION.csv", replace
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

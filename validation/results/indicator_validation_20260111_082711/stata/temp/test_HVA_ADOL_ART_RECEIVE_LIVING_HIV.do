
set trace off
set more off
capture log close
log using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/stata/test_log.txt", append

capture {
    unicefdata, indicator(HVA_ADOL_ART_RECEIVE_LIVING_HIV)   clear
    
    qui describe
    local nobs = r(N)
    
    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/stata/success/HVA_ADOL_ART_RECEIVE_LIVING_HIV.csv", replace
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

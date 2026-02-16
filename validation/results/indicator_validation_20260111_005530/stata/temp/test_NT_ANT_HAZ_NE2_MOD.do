
set trace off
set more off
capture log close
log using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_005530/stata/test_log.txt", append

capture {
    unicefdata, indicator(NT_ANT_HAZ_NE2_MOD) countries(USA BRA IND KEN CHN) year(2020) clear
    
    qui describe
    local nobs = r(N)
    
    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_005530/stata/success/NT_ANT_HAZ_NE2_MOD.csv", replace
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

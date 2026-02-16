
clear all
set more off
set trace off
discard

* Add unicefData ado paths
adopath ++ "C:/GitHub/myados/unicefData/stata/src/u"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/_"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/y"

capture log close
log using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_204107/stata/test_log.txt", text append

capture {
    unicefdata, indicator(CME_COVID_DEATHS_SHARE)   clear
    
    qui describe
    local nobs = r(N)
    
    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_204107/stata/success/CME_COVID_DEATHS_SHARE.csv", replace
        display "OK: `nobs' rows"
    } else {
        display "NO_DATA"
    }
}

if _rc {
    display "ERROR: _rc=`=_rc' " _error(706)
    file open ferr using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_204107/stata/failed/CME_COVID_DEATHS_SHARE.error", write replace
    file write ferr "Stata error: _rc=`=_rc'" _n
    file close ferr
}

log close
exit, clear

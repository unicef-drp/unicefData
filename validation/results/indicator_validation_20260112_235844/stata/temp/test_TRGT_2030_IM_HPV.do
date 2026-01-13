clear all
set more off
set trace off
discard

* Add unicefData ado paths
adopath ++ "C:/GitHub/myados/unicefData/stata/src/u"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/_"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/y"

capture log close
log using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/stata/test_log.txt", text append

unicefdata, indicator(TRGT_2030_IM_HPV)   clear

if _rc == 0 {
    qui describe
    local nobs = r(N)
    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/stata/success/TRGT_2030_IM_HPV.csv", replace
        display "OK: `nobs' rows"
    }
    else {
        display "NO_DATA"
    }
}
else {
    display "ERROR: _rc=" _rc
    file open ferr using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/stata/failed/TRGT_2030_IM_HPV.error", write replace
    file write ferr "Stata error: _rc=" (_rc) _n
    file close ferr
}

log close
exit, clear
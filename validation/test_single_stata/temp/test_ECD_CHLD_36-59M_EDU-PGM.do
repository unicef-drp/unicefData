
clear all
set more off
set trace off
discard

* Add unicefData ado paths
adopath ++ "C:/GitHub/myados/unicefData/stata/src/u"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/_"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/y"

capture log close
log using "C:/GitHub/myados/unicefData/validation/test_single_stata/test_log.txt", text append

capture {
    unicefdata, indicator(ECD_CHLD_36-59M_EDU-PGM)   clear
    
    qui describe
    local nobs = r(N)
    
    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData/validation/test_single_stata/success/ECD_CHLD_36-59M_EDU-PGM.csv", replace
        display "OK: `nobs' rows"
    } else {
        display "NO_DATA"
    }
}

if _rc {
    display "ERROR: _rc=`=_rc' " _error(706)
    file open ferr using "C:/GitHub/myados/unicefData/validation/test_single_stata/failed/ECD_CHLD_36-59M_EDU-PGM.error", write replace
    file write ferr "Stata error: _rc=`=_rc'" _n
    file close ferr
}

log close
exit, clear

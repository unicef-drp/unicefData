clear all
set more off
set trace off
discard

* Add unicefData ado paths
adopath ++ "C:/GitHub/myados/unicefData/stata/src/u"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/_"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/y"

capture log close
log using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/stata/test_log.txt", text append

unicefdata, indicator(COD_PARALYTIC_ILEUS_AND_INTESTINAL_OBSTRUCTION)   clear

if _rc == 0 {
    qui describe
    local nobs = r(N)
    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/stata/success/COD_PARALYTIC_ILEUS_AND_INTESTINAL_OBSTRUCTION.csv", replace
        display "OK: `nobs' rows"
    }
    else {
        display "NO_DATA"
    }
}
else {
    display "ERROR: _rc=" _rc
    file open ferr using "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/stata/failed/COD_PARALYTIC_ILEUS_AND_INTESTINAL_OBSTRUCTION.error", write replace
    file write ferr "Stata error: _rc=" (_rc) _n
    file close ferr
}

log close
exit, clear
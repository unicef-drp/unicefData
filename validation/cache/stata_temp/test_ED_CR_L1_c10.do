
clear all
set more off
capture log close

* Install unicefdata from local dev source
net install unicefdata, from("C:/GitHub/myados/unicefData-dev/stata") all replace force

* Fetch indicator with filter options
capture noisily unicefdata, indicator(ED_CR_L1) nosparse countries(USA GBR BRA IND NGA ZAF CHN JPN DEU FRA) clear

if _rc == 0 {
    qui describe
    local nobs = r(N)
    local nvars = r(k)

    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData-dev/validation/cache/stata/ED_CR_L1_c10.csv", replace
        di "SUCCESS:`nobs':`nvars'"
    }
    else {
        di "NOT_FOUND:0:0"
    }
}
else {
    di "ERROR:rc=" _rc
}

exit, clear

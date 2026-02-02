
clear all
set more off
capture log close

* Install unicefdata from local dev source
net install unicefdata, from("C:/GitHub/myados/unicefData-dev/stata") all replace force

* Fetch indicator with filter options
capture noisily unicefdata, indicator(PT_F_20-24_MRD_U18) nosparse nofilter clear

if _rc == 0 {
    qui describe
    local nobs = r(N)
    local nvars = r(k)

    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData-dev/validation/cache/stata/PT_F_20-24_MRD_U18_nofilter.csv", replace
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

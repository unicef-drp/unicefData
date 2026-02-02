
clear all
set more off
capture log close

* Install unicefdata from local dev source
net install unicefdata, from("C:/GitHub/myados/unicefData-dev/stata") all replace force

* Fetch indicator with filter options
capture noisily unicefdata, indicator(GN_FB_BNK_ACCSS) nosparse clear

if _rc == 0 {
    qui describe
    local nobs = r(N)
    local nvars = r(k)

    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData-dev/validation/cache/stata/GN_FB_BNK_ACCSS.csv", replace
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

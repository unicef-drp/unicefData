
clear all
set more off
capture log close

* Install unicefdata from local dev source
net install unicefdata, from("C:/GitHub/myados/unicefData-dev/stata") all replace force

* Fetch indicator with filter options
capture noisily unicefdata, indicator(WS_PPL_W-B) nosparse countries(AFG BGD ETH KEN MMR NGA PAK TZA UGA ZMB) clear

if _rc == 0 {
    qui describe
    local nobs = r(N)
    local nvars = r(k)

    if `nobs' > 0 {
        export delimited using "C:/GitHub/myados/unicefData-dev/validation/cache/stata/WS_PPL_W-B_c10.csv", replace
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

* stata_verbose_http_trace.do
* Capture HTTP request details in Stata
* Note: Stata's HTTP logging is limited, but we can use -set trace- and -set tracedepth-

clear all
set more off
set linesize 120

log using "stata_http_trace.log", replace text

noisily di "=== Stata: HTTP Request Capture ==="
noisily di ""
noisily di "Note: Stata has limited HTTP debugging capabilities"
noisily di "Using -set trace- to capture detailed execution"
noisily di ""

* Test indicators
local indicators "COD_DENGUE MG_NEW_INTERNAL_DISP"

noisily di "Testing: COD_DENGUE and MG_NEW_INTERNAL_DISP"
noisily di "Indicators with 404 errors in R"
noisily di ""

* Enable maximum tracing
set tracedepth 2
set tracewidth 200
set trace on

foreach indicator in `indicators' {
    noisily di ""
    noisily di string(70, "-")
    noisily di "Indicator: `indicator'"
    noisily di string(70, "-")
    noisily di ""
    
    noisily di "Making API request with trace enabled..."
    noisily di ""
    
    capture {
        noisily di "Calling: unicef_get_data"
        noisily di "  indicator: `indicator'"
        noisily di "  countries: USA"
        noisily di "  year: 2020"
        noisily di ""
        
        * This would call the actual Stata API function
        * unicef_get_data, indicator(`indicator') countries(USA) year(2020) clear
        
        noisily di "Request sent to UNICEF API"
    }
    
    if _rc == 0 {
        noisily di "✓ Request succeeded"
        noisily di "  Rows returned: " _N
    } else {
        noisily di "✗ Error encountered"
        noisily di "  Return code: " _rc
    }
}

* Disable tracing
set trace off

noisily di ""
noisily di "=== Trace Output Complete ==="
noisily di ""
noisily di "Key things to look for:"
noisily di "  1. Full URL being requested"
noisily di "  2. Request headers being sent"
noisily di "  3. HTTP response status code"
noisily di "  4. Response parsing logic"
noisily di ""

log close

noisily di "Detailed trace saved to: stata_http_trace.log"

*! stata_diagnostic.do - Diagnostic script to debug Stata failures
*! Run with: stata /e /b do stata_diagnostic.do
*! Output: stata_diagnostic_output.log

set more off
set trace off

log using "validation/stata_diagnostic_output.log", replace text

display "=" * 80
display "STATA DIAGNOSTIC TEST"
display "=" * 80
display ""
display "Stata version: " c(stata_version)
display "Flavor: " c(flavor)
display "Current directory: " c(pwd)
display "Current date: " c(current_date)
display "Current time: " c(current_time)
display ""

* Test 1: Check if unicefdata command exists
display "=" * 80
display "TEST 1: Check unicefdata command availability"
display "=" * 80
capture which unicefdata
if _rc {
    display "ERROR: unicefdata command not found (rc=`_rc')"
    display "Need to install: ssc install unicefdata"
}
else {
    display "SUCCESS: unicefdata command found"
    which unicefdata
}
display ""

* Test 2: Try a simple indicator that worked in Python/R
display "=" * 80
display "TEST 2: Simple indicator test (NT_CF_ZEROFV)"
display "=" * 80
display "This indicator succeeded in Python (4,951 rows) and R (5,008 rows)"
display ""

capture noisily {
    display "Attempting: unicefdata, indicator(NT_CF_ZEROFV) clear"
    timer clear 1
    timer on 1
    unicefdata, indicator(NT_CF_ZEROFV) clear
    timer off 1
    timer list 1
}

if _rc {
    display ""
    display "FAILED with error code: " _rc
    display "Error message captured above"
}
else {
    qui describe
    local obs = r(N)
    local vars = r(k)
    display ""
    display "SUCCESS!"
    display "Observations: " `obs'
    display "Variables: " `vars'
    qui timer list 1
    display "Execution time: " r(t1) " seconds"
    
    if `obs' > 0 {
        display ""
        display "First 5 observations:"
        list in 1/5, abbrev(15)
    }
}
display ""

* Test 3: Try with explicit countries (matching test suite)
display "=" * 80
display "TEST 3: Same indicator with country filter"
display "=" * 80
display "Testing: countries(USA BRA IND)"
display ""

capture noisily {
    display "Attempting: unicefdata, indicator(NT_CF_ZEROFV) countries(USA BRA IND) clear"
    timer clear 2
    timer on 2
    unicefdata, indicator(NT_CF_ZEROFV) countries(USA BRA IND) clear
    timer off 2
    timer list 2
}

if _rc {
    display ""
    display "FAILED with error code: " _rc
}
else {
    qui describe
    local obs = r(N)
    display ""
    display "SUCCESS!"
    display "Observations: " `obs'
    qui timer list 2
    display "Execution time: " r(t2) " seconds"
}
display ""

* Test 4: Try an indicator that failed in comprehensive test
display "=" * 80
display "TEST 4: Indicator that frequently fails (NT_DANT_BMI_L18_MOD)"
display "=" * 80
display "Python/R: 11,645-11,649 rows | Stata: FAILED"
display ""

capture noisily {
    display "Attempting: unicefdata, indicator(NT_DANT_BMI_L18_MOD) clear"
    timer clear 3
    timer on 3
    unicefdata, indicator(NT_DANT_BMI_L18_MOD) clear
    timer off 3
    timer list 3
}

if _rc {
    display ""
    display "FAILED with error code: " _rc
    display "This confirms the failure pattern seen in comprehensive test"
}
else {
    qui describe
    local obs = r(N)
    display ""
    display "SUCCESS!"
    display "Observations: " `obs'
    qui timer list 3
    display "Execution time: " r(t3) " seconds"
}
display ""

* Test 5: Memory and settings check
display "=" * 80
display "TEST 5: Stata memory and settings"
display "=" * 80
query memory
display ""
query output
display ""

* Test 6: Python subprocess test simulation
display "=" * 80
display "TEST 6: Subprocess communication test"
display "=" * 80
display "Testing if Stata can write output that Python can parse..."
display ""

* Write a simple success marker
display "PYTHON_PARSE_TEST: ROWS=100"
display "PYTHON_PARSE_TEST: STATUS=SUCCESS"
display ""

* Test 7: Check for timeout issues
display "=" * 80
display "TEST 7: Timeout simulation (sleep test)"
display "=" * 80
display "Sleeping for 5 seconds to test if subprocess times out..."
timer clear 4
timer on 4
sleep 5000
timer off 4
qui timer list 4
display "Completed 5-second sleep in " r(t4) " seconds"
display "If this works, 120-second timeout should not be the issue"
display ""

* Test 8: Large dataset test
display "=" * 80
display "TEST 8: Large dataset test (11,000+ rows)"
display "=" * 80
display "Testing NT_DANT_BMI_G25_MOD (Python: 11,645 rows, R: 11,649 rows)"
display ""

capture noisily {
    timer clear 5
    timer on 5
    unicefdata, indicator(NT_DANT_BMI_G25_MOD) clear
    timer off 5
    timer list 5
}

if _rc {
    display ""
    display "FAILED with error code: " _rc
    display "Possible memory or performance issue with large datasets"
}
else {
    qui describe
    local obs = r(N)
    display ""
    display "SUCCESS!"
    display "Observations: " `obs'
    qui timer list 5
    display "Execution time: " r(t5) " seconds"
    
    if `obs' > 10000 {
        display "Large dataset handled successfully!"
    }
}
display ""

* Summary
display "=" * 80
display "DIAGNOSTIC COMPLETE"
display "=" * 80
display "Review stata_diagnostic_output.log for detailed results"
display "=" * 80

log close
exit, clear

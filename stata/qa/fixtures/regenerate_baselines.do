*===============================================================================
* Regenerate Regression Test Baselines (REGR-01)
*===============================================================================
* PURPOSE:
*   Generate fresh baseline snapshots for REGR-01 regression testing.
*   Only run this when UNICEF API has intentionally changed data.
*
* WHEN TO USE:
*   - After UNICEF announces data revisions
*   - After API schema changes (coordinated with package updates)
*   - NEVER run automatically - baselines should be stable
*
* VERIFICATION:
*   - Compare new baselines against old baselines
*   - Document reason for change in git commit message
*   - Review with package maintainer before committing
*
* USAGE:
*   cd C:\GitHub\myados\unicefData-dev\stata\qa
*   stata /e do fixtures/regenerate_baselines.do
*===============================================================================

clear all
set more off

* Derive paths
local qadir "`c(pwd)'"
local outdir "`qadir'/fixtures"

* Verify we're in the qa directory
if !strmatch("`qadir'", "*qa") {
    di as error "ERROR: Must run from qa directory"
    di as error "Current dir: `qadir'"
    di as error "Expected: .../unicefData-dev/stata/qa"
    exit 601
}

* Verify output directory exists
cap mkdir "`outdir'"

di as text _n "{hline 80}"
di as text "Regenerating REGR-01 Regression Test Baselines"
di as text "{hline 80}"
di as text "Output directory: `outdir'"
di as text "{hline 80}" _n

*===============================================================================
* Snapshot 1: Mortality (CME_MRY0T4) - USA, BRA, 2020
*===============================================================================
di as text _n "[ 1/3 ] Generating snap_mortality_baseline.csv..."
clear
cap noi unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) clear

if _rc == 0 {
    keep indicator iso3 period value unit
    qui count
    local nobs = r(N)
    
    export delimited "`outdir'/snap_mortality_baseline.csv", replace
    di as text "        ✓ Saved: snap_mortality_baseline.csv (`nobs' obs)"
    
    di as text _n "        Preview:"
    list, sep(0) noobs
}
else {
    di as error "        ✗ FAILED: Download returned rc=`_rc'"
    di as error "        Cannot continue - check UNICEF API connectivity"
    exit _rc
}

*===============================================================================
* Snapshot 2: Vaccination (IM_DTP3) - IND, ETH, 2020
*===============================================================================
di as text _n "[ 2/3 ] Generating snap_vaccination_baseline.csv..."
clear
cap noi unicefdata, indicator(IM_DTP3) countries(IND ETH) year(2020) clear

if _rc == 0 {
    keep indicator iso3 period value unit
    qui count
    local nobs = r(N)
    
    export delimited "`outdir'/snap_vaccination_baseline.csv", replace
    di as text "        ✓ Saved: snap_vaccination_baseline.csv (`nobs' obs)"
    
    di as text _n "        Preview:"
    list, sep(0) noobs
}
else {
    di as error "        ✗ FAILED: Download returned rc=`_rc'"
    di as error "        Cannot continue - check UNICEF API connectivity"
    exit _rc
}

*===============================================================================
* Snapshot 3: Multi-indicator (CME_MRY0T4, IM_DTP3) - USA, 2020
*===============================================================================
di as text _n "[ 3/3 ] Generating snap_multi_baseline.csv..."
clear
cap noi unicefdata, indicator(CME_MRY0T4 IM_DTP3) countries(USA) year(2020) wide_indicators clear

if _rc == 0 {
    keep iso3 period CME_MRY0T4 IM_DTP3
    qui count
    local nobs = r(N)
    
    export delimited "`outdir'/snap_multi_baseline.csv", replace
    di as text "        ✓ Saved: snap_multi_baseline.csv (`nobs' obs)"
    
    di as text _n "        Preview:"
    list, sep(0) noobs
}
else {
    di as error "        ✗ FAILED: Download returned rc=`_rc'"
    di as error "        Cannot continue - check UNICEF API connectivity"
    exit _rc
}

*===============================================================================
* Summary
*===============================================================================
di as text _n "{hline 80}"
di as text "Baselines regenerated successfully"
di as text "{hline 80}"

di as text _n "NEXT STEPS:"
di as text "  1. Review differences:"
di as text "       git diff qa/fixtures/"
di as text _n "  2. If changes are intentional, document reason:"
di as text "       - UNICEF data revision"
di as text "       - API schema update"
di as text "       - Indicator replacement"
di as text _n "  3. Commit with descriptive message:"
di as text "       git add qa/fixtures/*.csv"
di as text "       git commit -m \"chore: update REGR-01 baselines (reason: <description>)\""
di as text _n "  4. Run full QA suite to verify:"
di as text "       do run_tests.do"
di as text "{hline 80}" _n

* Clean up
clear

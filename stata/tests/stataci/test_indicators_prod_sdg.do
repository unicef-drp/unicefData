*******************************************************************************
* test_indicators_prod_sdg.do
* Test all PROD-SDG-REP-2025 indicators
* Mirrors Python test_prod_sdg_indicators.py and R test_prod_sdg_indicators.R
*
* Author: Joao Pedro Azevedo
* Date: December 2025
*******************************************************************************

version 15.0

* Setup paths if not already set by run_tests.do
capture which unicefdata
if _rc {
    adopath ++ "../../src/u"
    adopath ++ "../../src/y"
    adopath ++ "."
}

* Load assertion utilities
run assert_utils.ado

di as txt ""
di as txt "TEST: PROD-SDG-REP-2025 Indicator Downloads"
di as txt "============================================"
di as txt ""

* Ensure output directory exists
capture mkdir "output"

* Initialize counters
local passed 0
local failed 0
local total_rows 0
local start_time = clock(c(current_time), "hms")

* ============================================================================
* INDICATOR DEFINITIONS (from 0121_get_data_api.R)
* ============================================================================

* Define test specifications as matrices
* Format: category dataflow indicator1 indicator2 ... explicit_flag

* ----------------------------------------------------------------------------
* Test 1: Mortality (CME)
* ----------------------------------------------------------------------------
di as txt "1. Testing MORTALITY..."
di as txt "   Indicators: CME_MRM0, CME_MRY0T4"
di as txt "   Dataflow: CME"

capture noisily unicefdata, ///
    indicator(CME_MRM0 CME_MRY0T4) ///
    dataflow(CME) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_mort.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 2: Nutrition (NUTRITION)
* ----------------------------------------------------------------------------
di as txt "2. Testing NUTRITION..."
di as txt "   Indicators: NT_ANT_HAZ_NE2_MOD, NT_ANT_WHZ_NE2, NT_ANT_WHZ_PO2_MOD"
di as txt "   Dataflow: NUTRITION"

capture noisily unicefdata, ///
    indicator(NT_ANT_HAZ_NE2_MOD NT_ANT_WHZ_NE2 NT_ANT_WHZ_PO2_MOD) ///
    dataflow(NUTRITION) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_nutr.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 3: Education (EDUCATION_UIS_SDG) - requires explicit dataflow
* ----------------------------------------------------------------------------
di as txt "3. Testing EDUCATION..."
di as txt "   Indicators: ED_CR_L1_UIS_MOD, ED_CR_L2_UIS_MOD, ED_CR_L3_UIS_MOD"
di as txt "   Dataflow: EDUCATION_UIS_SDG (explicit)"

capture noisily unicefdata, ///
    indicator(ED_CR_L1_UIS_MOD ED_CR_L2_UIS_MOD ED_CR_L3_UIS_MOD) ///
    dataflow(EDUCATION_UIS_SDG) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_edu.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 4: Immunization (IMMUNISATION)
* ----------------------------------------------------------------------------
di as txt "4. Testing IMMUNIZATION..."
di as txt "   Indicators: IM_DTP3, IM_MCV1"
di as txt "   Dataflow: IMMUNISATION"

capture noisily unicefdata, ///
    indicator(IM_DTP3 IM_MCV1) ///
    dataflow(IMMUNISATION) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_immun.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 5: HIV/AIDS (HIV_AIDS)
* ----------------------------------------------------------------------------
di as txt "5. Testing HIV/AIDS..."
di as txt "   Indicators: HVA_EPI_INF_RT"
di as txt "   Dataflow: HIV_AIDS"

capture noisily unicefdata, ///
    indicator(HVA_EPI_INF_RT) ///
    dataflow(HIV_AIDS) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_hiv.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 6: WASH (WASH_HOUSEHOLDS)
* ----------------------------------------------------------------------------
di as txt "6. Testing WASH..."
di as txt "   Indicators: WS_PPL_W-ALB, WS_PPL_S-ALB"
di as txt "   Dataflow: WASH_HOUSEHOLDS"

capture noisily unicefdata, ///
    indicator(WS_PPL_W-ALB WS_PPL_S-ALB) ///
    dataflow(WASH_HOUSEHOLDS) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_wash.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 7: MNCH (Maternal, Newborn, Child Health)
* ----------------------------------------------------------------------------
di as txt "7. Testing MNCH..."
di as txt "   Indicators: MNCH_ABR, MNCH_MMR, MNCH_SAB"
di as txt "   Dataflow: MNCH"

capture noisily unicefdata, ///
    indicator(MNCH_ABR MNCH_MMR MNCH_SAB) ///
    dataflow(MNCH) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_mnch.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 8: Child Protection (PT)
* ----------------------------------------------------------------------------
di as txt "8. Testing CHILD PROTECTION..."
di as txt "   Indicators: PT_CHLD_Y0T4_REG"
di as txt "   Dataflow: PT"

capture noisily unicefdata, ///
    indicator(PT_CHLD_Y0T4_REG) ///
    dataflow(PT) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_cp.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 9: Child Marriage (PT_CM) - requires explicit dataflow
* ----------------------------------------------------------------------------
di as txt "9. Testing CHILD MARRIAGE..."
di as txt "   Indicators: PT_F_20-24_MRD_U18_TND"
di as txt "   Dataflow: PT_CM (explicit)"

capture noisily unicefdata, ///
    indicator(PT_F_20-24_MRD_U18_TND) ///
    dataflow(PT_CM) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_chmrg.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 10: FGM (PT_FGM) - requires explicit dataflow
* ----------------------------------------------------------------------------
di as txt "10. Testing FGM..."
di as txt "    Indicators: PT_F_15-49_FGM"
di as txt "    Dataflow: PT_FGM (explicit)"

capture noisily unicefdata, ///
    indicator(PT_F_15-49_FGM) ///
    dataflow(PT_FGM) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_fgm.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 11: Child Poverty (CHLD_PVTY)
* ----------------------------------------------------------------------------
di as txt "11. Testing CHILD POVERTY..."
di as txt "    Indicators: PV_CHLD_DPRV-S-L1-HS"
di as txt "    Dataflow: CHLD_PVTY"

capture noisily unicefdata, ///
    indicator(PV_CHLD_DPRV-S-L1-HS) ///
    dataflow(CHLD_PVTY) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_pov.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ----------------------------------------------------------------------------
* Test 12: ECD (Early Childhood Development)
* ----------------------------------------------------------------------------
di as txt "12. Testing ECD..."
di as txt "    Indicators: ECD_CHLD_LMPSL"
di as txt "    Dataflow: ECD"

capture noisily unicefdata, ///
    indicator(ECD_CHLD_LMPSL) ///
    dataflow(ECD) ///
    clear

if (_rc == 0 & _N > 0) {
    local ++passed
    local total_rows = `total_rows' + _N
    di as result "   [OK] " _N " observations"
    qui save "output/api_unf_ecd.dta", replace
}
else {
    local ++failed
    di as error "   [FAIL] rc=" _rc ", N=" _N
}

* ============================================================================
* SUMMARY
* ============================================================================

local end_time = clock(c(current_time), "hms")
local duration = (`end_time' - `start_time') / 1000

local total = `passed' + `failed'

di as txt ""
di as txt "=============================================================================="
di as txt "SUMMARY"
di as txt "=============================================================================="
di as txt ""
di as txt "[OK] Successful: `passed'/`total'"
di as txt "[FAIL] Failed: `failed'/`total'"
di as txt ""
di as txt "[DATA] Total rows downloaded: " %12.0fc `total_rows'
di as txt "[TIME] Total time: " %5.1f `duration' "s"
di as txt ""

* Require at least 80% pass rate for overall success
local pass_rate = `passed' / `total' * 100

if (`pass_rate' < 80) {
    di as error "PROD-SDG indicator tests failed (< 80% pass rate)"
    exit 9
}

di as result "PROD-SDG indicator tests completed successfully (`passed'/`total' = " %4.1f `pass_rate' "%)"
di as txt ""

exit 0

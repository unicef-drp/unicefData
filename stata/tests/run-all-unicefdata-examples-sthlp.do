* test script
* run all examples in sthlp

cap log close

cd C:\GitHub\myados\unicefData-dev\stata\tests

log using "run-all-unicefdata-examples-sthlp_NEW.log", replace text

clear

cap program drop _inspect_current_data
program define _inspect_current_data
    * Efficient data inspection - only if data is loaded
    if _N == 0 {
        noisily di in smcl "{text}(no data in memory - metadata-only result)"
        exit
    }
    
    noisily di in smcl "{text}Observations: {result}" _N "{text}, Variables: {result}" c(k)
    
    noisily describe, short
    
    * Show first rows for structure verification (up to 3)
    local show_n = min(3, _N)
    if `show_n' > 0 {
        noisily list in 1/`show_n', abbr(20)
    }
    
    * Smart tabulation: only tab categorical vars with ≤10 unique values
    capture confirm variable iso3
    if !_rc {
        quietly levelsof iso3, local(iso3_levels)
        local n_iso : word count `iso3_levels'
        if `n_iso' <= 10 {
            noisily tab iso3, mi
        }
    }
    
    capture confirm variable sex
    if !_rc {
        quietly levelsof sex, local(sex_levels)
        local n_sex : word count `sex_levels'
        if `n_sex' <= 10 {
            noisily tab sex, mi
        }
    }
    
    capture confirm variable indicator
    if !_rc {
        quietly levelsof indicator, local(ind_levels)
        local n_ind : word count `ind_levels'
        if `n_ind' <= 10 {
            noisily tab indicator, mi
        }
    }
    
    capture confirm variable period
    if !_rc {
        quietly levelsof period, local(per_levels)
        local n_per : word count `per_levels'
        if `n_per' <= 10 {
            noisily tab period, mi
        }
    }
end


net install unicefdata, from("C:\GitHub\myados\unicefData-dev\stata") replace

discard

which unicefdata

help unicefdata

unicefdata, flows
return list
_inspect_current_data

unicefdata, flows detail
return list
_inspect_current_data

unicefdata, dataflow(EDUCATION)
return list
_inspect_current_data

unicefdata, dataflow(CME)
return list
_inspect_current_data

unicefdata, search(mortality)
return list
_inspect_current_data

unicefdata, search(rate) dataflow(CME)
return list
_inspect_current_data

unicefdata, indicators(CME)
return list
_inspect_current_data

unicefdata, info(CME_MRY0T4)
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) year(2010:2023) clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) year(2015,2018,2020) clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) latest clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) sex(F) clear
return list
_inspect_current_data

* SKIP: Bulk download without filters (downloads millions of rows, causes I/O errors)
* Original example: unicefdata, dataflow(CME) countries(ETH) clear verbose
* Note: This example is valid but impractical for automated testing
* Users should add filters: year(), indicator(), or other dimensions
di in yellow "Skipping bulk download example without filters (too large for automated tests)"

* TEST: Bulk download with multiple indicators and filters
* Note: Using multiple indicators instead of indicator(all) for stability
unicefdata, indicator(CME_MRY0T4 CME_MRY0 CME_MRM0) year(2020) clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) mrv(5) clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) simplify dropna clear
return list
_inspect_current_data


unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2018:2021) wide clear
return list
_inspect_current_data


unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) sex(ALL) clear
return list
_inspect_current_data



unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) sex(ALL) wide_attributes clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4 IM_DTP3) countries(USA BRA CHN) year(2020) wide_indicators clear
return list
_inspect_current_data

unicefdata, indicator(NT_ANT_HAZ_NE2) dataflow(NUTRITION) countries(ETH KEN) wealth(ALL) wide_attributes attributes(_Q1 _Q5) clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) clear
return list
_inspect_current_data

unicefdata, indicator(CME_MRY0T4) year(2020) circa clear
return list
_inspect_current_data

unicefdata, indicator(NT_ANT_HAZ_NE2) clear
return list
_inspect_current_data

unicefdata, indicator(NT_ANT_HAZ_NE2) dataflow(NUTRITION) wealth(Q1) clear
return list
_inspect_current_data

unicefdata, indicator(NT_ANT_HAZ_NE2) dataflow(NUTRITION) residence(RURAL) clear
return list
_inspect_current_data

unicefdata, indicator(NT_ANT_HAZ_NE2) dataflow(NUTRITION) residence(RURAL) clear
return list
_inspect_current_data

unicefdata, indicator(IM_DTP3) clear
return list
_inspect_current_data

unicefdata, indicator(IM_MCV1) clear
return list
_inspect_current_data

unicefdata, indicator(WS_PPL_W-B) clear
return list
_inspect_current_data

unicefdata, indicator(WS_PPL_S-B) clear
return list
_inspect_current_data

unicefdata, indicator(ED_ROFST_L1) clear
return list
_inspect_current_data

unicefdata, indicator(ED_ANAR_L1) clear
return list
_inspect_current_data

log close





log using "run-all-unicefdata-wide.log", replace text
 cls
 set trace on
 set tracedepth 1
 unicefdata, indicator(CME_MRY0T4  CME_MRM0  ) clear wide_attributes
log close
 
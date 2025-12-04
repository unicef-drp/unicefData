*******************************************************************************
* unicefdata
*! v 1.0.0   03Dec2025               by Joao Pedro Azevedo (UNICEF)
* Download indicators from UNICEF Data Warehouse via SDMX API
*******************************************************************************

program define unicefdata, rclass

    version 14.0

    syntax                                          ///
                 [,                                 ///
                        INDICATOR(string)           ///
                        DATAFLOW(string)            ///
                        COUNTries(string)           ///
                        STARTyear(integer 0)        ///
                        ENDyear(integer 0)          ///
                        SEX(string)                 ///
                        AGE(string)                 ///
                        WEALTH(string)              ///
                        RESIDENCE(string)           ///
                        MATERNAL_EDU(string)        ///
                        LONG                        ///
                        CLEAR                       ///
                        LATEST                      ///
                        MRV(integer 0)              ///
                        NOMETADATA                  ///
                        RAW                         ///
                        VERSION(string)             ///
                        PAGESIZE(integer 100000)    ///
                        RETRIES(integer 3)          ///
                        VERBOSE                     ///
                 ]

    quietly {

        *-----------------------------------------------------------------------
        * Validate inputs
        *-----------------------------------------------------------------------
        
        if ("`indicator'" == "") & ("`dataflow'" == "") {
            noi di as err "You must specify either indicator() or dataflow(). Please try again."
            exit 198
        }
        
        if ("`clear'" == "") {
            if (_N > 0) {
                noi di as err "You must start with an empty dataset; or enable the clear option."
                exit 4
            }
        }
        
        *-----------------------------------------------------------------------
        * Set defaults
        *-----------------------------------------------------------------------
        
        if ("`sex'" == "") {
            local sex "_T"
        }
        
        if ("`version'" == "") {
            local version "1.0"
        }
        
        local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
        
        *-----------------------------------------------------------------------
        * Auto-detect dataflow from indicator if not specified
        *-----------------------------------------------------------------------
        
        if ("`dataflow'" == "") & ("`indicator'" != "") {
            _unicef_detect_dataflow "`indicator'"
            local dataflow "`s(dataflow)'"
            if ("`verbose'" != "") {
                noi di as text "Auto-detected dataflow: " as result "`dataflow'"
            }
        }
        
        *-----------------------------------------------------------------------
        * Build the API query URL
        *-----------------------------------------------------------------------
        
        * Base path: data/UNICEF,{dataflow},{version}/{indicator_key}
        local indicator_key = cond("`indicator'" != "", "." + "`indicator'" + ".", ".")
        local rel_path "data/UNICEF,`dataflow',`version'/`indicator_key'"
        
        * Query parameters
        local query_params "format=csv&labels=both"
        
        if (`startyear' > 0) {
            local query_params "`query_params'&startPeriod=`startyear'"
        }
        
        if (`endyear' > 0) {
            local query_params "`query_params'&endPeriod=`endyear'"
        }
        
        local query_params "`query_params'&startIndex=0&count=`pagesize'"
        
        * Full URL
        local full_url "`base_url'/`rel_path'?`query_params'"
        
        if ("`verbose'" != "") {
            noi di as text "Fetching from: " as result "`full_url'"
        }
        
        *-----------------------------------------------------------------------
        * Download data
        *-----------------------------------------------------------------------
        
        set checksum off
        
        tempfile tempdata
        
        * Try to copy the file with retries
        local success 0
        forvalues attempt = 1/`retries' {
            capture copy "`full_url'" "`tempdata'", replace public
            if (_rc == 0) {
                local success 1
                continue, break
            }
            if ("`verbose'" != "") {
                noi di as text "Attempt `attempt' failed. Retrying..."
            }
            sleep 1000
        }
        
        if (`success' == 0) {
            noi di ""
            noi di as err "{p 4 4 2}Could not download data from UNICEF SDMX API.{p_end}"
            noi di as text `"{p 4 4 2}(1) Please check your internet connection by {browse "https://data.unicef.org/" :clicking here}.{p_end}"'
            noi di as text `"{p 4 4 2}(2) Please check if the indicator code is correct.{p_end}"'
            noi di as text `"{p 4 4 2}(3) Please check your firewall settings.{p_end}"'
            noi di as text `"{p 4 4 2}(4) Consider adjusting Stata timeout: {help netio}.{p_end}"'
            exit 677
        }
        
        *-----------------------------------------------------------------------
        * Import the CSV data
        *-----------------------------------------------------------------------
        
        import delimited using "`tempdata'", `clear' varnames(1) encoding("utf-8")
        
        local obs_count = _N
        if ("`verbose'" != "") {
            noi di as text "Downloaded " as result `obs_count' as text " observations."
        }
        
        if (`obs_count' == 0) {
            noi di as text "No data found for the specified query."
            exit 0
        }
        
        *-----------------------------------------------------------------------
        * Rename and standardize variables
        * (Aligned with R get_unicef() and Python unicef_api)
        * Using short names with descriptive variable labels
        *-----------------------------------------------------------------------
        
        if ("`raw'" == "") {
            
            * Rename core columns to standardized short names
            * Note: import delimited converts column names to lowercase
            capture rename ref_area iso3
            capture rename indicator indicator
            capture rename time_period period
            capture rename obs_value value
            capture rename geographicarea country
            
            * Rename descriptive columns (from API's "label" columns)
            * API returns pairs like INDICATOR/Indicator - Stata creates v4, v6 for duplicates
            capture rename v4 indicator_name
            capture rename unitofmeasure unit_name
            capture rename v6 sex_name
            capture rename wealthquintile wealth_name
            capture rename observationstatus status_name
            
            * Rename additional metadata columns (lowercase after import delimited)
            capture rename unit_measure unit
            capture rename wealth_quintile wealth
            capture rename lower_bound lb
            capture rename upper_bound ub
            capture rename obs_status status
            capture rename data_source source
            capture rename ref_period refper
            capture rename country_notes notes
            capture rename maternal_edu_lvl matedu
            
            * Add descriptive variable labels
            capture label variable iso3       "ISO3 country code"
            capture label variable country    "Country name"
            capture label variable indicator  "Indicator code"
            capture label variable indicator_name "Indicator name"
            capture label variable period     "Time period (year)"
            capture label variable value      "Observation value"
            capture label variable unit       "Unit of measure code"
            capture label variable unit_name  "Unit of measure"
            capture label variable sex        "Sex code"
            capture label variable sex_name   "Sex"
            capture label variable age        "Age group"
            capture label variable wealth     "Wealth quintile code"
            capture label variable wealth_name "Wealth quintile"
            capture label variable residence  "Residence type"
            capture label variable matedu     "Maternal education level"
            capture label variable lb         "Lower confidence bound"
            capture label variable ub         "Upper confidence bound"
            capture label variable status     "Observation status code"
            capture label variable status_name "Observation status"
            capture label variable source     "Data source"
            capture label variable refper     "Reference period"
            capture label variable notes      "Country notes"
            
            * Convert period to numeric (handle YYYY-MM format)
            capture {
                * Check if period contains "-" (YYYY-MM format)
                gen _has_month = strpos(period, "-") > 0
                gen _year = real(substr(period, 1, 4))
                gen _month = real(substr(period, 6, 2)) if _has_month == 1
                replace _month = 0 if _has_month == 0
                gen period_num = _year + _month/12
                drop period _has_month _year _month
                rename period_num period
                label variable period "Time period (year)"
            }
            
            * If the above fails, try simple numeric conversion
            capture {
                destring period, replace force
            }
            
            * Convert value to numeric
            capture {
                destring value, replace force
            }
            
            * Convert bounds to numeric
            capture destring lb, replace force
            capture destring ub, replace force
            
            * Filter by sex if specified
            if ("`sex'" != "" & "`sex'" != "ALL") {
                capture confirm variable sex
                if (_rc == 0) {
                    keep if sex == "`sex'"
                }
            }
            
            * Filter by age if specified
            if ("`age'" != "" & "`age'" != "ALL") {
                capture confirm variable age
                if (_rc == 0) {
                    keep if age == "`age'"
                }
            }
            
            * Filter by wealth quintile if specified
            if ("`wealth'" != "" & "`wealth'" != "ALL") {
                capture confirm variable wealth
                if (_rc == 0) {
                    keep if wealth == "`wealth'"
                }
            }
            
            * Filter by residence if specified
            if ("`residence'" != "" & "`residence'" != "ALL") {
                capture confirm variable residence
                if (_rc == 0) {
                    keep if residence == "`residence'"
                }
            }
            
            * Filter by maternal education if specified
            if ("`maternal_edu'" != "" & "`maternal_edu'" != "ALL") {
                capture confirm variable matedu
                if (_rc == 0) {
                    keep if matedu == "`maternal_edu'"
                }
            }
            
        }
        
        *-----------------------------------------------------------------------
        * Filter countries if specified
        *-----------------------------------------------------------------------
        
        if ("`countries'" != "") {
            capture confirm variable iso3
            if (_rc == 0) {
                local countries_upper = upper("`countries'")
                local countries_clean = subinstr("`countries_upper'", ",", " ", .)
                gen _keep = 0
                foreach c of local countries_clean {
                    replace _keep = 1 if iso3 == "`c'"
                }
                keep if _keep == 1
                drop _keep
            }
        }
        
        *-----------------------------------------------------------------------
        * Apply latest value filter
        *-----------------------------------------------------------------------
        
        if ("`latest'" != "") {
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable value
            if (_rc == 0) {
                * Keep only non-missing values
                drop if missing(value)
                
                * Get latest period for each country-indicator
                capture confirm variable indicator
                if (_rc == 0) {
                    bysort iso3 indicator (period): keep if _n == _N
                }
                else {
                    bysort iso3 (period): keep if _n == _N
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Apply MRV (Most Recent Values) filter
        *-----------------------------------------------------------------------
        
        if (`mrv' > 0) {
            capture confirm variable iso3
            capture confirm variable period
            if (_rc == 0) {
                capture confirm variable indicator
                if (_rc == 0) {
                    gsort iso3 indicator -period
                    by iso3 indicator: gen _rank = _n
                    keep if _rank <= `mrv'
                    drop _rank
                    sort iso3 indicator period
                }
                else {
                    gsort iso3 -period
                    by iso3: gen _rank = _n
                    keep if _rank <= `mrv'
                    drop _rank
                    sort iso3 period
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Reshape to long format if requested
        *-----------------------------------------------------------------------
        
        if ("`long'" != "") {
            * Data is already in long format from SDMX CSV
            * This option is for compatibility with wbopendata
            sort iso3 period
        }
        
        *-----------------------------------------------------------------------
        * Return values
        *-----------------------------------------------------------------------
        
        return local indicator "`indicator'"
        return local dataflow "`dataflow'"
        return local countries "`countries'"
        return local startyear "`startyear'"
        return local endyear "`endyear'"
        return local obs_count = _N
        return local url "`full_url'"
        
        if ("`verbose'" != "") {
            noi di ""
            noi di as text "Successfully loaded " as result _N as text " observations."
            noi di as text "Indicator: " as result "`indicator'"
            noi di as text "Dataflow:  " as result "`dataflow'"
        }
        
    }

end


*******************************************************************************
* Helper program: Auto-detect dataflow from indicator code
*******************************************************************************

program define _unicef_detect_dataflow, sclass
    args indicator
    
    * Extract prefix from indicator (first part before underscore)
    local prefix = word(subinstr("`indicator'", "_", " ", 1), 1)
    
    * Known indicator-to-dataflow mappings
    if ("`prefix'" == "CME") {
        sreturn local dataflow "CME"
    }
    else if ("`prefix'" == "NT") {
        sreturn local dataflow "NUTRITION"
    }
    else if ("`prefix'" == "IM") {
        sreturn local dataflow "IMMUNISATION"
    }
    else if ("`prefix'" == "ED") {
        sreturn local dataflow "EDUCATION"
    }
    else if ("`prefix'" == "WS") {
        sreturn local dataflow "WASH_HOUSEHOLDS"
    }
    else if ("`prefix'" == "HVA") {
        sreturn local dataflow "HIV_AIDS"
    }
    else if ("`prefix'" == "MNCH") {
        sreturn local dataflow "MNCH"
    }
    else if ("`prefix'" == "PT") {
        sreturn local dataflow "PT"
    }
    else if ("`prefix'" == "ECD") {
        sreturn local dataflow "ECD"
    }
    else if ("`prefix'" == "PV") {
        sreturn local dataflow "CHLD_PVTY"
    }
    else {
        * Default to GLOBAL_DATAFLOW if unknown
        sreturn local dataflow "GLOBAL_DATAFLOW"
    }
    
end

*******************************************************************************
* Version history
*******************************************************************************
* v 1.0.0   03Dec2025   by Joao Pedro Azevedo
*   Initial release
*   - Download UNICEF SDMX data via API
*   - Support for indicator and dataflow selection
*   - Country filtering
*   - Year range filtering
*   - Disaggregation filters (sex, age, wealth, residence, maternal education)
*   - Latest value and MRV options
*   - Auto-detect dataflow from indicator prefix
*******************************************************************************

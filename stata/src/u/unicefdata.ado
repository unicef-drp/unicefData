*******************************************************************************
* unicefdata
*! v 1.2.1   07Dec2025               by Joao Pedro Azevedo (UNICEF)
* Download indicators from UNICEF Data Warehouse via SDMX API
* Aligned with R get_unicef() and Python unicef_api
* Uses YAML metadata for dataflow detection and validation
*******************************************************************************

program define unicefdata, rclass

    version 14.0

    syntax                                          ///
                 [,                                 ///
                        INDICATOR(string)           /// Indicator code(s)
                        DATAFLOW(string)            /// SDMX dataflow ID
                        COUNTries(string)           /// ISO3 country codes
                        START_year(integer 0)       /// Start year (R/Python aligned)
                        END_year(integer 0)         /// End year (R/Python aligned)
                        SEX(string)                 /// Sex: _T, F, M, ALL
                        AGE(string)                 /// Age group filter
                        WEALTH(string)              /// Wealth quintile filter
                        RESIDENCE(string)           /// Residence: URBAN, RURAL
                        MATERNAL_edu(string)        /// Maternal education filter
                        LONG                        /// Long format (default)
                        WIDE                        /// Wide format
                        LATEST                      /// Most recent value only
                        MRV(integer 0)              /// N most recent values
                        DROPNA                      /// Drop missing values
                        SIMPLIFY                    /// Essential columns only
                        RAW                         /// Raw SDMX output
                        VERSION(string)             /// SDMX version
                        PAGE_size(integer 100000)   /// Rows per request
                        MAX_retries(integer 3)      /// Retry attempts
                        CLEAR                       /// Replace data in memory
                        VERBOSE                     /// Show progress
                        VALIDATE                    /// Validate inputs against codelists
                        *                           /// Legacy options
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
        * Locate metadata directory
        *-----------------------------------------------------------------------
        
        * Find the package installation path
        local metadata_path ""
        
        * Try to find metadata relative to this ado file
        findfile unicefdata.ado
        if (_rc == 0) {
            local ado_path "`r(fn)'"
            * Extract directory (go up from src/u/ to find metadata/)
            local ado_dir = subinstr("`ado_path'", "src/u/unicefdata.ado", "", .)
            local ado_dir = subinstr("`ado_dir'", "src\u\unicefdata.ado", "", .)
            local metadata_path "`ado_dir'metadata/"
        }
        
        * If not found, try PLUS directory
        if ("`metadata_path'" == "") | (!fileexists("`metadata_path'indicators.yaml")) {
            local metadata_path "`c(sysdir_plus)'u/metadata/"
        }
        
        if ("`verbose'" != "") {
            noi di as text "Metadata path: " as result "`metadata_path'"
        }
        
        *-----------------------------------------------------------------------
        * Auto-detect dataflow from indicator using YAML metadata
        *-----------------------------------------------------------------------
        
        if ("`dataflow'" == "") & ("`indicator'" != "") {
            _unicef_detect_dataflow_yaml "`indicator'" "`metadata_path'"
            local dataflow "`s(dataflow)'"
            local indicator_name "`s(indicator_name)'"
            if ("`verbose'" != "") {
                noi di as text "Auto-detected dataflow: " as result "`dataflow'"
                if ("`indicator_name'" != "") {
                    noi di as text "Indicator: " as result "`indicator_name'"
                }
            }
        }
        
        *-----------------------------------------------------------------------
        * Validate disaggregation filters against codelists (if requested)
        *-----------------------------------------------------------------------
        
        if ("`validate'" != "") {
            _unicef_validate_filters "`sex'" "`age'" "`wealth'" "`residence'" "`maternal_edu'" "`metadata_path'"
        }
        
        *-----------------------------------------------------------------------
        * Build the API query URL
        *-----------------------------------------------------------------------
        
        * Base path: data/UNICEF,{dataflow},{version}/{indicator_key}
        local indicator_key = cond("`indicator'" != "", "." + "`indicator'" + ".", ".")
        local rel_path "data/UNICEF,`dataflow',`version'/`indicator_key'"
        
        * Query parameters
        local query_params "format=csv&labels=both"
        
        if (`start_year' > 0) {
            local query_params "`query_params'&startPeriod=`start_year'"
        }
        
        if (`end_year' > 0) {
            local query_params "`query_params'&endPeriod=`end_year'"
        }
        
        local query_params "`query_params'&startIndex=0&count=`page_size'"
        
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
        forvalues attempt = 1/`max_retries' {
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
        * Apply dropna filter (aligned with R/Python)
        *-----------------------------------------------------------------------
        
        if ("`dropna'" != "") {
            capture confirm variable value
            if (_rc == 0) {
                drop if missing(value)
            }
        }
        
        *-----------------------------------------------------------------------
        * Format output (long/wide) - aligned with R/Python
        *-----------------------------------------------------------------------
        
        if ("`wide'" != "") {
            * Reshape to wide format
            capture confirm variable iso3
            capture confirm variable period
            capture confirm variable indicator
            capture confirm variable value
            if (_rc == 0) {
                keep iso3 country period indicator value
                capture reshape wide value, i(iso3 country period) j(indicator) string
                if (_rc != 0) {
                    noi di as text "Note: Could not reshape to wide format."
                }
            }
        }
        else {
            * Data is already in long format from SDMX CSV (default)
            sort iso3 period
        }
        
        *-----------------------------------------------------------------------
        * Simplify output (aligned with R/Python) - keep essential columns only
        *-----------------------------------------------------------------------
        
        if ("`simplify'" != "") {
            * Keep only essential columns like R's simplify option
            local keepvars ""
            foreach v in iso3 country indicator period value lb ub {
                capture confirm variable `v'
                if (_rc == 0) {
                    local keepvars "`keepvars' `v'"
                }
            }
            if ("`keepvars'" != "") {
                keep `keepvars'
            }
        }
        
        *-----------------------------------------------------------------------
        * Return values
        *-----------------------------------------------------------------------
        
        return local indicator "`indicator'"
        return local dataflow "`dataflow'"
        return local countries "`countries'"
        return local start_year "`start_year'"
        return local end_year "`end_year'"
        return local wide "`wide'"
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
* Helper program: Auto-detect dataflow from indicator code using YAML metadata
*******************************************************************************

program define _unicef_detect_dataflow_yaml, sclass
    args indicator metadata_path
    
    local dataflow ""
    local indicator_name ""
    
    * Try to load from YAML metadata first
    local yaml_file "`metadata_path'indicators.yaml"
    
    capture confirm file "`yaml_file'"
    if (_rc == 0) {
        * YAML file exists - try to read it using yaml command
        capture which yaml
        if (_rc == 0) {
            * yaml command is available
            preserve
            capture {
                yaml read "`yaml_file'", into(indicators_meta) clear
                
                * Look for indicator in the indicators mapping
                local indicator_clean = subinstr("`indicator'", "-", "_", .)
                
                * Try to get dataflow from YAML
                capture local dataflow = indicators_meta["indicators"]["`indicator'"]["dataflow"]
                capture local indicator_name = indicators_meta["indicators"]["`indicator'"]["name"]
            }
            restore
            
            if ("`dataflow'" != "") {
                sreturn local dataflow "`dataflow'"
                sreturn local indicator_name "`indicator_name'"
                exit
            }
        }
    }
    
    * Fallback to prefix-based detection if YAML not available or indicator not found
    _unicef_detect_dataflow_prefix "`indicator'"
    sreturn local dataflow "`s(dataflow)'"
    sreturn local indicator_name ""
    
end


*******************************************************************************
* Helper program: Fallback prefix-based dataflow detection
*******************************************************************************

program define _unicef_detect_dataflow_prefix, sclass
    args indicator
    
    * Extract prefix from indicator (first part before underscore)
    local prefix = word(subinstr("`indicator'", "_", " ", 1), 1)
    
    * Known indicator-to-dataflow mappings (aligned with R/Python)
    if ("`prefix'" == "CME") {
        sreturn local dataflow "CME"
    }
    else if ("`prefix'" == "NT") {
        sreturn local dataflow "NUTRITION"
    }
    else if ("`prefix'" == "IM") {
        sreturn local dataflow "IMMUNISATION"
    }
    else if inlist("`prefix'", "ED", "EDUNF") {
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
    else if ("`prefix'" == "CCRI") {
        sreturn local dataflow "CCRI"
    }
    else if ("`prefix'" == "SDG") {
        sreturn local dataflow "CHILD_RELATED_SDG"
    }
    else {
        * Default to GLOBAL_DATAFLOW if unknown
        sreturn local dataflow "GLOBAL_DATAFLOW"
    }
    
end


*******************************************************************************
* Helper program: Validate disaggregation filters against YAML codelists
*******************************************************************************

program define _unicef_validate_filters, sclass
    args sex age wealth residence maternal_edu metadata_path
    
    local yaml_file "`metadata_path'codelists.yaml"
    local warnings ""
    
    capture confirm file "`yaml_file'"
    if (_rc != 0) {
        * YAML file not found - skip validation
        exit
    }
    
    capture which yaml
    if (_rc != 0) {
        * yaml command not available - skip validation
        exit
    }
    
    * Validate sex
    if ("`sex'" != "" & "`sex'" != "ALL") {
        if !inlist("`sex'", "_T", "F", "M") {
            noi di as text "Warning: sex value '`sex'' may not be valid. Expected: _T, F, M"
        }
    }
    
    * Validate wealth
    if ("`wealth'" != "" & "`wealth'" != "ALL") {
        if !inlist("`wealth'", "_T", "Q1", "Q2", "Q3", "Q4", "Q5") {
            noi di as text "Warning: wealth value '`wealth'' may not be valid. Expected: _T, Q1-Q5"
        }
    }
    
    * Validate residence
    if ("`residence'" != "" & "`residence'" != "ALL") {
        if !inlist("`residence'", "_T", "U", "R", "URBAN", "RURAL") {
            noi di as text "Warning: residence value '`residence'' may not be valid. Expected: _T, U, R"
        }
    }
    
end


*******************************************************************************
* Helper program: Legacy fallback (deprecated, kept for compatibility)
*******************************************************************************

program define _unicef_detect_dataflow, sclass
    args indicator
    
    * Call the new prefix-based detection
    _unicef_detect_dataflow_prefix "`indicator'"
    sreturn local dataflow "`s(dataflow)'"
    
end


*******************************************************************************
* Version history
*******************************************************************************
* v 1.2.0   04Dec2025   by Joao Pedro Azevedo
*   YAML-based metadata loading (aligned with R/Python)
*   - Added stata/metadata/*.yaml files for indicators, codelists, dataflows
*   - Auto-detect dataflow from YAML indicators.yaml
*   - Added validate option for codelist validation
*   - Uses yaml.ado for metadata parsing (with prefix fallback)
*
* v 1.1.0   04Dec2025   by Joao Pedro Azevedo
*   API alignment with R get_unicef() and Python unicef_api
*   - Renamed options: start_year, end_year, max_retries, page_size
*   - Added long/wide options for output format
*   - Added dropna option to drop missing values
*   - Added simplify option to keep essential columns only
*   - Backward compatible with legacy option syntax
*
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

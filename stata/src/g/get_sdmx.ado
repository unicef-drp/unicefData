*! version 1.3.3  20Jan2026
*! Get SDMX data from any agency
*! Description: Low-level function to fetch SDMX data or structure from any agency
*! Author: João Pedro Azevedo (https://jpazvd.github.io)
*! License: MIT
*!
*! NEW in v1.3.3:
*! - Wide format now reorders variables: context/dimension columns before year columns
*!
*! NEW in v1.3.0:
*! - Added bulk download support: indicator(all) fetches entire dataflow
*! - Filters (countries, year, disaggregations) still work with bulk mode
*! - Performance: ~3-10x faster for multiple indicators from same dataflow
*!
*! NEW in v1.2.0:
*! - Added filename() parameter for flexible data handling
*!   - When specified: saves CSV to that file, caller handles import
*!   - When omitted: creates tempfile, loads data directly into memory
*!
*! NEW in v1.1.0:
*! - Integrated intelligent query filter engine (__unicef_get_indicator_filters)
*! - Query mode detection (auto-detect, bypass, validation)
*! - Automatic dimension extraction from dataflow schemas
*! - Enhanced verbose output showing query mode and dimensions

/*
GET_SDMX - Fetch SDMX Data or Structure
========================================

Purpose:
--------
Low-level function for downloading SDMX data from any agency (UNICEF, World Bank, etc.)
with paging, retries, caching, and post-processing options.
Supports both auto-detection and manual dataflow specification.

Syntax:
-------
get_sdmx, indicator(string) [agency(string) dataflow(string) filter(string) ///
          detail(string) format(string) labels(string) start_period(string) ///
          end_period(string) nofilter retry(integer) cache country_names verbose]

Parameters:
-----------
indicator:  Indicator code(s) or "all" for bulk download. Required.
            Examples: SP.POP.TOTL, NY.GDP.MKTP.CD, CME
            Special: "all" = fetch entire dataflow (bulk download mode)
                     Filters (countries, year, disaggregations) still apply
                     Performance: ~3-10x faster than multiple individual requests

agency:     SDMX agency ID. Default: UNICEF
            Other options: WB (World Bank), WHO, IMF, etc.
            Note: Ignored if dataflow() is specified.

dataflow:   Manual dataflow ID (format: AGENCY.DATAFLOW_CODE).
            Optional. If specified, bypasses auto-detection.
            Examples: UNICEF.CME, WB.SP.POP.TOTL
            Default: empty (auto-detect from agency+indicator)

country:    ISO3 country code(s) to filter. Optional.
            Format: Single code ("BRA") or plus-separated list ("BRA+MEX+ARG")
            Special: "all" or "" (empty) = fetch all countries
            Example: "BRA" fetches only Brazil data; "DZA+GAB+LAO" mirrors the
            SDMX path fragment in /data/.../DZA+GAB+LAO.INDICATOR...
            Default: empty (fetch all countries)

filter:     Dimension filter vector (space-separated values).
            Format: "sex_val age_val wealth_val residence_val maternal_edu_val"
            Example: "_T Y0T4 Q1 _T _T" 
            Used by unicefdata wrapper to build efficient URLs.
            Tokens may include '+' to request multiple members within a dimension
            (e.g., "M12T13+M18T19+M20T21" for age groups).
            To leave a dimension blank (double-dot in the URL, e.g., all ages),
            insert a double space between adjacent tokens so it remains empty
            after space→dot substitution.
            Default: empty (uses nofilter behavior if specified)

filtervector:  Pre-constructed SDMX filter key (alternative to filter()).
            Format: Complete SDMX REST key fragment (e.g., ".INDICATOR..M")
            Example: ".CME_MRY0T4.USA..M" or ".CME_MRY0T4...."
            Used for advanced/custom filtering without dimension parsing.
            Cannot be used simultaneously with filter() option.
            Typically called by unicefdata when user specifies filtervector()
            directly.
            Default: empty (use filter() instead)

detail:     Query detail level. Default: data
            Options: data, structure

format:     API response format. Default: csv
            Options: csv, sdmx-xml, sdmx-json, sdmx-compact-2.1

labels:     Column labels format. Default: id
            Options: both, id, none

year:       Year(s) to filter. Optional. Overrides start_period/end_period if specified.
            Format: Single year ("2015"), range ("2015:2023"), or list ("2015,2018,2020")
            Examples: 
              year(2020)         - Single year
              year(2015:2023)    - Range from 2015 to 2023
              year(2015,2018,2020) - Specific years (fetches 2015-2020, filters post-download)

start_period:   Start year (4-digit). Optional.
                Ignored if year() is specified.

end_period:     End year (4-digit). Optional.
                Ignored if year() is specified.

filename:   File path for saving downloaded CSV. Optional.
            When specified: saves API response to this file, skips loading.
            When omitted: creates tempfile, loads data directly into memory.
            Returns r(datafile) with the file path when filename() is used.
            Example: filename("C:/temp/data.csv")

nofilter:   If specified, fetch all disaggregations (slow)
            Default: efficient filtering (totals only)

retry:      Number of retry attempts on failure. Default: 3

cache:      If specified, enable schema caching for speed

country_names:  If specified, add country name column (default: on)

verbose:    If specified, display progress messages

debug:      If specified, display maximum debugging information including:
            - System network configuration
            - Full URL details and connection info
            - Detailed error codes and error explanations
            - API response preview (first 100 chars)
            - Network diagnostics (connectivity check)
            - Netio timeout settings

trace:      If specified, enable Stata trace on network call
            Use with set tracedepth 1 for deeper inspection
            (Usually combined with debug for maximum detail)

Examples:
---------
* Fetch population data (auto-detect dataflow)
get_sdmx, indicator(SP.POP.TOTL) agency(UNICEF)

* Fetch with manual dataflow specification (bypass auto-detection)
get_sdmx, indicator(CME) dataflow(UNICEF.CME)

* BULK DOWNLOAD: Fetch entire dataflow with filters
get_sdmx, indicator(all) dataflow(UNICEF.CME) countries(ETH)
get_sdmx, indicator(all) dataflow(UNICEF.NUTRITION) year(2020:2023)

* Fetch multiple indicators with caching
get_sdmx, indicator(SP.POP.TOTL NY.GDP.MKTP.CD) cache

* Fetch with time period and verbose output
get_sdmx, indicator(CME) start_period(2015) end_period(2023) verbose

* View structure/schema with manual dataflow
get_sdmx, indicator(CME) dataflow(UNICEF.CME) detail(structure)

Returns:
--------
Data in memory as dataset with columns:
  - indicator:  Indicator code
  - iso3:       ISO3 country code
  - country:    Country name
  - period:     Time period (year)
  - value:      Observation value
  - unit:       Unit code
  - unit_name:  Unit name
  - source:     Data source

Performance:
------------
With caching enabled, subsequent calls from same dataflow are 8-17x faster.
First call: ~2.2 seconds (API + schema fetch)
Cached call: ~0.13 seconds (memory lookup only)
*/

program define get_sdmx, rclass
  version 11
  
  syntax, INDicator(string) ///
          [AGency(string) ///
           DATAflow(string) ///
           COUntries(string) ///
           FILTERvector(string) ///
           FILter(string) ///
           DETail(string) ///
           FORmat(string) ///
           LABels(string) ///
           YEAR(string) ///
           Start_period(string) ///
           End_period(string) ///
           FILEname(string) ///
           WIDE ///
           CLEar ///
           NOFilter ///
           RETry(integer 3) ///
           CAChe ///
           COUNtry_names ///
           VERbose ///
           DEBUG ///
           TRACE]
  
  * Validate: cannot specify both filtervector() and filter() option
  if ("`filtervector'" != "" & "`filter'" != "") {
      noi di as error "Cannot specify both {bf:filtervector()} and {bf:filter()}"
      noi di as text ""
      noi di as text "{bf:Choose one:}"
      noi di as text "  {bf:filtervector(string)}: Pre-constructed SDMX filter key (e.g., {bf:.INDICATOR..M})"
      noi di as text "  {bf:filter(string)}: Space-separated dimension values (e.g., {bf:_T Y0T4 Q1})"
      noi di as text ""
      error 198
  }
  
  * Use filtervector if provided, otherwise use filter
  if ("`filtervector'" != "") {
      local filter = "`filtervector'"
  }
  
  // Set defaults
  if "`agency'" == "" local agency "UNICEF"
  if "`detail'" == "" local detail "data"
  if "`format'" == "" local format "csv"
  if "`labels'" == "" local labels "id"
  if "`country_names'" == "" local country_names "yes"
  
  // If wide option specified, override format to csv-ts (time series transposed)
  if ("`wide'" != "") {
    local format "csv-ts"
    if "`verbose'" != "" {
      display as text "    Wide format requested: using csv-ts API format"
      display as text "    Output will have years as columns (yr####)"
    }
  }
  
  // Parse year() option if provided (overrides start_period/end_period)
  // Supports: single (2020), range (2015:2023), list (2015,2018,2020)
  if ("`year'" != "") {
    // Check for range format: 2015:2023
    if (strpos("`year'", ":") > 0) {
      local colon_pos = strpos("`year'", ":")
      local start_period = real(substr("`year'", 1, `colon_pos' - 1))
      local end_period = real(substr("`year'", `colon_pos' + 1, .))
      if "`verbose'" != "" {
        display as text "    Year range: `start_period' to `end_period'"
      }
    }
    // Check for list format: 2015,2018,2020 (use min/max as range)
    else if (strpos("`year'", ",") > 0) {
      local year_list = subinstr("`year'", ",", " ", .)
      local min_year = 9999
      local max_year = 0
      foreach yr of local year_list {
        local yr_num = real("`yr'")
        if (`yr_num' < `min_year') local min_year = `yr_num'
        if (`yr_num' > `max_year') local max_year = `yr_num'
      }
      local start_period = `min_year'
      local end_period = `max_year'
      if "`verbose'" != "" {
        display as text "    Year list: `year_list'"
        display as text "    Query range: `min_year' to `max_year'"
      }
    }
    // Single year
    else {
      local start_period = real("`year'")
      local end_period = `start_period'
      if "`verbose'" != "" {
        display as text "    Single year: `start_period'"
      }
    }
  }
  
  // Parse manual dataflow if provided (format: AGENCY.DATAFLOW_CODE)
  local manual_dataflow ""
  if "`dataflow'" != "" {
    local manual_dataflow "`dataflow'"
    // Extract AGENCY from format: AGENCY.CODE
    if ustrregexm("`dataflow'", "^([A-Z0-9]+)\.(.+)$") {
      local extracted_agency = ustrregexs(1)
      if "`extracted_agency'" != "" {
        local agency "`extracted_agency'"
        if "`verbose'" != "" {
          noi di as text "    Dataflow: `manual_dataflow' (manual specification, agency extracted: `agency')"
        }
      }
    }
  }
  
  // Validate parameters
  local detail_valid 0
  foreach d in data structure {
    if "`detail'" == "`d'" local detail_valid 1
  }
  if !`detail_valid' {
    display as error "detail() must be 'data' or 'structure'"
    error 198
  }
  
  local format_valid 0
  foreach f in csv csv-ts sdmx-xml sdmx-json sdmx-compact-2.1 {
    if "`format'" == "`f'" local format_valid 1
  }
  if !`format_valid' {
    display as error "format() must be 'csv', 'csv-ts', 'sdmx-xml', 'sdmx-json', or 'sdmx-compact-2.1'"
    error 198
  }
  
  local labels_valid 0
  foreach l in id both none {
    if "`labels'" == "`l'" local labels_valid 1
  }
  if !`labels_valid' {
    display as error "labels() must be 'id', 'both', or 'none'"
    error 198
  }
  
  // If debug mode, set verbose automatically
  if "`debug'" != "" {
    local verbose "verbose"
  }
  
  // Validate years
  if "`start_period'" != "" {
    if !ustrregexm("`start_period'", "^[0-9]{4}$") {
      display as error "start_period() must be a 4-digit year"
      error 198
    }
  }
  
  if "`end_period'" != "" {
    if !ustrregexm("`end_period'", "^[0-9]{4}$") {
      display as error "end_period() must be a 4-digit year"
      error 198
    }
  }
  
  if "`verbose'" != "" {
    display as text "(get_sdmx) Fetching `indicator' from `agency'..."
    display as text "  Agency: `agency'"
    display as text "  Detail: `detail'"
    display as text "  Format: `format'"
    display as text "  Labels: `labels'"
    if "`start_period'" != "" display as text "  Start: `start_period'"
    if "`end_period'" != "" display as text "  End: `end_period'"
    if "`cache'" != "" display as text "  Caching: enabled"
    if "`debug'" != "" display as text "  DEBUG MODE: enabled (max verbosity)"
  }
  
  // System diagnostics for debug mode
  if "`debug'" != "" {
    display as text ""
    display as text "=== SYSTEM DIAGNOSTICS ==="
    display as text "Stata version: `c(stata_version)'"
    display as text "OS: `c(os)'"
    display as text "Machine: `c(machine_type)'"
    display as text "Current directory: `c(pwd)'"
    
    // Try to detect network connectivity
    capture noisily {
      // This is a basic connectivity check using a public API
      tempfile connectivity_test
      capture copy "https://www.google.com" "`connectivity_test'", replace public
      if _rc == 0 {
        display as result "  Network status: OK (can reach public internet)"
      }
      else {
        display as error "  Network status: BLOCKED or OFFLINE (cannot reach public internet)"
        display as error "    Error code: `_rc'"
      }
    }
    display as text ""
  }
  
  // QUERY MODE DETERMINATION & DIMENSION EXTRACTION
  // ================================================
  // Three modes:
  //   1. AUTO-DETECT: User provides indicator only; system auto-detects dataflow
  //   2. BYPASS: User provides indicator+dataflow; skip auto-detection
  //   3. VALIDATION: Extract dimension metadata for filter validation
  
  local query_mode ""
  local dataflow_for_query ""
  
  if "`manual_dataflow'" != "" {
    // Mode 2: BYPASS (user specified dataflow explicitly)
    local query_mode "bypass"
    local dataflow_for_query = word("`manual_dataflow'", 1)
    if "`verbose'" != "" {
      display as text "  Query mode: BYPASS (user specified dataflow)"
      display as text "  Dataflow: `dataflow_for_query'"
    }
  }
  else {
    // Mode 1: AUTO-DETECT (default) - indicator only
    // For UNICEF, the indicator code IS often the dataflow code (CME, CDD, etc.)
    local first_indicator = word("`indicator'", 1)
    local dataflow_for_query "`first_indicator'"
    local query_mode "auto-detect"
    if "`verbose'" != "" {
      display as text "  Query mode: AUTO-DETECT"
      display as text "  Using indicator as dataflow: `dataflow_for_query'"
    }
  }
  
  // Mode 3: VALIDATION - Try to extract dimension metadata for filter validation
  // This is optional and non-fatal if dimensions can't be extracted
  // Always attempt dimension extraction so we can pad empty dimensions when nofilter is used
  capture noisily {
    __unicef_get_indicator_filters, dataflow("`dataflow_for_query'") ///
                                   `verbose'
    if _rc == 0 {
      local dimensions_extracted = r(dimensions)
      local num_dimensions = r(num_dimensions)
      if "`verbose'" != "" {
        display as text "  ✓ Dimension metadata: `num_dimensions' dimensions found"
        display as text "    Available dimensions: `dimensions_extracted'"
      }
    }
  }
  if _rc != 0 & "`verbose'" != "" {
    display as text "  (Dimension extraction skipped or not available)"
  }
  
  // Try to use schema cache if enabled
  if "`cache'" != "" {
    capture unicef_cache_get, indicator(`indicator') local(cached_schema)
    if _rc == 0 {
      if "`verbose'" != "" display as result "✓ Using cached schema for `indicator'"
    }
  }
  
  // Build API URL
  local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
  
  // Handle different detail types
  if "`detail'" == "structure" {
    local url "`base_url'/structure/dataflow/`agency'.`indicator'?references=all&detail=full"
  }
  else {
    // Build country filter (reference area dimension). Accept plus-separated lists (e.g., DZA+GAB+LAO).
    // SDMX URL format: /REF_AREA.INDICATOR.DIM1.DIM2...
    // When REF_AREA is empty (all countries), we get /.INDICATOR.DIM1... (dot separators)
    // Empty string for REF_AREA = all countries (SDMX-REST standard)
    local country_key ""
    if "`countries'" != "" & "`countries'" != "all" {
      // User specified country codes - use them directly
      local country_key "`countries'"
    }
    
    // Build data key for filtering (indicator + dimensions)
    // Format: .INDICATOR.DIM1.DIM2... (leading dot is separator after REF_AREA)
    // Special case: indicator(all) requests entire dataflow
    if "`indicator'" == "all" {
      // Bulk download mode: request ALL indicators from dataflow
      // SDMX pattern depends on whether countries are specified:
      //   No countries:   /all?                (fetch ALL countries + ALL indicators)
      //   With countries: /ETH...?             (fetch ETH + ALL indicators, dots for dimensions)
      if "`country_key'" == "" {
        // No countries specified - use "all" for both country and indicator
        local key_suffix "all"
        if "`verbose'" != "" {
          display as text "  ✓ Bulk download mode: fetching ALL countries + ALL indicators"
        }
      }
      else {
        // Countries specified - use dots for empty indicator and dimension positions
        // Determine number of dots needed (2+ for typical dataflows: indicator + dimensions)
        local num_dots = 3  // Default: ... (indicator + 2 dimensions)
        if "`num_dimensions'" != "" {
          // If we know dimension count, use exact number of dots
          local num_dots = `num_dimensions'
        }
        local key_suffix "."
        forvalues i = 1/`num_dots' {
          local key_suffix "`key_suffix'."
        }
        if "`verbose'" != "" {
          display as text "  ✓ Bulk download mode: fetching country `country_key' + ALL indicators"
        }
      }
    }
    else if "`filter'" != "" {
      // Use explicit filter vector from wrapper; it should ALREADY contain indicator + dimensions
      // Example from unicefdata: ".CME_MRY0T4._T._T._T._T"
      // Do NOT add indicator again - just use the filter as-is
      local key_suffix "`filter'"
    }
    else if "`nofilter'" == "" {
      // Efficient filtering: explicit totals across all known dimensions
      // If dimension metadata is available, apply _T to each dimension; otherwise apply one _T
      local key_suffix ".`indicator'"
      if "`num_dimensions'" != "" {
        forvalues i = 1/`num_dimensions' {
          local key_suffix "`key_suffix'._T"
        }
        if "`verbose'" != "" {
          display as text "  ✓ Totals filter: applied _T to `num_dimensions' dimensions"
        }
      }
      else {
        // Fallback: apply a single _T when dimension count is unknown
        local key_suffix "`key_suffix'._T"
      }
    }
    else {
      // No filter: request with no dimension slices; if we know dimension count, pad with dots
      local key_suffix ".`indicator'"
      if "`num_dimensions'" != "" {
        local dotpad ""
        forvalues i = 1/`num_dimensions' {
          local dotpad "`dotpad'."
        }
        local key_suffix "`key_suffix'`dotpad'"
      }
    }
    
    // Align with Python/R: build /data/AGENCY,DATAFLOW,VERSION/COUNTRY.KEY
    // Parse dataflow components and ensure a version is present
    local df_agency "`agency'"
    local df_version "`version'"
    local df_flow ""
    
    if "`manual_dataflow'" != "" {
      // Extract first dataflow if multiple provided
      local df_flow = word("`manual_dataflow'", 1)
      // If provided as AGENCY.FLOW, split components
      local dotpos = strpos("`df_flow'", ".")
      if `dotpos' > 0 {
        local df_agency = substr("`df_flow'", 1, `dotpos' - 1)
        local df_flow   = substr("`df_flow'", `dotpos' + 1, .)
      }
    }
    else {
      // Fallback: use first indicator token as flow when none supplied
      local df_flow = word("`indicator'", 1)
    }
    
    // Default version if none supplied
    if "`df_version'" == "" local df_version "1.0"
    
    // Build URL: /data/AGENCY,DATAFLOW,VERSION/REF_AREA.INDICATOR.DIM1.DIM2...
    // When country_key is empty, key_suffix starts with dot: /.INDICATOR...
    // When country_key is "BRA", we get /BRA.INDICATOR...
    local url "`base_url'/data/`df_agency',`df_flow',`df_version'/`country_key'`key_suffix'?"
    
    // Add format parameter
    local url "`url'format=`format'&labels=`labels'"
    
    // Add time period parameters
    if "`start_period'" != "" local url "`url'&startPeriod=`start_period'"
    if "`end_period'" != "" local url "`url'&endPeriod=`end_period'"
  }
  
  if "`verbose'" != "" {
    display as text "  URL: `url'"
  }
  
  if "`debug'" != "" {
    display as text ""
    display as text "=== NETWORK REQUEST DETAILS ==="
    display as text "URL: `url'"
    display as text "Method: HTTP GET via Stata copy command"
    display as text "Timeout: Stata default (netio setting)"
    
    // Show current netio timeout
    capture set netio query
    if _rc == 0 {
      display as text "Netio timeout: `c(netio_timeout)' milliseconds"
    }
    display as text ""
  }
  
  // Fetch from API with retries using paging helper or plain copy
  // Strategy: use __unicef_fetch_paged for CSV data requests; fall back to copy for structure or non-paged
  local success 0
  local error_msg ""
  
  // If filename() specified, use that; otherwise create tempfile
  if "`filename'" != "" {
    local api_response "`filename'"
    if "`verbose'" != "" display as text "(get_sdmx) Using caller-specified file: `filename'"
  }
  else {
    tempfile api_response
  }
  
  // For data requests in CSV format, use paging helper
  if "`detail'" == "data" & inlist("`format'", "csv", "csv-ts") {
    // Determine if we can use the paging helper
    local can_page = 1
    local success = 0
    
    // Extract components for paging helper
    // We have already built URL with pagination info; extract components
    // Paging helper needs: indicator (or key segment), dataflow, version, start_year, end_year, countries
    
    // Build indicator segment from key_suffix
    // key_suffix already contains the full key: .INDICATOR.DIM1.DIM2...
    // For paging helper, pass the entire key_suffix as indicator() arg
    local page_indicator "`key_suffix'"
    
    if `can_page' {
      if "`verbose'" != "" display as text "  Using paging fetch (100k rows/page)..."
      
      capture noisily __unicef_fetch_paged, ///
        indicator("`page_indicator'") ///
        dataflow("`df_flow'") ///
        version("`df_version'") ///
        startyear("`start_period'") ///
        endyear("`end_period'") ///
        pagesize(100000) ///
        `verbose'
      
      if _rc == 0 & _N > 0 {
        // Success - data is in memory
        local success 1
        if "`verbose'" != "" display as result "  ✓ Paging fetch successful (`=_N' rows)"
        if "`verbose'" != "" display as result "  DEBUG: Before save, success=`success'"
        
        // Save to api_response file so downstream logic can proceed
        quietly save "`api_response'", replace
        if "`verbose'" != "" display as result "  DEBUG: After save, success=`success'"
      }
      else {
        if "`verbose'" != "" display as text "  Paging fetch failed or returned no data; trying single-page fallback..."
        local can_page = 0
      }
    }
    
    // Fallback to single-page copy if paging wasn't used or failed
    if !`success' {
      forvalues attempt = 1/`retry' {
      if "`verbose'" != "" & `attempt' > 1 {
        display as text "  Retry attempt `attempt' of `retry'..."
      }
      
      // Try copy with public flag (plain query, no auth/UA details)
      if "`verbose'" != "" display as text "  Trying copy..."
      
      // Enable trace for debug mode to see detailed error info
      if "`trace'" != "" {
        set trace on
        display as text "[TRACE] About to execute: copy \"`url'\" \"`api_response'\" replace public"
      }
    
    capture copy "`url'" "`api_response'", replace public
    local copy_rc = _rc
    if "`trace'" != "" set trace off
    
    if `copy_rc' == 0 {
      // File created - validate it has content
      capture confirm file "`api_response'"
      if _rc == 0 {
        // File exists - try to read it to verify not empty/error page
        tempname fh
        file open `fh' using "`api_response'", read
        file read `fh' first_line
        file close `fh'
        
        if "`debug'" != "" {
          display as text "[DEBUG] Response first line (first 100 chars):"
          display as text "  `=substr("`first_line'", 1, 100)'"
        }
        
        // Check if valid CSV (not HTML error)
        if !regexm("`first_line'", "<html|<HTML|<!DOCTYPE") {
          // Valid CSV header line
          local success 1
          if "`verbose'" != "" display as result "  ✓ copy successful, valid data"
        }
        else {
          if "`verbose'" != "" display as text "  copy returned HTML error page"
          if "`debug'" != "" display as error "[DEBUG] API returned HTML (likely error page)"
        }
      }
      else {
        if "`verbose'" != "" display as text "  copy failed to create file"
        if "`debug'" != "" display as error "[DEBUG] File creation failed after copy: rc=`_rc'"
      }
    }
    else {
      if "`verbose'" != "" display as text "  copy failed (rc=`copy_rc')"
      if "`debug'" != "" {
        display as error "[DEBUG] copy command failed with rc=`copy_rc'"
        display as error "[DEBUG] Common causes and solutions:"
        if `copy_rc' == 622 {
          display as error "  - rc=622: Host not found / DNS resolution FAILED"
          display as error "  SOLUTION: Check internet connection and domain name spelling"
          display as error "  - Try: ping sdmx.data.unicef.org"
          display as error "  - Check firewall/proxy settings"
        }
        else if `copy_rc' == 611 {
          display as error "  - rc=611: Protocol error or connection refused"
          display as error "  SOLUTION: Check if server is running and port is accessible"
          display as error "  - Verify URL is correct"
          display as error "  - Try a different dataflow or endpoint"
        }
        else if `copy_rc' == 645 {
          display as error "  - rc=645: Timeout (connection or transfer timeout)"
          display as error "  SOLUTION: API server may be slow or unresponsive"
          display as error "  - Try: set netio timeout 120 (increase from default)"
          display as error "  - Use: get_sdmx, indicator(...) debug retry(5)"
        }
        else if `copy_rc' == 677 {
          display as error "  - rc=677: Connection terminated unexpectedly"
          display as error "  SOLUTION: Server may have closed connection (firewall/proxy)"
          display as error "  - Try from a different network if possible"
          display as error "  - Check corporate firewall/proxy settings"
          display as error "  - May need VPN or network admin approval"
        }
        else {
          display as error "  - rc=`copy_rc': Unrecognized error"
          display as error "  - See: help netio (for network error codes)"
          display as error "  - See: help copy (for Stata-specific errors)"
        }
      }
    }
    
    // If not successful, retry with delay
    if !`success' {
      if `attempt' < `retry' {
        sleep 1000  // 1 second delay before retry
      }
      }
      }  // Close forvalues retry loop
  
  if !`success' {
    display as error "API connection failed after `retry' attempts"
    display as error "URL: `url'"
    error 631  // Stata error for network issues
  }
  
  if "`verbose'" != "" {
    display as text "  Fetch method: copy (plain query)"
  }
    } // Close if !`success' fallback block
    if "`verbose'" != "" display as result "  DEBUG: After fallback block, success=`success'"
  } // Close CSV format conditional
  if "`verbose'" != "" display as result "  DEBUG: Before load block"
  
  // For CSV format (including csv-ts for wide data), import the data (unless filename() was specified)
  if inlist("`format'", "csv", "csv-ts") {
    // Verify file exists before attempting to read
    capture confirm file "`api_response'"
    if _rc != 0 {
      display as error "Error: API response file not found"
      error 601
    }
    
    // Check if file contains valid CSV (not an HTML error page)
    tempname fh
    file open `fh' using "`api_response'", read
    file read `fh' first_line
    file close `fh'
    
    // If first line contains HTML tags, it's an error page not CSV
    if regexm("`first_line'", "<html|<HTML|<!DOCTYPE") {
      display as error "Error: API returned HTML error page instead of CSV"
      display as error "First line: `first_line'"
      error 631
    }
    
    // If filename() was specified, caller will handle import - just return
    if "`filename'" != "" {
      if "`verbose'" != "" {
        display as result "✓ Data saved to: `filename'"
        display as text "(Caller will handle import)"
      }
      // Return the file path so caller knows where data is
      return local datafile "`filename'"
    }
    else {
      // No filename specified - load data directly into memory
      // NOTE: UTF-8 encoding support
      // The SDMX API returns UTF-8 encoded CSV data with accented characters
      // (e.g., Côte d'Ivoire, Curaçao, Réunion). The insheet command may 
      // misinterpret UTF-8 as Latin1, causing mojibake. Post-processing in 
      // unicefdata.ado normalizes known country names to proper UTF-8.
      // Future: Consider upgrading to import delimited with encoding("utf-8")
      // when minimum Stata version allows.
      
      // If paged helper was used, data is already in memory and saved to file
      // Just load it; otherwise import from api_response
      if (`success') & ("`detail'" == "data") {
        // Paged fetch saved dataset to api_response; load it
        capture use "`api_response'", clear
        if _rc != 0 {
          display as error "Error: Failed to load paged dataset (use error `=_rc')"
          error _rc
        }
        if "`verbose'" != "" display as result "  ✓ Loaded paged dataset (`=_N' rows)"
      }
      else {
        // Standard import for single-page or non-paged formats
        // Apply clear option if specified
        local clear_opt = cond("`clear'" != "", "clear", "")
        capture insheet using "`api_response'", `clear_opt'
        if _rc != 0 {
          display as error "Error: Failed to load CSV file (insheet error `=_rc')"
          display as error "File size: `file_size' bytes"
          display as error "URL: `url'"
          error _rc
        }
        if "`verbose'" != "" display as result "  ✓ Imported `=_N' rows via insheet"
      }
      
      // Post-process column names if tidy
      // Convert to lowercase and replace spaces with underscores
      foreach var of varlist * {
        local new_name = lower("`var'")
        local new_name = subinstr("`new_name'", " ", "_", .)
        capture rename `var' `new_name'
      }
      
      // Rename year columns to yr#### format if wide option was specified
      // Also reorder so context/dimension variables come before year columns
      if ("`wide'" != "") {
        _get_sdmx_rename_year_columns, csvfile("`api_response'") reorder
        if "`verbose'" != "" {
          display as text "    Year columns renamed to yr#### format"
          display as text "    Variables reordered: `r(non_year_count)' context vars, `r(year_count)' year vars"
        }
      }
      
      // Add country names if requested
      if "`country_names'" != "" & "`detail'" != "structure" {
        capture confirm variable iso3
        if _rc == 0 {
          capture {
            // Use countrycode if available
            generate country = ""
            replace country = "Afghanistan" if iso3 == "AFG"
            replace country = "Albania" if iso3 == "ALB"
            // Note: Full list would be much longer
            // Better implementation would use a lookup or external command
          }
        }
      }
      
      if "`verbose'" != "" {
        display as result "✓ Data loaded into memory"
        describe
      }
    }
  }
  else if "`format'" == "sdmx-xml" {
    display as text "(get_sdmx) XML format returned - use xmltoyaml to parse"
  }
  else if "`format'" == "sdmx-json" {
    display as text "(get_sdmx) JSON format returned - use JSON parser to process"
  }
  
  // Cache schema if requested
  if "`cache'" != "" & "`detail'" != "structure" {
    capture unicef_cache_set, indicator(`indicator') schema("cached")
  }
  
  // Return metadata
  return local agency "`agency'"
  return local indicator "`indicator'"
  return local detail "`detail'"
  return local format "`format'"
  return local labels "`labels'"
  return local cache "`cache'"
  
  if "`verbose'" != "" {
    display as text "(get_sdmx) Complete"
  }
end

// Helper: Fetch with curl + fallback to copy
program define _get_sdmx_fetch, rclass
  syntax, URL(string) [RETry(integer 3) TIMEOUT(integer 30)]
  
  tempfile tmpfile
  local attempt 1
  local success 0
  
  // Build User-Agent with dynamic Stata version and OS
  // pkg_ver corresponds to main package version in unicefdata.ado
  local pkg_ver "1.6.0"
  local stata_ver = c(stata_version)
  local os = cond(c(os) == "Windows", "Windows", ///
             cond(c(os) == "MacOSX", "Darwin", c(os)))
  local ua "unicefData-Stata/`pkg_ver' (Stata/`stata_ver'; `os') (+https://github.com/unicef-drp/unicefData)"
  
  while `attempt' <= `retry' & !`success' {
    // Try curl first (primary method with User-Agent and timeout)
    local curl_cmd `"curl -s -A "`ua'" --max-time `timeout' "`url'" > "`tmpfile'" 2>/dev/null"'
    capture shell `curl_cmd'
    
    // Check if file exists and is not empty
    capture confirm file "`tmpfile'"
    if _rc == 0 {
      qui capture {
        local file_size : dir . files "`tmpfile'"
        local file_size = wordcount("`file_size'")
      }
      if "`file_size'" != "" & "`file_size'" != "0" {
        local success 1
        return local file "`tmpfile'"
        exit 0
      }
    }
    
    // If curl failed, try fallback to copy
    capture copy "`url'" "`tmpfile'", replace timeout(`timeout')
    if _rc == 0 {
      local success 1
      return local file "`tmpfile'"
      exit 0
    }
    
    local attempt = `attempt' + 1
  }
  
  error 631  // Network error
end

// Helper: Parse SDMX structure
program define _get_sdmx_parse_structure, rclass
  syntax, INFile(string)
  
  // This would parse SDMX XML structure
  // For now, just return file path
  return local structure "`infile'"
end

// Helper: Tidy SDMX data columns
program define _get_sdmx_tidy
  
  // Standardize core column names
  capture rename geo iso3
  capture rename time period
  capture rename value obs_value
  
  // Clean up formatting
  foreach var of varlist * {
    local new_name = lower("`var'")
    local new_name = subinstr("`new_name'", " ", "_", .)
    capture rename `var' `new_name'
  }
  
  // Convert numeric columns
  capture destring obs_value, replace
  
end

// Note: _get_sdmx_rename_year_columns is now a standalone helper program
// located at: src/_/_get_sdmx_rename_year_columns.ado
// This avoids code duplication and simplifies maintenance.
// The helper is called at line ~738 when format is csv-ts (wide mode).

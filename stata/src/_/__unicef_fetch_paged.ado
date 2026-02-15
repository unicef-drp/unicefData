*! v 0.1.1  13Feb2026               by Joao Pedro Azevedo (UNICEF)
program define __unicef_fetch_paged, rclass
    version 11
    /*
        Purpose: Fetch SDMX CSV from UNICEF API with automatic paging
        Inputs (options):
            indicator(str)   - Indicator code, or dot-separated path segment (e.g., .CME_MRY0T4._T)
            dataflow(str)    - Dataflow ID (e.g., CME)
            version(str)     - SDMX version (default 1.0)
            startyear(str)   - Start period (YYYY)
            endyear(str)     - End period (YYYY)
            countries(str)   - Space or comma separated ISO3 list (optional server-side filter)
            pagesize(int)    - Count per page (default 100000)
            verbose          - Print progress
        Output: In memory dataset with concatenated pages
    */
    syntax , INDICator(str) DATAFLOW(str) [ VERsion(str) STARTYear(str) ENDYear(str) COUNTRIES(str) PAGESIze(int 100000) VERBOSE ]

    local base "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
    local ver = cond("`version'"=="", "1.0", "`version'")

    /* Build indicator path: if user passed raw segment starting with '.' keep it; else prepend and suffix dots */
    /* Special case: "all" means bulk download — pass through as-is (SDMX REST standard: /all) */
    local indicator_seg ""
    if (lower("`indicator'") == "all") {
        local indicator_seg "all"
    }
    else if (substr("`indicator'",1,1) == ".") {
        local indicator_seg "`indicator'"
    }
    else {
        local indicator_upper = upper("`indicator'")
        local indicator_seg ".`indicator_upper'."
    }

    /* Compose relative path and common query */
    local relpath "data/UNICEF,`dataflow',`ver'/`indicator_seg'"
    local baseurl "`base'/`relpath'?format=csv&labels=id"
    if ("`startyear'" != "") local baseurl "`baseurl'&startPeriod=`startyear'"
    if ("`endyear'"   != "") local baseurl "`baseurl'&endPeriod=`endyear'"

    tempname fh
    tempfile pagefile allfile
    clear

    local page 0
    local total 0
    local stop 0

    while (`stop' == 0) {
        /* Build page URL */
        local startidx = `page' * `pagesize'
        local url "`baseurl'&startIndex=`startidx'&count=`pagesize'"
        if ("`verbose'" != "") noi di as text "Fetching page " as res `page'+1 " ..."

        /* Import directly from URL; capture empty pages */
        capture noisily import delimited using "`url'", clear varnames(1) stringcols(_all) encoding("UTF-8")
        if (_rc) {
            /* If HTTP 404 or other error yields no data, stop */
            local stop 1
            continue
        }
        /* If zero observations, stop */
        quietly count
        if (r(N) == 0) {
            local stop 1
            continue
        }

        /* Append to accumulator */
        tempname cur
        tempfile curfile
        quietly save "`curfile'", replace
        if (`total' == 0) {
            quietly save "`allfile'", replace
        }
        else {
            use "`allfile'", clear
            append using "`curfile'"
            quietly save "`allfile'", replace
        }

        local total = `total' + r(N)
        if (r(N) < `pagesize') local stop 1
        local page = `page' + 1
    }

    /* Load accumulated data if any */
    capture confirm file "`allfile'"
    if (_rc==0) {
        use "`allfile'", clear
    }
    else {
        clear
    }

    /* Optional server-side country filter: keep only listed ISO3 codes if present */
    capture confirm variable REF_AREA
    if (_rc==0 & "`countries'" != "") {
        local countries_clean = subinstr(upper("`countries'"), ",", " ", .)
        gen byte _keep = 0
        foreach c of local countries_clean {
            replace _keep = 1 if REF_AREA == "`c'"
        }
        keep if _keep
        drop _keep
    }

    return scalar N = _N
end

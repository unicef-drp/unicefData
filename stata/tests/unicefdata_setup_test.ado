*! version 2.0.1  01Feb2026
*! unicefdata_setup - Install YAML metadata files for unicefdata
*! Author: Joao Pedro Azevedo (jpazevedo@unicef.org)

program define unicefdata_setup, rclass
    version 14.0
    
    syntax [, FROM(string) REPLACE VERBOSE QUIET]
    
    * Define path separator for building file paths
    local pathsep = char(92)  /* backslash for Windows */
    
    * Try to find local GitHub repository first
    local local_found 0
    local source_type ""
    
    if "`from'" == "" {
        * Check common local paths for unicefData-dev repository
        * Check each path individually to avoid backslash parsing issues
        
        * Path 1: C:\GitHub\myados\unicefData-dev\stata\src
        local testpath = "C:" + "`pathsep'" + "GitHub" + "`pathsep'" + "myados" + "`pathsep'" + "unicefData-dev" + "`pathsep'" + "stata" + "`pathsep'" + "src"
        local testfile = "`testpath'" + "`pathsep'" + "_" + "`pathsep'" + "_unicefdata_indicators_metadata.yaml"
        cap confirm file "`testfile'"
        if _rc == 0 {
            local from "`testpath'"
            local local_found 1
            local source_type "local"
        }
        
        * Path 2: C:\GitHub\unicefData-dev\stata\src
        if `local_found' == 0 {
            local testpath = "C:" + "`pathsep'" + "GitHub" + "`pathsep'" + "unicefData-dev" + "`pathsep'" + "stata" + "`pathsep'" + "src"
            local testfile = "`testpath'" + "`pathsep'" + "_" + "`pathsep'" + "_unicefdata_indicators_metadata.yaml"
            cap confirm file "`testfile'"
            if _rc == 0 {
                local from "`testpath'"
                local local_found 1
                local source_type "local"
            }
        }
        
        * Path 3: D:\GitHub\myados\unicefData-dev\stata\src
        if `local_found' == 0 {
            local testpath = "D:" + "`pathsep'" + "GitHub" + "`pathsep'" + "myados" + "`pathsep'" + "unicefData-dev" + "`pathsep'" + "stata" + "`pathsep'" + "src"
            local testfile = "`testpath'" + "`pathsep'" + "_" + "`pathsep'" + "_unicefdata_indicators_metadata.yaml"
            cap confirm file "`testfile'"
            if _rc == 0 {
                local from "`testpath'"
                local local_found 1
                local source_type "local"
            }
        }
        
        if `local_found' == 1 {
            if "`quiet'" == "" & "`verbose'" != "" {
                di as text "Found local repository: `from'"
            }
        }
        else {
            * Fall back to GitHub raw URL if no local repo found
            local from "https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/src"
            local source_type "remote"
            if "`quiet'" == "" & "`verbose'" != "" {
                di as text "Using remote repository: `from'"
            }
        }
    }
    else {
        * User provided explicit path
        local source_type "user"
    }
    
    * Get the ado/plus directory
    local plusdir : sysdir PLUS
    local targetdir "`plusdir'_"
    
    * Create target directory if it doesn't exist
    cap mkdir "`targetdir'"
    
    if "`verbose'" != "" {
        di as text "Source: `from'"
        di as text "Target: `targetdir'"
    }
    
    * List of YAML files to install
    * NOTE: _unicefdata_indicators.yaml is DEPRECATED - use _unicefdata_indicators_metadata.yaml
    local yamlfiles ///
        _unicefdata_dataflows.yaml ///
        _unicefdata_codelists.yaml ///
        _unicefdata_countries.yaml ///
        _unicefdata_regions.yaml ///
        _unicefdata_sync_history.yaml ///
        _dataflow_index.yaml ///
        _dataflow_fallback_sequences.yaml ///
        _unicefdata_indicators_metadata.yaml ///
        _indicator_dataflow_map.yaml ///
        _unicefdata_dataflow_metadata.yaml
    
    * Also include the text file
    local txtfiles _dataflow_indicators_list.txt
    
    local installed 0
    local failed 0
    
    if "`quiet'" == "" {
        di as text ""
        di as text "{hline 70}"
        di as text "Installing unicefdata metadata files..."
        di as text "{hline 70}"
    }
    
    * Install YAML files
    foreach f of local yamlfiles {
        * Build source path - handle both local (backslash) and remote (forward slash) paths
        if `local_found' == 1 {
            local srcfile = "`from'" + "`pathsep'" + "_" + "`pathsep'" + "`f'"
        }
        else {
            local srcfile "`from'/_/`f'"
        }
        local destfile "`targetdir'/`f'"
        
        if "`verbose'" != "" {
            di as text "  Downloading: `f'"
        }
        
        cap copy "`srcfile'" "`destfile'", `replace'
        
        if _rc == 0 {
            local installed = `installed' + 1
            if "`quiet'" == "" {
                di as text "  {result:OK} `f'"
            }
        }
        else if _rc == 602 & "`replace'" == "" {
            if "`quiet'" == "" {
                di as text "  {result:SKIP} `f' (already exists, use replace option)"
            }
        }
        else {
            local failed = `failed' + 1
            di as error "  {error:FAIL} `f' (error `=_rc')"
        }
    }
    
    * Install TXT files
    foreach f of local txtfiles {
        * Build source path - handle both local (backslash) and remote (forward slash) paths
        if `local_found' == 1 {
            local srcfile = "`from'" + "`pathsep'" + "_" + "`pathsep'" + "`f'"
        }
        else {
            local srcfile "`from'/_/`f'"
        }
        local destfile "`targetdir'/`f'"
        
        if "`verbose'" != "" {
            di as text "  Downloading: `f'"
        }
        
        cap copy "`srcfile'" "`destfile'", `replace'
        
        if _rc == 0 {
            local installed = `installed' + 1
            if "`quiet'" == "" {
                di as text "  {result:OK} `f'"
            }
        }
        else if _rc == 602 & "`replace'" == "" {
            if "`quiet'" == "" {
                di as text "  {result:SKIP} `f' (already exists, use replace option)"
            }
        }
        else {
            local failed = `failed' + 1
            di as error "  {error:FAIL} `f' (error `=_rc')"
        }
    }
    
    * Install individual dataflow schema files
    local dfdir "`targetdir'/_dataflows"
    cap mkdir "`dfdir'"
    local dataflows "CAUSE_OF_DEATH CCRI CHILD_RELATED_SDG CHLD_PVTY"
    local dataflows "`dataflows' CME CME_CAUSE_OF_DEATH CME_COUNTRY_PROFILES_DATA CME_DF_2021_WQ"
    local dataflows "`dataflows' CME_SUBNAT_AGO CME_SUBNAT_BDI CME_SUBNAT_BEN CME_SUBNAT_BGD"
    local dataflows "`dataflows' CME_SUBNAT_CMR CME_SUBNAT_ETH CME_SUBNAT_GHA CME_SUBNAT_GIN"
    local dataflows "`dataflows' CME_SUBNAT_HTI CME_SUBNAT_KEN CME_SUBNAT_LAO CME_SUBNAT_LBR"
    local dataflows "`dataflows' CME_SUBNAT_LSO CME_SUBNAT_MDG CME_SUBNAT_MLI CME_SUBNAT_MMR"
    local dataflows "`dataflows' CME_SUBNAT_MRT CME_SUBNAT_MWI CME_SUBNAT_NAM CME_SUBNAT_NGA"
    local dataflows "`dataflows' CME_SUBNAT_NPL CME_SUBNAT_PAK CME_SUBNAT_RWA CME_SUBNAT_SEN"
    local dataflows "`dataflows' CME_SUBNAT_SLE CME_SUBNAT_TCD CME_SUBNAT_TGO CME_SUBNAT_TZA"
    local dataflows "`dataflows' CME_SUBNAT_UGA CME_SUBNAT_ZMB CME_SUBNAT_ZWE CME_SUBNATIONAL"
    local dataflows "`dataflows' COVID COVID_CASES DM DM_PROJECTIONS ECD ECONOMIC"
    local dataflows "`dataflows' EDUCATION EDUCATION_FLS EDUCATION_UIS_SDG"
    local dataflows "`dataflows' FUNCTIONAL_DIFF GENDER GLOBAL_DATAFLOW HIV_AIDS IMMUNISATION"
    local dataflows "`dataflows' MG MNCH NUTRITION PT PT_CM PT_CM_SUBNATIONAL PT_CONFLICT PT_FGM"
    local dataflows "`dataflows' SDG_PROG_ASSESSMENT SOC_PROTECTION"
    local dataflows "`dataflows' WASH_HEALTHCARE_FACILITY WASH_HOUSEHOLD_MH WASH_HOUSEHOLD_SUBNAT"
    local dataflows "`dataflows' WASH_HOUSEHOLDS WASH_SCHOOLS WT"
    local df_installed 0
    local df_failed 0
    if "`quiet'" == "" {
        di as text ""
        di as text "Installing dataflow schema files..."
    }
    foreach df of local dataflows {
        if `local_found' == 1 {
            local srcfile = "`from'" + "`pathsep'" + "_" + "`pathsep'" + "_dataflows" + "`pathsep'" + "`df'.yaml"
        }
        else {
            local srcfile "`from'/_/_dataflows/`df'.yaml"
        }
        local destfile "`dfdir'/`df'.yaml"
        cap copy "`srcfile'" "`destfile'", `replace'
        if _rc == 0 {
            local df_installed = `df_installed' + 1
        }
        else if _rc == 602 & "`replace'" == "" {
            * Already exists
        }
        else {
            local df_failed = `df_failed' + 1
        }
    }
    if "`quiet'" == "" {
        di as text "  `df_installed' dataflow schemas installed, `df_failed' failed"
    }
    local installed = `installed' + `df_installed'
    local failed = `failed' + `df_failed'
    if "`quiet'" == "" {
        di as text "{hline 70}"
        di as text "Installation complete: `installed' installed, `failed' failed"
        if "`source_type'" == "local" {
            di as text "Source: local repository"
        }
        else if "`source_type'" == "remote" {
            di as text "Source: GitHub (remote)"
        }
        di as text "Files installed to: `targetdir'"
        di as text "{hline 70}"
    }
    if `failed' > 0 {
        di as error "Some files failed to install. Check network connection or use from() option."
        error 601
    }
    return local targetdir "`targetdir'"
    return local source "`from'"
    return local source_type "`source_type'"
    return scalar installed = `installed'
    return scalar failed = `failed'
end

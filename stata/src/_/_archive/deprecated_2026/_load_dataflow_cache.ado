*! version 1.0.0  13jan2026
*! _load_dataflow_cache: Load YAML fallback sequences into global macros (once per session)
*! Author: João Pedro Azevedo
*! Uses: yaml.ado to read YAML into a frame (_fallback)

program define _load_dataflow_cache
    version 16

    * Check if already loaded this session
    if "${dataflow_cache_loaded}" == "1" {
        noisily di as text "Dataflow cache already loaded"
        exit 0
    }

    noisily di as text "Loading dataflow cache..."

    * Find the YAML file using sysdir PLUS (standard Stata location)
    local plus_dir "`c(sysdir_plus)'"

    local yaml_file ""
    * Candidate locations (checked in order)
    * Note: net install with 'all' copies ancillary files to current directory
    * Note: net install puts ado files in plus/_/ subfolder (alphabetical by first char)
    local candidate_paths ///
        "_dataflow_fallback_sequences.yaml" ///
        "`plus_dir'_/_dataflow_fallback_sequences.yaml" ///
        "`plus_dir'_dataflow_fallback_sequences.yaml" ///
        "stata/src/_/_dataflow_fallback_sequences.yaml" ///
        "src/_/_dataflow_fallback_sequences.yaml" ///
        "metadata/current/_dataflow_fallback_sequences.yaml" ///
        "../metadata/current/_dataflow_fallback_sequences.yaml" ///
        "../../metadata/current/_dataflow_fallback_sequences.yaml"

    foreach path of local candidate_paths {
        capture confirm file "`path'"
        if !_rc {
            local yaml_file "`path'"
            noisily di as text "Found YAML: `yaml_file'"
            continue, break
        }
    }

    * If YAML not found, fall back to defaults
    if "`yaml_file'" == "" {
        noisily di as text "No YAML fallback sequences found; using defaults"
        *capture _set_default_dataflows
        *global dataflow_cache_loaded "1"
        *exit 0
    }

    * Read YAML into frame _fallback (requires yaml.ado)
    quietly: yaml read using "`yaml_file'", frame(_fallback) replace

    * 1) get prefixes under fallback_sequences
    quietly: yaml list fallback_sequences, frame(_fallback) children keys
    local prefixes "`r(keys)'"
    noisily di as text "Found prefixes: `prefixes'"

    * guardrail: if none found, use defaults
    if "`prefixes'" == "" {
        noisily di as error "No prefixes found under fallback_sequences; using defaults"
        capture _set_default_dataflows
        global dataflow_cache_loaded "1"
        exit 0
    }

    * 2) for each prefix, list its children (dataflow sequence)
    foreach prefix of local prefixes {
        * Get numeric order (indexes)
        quietly: yaml list fallback_sequences_`prefix', frame(_fallback) children keys
        local order "`r(keys)'"

        * Get resolved names directly
        quietly: yaml list fallback_sequences_`prefix', frame(_fallback) children values
        local names "`r(values)'"

        if "`order'" != "" {
            global dataflow_order_`prefix' "`order'"
        }
        if "`names'" != "" {
            global dataflow_`prefix' "`names'"
        }

        if ("`order'" != "" | "`names'" != "") {
            noisily di as text "Saved `prefix' order: ${dataflow_order_`prefix'}"
            noisily di as text "Saved `prefix' names: ${dataflow_`prefix'}"
        }
    }

    * Mark cache as loaded
    global dataflow_cache_loaded "1"
    noisily di as text "Cache loaded successfully"

end

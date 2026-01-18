*! version 1.0.0  13jan2026
*! _get_dataflow_for_indicator: Get the appropriate dataflow for a given indicator
*! Author: João Pedro Azevedo
*! Returns: Space-separated list of dataflows to try (in order)

program define _get_dataflow_for_indicator, rclass
    version 11
    syntax anything(name=indicator)

    * Ensure cache is loaded
    _load_dataflow_cache

    * Extract prefix and look up dataflow global directly
    * subinstr replaces ALL "_" with " ", then word() gets first token (the prefix)
    * This gives us the prefix to insert into dataflow_<prefix>
    local prefix = word(subinstr("`indicator'", "_", " ", .), 1)
    local dataflows "${dataflow_`prefix'}"

    * Fallback to DEFAULT sequence if prefix not present
    if ("`dataflows'" == "") {
        local dataflows "${dataflow_DEFAULT}"
    }

    * Final fallback: use GLOBAL_DATAFLOW only
    if ("`dataflows'" == "") {
        local dataflows "GLOBAL_DATAFLOW"
    }

    * Return the sequence and first element
    return local dataflows "`dataflows'"
    local first_dataflow = word("`dataflows'", 1)
    return local first "`first_dataflow'"

end

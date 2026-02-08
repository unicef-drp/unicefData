* Minimal test of the new dataflow setup code
clear all
discard

program define test_setup, rclass
    version 14.0

    local dataflows "CME NUTRITION IMMUNISATION"
    local dataflows "`dataflows' EDUCATION HIV_AIDS"

    foreach df of local dataflows {
        di as text "  Processing: `df'"
    }

    di as result "Done: processed dataflows"
end

test_setup

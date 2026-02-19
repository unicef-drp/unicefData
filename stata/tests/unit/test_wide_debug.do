clear all
set more off
discard
unicefdata, indicator(CME_MRY0T4) clear wide

capture confirm variable v8 v9 v10 v11 v12
if _rc {
    di ""
    di as txt "Variables v8-v12 not found; wide-year renaming likely succeeded. Skipping debug output."
}
else {
    di ""
    di "=== Variable types for v8-v12 ==="
    describe v8 v9 v10 v11 v12

    di ""
    di "=== First 2 obs for v8-v12 ==="
    list v8 v9 v10 v11 v12 in 1/2
}

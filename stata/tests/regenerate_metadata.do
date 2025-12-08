// Regenerate Stata metadata files
// Uses forcestata parser for consistent output
clear all
set more off

// Add ado paths
adopath ++ "D:/jazevedo/GitHub/unicefData/stata/src/u"
adopath ++ "D:/jazevedo/GitHub/unicefData/stata/src/_"

cap log close
log using "D:/jazevedo/GitHub/unicefData/stata/log/regenerate_metadata.log", replace text

di as text _n "=============================================="
di as text "Regenerating Stata metadata files"
di as text "Using: forcestata parser"
di as text "=============================================="

timer clear
timer on 1

// Run sync with forcestata (pure Stata parser, no suffix)
unicefdata_sync, verbose forcestata

timer off 1
timer list 1

di as text _n "=============================================="
di as text "Metadata regeneration complete"
di as text "=============================================="

log close

exit, clear STATA

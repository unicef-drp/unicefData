clear all
set more off
set trace on
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

unicefdata, indicator(CME_MRY0T4) startyear(2020) endyear(2023) clear verbose

set trace off
display "Test complete: `=_N' rows"

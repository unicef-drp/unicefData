*! Direct get_sdmx test
clear all
set more off
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

display "Testing get_sdmx directly..."
get_sdmx CME_MRY0T4, dataflow(CME) version(1.0) start_period(2020) end_period(2023) verbose clear

display _n "Rows: `=_N'"
list in 1/3

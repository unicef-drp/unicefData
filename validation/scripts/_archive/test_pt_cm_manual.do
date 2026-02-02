clear all
set more off
set trace off
discard

* Add unicefData ado paths
adopath ++ "C:/GitHub/myados/unicefData/stata/src/u"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/_"
adopath ++ "C:/GitHub/myados/unicefData/stata/src/y"

unicefdata, indicator(PT_CM_EMPLOY_12M) clear verbose

qui describe
local nobs = r(N)
display "Rows: `nobs'"

* Test if get_sdmx.ado can be parsed
clear all
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

* Try to compile the program
discard
which get_sdmx

program list get_sdmx

display "If you see this, get_sdmx parsed successfully"

* Test if get_sdmx compiles
clear all
set linesize 120

* Load the ado path
adopath ++ "C:\GitHub\myados\unicefData-dev\stata\src"

* Discard any cached programs
discard

* Try to load get_sdmx
display "Attempting to load get_sdmx..."
which get_sdmx

* If we reach here, it loaded successfully
display "get_sdmx loaded successfully"

* Try to see the program code
program list get_sdmx

log close _all

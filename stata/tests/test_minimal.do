* Minimal test - just attempt to run unicefdata_sync help
clear all
set more off

adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\u"
adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\_"

di "Testing basic sync with verbose only..."
unicefdata_sync, verbose

di "Done"
exit, clear

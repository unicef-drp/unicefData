* Test loading unicefdata_sync.ado
clear all
set more off

adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\u"
adopath ++ "D:\jazevedo\GitHub\unicefData\stata\src\_"

di "Attempting to load unicefdata_sync..."
which unicefdata_sync
di "Loaded successfully"

exit, clear

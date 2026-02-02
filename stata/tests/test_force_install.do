clear all
discard
net install unicefdata, from("C:\GitHub\myados\unicefData-dev\stata") replace force
discard
_get_sdmx_rename_year_columns

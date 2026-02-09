# Deploy the updated help file
Copy-Item -Path "C:\GitHub\myados\unicefData\stata\src\u\unicefdata.sthlp" -Destination "$env:USERPROFILE\ado\plus\u\unicefdata.sthlp" -Force
Write-Host "Help file deployed successfully"
Write-Host "Now in Stata:"
Write-Host "1. Run: discard"
Write-Host "2. Run: help unicefdata"

# Deploy updated unicefdata.sthlp (937 lines) with Sections Menu navigation
$src = "C:\GitHub\myados\unicefData\stata\src\u"
$dest = "$env:USERPROFILE\ado\plus\u"

Copy-Item "$src\unicefdata.sthlp" -Destination "$dest\unicefdata.sthlp" -Force
Copy-Item "$src\unicefdata_whatsnew.sthlp" -Destination "$dest\unicefdata_whatsnew.sthlp" -Force

Write-Host "Deployed:"
Write-Host "  - unicefdata.sthlp ($(Get-Content "$src\unicefdata.sthlp" | Measure-Object -Line | Select-Object -ExpandProperty Lines) lines)"
Write-Host "  - unicefdata_whatsnew.sthlp"

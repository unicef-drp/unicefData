# Deploy unicefdata files to ado\plus path
$source = "C:\GitHub\myados\unicefData\stata\src\u"
$dest = "$env:USERPROFILE\ado\plus\u"

Copy-Item -Path "$source\unicefdata.sthlp" -Destination "$dest\unicefdata.sthlp" -Force
Copy-Item -Path "$source\unicefdata_examples.ado" -Destination "$dest\unicefdata_examples.ado" -Force

Write-Host "Deployed:"
Write-Host "  - unicefdata.sthlp"
Write-Host "  - unicefdata_examples.ado"
Write-Host "To: $dest"

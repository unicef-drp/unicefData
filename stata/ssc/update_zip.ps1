# PowerShell script to automate the creation of the unicefdata zip package

# Define paths
$pkgFile = "c:\GitHub\myados\unicefData\stata\ssc\unicefdata.pkg"
$srcFolder = "c:\GitHub\myados\unicefData\stata\src"
$zipFolder = "c:\GitHub\myados\unicefData\stata\ssc"
$tempFolder = "$zipFolder\temp_unzip"
$zipFile = "$zipFolder\unicefdata_package_151.zip"

# Ensure temp folder exists
if (Test-Path $tempFolder) {
    Remove-Item -Recurse -Force $tempFolder
}
New-Item -ItemType Directory -Path $tempFolder

# Read files from pkg
$files = Get-Content $pkgFile | Where-Object { $_ -match '^f ' } | ForEach-Object { ($_ -split ' ')[1] }

# Copy files to temp folder
foreach ($file in $files) {
    $sourcePath = Join-Path -Path $srcFolder -ChildPath $file
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $tempFolder -Force
    } else {
        Write-Host "Warning: File not found - $sourcePath"
    }
}

# Recreate the zip file
if (Test-Path $zipFile) {
    Remove-Item -Force $zipFile
}
Compress-Archive -Path "$tempFolder\*" -DestinationPath $zipFile -Force

# Cleanup
Remove-Item -Recurse -Force $tempFolder

Write-Host "Zip package created: $zipFile"